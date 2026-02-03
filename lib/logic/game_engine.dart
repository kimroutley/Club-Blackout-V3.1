// ignore_for_file: unreachable_switch_case

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_script.dart';
import '../data/gossip_repository.dart';
import '../data/role_repository.dart';
import '../models/game_log_entry.dart';
import '../models/player.dart';
import '../models/role.dart';
import '../models/saved_game.dart';
import '../models/script_step.dart';
import '../models/vote_cast.dart';
import '../utils/death_causes.dart';
import '../utils/game_exceptions.dart';
import '../utils/game_logger.dart';
import '../utils/input_validator.dart';
import '../utils/role_validator.dart';
import 'ability_system.dart';
import 'game_state.dart';
import 'games_night_service.dart';
import 'hall_of_fame_service.dart';
import 'reaction_system.dart';
import 'script_builder.dart';

export 'game_state.dart';

class DramaQueenSwapRecord {
  final int day;
  final String playerAName;
  final String playerBName;
  final String fromRoleA;
  final String fromRoleB;
  final String toRoleA;
  final String toRoleB;

  const DramaQueenSwapRecord({
    required this.day,
    required this.playerAName,
    required this.playerBName,
    required this.fromRoleA,
    required this.fromRoleB,
    required this.toRoleA,
    required this.toRoleB,
  });
}

class GameEndResult {
  final String winner; // e.g. 'DEALER', 'PARTY_ANIMAL'
  final String message;

  const GameEndResult({required this.winner, required this.message});
}

class GameEngine extends ChangeNotifier {
  final RoleRepository roleRepository;

  /// If true, logging to the game log and external services is disabled.
  /// This is critical for performance during Monte Carlo simulations.
  final bool silent;

  /// If false, SharedPreferences interactions are disabled.
  /// Used for simulations/tests to prevent side effects and isolate crashes.
  final bool persistenceEnabled;

  static const String hostRoleId = 'host';
  static const String hostPlayerId = 'host';

  static const String _hostNamePrefsKey = 'host_name';

  static const int _saveSchemaVersion = 1;
  static const String _savedGamesIndexKey = 'savedGames';
  static const String _savePrefix = 'gameState_';
  static const String _saveBlobSuffix = '_blob';

  // Stores a single â€œlast gameâ€ snapshot so hosts can view/export stats after
  // returning to the lobby.
  static const String _lastArchivedGameBlobKey = 'lastArchivedGameBlob';

  String _saveKey(String saveId, String field) =>
      '$_savePrefix${saveId}_$field';
  String _saveBlobKey(String saveId) => '$_savePrefix$saveId$_saveBlobSuffix';

  // Optimization: cached map of active role colors
  Map<String, Color>? _activeRoleColorsCache;

  Color? getRoleColor(String roleId) {
    if (_activeRoleColorsCache == null) {
      _activeRoleColorsCache = {};
      for (final p in players) {
        _activeRoleColorsCache![p.role.id] = p.role.color;
      }
    }
    return _activeRoleColorsCache![roleId];
  }

  @override
  void notifyListeners() {
    _activeRoleColorsCache = null;
    super.notifyListeners();
  }

  void refreshUi() {
    notifyListeners();
  }

  void enterEndGame({String? reason}) {
    if (reason != null) {
      logAction('Game Over', reason);
    }
    currentPhase = GamePhase.endGame;
  }

  bool setPlayerEnabled(
    String playerId,
    bool enabled, {
    bool notify = true,
  }) {
    final player = players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) return false;

    if (player.isEnabled == enabled) return true;
    player.isEnabled = enabled;

    if (!enabled) {
      // Defensive cleanup: if a player is removed mid-day, clear any votes
      // they cast and any votes pointing at them.
      final prevTarget = currentDayVotesByVoter.remove(playerId);
      if (prevTarget != null) {
        currentDayVotesByTarget[prevTarget]?.remove(playerId);
        if (currentDayVotesByTarget[prevTarget]?.isEmpty ?? false) {
          currentDayVotesByTarget.remove(prevTarget);
        }
      }

      final voters = List<String>.from(
        currentDayVotesByTarget[playerId] ?? const <String>[],
      );
      currentDayVotesByTarget.remove(playerId);
      for (final voterId in voters) {
        if (currentDayVotesByVoter[voterId] == playerId) {
          currentDayVotesByVoter[voterId] = null;
        }
      }
    }

    if (notify) {
      notifyListeners();
    }
    _invalidateEligibleVotesCache();
    return true;
  }

  bool applyPlayerStatus(
    String playerId,
    String status, {
    bool notify = true,
  }) {
    final player = players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) return false;
    player.applyStatus(status);
    if (notify) {
      notifyListeners();
    }
    _invalidateEligibleVotesCache();
    return true;
  }

  List<Player> players = [];
  GamePhase _currentPhase = GamePhase.lobby;

  // Callback for phase transitions
  void Function(GamePhase oldPhase, GamePhase newPhase)? onPhaseChanged;

  // Callback for clinger double death (clinger, obsession)
  void Function(String clingerName, String obsessionName)? onClingerDoubleDeath;

  // Callback for club manager role reveal (target player)
  void Function(Player target)? onClubManagerReveal;

  // Host UI alerts (one-shot messages; UI watches version changes).
  int hostAlertVersion = 0;
  String? hostAlertTitle;
  String? hostAlertMessage;

  // Host identity is facilitator-only (NOT a gameplay player).
  String? _hostName;

  // Gameplay toasts (short-lived, non-blocking UI cues).
  // The UI listens to toastVersion and shows toastTitle/toastMessage once.
  int toastVersion = 0;
  String? toastTitle;
  String? toastMessage;
  String? toastActionLabel;
  VoidCallback? toastAction;

  // Persistent toast for important actions (AI commentary)
  int persistentToastVersion = 0;
  String? persistentToastTitle;
  String? persistentToastMessage;
  String? persistentToastContent; // For file path or prompt content
  VoidCallback? persistentToastShareAction;
  VoidCallback? persistentToastIgnoreAction;
  bool hasPersistentToast = false;

  // Messy Bitch Victory handling
  bool messyBitchVictoryPending = false;
  void markMessyBitchVictoryPending() {
    if (messyBitchVictoryPending) return;
    messyBitchVictoryPending = true;

    if (!silent) {
      queueHostAlert(
        title: 'Messy Bitch can win',
        message: 'Rumours reached every enabled guest. Declare the win.',
      );

      showPersistentToast(
        title: 'Messy Bitch Victory?',
        message: 'Rumours reached everyone. Confirm to end the game.',
        onIgnore: dismissPersistentToast,
      );
    }

    notifyListeners();
  }

  void declareMessyBitchVictory() {
    if (!messyBitchVictoryPending) return;
    messyBitchVictoryPending = false;
    enterEndGame(reason: 'Messy Bitch spread a rumour to every player.');
    notifyListeners();
  }

  void clearMessyBitchVictoryPending() {
    messyBitchVictoryPending = false;
    notifyListeners();
  }

  void showToast(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    toastTitle = title;
    toastMessage = message;
    toastActionLabel = actionLabel;
    toastAction = onAction;
    toastVersion++;
    notifyListeners();
  }

  void showPersistentToast({
    required String title,
    required String message,
    String? content,
    VoidCallback? onShare,
    VoidCallback? onIgnore,
  }) {
    persistentToastTitle = title;
    persistentToastMessage = message;
    persistentToastContent = content;
    persistentToastShareAction = onShare;
    persistentToastIgnoreAction = onIgnore;
    hasPersistentToast = true;
    persistentToastVersion++;
    notifyListeners();
  }

  void dismissPersistentToast() {
    hasPersistentToast = false;
    persistentToastTitle = null;
    persistentToastMessage = null;
    persistentToastContent = null;
    persistentToastShareAction = null;
    persistentToastIgnoreAction = null;
    notifyListeners();
  }

  void _queueToast({required String title, required String message}) =>
      showToast(message, title: title);

  void queueHostAlert({required String title, required String message}) {
    hostAlertTitle = title;
    hostAlertMessage = message;
    hostAlertVersion++;
    notifyListeners();
  }

  void triggerMeowAlert() {
    queueHostAlert(title: 'THE ALLY CAT', message: 'M E O W ! ðŸ¾');
    logAction('Social', 'The Ally Cat meowed.');
  }

  // Script Engine
  List<ScriptStep> _scriptQueue = [];
  int _scriptIndex = 0;

  // Game State Tracking
  int dayCount = 0;
  Map<String, dynamic> nightActions = {};
  List<String> deadPlayerIds = [];
  List<String> nameHistory = [];
  List<GameLogEntry> _gameLog = [];
  String lastNightSummary = '';

  /// Host-facing recap (UI reads this first, falls back to lastNightSummary).
  String lastNightHostRecap = '';

  /// Host-facing numeric deltas (kept minimal; UI expects a map).
  final Map<String, int> lastNightStats = <String, int>{};

  bool dramaQueenSwapPending = false;
  String? dramaQueenMarkedAId;
  String? dramaQueenMarkedBId;
  DramaQueenSwapRecord? lastDramaQueenSwap;

  bool _dayphaseVotesMade = false;
  final List<Map<String, String>> _clingerDoubleDeaths = [];

  // Predator retaliation in-flight state (persisted)
  String? pendingPredatorId;
  List<String> pendingPredatorEligibleVoterIds = [];
  String? pendingPredatorPreferredTargetId;

  bool get hasPendingPredatorRetaliation => pendingPredatorId != null;

  // Tea Spiller reveal in-flight state (persisted)
  String? pendingTeaSpillerId;
  List<String> pendingTeaSpillerEligibleVoterIds = [];
  bool get hasPendingTeaSpillerReveal => pendingTeaSpillerId != null;

  final ReactionSystem reactionSystem = ReactionSystem();
  final StatusEffectManager statusEffectManager = StatusEffectManager();
  final AbilityChainResolver chainResolver = AbilityChainResolver();
  final AbilityResolver abilityResolver = AbilityResolver();
  final Map<String, List<String>> _abilityTargets = {};

  // Voting telemetry (used by HostInsights/VotingInsights/StoryExporter)
  final List<VoteCast> voteHistory = [];
  final List<Map<String, dynamic>> nightHistory =
      []; // Archives nightActions per night
  final List<VoteCast> voteChanges =
      []; // Tracks real-time vote switching within a day
  final Map<String, String?> currentDayVotesByVoter = {};
  final Map<String, List<String>> currentDayVotesByTarget = {};
  int _voteSequence = 0;

  // Win state (used by GameScreen)
  String? _winner;
  String? _winMessage;

  List<GameLogEntry> get gameLog => List.unmodifiable(_gameLog);

  GamePhase get currentPhase => _currentPhase;
  set currentPhase(GamePhase value) {
    if (_currentPhase != value) {
      final old = _currentPhase;
      _currentPhase = value;
      notifyListeners();
      onPhaseChanged?.call(old, value);
    }
  }

  List<ScriptStep> get scriptQueue => List.unmodifiable(_scriptQueue);
  int get currentScriptIndex => _scriptIndex;

  ScriptStep? get currentScriptStep {
    if (_scriptQueue.isNotEmpty && _scriptIndex < _scriptQueue.length) {
      return _scriptQueue[_scriptIndex];
    }
    return null;
  }

  /// Guests are the real, in-game players.
  Iterable<Player> get guests => players;

  /// Host is *not* a gameplay player. This remains for API compatibility and
  /// always returns null.
  Player? get hostPlayer => null;

  String? get hostName {
    final name = _hostName?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  String get hostDisplayName => hostName ?? 'Host';

  void setHostName(String rawName) {
    final sanitized = InputValidator.sanitizeString(rawName).trim();
    if (sanitized.isEmpty) {
      _setHostNameInternal(null);
      return;
    }

    final validation = InputValidator.validatePlayerName(sanitized);
    if (validation.isInvalid) {
      throw ArgumentError(validation.error);
    }

    // Ensure uniqueness vs all players (case-insensitive)
    final lower = sanitized.toLowerCase();
    final collision = players.any((p) {
      return p.name.trim().toLowerCase() == lower;
    });
    if (collision) {
      throw ArgumentError('A player with this name already exists');
    }

    _addToHistory(sanitized);

    _setHostNameInternal(sanitized);
  }

  Future<void> _loadHostName() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hostNamePrefsKey);
    _hostName = raw;
    notifyListeners();
  }

  void _setHostNameInternal(String? name, {bool notify = true}) {
    _hostName = name;
    // Fire-and-forget persistence; UI can update immediately.
    if (persistenceEnabled) {
      SharedPreferences.getInstance().then((prefs) {
        if (name == null || name.trim().isEmpty) {
          prefs.remove(_hostNamePrefsKey);
        } else {
          prefs.setString(_hostNamePrefsKey, name);
        }
      });
    }
    if (notify) {
      notifyListeners();
    }
    _invalidateEligibleVotesCache();
  }

  String? get winner => _winner;
  String? get winMessage => _winMessage;

  GameEngine({
    required this.roleRepository,
    bool loadNameHistory = true,
    bool loadArchivedSnapshot = true,
    this.silent = false,
    this.persistenceEnabled = true,
  }) {
    if (loadNameHistory) {
      _loadNameHistory();
      _loadHostName();
    }

    if (loadArchivedSnapshot) {
      _loadLastArchivedGameBlob();
    }
  }

  String? _lastArchivedGameBlobJson;
  DateTime? _cachedLastArchivedGameSavedAt;

  /// JSON-encoded save blob of the most recently archived game.
  ///
  /// This is written automatically before [resetToLobby] wipes the active game.
  String? get lastArchivedGameBlobJson => _lastArchivedGameBlobJson;

  DateTime? get lastArchivedGameSavedAt => _cachedLastArchivedGameSavedAt;

  void _updateCachedSavedAt() {
    final json = _lastArchivedGameBlobJson;
    if (json == null) {
      _cachedLastArchivedGameSavedAt = null;
      return;
    }
    try {
      final decoded = (jsonDecode(json) as Map).cast<String, dynamic>();
      final savedAt = decoded['savedAt'] as String?;
      if (savedAt == null) {
        _cachedLastArchivedGameSavedAt = null;
      } else {
        _cachedLastArchivedGameSavedAt = DateTime.tryParse(savedAt);
      }
    } catch (_) {
      _cachedLastArchivedGameSavedAt = null;
    }
  }

  Future<void> _loadLastArchivedGameBlob() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    _lastArchivedGameBlobJson = prefs.getString(_lastArchivedGameBlobKey);
    _updateCachedSavedAt();
    notifyListeners();
  }

  bool _shouldArchiveBeforeReset() {
    if (_currentPhase != GamePhase.lobby) return true;
    if (dayCount != 0) return true;
    if (_gameLog.isNotEmpty) return true;
    if (_winner != null || _winMessage != null) return true;

    // If roles were assigned at any point, preserve the snapshot.
    final anyAssigned =
        players.where((p) => p.isEnabled).any((p) => p.role.id != 'temp');
    return anyAssigned;
  }

  Future<void> archiveCurrentGameBlob({bool notify = true}) async {
    final blob = exportSaveBlobMap(includeLog: true);
    final encoded = jsonEncode(blob);
    _lastArchivedGameBlobJson = encoded;
    if (persistenceEnabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastArchivedGameBlobKey, encoded);
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> clearArchivedGameBlob({bool notify = true}) async {
    _lastArchivedGameBlobJson = null;
    if (persistenceEnabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastArchivedGameBlobKey);
    }
    if (notify) {
      notifyListeners();
    }
  }

  /// Export a single-map representation of the current engine state.
  ///
  /// This is similar to the persistence â€œblobâ€ save format, but does not touch
  /// disk. Intended for simulations/tests/tools.
  Map<String, dynamic> exportSaveBlobMap({bool includeLog = true}) {
    return <String, dynamic>{
      'schemaVersion': _saveSchemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'winner': _winner,
      'winMessage': _winMessage,
      'hostName': hostName,
      'players': players.map((p) => p.toJson()).toList(growable: false),
      'log': includeLog
          ? _gameLog.map((l) => l.toJson()).toList(growable: false)
          : const <dynamic>[],
      'phaseIndex': _currentPhase.index,
      'dayCount': dayCount,
      'scriptIndex': _scriptIndex,
      'lastNightSummary': lastNightSummary,
      'lastNightHostRecap': lastNightHostRecap,
      'lastNightStats': Map<String, int>.from(lastNightStats),
      'nightActions': nightActions,
      'deadPlayerIds': deadPlayerIds,
      'votesByVoter': currentDayVotesByVoter,
      'votesByTarget': currentDayVotesByTarget,
      'voteHistory': includeLog
          ? voteHistory.map((v) => v.toJson()).toList(growable: false)
          : const <dynamic>[],
      'voteSequence': _voteSequence,
      'predatorPending': {
        'pendingPredatorId': pendingPredatorId,
        'eligibleVoterIds': pendingPredatorEligibleVoterIds,
        'preferredTargetId': pendingPredatorPreferredTargetId,
      },
      'teaSpillerPending': {
        'pendingTeaSpillerId': pendingTeaSpillerId,
        'eligibleVoterIds': pendingTeaSpillerEligibleVoterIds,
      },
      'dramaQueenPending': {
        'swapPending': dramaQueenSwapPending,
        'markedAId': dramaQueenMarkedAId,
        'markedBId': dramaQueenMarkedBId,
      },
      'statusEffects': statusEffectManager.toJson(),
      'abilityQueue': abilityResolver.toJson(),
      'reactionHistory': reactionSystem.getHistoryJson(),
      if (lastDramaQueenSwap != null)
        'lastDramaQueenSwap': {
          'day': lastDramaQueenSwap!.day,
          'playerAName': lastDramaQueenSwap!.playerAName,
          'playerBName': lastDramaQueenSwap!.playerBName,
          'fromRoleA': lastDramaQueenSwap!.fromRoleA,
          'fromRoleB': lastDramaQueenSwap!.fromRoleB,
          'toRoleA': lastDramaQueenSwap!.toRoleA,
          'toRoleB': lastDramaQueenSwap!.toRoleB,
        },
    };
  }

  /// Load engine state from a save-map (blob format). Does not read prefs.
  Future<void> importSaveBlobMap(
    Map<String, dynamic> map, {
    bool notify = true,
  }) async {
    await _loadFromSaveMap(map);

    // Ensure dead list contains any actually-dead players, but do not discard
    // persisted in-flight state (tests expect this).
    final derivedDead = players
        .where((p) => p.isEnabled && !p.isAlive)
        .map((p) => p.id)
        .toList(growable: false);
    final merged =
        <String>{...deadPlayerIds, ...derivedDead}.toList(growable: true);
    deadPlayerIds = merged;

    // Keep night action keys compatible with engine rules.
    _canonicalizeNightActions();

    if (notify) {
      notifyListeners();
    }
  }

  /// Creates a deep-ish clone suitable for Monte Carlo simulations.
  Future<GameEngine> cloneForSimulation({bool includeLog = false}) async {
    final clone = GameEngine(
      roleRepository: roleRepository,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
      persistenceEnabled: persistenceEnabled,
    );
    await clone.importSaveBlobMap(exportSaveBlobMap(includeLog: includeLog),
        notify: false);
    return clone;
  }

  Future<void> _loadNameHistory() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    nameHistory = prefs.getStringList('player_name_history') ?? [];
    notifyListeners();
  }

  Future<void> _addToHistory(String name) async {
    if (name.isEmpty) return;
    nameHistory.removeWhere((n) => n == name);
    nameHistory.add(name);

    const maxHistory = 200;
    if (nameHistory.length > maxHistory) {
      nameHistory = nameHistory.sublist(nameHistory.length - maxHistory);
    }

    if (persistenceEnabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('player_name_history', nameHistory);
    }
    notifyListeners();
  }

  /// Removes the provided names from the saved name history.
  Future<void> removeNamesFromHistory(List<String> names) async {
    if (names.isEmpty) return;
    nameHistory.removeWhere((n) => names.contains(n));
    if (persistenceEnabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('player_name_history', nameHistory);
    }
    notifyListeners();
  }

  List<Player> get enabledPlayers => players.where((p) => p.isEnabled).toList();
  List<Player> get activePlayers => players.where((p) => p.isActive).toList();

  /// Rule-aware vote tally: only counts votes from eligible voters.
  ///
  /// Defensive by design: the UI should already use [recordVote], which blocks
  /// ineligible voters (e.g., Sober-sent-home), but this protects against any
  /// direct map mutations or stale saved state.
  Map<String, List<String>>? _cachedEligibleVotes;

  void _invalidateEligibleVotesCache() {
    _cachedEligibleVotes = null;
  }

  Map<String, List<String>> get eligibleDayVotesByTarget {
    if (_cachedEligibleVotes != null) {
      return _cachedEligibleVotes!;
    }

    // Optimization: Create a map for O(1) player lookup instead of O(N) search per target.
    // This reduces complexity from O(T*N) to O(N + T).
    final playerMap = {for (var p in players) p.id: p};

    final eligibleVoterIds = players
        .where((p) => p.isAlive && p.isEnabled)
        .where((p) => p.id != hostPlayerId && p.role.id != hostRoleId)
        .where((p) => p.role.id != 'ally_cat')
        .where((p) => !p.soberSentHome)
        .where((p) => p.silencedDay != dayCount)
        .map((p) => p.id)
        .toSet();

    final filtered = <String, List<String>>{};
    for (final entry in currentDayVotesByTarget.entries) {
      final targetId = entry.key;
      final target = playerMap[targetId];
      if (target != null && target.alibiDay == dayCount) {
        // Silver Fox alibi: targets with vote immunity cannot accrue votes today.
        continue;
      }
      final voters = entry.value.where(eligibleVoterIds.contains).toList();
      if (voters.isNotEmpty) {
        filtered[targetId] = voters;
      }
    }

    final result = Map<String, List<String>>.unmodifiable(filtered);
    _cachedEligibleVotes = result;
    return result;
  }

  bool _isVoteImmuneTarget(String targetId) {
    final target = players.where((p) => p.id == targetId).firstOrNull;
    return target != null && target.alibiDay == dayCount;
  }

  // --- Voting telemetry API (safe even if UI never calls it) ---

  void recordVote({
    required String voterId,
    required String? targetId,
  }) {
    // Host is facilitator-only and must never participate in vote math.
    if (voterId == hostPlayerId) return;

    final voter = players.where((p) => p.id == voterId).firstOrNull;
    if (voter == null) return;
    if (voter.role.id == hostRoleId) return;

    if (voter.soberSentHome) {
      logAction('Sober', '${voter.name} is SENT HOME and cannot vote.');
      return;
    }

    // Ally Cat is excluded from day voting.
    if (voter.role.id == 'ally_cat') {
      return;
    }

    if (voter.silencedDay == dayCount) {
      logAction('Roofi', '${voter.name} is SILENCED and cannot vote today.');
      return;
    }

    // Prevent self-voting
    if (targetId == voterId) {
      logAction(
        'Self-Vote Prevention',
        '${voter.name} cannot vote for themselves.',
      );
      return;
    }

    var effectiveTargetId = targetId;
    if (effectiveTargetId != null && _isVoteImmuneTarget(effectiveTargetId)) {
      final target =
          players.where((p) => p.id == effectiveTargetId).firstOrNull;
      if (target != null) {
        logAction('Silver Fox',
            '${target.name} has an ALIBI today and cannot receive votes.');
      }
      effectiveTargetId = null;
    }

    // Remove voter from previous target bucket
    final prev = currentDayVotesByVoter[voterId];
    if (prev != null) {
      if (prev != effectiveTargetId) {
        // Changed vote
        voteChanges.add(VoteCast(
          day: dayCount,
          voterId: voterId,
          targetId: effectiveTargetId,
          timestamp: DateTime.now(),
          sequence: _voteSequence++,
        ));
      }
      currentDayVotesByTarget[prev]?.remove(voterId);
      if (currentDayVotesByTarget[prev]?.isEmpty ?? false) {
        currentDayVotesByTarget.remove(prev);
      }
    }

    currentDayVotesByVoter[voterId] = effectiveTargetId;

    if (effectiveTargetId != null) {
      currentDayVotesByTarget
          .putIfAbsent(effectiveTargetId, () => <String>[])
          .add(voterId);
    }

    voteHistory.add(
      VoteCast(
        day: dayCount,
        voterId: voterId,
        targetId: effectiveTargetId,
        timestamp: DateTime.now(),
        sequence: _voteSequence++,
      ),
    );

    // Clinger mechanic: Clinger must vote exactly as their obsession votes.
    // This is enforced whenever any vote is recorded, so partner vote changes
    // automatically propagate.
    _syncClingerVotesToPartner();
    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  void _syncClingerVotesToPartner() {
    final clingers = players
        .where((p) =>
            p.role.id == 'clinger' &&
            p.isActive &&
            !p.soberSentHome &&
            !p.clingerFreedAsAttackDog &&
            p.clingerPartnerId != null)
        .toList();

    for (final clinger in clingers) {
      final partnerId = clinger.clingerPartnerId;
      if (partnerId == null) continue;

      final partnerVote = currentDayVotesByVoter[partnerId];
      final existing = currentDayVotesByVoter[clinger.id];
      if (existing == partnerVote) continue;

      // This will also write a VoteCast entry (useful for audits/exports) and
      // is idempotent because we only call it when a change is needed.
      recordVote(voterId: clinger.id, targetId: partnerVote);
    }
  }

  /// Host-triggered: mark that the obsession called the Clinger "controller".
  /// This frees the Clinger from heartbreak and enables their one-time Attack Dog kill.
  bool freeClingerFromObsession(String clingerId) {
    final clinger = players.where((p) => p.id == clingerId).firstOrNull;
    if (clinger == null) return false;
    if (!clinger.isActive) return false;
    if (clinger.role.id != 'clinger') return false;
    if (clinger.clingerFreedAsAttackDog) return false;

    final partnerId = clinger.clingerPartnerId;
    final partnerName = partnerId != null
        ? players.where((p) => p.id == partnerId).firstOrNull?.name
        : null;

    clinger.clingerFreedAsAttackDog = true;
    clinger.clingerPartnerId = null;

    logAction(
      'Clinger Freed',
      partnerName != null
          ? '${clinger.name} was called "controller" by $partnerName and is now UNLEASHED (Attack Dog).'
          : '${clinger.name} is now UNLEASHED (Attack Dog).',
    );
    notifyListeners();
    return true;
  }

  /// Back-compat API used by tests.
  void setDayVote({
    required String voterId,
    required String targetId,
  }) {
    recordVote(voterId: voterId, targetId: targetId);
  }

  void clearDayVotes() {
    currentDayVotesByVoter.clear();
    currentDayVotesByTarget.clear();
    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  /// Test helper: populate the engine with a deterministic roster.
  ///
  /// When `fullRoster` is true, adds one player per role in the repository
  /// (excluding placeholder roles). Roles are assigned manually so `startGame`
  /// will not overwrite them.
  Future<void> createTestGame({bool fullRoster = false}) async {
    // Start from a known-clean lobby state so scripts/dayCount/etc are reset.
    resetToLobby(keepGuests: false, keepAssignedRoles: false);

    if (!fullRoster) {
      // Small, practical roster for quick playthroughs.
      final dealer = roleRepository.getRoleById('dealer');
      final party = roleRepository.getRoleById('party_animal');
      final medic = roleRepository.getRoleById('medic');
      final wallflower = roleRepository.getRoleById('wallflower');
      final whore = roleRepository.getRoleById('whore');

      if (dealer != null) addPlayer('Dealer1', role: dealer);
      if (party != null) {
        addPlayer('PA1', role: party);
        addPlayer('PA2', role: party);
      }
      if (medic != null) addPlayer('Medic1', role: medic);
      if (wallflower != null) addPlayer('Wallflower1', role: wallflower);
      if (whore != null) addPlayer('Whore1', role: whore);

      // Defensive fallback: ensure the roster is startable (4+ enabled players).
      if (enabledPlayers.length < 4) {
        final fillers = roleRepository.roles
            .where((r) => r.id != 'temp' && r.id != hostRoleId)
            .toList();
        var i = 1;
        while (enabledPlayers.length < 4 && fillers.isNotEmpty) {
          addPlayer('Guest$i', role: fillers[i % fillers.length]);
          i++;
        }
      }
      return;
    }

    final roles = roleRepository.roles
        .where((r) => r.id != 'temp' && r.id != hostRoleId)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    var i = 1;
    for (final role in roles) {
      // Keep names within InputValidator constraints (no underscores, <= 20 chars)
      addPlayer('Player $i', role: role);
      i++;
    }
  }

  /// Back-compat API used by gameplay scenario tests.
  ///
  /// Returns a simple winner token when the game is over, otherwise null.
  GameEndResult? checkGameEnd() {
    final alive = <Player>[];
    int dealerCount = 0;
    int partyCount = 0;
    bool clubManagerAlive = false;

    Player? messyBitch;
    bool allTargetsHaveRumour = true;

    for (final p in players) {
      if (!p.isEnabled) continue;

      if (p.role.id == 'messy_bitch') {
        messyBitch = p;
      }

      if (p.isAlive) {
        alive.add(p);

        final allianceLower = p.alliance.toLowerCase();
        if (p.role.id == 'dealer' || allianceLower.contains('dealer')) {
          dealerCount++;
        }
        if (allianceLower.contains('party')) {
          partyCount++;
        }
        if (p.role.id == 'club_manager') {
          clubManagerAlive = true;
        }

        if (p.role.id != 'messy_bitch') {
          if (!p.hasRumour) {
            allTargetsHaveRumour = false;
          }
        }
      }
    }

    // Messy Bitch immediate win: rumours have reached every enabled guest.
    if (messyBitch != null && messyBitch.isAlive && allTargetsHaveRumour) {
      markMessyBitchVictoryPending();

      return const GameEndResult(
        winner: 'MESSY_BITCH',
        message: 'Messy Bitch spread a rumour to every player.',
      );
    }

    if (alive.isEmpty) {
      return const GameEndResult(
        winner: 'NONE',
        message: 'No one wins. Everyone is dead.',
      );
    }

    // Party Animals win when all Dealers are dead (and at least one Party Animal remains).
    if (dealerCount == 0 && partyCount > 0) {
      return const GameEndResult(
        winner: 'PARTY_ANIMAL',
        message: 'All Dealers are eliminated.',
      );
    }

    // Special case: Club Manager vs Dealers.
    // Dealers do NOT win at parity if a Club Manager is still alive to maintain order.

    // Dealer win condition:
    // 1. Dealers outnumber or equal Party Animals (control the vote).
    // 2. Exception: Club Manager wins a 1v1 standoff against a Dealer or others.
    if (dealerCount >= partyCount) {
      if (alive.length == 2 && clubManagerAlive) {
        return const GameEndResult(
          winner: 'CLUB_MANAGER',
          message:
              'Final showdown: Club Manager wins the standoff against the Dealer.',
        );
      }

      if (alive.length == 2 && dealerCount == 1 && partyCount == 1) {
        return const GameEndResult(
          winner: 'DEALER',
          message: 'Final showdown: Dealer wins the standoff.',
        );
      }

      // If CM is alive and it's not a 1v1, it might not be over yet (maintaining order).
      if (clubManagerAlive && alive.length > 2) {
        return null;
      }

      // Otherwise, Dealers control the room.
      return const GameEndResult(
        winner: 'DEALER',
        message: 'Dealers have reached parity and control the club.',
      );
    }

    return null;
  }

  bool _isMessyBitchWinConditionMet() {
    final messyBitch = players
        .where((p) => p.isEnabled && p.role.id == 'messy_bitch')
        .firstOrNull;
    if (messyBitch == null) return false;
    if (!messyBitch.isAlive) return false;

    // Rules: wins immediately if every currently living player (besides herself)
    // has heard a rumour.
    final targets = players
        .where((p) => p.isAlive && p.isEnabled)
        .where((p) => p.id != messyBitch.id)
        .toList();

    // Vacuously true if Messy Bitch is the last living player.
    return targets.every((p) => p.hasRumour);
  }

  // --- Roles / Players ---

  List<Role> availableRolesForNewPlayer() {
    final allRoles = roleRepository.roles;

    final partyAnimalRole = allRoles.firstWhere(
      (r) => r.id == 'party_animal',
      orElse: () => Role(
        id: 'missing',
        name: 'Missing Role',
        alliance: 'None',
        type: 'Placeholder',
        description: '',
        nightPriority: 0,
        assetPath: '',
        colorHex: '#FFFFFF',
      ),
    );
    if (partyAnimalRole.id == 'missing') {
      throw StateError(
          'Missing required role: party_animal. Check assets/data/roles.json.');
    }

    final dealerRole = allRoles.firstWhere(
      (r) => r.id == 'dealer',
      orElse: () => Role(
        id: 'missing',
        name: 'Missing Role',
        alliance: 'None',
        type: 'Placeholder',
        description: '',
        nightPriority: 0,
        assetPath: '',
        colorHex: '#FFFFFF',
      ),
    );

    final usedUniqueRoleIds = players
        .map((p) => p.role.id)
        .where((id) => id != 'temp')
        .where((id) => !RoleValidator.multipleAllowedRoles.contains(id))
        .toSet();

    final uniqueAvailable = allRoles
        .where((r) => r.id != 'temp' && r.id != hostRoleId)
        .where((r) => !RoleValidator.multipleAllowedRoles.contains(r.id))
        .where((r) => !usedUniqueRoleIds.contains(r.id))
        .toList();

    final currentEnabled = players.where((p) => p.isEnabled).length;
    final newTotal = currentEnabled + 1;
    final recommendedDealers = RoleValidator.recommendedDealerCount(newTotal);
    final currentDealersAlive = players
        .where((p) => p.isEnabled && p.isAlive && p.role.id == 'dealer')
        .length;
    final canAddDealer =
        dealerRole.id != 'missing' && currentDealersAlive < recommendedDealers;

    final results = <Role>[...uniqueAvailable];
    if (canAddDealer) results.add(dealerRole);

    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  void addPlayer(String name, {Role? role}) {
    GameLogger.debug('Adding player: $name', context: 'GameEngine');

    final validation = InputValidator.validatePlayerName(name);
    if (validation.isInvalid) {
      GameLogger.warning('Invalid player name: ${validation.error}',
          context: 'GameEngine');
      throw ArgumentError(validation.error);
    }

    final sanitizedName = InputValidator.sanitizeString(name);

    if (players
        .any((p) => p.name.toLowerCase() == sanitizedName.toLowerCase())) {
      GameLogger.warning('Duplicate player name: $sanitizedName',
          context: 'GameEngine');
      throw ArgumentError('A player with this name already exists');
    }

    _addToHistory(sanitizedName);
    unawaited(HallOfFameService.instance.registerPlayer(sanitizedName));

    final assignedRole = role ??
        Role(
          id: 'temp',
          name: 'Unassigned',
          alliance: 'None',
          type: 'Placeholder',
          description: 'Role will be assigned when the game starts',
          nightPriority: 0,
          assetPath: '',
          colorHex: '#888888',
        );

    if (assignedRole.id == hostRoleId) {
      throw ArgumentError('Host is not a gameplay player.');
    }

    final player = Player(
      id: '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(10000)}',
      name: sanitizedName,
      role: assignedRole,
    );

    players.add(player);
    GameLogger.info('Player added: ${player.name} as ${assignedRole.name}',
        context: 'GameEngine');
    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  Player addPlayerDuringDay(String name, {Role? role}) {
    if (_currentPhase == GamePhase.lobby) {
      throw StateError('Players can only join after the game has started');
    }

    GameLogger.debug('Adding late joiner: $name', context: 'GameEngine');

    final validation = InputValidator.validatePlayerName(name);
    if (validation.isInvalid) throw ArgumentError(validation.error);

    final sanitizedName = InputValidator.sanitizeString(name);

    if (players
        .any((p) => p.name.toLowerCase() == sanitizedName.toLowerCase())) {
      throw ArgumentError('A player with this name already exists');
    }

    _addToHistory(sanitizedName);
    unawaited(HallOfFameService.instance.registerPlayer(sanitizedName));

    final available = availableRolesForNewPlayer();
    if (available.isEmpty) {
      throw StateError('No roles are available for new players');
    }

    final assignedRole = role != null
        ? (available.any((r) => r.id == role.id)
            ? role
            : throw ArgumentError('Selected role is not available'))
        : available[Random().nextInt(available.length)];

    final player = Player(
      id: '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(10000)}',
      name: sanitizedName,
      role: assignedRole,
      joinsNextNight: true,
    )..initialize();

    players.add(player);
    notifyListeners();
    _invalidateEligibleVotesCache();
    return player;
  }

  void updatePlayerRole(String playerId, Role? newRole) {
    if (newRole == null) return;
    if (!InputValidator.isValidId(playerId)) {
      throw PlayerNotFoundException(playerId);
    }

    final index = players.indexWhere((p) => p.id == playerId);
    if (index == -1) throw PlayerNotFoundException(playerId);

    if (newRole.id == 'bouncer') {
      final existing = players.firstWhere(
        (p) => p.id != playerId && p.role.id == 'bouncer' && p.isEnabled,
        orElse: () => Player(
          id: 'none',
          name: '',
          role: Role(
            id: 'none',
            name: '',
            alliance: '',
            type: '',
            description: '',
            nightPriority: 0,
            assetPath: '',
            colorHex: '#FFFFFF',
          ),
        ),
      );
      if (existing.id != 'none') {
        throw StateError(
            'Only one Bouncer is allowed. ${existing.name} already has this role.');
      }
    }

    players[index].role = newRole;
    players[index].initialize();
    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  /// Clears the entire guest list and all associated session state.
  void clearAllPlayers() {
    players.clear();
    deadPlayerIds.clear();
    currentDayVotesByVoter.clear();
    currentDayVotesByTarget.clear();
    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  void removePlayer(String id) {
    if (!InputValidator.isValidId(id)) throw PlayerNotFoundException(id);

    players.removeWhere((p) => p.id == id);

    // Keep auxiliary state in sync
    deadPlayerIds.remove(id);
    currentDayVotesByVoter.remove(id);
    currentDayVotesByTarget.remove(id);
    currentDayVotesByTarget.forEach((_, voters) => voters.remove(id));

    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  /// Restores a previously removed player (used by Lobby undo).
  ///
  /// Returns false if the restore cannot be applied safely (e.g., a name
  /// collision occurred after removal).
  bool restorePlayer(Player player, {int? index}) {
    final restoredName = player.name.trim();
    if (restoredName.isEmpty) return false;

    final lower = restoredName.toLowerCase();
    final nameCollision =
        players.any((p) => p.name.trim().toLowerCase() == lower);
    if (nameCollision) return false;

    final idCollision = players.any((p) => p.id == player.id);
    if (idCollision) return false;

    var insertIndex = index ?? players.length;
    if (insertIndex < 0) insertIndex = 0;
    if (insertIndex > players.length) insertIndex = players.length;

    players.insert(insertIndex, player);
    notifyListeners();
    _invalidateEligibleVotesCache();
    return true;
  }

  /// Restores a previously cleared roster (used by Lobby undo).
  ///
  /// Returns false if any player name would collide with an existing player.
  bool restoreAllPlayers(List<Player> roster) {
    final normalized = <String>{};
    for (final p in roster) {
      final name = p.name.trim().toLowerCase();
      if (name.isEmpty) return false;
      if (normalized.contains(name)) return false;
      normalized.add(name);
    }

    // If the current roster isn't empty, do not merge; only allow restore into empty.
    if (players.isNotEmpty) return false;

    players.addAll(roster);
    notifyListeners();
    _invalidateEligibleVotesCache();
    return true;
  }

  void renamePlayer(String playerId, String newName) {
    final player = players.firstWhere((p) => p.id == playerId);
    final validation = InputValidator.validatePlayerName(newName);
    if (validation.isInvalid) {
      throw ArgumentError(validation.error);
    }

    final sanitizedName = InputValidator.sanitizeString(newName);

    // If case-insensitive match with self, just update it (case update)
    if (player.name.toLowerCase() == sanitizedName.toLowerCase()) {
      player.name = sanitizedName;
      notifyListeners();
      return;
    }

    if (players
        .any((p) => p.name.toLowerCase() == sanitizedName.toLowerCase())) {
      throw ArgumentError('A player with this name already exists');
    }

    player.name = sanitizedName;
    notifyListeners();
  }

  // --- Game start / scripts ---

  Future<void> startGame() async {
    final enabledGuestPlayers = players.where((p) => p.isEnabled).toList();
    final enabledCount = enabledGuestPlayers.length;

    final validation = InputValidator.validatePlayerCount(enabledCount);
    if (validation.isInvalid) {
      throw InvalidPlayerCountException(enabledCount, 4);
    }

    _assignRoles();

    // Ensure bookkeeping starts clean
    deadPlayerIds = players
        .where((p) => p.isEnabled && !p.isAlive)
        .map((p) => p.id)
        .toList(growable: true);

    _scriptQueue = [
      ...GameScript.intro,
      ...ScriptBuilder.buildNightScript(enabledGuestPlayers, dayCount),
    ];
    _scriptIndex = 0;
    _currentPhase = GamePhase.setup;

    lastNightSummary = '';
    lastNightHostRecap = '';
    lastNightStats.clear();
    _winner = null;
    _winMessage = null;

    // Games Night recording should treat each startGame as a new game boundary.
    GamesNightService.instance.recordGameStarted(this);

    _logCurrentStep();
    notifyListeners();
  }

  void rebuildNightScript() {
    if (_currentPhase != GamePhase.night) return;

    final currentIndex = _scriptIndex;
    final currentStep =
        currentIndex < _scriptQueue.length ? _scriptQueue[currentIndex] : null;
    final newQueue = ScriptBuilder.buildNightScript(players, dayCount);

    if (currentStep != null) {
      final newIndex = newQueue.indexWhere((s) => s.id == currentStep.id);
      if (newIndex != -1) {
        _scriptQueue = newQueue;
        _scriptIndex = newIndex;
      } else {
        int bestMatchNewIndex = 0;
        for (int i = currentIndex - 1; i >= 0; i--) {
          final pastStep = _scriptQueue[i];
          final match = newQueue.indexWhere((s) => s.id == pastStep.id);
          if (match != -1) {
            bestMatchNewIndex = match;
            break;
          }
        }
        _scriptQueue = newQueue;
        _scriptIndex = bestMatchNewIndex;
      }
    } else {
      _scriptQueue = newQueue;
      _scriptIndex = 0;
    }

    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  void advanceScript() {
    _scriptIndex++;
    if (_scriptIndex >= _scriptQueue.length) {
      _loadNextPhaseScript();
    }
    _logCurrentStep();
    notifyListeners();
  }

  void regressScript() {
    if (_scriptIndex > 0) {
      _scriptIndex--;
      notifyListeners();
    }
  }

  void skipToNextPhase() {
    _scriptIndex = _scriptQueue.length;
    _loadNextPhaseScript();
    _logCurrentStep();
    notifyListeners();
  }

  void _logCurrentStep() {
    final step = currentScriptStep;
    if (step == null) return;

    if (_gameLog.isNotEmpty) {
      final last = _gameLog.first;
      final desc = step.readAloudText.isNotEmpty
          ? step.readAloudText
          : step.instructionText;
      if (last.title == step.title && last.description == desc) return;
    }

    logAction(
      step.title,
      step.readAloudText.isNotEmpty ? step.readAloudText : step.instructionText,
      type: GameLogType.script,
    );
  }

  void _loadNextPhaseScript() {
    final oldPhase = _currentPhase;

    if (_currentPhase == GamePhase.setup) {
      _currentPhase = GamePhase.night;
      onPhaseChanged?.call(oldPhase, _currentPhase);

      // Archive setup night actions if any (rare, but setup choices exist)
      nightHistory.add(Map<String, dynamic>.from(nightActions));
      nightActions.clear();
      _abilityTargets.clear();
      abilityResolver.clear();

      for (final p in players) {
        p.soberSentHome = false;
      }

      dayCount++;

      for (final p in players.where((p) => p.joinsNextNight)) {
        p.joinsNextNight = false;
        p.initialize();
      }

      reactionSystem.triggerEvent(
          GameEvent(type: GameEventType.nightPhaseStart), players);
      statusEffectManager.updateEffects();

      _scriptQueue = ScriptBuilder.buildNightScript(players, dayCount);
      _scriptIndex = 0;
      _invalidateEligibleVotesCache();
      return;
    }

    if (_currentPhase == GamePhase.night) {
      _currentPhase = GamePhase.day;
      onPhaseChanged?.call(oldPhase, _currentPhase);

      // Resolve deaths/results BEFORE clearing actions
      final announcement = _resolveNightPhase();

      // Sober immunity should win, regardless of script ordering.
      // If Roofi targeted someone who was sent home this night, ensure the
      // paralysis/dealer-block flags do not persist into the Day.
      final soberTargetId = nightActions['sober_sent_home'] as String?;
      final roofiTargetId = nightActions['roofi'] as String?;
      if (soberTargetId != null && roofiTargetId == soberTargetId) {
        final target = players.where((p) => p.id == soberTargetId).firstOrNull;
        if (target != null) {
          target.silencedDay = null;
          target.blockedKillNight = null;
        }
      }

      // Archive Night N actions
      nightHistory.add(Map<String, dynamic>.from(nightActions));
      nightActions.clear();
      _abilityTargets.clear();
      abilityResolver.clear();

      _dayphaseVotesMade = false;
      clearDayVotes();

      final dayQueue =
          ScriptBuilder.buildDayScript(dayCount, announcement, players);

      // Second Wind conversion choice is a NEXT-NIGHT decision (after the day + vote).
      // Do not inject anything into the Day script.
      _scriptQueue = dayQueue;
      _scriptIndex = 0;
      dayCount++;
      _invalidateEligibleVotesCache();
      return;
    }

    if (_currentPhase == GamePhase.day) {
      if (!_dayphaseVotesMade) {
        logAction('No Vote Cast',
            'Time ran out without a vote being called. No one was eliminated.');
      }

      _currentPhase = GamePhase.night;
      onPhaseChanged?.call(oldPhase, _currentPhase);

      for (final p in players) {
        p.soberSentHome = false;
      }

      // Silver Fox: alibi lasts only for the day/vote round.
      // We clear it when the Day phase ends so it doesn't linger into the Night.
      for (final p in players) {
        if (p.alibiDay == dayCount) {
          p.alibiDay = null;
        }
      }

      for (final p in players.where((p) => p.joinsNextNight)) {
        p.joinsNextNight = false;
        p.initialize();
      }

      reactionSystem.triggerEvent(
          GameEvent(type: GameEventType.nightPhaseStart), players);
      statusEffectManager.updateEffects();

      var nightQueue = ScriptBuilder.buildNightScript(players, dayCount);

      // If Second Wind was killed by Dealers on the previous night, the Dealers may
      // choose TONIGHT to convert them (forfeiting their kill) or proceed with a kill.
      final hasPendingSecondWindThisNight = players.any(
        (p) =>
            p.isEnabled &&
            p.role.id == 'second_wind' &&
            p.secondWindPendingConversion &&
            !p.secondWindConverted &&
            !p.secondWindRefusedConversion &&
            p.secondWindConversionNight == dayCount,
      );

      if (hasPendingSecondWindThisNight) {
        final insertBefore = nightQueue.indexWhere((s) => s.id == 'dealer_act');
        if (insertBefore != -1) {
          nightQueue = <ScriptStep>[
            ...nightQueue.take(insertBefore),
            const ScriptStep(
              id: 'second_wind_conversion_choice',
              title: 'Second Wind (Host Only)',
              readAloudText: '',
              instructionText:
                  'Host only (do not read aloud): The Dealers killed the Second Wind last night.\n\nTonight, choose:\n\nCONVERT â€” revive them as a Dealer (Dealers forfeit their kill tonight).\nKILL â€” do not convert; proceed with a normal Dealer kill tonight.',
              actionType: ScriptActionType.binaryChoice,
              roleId: 'dealer',
              isNight: true,
              optionLabels: ['CONVERT', 'KILL'],
            ),
            ...nightQueue.skip(insertBefore),
          ];
        }
      }

      _scriptQueue = nightQueue;
      _scriptIndex = 0;
      _invalidateEligibleVotesCache();
    }
  }

  // --- Death handling ---

  void processDeath(Player victim, {String cause = 'unknown'}) {
    if (!victim.isAlive) return;

    final causeLower = cause.toLowerCase();

    // Sober: sent-home players cannot be killed by night murders.
    // Also, when a Dealer is sent home, guest murders are cancelled.
    final noDealersActiveTonight = nightActions['no_murders_tonight'] == true;
    final isDealerKillAttempt = causeLower == 'night_kill' ||
        causeLower == 'dealer_kill' ||
        causeLower == 'night_kill_special';
    final isClingerKill = causeLower == 'clinger_attack_dog';

    // Rule: Sent-home players are safe from ALL night murders.
    if ((isDealerKillAttempt || isClingerKill) && victim.soberSentHome) {
      logAction(
        'Sober',
        '${victim.name} would have died, but was sent home by The Sober.',
      );
      return;
    }

    // Rule: If a Dealer was sent home, Dealer-specific murders are cancelled.
    if (isDealerKillAttempt && noDealersActiveTonight) {
      logAction(
        'Sober',
        '${victim.name} would have died, but a Dealer was sent home â€” Dealer murders cancelled.',
      );
      return;
    }

    // Second Wind should only intercept Dealer-kill attempts (per rules).

    // Minor: cannot die to Dealer kill attempts until ID'd by the Bouncer.
    if (victim.role.id == 'minor' &&
        isDealerKillAttempt &&
        !victim.minorHasBeenIDd) {
      logAction('Minor',
          '${victim.name} is The Minor and cannot be killed by the Dealers until IDâ€™d by the Bouncer.');
      notifyListeners();
      return;
    }

    // Second Wind: When killed by a Dealer kill attempt, they can be converted
    // on the FOLLOWING night (Dealers must forfeit that night's kill).
    if (victim.role.id == 'second_wind' &&
        isDealerKillAttempt &&
        !victim.secondWindConverted &&
        !victim.secondWindRefusedConversion) {
      victim.secondWindPendingConversion = true;

      // Conversion choice is available on the next night.
      victim.secondWindConversionNight = dayCount + 1;

      logAction(
        'Second Wind',
        '${victim.name} was killed by the Dealers. Conversion choice will be available next night.',
      );
    }

    // If the host explicitly refused conversion, allow the kill to proceed.
    if (victim.role.id == 'second_wind' && causeLower.contains('refus')) {
      victim.secondWindRefusedConversion = true;
      victim.secondWindPendingConversion = false;
    }

    if (_absorbDeathWithLives(victim, cause)) {
      notifyListeners();
      return;
    }

    final deathEvent = GameEvent(
      type: GameEventType.playerDied,
      sourcePlayerId: victim.id,
      data: {'cause': cause},
    );
    final reactions = reactionSystem.triggerEvent(deathEvent, players);
    _processDeathReactions(victim, reactions);

    victim.die(dayCount, cause);
    if (!deadPlayerIds.contains(victim.id)) {
      deadPlayerIds.add(victim.id);
    }

    logAction(
        'Death', '${victim.name} (${victim.role.name}) died. Cause: $cause');

    _handleCreepInheritance(victim);
    _handleClingerObsessionDeath(victim);

    // Clear medic protection if medic dies
    if (victim.role.id == 'medic') {
      victim.medicProtectedPlayerId = null;
      logAction('Medic Protection', 'Medic protection cleared (medic died).');
    }

    notifyListeners();
  }

  /// Lightweight: if they speak a taboo name, they die immediately.
  ///
  /// This is a real-world speech rule, so the host triggers it explicitly.
  void markLightweightTabooViolation(
      {String? tabooName, String? lightweightId}) {
    Player? lightweight;

    if (lightweightId != null) {
      lightweight = players.where((p) => p.id == lightweightId).firstOrNull;
      if (lightweight == null) {
        logAction('Taboo Violation', 'No player found for id=$lightweightId.');
        return;
      }
    } else {
      final livingLightweights = players
          .where((p) => p.isAlive && p.role.id == 'lightweight')
          .toList();

      if (livingLightweights.isEmpty) {
        logAction('Taboo Violation', 'No alive Lightweight in game.');
        return;
      }
      if (livingLightweights.length > 1) {
        logAction('Taboo Violation',
            'Multiple Lightweights are alive; specify which one violated the taboo.');
        return;
      }
      lightweight = livingLightweights.first;
    }

    if (!lightweight.isAlive) {
      logAction('Taboo Violation', '${lightweight.name} is already dead.');
      return;
    }

    final cleaned = tabooName?.trim();
    final detail =
        (cleaned != null && cleaned.isNotEmpty) ? ' ("$cleaned")' : '';
    logAction('Taboo Violation',
        '${lightweight.name} spoke a taboo name$detail and dies immediately.');
    processDeath(lightweight, cause: DeathCause.spokeTabooName);
  }

  bool _absorbDeathWithLives(Player victim, String cause) {
    if (victim.role.id == 'ally_cat') {
      victim.lives = (victim.lives - 1).clamp(0, 999);
      if (victim.lives > 0) {
        final isVote = cause.toLowerCase().contains('vote');
        logAction('Nine Lives',
            '${victim.name} survived ${isVote ? "the vote" : "death"}. Lives left: ${victim.lives}.');
        return true;
      }
      return false;
    }

    final causeLower = cause.toLowerCase();
    final isDealerKillAttempt = causeLower == 'night_kill' ||
        causeLower == 'dealer_kill' ||
        causeLower == 'night_kill_special';
    if (victim.role.id == 'seasoned_drinker' && isDealerKillAttempt) {
      victim.lives = (victim.lives - 1).clamp(0, 999);
      if (victim.lives > 0) {
        logAction('Seasoned Drinker',
            '${victim.name} burned a life against the Dealers. Lives left: ${victim.lives}.');
        return true;
      }
      return false;
    }

    return false;
  }

  // --- Night resolution (kept compatible with your existing UI expectations) ---
  String _resolveNightPhase({bool buildMorningReports = true}) {
    // Canonicalize actions (keep for specific edge cases or remove?)
    // _canonicalizeNightActions(); 
    
    if (players.isEmpty) return 'No players in game state; night resolution skipped.';

    _clingerDoubleDeaths.clear();
    lastNightStats..clear()..addAll({'killed': 0, 'saved': 0, 'silenced': 0});

    // 1. Resolve Ability Queue
    final results = abilityResolver.resolveAllAbilities(players);

    // 2. Apply Effects
    final killedIds = <String>[];
    final protectedIds = <String>[]; 
    final silencedIds = <String>[];
    
    for (final result in results) {
       for (final targetId in result.targets) {
           final target = players.firstWhere((p) => p.id == targetId, orElse: () => Player(
             id: '?',
             name: '?',
             role: Role(
               id: '?',
               name: 'Unknown',
               alliance: '?',
               type: '?',
               description: '',
               nightPriority: 0,
               assetPath: '',
               colorHex: '#000000',
             ),
             isAlive: true, isEnabled: false));
           if (target.id == '?') continue;

           switch (result.abilityId) {
               case 'dealer_kill':
               case 'clinger_kill':
                   if (result.success) {
                       processDeath(target, cause: result.abilityId);
                       killedIds.add(targetId);
                       lastNightStats['killed'] = (lastNightStats['killed'] ?? 0) + 1;
                   }
                   break;
               
               case 'roofi_silence':
                   if (result.success) {
                       target.silencedDay = dayCount + 1;
                       if (target.role.id == 'dealer') {
                           target.blockedKillNight = dayCount + 1;
                       }
                       silencedIds.add(targetId);
                       lastNightStats['silenced'] = (lastNightStats['silenced'] ?? 0) + 1;
                   }
                   break;

               case 'messy_bitch_rumour':
                   target.hasRumour = true;
                   break;

               case 'sober_send_home':
                   target.soberSentHome = true;
                   break;
                
               case 'medic_revive':
                   // Revive logic
                   if (!target.isAlive && target.deathDay == dayCount) {
                       target.isAlive = true;
                       target.deathDay = null; 
                       target.deathReason = null;
                       deadPlayerIds.remove(target.id);
                       
                       // Mark revive used
                       // Retrieve source from helper or assume logic works
                       final medics = players.where((p)=>p.role.id=='medic');
                       for (final m in medics) {
                           // If m targeted target with revive...
                           // Or simpler: just mark all active medics who chose revive as used.
                           if (m.medicChoice=='REVIVE') m.reviveUsed=true;
                       }
                   }
                   break;
           }
       }
       
       if (result.metadata.containsKey('protected')) {
           protectedIds.addAll((result.metadata['protected'] as List).cast<String>());
           lastNightStats['saved'] = (lastNightStats['saved'] ?? 0) + 1;
       }
    }

    // 3. Generate Report
    final sb = StringBuffer()..writeln('Good Morning, Clubbers!\nHere is what went down last night:\n');
    bool quiet = true;

    // Sober
    for (final res in results.where((r) => r.abilityId == 'sober_send_home')) {
        for (final t in res.targets) {
             final name = players.firstWhere((p)=>p.id==t).name;
             sb.writeln('â€¢ $name was sent home early.');
             quiet = false;
        }
    }
    
    // Silenced
    if (silencedIds.isNotEmpty) {
        final names = silencedIds.map((id) => players.firstWhere((p)=>p.id==id).name).join(', ');
        sb.writeln('â€¢ Silenced today: $names.');
        quiet = false;
    }

    // Saved
    for (final pId in protectedIds) {
        final name = players.firstWhere((p)=>p.id==pId).name;
        sb.writeln('â€¢ $name was attacked, but survived.');
        quiet = false;
    }
    
    // Killed
    for (final kId in killedIds) {
        final name = players.firstWhere((p)=>p.id==kId).name;
        sb.writeln('â€¢ $name was found dead.');
        quiet = false;
    }
    
    // Clinger
    if (_clingerDoubleDeaths.isNotEmpty) {
      for (final death in _clingerDoubleDeaths) {
        sb.writeln("â€¢ ${death['clinger']} died of a broken heart!");
        quiet = false;
      }
    }
    
    if (quiet) {
        sb.writeln('â€¢ Surprisingly... nothing happened. It was a quiet night.');
    }

    final summary = sb.toString();
    if (buildMorningReports) {
        lastNightSummary = summary;
        lastNightHostRecap = summary; 
    }
    
    return summary;
  }


  bool voteOutPlayer(String playerId) {
    if (players.isEmpty) {
      logAction('Vote Error', 'No players available for voting.');
      return false;
    }

    _dayphaseVotesMade = true;

    final votedOutPlayer = players.where((p) => p.id == playerId).firstOrNull;
    if (votedOutPlayer == null) {
      logAction('Vote Error', 'Player with ID $playerId not found for voting.');
      return false;
    }

    if (votedOutPlayer.alibiDay == dayCount) {
      logAction(
        'Silver Fox',
        '${votedOutPlayer.name} has an ALIBI today and cannot be voted out.',
      );
      return false;
    }

    // Whore: vote deflection (only triggers when Dealer or Whore is voted out).
    if (votedOutPlayer.isAlive &&
        (votedOutPlayer.role.id == 'dealer' ||
            votedOutPlayer.role.id == 'whore')) {
      final whore =
          players.where((p) => p.role.id == 'whore' && p.isActive).firstOrNull;
      final deflectTargetId = whore?.whoreDeflectionTargetId;
      if (whore != null && deflectTargetId != null) {
        final target =
            players.where((p) => p.id == deflectTargetId).firstOrNull;
        if (target != null && target.isAlive) {
          whore.whoreDeflectionTargetId = null;
          whore.whoreDeflectionUsed = true; // Mark as used
          logAction('Vote Deflection',
              '${whore.name} deflected the vote from ${votedOutPlayer.name} to ${target.name}.');
          processDeath(target, cause: 'vote_deflection');
          return false;
        }
      }
    }

    // Predator: capture eligible voters at the moment of elimination.
    if (votedOutPlayer.role.id == 'predator') {
      pendingPredatorId = votedOutPlayer.id;
      // Capture voters from the raw vote map to avoid edge cases where
      // eligibility filters (sent-home / silenced) would prevent retaliation.
      // The engine will still validate the final retaliation target.
      pendingPredatorEligibleVoterIds = List<String>.from(
        currentDayVotesByTarget[votedOutPlayer.id] ?? const <String>[],
        growable: true,
      );

      // Prefer the marked target (if any), even if they weren't eligible to vote
      // (e.g., driven home / paralyzed). This keeps retaliation usable.
      final markedId = votedOutPlayer.predatorTargetId ??
          (nightActions['predator_mark'] as String?);
      if (markedId != null) {
        final markedPlayer = players.where((p) => p.id == markedId).firstOrNull;
        if (markedPlayer != null &&
            markedPlayer.isAlive &&
            markedPlayer.id != votedOutPlayer.id) {
          pendingPredatorPreferredTargetId = markedPlayer.id;
        } else {
          pendingPredatorPreferredTargetId = null;
        }
      } else {
        pendingPredatorPreferredTargetId = null;
      }

      queueHostAlert(
        title: 'Predator Retaliation',
        message:
            '${votedOutPlayer.name} was voted out. Resolve their retaliation in Host Overview â†’ Pending actions.',
      );
    }

    processDeath(votedOutPlayer, cause: 'vote');
    return votedOutPlayer.role.id == 'dealer';
  }

  // --- Reactions ---

  void _processDeathReactions(Player victim, List<PendingReaction> reactions) {
    for (final reaction in reactions) {
      if (reaction.ability.id == 'drama_queen_swap') {
        _handleDramaQueenSwap(reaction);
      } else if (reaction.ability.id == 'tea_spiller_reveal') {
        _handleTeaSpillerReveal(reaction);
      }
    }
  }

  void _handleDramaQueenSwap(PendingReaction reaction) {
    dramaQueenSwapPending = true;
    dramaQueenMarkedAId ??= nightActions['drama_swap_a'] as String?;
    dramaQueenMarkedBId ??= nightActions['drama_swap_b'] as String?;

    final aName = dramaQueenMarkedAId != null
        ? players
            .firstWhere((p) => p.id == dramaQueenMarkedAId,
                orElse: () => reaction.sourcePlayer)
            .name
        : null;
    final bName = dramaQueenMarkedBId != null
        ? players
            .firstWhere((p) => p.id == dramaQueenMarkedBId,
                orElse: () => reaction.sourcePlayer)
            .name
        : null;

    final pendingLine = (aName != null && bName != null)
        ? 'Marked pair: $aName â†” $bName.'
        : 'No marked pair. Host must choose two players.';

    logAction(
      "Drama Queen's Final Act",
      '${reaction.sourcePlayer.name} died. Open the action menu to swap two players. $pendingLine',
    );
    notifyListeners();
  }

  DramaQueenSwapRecord? completeDramaQueenSwap(Player playerA, Player playerB) {
    try {
      final roleA = playerA.role;
      final roleB = playerB.role;

      final fromRoleA = roleA.name;
      final fromRoleB = roleB.name;

      playerA.role = roleB;
      playerB.role = roleA;
      _resetPlayerStateForNewRole(playerA);
      _resetPlayerStateForNewRole(playerB);

      final record = DramaQueenSwapRecord(
        day: dayCount,
        playerAName: playerA.name,
        playerBName: playerB.name,
        fromRoleA: fromRoleA,
        fromRoleB: fromRoleB,
        toRoleA: playerA.role.name,
        toRoleB: playerB.role.name,
      );

      lastDramaQueenSwap = record;
      dramaQueenSwapPending = false;
      dramaQueenMarkedAId = null;
      dramaQueenMarkedBId = null;

      logAction(
        'Drama Queen Swap',
        'Swapped ${record.playerAName} (${record.fromRoleA} â†’ ${record.toRoleA}) with ${record.playerBName} (${record.fromRoleB} â†’ ${record.toRoleB}).',
      );
      notifyListeners();
      return record;
    } catch (e) {
      debugPrint('Error completing Drama Queen swap: $e');
      return null;
    }
  }

  void _resetPlayerStateForNewRole(Player player) {
    player.initialize();
    player.lives = 1;
    player.setLivesBasedOnDealers(players
        .where((p) => p.role.id == 'dealer' && p.isEnabled && p.isAlive)
        .length);

    // ...reset all role-state flags...
    player.idCheckedByBouncer = false;
    player.medicChoice = null;
    player.reviveUsed = false;
    player.creepTargetId = null;
    player.hasRumour = false;
    player.messyBitchKillUsed = false;
    player.clingerPartnerId = null;
    player.clingerFreedAsAttackDog = false;
    player.clingerAttackDogUsed = false;
    player.teaSpillerMarkId = null;
    player.predatorTargetId = null;
    player.tabooNames = [];
    player.minorHasBeenIDd = false;
    player.soberAbilityUsed = false;
    player.soberSentHome = false;
    player.silverFoxAbilityUsed = false;
    player.alibiDay = null;
    player.secondWindConverted = false;
    player.secondWindPendingConversion = false;
    player.secondWindRefusedConversion = false;
    player.secondWindConversionNight = null;
    player.joinsNextNight = false;
    player.deathDay = null;
    player.silencedDay = null;
    player.blockedKillNight = null;
    player.roofiAbilityRevoked = false;
    player.bouncerAbilityRevoked = false;
    player.bouncerHasRoofiAbility = false;
    player.whoreDeflectionTargetId = null;
    player.whoreDeflectionUsed = false;
    player.deathReason = null;

    // Check if new role requires setup
    if (['clinger', 'creep', 'medic', 'whore'].contains(player.role.id)) {
      player.needsSetup = true;
    }
  }

  void _handleTeaSpillerReveal(PendingReaction reaction) {
    // Spec: triggers only when eliminated by vote, and can only target voters.
    final rawCause = reaction.triggeringEvent.data['cause'];
    final cause = rawCause is String ? rawCause.toLowerCase() : '';
    final isVoteElimination = cause == 'vote' || cause == 'voted_out';
    if (!isVoteElimination) return;

    if (pendingTeaSpillerId != null) return;

    final teaId = reaction.sourcePlayer.id;
    pendingTeaSpillerId = teaId;
    pendingTeaSpillerEligibleVoterIds = List<String>.from(
      eligibleDayVotesByTarget[teaId] ?? const <String>[],
      growable: true,
    );

    // Clean up any legacy mark so old saves don't show stale chips.
    reaction.sourcePlayer.teaSpillerMarkId = null;
    nightActions.remove('tea_spiller_mark');

    if (pendingTeaSpillerEligibleVoterIds.isEmpty) {
      logAction(
        'Tea Spiller',
        '${reaction.sourcePlayer.name} was eliminated by vote, but had no eligible voters to target.',
      );
      clearPendingTeaSpillerReveal(notify: false);
      return;
    }

    logAction(
      'Tea Spiller',
      '${reaction.sourcePlayer.name} was eliminated by vote. Hand the screen to them to choose 1 of their voters to expose.',
    );
    notifyListeners();
  }

  void clearPendingTeaSpillerReveal({String? reason, bool notify = true}) {
    if (pendingTeaSpillerId == null &&
        pendingTeaSpillerEligibleVoterIds.isEmpty) {
      return;
    }

    final teaId = pendingTeaSpillerId;
    pendingTeaSpillerId = null;
    pendingTeaSpillerEligibleVoterIds = <String>[];

    if (reason != null) {
      logAction(
        'Tea Spiller',
        teaId == null
            ? 'Cleared pending Tea Spiller reveal ($reason).'
            : 'Cleared pending Tea Spiller reveal for $teaId ($reason).',
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool completeTeaSpillerReveal(String targetId) {
    final teaId = pendingTeaSpillerId;
    if (teaId == null) return false;

    final tea = players.where((p) => p.id == teaId).firstOrNull;
    if (tea == null) {
      clearPendingTeaSpillerReveal(reason: 'source player missing');
      return false;
    }

    final target = players.where((p) => p.id == targetId).firstOrNull;
    if (target == null || target.role.id == hostRoleId) return false;
    if (target.id == teaId) return false;

    if (!pendingTeaSpillerEligibleVoterIds.contains(targetId)) {
      return false;
    }

    clearPendingTeaSpillerReveal(notify: false);

    // Emit a reveal event so any future reaction logic can hook into this.
    reactionSystem.triggerEvent(
      GameEvent(
        type: GameEventType.roleRevealed,
        sourcePlayerId: teaId,
        targetPlayerId: targetId,
        data: const {'reason': 'tea_spiller'},
      ),
      players,
    );

    logAction(
      'Tea Spilled!',
      '${tea.name} exposed ${target.name} as ${target.role.name}.',
    );
    notifyListeners();
    return true;
  }

  void _handleCreepInheritance(Player victim) {
    try {
      final creeps = players
          .where((p) =>
              p.role.id == 'creep' &&
              p.isActive &&
              p.creepTargetId == victim.id)
          .toList();
      for (final creep in creeps) {
        logAction('Creep Inheritance',
            '${creep.name} inherited ${victim.role.name} from ${victim.name}');
        creep.role = victim.role;
        _resetPlayerStateForNewRole(creep);

        // Whore deflection should never transfer to a new holder.
        if (victim.role.id == 'whore') {
          creep.whoreDeflectionTargetId = null;
          creep.whoreDeflectionUsed = false;
          nightActions.remove('whore_deflect');
        }

        creep.alliance = victim.alliance;
      }
    } catch (_) {}
  }

  void _handleClingerObsessionDeath(Player victim) {
    try {
      final clingers = players
          .where((p) =>
              p.role.id == 'clinger' &&
              p.isActive &&
              p.clingerPartnerId == victim.id &&
              !p.clingerFreedAsAttackDog)
          .toList();
      for (final clinger in clingers) {
        logAction(
          'DOUBLE DEATH',
          "OBSESSION OVER! ${clinger.name} (The Clinger) couldn't live without ${victim.name} and has died of a broken heart!",
        );

        processDeath(clinger, cause: 'clinger_heartbreak');

        _clingerDoubleDeaths
            .add({'clinger': clinger.name, 'obsession': victim.name});
        onClingerDoubleDeath?.call(clinger.name, victim.name);
      }
    } catch (_) {}
  }

  // --- Role assignment ---

  void _assignRoles() {
    final eligiblePlayers = players.where((p) => p.isEnabled).toList();
    if (eligiblePlayers.isEmpty) return;

    final random = Random();
    final dealerRole = roleRepository.getRoleById('dealer');
    if (dealerRole == null) {
      throw StateError('Dealer role is missing from the role repository.');
    }

    final partyAnimalRole = roleRepository.getRoleById('party_animal');
    final medicRole = roleRepository.getRoleById('medic');
    final bouncerRole = roleRepository.getRoleById('bouncer');

    final manualPlayers =
        eligiblePlayers.where((p) => p.role.id != 'temp').toList();
    final autoPlayers =
        eligiblePlayers.where((p) => p.role.id == 'temp').toList();

    final usedUniqueRoleIds = <String>{};
    var manualDealerCount = 0;

    for (final p in manualPlayers) {
      if (p.role.id == 'dealer') {
        manualDealerCount++;
      } else if (p.role.id != 'party_animal' &&
          !RoleValidator.multipleAllowedRoles.contains(p.role.id)) {
        if (!usedUniqueRoleIds.add(p.role.id)) {
          throw StateError(
              'Duplicate role detected: ${p.role.id}. Only Dealers and Party Animals can repeat.');
        }
      }
      p.initialize();
    }

    if (autoPlayers.isNotEmpty) {
      final deck = <Role>[];

      final recommendedDealers =
          RoleValidator.recommendedDealerCount(eligiblePlayers.length);
      final dealersToAssign =
          (recommendedDealers - manualDealerCount).clamp(0, autoPlayers.length);
      for (var i = 0; i < dealersToAssign; i++) {
        deck.add(dealerRole);
      }

      void addRequired(Role? role) {
        if (role == null) return;
        if (role.id == 'dealer') return;
        if (usedUniqueRoleIds.contains(role.id)) return;
        if (deck.length >= autoPlayers.length) return;
        usedUniqueRoleIds.add(role.id);
        deck.add(role);
      }

      addRequired(partyAnimalRole);
      if (!usedUniqueRoleIds.contains('medic') &&
          !usedUniqueRoleIds.contains('bouncer')) {
        addRequired(medicRole ?? bouncerRole);
      }

      final candidates = roleRepository.roles
          .where(
              (r) => r.id != 'dealer' && r.id != 'temp' && r.id != hostRoleId)
          .where((r) => !usedUniqueRoleIds.contains(r.id))
          .toList()
        ..shuffle(random);

      for (final r in candidates) {
        if (deck.length >= autoPlayers.length) break;
        usedUniqueRoleIds.add(r.id);
        deck.add(r);
      }

      if (deck.length < autoPlayers.length) {
        throw StateError(
            'Not enough unique roles to assign ${autoPlayers.length} player(s).');
      }

      deck.shuffle(random);
      for (var i = 0; i < autoPlayers.length; i++) {
        autoPlayers[i].role = deck[i];
        autoPlayers[i].initialize();
      }
    }

    final dealerCount =
        eligiblePlayers.where((p) => p.role.id == 'dealer').length;
    for (final p in eligiblePlayers) {
      p.setLivesBasedOnDealers(dealerCount);
    }
  }

  // --- Logging ---

  void logAction(String title, String description,
      {GameLogType type = GameLogType.action, bool toast = false}) {
    if (silent) return;

    final entry = GameLogEntry(
      turn: dayCount,
      phase: _currentPhase.name.toUpperCase(),
      title: title,
      description: description,
      timestamp: DateTime.now(),
      type: type,
    );

    _gameLog.insert(0, entry);

    // Games Night session recorder (no-op unless active).
    GamesNightService.instance.recordLogEntry(entry);

    // Optional UI toast for script actions (kept non-blocking).
    if (toast) {
      final trimmed = description.trim();
      final lower = trimmed.toLowerCase();
      final isTrivial = lower == 'acknowledged.' ||
          lower == 'skipped.' ||
          lower == 'no selection made.';
      if (trimmed.isNotEmpty && !isTrivial) {
        _queueToast(title: title, message: trimmed);
      }
    }

    notifyListeners();
  }

  // --- Script actions ---

  void queueMedicSelfRevive() {
    final medic = players
        .where((p) => p.role.id == 'medic' && deadPlayerIds.contains(p.id))
        .firstOrNull;
    if (medic == null) {
      throw const ValidationException('No dead Medic found to self-revive.');
    }

    final medicChoseRevive =
        (medic.medicChoice ?? '').toUpperCase() == 'REVIVE';
    final eligible =
        medicChoseRevive && !medic.reviveUsed && medic.deathDay == dayCount;
    if (!eligible) {
      throw const ValidationException(
          'Medic self-revive is not available right now.');
    }

    // Self-revive is a special-case (allowed even though Medic cannot normally
    // target themselves through the standard Medic step).
    nightActions['medic_revive'] = medic.id;
    logAction('Medic Revive', 'Medic queued a self-revive attempt for dawn.');
    notifyListeners();
  }
  // --- Helper for Night Logic Refactor ---
  bool _isSoberSentHome(String targetId) {
    return abilityResolver.isTargetedBy('sober_send_home', targetId);
  }

  void handleScriptAction(ScriptStep step, List<String> selectedPlayerIds) {
    if (selectedPlayerIds.isEmpty) {
      switch (step.actionType) {
        case ScriptActionType.none:
        case ScriptActionType.showInfo:
        case ScriptActionType.info:
        case ScriptActionType.showTimer:
        case ScriptActionType.showDayScene:
        case ScriptActionType.phaseTransition:
        case ScriptActionType.discussion:
          logAction(step.title, 'Acknowledged.');
          return;
        case ScriptActionType.optional:
          logAction(step.title, 'Skipped.');
          return;
        default:
          logAction(step.title, 'No selection made.');
          return;
      }
    }

    final selections = selectedPlayerIds.toList();
    final roleId = step.roleId;
    if (roleId == null) {
      logAction(step.title, 'Step has no roleId; selection ignored.');
      return;
    }

    Player resolvePlayer(String id) {
      if (id == hostPlayerId) {
        return Player(
            id: hostPlayerId,
            name: hostDisplayName,
            role: Role(
                id: hostRoleId,
                name: 'The Host',
                alliance: 'Host',
                type: 'meta',
                description: 'Facilitator / game master.',
                nightPriority: 0,
                assetPath: '',
                colorHex: '#B0B0B0'),
            isAlive: true,
            isEnabled: false);
      }
      return players.firstWhere(
        (p) => p.id == id,
        orElse: () => Player(
            id: '?',
            name: 'Unknown',
            role: Role(
                id: '?',
                name: 'Unknown',
                alliance: '?',
                type: '?',
                description: '',
                nightPriority: 0,
                assetPath: '',
                colorHex: '#FFFFFF'),
            isAlive: true,
            isEnabled: false),
      );
    }
    
    // Find source player
    Player? sourcePlayer;
    try {
      sourcePlayer = players.firstWhere((p) => p.role.id == roleId && p.isActive);
    } catch (_) {}

    if (sourcePlayer != null) {
      // Clear previous actions for this source to allow re-selection (Undo/Redo support)
      abilityResolver.removeAbilitiesForSource(sourcePlayer.id);

      if (_isSoberSentHome(sourcePlayer.id)) {
        logAction(step.title, '${sourcePlayer.name} is SENT HOME and cannot act.');
        return;
      }
      if (sourcePlayer.silencedDay != null) {
         final s = sourcePlayer.silencedDay!;
         if ((_currentPhase == GamePhase.day && s == dayCount) || (_currentPhase == GamePhase.night && s == dayCount + 1)) {
            logAction(step.title, '${sourcePlayer.name} is PARALYZED (Roofi) and cannot act.');
            return;
         }
      }
    }

    bool? parseBinaryChoice(String raw) {
      final v = raw.trim().toLowerCase();
      if (['true','yes','y','1'].contains(v)) return true;
      if (['false','no','n','0'].contains(v)) return false;
      return null;
    }

    // Legacy Second Wind Support
    void applySecondWindDecision({required bool convert, required String sourceTitle}) {
      final secondWind = players
          .where((p) =>
              p.role.id == 'second_wind' && p.secondWindPendingConversion)
          .firstOrNull;
      if (secondWind == null) {
        logAction(sourceTitle, 'No pending Second Wind conversion found.');
        return;
      }

      if (convert) {
        secondWind.secondWindConverted = true;
        secondWind.secondWindPendingConversion = false;
        secondWind.secondWindRefusedConversion = false;
        secondWind.secondWindConversionNight = null;

        final dealerRole = roleRepository.getRoleById('dealer');
        if (dealerRole != null) {
          secondWind.role = dealerRole;
          secondWind.alliance = dealerRole.alliance;
        }

        logAction(
            sourceTitle, '${secondWind.name} was converted into a Dealer.',
            toast: _currentPhase == GamePhase.night);

        // Advance script if next step is Dealer Act
        final nextIndex = _scriptIndex + 1;
        if (nextIndex < _scriptQueue.length) {
          final nextStep = _scriptQueue[nextIndex];
          if (nextStep.id == 'dealer_act') {
            _scriptIndex++;
            logAction(
                'System', 'Skipping Dealer Kill phase due to Conversion.');
          }
        }
        
        secondWind.isAlive = true;
        deadPlayerIds.remove(secondWind.id);
        secondWind.deathReason = null;
        secondWind.deathDay = null;
      } else {
        secondWind.secondWindRefusedConversion = true;
        secondWind.secondWindPendingConversion = false;
        secondWind.secondWindConversionNight = null;

        logAction(sourceTitle,
            'Dealers refused conversion. ${secondWind.name} remains dead.',
            toast: _currentPhase == GamePhase.night);
      }
    }

    switch (roleId) {
      case 'dealer':
         if (step.actionType == ScriptActionType.binaryChoice &&
            (step.id == 'second_wind_conversion_choice' ||
                step.id == 'second_wind_conversion_vote')) {
          final raw = selections.first.trim().toLowerCase();
          final decision = raw == 'convert'
              ? true
              : (raw == 'kill' ? false : parseBinaryChoice(selections.first));
          if (decision == null) {
            logAction(step.title,
                'Invalid choice. Expected CONVERT/KILL (or yes/no legacy).');
            break;
          }
          applySecondWindDecision(convert: decision, sourceTitle: step.title);
          break;
        }
        
        final target = resolvePlayer(selections.first);

        // Check if ANY active dealer is sent home (blocks murders)
        final anyDealerSentHome = players
            .where((p) => p.role.id == 'dealer' && p.isActive)
            .any((p) => _isSoberSentHome(p.id));

        if (anyDealerSentHome) {
           logAction(step.title, 'A Dealer was sent home by The Sober â€” no murders tonight.');
           break;
        }
        if (_isSoberSentHome(target.id)) {
           queueHostAlert(title: 'Sent Home Early', message: '${target.name} was sent home early and is immune.');
           logAction(step.title, 'Dealers tried to target ${target.name}, but they were sent home.');
           break;
        }
        if (sourcePlayer != null && target.id == sourcePlayer.id) {
           logAction(step.title, 'Invalid target: Dealers cannot eliminate themselves.');
           break;
        }

        abilityResolver.queueAbility(ActiveAbility(
           abilityId: 'dealer_kill',
           sourcePlayerId: sourcePlayer?.id ?? 'dealer',
           targetPlayerIds: [target.id],
           trigger: AbilityTrigger.nightAction,
           effect: AbilityEffect.kill,
           priority: 50
        ));
        nightActions['kill'] = target.id;
        logAction(step.title, 'Dealers selected ${target.name} (action queued).', toast: _currentPhase == GamePhase.night);
        break;

      case 'sober':
        final target = resolvePlayer(selections.first);
        if (_isSoberSentHome(sourcePlayer?.id ?? '')) return; 
        if (target.id == sourcePlayer?.id) {
           logAction(step.title, 'Sober cannot send themselves home.');
           break;
        }

        abilityResolver.queueAbility(ActiveAbility(
           abilityId: 'sober_send_home',
           sourcePlayerId: sourcePlayer?.id ?? 'sober',
           targetPlayerIds: [target.id],
           trigger: AbilityTrigger.nightAction,
           effect: AbilityEffect.protect,
           priority: 1
        ));
        
        nightActions['sober_act'] = target.id;
        nightActions['sober_sent_home'] = target.id;
        logAction(step.title, 'Sober selected ${target.name} to be sent home (action queued).', toast: _currentPhase == GamePhase.night);
        rebuildNightScript();
        break;

      case 'medic':
        if (step.id == 'medic_setup_choice') {
           final decision = selections.first;
           final actors = players.where((p) => p.role.id == 'medic' && p.isActive).toList();
           for (final p in actors) {
             p.medicChoice = decision;
             p.needsSetup = false;
           }
           logAction(step.title, 'Medic(s) chose ability: $decision.',
                 toast: _currentPhase == GamePhase.night);
           break;
        }
        
        final target = resolvePlayer(selections.first);
        final actors = players.where((p) => p.role.id == 'medic' && p.isActive).toList();
        
        if (actors.any((p) => p.id == target.id) && actors.any((p)=>p.medicChoice!='REVIVE')) {
           logAction(step.title, 'Medic cannot target themselves (unless Revive logic allows).');
           // break; // Let them through if reviving logic handles it, or block here for Protect.
           // Assuming strict block for Protect.
        }
        if (_isSoberSentHome(target.id)) {
           queueHostAlert(title: 'Sent Home Early', message: '${target.name} was sent home early and is immune.');
           logAction(step.title, 'Medic targeted ${target.name} but they were sent home.');
           break;
        }

        for (final medic in actors) {
           if (medic.medicChoice == 'PROTECT_DAILY') {
               abilityResolver.removeAbilitiesForSource(medic.id); 
               abilityResolver.queueAbility(ActiveAbility(
                   abilityId: 'medic_protect',
                   sourcePlayerId: medic.id,
                   targetPlayerIds: [target.id],
                   trigger: AbilityTrigger.nightAction,
                   effect: AbilityEffect.protect,
                   priority: 20
               ));
               nightActions['protect'] = target.id;
               logAction(step.title, 'Medic (${medic.name}) protecting ${target.name} (queued).', toast: _currentPhase == GamePhase.night);
           } else if (medic.medicChoice == 'REVIVE') {
               if (!medic.reviveUsed) {
                   abilityResolver.removeAbilitiesForSource(medic.id);
                   abilityResolver.queueAbility(ActiveAbility(
                       abilityId: 'medic_revive',
                       sourcePlayerId: medic.id,
                       targetPlayerIds: [target.id],
                       trigger: AbilityTrigger.nightAction,
                       effect: AbilityEffect.other,
                       priority: 55
                   ));
                   nightActions['medic_revive'] = target.id;
                   logAction(step.title, 'Medic (${medic.name}) reviving ${target.name} (queued).', toast: _currentPhase == GamePhase.night);
               }
           }
        }
        break;

      case 'clinger':
        final target = resolvePlayer(selections.first);
        if (step.id == 'clinger_act') {
           // Attack Dog
           final clinger = players.firstWhere((p) => p.role.id == 'clinger', orElse: () => Player(
             id: '?',
             name: '',
             role: Role(
               id: '?',
               name: '',
               alliance: '?',
               type: '?',
               description: '',
               nightPriority: 0,
               assetPath: '',
               colorHex: '#000000',
             ),
             isAlive: true, isEnabled: false));
            if (!clinger.isActive || !clinger.clingerFreedAsAttackDog || clinger.clingerAttackDogUsed) {
               logAction(step.title, 'Clinger Attack Dog not available.');
               break;
            }
            if (_isSoberSentHome(target.id)) {
               logAction(step.title, 'Target sent home. Immune.');
               break;
            }

            abilityResolver.queueAbility(ActiveAbility(
               abilityId: 'clinger_kill',
               sourcePlayerId: clinger.id,
               targetPlayerIds: [target.id],
               trigger: AbilityTrigger.nightAction,
               effect: AbilityEffect.kill,
               priority: 45
            ));
            clinger.clingerAttackDogUsed = true;
            nightActions['kill_clinger'] = target.id;
            logAction(step.title, 'Clinger Attack Dog targeting ${target.name} (queued).', toast: _currentPhase == GamePhase.night);
        } else {
           // Obsession
           if (_isSoberSentHome(target.id)) {
              logAction(step.title, 'Target sent home. Cannot obsess.');
              break;
           }
           if (sourcePlayer != null) {
              abilityResolver.queueAbility(ActiveAbility(
                 abilityId: 'clinger_obsession',
                 sourcePlayerId: sourcePlayer.id,
                 targetPlayerIds: [target.id],
                 trigger: AbilityTrigger.startup,
                 priority: 0
              ));
              sourcePlayer.clingerPartnerId = target.id;
              sourcePlayer.needsSetup = false;
              nightActions['clinger_obsession'] = target.id;
              logAction(step.title, 'Clinger obsession: ${target.name} (queued).', toast: _currentPhase == GamePhase.night);
              queueHostAlert(title: 'Reveal', message: 'Show ${target.name}\'s role: ${target.role.name}.');
           }
        }
        break;

      case 'messy_bitch':
         final target = resolvePlayer(selections.first);
         if (_isSoberSentHome(target.id)) {
            logAction(step.title, 'Target sent home. Immune.');
            break;
         }
         abilityResolver.queueAbility(ActiveAbility(
            abilityId: 'messy_bitch_rumour',
            sourcePlayerId: sourcePlayer?.id ?? 'messy_bitch',
            targetPlayerIds: [target.id],
            trigger: AbilityTrigger.nightAction,
            effect: AbilityEffect.rumour,
            priority: 60
         ));
         nightActions['messy_bitch_rumour'] = target.id;
         logAction(step.title, 'Rumour targeting ${target.name} (queued).', toast: _currentPhase == GamePhase.night);
         break;

      case 'roofi':
         final target = resolvePlayer(selections.first);
         if (_isSoberSentHome(target.id)) {
            logAction(step.title, 'Target sent home. Immune.');
            break;
         }
         final roofis = players.where((p) => p.role.id == 'roofi' || p.bouncerHasRoofiAbility).where((p)=>p.isActive).toList();
         for (final r in roofis) {
             if (r.roofiAbilityRevoked) continue;
             abilityResolver.removeAbilitiesForSource(r.id);
             abilityResolver.queueAbility(ActiveAbility(
                abilityId: 'roofi_silence',
                sourcePlayerId: r.id,
                targetPlayerIds: [target.id],
                trigger: AbilityTrigger.nightAction,
                effect: AbilityEffect.silence,
                priority: 35
             ));
         }
         nightActions['roofi'] = target.id;
         logAction(step.title, 'Roofi poisoning ${target.name} (queued).', toast: _currentPhase == GamePhase.night);
         break;

      case 'wallflower':
        final wantsWitness = parseBinaryChoice(selections.first);
        if (wantsWitness == null) {
          logAction(step.title, 'Invalid choice.');
          break;
        }
        handleScriptOption(step, wantsWitness ? 'PEEK' : 'SKIP');
        break;
      
      case 'bouncer':
         final target = resolvePlayer(selections.first);
         if (_isSoberSentHome(target.id)) {
             logAction(step.title, 'Target sent home. Immune to check.');
             break;
         }
         nightActions['bouncer_check'] = target.id;
         target.idCheckedByBouncer = true;
          queueHostAlert(
            title: (target.alliance.contains('Dealer') || target.role.alliance == 'The Dealers') ? 'Gotcha!' : 'Clear',
            message: '${target.name} is ${target.alliance}.'
          );
          logAction(step.title, "Bouncer I.D.'d ${target.name}.", toast: _currentPhase == GamePhase.night);
          break;

      case 'club_manager':
      case 'club_manager_act':
          final target = resolvePlayer(selections.first);
          if (_isSoberSentHome(target.id)) {
              logAction(step.title, 'Target sent home. Immune.');
              break;
          }
          logAction(step.title, "Club Manager viewed ${target.name}'s role: ${target.role.name}", toast: _currentPhase == GamePhase.night);
          onClubManagerReveal?.call(target);
          break;

      case 'tea_spiller':
         break;

      case 'predator':
        final target = resolvePlayer(selections.first);
        if (_isSoberSentHome(target.id)) {
             logAction(step.title, 'Target sent home. Immune.');
             break;
        }
        if (sourcePlayer != null) sourcePlayer.predatorTargetId = target.id;
        nightActions['predator_mark'] = target.id;
        logAction(step.title, 'Predator marked ${target.name}.');
        break;

      case 'lightweight':
        final target = resolvePlayer(selections.first);
        if (_isSoberSentHome(target.id)) {
             logAction(step.title, 'Target sent home. Immune.');
             break;
        }
        nightActions['lightweight_taboo'] = target.id;
        final actors = players.where((p) => p.role.id == 'lightweight').toList();
        for (final p in actors) {
          if (!p.tabooNames.contains(target.name)) {
            p.tabooNames.add(target.name);
          }
        }
        logAction(step.title, 'Taboo added: ${target.name}.');
        break;
        
      default:
        // Generic fallback
        final names = selections.map((id) => resolvePlayer(id).name).join(', ');
        logAction(step.title, 'Selected: $names', toast: _currentPhase == GamePhase.night);
        break;
    }
  }


  /// Completes Predator retaliation by killing one eligible voter.
  ///
  /// If vote telemetry was not recorded, falls back to any alive non-Predator.
  bool completePredatorRetaliation(String targetId) {
    final predatorId = pendingPredatorId;
    if (predatorId == null) return false;

    final predator = players.where((p) => p.id == predatorId).firstOrNull;
    if (predator == null) {
      pendingPredatorId = null;
      pendingPredatorEligibleVoterIds = <String>[];
      pendingPredatorPreferredTargetId = null;
      return false;
    }

    final alive = players.where((p) => p.isAlive && p.isEnabled).toList();

    final baseEligible = alive.where((p) => p.id != predatorId).toList();

    // If we have captured voter telemetry, restrict to those voters...
    final restricted = pendingPredatorEligibleVoterIds.isNotEmpty
        ? baseEligible
            .where((p) => pendingPredatorEligibleVoterIds.contains(p.id))
            .toList()
        : baseEligible;

    // ...but always allow the preferred marked target (if alive), even if they
    // were sent home / silenced and didn't vote.
    final preferredId = pendingPredatorPreferredTargetId;
    final preferred = preferredId == null
        ? null
        : baseEligible.where((p) => p.id == preferredId).firstOrNull;

    final eligible =
        <Player>{...restricted, if (preferred != null) preferred}.toList();

    final target = eligible.where((p) => p.id == targetId).firstOrNull;
    if (target == null) {
      logAction('Predator Retaliation', 'Invalid retaliation target selected.');
      return false;
    }

    processDeath(target, cause: 'predator_retaliation');
    logAction('Predator Retaliation',
        '${predator.name} took ${target.name} down with them.');

    pendingPredatorId = null;
    pendingPredatorEligibleVoterIds = <String>[];
    pendingPredatorPreferredTargetId = null;
    notifyListeners();
    return true;
  }

  /// The Bouncer may challenge a suspected Roofi to steal their paralyze power.
  ///
  /// - If the suspect is an active Roofi, Roofi loses their ability and the
  ///   Bouncer gains it.
  /// - If incorrect, the Bouncer permanently loses their ID-check ability.
  ///
  /// Defensive behavior: this is a one-time resolution per game because either
  /// success or failure sets a terminal flag.
  bool resolveBouncerRoofiChallenge(String suspectedPlayerId) {
    final bouncer =
        players.where((p) => p.isActive && p.role.id == 'bouncer').firstOrNull;
    if (bouncer == null) {
      logAction('Bouncer Challenge', 'No active Bouncer in game.');
      return false;
    }

    // If the Bouncer already lost ID checks or already has Roofi powers,
    // the challenge should not run again.
    if (bouncer.bouncerAbilityRevoked) {
      logAction('Bouncer Challenge',
          'Bouncer already lost ID-check ability; cannot challenge again.');
      return false;
    }
    if (bouncer.bouncerHasRoofiAbility) {
      logAction('Bouncer Challenge',
          'Bouncer already has Roofi powers; cannot challenge again.');
      return false;
    }

    final suspect = players.where((p) => p.id == suspectedPlayerId).firstOrNull;
    if (suspect == null || !suspect.isActive) {
      logAction('Bouncer Challenge', 'Invalid Roofi challenge target.');
      return false;
    }

    if (suspect.role.id == 'roofi' && !suspect.roofiAbilityRevoked) {
      suspect.roofiAbilityRevoked = true;
      bouncer.bouncerHasRoofiAbility = true;
      logAction('Bouncer Challenge',
          'Bouncer correctly challenged ${suspect.name} and stole Roofi powers.');
      rebuildNightScript();
      notifyListeners();
      return true;
    }

    bouncer.bouncerAbilityRevoked = true;
    logAction('Bouncer Challenge',
        'Bouncer incorrectly challenged ${suspect.name} â€” ID checks are lost forever.');
    rebuildNightScript();
    notifyListeners();
    return true;
  }

  void handleScriptOption(ScriptStep step, String selectedOption) {
    final roleId = step.roleId;

    switch (roleId) {
      case 'wallflower':
        final raw = selectedOption.trim().toUpperCase();
        String? mode;
        if (raw == 'SKIP') mode = 'skip';
        if (raw == 'PEEK') mode = 'peek';
        if (raw == 'STARE') mode = 'stare';

        // Back-compat: older scripts/tests may still send YES/NO.
        if (mode == null && raw == 'YES') mode = 'peek';
        if (mode == null && raw == 'NO') mode = 'skip';

        if (mode == null) {
          logAction(step.title, 'Invalid Wallflower option: $selectedOption');
          break;
        }

        final wallflower = players
            .where((p) => p.role.id == 'wallflower' && p.isActive)
            .firstOrNull;
        if (wallflower == null) {
          logAction(step.title, 'No active Wallflower in game.');
          break;
        }
        if (!wallflower.isAlive) {
          logAction(step.title, 'Wallflower is dead; witness choice ignored.');
          break;
        }
        if (wallflower.soberSentHome) {
          logAction(
              step.title, 'Wallflower was sent home; witness choice ignored.');
          break;
        }

        nightActions['wallflower_witness_mode'] = mode;

        if (mode == 'skip') {
          abilityResolver.queueAbility(
            ActiveAbility(
              abilityId: 'wallflower_skip',
              sourcePlayerId: wallflower.id,
              trigger: AbilityTrigger.nightAction,
              effect: AbilityEffect.other,
              priority: 60,
            ),
          );
          logAction(step.title, 'Wallflower declined to witness.',
              toast: _currentPhase == GamePhase.night);
        } else {
          abilityResolver.queueAbility(
            ActiveAbility(
              abilityId: 'wallflower_witness',
              sourcePlayerId: wallflower.id,
              trigger: AbilityTrigger.nightAction,
              effect: AbilityEffect.other,
              priority: 60,
              metadata: {'mode': mode},
            ),
          );
          logAction(step.title, 'Wallflower chose to $mode.',
              toast: _currentPhase == GamePhase.night);
        }
        break;

      case 'medic':
        final option = selectedOption.toUpperCase();
        if (option != 'PROTECT' && option != 'REVIVE') return;

        final medic = players.where((p) => p.role.id == 'medic').firstOrNull;
        if (medic != null) {
          if (medic.medicChoice != null && medic.medicChoice!.isNotEmpty) {
            logAction(step.title,
                'Medic choice already locked: ${medic.medicChoice} (ignored: $option)');
            break;
          }
          medic.medicChoice = option == 'PROTECT' ? 'PROTECT_DAILY' : 'REVIVE';
          medic.needsSetup = false;
          logAction(step.title, 'Medic permanently chose: ${medic.medicChoice}',
              toast: _currentPhase == GamePhase.night);
        }
        break;

      default:
        logAction(step.title, 'Selected option: $selectedOption',
            toast: _currentPhase == GamePhase.night);
        break;
    }
    notifyListeners();
  }

  // --- Win checks (minimal, matches common rules + your LiveGameStats normalization) ---

  bool checkWinConditions() {
    // Once a winner is locked in, keep returning true without re-evaluating.
    if (_winner != null) return true;

    // Messy Bitch immediate win: rumours have reached every enabled guest.
    if (_isMessyBitchWinConditionMet()) {
      _winner = 'Messy Bitch';
      _winMessage = 'Messy Bitch spread a rumour to every player.';
      GamesNightService.instance.recordGameEnded(this);
      return true;
    }

    final alive = players.where((p) => p.isAlive && p.isEnabled).toList();
    final dealerAlive = alive
        .where((p) =>
            p.alliance.toLowerCase().contains('dealer') ||
            p.role.id == 'dealer')
        .length;
    final partyAlive =
        alive.where((p) => p.alliance.toLowerCase().contains('party')).length;

    if (alive.isEmpty) {
      _winner = 'No one';
      _winMessage = 'No one wins. Everyone is dead.';
      GamesNightService.instance.recordGameEnded(this);
      return true;
    }

    // Club Manager special win: only Club Manager + 1 Dealer remain.
    if (alive.length == 2 && dealerAlive == 1) {
      final clubManagerAlive = alive.any((p) => p.role.id == 'club_manager');
      if (clubManagerAlive) {
        _winner = 'Club Manager';
        _winMessage = 'Only the Club Manager and a Dealer remain.';
        GamesNightService.instance.recordGameEnded(this);
        return true;
      }
    }

    // Party wins if no dealers remain (and at least one party remains).
    if (dealerAlive == 0 && partyAlive > 0) {
      _winner = 'Party Animals';
      _winMessage = 'All Dealers are eliminated.';
      GamesNightService.instance.recordGameEnded(this);
      return true;
    }

    // Dealer win condition: exactly 1 Dealer vs 1 Party Animal.
    if (alive.length == 2 && dealerAlive == 1 && partyAlive == 1) {
      _winner = 'Dealers';
      _winMessage = 'Final showdown: 1 Dealer vs 1 Party Animal.';
      GamesNightService.instance.recordGameEnded(this);
      return true;
    }

    return false;
  }

  // --- Persistence (kept minimal; extend as needed) ---

  Future<void> saveGame(String saveName, {String? overwriteId}) async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();

    final saveId =
        overwriteId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // If overwriting, clear out old keys we know about to avoid stale state.
    if (overwriteId != null) {
      await _deleteSaveKeys(prefs, saveId);
    }

    // Optimization: Avoid redundant decode by serializing lists once.
    final playersList = players.map((p) => p.toJson()).toList();
    final logList = _gameLog.map((l) => l.toJson()).toList();

    final playersJson = jsonEncode(playersList);
    final logJson = jsonEncode(logList);

    // New: single-blob save (preferred for robustness).
    // Optimization: construct blob without large lists first, then inject
    // the pre-encoded JSON strings to avoid double-encoding overhead.
    final blobMap = <String, dynamic>{
      'schemaVersion': _saveSchemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'hostName': hostName,
      // 'players' and 'log' injected manually below
      'phaseIndex': _currentPhase.index,
      'dayCount': dayCount,
      'scriptIndex': _scriptIndex,
      'lastNightSummary': lastNightSummary,
      'lastNightHostRecap': lastNightHostRecap,
      'nightActions': nightActions,
      'deadPlayerIds': deadPlayerIds,
      'votesByVoter': currentDayVotesByVoter,
      'votesByTarget': currentDayVotesByTarget,
      'voteHistory': voteHistory.map((v) => v.toJson()).toList(),
      'voteSequence': _voteSequence,
      'predatorPending': {
        'pendingPredatorId': pendingPredatorId,
        'eligibleVoterIds': pendingPredatorEligibleVoterIds,
        'preferredTargetId': pendingPredatorPreferredTargetId,
      },
      'teaSpillerPending': {
        'pendingTeaSpillerId': pendingTeaSpillerId,
        'eligibleVoterIds': pendingTeaSpillerEligibleVoterIds,
      },
      'dramaQueenPending': {
        'swapPending': dramaQueenSwapPending,
        'markedAId': dramaQueenMarkedAId,
        'markedBId': dramaQueenMarkedBId,
      },
      'statusEffects': statusEffectManager.toJson(),
      'abilityQueue': abilityResolver.toJson(),
      'reactionHistory': reactionSystem.getHistoryJson(),
      if (lastDramaQueenSwap != null)
        'lastDramaQueenSwap': {
          'day': lastDramaQueenSwap!.day,
          'playerAName': lastDramaQueenSwap!.playerAName,
          'playerBName': lastDramaQueenSwap!.playerBName,
          'fromRoleA': lastDramaQueenSwap!.fromRoleA,
          'fromRoleB': lastDramaQueenSwap!.fromRoleB,
          'toRoleA': lastDramaQueenSwap!.toRoleA,
          'toRoleB': lastDramaQueenSwap!.toRoleB,
        },
    };

    final partialJson = jsonEncode(blobMap);
    // Inject pre-encoded players and log. Assumes partialJson ends with '}'.
    final finalJson =
        '${partialJson.substring(0, partialJson.length - 1)},"players":$playersJson,"log":$logJson}';

    await prefs.setString(_saveBlobKey(saveId), finalJson);

    // Legacy per-field keys (kept for backward compatibility + existing tests).
    await prefs.setString(_saveKey(saveId, 'players'), playersJson);
    await prefs.setString(_saveKey(saveId, 'log'), logJson);
    await prefs.setString(_saveKey(saveId, 'hostName'), hostName ?? '');
    await prefs.setInt(_saveKey(saveId, 'phase'), _currentPhase.index);
    await prefs.setInt(_saveKey(saveId, 'dayCount'), dayCount);
    await prefs.setInt(_saveKey(saveId, 'scriptIndex'), _scriptIndex);

    // Host-facing recap (keeps Day bulletin consistent after load).
    await prefs.setString(
        _saveKey(saveId, 'lastNightSummary'), lastNightSummary);
    await prefs.setString(
        _saveKey(saveId, 'lastNightHostRecap'), lastNightHostRecap);

    // In-flight engine state used by tests / mid-game resumes
    await prefs.setString(
        _saveKey(saveId, 'nightActions'), jsonEncode(nightActions));
    await prefs.setString(
        _saveKey(saveId, 'deadPlayerIds'), jsonEncode(deadPlayerIds));
    await prefs.setString(
        _saveKey(saveId, 'votesByVoter'), jsonEncode(currentDayVotesByVoter));
    await prefs.setString(
        _saveKey(saveId, 'votesByTarget'), jsonEncode(currentDayVotesByTarget));
    await prefs.setString(_saveKey(saveId, 'voteHistory'),
        jsonEncode(voteHistory.map((v) => v.toJson()).toList()));
    await prefs.setInt(_saveKey(saveId, 'voteSequence'), _voteSequence);
    await prefs.setString(
      _saveKey(saveId, 'predatorPending'),
      jsonEncode({
        'pendingPredatorId': pendingPredatorId,
        'eligibleVoterIds': pendingPredatorEligibleVoterIds,
        'preferredTargetId': pendingPredatorPreferredTargetId,
      }),
    );
    await prefs.setString(
      _saveKey(saveId, 'teaSpillerPending'),
      jsonEncode({
        'pendingTeaSpillerId': pendingTeaSpillerId,
        'eligibleVoterIds': pendingTeaSpillerEligibleVoterIds,
      }),
    );
    await prefs.setString(
      _saveKey(saveId, 'dramaQueenPending'),
      jsonEncode({
        'swapPending': dramaQueenSwapPending,
        'markedAId': dramaQueenMarkedAId,
        'markedBId': dramaQueenMarkedBId,
      }),
    );
    await prefs.setString(_saveKey(saveId, 'statusEffects'),
        jsonEncode(statusEffectManager.toJson()));
    await prefs.setString(
        _saveKey(saveId, 'abilityQueue'), jsonEncode(abilityResolver.toJson()));

    final saveMetadata = SavedGame(
      id: saveId,
      name: saveName,
      savedAt: DateTime.now(),
      dayCount: dayCount,
      alivePlayers: players.where((p) => p.isActive).length,
      totalPlayers: players.where((p) => p.isEnabled).length,
      currentPhase: _currentPhase.toString().split('.').last,
    );

    final saves = await getSavedGames();
    // Remove any existing entry for this id (overwrite / duplicate repair).
    saves.removeWhere((s) => s.id == saveId);
    saves.add(saveMetadata);
    await prefs.setString(
        _savedGamesIndexKey, jsonEncode(saves.map((s) => s.toJson()).toList()));

    if (lastDramaQueenSwap != null) {
      prefs.setString(
        _saveKey(saveId, 'lastDramaQueenSwap'),
        jsonEncode({
          'day': lastDramaQueenSwap!.day,
          'playerAName': lastDramaQueenSwap!.playerAName,
          'playerBName': lastDramaQueenSwap!.playerBName,
          'fromRoleA': lastDramaQueenSwap!.fromRoleA,
          'fromRoleB': lastDramaQueenSwap!.fromRoleB,
          'toRoleA': lastDramaQueenSwap!.toRoleA,
          'toRoleB': lastDramaQueenSwap!.toRoleB,
        }),
      );
    }

    prefs.setString(_saveKey(saveId, 'reactionHistory'),
        jsonEncode(reactionSystem.getHistoryJson()));
  }

  Future<List<SavedGame>> getSavedGames() async {
    if (!persistenceEnabled) return [];
    final prefs = await SharedPreferences.getInstance();
    final savesJson = prefs.getString(_savedGamesIndexKey);
    if (savesJson == null) return [];

    try {
      final decoded = jsonDecode(savesJson) as List<dynamic>;
      final saves = decoded
          .whereType<Map>()
          .map((j) => SavedGame.fromJson(j.cast<String, dynamic>()))
          .where((s) => s.id.isNotEmpty)
          .toList();
      return saves;
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteSavedGame(String saveId) async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await _deleteSaveKeys(prefs, saveId);

    final saves = await getSavedGames();
    saves.removeWhere((s) => s.id == saveId);
    await prefs.setString(
      _savedGamesIndexKey,
      jsonEncode(saves.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> _deleteSaveKeys(SharedPreferences prefs, String saveId) async {
    // Legacy per-field keys.
    const fields = <String>[
      'players',
      'log',
      'phase',
      'dayCount',
      'scriptIndex',
      'lastNightSummary',
      'lastNightHostRecap',
      'nightActions',
      'deadPlayerIds',
      'votesByVoter',
      'votesByTarget',
      'voteHistory',
      'voteSequence',
      'predatorPending',
      'teaSpillerPending',
      'dramaQueenPending',
      'statusEffects',
      'abilityQueue',
      'lastDramaQueenSwap',
      'reactionHistory',
    ];

    // Parallelize all removals (Blob + Legacy fields)
    await Future.wait([
      prefs.remove(_saveBlobKey(saveId)),
      ...fields.map((f) => prefs.remove(_saveKey(saveId, f))),
    ]);
  }

  Future<bool> loadGame(String saveId) async {
    if (!persistenceEnabled) return false;
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_saveBlobKey(saveId)) &&
        !prefs.containsKey(_saveKey(saveId, 'players'))) {
      return false;
    }

    try {
      // Prefer blob format.
      final blobStr = prefs.getString(_saveBlobKey(saveId));
      if (blobStr != null) {
        final decoded = jsonDecode(blobStr);
        if (decoded is Map) {
          await _loadFromSaveMap(decoded.cast<String, dynamic>());
        }
      } else {
        // Fallback: legacy per-field keys.
        await _loadFromLegacyKeys(prefs, saveId);
      }

      if (_currentPhase == GamePhase.night) {
        _scriptQueue = ScriptBuilder.buildNightScript(players, dayCount);
      } else if (_currentPhase == GamePhase.day) {
        final bulletin = lastNightSummary.trim().isNotEmpty
            ? lastNightSummary
            : 'Game Loaded.';
        _scriptQueue =
            ScriptBuilder.buildDayScript(dayCount, bulletin, players);
      } else {
        _scriptQueue = [];
      }

      final dqDataStr = prefs.getString(_saveKey(saveId, 'lastDramaQueenSwap'));
      if (dqDataStr != null) {
        final dqData = jsonDecode(dqDataStr) as Map<String, dynamic>;
        lastDramaQueenSwap = DramaQueenSwapRecord(
          day: dqData['day'] as int,
          playerAName: dqData['playerAName'] as String,
          playerBName: dqData['playerBName'] as String,
          fromRoleA: dqData['fromRoleA'] as String,
          fromRoleB: dqData['fromRoleB'] as String,
          toRoleA: dqData['toRoleA'] as String,
          toRoleB: dqData['toRoleB'] as String,
        );
      }

      final reactionHistoryStr =
          prefs.getString(_saveKey(saveId, 'reactionHistory'));
      if (reactionHistoryStr != null) {
        final decoded = jsonDecode(reactionHistoryStr) as List<dynamic>;
        reactionSystem.loadHistoryFromJson(decoded);
      }
    } catch (_) {
      return false;
    }

    // Ensure dead list contains any actually-dead players, but do not discard
    // persisted in-flight state (tests expect this).
    final derivedDead = players
        .where((p) => p.isEnabled && !p.isAlive)
        .map((p) => p.id)
        .toList(growable: false);
    final merged =
        <String>{...deadPlayerIds, ...derivedDead}.toList(growable: true);
    deadPlayerIds = merged;

    // Keep night action keys compatible with engine rules.
    _canonicalizeNightActions();

    notifyListeners();
    return true;
  }

  Future<void> _loadFromSaveMap(Map<String, dynamic> map) async {
    int asInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    List<dynamic> asList(dynamic v) => v is List ? v : const [];
    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

    final blobHostName = (map['hostName'] as String?)?.trim();

    final playersList = asList(map['players']);
    String? migratedHostName;
    final loadedPlayers = <Player>[];
    for (final json in playersList) {
      final p = (json as Map).cast<String, dynamic>();
      final roleId = (p['roleId'] as String?) ?? 'temp';
      final id = (p['id'] as String?) ?? '';
      if (roleId == hostRoleId || id == hostPlayerId) {
        migratedHostName ??= (p['name'] as String?)?.trim();
        continue;
      }

      final role = roleRepository.getRoleById(roleId) ??
          Role(
            id: 'temp',
            name: 'Unknown',
            alliance: 'None',
            type: 'None',
            description: '',
            nightPriority: 0,
            assetPath: '',
            colorHex: '#FFFFFF',
          );
      loadedPlayers.add(Player.fromJson(p, role));
    }
    players = loadedPlayers;

    final effectiveHostName = (blobHostName != null && blobHostName.isNotEmpty)
        ? blobHostName
        : (migratedHostName != null && migratedHostName.isNotEmpty)
            ? migratedHostName
            : null;
    if (effectiveHostName != null) {
      _setHostNameInternal(effectiveHostName, notify: false);
    }

    final logList = asList(map['log']);
    _gameLog = logList
        .map((j) => GameLogEntry.fromJson((j as Map).cast<String, dynamic>()))
        .toList();

    final phaseIdx = asInt(map['phaseIndex'], fallback: 0);
    if (phaseIdx >= 0 && phaseIdx < GamePhase.values.length) {
      _currentPhase = GamePhase.values[phaseIdx];
    }

    dayCount = asInt(map['dayCount'], fallback: 0);
    _scriptIndex = asInt(map['scriptIndex'], fallback: 0);

    lastNightSummary = (map['lastNightSummary'] as String?) ?? lastNightSummary;
    lastNightHostRecap =
        (map['lastNightHostRecap'] as String?) ?? lastNightHostRecap;

    final loadedStats = asMap(map['lastNightStats']);
    lastNightStats
      ..clear()
      ..addAll(loadedStats.map((k, v) => MapEntry(k, asInt(v))));

    _winner = map['winner'] as String?;
    _winMessage = map['winMessage'] as String?;

    // In-flight state
    nightActions = asMap(map['nightActions']);
    deadPlayerIds = asList(map['deadPlayerIds'])
        .map((e) => e.toString())
        .toList(growable: true);

    final votesByVoter = asMap(map['votesByVoter']);
    currentDayVotesByVoter
      ..clear()
      ..addAll(votesByVoter.map((k, v) => MapEntry(k, v as String?)));

    final votesByTarget = asMap(map['votesByTarget']);
    currentDayVotesByTarget.clear();
    for (final entry in votesByTarget.entries) {
      final list = entry.value;
      if (list is List) {
        currentDayVotesByTarget[entry.key] =
            list.map((e) => e.toString()).toList();
      }
    }

    final historyList = asList(map['voteHistory']);
    voteHistory
      ..clear()
      ..addAll(historyList
          .map((e) => VoteCast.fromJson((e as Map).cast<String, dynamic>())));

    _voteSequence = asInt(map['voteSequence'], fallback: _voteSequence);

    final predatorPending = asMap(map['predatorPending']);
    pendingPredatorId = predatorPending['pendingPredatorId'] as String?;
    pendingPredatorPreferredTargetId =
        predatorPending['preferredTargetId'] as String?;
    final eligible = predatorPending['eligibleVoterIds'];
    if (eligible is List) {
      pendingPredatorEligibleVoterIds =
          eligible.map((e) => e.toString()).toList(growable: true);
    } else {
      pendingPredatorEligibleVoterIds = <String>[];
    }

    final dqPending = asMap(map['dramaQueenPending']);
    dramaQueenSwapPending =
        dqPending['swapPending'] as bool? ?? dramaQueenSwapPending;
    dramaQueenMarkedAId = dqPending['markedAId'] as String?;
    dramaQueenMarkedBId = dqPending['markedBId'] as String?;

    final teaPending = asMap(map['teaSpillerPending']);
    pendingTeaSpillerId = teaPending['pendingTeaSpillerId'] as String?;
    final teaEligible = teaPending['eligibleVoterIds'];
    if (teaEligible is List) {
      pendingTeaSpillerEligibleVoterIds =
          teaEligible.map((e) => e.toString()).toList(growable: true);
    } else {
      pendingTeaSpillerEligibleVoterIds = <String>[];
    }

    final statusEffects = asMap(map['statusEffects']);
    if (statusEffects.isNotEmpty) {
      statusEffectManager.loadFromJson(statusEffects);
    }

    final abilityQueue = asMap(map['abilityQueue']);
    if (abilityQueue.isNotEmpty) {
      abilityResolver.loadFromJson(abilityQueue);
    }

    final reactionHistory = map['reactionHistory'];
    if (reactionHistory is List) {
      reactionSystem.loadHistoryFromJson(reactionHistory);
    }

    final dq = map['lastDramaQueenSwap'];
    if (dq is Map) {
      final d = dq.cast<String, dynamic>();
      lastDramaQueenSwap = DramaQueenSwapRecord(
        day: asInt(d['day']),
        playerAName: (d['playerAName'] as String?) ?? '',
        playerBName: (d['playerBName'] as String?) ?? '',
        fromRoleA: (d['fromRoleA'] as String?) ?? '',
        fromRoleB: (d['fromRoleB'] as String?) ?? '',
        toRoleA: (d['toRoleA'] as String?) ?? '',
        toRoleB: (d['toRoleB'] as String?) ?? '',
      );
    }

    if (_currentPhase == GamePhase.night) {
      _scriptQueue = ScriptBuilder.buildNightScript(players, dayCount);
    } else if (_currentPhase == GamePhase.day) {
      _scriptQueue =
          ScriptBuilder.buildDayScript(dayCount, 'Game Loaded.', players);
    } else {
      _scriptQueue = [];
    }
  }

  Future<void> _loadFromLegacyKeys(
      SharedPreferences prefs, String saveId) async {
    final savedHostName =
        (prefs.getString(_saveKey(saveId, 'hostName')) ?? '').trim();

    final playersStr = prefs.getString(_saveKey(saveId, 'players'));
    if (playersStr != null) {
      final decoded = jsonDecode(playersStr) as List<dynamic>;
      String? migratedHostName;
      final loadedPlayers = <Player>[];
      for (final json in decoded) {
        final map = (json as Map).cast<String, dynamic>();
        final roleId = (map['roleId'] as String?) ?? 'temp';
        final id = (map['id'] as String?) ?? '';
        if (roleId == hostRoleId || id == hostPlayerId) {
          migratedHostName ??= (map['name'] as String?)?.trim();
          continue;
        }

        final role = roleRepository.getRoleById(roleId) ??
            Role(
              id: 'temp',
              name: 'Unknown',
              alliance: 'None',
              type: 'None',
              description: '',
              nightPriority: 0,
              assetPath: '',
              colorHex: '#FFFFFF',
            );
        loadedPlayers.add(Player.fromJson(map, role));
      }

      players = loadedPlayers;

      final effectiveHostName = savedHostName.isNotEmpty
          ? savedHostName
          : (migratedHostName != null && migratedHostName.isNotEmpty)
              ? migratedHostName
              : null;
      if (effectiveHostName != null) {
        _setHostNameInternal(effectiveHostName, notify: false);
      }
    }

    final logStr = prefs.getString(_saveKey(saveId, 'log'));
    if (logStr != null) {
      final decoded = jsonDecode(logStr) as List<dynamic>;
      _gameLog = decoded
          .map((j) => GameLogEntry.fromJson((j as Map).cast<String, dynamic>()))
          .toList();
    }

    final phaseIdx = prefs.getInt(_saveKey(saveId, 'phase'));
    if (phaseIdx != null && phaseIdx < GamePhase.values.length) {
      _currentPhase = GamePhase.values[phaseIdx];
    }

    dayCount = prefs.getInt(_saveKey(saveId, 'dayCount')) ?? 0;
    _scriptIndex = prefs.getInt(_saveKey(saveId, 'scriptIndex')) ?? 0;

    lastNightSummary = prefs.getString(_saveKey(saveId, 'lastNightSummary')) ??
        lastNightSummary;
    lastNightHostRecap =
        prefs.getString(_saveKey(saveId, 'lastNightHostRecap')) ??
            lastNightHostRecap;

    if (_currentPhase == GamePhase.night) {
      _scriptQueue = ScriptBuilder.buildNightScript(players, dayCount);
    } else if (_currentPhase == GamePhase.day) {
      _scriptQueue =
          ScriptBuilder.buildDayScript(dayCount, 'Game Loaded.', players);
    } else {
      _scriptQueue = [];
    }

    final nightActionsStr = prefs.getString(_saveKey(saveId, 'nightActions'));
    if (nightActionsStr != null) {
      nightActions =
          (jsonDecode(nightActionsStr) as Map).cast<String, dynamic>();
    }

    final deadIdsStr = prefs.getString(_saveKey(saveId, 'deadPlayerIds'));
    if (deadIdsStr != null) {
      deadPlayerIds = (jsonDecode(deadIdsStr) as List)
          .map((e) => e as String)
          .toList(growable: true);
    }

    final votesByVoterStr = prefs.getString(_saveKey(saveId, 'votesByVoter'));
    if (votesByVoterStr != null) {
      final decoded =
          (jsonDecode(votesByVoterStr) as Map).cast<String, dynamic>();
      currentDayVotesByVoter
        ..clear()
        ..addAll(decoded.map((k, v) => MapEntry(k, v as String?)));
    }

    final votesByTargetStr = prefs.getString(_saveKey(saveId, 'votesByTarget'));
    if (votesByTargetStr != null) {
      final decoded =
          (jsonDecode(votesByTargetStr) as Map).cast<String, dynamic>();
      currentDayVotesByTarget.clear();
      for (final entry in decoded.entries) {
        final list = entry.value;
        if (list is List) {
          currentDayVotesByTarget[entry.key] =
              list.map((e) => e as String).toList();
        }
      }
    }

    final voteHistoryStr = prefs.getString(_saveKey(saveId, 'voteHistory'));
    if (voteHistoryStr != null) {
      final decoded = jsonDecode(voteHistoryStr) as List<dynamic>;
      voteHistory
        ..clear()
        ..addAll(decoded
            .map((e) => VoteCast.fromJson((e as Map).cast<String, dynamic>())));
    }

    _voteSequence =
        prefs.getInt(_saveKey(saveId, 'voteSequence')) ?? _voteSequence;

    final predatorPendingStr =
        prefs.getString(_saveKey(saveId, 'predatorPending'));
    if (predatorPendingStr != null) {
      final decoded =
          (jsonDecode(predatorPendingStr) as Map).cast<String, dynamic>();
      pendingPredatorId = decoded['pendingPredatorId'] as String?;
      pendingPredatorPreferredTargetId =
          decoded['preferredTargetId'] as String?;
      final voters = decoded['eligibleVoterIds'];
      if (voters is List) {
        pendingPredatorEligibleVoterIds =
            voters.map((e) => e as String).toList(growable: true);
      }
    }

    final teaPendingStr =
        prefs.getString(_saveKey(saveId, 'teaSpillerPending'));
    if (teaPendingStr != null) {
      final decoded =
          (jsonDecode(teaPendingStr) as Map).cast<String, dynamic>();
      pendingTeaSpillerId = decoded['pendingTeaSpillerId'] as String?;
      final voters = decoded['eligibleVoterIds'];
      if (voters is List) {
        pendingTeaSpillerEligibleVoterIds =
            voters.map((e) => e.toString()).toList(growable: true);
      } else {
        pendingTeaSpillerEligibleVoterIds = <String>[];
      }
    }

    final dqPendingStr = prefs.getString(_saveKey(saveId, 'dramaQueenPending'));
    if (dqPendingStr != null) {
      final decoded = (jsonDecode(dqPendingStr) as Map).cast<String, dynamic>();
      dramaQueenSwapPending =
          decoded['swapPending'] as bool? ?? dramaQueenSwapPending;
      dramaQueenMarkedAId = decoded['markedAId'] as String?;
      dramaQueenMarkedBId = decoded['markedBId'] as String?;
    }

    final statusEffectsStr = prefs.getString(_saveKey(saveId, 'statusEffects'));
    if (statusEffectsStr != null) {
      statusEffectManager.loadFromJson(
          (jsonDecode(statusEffectsStr) as Map).cast<String, dynamic>());
    }

    final abilityQueueStr = prefs.getString(_saveKey(saveId, 'abilityQueue'));
    if (abilityQueueStr != null) {
      abilityResolver.loadFromJson(
          (jsonDecode(abilityQueueStr) as Map).cast<String, dynamic>());
    }
  }

  /// Reset the engine back to the lobby.
  ///
  /// - When [keepGuests] is true, keeps names/ids/enabled flags.
  /// - When [keepAssignedRoles] is false, guests are reset to the temp role so
  ///   roles can be assigned again.
  void resetToLobby({
    bool keepGuests = true,
    bool keepAssignedRoles = false,
    bool clearArchived = false,
  }) {
    if (clearArchived) {
      clearArchivedGameBlob(notify: false);
    } else if (_shouldArchiveBeforeReset()) {
      archiveCurrentGameBlob(notify: false);
    }

    final kept = keepGuests ? guests.toList(growable: false) : const <Player>[];

    final tempRole = roleRepository.getRoleById('temp') ??
        Role(
          id: 'temp',
          name: 'Unassigned',
          alliance: 'None',
          type: 'None',
          description: '',
          nightPriority: 0,
          assetPath: '',
          colorHex: '#FFFFFF',
        );

    players = kept.map(
      (p) {
        final role = keepAssignedRoles ? p.role : tempRole;
        final rebuilt = Player(
          id: p.id,
          name: p.name,
          role: role,
          isAlive: true,
          isEnabled: p.isEnabled,
        );
        rebuilt.initialize();
        return rebuilt;
      },
    ).toList(growable: true);

    _currentPhase = GamePhase.lobby;
    dayCount = 0;
    _scriptQueue = [];
    _scriptIndex = 0;

    _winner = null;
    _winMessage = null;

    _gameLog = [];
    lastNightSummary = '';
    lastNightHostRecap = '';
    lastNightStats.clear();

    nightActions = {};
    deadPlayerIds = <String>[];
    clearDayVotes();
    voteHistory.clear();
    _voteSequence = 0;

    pendingPredatorId = null;
    pendingPredatorEligibleVoterIds = <String>[];
    pendingPredatorPreferredTargetId = null;

    dramaQueenSwapPending = false;
    dramaQueenMarkedAId = null;
    dramaQueenMarkedBId = null;
    lastDramaQueenSwap = null;

    abilityResolver.clear();
    reactionSystem.clearHistory();
    statusEffectManager.clearAll();

    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  // Canonicalize UI-written nightActions keys (step.id) into engine keys
  void _canonicalizeNightActions() {
    // Tea Spiller no longer marks at night (target is chosen on death).
    nightActions.remove('tea_spiller_mark');

    // dealer_act -> kill
    final dealerTarget = nightActions['dealer_act'];
    if (nightActions['kill'] == null && dealerTarget is String) {
      nightActions['kill'] = dealerTarget;
    }

    // sober_act -> sober_sent_home
    // ScriptBuilder uses 'sober_act' for the nightly selection.
    final soberTarget = nightActions['sober_act'];
    if (nightActions['sober_sent_home'] == null && soberTarget is String) {
      nightActions['sober_sent_home'] = soberTarget;
    }

    // medic_protect -> protect
    final medicTarget = nightActions['medic_protect'];
    if (nightActions['protect'] == null && medicTarget is String) {
      nightActions['protect'] = medicTarget;
    }

    // medic_act -> protect OR medic_revive (depends on Medic's locked mode)
    // The current ScriptBuilder uses 'medic_act' for the nightly Medic step.
    // We translate it here so both UI-written actions and legacy saves behave.
    final medicActTarget = nightActions['medic_act'];
    if (medicActTarget is String) {
      final medic = players.where((p) => p.role.id == 'medic').firstOrNull;
      final medicMode = (medic?.medicChoice ?? 'PROTECT_DAILY').toUpperCase();
      if (medicMode == 'REVIVE') {
        if (nightActions['medic_revive'] == null) {
          nightActions['medic_revive'] = medicActTarget;
        }
      } else {
        if (nightActions['protect'] == null) {
          nightActions['protect'] = medicActTarget;
        }

        // Keep persistent protection in sync with the most recent selection.
        if (medic != null) {
          medic.medicProtectedPlayerId = medicActTarget;
        }
      }
    }

    // bouncer_act -> bouncer_check
    final bouncerTarget = nightActions['bouncer_act'];
    if (nightActions['bouncer_check'] == null && bouncerTarget is String) {
      nightActions['bouncer_check'] = bouncerTarget;
    }

    // roofi_act -> roofi
    final roofiTarget = nightActions['roofi_act'];
    if (nightActions['roofi'] == null && roofiTarget is String) {
      nightActions['roofi'] = roofiTarget;
    }

    // bouncer_roofi_act -> roofi
    // When Bouncer steals Roofi powers, ScriptBuilder uses 'bouncer_roofi_act'.
    final stolenRoofiTarget = nightActions['bouncer_roofi_act'];
    if (nightActions['roofi'] == null && stolenRoofiTarget is String) {
      nightActions['roofi'] = stolenRoofiTarget;
    }

    // creep_act -> creep_target
    final creepTarget = nightActions['creep_act'];
    if (nightActions['creep_target'] == null && creepTarget is String) {
      nightActions['creep_target'] = creepTarget;
    }

    // clinger_act -> kill_clinger
    // Mirrors other UI step-id mappings (dealer_act -> kill, etc).
    final clingerKillTarget = nightActions['clinger_act'];
    if (nightActions['kill_clinger'] == null && clingerKillTarget is String) {
      nightActions['kill_clinger'] = clingerKillTarget;
    }

    // NOTE: clinger_obsession is already used as-is in the UI and engine.
  }

  @visibleForTesting
  void assertStateIsConsistent() {
    assert(() {
      final deadSet = deadPlayerIds.toSet();
      if (deadSet.length != deadPlayerIds.length) {
        throw StateError('deadPlayerIds contains duplicates.');
      }
      for (final id in deadPlayerIds) {
        final p = players.where((x) => x.id == id).firstOrNull;
        if (p == null) {
          throw StateError('deadPlayerIds contains unknown player id: $id');
        }
        if (p.isAlive) {
          throw StateError(
              'Player ${p.name} isAlive=true but is listed in deadPlayerIds.');
        }
      }
      return true;
    }());
  }

  /// Special handling for the Messy Bitch "Soft Win".
  /// Logs the victory, removes the Messy Bitch from the game (treated as sent home),
  /// and clears the game-ending state so the party can continue.
  void continueAfterMessyBitchWin() {
    // 1. Identify the Messy Bitch
    final messyBitch = players
        .where((p) => p.isEnabled && p.role.id == 'messy_bitch')
        .firstOrNull;

    if (messyBitch == null) {
      // Should not happen if called correctly, but safety first.
      _winner = null;
      _winMessage = null;
      notifyListeners();
      return;
    }

    // 2. Log the "Win" as a major event before they leave
    logAction('Messy Bitch Victory',
        '${messyBitch.name} has successfully spread rumours to everyone. She takes her win and leaves the party in chaos.');

    // 3. Remove the player (Soft kill / Send home)
    messyBitch.isAlive = false;
    messyBitch.isEnabled = false;
    messyBitch.soberSentHome =
        true; // Mark as sent home to distinguish from death if needed

    // Add to dead/inactive list logic if needed, but isAlive=false usually suffices for exclusion
    if (!deadPlayerIds.contains(messyBitch.id)) {
      deadPlayerIds.add(messyBitch.id);
    }

    // 4. Reset Win State
    _winner = null;
    _winMessage = null;

    // 5. Notify
    notifyListeners();
    _invalidateEligibleVotesCache();
  }

  /// Host-only moderation tool: revive a player regardless of normal revive rules.
  ///
  /// Intended for stuck games or correcting mistakes.
  /// Returns true if a player was revived.
  bool adminRevivePlayer(String playerId) {
    final target = players.where((p) => p.id == playerId).firstOrNull;
    if (target == null) return false;
    if (target.isAlive) return false;

    target.isAlive = true;
    target.isEnabled = true;
    target.soberSentHome = false;
    target.deathDay = null;
    target.deathReason = null;
    if (target.lives <= 0) target.lives = 1;
    deadPlayerIds.remove(target.id);

    logAction('Admin', '${target.name} was revived by the host.');
    notifyListeners();
    _invalidateEligibleVotesCache();
    return true;
  }
}

extension _FirstOrNullX<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

