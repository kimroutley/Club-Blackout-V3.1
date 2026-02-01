// ignore_for_file: avoid_print

import 'package:club_blackout/data/role_repository.dart';
import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRoleRepository extends RoleRepository {
  @override
  Future<void> loadRoles() async {}
  @override
  List<Role> get roles => [];
  @override
  Role? getRoleById(String id) => Role(
      id: id,
      name: id,
      alliance: 'None',
      type: 'Fake',
      description: 'Fake',
      nightPriority: 0,
      assetPath: '',
      colorHex: '#FFFFFF');
}

void main() {
  test('benchmark lastArchivedGameSavedAt performance', () async {
    SharedPreferences.setMockInitialValues({});
    // Disable auto-loading to prevent race conditions in test
    final engine = GameEngine(
      roleRepository: FakeRoleRepository(),
      loadArchivedSnapshot: false,
      loadNameHistory: false,
    );

    // Add some players to make the blob bigger
    for (int i = 0; i < 20; i++) {
      engine.addPlayer('Player $i',
          role: Role(
              id: 'villager',
              name: 'Villager',
              alliance: 'Good',
              type: 'Good',
              description: 'Villager',
              nightPriority: 0,
              assetPath: '',
              colorHex: '#FFFFFF'));
    }

    // Add some logs
    for (int i = 0; i < 100; i++) {
      engine.logAction('Action $i', 'Description of action $i');
    }

    // Populate the blob
    await engine.archiveCurrentGameBlob(notify: false);

    final blob = engine.lastArchivedGameBlobJson;
    // ignore: avoid_print
    print('Blob size: ${blob?.length ?? 0} chars');

    final stopwatch = Stopwatch()..start();
    const iterations = 10000;

    for (var i = 0; i < iterations; i++) {
      final _ = engine.lastArchivedGameSavedAt;
    }

    stopwatch.stop();
    // ignore: avoid_print
    print('Time taken for $iterations accesses: ${stopwatch.elapsedMilliseconds} ms');
  });
}
