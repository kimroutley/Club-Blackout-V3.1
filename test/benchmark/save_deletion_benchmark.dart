// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:club_blackout/logic/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/file_role_repository.dart';

void main() {
  test('Benchmark deleteSavedGame', () async {
    // 1. Setup
    final repo = FileRoleRepository();
    // Pre-load roles (not strictly necessary for delete, but good for engine init)
    await repo.loadRoles();

    // We need to set mock initial values before instantiating GameEngine or calling delete
    // However, SharedPreferences.getInstance() uses the mock values if set.
    // Ideally we want to simulate a populated store.

    // Create a large number of dummy keys mimicking a real save
    const saveId = 'benchmark_save';
    final Map<String, Object> initialValues = {};
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

    for (final f in fields) {
      initialValues['gameState_${saveId}_$f'] =
          'some_dummy_data_content_representing_json_blob_or_value';
    }

    // Also add the save to the index
    initialValues['savedGames'] = jsonEncode([
      {
        'id': saveId,
        'name': 'Benchmark Save',
        'savedAt': DateTime.now().toIso8601String(),
        'dayCount': 1,
        'alivePlayers': 10,
        'totalPlayers': 12,
        'currentPhase': 'day',
      }
    ]);

    SharedPreferences.setMockInitialValues(initialValues);

    final engine = GameEngine(
      roleRepository: repo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    // Warm up? Maybe not needed for simple async measurement.

    // 2. Measure
    final stopwatch = Stopwatch()..start();

    // Run the deletion
    await engine.deleteSavedGame(saveId);

    stopwatch.stop();

    print(
        'Baseline execution time for deleteSavedGame: ${stopwatch.elapsedMicroseconds} µs');

    // Verify it actually deleted
    final prefs = await SharedPreferences.getInstance();
    for (final f in fields) {
      if (prefs.containsKey('gameState_${saveId}_$f')) {
        fail('Key gameState_${saveId}_$f was not deleted');
      }
    }
  });
}
