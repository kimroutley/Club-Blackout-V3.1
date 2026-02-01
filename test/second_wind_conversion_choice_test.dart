import 'package:club_blackout/logic/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  test('Second Wind conversion choice is inserted before dealer_act on conversion night',
      () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final dealerRole = roleRepo.getRoleById('dealer');
    final secondWindRole = roleRepo.getRoleById('second_wind');
    final partyRole = roleRepo.getRoleById('party_animal');

    expect(dealerRole, isNotNull);
    expect(secondWindRole, isNotNull);
    expect(partyRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Dealer', role: dealerRole);
    engine.addPlayer('SecondWind', role: secondWindRole);
    engine.addPlayer('Filler', role: partyRole);
    engine.addPlayer('Filler2', role: partyRole);

    // Configure a pending conversion for tonight.
    engine.dayCount = 2;
    engine.currentPhase = GamePhase.day;

    final secondWind =
        engine.players.firstWhere((p) => p.name == 'SecondWind');
    secondWind.secondWindPendingConversion = true;
    secondWind.secondWindConverted = false;
    secondWind.secondWindRefusedConversion = false;
    secondWind.secondWindConversionNight = 2;

    // Transition Day -> Night to build the night script.
    engine.skipToNextPhase();

    expect(engine.currentPhase, GamePhase.night);

    final ids = engine.scriptQueue.map((s) => s.id).toList(growable: false);
    final choiceIndex = ids.indexOf('second_wind_conversion_choice');
    final dealerIndex = ids.indexOf('dealer_act');

    expect(choiceIndex, isNot(-1));
    expect(dealerIndex, isNot(-1));
    expect(choiceIndex < dealerIndex, isTrue);
  });

  test('Second Wind conversion revives and clears death metadata', () async {
    SharedPreferences.setMockInitialValues({});

    final roleRepo = FileRoleRepository();
    await roleRepo.loadRoles();

    final dealerRole = roleRepo.getRoleById('dealer');
    final secondWindRole = roleRepo.getRoleById('second_wind');
    final partyRole = roleRepo.getRoleById('party_animal');

    expect(dealerRole, isNotNull);
    expect(secondWindRole, isNotNull);
    expect(partyRole, isNotNull);

    final engine = GameEngine(
      roleRepository: roleRepo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    engine.addPlayer('Dealer', role: dealerRole);
    engine.addPlayer('SecondWind', role: secondWindRole);
    engine.addPlayer('Filler', role: partyRole);
    engine.addPlayer('Filler2', role: partyRole);

    // Simulate that Second Wind died to a Dealer kill last night.
    engine.dayCount = 2;
    engine.currentPhase = GamePhase.day;
    final secondWind = engine.players.firstWhere((p) => p.name == 'SecondWind');
    secondWind.die(1, 'night_kill');
    engine.deadPlayerIds.add(secondWind.id);

    // Conversion choice is available tonight.
    secondWind.secondWindPendingConversion = true;
    secondWind.secondWindConverted = false;
    secondWind.secondWindRefusedConversion = false;
    secondWind.secondWindConversionNight = 2;

    // Transition Day -> Night to build the night script.
    engine.skipToNextPhase();
    expect(engine.currentPhase, GamePhase.night);

    // Advance until we reach the conversion choice step.
    while (engine.currentScriptStep != null &&
        engine.currentScriptStep!.id != 'second_wind_conversion_choice') {
      engine.advanceScript();
    }

    final step = engine.currentScriptStep;
    expect(step, isNotNull);
    expect(step!.id, 'second_wind_conversion_choice');

    engine.handleScriptAction(step, const ['CONVERT']);

    expect(secondWind.isAlive, isTrue);
    expect(engine.deadPlayerIds.contains(secondWind.id), isFalse);
    expect(secondWind.deathReason, isNull);
    expect(secondWind.deathDay, isNull);
    expect(secondWind.role.id, 'dealer');
  });
}
