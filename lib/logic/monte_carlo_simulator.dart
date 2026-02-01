import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import '../data/role_repository.dart';
import '../models/role.dart';
import '../models/script_step.dart';
import 'game_engine.dart';

class MonteCarloWinOddsResult {
  final int runs;
  final int completed;
  final int seed;

  /// Winner token -> count. Tokens match [GameEndResult.winner].
  final Map<String, int> wins;

  /// Winner token -> probability (0..1), normalized across [completed].
  final Map<String, double> odds;

  /// Human-readable note about what was simulated.
  final String note;

  const MonteCarloWinOddsResult({
    required this.runs,
    required this.completed,
    required this.seed,
    required this.wins,
    required this.odds,
    required this.note,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'runsRequested': runs,
        'runsCompleted': completed,
        'seed': seed,
        'wins': wins,
        'odds': odds,
        'note': note,
      };
}

class _SimulationRequest {
  final Map<String, dynamic> baseMap;
  final List<Role> roles;
  final int runs;
  final int seed;
  final int maxStepsPerRun;
  final SendPort sendPort;

  _SimulationRequest({
    required this.baseMap,
    required this.roles,
    required this.runs,
    required this.seed,
    required this.maxStepsPerRun,
    required this.sendPort,
  });
}

class _SimulationProgress {
  final int completed;

  _SimulationProgress(this.completed);
}

class _SimulationResult {
  final Map<String, int> wins;
  final int completed;

  _SimulationResult(this.wins, this.completed);
}

Future<void> _runSimulation(_SimulationRequest request) async {
  final repo = RoleRepository.fromRoles(request.roles);
  final rng = Random(request.seed);
  final wins = <String, int>{};
  var completed = 0;

  for (var i = 0; i < request.runs; i++) {
    final sim = GameEngine(
      roleRepository: repo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
      silent: true,
      persistenceEnabled: false,
    );
    await sim.importSaveBlobMap(request.baseMap, notify: false);

    final winner = MonteCarloSimulator._playToEnd(sim, rng,
        maxStepsPerRun: request.maxStepsPerRun);
    if (winner != null) {
      wins[winner] = (wins[winner] ?? 0) + 1;
      completed++;
    }

    if ((i + 1) % 25 == 0) {
      request.sendPort.send(_SimulationProgress(i + 1));
    }
  }

  request.sendPort.send(_SimulationResult(wins, completed));
}

class MonteCarloSimulator {
  /// Runs a Monte Carlo simulation starting from the given engine state.
  ///
  /// Implementation notes:
  /// - Clones engine state via [GameEngine.exportSaveBlobMap] + [GameEngine.importSaveBlobMap].
  /// - Auto-selects random valid-ish targets for script steps.
  /// - Resolves day voting using [GameEngine.voteOutPlayer] so special rules apply.
  /// - Auto-resolves pending reactions (Predator retaliation, Drama Queen swap).
  static Future<MonteCarloWinOddsResult> simulateWinOdds(
    GameEngine base, {
    int runs = 250,
    int? seed,
    int maxStepsPerRun = 25000,
    void Function(int completedRuns, int totalRuns)? onProgress,
  }) async {
    final endAlready = base.checkGameEnd();
    if (endAlready != null) {
      return MonteCarloWinOddsResult(
        runs: runs,
        completed: 0,
        seed: seed ?? 0,
        wins: const <String, int>{},
        odds: const <String, double>{},
        note: 'Game is already over; no simulations were run.',
      );
    }

    final effectiveSeed = seed ?? DateTime.now().millisecondsSinceEpoch;

    final baseMap = base.exportSaveBlobMap(includeLog: false);
    final roles = base.roleRepository.roles;

    // Use multiple isolates to parallelize the simulation.
    // Cap at 4 workers or number of processors, whichever is lower (but at least 1).
    final workerCount = max(1, min(Platform.numberOfProcessors, 4));
    final runsPerWorker = (runs / workerCount).ceil();

    final wins = <String, int>{};
    var totalCompleted = 0;

    final workerProgress = List<int>.filled(workerCount, 0);
    final completer = Completer<void>();
    var activeWorkers = 0;

    // Launch workers
    for (var i = 0; i < workerCount; i++) {
      // Distribute remainder runs to the last worker or evenly?
      // Simple logic: if runs=10, workers=4 -> ceil(2.5)=3.
      // 3, 3, 3, 1.
      final assignedRuns = (i == workerCount - 1)
          ? max(0, runs - (runsPerWorker * i))
          : runsPerWorker;

      if (assignedRuns <= 0) continue;

      activeWorkers++;
      final receivePort = ReceivePort();
      final workerSeed = effectiveSeed + (i * 1093); // Diverge seeds

      final request = _SimulationRequest(
        baseMap: baseMap,
        roles: roles,
        runs: assignedRuns,
        seed: workerSeed,
        maxStepsPerRun: maxStepsPerRun,
        sendPort: receivePort.sendPort,
      );

      // ignore: unawaited_futures
      Isolate.spawn(_runSimulation, request);

      final workerIndex = i;
      receivePort.listen((message) {
        if (message is _SimulationProgress) {
          workerProgress[workerIndex] = message.completed;
          if (onProgress != null) {
            final currentTotal = workerProgress.reduce((a, b) => a + b);
            onProgress(currentTotal, runs);
          }
        } else if (message is _SimulationResult) {
          for (final e in message.wins.entries) {
            wins[e.key] = (wins[e.key] ?? 0) + e.value;
          }
          totalCompleted += message.completed;

          // Ensure we count strictly for the progress bar at the end
          workerProgress[workerIndex] = message.completed;
          if (onProgress != null) {
            final currentTotal = workerProgress.reduce((a, b) => a + b);
            onProgress(currentTotal, runs);
          }

          receivePort.close();
          activeWorkers--;
          if (activeWorkers == 0) {
            completer.complete();
          }
        }
      });
    }

    if (activeWorkers == 0) {
      completer.complete();
    }

    await completer.future;

    final odds = <String, double>{};
    if (totalCompleted > 0) {
      for (final e in wins.entries) {
        odds[e.key] = (e.value / totalCompleted).clamp(0.0, 1.0);
      }
    }

    return MonteCarloWinOddsResult(
      runs: runs,
      completed: totalCompleted,
      seed: effectiveSeed,
      wins: wins,
      odds: odds,
      note:
          'Monte Carlo simulation from the current engine state. Random actions + votes; includes special vote rules (Whore/Predator) and pending reactions (Drama Queen/Predator). Parallelized across $workerCount isolates.',
    );
  }

  static String? _playToEnd(
    GameEngine engine,
    Random rng, {
    required int maxStepsPerRun,
  }) {
    // Defensive: avoid infinite loops in case scripts stall.
    for (var steps = 0; steps < maxStepsPerRun; steps++) {
      final end = engine.checkGameEnd();
      if (end != null) return end.winner;

      final step = engine.currentScriptStep;
      if (step == null) {
        engine.advanceScript();
        _autoResolvePendingReactions(engine, rng);
        continue;
      }

      switch (step.actionType) {
        case ScriptActionType.none:
        case ScriptActionType.showInfo:
        case ScriptActionType.info:
        case ScriptActionType.showTimer:
        case ScriptActionType.phaseTransition:
        case ScriptActionType.discussion:
          engine.handleScriptAction(step, const <String>[]);
          engine.advanceScript();
          _autoResolvePendingReactions(engine, rng);
          break;

        case ScriptActionType.showDayScene:
          _simulateDayVote(engine, rng);
          engine.advanceScript();
          _autoResolvePendingReactions(engine, rng);
          break;

        case ScriptActionType.optional:
          // 50/50: act vs skip. (Most optional behaviors are modeled as toggleOption today.)
          if (rng.nextBool()) {
            engine.handleScriptAction(step, const <String>[]);
          } else {
            engine.handleScriptAction(step, const <String>[]);
          }
          engine.advanceScript();
          _autoResolvePendingReactions(engine, rng);
          break;

        case ScriptActionType.toggleOption:
          final option = _pickOption(step, rng);
          if (option != null) {
            engine.handleScriptOption(step, option);
          } else {
            engine.handleScriptAction(step, const <String>[]);
          }
          engine.advanceScript();
          _autoResolvePendingReactions(engine, rng);
          break;

        case ScriptActionType.binaryChoice:
          engine.handleScriptAction(
              step, <String>[rng.nextBool() ? 'yes' : 'no']);
          engine.advanceScript();
          _autoResolvePendingReactions(engine, rng);
          break;

        case ScriptActionType.selectPlayer:
          final target = _pickTargetId(engine, step, rng);
          if (target != null) {
            engine.handleScriptAction(step, <String>[target]);
          } else {
            engine.handleScriptAction(step, const <String>[]);
          }
          engine.advanceScript();
          _autoResolvePendingReactions(engine, rng);
          break;

        case ScriptActionType.selectTwoPlayers:
          final targets = _pickTwoTargetIds(engine, step, rng);
          if (targets.length == 2) {
            engine.handleScriptAction(step, targets);
          } else {
            engine.handleScriptAction(step, const <String>[]);
          }
          engine.advanceScript();
          _autoResolvePendingReactions(engine, rng);
          break;
      }
    }

    // If we hit max steps, count it as null (dropped run).
    return null;
  }

  static void _simulateDayVote(GameEngine engine, Random rng) {
    final voters = engine.players
        .where((p) => p.isAlive && p.isEnabled)
        .where((p) => !p.soberSentHome)
        .toList(growable: false);

    final targets = engine.players
        .where((p) => p.isAlive && p.isEnabled)
        .toList(growable: false);

    if (voters.isEmpty || targets.isEmpty) {
      return;
    }

    // Cast random votes.
    for (final voter in voters) {
      final target = targets[rng.nextInt(targets.length)];
      engine.recordVote(voterId: voter.id, targetId: target.id);
    }

    final tallies = <String, int>{};
    for (final entry in engine.eligibleDayVotesByTarget.entries) {
      tallies[entry.key] = entry.value.length;
    }

    String? votedOutId;
    if (tallies.isNotEmpty) {
      var best = -1;
      final leaders = <String>[];
      for (final e in tallies.entries) {
        if (e.value > best) {
          best = e.value;
          leaders
            ..clear()
            ..add(e.key);
        } else if (e.value == best) {
          leaders.add(e.key);
        }
      }
      votedOutId =
          leaders.isNotEmpty ? leaders[rng.nextInt(leaders.length)] : null;
    }

    // Fallback to a random alive target if tally was empty.
    votedOutId ??= targets[rng.nextInt(targets.length)].id;

    engine.voteOutPlayer(votedOutId);

    // If Predator died by vote, retaliation becomes pending and must be resolved.
    _autoResolvePendingReactions(engine, rng);
  }

  static void _autoResolvePendingReactions(GameEngine engine, Random rng) {
    // Drama Queen swap.
    if (engine.dramaQueenSwapPending) {
      final aId = engine.dramaQueenMarkedAId;
      final bId = engine.dramaQueenMarkedBId;

      final alive = engine.players
          .where((p) => p.isAlive && p.isEnabled)
          .toList(growable: false);

      if (alive.length >= 2) {
        final a =
            aId != null ? alive.where((p) => p.id == aId).firstOrNull : null;
        final b =
            bId != null ? alive.where((p) => p.id == bId).firstOrNull : null;

        if (a != null && b != null && a.id != b.id) {
          engine.completeDramaQueenSwap(a, b);
        } else {
          final i = rng.nextInt(alive.length);
          var j = rng.nextInt(alive.length);
          if (j == i) j = (j + 1) % alive.length;
          engine.completeDramaQueenSwap(alive[i], alive[j]);
        }
      }
    }

    // Predator retaliation.
    final predatorId = engine.pendingPredatorId;
    if (predatorId != null) {
      final alive = engine.players
          .where((p) => p.isAlive && p.isEnabled)
          .toList(growable: false);

      if (alive.isEmpty) {
        engine.completePredatorRetaliation('');
        return;
      }

      final eligibleIds = engine.pendingPredatorEligibleVoterIds;
      final eligible = eligibleIds.isNotEmpty
          ? alive
              .where((p) => eligibleIds.contains(p.id))
              .toList(growable: false)
          : alive.where((p) => p.id != predatorId).toList(growable: false);

      if (eligible.isNotEmpty) {
        final preferred = engine.pendingPredatorPreferredTargetId;
        final pick = preferred != null && eligible.any((p) => p.id == preferred)
            ? preferred
            : eligible[rng.nextInt(eligible.length)].id;
        engine.completePredatorRetaliation(pick);
      } else {
        // Fall back to any alive non-predator.
        final fallback = alive.where((p) => p.id != predatorId).toList();
        if (fallback.isNotEmpty) {
          engine.completePredatorRetaliation(
              fallback[rng.nextInt(fallback.length)].id);
        }
      }
    }
  }

  static String? _pickOption(ScriptStep step, Random rng) {
    final roleId = step.roleId;
    if (roleId == null) return null;

    switch (roleId) {
      case 'medic':
        // Setup choice.
        return rng.nextBool() ? 'PROTECT' : 'REVIVE';
      case 'wallflower':
        // Weighted: mostly skip.
        final roll = rng.nextDouble();
        if (roll < 0.55) return 'SKIP';
        if (roll < 0.90) return 'PEEK';
        return 'STARE';
      default:
        return null;
    }
  }

  static String? _pickTargetId(GameEngine engine, ScriptStep step, Random rng) {
    final roleId = step.roleId;

    final candidates =
        engine.players.where((p) => p.isAlive && p.isEnabled).toList();

    if (candidates.isEmpty) return null;

    // Role-specific filtering to reduce rejected selections.
    if (roleId == 'whore') {
      final whore = engine.players
          .where((p) => p.isAlive && p.isEnabled && p.role.id == 'whore')
          .firstOrNull;
      candidates.removeWhere((p) => whore != null && p.id == whore.id);
      candidates.removeWhere((p) =>
          p.role.id == 'dealer' || p.alliance.toLowerCase().contains('dealer'));
    }

    return candidates.isNotEmpty
        ? candidates[rng.nextInt(candidates.length)].id
        : null;
  }

  static List<String> _pickTwoTargetIds(
      GameEngine engine, ScriptStep step, Random rng) {
    final candidates = engine.players
        .where((p) => p.isAlive && p.isEnabled)
        .map((p) => p.id)
        .toList();

    if (candidates.length < 2) return const <String>[];

    final i = rng.nextInt(candidates.length);
    var j = rng.nextInt(candidates.length);
    if (j == i) j = (j + 1) % candidates.length;

    return <String>[candidates[i], candidates[j]];
  }
}
