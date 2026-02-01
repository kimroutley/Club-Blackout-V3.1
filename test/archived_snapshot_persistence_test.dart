import 'dart:convert';

import 'package:club_blackout/logic/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  test('resetToLobby archives last game blob unless cleared', () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final dealerRole = roleRepo.getRoleById('dealer');
    final medicRole = roleRepo.getRoleById('medic');
    expect(dealerRole, isNotNull);
    expect(medicRole, isNotNull);

    final engine = GameEngine(roleRepository: roleRepo);

    engine.addPlayer('Alice', role: dealerRole);
    engine.addPlayer('Bob', role: medicRole);

    expect(engine.lastArchivedGameBlobJson, isNull);

    engine.resetToLobby(keepGuests: true, keepAssignedRoles: false);

    final archived = engine.lastArchivedGameBlobJson;
    expect(archived, isNotNull);

    final decoded = jsonDecode(archived!) as Map;
    expect(decoded['players'], isA<List>());

    engine.resetToLobby(clearArchived: true);
    expect(engine.lastArchivedGameBlobJson, isNull);
  });
}
