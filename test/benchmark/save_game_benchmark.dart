// ignore_for_file: avoid_print

import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/game_log_entry.dart';
import 'package:club_blackout/models/player.dart';
import 'package:club_blackout/models/role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/file_role_repository.dart';

void main() {
  test('Benchmark saveGame', () async {
    // 1. Setup
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    // Create a game engine instance
    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    final villagerRole = roleRepo.getRoleById('party_animal') ??
        Role(
            id: 'party_animal',
            name: 'Party Animal',
            alliance: 'Party',
            type: 'Good',
            description: 'Desc',
            nightPriority: 0,
            assetPath: '',
            colorHex: '#FFFFFF');

    // Add 50 players
    for (int i = 0; i < 50; i++) {
      engine.players.add(Player(
        id: 'player_$i',
        name: 'Player $i',
        role: villagerRole,
        isAlive: true,
        isEnabled: true,
      )..initialize());
    }

    // Add 1000 log entries
    for (int i = 0; i < 1000; i++) {
      engine.logAction(
        'Action $i',
        'This is a detailed description of action number $i in the game log.',
        type: GameLogType.action,
      );
    }

    // 2. Measure
    final stopwatch = Stopwatch()..start();

    await engine.saveGame('benchmark_save');

    stopwatch.stop();

    print('saveGame execution time: ${stopwatch.elapsedMilliseconds} ms');

    // Verify save size (roughly)
    final prefs = await SharedPreferences.getInstance();
    // Reconstruct the blob key. Note: private constants in GameEngine, so we guess or inspect.
    // _savePrefix = 'gameState_', _saveBlobSuffix = '_blob'
    // saveId we need to find.

    // getSavedGames gives us the list
    final saves = await engine.getSavedGames();
    final saveId = saves.last.id;

    final blobKey = 'gameState_${saveId}_blob';
    final blobStr = prefs.getString(blobKey);
    if (blobStr != null) {
      print('Blob size: ${blobStr.length} bytes');
    } else {
      print('Blob not found at $blobKey');
    }
  });
}
