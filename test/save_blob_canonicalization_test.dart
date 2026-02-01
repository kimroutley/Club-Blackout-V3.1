import 'package:club_blackout/logic/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  test('importSaveBlobMap canonicalizes nightActions keys', () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final dealerRole = roleRepo.getRoleById('dealer');
    final medicRole = roleRepo.getRoleById('medic');
    final partyRole = roleRepo.getRoleById('party_animal');
    final clingerRole = roleRepo.getRoleById('clinger');

    expect(dealerRole, isNotNull);
    expect(medicRole, isNotNull);
    expect(partyRole, isNotNull);
    expect(clingerRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Dealer', role: dealerRole);
    engine.addPlayer('Medic', role: medicRole);
    engine.addPlayer('Target', role: partyRole);

    final targetId = engine.players.firstWhere((p) => p.name == 'Target').id;
    final medicId = engine.players.firstWhere((p) => p.name == 'Medic').id;

    final blob = engine.exportSaveBlobMap(includeLog: false);
    blob['nightActions'] = {
      'dealer_act': targetId,
      'medic_protect': medicId,
      'clinger_act': targetId,
      'tea_spiller_mark': targetId,
    };

    final engine2 = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );
    await engine2.importSaveBlobMap(blob, notify: false);

    expect(engine2.nightActions['kill'], targetId);
    expect(engine2.nightActions['protect'], medicId);
    expect(engine2.nightActions['kill_clinger'], targetId);
    expect(engine2.nightActions.containsKey('tea_spiller_mark'), isFalse);
  });

  test('importSaveBlobMap canonicalizes medic_act in PROTECT mode', () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final medicRole = roleRepo.getRoleById('medic');
    final partyRole = roleRepo.getRoleById('party_animal');

    expect(medicRole, isNotNull);
    expect(partyRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Medic', role: medicRole);
    engine.addPlayer('Target', role: partyRole);

    final targetId = engine.players.firstWhere((p) => p.name == 'Target').id;

    // Default/empty medicChoice implies PROTECT_DAILY.
    final blob = engine.exportSaveBlobMap(includeLog: false);
    blob['nightActions'] = {
      'medic_act': targetId,
    };

    final engine2 = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );
    await engine2.importSaveBlobMap(blob, notify: false);

    expect(engine2.nightActions['protect'], targetId);
    final medic2 = engine2.players.firstWhere((p) => p.role.id == 'medic');
    expect(medic2.medicProtectedPlayerId, targetId);
  });

  test('importSaveBlobMap canonicalizes medic_act in REVIVE mode', () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final medicRole = roleRepo.getRoleById('medic');
    final partyRole = roleRepo.getRoleById('party_animal');

    expect(medicRole, isNotNull);
    expect(partyRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Medic', role: medicRole);
    engine.addPlayer('Target', role: partyRole);

    final targetId = engine.players.firstWhere((p) => p.name == 'Target').id;
    final medic = engine.players.firstWhere((p) => p.role.id == 'medic');
    medic.medicChoice = 'REVIVE';

    final blob = engine.exportSaveBlobMap(includeLog: false);
    blob['nightActions'] = {
      'medic_act': targetId,
    };

    final engine2 = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );
    await engine2.importSaveBlobMap(blob, notify: false);

    expect(engine2.nightActions['medic_revive'], targetId);
  });

  test('importSaveBlobMap canonicalizes sober_act to sober_sent_home',
      () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final soberRole = roleRepo.getRoleById('sober');
    final partyRole = roleRepo.getRoleById('party_animal');

    expect(soberRole, isNotNull);
    expect(partyRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Sober', role: soberRole);
    engine.addPlayer('Target', role: partyRole);

    final targetId = engine.players.firstWhere((p) => p.name == 'Target').id;

    final blob = engine.exportSaveBlobMap(includeLog: false);
    blob['nightActions'] = {
      'sober_act': targetId,
    };

    final engine2 = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );
    await engine2.importSaveBlobMap(blob, notify: false);

    expect(engine2.nightActions['sober_sent_home'], targetId);
  });

  test('importSaveBlobMap canonicalizes bouncer_roofi_act to roofi', () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final bouncerRole = roleRepo.getRoleById('bouncer');
    final partyRole = roleRepo.getRoleById('party_animal');

    expect(bouncerRole, isNotNull);
    expect(partyRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Bouncer', role: bouncerRole);
    engine.addPlayer('Target', role: partyRole);

    final bouncer = engine.players.firstWhere((p) => p.role.id == 'bouncer');
    bouncer.bouncerHasRoofiAbility = true;

    final targetId = engine.players.firstWhere((p) => p.name == 'Target').id;

    final blob = engine.exportSaveBlobMap(includeLog: false);
    blob['nightActions'] = {
      'bouncer_roofi_act': targetId,
    };

    final engine2 = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );
    await engine2.importSaveBlobMap(blob, notify: false);

    expect(engine2.nightActions['roofi'], targetId);
  });

  test('importSaveBlobMap does not overwrite canonical nightActions', () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final dealerRole = roleRepo.getRoleById('dealer');
    final partyRole = roleRepo.getRoleById('party_animal');

    expect(dealerRole, isNotNull);
    expect(partyRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Dealer', role: dealerRole);
    engine.addPlayer('AA', role: partyRole);
    engine.addPlayer('BB', role: partyRole);

    final aId = engine.players.firstWhere((p) => p.name == 'AA').id;
    final bId = engine.players.firstWhere((p) => p.name == 'BB').id;

    final blob = engine.exportSaveBlobMap(includeLog: false);
    blob['nightActions'] = {
      'kill': aId,
      'dealer_act': bId,
    };

    final engine2 = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );
    await engine2.importSaveBlobMap(blob, notify: false);

    expect(engine2.nightActions['kill'], aId);
  });

  test('importSaveBlobMap merges derived deadPlayerIds from players', () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final dealerRole = roleRepo.getRoleById('dealer');
    final partyRole = roleRepo.getRoleById('party_animal');

    expect(dealerRole, isNotNull);
    expect(partyRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Dealer', role: dealerRole);
    engine.addPlayer('Victim', role: partyRole);

    final victim = engine.players.firstWhere((p) => p.name == 'Victim');
    engine.processDeath(victim, cause: 'vote');

    final blob = engine.exportSaveBlobMap(includeLog: false);
    blob['deadPlayerIds'] = <String>[]; // simulate stale/incomplete saved state

    final engine2 = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );
    await engine2.importSaveBlobMap(blob, notify: false);

    expect(engine2.deadPlayerIds, contains(victim.id));
  });
}
