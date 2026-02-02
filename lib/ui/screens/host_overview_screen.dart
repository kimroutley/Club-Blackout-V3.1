import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/ai_exporter.dart';
import '../../logic/game_dashboard_stats.dart';
import '../../logic/game_engine.dart';
import '../../logic/game_odds.dart';
import '../../logic/games_night_service.dart';
import '../../logic/host_insights.dart';
import '../../logic/live_game_stats.dart';
import '../../logic/monte_carlo_simulator.dart';
import '../../logic/story_exporter.dart';
import '../../logic/voting_insights.dart';
import '../../models/game_log_entry.dart';
import '../../models/player.dart';
import '../../utils/death_causes.dart';
import '../screens/game_screen.dart';
import '../screens/games_night_screen.dart';
import '../screens/host_privacy_screen.dart';
import '../styles.dart';
import '../utils/export_file_service.dart';
import '../utils/keep_screen_awake_service.dart';
import '../widgets/bulletin_dialog_shell.dart';
import '../widgets/club_alert_dialog.dart';
import '../widgets/drama_queen_swap_dialog.dart';
import '../widgets/game_drawer.dart';
import '../widgets/game_toast_listener.dart';
import '../widgets/host_alert_listener.dart';
import '../widgets/neon_background.dart';
import '../widgets/neon_glass_card.dart';
import '../widgets/unified_player_tile.dart';

class HostOverviewScreen extends StatefulWidget {
  final GameEngine gameEngine;

  const HostOverviewScreen({super.key, required this.gameEngine});

  @override
  State<HostOverviewScreen> createState() => _HostOverviewScreenState();
}

class _HostOverviewScreenState extends State<HostOverviewScreen> {
  GameEngine get gameEngine => widget.gameEngine;

  Timer? _oddsDebounce;
  int? _lastRequestedOddsSignature;
  int? _lastCompletedOddsSignature;
  bool _oddsSimRunning = false;
  GameOddsSnapshot? _simulatedOdds;
  DateTime? _simulatedOddsUpdatedAt;

  // Export loading states
  bool _isExportingStory = false;
  bool _isExportingAiStats = false;
  bool _isExportingCommentary = false;

  bool _viewingArchived = false;
  bool _loadingArchived = false;
  String? _archivedError;
  GameEngine? _archivedEngine;
  String? _archivedSourceJson;

  @override
  void initState() {
    super.initState();
    gameEngine.addListener(_onEngineChanged);
    _restoreKeepScreenAwakeSetting();
    // Kick off an initial compute shortly after first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeDefaultToArchived();
      if (!_viewingArchived) {
        _scheduleOddsUpdate();
      }
    });
  }

  Future<void> _restoreKeepScreenAwakeSetting() async {
    final enabled = await KeepScreenAwakeService.loadEnabled();
    // Best-effort: safe to call in tests.
    await KeepScreenAwakeService.apply(enabled);
  }

  Future<void> _toggleKeepScreenAwake() async {
    final next = !KeepScreenAwakeService.status.value.enabled;
    HapticFeedback.selectionClick();
    await KeepScreenAwakeService.setEnabled(next);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next ? 'Keep screen awake: ON' : 'Keep screen awake: OFF',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HostOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameEngine != widget.gameEngine) {
      oldWidget.gameEngine.removeListener(_onEngineChanged);
      widget.gameEngine.addListener(_onEngineChanged);
      _lastRequestedOddsSignature = null;
      _lastCompletedOddsSignature = null;
      _simulatedOdds = null;
      _simulatedOddsUpdatedAt = null;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scheduleOddsUpdate());
    }
  }

  @override
  void dispose() {
    _oddsDebounce?.cancel();
    gameEngine.removeListener(_onEngineChanged);
    super.dispose();
  }

  void _openPrivacyMode() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HostPrivacyScreen(
          hint: 'Long-press anywhere\nwhen it\'s safe to return.',
        ),
      ),
    );
  }

  Future<bool> _confirmHostAction({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.warning_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ClubAlertDialog(
          icon: Icon(icon),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showHostSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<Player?> _pickPlayer({
    required GameEngine engine,
    required String title,
    bool aliveOnly = false,
    bool deadOnly = false,
  }) async {
    final players = engine.players
        .where((p) => p.isEnabled)
        .where((p) => aliveOnly ? p.isAlive : true)
        .where((p) => deadOnly ? !p.isAlive : true)
        .toList(growable: false)
      ..sort((a, b) {
        final aliveCmp = (b.isAlive ? 1 : 0).compareTo(a.isAlive ? 1 : 0);
        if (aliveCmp != 0) return aliveCmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    if (players.isEmpty) return null;

    return showModalBottomSheet<Player>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return Container(
          decoration: ClubBlackoutTheme.neonSheet(
            context: context,
            color: ClubBlackoutTheme.neonBlue,
          ),
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.person_search_rounded,
                        color: ClubBlackoutTheme.neonBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: (tt.titleMedium ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = players[index];
                    return UnifiedPlayerTile.dashboard(
                      player: p,
                      gameEngine: engine,
                      onTap: () => Navigator.of(context).pop(p),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeratorToolsCard(BuildContext context, GameEngine engine) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isReadOnly = _viewingArchived;
    final opacity = isReadOnly ? 0.55 : 1.0;

    Future<void> runOrWarn(Future<void> Function() action) async {
      if (isReadOnly) {
        _showHostSnack('Moderator tools are disabled in archived view.');
        return;
      }
      await action();
    }

    return Opacity(
      opacity: opacity,
      child: NeonGlassCard(
        glowColor: cs.onSurface.withValues(alpha: 0.15),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    color: cs.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MODERATOR TOOLS',
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (isReadOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'ARCHIVED',
                      style: (tt.labelSmall ?? const TextStyle()).copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildNeonToolButton(
                  context,
                  label: 'Skip phase',
                  icon: Icons.skip_next_rounded,
                  color: ClubBlackoutTheme.neonBlue,
                  onPressed: () => runOrWarn(() async {
                    final ok = await _confirmHostAction(
                      title: 'Skip to next phase?',
                      message:
                          'This advances the game immediately. Use if the table is stuck.',
                      confirmLabel: 'Skip',
                      icon: Icons.skip_next_rounded,
                    );
                    if (!ok) return;
                    HapticFeedback.mediumImpact();
                    engine.skipToNextPhase();
                    _showHostSnack('Skipped to next phase.');
                  }),
                ),
                _buildNeonToolButton(
                  context,
                  label: 'Clear votes',
                  icon: Icons.delete_sweep_rounded,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  onPressed: () => runOrWarn(() async {
                    final ok = await _confirmHostAction(
                      title: 'Clear day votes?',
                      message:
                          'This clears the current day vote map (useful if votes were entered incorrectly).',
                      confirmLabel: 'Clear',
                      icon: Icons.delete_sweep_rounded,
                    );
                    if (!ok) return;
                    HapticFeedback.selectionClick();
                    engine.clearDayVotes();
                    _showHostSnack('Day votes cleared.');
                  }),
                ),
                _buildNeonToolButton(
                  context,
                  label: 'Force vote-out',
                  icon: Icons.how_to_vote_rounded,
                  color: ClubBlackoutTheme.neonBlue,
                  onPressed: () => runOrWarn(() async {
                    final target = await _pickPlayer(
                      engine: engine,
                      title: 'Force vote-out: pick a player',
                      aliveOnly: true,
                    );
                    if (target == null) return;

                    final ok = await _confirmHostAction(
                      title: 'Force vote-out?',
                      message:
                          'This will eliminate ${target.name} as if voted out.',
                      confirmLabel: 'Vote out',
                      icon: Icons.how_to_vote_rounded,
                    );
                    if (!ok) return;
                    HapticFeedback.mediumImpact();
                    final success = engine.voteOutPlayer(target.id);
                    if (success) {
                      _showHostSnack('${target.name} voted out.');
                    } else {
                      _showHostSnack('Vote-out failed (see log for details).');
                    }
                  }),
                ),
                _buildNeonToolButton(
                  context,
                  label: 'Admin kill',
                  icon: Icons.dangerous_rounded,
                  color: ClubBlackoutTheme.neonRed,
                  onPressed: () => runOrWarn(() async {
                    final target = await _pickPlayer(
                      engine: engine,
                      title: 'Admin kill: pick a player',
                      aliveOnly: true,
                    );
                    if (target == null) return;

                    final ok = await _confirmHostAction(
                      title: 'Admin kill?',
                      message:
                          'This will immediately kill ${target.name} (ignores most protections).',
                      confirmLabel: 'Kill',
                      icon: Icons.dangerous_rounded,
                    );
                    if (!ok) return;
                    HapticFeedback.heavyImpact();
                    engine.processDeath(target, cause: DeathCause.adminKill);
                    _showHostSnack('${target.name} killed.');
                  }),
                ),
                _buildNeonToolButton(
                  context,
                  label: 'Admin revive',
                  icon: Icons.volunteer_activism_rounded,
                  color: ClubBlackoutTheme.neonGreen,
                  onPressed: () => runOrWarn(() async {
                    final target = await _pickPlayer(
                      engine: engine,
                      title: 'Admin revive: pick a player',
                      deadOnly: true,
                    );
                    if (target == null) return;

                    final ok = await _confirmHostAction(
                        title: 'Admin revive?',
                        message:
                            'This will revive ${target.name} and return them to the game.',
                        confirmLabel: 'Revive',
                        icon: Icons.volunteer_activism_rounded);
                    if (!ok) return;
                    HapticFeedback.mediumImpact();
                    final success = engine.adminRevivePlayer(target.id);
                    if (success) {
                      _showHostSnack('${target.name} revived.');
                    } else {
                      _showHostSnack(
                          'Revive failed (player not found/already alive).');
                    }
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonToolButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: color.withValues(alpha: 0.05),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(color.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _buildPrivacyPanicFab() {
    return Tooltip(
      message: 'Hold for Privacy Mode',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: _openPrivacyMode,
        child: AbsorbPointer(
          child: FloatingActionButton.small(
            heroTag: 'hostPrivacyFab',
            onPressed: () {},
            backgroundColor:
                ClubBlackoutTheme.neonPurple.withValues(alpha: 0.22),
            foregroundColor: ClubBlackoutTheme.neonPurple,
            child: const Icon(Icons.visibility_off_rounded),
          ),
        ),
      ),
    );
  }

  void _onEngineChanged() {
    if (!mounted) return;

    if (_viewingArchived) {
      final hasArchived = gameEngine.lastArchivedGameBlobJson != null;
      if (!hasArchived) {
        setState(() {
          _viewingArchived = false;
          _archivedEngine = null;
          _archivedSourceJson = null;
          _archivedError = null;
          _loadingArchived = false;
        });
        _scheduleOddsUpdate();
        return;
      }

      _ensureArchivedEngineLoaded();
      return;
    }

    _maybeDefaultToArchived();
    if (!_viewingArchived) {
      _scheduleOddsUpdate();
    }
  }

  bool _liveGameLooksWiped() {
    if (gameEngine.currentPhase != GamePhase.lobby) return false;
    if (gameEngine.dayCount != 0) return false;
    if (gameEngine.gameLog.isNotEmpty) return false;

    final guests =
        gameEngine.guests.where((p) => p.isEnabled).toList(growable: false);
    final anyAssigned = guests.any((p) => p.role.id != 'temp');
    return !anyAssigned;
  }

  void _maybeDefaultToArchived() {
    final hasArchived = gameEngine.lastArchivedGameBlobJson != null;
    if (!hasArchived) return;
    if (!_liveGameLooksWiped()) return;
    if (_viewingArchived) return;

    setState(() {
      _viewingArchived = true;
    });
    _ensureArchivedEngineLoaded();
  }

  Future<void> _ensureArchivedEngineLoaded() async {
    final archivedJson = gameEngine.lastArchivedGameBlobJson;
    if (archivedJson == null) return;

    if (_archivedEngine != null && _archivedSourceJson == archivedJson) return;
    if (_loadingArchived) return;

    setState(() {
      _loadingArchived = true;
      _archivedError = null;
    });

    try {
      final decoded = (jsonDecode(archivedJson) as Map).cast<String, dynamic>();
      final engine = GameEngine(
        roleRepository: gameEngine.roleRepository,
        loadNameHistory: false,
        loadArchivedSnapshot: false,
        silent: true,
      );
      await engine.importSaveBlobMap(decoded, notify: false);

      if (mounted) {
        setState(() {
          _archivedEngine = engine;
          _archivedSourceJson = archivedJson;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _archivedError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingArchived = false;
        });
      }
    }
  }

  Future<void> _toggleArchivedView() async {
    final hasArchived = gameEngine.lastArchivedGameBlobJson != null;
    if (!hasArchived && !_viewingArchived) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No archived game snapshot available yet.')),
      );
      return;
    }

    setState(() {
      _viewingArchived = !_viewingArchived;
    });

    if (_viewingArchived) {
      await _ensureArchivedEngineLoaded();
      return;
    }

    _scheduleOddsUpdate();
  }

  Widget _buildArchivedBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final savedAt = gameEngine.lastArchivedGameSavedAt;
    final subtitle = savedAt == null
        ? 'Saved snapshot'
        : 'Saved ${savedAt.toLocal().toString()}';

    final err = _archivedError;
    final loading = _loadingArchived;

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonPurple,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing last game snapshot',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  err != null ? 'Snapshot load failed: $err' : subtitle,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        return ClubAlertDialog(
                          title: const Text('Clear saved snapshot?'),
                          content: Text(
                            'This removes the stored “last game” snapshot. You will no longer be able to view/export the previous game stats after reset.',
                            style: TextStyle(
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('CANCEL'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ClubBlackoutTheme.neonButtonStyle(
                                ClubBlackoutTheme.neonRed,
                                isPrimary: true,
                              ),
                              child: const Text('CLEAR'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed != true) return;

                    await gameEngine.clearArchivedGameBlob();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved snapshot cleared.')),
                    );
                  },
                  child: const Text('CLEAR'),
                ),
                TextButton(
                  onPressed: _toggleArchivedView,
                  child: const Text('VIEW LIVE'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _scheduleOddsUpdate() {
    if (!mounted) return;
    if (kIsWeb) return;
    _oddsDebounce?.cancel();
    _oddsDebounce =
        Timer(const Duration(milliseconds: 650), _maybeRunOddsSimulation);
  }

  int _engineOddsSignature(GameEngine engine) {
    final players = engine.players
        .where((p) => p.isEnabled)
        .map((p) => Object.hash(
              p.id,
              p.role.id,
              p.isAlive,
              p.soberSentHome,
              p.silencedDay,
              p.alibiDay,
              p.hasRumour,
            ))
        .toList(growable: false);

    // Votes are high-signal for odds; include the tallied map defensively.
    final votes = engine.eligibleDayVotesByTarget.entries
        .map((e) => Object.hash(e.key, Object.hashAll(e.value)))
        .toList(growable: false);

    return Object.hash(
      engine.dayCount,
      engine.currentPhase.index,
      engine.currentScriptIndex,
      engine.scriptQueue.length,
      Object.hashAll(players),
      Object.hashAll(votes),
    );
  }

  Future<void> _maybeRunOddsSimulation() async {
    if (!mounted) return;
    if (kIsWeb) {
      // Web builds don't support the isolate + dart:io implementation used by
      // the Monte Carlo simulator. Keep the dashboard stable instead.
      setState(() {
        _oddsSimRunning = false;
        _simulatedOddsUpdatedAt ??= DateTime.now();
        _simulatedOdds ??= GameOddsSnapshot(
          odds: const {},
          note: 'Odds simulation is disabled on web builds.',
        );
      });
      return;
    }

    // If the game is already over, simulated odds are trivial.
    final end = gameEngine.checkGameEnd();
    if (end != null) {
      setState(() {
        _oddsSimRunning = false;
        _lastRequestedOddsSignature = null;
        _lastCompletedOddsSignature = null;
        _simulatedOddsUpdatedAt = DateTime.now();
        _simulatedOdds = GameOddsSnapshot(
          odds: {end.winner: 1.0},
          note: 'Game is already over.',
        );
      });
      return;
    }

    final signature = _engineOddsSignature(gameEngine);
    _lastRequestedOddsSignature = signature;

    // Avoid rerunning if we already have results for the current state.
    if (_lastCompletedOddsSignature == signature) return;
    if (_oddsSimRunning) return;

    setState(() {
      _oddsSimRunning = true;
    });

    try {
      final res = await MonteCarloSimulator.simulateWinOdds(
        gameEngine,
        runs: 100,
        seed: signature,
        // Keep this high enough to finish typical games, low enough to avoid stalls.
        maxStepsPerRun: 20000,
      );

      if (!mounted) return;

      final completed = res.completed;
      final odds = res.odds;

      setState(() {
        _lastCompletedOddsSignature = signature;
        _simulatedOddsUpdatedAt = DateTime.now();
        _simulatedOdds = GameOddsSnapshot(
          odds: odds,
          note: completed <= 0
              ? 'Simulated odds unavailable (0 completed runs).'
              : 'Simulated odds from 100 runs (completed $completed). Auto-updates as the game changes.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _oddsSimRunning = false;
        });

        // If the engine changed while we were simulating, immediately queue another run.
        final latestSignature = _engineOddsSignature(gameEngine);
        if (_lastRequestedOddsSignature != null &&
            latestSignature != _lastCompletedOddsSignature) {
          _scheduleOddsUpdate();
        }
      }
    }
  }

  void _handleDrawerNavigation(int index) {
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => GamesNightScreen(gameEngine: gameEngine)),
      );
      return;
    }

    // For other navigation (Home, Lobby, Guides), we need to confirm quitting the game.
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isNightM3 = gameEngine.currentPhase == GamePhase.night;
        const accent = ClubBlackoutTheme.neonRed;

        if (isNightM3) {
          return ClubAlertDialog(
            title: const Text('Quit game?'),
            content: Text(
              'Navigating away will end the current game session. Progress will be lost unless saved.',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.85)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Quit'),
              ),
            ],
          );
        }

        return BulletinDialogShell(
          accent: accent,
          maxWidth: 560,
          title: Text(
            'QUIT GAME?',
            style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
          ),
          content: Text(
            'Navigating away will end the current game session. Progress will be lost unless saved.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.7),
              ),
              child: const Text('STAY'),
            ),
            ClubBlackoutTheme.hGap8,
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ClubBlackoutTheme.neonButtonStyle(accent, isPrimary: true),
              child: const Text('QUIT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([gameEngine, GamesNightService.instance]),
      builder: (context, _) {
        const accent = ClubBlackoutTheme.neonBlue;
        final viewEngine =
            _viewingArchived ? (_archivedEngine ?? gameEngine) : gameEngine;
        final insights = HostInsightsSnapshot.fromEngine(viewEngine);
        final stats = insights.stats;
        final dashboard = insights.dashboard;

        final isNightM3 =
            !_viewingArchived && viewEngine.currentPhase == GamePhase.night;

        // Unified AppBar for both night and day modes
        AppBar buildUnifiedAppBar() {
          return AppBar(
            backgroundColor: isNightM3 ? null : Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(
              color: isNightM3 ? null : accent,
              shadows: isNightM3
                  ? null
                  : [const Shadow(color: accent, blurRadius: 12)],
            ),
            actionsIconTheme: IconThemeData(
              color: isNightM3 ? null : accent,
              shadows: isNightM3
                  ? null
                  : [const Shadow(color: accent, blurRadius: 12)],
            ),
            title: Text(
              'HOST DASHBOARD',
              style: ClubBlackoutTheme.neonGlowTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
            actions: [
              // Combined Status Menu
              PopupMenuButton<String>(
                icon: Icon(
                  viewEngine.currentPhase == GamePhase.night
                      ? Icons.nightlight_round
                      : (viewEngine.currentPhase == GamePhase.day
                          ? Icons.wb_sunny_rounded
                          : Icons.home_rounded),
                  color: accent,
                  shadows: isNightM3
                      ? null
                      : [const Shadow(color: accent, blurRadius: 12)],
                ),
                offset: const Offset(0, 48),
                color: Colors.grey[900]?.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      '${viewEngine.currentPhase == GamePhase.night ? 'NIGHT' : (viewEngine.currentPhase == GamePhase.day ? 'DAY' : 'LOBBY')} ${viewEngine.dayCount}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    onPressed: _toggleKeepScreenAwake,
                    child: ListenableBuilder(
                      listenable: KeepScreenAwakeService.status,
                      builder: (context, _) {
                        final status = KeepScreenAwakeService.status.value;
                        return Row(
                          children: [
                            Icon(
                              status.enabled
                                  ? Icons.screen_lock_portrait_rounded
                                  : Icons.screen_lock_portrait_outlined,
                              size: 20,
                              color: status.enabled ? accent : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              status.enabled ? 'Awake Active' : 'Enable Awake',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  PopupMenuItem(
                    onPressed: _openPrivacyMode,
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_off_rounded, size: 20),
                        const SizedBox(width: 12),
                        const Text('Privacy Mode'),
                      ],
                    ),
                  ),
                  if (gameEngine.lastArchivedGameBlobJson != null)
                    PopupMenuItem(
                      onPressed: _loadingArchived ? null : _toggleArchivedView,
                      child: Row(
                        children: [
                          Icon(
                            _viewingArchived
                                ? Icons.play_circle_fill_rounded
                                : Icons.history_rounded,
                            size: 20,
                            color: _viewingArchived ? accent : null,
                          ),
                          const SizedBox(width: 12),
                          Text(_viewingArchived
                              ? 'Return to Live'
                              : 'View Archive'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onPressed: (_oddsSimRunning || _viewingArchived)
                        ? null
                        : () => _maybeRunOddsSimulation(),
                    child: Row(
                      children: [
                        if (_oddsSimRunning)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.refresh_rounded, size: 20),
                        const SizedBox(width: 12),
                        const Text('Recalculate Odds'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          );
        }

        if (isNightM3) {
          return _buildNightM3Scaffold(
            context: context,
            engine: gameEngine,
            stats: stats,
            dashboard: dashboard,
            appBar: buildUnifiedAppBar(),
          );
        }

        return Stack(
          children: [
            const Positioned.fill(
              child: NeonBackground(
                accentColor: accent,
                backgroundAsset:
                    'Backgrounds/Club Blackout V2 Game Background.png',
                blurSigma: 12.0,
                showOverlay: true,
                child: SizedBox.expand(),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              floatingActionButton: _buildPrivacyPanicFab(),
              drawer: GameDrawer(
                gameEngine: gameEngine,
                onContinueGameTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(gameEngine: gameEngine),
                    ),
                  );
                },
                onNavigate: _handleDrawerNavigation,
                selectedIndex: -1,
              ),
              appBar: buildUnifiedAppBar(),
              body: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top +
                          kToolbarHeight +
                          8,
                      left: MediaQuery.sizeOf(context).width >= 900 ? 16 : 8,
                      right: MediaQuery.sizeOf(context).width >= 900 ? 16 : 8,
                      bottom: MediaQuery.paddingOf(context).bottom + 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width >= 1200
                              ? 1180
                              : 1000,
                        ),
                        child: DefaultTabController(
                          length: 3,
                          child: Column(
                            children: [
                              if (_viewingArchived) ...[
                                _buildArchivedBanner(context),
                                ClubBlackoutTheme.gap12,
                              ],
                              _buildHostTabs(context),
                              ClubBlackoutTheme.gap12,
                              _buildModeratorToolsCard(context, viewEngine),
                              ClubBlackoutTheme.gap12,
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildOverviewTab(
                                        context, viewEngine, stats, dashboard),
                                    _buildStatsTab(
                                        context, viewEngine, dashboard),
                                    _buildPlayersTab(context, viewEngine),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  HostAlertListener(engine: gameEngine),
                  GameToastListener(engine: gameEngine),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNightM3Scaffold({
    required BuildContext context,
    required GameEngine engine,
    required LiveGameStats stats,
    required dynamic dashboard,
    required AppBar appBar,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final baseOdds = dashboard.odds as GameOddsSnapshot;
    final odds = _simulatedOdds ?? baseOdds;

    final recent = engine.gameLog
        .where((e) => e.type != GameLogType.script)
        .take(12)
        .toList(growable: false);

    final morningText = (engine.lastNightHostRecap.isNotEmpty
            ? engine.lastNightHostRecap
            : engine.lastNightSummary)
        .trim();

    final oddsRows = odds.odds.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget statTile(String label, String value, Color color, IconData icon) {
      return Card(
        elevation: 0,
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: (tt.titleLarge ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: GameDrawer(
        gameEngine: engine,
        onContinueGameTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameScreen(gameEngine: engine),
            ),
          );
        },
        onNavigate: _handleDrawerNavigation,
        selectedIndex: -1,
      ),
      appBar: appBar,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildPrivacyPanicFab(),
      body: LayoutBuilder(
        builder: (context, box) {
          // Designed for Phones: Use 2 columns on phones (< 600), 3 on tablets/desktop
          final isPhone = box.maxWidth < 600;
          final crossAxis = isPhone ? 2 : 3;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                // Use safe area padding for content, allowing background to bleed if we had one
                padding: ClubBlackoutTheme.inset16 +
                    MediaQuery.paddingOf(context).copyWith(top: 0),
                children: [
                  Text(
                    'Night mode (Material 3)',
                    style: (tt.titleSmall ?? const TextStyle()).copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildModeratorToolsCard(context, engine),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxis,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    // Slightly taller tiles on phone to prevent overflow
                    childAspectRatio: isPhone ? 1.25 : 1.35,
                    children: [
                      statTile('Players', stats.totalPlayers.toString(),
                          ClubBlackoutTheme.neonBlue, Icons.groups_rounded),
                    statTile('Alive', stats.aliveCount.toString(),
                        ClubBlackoutTheme.neonGreen, Icons.favorite_rounded),
                    statTile('Dead', stats.deadCount.toString(),
                        ClubBlackoutTheme.neonRed, Icons.cancel_rounded),
                    statTile('Dealers', stats.dealerAliveCount.toString(),
                        ClubBlackoutTheme.neonRed, Icons.dangerous_rounded),
                    statTile('Party', stats.partyAliveCount.toString(),
                        ClubBlackoutTheme.neonBlue, Icons.celebration_rounded),
                    statTile(
                        'Neutral',
                        stats.neutralAliveCount.toString(),
                        ClubBlackoutTheme.neonPurple,
                        Icons.auto_awesome_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHigh,
                  child: Padding(
                    padding: ClubBlackoutTheme.inset16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Win odds',
                          style: (tt.titleMedium ?? const TextStyle())
                              .copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        if (_oddsSimRunning)
                          Row(
                            children: [
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Updating odds…',
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          )
                        else if (_simulatedOddsUpdatedAt != null)
                          Text(
                            "Updated ${_simulatedOddsUpdatedAt!.hour.toString().padLeft(2, '0')}:${_simulatedOddsUpdatedAt!.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        const SizedBox(height: 10),
                        for (final e in oddsRows) ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: e.value.clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor:
                                        cs.onSurface.withValues(alpha: 0.10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(e.value * 100).round()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: cs.onSurface.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (odds.note.isNotEmpty)
                          Text(
                            odds.note,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHigh,
                  child: Padding(
                    padding: ClubBlackoutTheme.inset16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent events',
                          style: (tt.titleMedium ?? const TextStyle())
                              .copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        if (recent.isEmpty)
                          Text(
                            'No events yet.',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                          )
                        else
                          ...recent.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                  if (e.description.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        e.description,
                                        style: TextStyle(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.78),
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHigh,
                  child: Padding(
                    padding: ClubBlackoutTheme.inset16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Morning summary',
                          style: (tt.titleMedium ?? const TextStyle())
                              .copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          morningText.isEmpty ? 'No data yet.' : morningText,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.88),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildHostTabs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NeonGlassCard(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 16,
      opacity: 0.1,
      glowColor: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.2),
      child: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          fontSize: 11,
        ),
        indicator: BoxDecoration(
          color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'STATS'),
          Tab(text: 'PLAYERS'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    GameEngine engine,
    dynamic stats,
    dynamic dashboard,
  ) {
    final baseOdds = dashboard.odds as GameOddsSnapshot;
    final odds = _simulatedOdds ?? baseOdds;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _buildDashboardIntroCard(context),
        ClubBlackoutTheme.gap12,
        _buildSummaryGrid(context, stats),
        ClubBlackoutTheme.gap16,
        _buildSectionHeader(
            'WIN ODDS & PREDICTABILITY', ClubBlackoutTheme.neonBlue),
        ClubBlackoutTheme.gap8,
        _buildPredictabilityCard(context, odds),
        ClubBlackoutTheme.gap8,
        _buildOddsCard(context, odds,
            isUpdating: _oddsSimRunning, updatedAt: _simulatedOddsUpdatedAt),
        ClubBlackoutTheme.gap16,
        _buildSectionHeader('RECENT EVENTS', ClubBlackoutTheme.neonBlue),
        ClubBlackoutTheme.gap8,
        _buildRecentEventsCard(context, engine.gameLog),
        ClubBlackoutTheme.gap16,
        _buildSectionHeader('MORNING SUMMARY', ClubBlackoutTheme.neonBlue),
        ClubBlackoutTheme.gap8,
        NeonGlassCard(
          glowColor: ClubBlackoutTheme.neonBlue,
          padding: const EdgeInsets.all(12),
          child: Text(
            (engine.lastNightHostRecap.isNotEmpty
                        ? engine.lastNightHostRecap
                        : engine.lastNightSummary)
                    .isEmpty
                ? 'No data yet.'
                : (engine.lastNightHostRecap.isNotEmpty
                    ? engine.lastNightHostRecap
                    : engine.lastNightSummary),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        // Night History Viewer
        if (engine.nightHistory.isNotEmpty) ...[
          ClubBlackoutTheme.gap16,
          _buildSectionHeader('NIGHT HISTORY', ClubBlackoutTheme.neonPurple),
          ClubBlackoutTheme.gap8,
          _buildNightHistoryCard(context, engine),
        ],
        ClubBlackoutTheme.gap24,
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        border: Border(
          left: BorderSide(color: color, width: 4),
          bottom: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: ClubBlackoutTheme.headingStyle.copyWith(
          color: color,
          fontSize: 14,
          letterSpacing: 2.0,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab(
      BuildContext context, GameEngine engine, dynamic dashboard) {
    final voting = dashboard.voting as VotingInsights;
    return _HostStatsTab(
      engine: engine,
      dashboard: dashboard,
      voting: voting,
      buildVotingHighlightsCard: (ctx, v, e) =>
          _buildVotingHighlightsCard(ctx, v, e),
      buildVotingCard: _buildVotingCard,
      buildVotingHistoryCard: (ctx) => _buildVotingHistoryCard(ctx, engine),
      buildRoleChipsCard: (ctx) => _buildRoleChipsCard(ctx, dashboard),
      buildHostToolsCard: (ctx) => _buildHostToolsCard(ctx, engine),
      buildAiExportCard: (ctx) => _buildAiExportCard(ctx, engine),
    );
  }

  Widget _buildPlayersTab(BuildContext context, GameEngine engine) {
    return _HostPlayersTab(engine: engine);
  }

  Widget _buildSummaryGrid(BuildContext context, dynamic stats) {
    final s = stats as LiveGameStats;

    Widget tile(String label, String value, Color color, IconData icon) {
      return Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: ClubBlackoutTheme.headingStyle.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: [
          tile('PLAYERS', s.totalPlayers.toString(), ClubBlackoutTheme.neonBlue,
              Icons.groups_rounded),
          tile('ALIVE', s.aliveCount.toString(), ClubBlackoutTheme.neonGreen,
              Icons.favorite_rounded),
          tile('DEAD', s.deadCount.toString(), ClubBlackoutTheme.neonRed,
              Icons.cancel_rounded),
          tile('DEALERS', s.dealerAliveCount.toString(),
              ClubBlackoutTheme.neonRed, Icons.dangerous_rounded),
          tile('PARTY', s.partyAliveCount.toString(), ClubBlackoutTheme.neonBlue,
              Icons.celebration_rounded),
          tile('NEUTRAL', s.neutralAliveCount.toString(),
              ClubBlackoutTheme.neonPurple, Icons.auto_awesome_rounded),
        ],
      ),
    );
  }

  Widget _buildNightHistoryCard(BuildContext context, GameEngine engine) {
    final cs = Theme.of(context).colorScheme;

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonPurple,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'PAST LOGS (${engine.nightHistory.length} NIGHTS)',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          iconColor: ClubBlackoutTheme.neonPurple,
          collapsedIconColor: cs.onSurface.withValues(alpha: 0.7),
          children: engine.nightHistory.asMap().entries.map((entry) {
            final nightNum = entry.key + 1;
            final nightData = entry.value;

            // Extract summary from night data
            final summary = (nightData['summary'] ??
                    nightData['description'] ??
                    nightData['recap'] ??
                    'Night $nightNum records')
                .toString();

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: cs.onSurface.withValues(alpha: 0.05)),
                ),
              ),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: ClubBlackoutTheme.neonPurple
                            .withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$nightNum',
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      fontSize: 12,
                      color: ClubBlackoutTheme.neonPurple,
                    ),
                  ),
                ),
                title: Text(
                  'NIGHT $nightNum ARCHIVE',
                  style: ClubBlackoutTheme.headingStyle.copyWith(fontSize: 10),
                ),
                subtitle: Text(
                  summary.length > 80 ? '${summary.substring(0, 77)}...' : summary,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () => _showNightDetails(context, nightNum, nightData),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNightDetails(
      BuildContext context, int nightNum, dynamic nightData) {
    final cs = Theme.of(context).colorScheme;

    String getDetailedSummary() {
      if (nightData is Map) {
        final buffer = StringBuffer();

        // Show all available data in a readable format
        nightData.forEach((key, value) {
          if (key != null && value != null) {
            buffer.writeln('$key: $value');
            buffer.writeln();
          }
        });

        return buffer.toString().trim().isNotEmpty
            ? buffer.toString()
            : 'No detailed data available for Night $nightNum';
      }
      return nightData?.toString() ?? 'No data';
    }

    showDialog(
      context: context,
      builder: (ctx) => BulletinDialogShell(
        accent: ClubBlackoutTheme.neonPurple,
        title: Text(
          'NIGHT $nightNum DETAILS',
          style: ClubBlackoutTheme.bulletinHeaderStyle(
              ClubBlackoutTheme.neonPurple),
        ),
        content: SingleChildScrollView(
          child: Text(
            getDetailedSummary(),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: cs.onSurface,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsCard(
      BuildContext context, List<GameLogEntry> entries) {
    final cs = Theme.of(context).colorScheme;
    final rows = entries
        .where((e) => e.type != GameLogType.script)
        .take(12)
        .toList(growable: false);

    if (rows.isEmpty) {
      return NeonGlassCard(
        glowColor: ClubBlackoutTheme.neonBlue,
        child: Text(
          'NO EVENTS LOGGED YET.',
          style: ClubBlackoutTheme.headingStyle.copyWith(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.1,
          ),
        ),
      );
    }

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4, right: 10),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ClubBlackoutTheme.neonBlue,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                          color: ClubBlackoutTheme.neonBlue, blurRadius: 4)
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rows[i].title.toUpperCase(),
                        style: ClubBlackoutTheme.headingStyle.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (rows[i].description.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            rows[i].description,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (i < rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(
                  height: 1,
                  color: cs.onSurface.withValues(alpha: 0.05),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildVotingHighlightsCard(
      BuildContext context, VotingInsights voting, GameEngine engine) {
    final cs = Theme.of(context).colorScheme;

    // Eligible voters mirror GameEngine.recordVote constraints.
    final eligibleVoterIds = engine.guests
        .where((p) => p.isAlive && p.isEnabled)
        .where((p) => p.id != GameEngine.hostPlayerId)
        .where((p) => p.role.id != GameEngine.hostRoleId)
        .where((p) => p.role.id != 'ally_cat')
        .where((p) => !p.soberSentHome)
        .where((p) => p.silencedDay != engine.dayCount)
        .map((p) => p.id)
        .toList(growable: false);

    final votedVoterIds = eligibleVoterIds
        .where((id) => engine.currentDayVotesByVoter[id] != null)
        .toList(growable: false);

    final abstainedVoterIds = eligibleVoterIds
        .where((id) => engine.currentDayVotesByVoter[id] == null)
        .toList(growable: false);

    final totalVoters = votedVoterIds.length;
    final eligibleVoters = eligibleVoterIds.length;
    final abstained = abstainedVoterIds.length;

    final playersById = <String, Player>{
      for (final p in engine.players) p.id: p,
    };

    final pendingPredator = engine.pendingPredatorId != null
        ? playersById[engine.pendingPredatorId!]
        : null;

    final predatorVoterIds = engine.pendingPredatorEligibleVoterIds
        .where((id) => id != GameEngine.hostPlayerId)
        .toSet()
        .toList(growable: false)
      ..sort((a, b) {
        final an = playersById[a]?.name ?? a;
        final bn = playersById[b]?.name ?? b;
        return an.compareTo(bn);
      });

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonPurple,
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(
          'VOTING ANALYTICS',
          style: ClubBlackoutTheme.headingStyle.copyWith(
            color: ClubBlackoutTheme.neonPurple,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        subtitle: Text(
          '$totalVoters voted • $abstained abstained',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        iconColor: ClubBlackoutTheme.neonPurple,
        collapsedIconColor: cs.onSurface.withValues(alpha: 0.7),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'DAY ${engine.dayCount} BREAKdown'.toUpperCase(),
                  style: ClubBlackoutTheme.headingStyle.copyWith(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.9),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildVotingStatRow('Total Eligible', '$eligibleVoters', cs),
                _buildVotingStatRow('Voted', '$totalVoters', cs),
                _buildVotingStatRow('Abstained', '$abstained', cs),
                const SizedBox(height: 16),
                if (pendingPredator != null) ...[
                  Text(
                    'PREDATOR RETALIATION',
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      fontSize: 12,
                      color: ClubBlackoutTheme.neonRed,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target: ${pendingPredator.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (predatorVoterIds.isEmpty)
                    Text(
                      'No recorded Predator voters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: predatorVoterIds
                          .map(
                            (id) => Chip(
                              label: Text(
                                playersById[id]?.name ?? id,
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              side: BorderSide(
                                color: ClubBlackoutTheme.neonRed
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  const SizedBox(height: 12),
                ],
                if (abstained > 0) ...[
                  Text(
                    'Abstentions',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildAbstainersList(context, engine, abstainedVoterIds, cs),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingStatRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.85),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbstainersList(
    BuildContext context,
    GameEngine engine,
    List<String> abstainedVoterIds,
    ColorScheme cs,
  ) {
    final playersById = <String, Player>{
      for (final p in engine.players) p.id: p,
    };

    final abstainers = abstainedVoterIds
        .map((id) => playersById[id]?.name ?? id)
        .toList(growable: false);

    if (abstainers.isEmpty) {
      return Text(
        'Everyone voted!',
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: abstainers
          .map(
            (name) => Chip(
              label: Text(
                name,
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor:
                  cs.surfaceContainerHighest.withValues(alpha: 0.5),
              side: BorderSide(
                color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildVotingHistoryCard(BuildContext context, GameEngine engine) {
    final cs = Theme.of(context).colorScheme;

    final insights = VotingInsights.fromEngine(engine);
    final days = insights.daySnapshots;

    if (days.isEmpty) {
      return NeonGlassCard(
        glowColor: ClubBlackoutTheme.neonPurple,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No vote history yet.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonPurple,
      child: ExpansionTile(
        title: const Text(
          'Vote History (By Day)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          '${days.length} ${days.length == 1 ? "day" : "days"} recorded',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        iconColor: ClubBlackoutTheme.neonPurple,
        collapsedIconColor: cs.onSurface.withValues(alpha: 0.7),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: days.map((snapshot) {
                final voteCount = snapshot.votesByTarget.values
                    .fold<int>(0, (sum, voters) => sum + voters.length);
                final abstained = snapshot.abstainedVoterIds.length;
                final targets = snapshot.votesByTarget.length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            ClubBlackoutTheme.neonPurple.withValues(alpha: 0.4),
                      ),
                      backgroundColor: cs.surface,
                    ),
                    onPressed: () =>
                        _showDayVoteDetailsDialog(context, engine, snapshot),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Day ${snapshot.day}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$voteCount votes • $abstained abstained • $targets targets',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: ClubBlackoutTheme.neonPurple,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  void _showDayVoteDetailsDialog(
    BuildContext context,
    GameEngine engine,
    DayVoteSnapshot snapshot,
  ) {
    final cs = Theme.of(context).colorScheme;
    final playersById = <String, Player>{
      for (final p in engine.players) p.id: p,
    };

    final targets = snapshot.votesByTarget.entries.toList(growable: false)
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final abstainers = snapshot.abstainedVoterIds
        .map((id) => playersById[id]?.name ?? id)
        .toList(growable: false);

    showDialog(
      context: context,
      builder: (context) => BulletinDialogShell(
        accent: ClubBlackoutTheme.neonPurple,
        maxWidth: 560,
        title: Text(
          'DAY ${snapshot.day} VOTES',
          style: ClubBlackoutTheme.bulletinHeaderStyle(
            ClubBlackoutTheme.neonPurple,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vote actions recorded: ${snapshot.voteActions}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              if (targets.isEmpty)
                Text(
                  'No final votes recorded.',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                )
              else
                ...targets.map((entry) {
                  final targetId = entry.key;
                  final voterIds = entry.value;
                  final targetName = playersById[targetId]?.name ?? targetId;
                  final voterNames = voterIds
                      .map((id) => playersById[id]?.name ?? id)
                      .toList(growable: false);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$targetName — ${voterIds.length}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voterNames.join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              if (abstainers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Final abstentions (${abstainers.length})',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: abstainers
                      .map(
                        (name) => Chip(
                          label: Text(
                            name,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          backgroundColor:
                              cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          side: BorderSide(
                            color: ClubBlackoutTheme.neonPurple
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingCard(BuildContext context, VotingInsights voting) {
    final cs = Theme.of(context).colorScheme;
    final breakdown = voting.currentBreakdown;

    if (breakdown.isEmpty) {
      return NeonGlassCard(
        glowColor: ClubBlackoutTheme.neonBlue,
        child: Text(
          'No votes recorded yet.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
        ),
      );
    }

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT VOTES',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              color: ClubBlackoutTheme.neonBlue,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          for (final row in breakdown) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.targetName.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    row.voteCount.toString(),
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      fontSize: 14,
                      color: ClubBlackoutTheme.neonBlue,
                    ),
                  ),
                ),
              ],
            ),
            if (row.voterNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  row.voterNames.join(' • '),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.60),
                    letterSpacing: 0.3,
                  ),
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleChipsCard(BuildContext context, dynamic dashboard) {
    final cs = Theme.of(context).colorScheme;
    final chips = (dashboard as GameDashboardStats).roleChips;

    if (chips.isEmpty) {
      return NeonGlassCard(
        glowColor: ClubBlackoutTheme.neonPurple,
        child: Text(
          'No roles available.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
        ),
      );
    }

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonPurple,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE ROLES',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              color: ClubBlackoutTheme.neonPurple,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final c in chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.color.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${c.roleName.toUpperCase()} • ${c.aliveCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: cs.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiExportCard(BuildContext context, GameEngine engine) {
    final cs = Theme.of(context).colorScheme;
    final isExportingAiStats = _isExportingAiStats;
    final isExportingCommentary = _isExportingCommentary;

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'AI DATA EXPORT',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              color: ClubBlackoutTheme.neonBlue,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Extract structured game state for AI analysis or commentary generation.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'RAW GAME STATS (JSON)',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.9),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Tooltip(
                message: 'Copy Game Stats JSON',
                child: FilledButton.icon(
                  onPressed: isExportingAiStats
                      ? null
                      : () => _copyAiGameStatsJson(context, engine),
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonBlue,
                    isPrimary: true,
                  ),
                  icon: isExportingAiStats
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('COPY JSON'),
                ),
              ),
              Tooltip(
                message: 'Save Game Stats JSON',
                child: FilledButton.icon(
                  onPressed: isExportingAiStats
                      ? null
                      : () => _saveAiGameStatsJson(context, engine),
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonBlue,
                    isPrimary: false,
                  ),
                  icon: isExportingAiStats
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text('SAVE FILE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: cs.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Text(
            'AI COMMENTARY PROMPT',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              fontSize: 11,
              color: ClubBlackoutTheme.neonPurple,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configured for PG / RUDE / HARD-R personas.',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Tooltip(
                message: 'Copy Prompt',
                child: FilledButton.icon(
                  onPressed: isExportingCommentary
                      ? null
                      : () => _copyAiCommentaryPrompt(context, engine),
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonPurple,
                    isPrimary: true,
                  ),
                  icon: isExportingCommentary
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.content_copy_rounded, size: 18),
                  label: const Text('COPY PROMPT'),
                ),
              ),
              Tooltip(
                message: 'Save Prompt',
                child: FilledButton.icon(
                  onPressed: isExportingCommentary
                      ? null
                      : () => _saveAiCommentaryPrompt(context, engine),
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonPurple,
                    isPrimary: false,
                  ),
                  icon: isExportingCommentary
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text('SAVE FILE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHostToolsCard(BuildContext context, GameEngine engine) {
    final cs = Theme.of(context).colorScheme;
    final hasPending = engine.dramaQueenSwapPending ||
      engine.hasPendingPredatorRetaliation ||
      engine.hasPendingTeaSpillerReveal ||
      engine.messyBitchVictoryPending;

    final canControlScript =
        engine.currentPhase != GamePhase.lobby && engine.scriptQueue.isNotEmpty;
    final canRegress = canControlScript && engine.currentScriptIndex > 0;
    final currentStep = engine.currentScriptStep;

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonOrange,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'QUICK CONTROLS',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              color: ClubBlackoutTheme.neonOrange,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            child: Builder(
              builder: (context) {
                if (currentStep == null) {
                  return Text(
                    canControlScript
                        ? 'No active script step.'
                        : 'Game script controls are available once the game starts.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }

                Player? stepPlayer;
                final stepRoleId = currentStep.roleId;
                if (stepRoleId != null && stepRoleId.isNotEmpty) {
                  try {
                    stepPlayer = engine.players.firstWhere(
                      (p) =>
                          p.role.id == stepRoleId &&
                          p.isActive &&
                          !p.soberSentHome,
                    );
                  } catch (_) {}
                }

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT STEP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface.withValues(alpha: 0.4),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentStep.title,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (stepPlayer != null) ...[
                      const SizedBox(width: 12),
                      UnifiedPlayerTile.minimal(
                        player: stepPlayer,
                        gameEngine: engine,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonBlue,
                    isPrimary: false,
                  ),
                  onPressed: canRegress
                      ? () {
                          engine.regressScript();
                          engine.showToast('Went back one step.');
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('PREV'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonGreen,
                    isPrimary: true,
                  ),
                  onPressed: canControlScript
                      ? () {
                          engine.advanceScript();
                        }
                      : null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('NEXT'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonRed,
                    isPrimary: true,
                  ),
                  onPressed: canControlScript
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              final cs = Theme.of(ctx).colorScheme;
                              return ClubAlertDialog(
                                title: const Text('SKIP TO NEXT PHASE?'),
                                icon: Icon(Icons.fast_forward_rounded,
                                    color: cs.error),
                                content: Text(
                                  'This fast-forwards the remaining script steps for this phase.\n\nUse when you need to recover from a mistake or keep the night moving.',
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.85),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('CANCEL'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.error,
                                      foregroundColor: cs.onError,
                                    ),
                                    child: const Text('SKIP'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm != true) return;
                          engine.skipToNextPhase();
                          engine.showToast('Skipped to next phase.');
                        }
                      : null,
                  icon: const Icon(Icons.fast_forward_rounded, size: 18),
                  label: const Text('SKIP'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: ClubBlackoutTheme.neonButtonStyle(
              ClubBlackoutTheme.neonOrange,
              isPrimary: true,
            ),
            onPressed: _isExportingStory
                ? null
                : () => _copyStorySnapshotJson(context),
            icon: _isExportingStory
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_stories_rounded, size: 18),
            label: Text(_isExportingStory ? 'COPYING...' : 'COPY STORY JSON'),
          ),
          const SizedBox(height: 24),
          Text(
            'PENDING ACTIONS',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          if (!hasPending)
            Text(
              'No pending host actions.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          if (engine.dramaQueenSwapPending) ...[
            const SizedBox(height: 8),
            _DramaQueenSwapPanel(gameEngine: engine),
          ],
          if (engine.hasPendingPredatorRetaliation) ...[
            const SizedBox(height: 12),
            _PredatorRetaliationPanel(gameEngine: engine),
          ],
          if (engine.hasPendingTeaSpillerReveal) ...[
            const SizedBox(height: 12),
            _TeaSpillerRevealPanel(gameEngine: engine),
          ],
          if (engine.messyBitchVictoryPending) ...[
            const SizedBox(height: 12),
            _buildPendingRow(
              context,
              icon: Icons.record_voice_over_rounded,
              color: ClubBlackoutTheme.neonPurple,
              title: 'MESSY BITCH VICTORY PENDING',
              subtitle:
                  'Rumours reached everyone. Declare to end the game now.',
              trailing: FilledButton(
                style: ClubBlackoutTheme.neonButtonStyle(
                  ClubBlackoutTheme.neonPurple,
                  isPrimary: true,
                ),
                onPressed: engine.declareMessyBitchVictory,
                child: const Text('DECLARE WIN'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: ClubBlackoutTheme.headingStyle.copyWith(
                    fontSize: 11,
                    color: cs.onSurface,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardIntroCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonBlue,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: ClubBlackoutTheme.neonBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE DASHBOARD',
                  style: ClubBlackoutTheme.headingStyle.copyWith(
                    color: ClubBlackoutTheme.neonBlue,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Real-time win odds, voting activity, and role metrics.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: ClubBlackoutTheme.neonPurple,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Confidence indicates game stability.',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictabilityCard(BuildContext context, GameOddsSnapshot odds) {
    final rows = odds.sortedDesc;
    if (rows.isEmpty) {
      return const NeonGlassCard(
        glowColor: ClubBlackoutTheme.neonPurple,
        child: Text('No odds available yet.'),
      );
    }

    final clamped = rows
        .map((e) => MapEntry(e.key, e.value.clamp(0.0, 1.0)))
        .toList(growable: false);
    final top = clamped.first;
    final second = clamped.length > 1
        ? clamped[1]
        : const MapEntry<String, double>('', 0.0);

    // A simple confidence metric: leader probability + separation from runner-up.
    final leader = top.value;
    final spread = (leader - second.value).clamp(0.0, 1.0);
    final confidence = (leader * 0.65 + spread * 0.35).clamp(0.0, 1.0);

    String bandLabel(double c) {
      if (c >= 0.72) return 'HIGH';
      if (c >= 0.52) return 'MEDIUM';
      return 'LOW';
    }

    Color bandColor(double c) {
      if (c >= 0.72) return ClubBlackoutTheme.neonGreen;
      if (c >= 0.52) return ClubBlackoutTheme.neonOrange;
      return ClubBlackoutTheme.neonPink;
    }

    String labelFor(String token) {
      switch (token) {
        case 'DEALER':
          return 'Dealers';
        case 'PARTY_ANIMAL':
          return 'Party Animals';
        case 'CLUB_MANAGER':
          return 'Club Manager';
        case 'MESSY_BITCH':
          return 'Messy Bitch';
        default:
          return token;
      }
    }

    final band = bandLabel(confidence);
    final bandC = bandColor(confidence);

    return NeonGlassCard(
      glowColor: bandC,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'PREDICTABILITY: $band',
                      style: ClubBlackoutTheme.headingStyle.copyWith(
                        fontSize: 12,
                        color: bandC,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'Formula: (Leader chance × 65%) + (Separation from runner-up × 35%)\n\nHIGH: ≥72% | MEDIUM: 52-72% | LOW: <52%',
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(confidence * 100).round()}%',
                style: ClubBlackoutTheme.headingStyle.copyWith(
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current leader: ${labelFor(top.key).toUpperCase()} (${(top.value * 100).round()}%)',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.85)),
          ),
          if (second.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Runner-up: ${labelFor(second.key).toUpperCase()} (${(second.value * 100).round()}%)',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.60)),
              ),
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 12,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              color: bandC.withValues(alpha: 0.9),
            ),
          ),
          if (odds.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bandC.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bandC.withValues(alpha: 0.15)),
              ),
              child: Text(
                odds.note,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOddsCard(
    BuildContext context,
    GameOddsSnapshot odds, {
    required bool isUpdating,
    required DateTime? updatedAt,
  }) {
    final rows = odds.sortedDesc;
    if (rows.isEmpty) {
      return const NeonGlassCard(
        glowColor: ClubBlackoutTheme.neonPurple,
        child: Text('No odds available.'),
      );
    }

    Color colorFor(String token) {
      switch (token) {
        case 'DEALER':
          return ClubBlackoutTheme.neonRed;
        case 'PARTY_ANIMAL':
          return ClubBlackoutTheme.neonBlue;
        case 'CLUB_MANAGER':
          return ClubBlackoutTheme.neonGreen;
        case 'MESSY_BITCH':
          return ClubBlackoutTheme.neonOrange;
        default:
          return ClubBlackoutTheme.neonPurple;
      }
    }

    String labelFor(String token) {
      switch (token) {
        case 'DEALER':
          return 'Dealers';
        case 'PARTY_ANIMAL':
          return 'Party Animals';
        case 'CLUB_MANAGER':
          return 'Club Manager';
        case 'MESSY_BITCH':
          return 'Messy Bitch';
        default:
          return token;
      }
    }

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUpdating || updatedAt != null) ...[
            Row(
              children: [
                if (isUpdating) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ClubBlackoutTheme.neonPurple,
                    ),
                  ),
                  ClubBlackoutTheme.hGap12,
                ],
                Expanded(
                  child: Text(
                    isUpdating
                        ? 'RUNNING CLOUD SIMULATION…'
                        : (updatedAt == null
                            ? ''
                            : "LAST SYNC: ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}"),
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            ClubBlackoutTheme.gap12,
          ],
          for (final e in rows) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      labelFor(e.key).toUpperCase(),
                      style: ClubBlackoutTheme.headingStyle.copyWith(
                        fontSize: 11,
                        color: colorFor(e.key),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08),
                        color: colorFor(e.key).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(e.value * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: ClubBlackoutTheme.headingStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (odds.note.isNotEmpty) ...[
            ClubBlackoutTheme.gap4,
            Text(
              odds.note,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyStorySnapshotJson(BuildContext context) async {
    setState(() => _isExportingStory = true);
    try {
      final snapshot = gameEngine.exportStorySnapshot();
      final jsonText =
          const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
      await Clipboard.setData(ClipboardData(text: jsonText));
      if (!context.mounted) return;
      gameEngine.showToast('Copied story snapshot JSON', title: 'Success');
    } finally {
      if (mounted) setState(() => _isExportingStory = false);
    }
  }

  Future<AiCommentaryStyle?> _pickAiStyle(
    BuildContext context, {
    AiCommentaryStyle initial = AiCommentaryStyle.pg,
    String title = 'Select Commentary Style',
  }) async {
    return showDialog<AiCommentaryStyle>(
      context: context,
      builder: (ctx) {
        AiCommentaryStyle selected = initial;
        return StatefulBuilder(
          builder: (ctx, setState) {
            final cs = Theme.of(ctx).colorScheme;
            const accent = ClubBlackoutTheme.neonBlue;
            return BulletinDialogShell(
              accent: accent,
              maxWidth: 640,
              title: Text(
                title.toUpperCase(),
                style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AiCommentaryStyle.values
                        .map(
                          (s) => ChoiceChip(
                            label: Text(s.label),
                            selected: selected == s,
                            onSelected: (_) => setState(() => selected = s),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selected.shortGuidance,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.8),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                  ),
                  child: const Text('CANCEL'),
                ),
                ClubBlackoutTheme.hGap8,
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  style: ClubBlackoutTheme.neonButtonStyle(accent,
                      isPrimary: true),
                  child: const Text('SELECT'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _copyAiGameStatsJson(
      BuildContext context, GameEngine engine) async {
    setState(() => _isExportingAiStats = true);
    try {
      final export = buildAiGameStatsExport(engine);
      final jsonText = const JsonEncoder.withIndent('  ').convert(export);
      await Clipboard.setData(ClipboardData(text: jsonText));
      if (!context.mounted) return;
      gameEngine.showToast('Copied AI Game Stats JSON', title: 'Success');
    } finally {
      if (mounted) setState(() => _isExportingAiStats = false);
    }
  }

  Future<void> _saveAiGameStatsJson(
      BuildContext context, GameEngine engine) async {
    setState(() => _isExportingAiStats = true);
    try {
      final export = buildAiGameStatsExport(engine);
      final jsonText = const JsonEncoder.withIndent('  ').convert(export);

      final stamp = ExportFileService.safeTimestampForFilename(DateTime.now());
      final file = await ExportFileService.saveText(
        fileName: 'ai_game_stats_$stamp.json',
        content: jsonText,
      );

      if (!context.mounted) return;
      engine.showToast(
        'Saved AI Game Stats JSON to ${file.path}',
        actionLabel:
            ExportFileService.supportsOpenFolder ? 'OPEN FOLDER' : 'SHARE',
        onAction: () {
          if (ExportFileService.supportsOpenFolder) {
            _openExportsFolder(context, engine);
            return;
          }
          ExportFileService.shareFile(file,
              subject: 'Club Blackout: AI Game Stats');
        },
      );
    } finally {
      if (mounted) setState(() => _isExportingAiStats = false);
    }
  }

  Future<void> _copyAiCommentaryPrompt(
      BuildContext context, GameEngine engine) async {
    final style = await _pickAiStyle(context);
    if (style == null) return;

    setState(() => _isExportingCommentary = true);
    try {
      final export = buildAiGameStatsExport(engine);
      final prompt =
          await buildAiCommentaryPrompt(style: style, gameStatsExport: export);
      await Clipboard.setData(ClipboardData(text: prompt));
      if (!context.mounted) return;
      engine.showToast('Copied ${style.label} commentary prompt');
    } finally {
      if (mounted) setState(() => _isExportingCommentary = false);
    }
  }

  Future<void> _saveAiCommentaryPrompt(
      BuildContext context, GameEngine engine) async {
    final style = await _pickAiStyle(context);
    if (style == null) return;

    setState(() => _isExportingCommentary = true);
    try {
      final export = buildAiGameStatsExport(engine);
      final prompt =
          await buildAiCommentaryPrompt(style: style, gameStatsExport: export);

      final stamp = ExportFileService.safeTimestampForFilename(DateTime.now());
      final file = await ExportFileService.saveText(
        fileName: 'ai_commentary_prompt_${style.label}_$stamp.txt',
        content: prompt,
        // Default to downloads folder if available
        useDownloadsFolder: true,
      );

      if (!context.mounted) return;

      // Show persistent toast that remains until user takes action
      engine.showPersistentToast(
        title: 'AI Commentary Prompt Saved',
        message: 'Stored on this device at:\n${file.path}',
        content: prompt,
        onShare: () {
          engine.dismissPersistentToast();
          if (ExportFileService.supportsOpenFolder) {
            _openExportsFolder(context, engine);
          } else {
            ExportFileService.shareFile(file,
                subject: 'Club Blackout: ${style.label} Commentary Prompt');
          }
        },
        onIgnore: () {
          engine.dismissPersistentToast();
        },
      );
    } finally {
      if (mounted) setState(() => _isExportingCommentary = false);
    }
  }

  Future<void> _openExportsFolder(
      BuildContext context, GameEngine engine) async {
    try {
      await ExportFileService.openExportsFolder();
      if (!context.mounted) return;
      engine.showToast('Opened exports folder.');
    } catch (_) {
      if (!context.mounted) return;
      engine.showToast('Unable to open exports folder on this platform.');
    }
  }
}

typedef _SimpleContextWidgetBuilder = Widget Function(BuildContext context);

class _HostStatsTab extends StatelessWidget {
  final GameEngine engine;
  final dynamic dashboard;
  final VotingInsights voting;

  final Widget Function(
          BuildContext context, VotingInsights voting, GameEngine engine)
      buildVotingHighlightsCard;
  final Widget Function(BuildContext context, VotingInsights voting)
      buildVotingCard;
  final _SimpleContextWidgetBuilder buildVotingHistoryCard;
  final _SimpleContextWidgetBuilder buildRoleChipsCard;
  final _SimpleContextWidgetBuilder buildHostToolsCard;
  final _SimpleContextWidgetBuilder buildAiExportCard;

  const _HostStatsTab({
    required this.engine,
    required this.dashboard,
    required this.voting,
    required this.buildVotingHighlightsCard,
    required this.buildVotingCard,
    required this.buildVotingHistoryCard,
    required this.buildRoleChipsCard,
    required this.buildHostToolsCard,
    required this.buildAiExportCard,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        buildVotingHighlightsCard(context, voting, engine),
        ClubBlackoutTheme.gap8,
        buildVotingHistoryCard(context),
        ClubBlackoutTheme.gap8,
        buildVotingCard(context, voting),
        ClubBlackoutTheme.gap16,
        buildRoleChipsCard(context),
        ClubBlackoutTheme.gap16,
        buildHostToolsCard(context),
        ClubBlackoutTheme.gap16,
        buildAiExportCard(context),
      ],
    );
  }
}

class _DramaQueenSwapPanel extends StatelessWidget {
  final GameEngine gameEngine;
  const _DramaQueenSwapPanel({required this.gameEngine});

  void _showSwapDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DramaQueenSwapDialog(
        gameEngine: gameEngine,
        onConfirm: (a, b) {
          gameEngine.completeDramaQueenSwap(a, b);
          gameEngine.showToast('Swap completed.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Drama Queen swap pending',
            style: ClubBlackoutTheme.glowTextStyle(
              color: ClubBlackoutTheme.neonPurple,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          ClubBlackoutTheme.gap12,
          Text(
            'The Drama Queen has died and must swap two players\' roles.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          ClubBlackoutTheme.gap16,
          Center(
            child: FilledButton.icon(
              style: ClubBlackoutTheme.neonButtonStyle(
                ClubBlackoutTheme.neonPurple,
                isPrimary: true,
              ),
              icon: const Icon(Icons.swap_calls_rounded),
              label: const Text('Select players to swap'),
              onPressed: () => _showSwapDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredatorRetaliationPanel extends StatefulWidget {
  final GameEngine gameEngine;
  const _PredatorRetaliationPanel({required this.gameEngine});

  @override
  State<_PredatorRetaliationPanel> createState() =>
      _PredatorRetaliationPanelState();
}

class _PredatorRetaliationPanelState extends State<_PredatorRetaliationPanel> {
  String? _target;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final engine = widget.gameEngine;
    final alive = engine.guests.where((p) => p.isAlive && p.isEnabled).toList();

    final predatorId = engine.pendingPredatorId;
    final baseCandidates = predatorId == null
        ? alive
        : alive.where((p) => p.id != predatorId).toList();

    final eligibleVoters = engine.pendingPredatorEligibleVoterIds.toSet();
    final preferredId = engine.pendingPredatorPreferredTargetId;

    // If the engine captured a voter list, constrain to it, but always include
    // the preferred marked target if present.
    final candidates = eligibleVoters.isNotEmpty
        ? baseCandidates
            .where((p) => eligibleVoters.contains(p.id) || p.id == preferredId)
            .toList()
        : baseCandidates;

    final items = candidates
        .map(
          (p) => DropdownMenuItem<String>(
            value: p.id,
            child: Text(p.name),
          ),
        )
        .toList();

    InputDecoration buildNeonDecoration({required String label}) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.12),
        contentPadding: ClubBlackoutTheme.fieldPadding,
        border: OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(
            color: ClubBlackoutTheme.neonRed.withValues(alpha: 0.30),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(
            color: ClubBlackoutTheme.neonRed.withValues(alpha: 0.30),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(color: ClubBlackoutTheme.neonRed, width: 2),
        ),
      );
    }

    _target ??= (engine.pendingPredatorPreferredTargetId != null &&
            candidates
                .any((p) => p.id == engine.pendingPredatorPreferredTargetId))
        ? engine.pendingPredatorPreferredTargetId
        : null;

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Predator Retaliation',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Choose who dies with the Predator:',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>(_target),
            initialValue: _target,
            decoration: buildNeonDecoration(label: 'Select target'),
            items: items,
            onChanged: (v) => setState(() => _target = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: ClubBlackoutTheme.neonButtonStyle(
              ClubBlackoutTheme.neonRed,
              isPrimary: true,
            ),
            onPressed: _target == null
                ? null
                : () {
                    final ok = engine.completePredatorRetaliation(_target!);
                    if (!ok) {
                      widget.gameEngine.showToast('Retaliation failed.');
                      return;
                    }
                    setState(() => _target = null);
                    widget.gameEngine.showToast('Retaliation applied.');
                  },
            child: const Text('Retaliate'),
          ),
        ],
      ),
    );
  }
}

class _TeaSpillerRevealPanel extends StatefulWidget {
  final GameEngine gameEngine;
  const _TeaSpillerRevealPanel({required this.gameEngine});

  @override
  State<_TeaSpillerRevealPanel> createState() => _TeaSpillerRevealPanelState();
}

class _TeaSpillerRevealPanelState extends State<_TeaSpillerRevealPanel> {
  String? _target;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final engine = widget.gameEngine;

    final teaId = engine.pendingTeaSpillerId;
    final teaName = teaId == null
        ? 'Tea Spiller'
        : (engine.players.where((p) => p.id == teaId).firstOrNull?.name ??
            'Tea Spiller');

    final alive = engine.guests.where((p) => p.isAlive && p.isEnabled).toList();
    final candidates = teaId == null
        ? const <Player>[]
        : alive
            .where(
                (p) => engine.pendingTeaSpillerEligibleVoterIds.contains(p.id))
            .toList(growable: false);

    final items = candidates
        .map(
          (p) => DropdownMenuItem<String>(
            value: p.id,
            child: Text(p.name),
          ),
        )
        .toList(growable: false);

    InputDecoration buildNeonDecoration({required String label}) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.12),
        contentPadding: ClubBlackoutTheme.fieldPadding,
        border: OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(
            color: ClubBlackoutTheme.neonOrange.withValues(alpha: 0.30),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(
            color: ClubBlackoutTheme.neonOrange.withValues(alpha: 0.30),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(color: ClubBlackoutTheme.neonOrange, width: 2),
        ),
      );
    }

    // Reset selection if it becomes invalid.
    if (_target != null && !candidates.any((p) => p.id == _target)) {
      _target = null;
    }

    return NeonGlassCard(
      glowColor: ClubBlackoutTheme.neonOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tea Spiller Reveal',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '$teaName was eliminated by vote. Choose 1 of their voters to expose:',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>(_target),
            initialValue: _target,
            decoration: buildNeonDecoration(label: 'Select target'),
            items: items,
            onChanged: (v) => setState(() => _target = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: ClubBlackoutTheme.neonButtonStyle(
              ClubBlackoutTheme.neonOrange,
              isPrimary: true,
            ),
            onPressed: _target == null
                ? null
                : () {
                    final ok = engine.completeTeaSpillerReveal(_target!);
                    if (!ok) {
                      widget.gameEngine
                          .showToast('Reveal failed. Please try again.');
                      return;
                    }
                    setState(() => _target = null);
                    widget.gameEngine.showToast('Tea spilled.');
                  },
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
  }
}

enum _RosterStatusFilter { all, alive, dead }

class _HostPlayersTab extends StatefulWidget {
  final GameEngine engine;

  const _HostPlayersTab({required this.engine});

  @override
  State<_HostPlayersTab> createState() => _HostPlayersTabState();
}

class _HostPlayersTabState extends State<_HostPlayersTab> {
  final TextEditingController _searchController = TextEditingController();
  _RosterStatusFilter _statusFilter = _RosterStatusFilter.all;
  bool _onlyEnabled = false;
  String? _selectedPlayerId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final engine = widget.engine;
    final q = _searchController.text.trim().toLowerCase();

    bool matchesSearch(Player p) {
      if (q.isEmpty) return true;
      final name = p.name.toLowerCase();
      final roleName = p.role.name.toLowerCase();
      return name.contains(q) || roleName.contains(q);
    }

    bool matchesFilter(Player p) {
      if (_onlyEnabled && !p.isEnabled) return false;

      switch (_statusFilter) {
        case _RosterStatusFilter.all:
          return true;
        case _RosterStatusFilter.alive:
          return p.isAlive;
        case _RosterStatusFilter.dead:
          return !p.isAlive;
      }
    }

    final filtered = engine.guests
        .where((p) => matchesFilter(p) && matchesSearch(p))
        .toList();
    filtered.sort((a, b) {
      // Alive first, enabled first, then name.
      final aliveCmp = (b.isAlive ? 1 : 0).compareTo(a.isAlive ? 1 : 0);
      if (aliveCmp != 0) return aliveCmp;
      final enabledCmp = (b.isEnabled ? 1 : 0).compareTo(a.isEnabled ? 1 : 0);
      if (enabledCmp != 0) return enabledCmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    final alive = filtered.where((p) => p.isAlive).toList();
    final dead = filtered.where((p) => !p.isAlive).toList();

    InputDecoration buildNeonDecoration(
        {required String label, required IconData icon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: ClubBlackoutTheme.neonGlowFont.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon,
            color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.7)),
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.12),
        contentPadding: ClubBlackoutTheme.fieldPadding,
        border: OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(
            color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.30),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(
            color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.30),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: ClubBlackoutTheme.borderRadiusControl,
          borderSide: BorderSide(color: ClubBlackoutTheme.neonBlue, width: 2),
        ),
      );
    }

    Widget buildFilterChip({
      required String label,
      required bool selected,
      required VoidCallback onSelected,
    }) {
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: cs.surface.withValues(alpha: 0.35),
        backgroundColor: cs.surface.withValues(alpha: 0.18),
        side: BorderSide(
          color: (selected ? ClubBlackoutTheme.neonBlue : cs.onSurface)
              .withValues(alpha: selected ? 0.55 : 0.18),
        ),
        labelStyle: ClubBlackoutTheme.neonGlowFont.copyWith(
          color: cs.onSurface,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      );
    }

    Widget buildPlayerCard(Player p) {
      final isSelected = _selectedPlayerId == p.id;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UnifiedPlayerTile.dashboard(
            player: p,
            gameEngine: engine,
            isSelected: isSelected,
            onTap: () => setState(() {
              if (_selectedPlayerId == p.id) {
                _selectedPlayerId = null;
              } else {
                _selectedPlayerId = p.id;
              }
            }),
            trailing: (p.role.id == 'clinger' &&
                    p.isActive &&
                    !p.clingerFreedAsAttackDog &&
                    p.clingerPartnerId != null)
                ? IconButton(
                    tooltip: 'Mark freed (called "controller")',
                    icon: const Icon(Icons.link_off_rounded),
                    onPressed: () {
                      final partnerName = (p.clingerPartnerId == null)
                          ? null
                          : engine.players
                              .where((x) => x.id == p.clingerPartnerId)
                              .firstOrNull
                              ?.name;
                      final ok = engine.freeClingerFromObsession(p.id);
                      final msg = ok
                          ? (partnerName != null
                              ? '${p.name} was called "controller" by $partnerName and is now unleashed.'
                              : '${p.name} is now unleashed.')
                          : 'Unable to mark ${p.name} as unleashed.';
                      engine.showToast(msg);
                    },
                  )
                : null,
          ),
          if (isSelected) _buildQuickActions(p, engine),
        ],
      );
    }

    const horizPad = EdgeInsets.symmetric(horizontal: 8);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: horizPad,
          sliver: SliverToBoxAdapter(
            child: NeonGlassCard(
              glowColor: ClubBlackoutTheme.neonBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: buildNeonDecoration(
                      label: 'Search name or role',
                      icon: Icons.search_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      buildFilterChip(
                        label: 'All',
                        selected: _statusFilter == _RosterStatusFilter.all,
                        onSelected: () => setState(
                            () => _statusFilter = _RosterStatusFilter.all),
                      ),
                      buildFilterChip(
                        label: 'Alive',
                        selected: _statusFilter == _RosterStatusFilter.alive,
                        onSelected: () => setState(
                            () => _statusFilter = _RosterStatusFilter.alive),
                      ),
                      buildFilterChip(
                        label: 'Dead',
                        selected: _statusFilter == _RosterStatusFilter.dead,
                        onSelected: () => setState(
                            () => _statusFilter = _RosterStatusFilter.dead),
                      ),
                      FilterChip(
                        label: const Text('Only enabled'),
                        selected: _onlyEnabled,
                        onSelected: (v) => setState(() => _onlyEnabled = v),
                        selectedColor: cs.surface.withValues(alpha: 0.35),
                        backgroundColor: cs.surface.withValues(alpha: 0.18),
                        side: BorderSide(
                          color: ClubBlackoutTheme.neonBlue
                              .withValues(alpha: _onlyEnabled ? 0.55 : 0.18),
                        ),
                        labelStyle: TextStyle(
                          color: cs.onSurface,
                          fontWeight:
                              _onlyEnabled ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${filtered.length} of ${engine.guests.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (filtered.isEmpty)
          SliverPadding(
            padding: horizPad,
            sliver: SliverToBoxAdapter(
              child: Text(
                'No matching players.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          )
        else ...[
          if (_statusFilter != _RosterStatusFilter.dead) ...[
            SliverPadding(
              padding: horizPad,
              sliver: SliverToBoxAdapter(
                child: Text('Alive (${alive.length})',
                    style: ClubBlackoutTheme.headingStyle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverPadding(
              padding: horizPad,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => buildPlayerCard(alive[index]),
                  childCount: alive.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
          if (_statusFilter != _RosterStatusFilter.alive) ...[
            SliverPadding(
              padding: horizPad,
              sliver: SliverToBoxAdapter(
                child: Text('Dead (${dead.length})',
                    style: ClubBlackoutTheme.headingStyle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverPadding(
              padding: horizPad,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => buildPlayerCard(dead[index]),
                  childCount: dead.length,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildQuickActions(Player p, GameEngine engine) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Kill / Revive
          if (p.isAlive)
            FilledButton.tonalIcon(
              onPressed: () => _confirmAndRun(
                'Kill ${p.name}',
                'This will immediately eliminate this player.',
                () => engine.processDeath(p, cause: DeathCause.adminKill),
                isDangerous: true,
              ),
              icon: const Icon(Icons.dangerous_rounded, size: 18),
              label: const Text('KILL'),
              style: FilledButton.styleFrom(
                foregroundColor: ClubBlackoutTheme.neonRed,
              ),
            )
          else
            FilledButton.tonalIcon(
              onPressed: () => _confirmAndRun(
                'Revive ${p.name}',
                'This will bring this player back to life.',
                () => engine.adminRevivePlayer(p.id),
              ),
              icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
              label: const Text('REVIVE'),
              style: FilledButton.styleFrom(
                foregroundColor: ClubBlackoutTheme.neonGreen,
              ),
            ),

          // Toggle Enabled
          FilledButton.tonalIcon(
            onPressed: () {
              engine.setPlayerEnabled(p.id, !p.isEnabled);
              setState(() {});
            },
            icon: Icon(
              p.isEnabled
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              size: 18,
            ),
            label: Text(p.isEnabled ? 'DISABLE' : 'ENABLE'),
          ),

          // Rename
          FilledButton.tonalIcon(
            onPressed: () => _renamePlayerDialog(p, engine),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('RENAME'),
          ),

          // Clear Status
          if (p.statusEffects.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: () {
                p.statusEffects.clear();
                engine.refreshUi();
                setState(() {});
              },
              icon: const Icon(Icons.layers_clear_rounded, size: 18),
              label: const Text('CLEAR STATUS'),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRun(
    String title,
    String message,
    VoidCallback action, {
    bool isDangerous = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ClubAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDangerous
                ? FilledButton.styleFrom(
                    backgroundColor: ClubBlackoutTheme.neonRed,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: const Text('PROCEED'),
          ),
        ],
      ),
    );
    if (ok == true) {
      action();
      setState(() {});
    }
  }

  Future<void> _renamePlayerDialog(Player p, GameEngine engine) async {
    final controller = TextEditingController(text: p.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ClubAlertDialog(
        title: const Text('Rename Player'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'New Name',
            prefixIcon: const Icon(Icons.edit_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      engine.renamePlayer(p.id, controller.text.trim());
      setState(() {});
    }
  }
}
