import 'dart:io';
// Note: Keep this test filesystem-based (no package URI resolution) because
// Isolate.resolvePackageUri is unsupported under flutter test.

import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/logic/script_builder.dart';
import 'package:club_blackout/models/player.dart';
import 'package:club_blackout/models/role.dart';
import 'package:club_blackout/models/script_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  test('UI wiring includes all interactive step ids we generate', () {
    final gameScreenPath = p.join('lib', 'ui', 'screens', 'game_screen.dart');
    final contents = File(gameScreenPath).readAsStringSync();

    // toggleOption steps
    expect(contents.contains("step.id == 'medic_setup_choice'"), isTrue);
    expect(contents.contains("step.id == 'wallflower_act'"), isTrue);

    // binaryChoice steps
    expect(
      contents.contains("step.id == 'second_wind_conversion_choice'"),
      isTrue,
      reason: 'Binary choice step must be renderable in the main script UI.',
    );
  });

  test('Engine only emits known toggleOption ids (ScriptBuilder)', () {
    Role role(String id) {
      return Role(
        id: id,
        name: id,
        description: 'test role $id',
        alliance: 'test',
        type: 'test',
        nightPriority: 0,
        assetPath: '',
        colorHex: '#FFFFFF',
      );
    }

    Player player(String id, String name, String roleId) {
      return Player(id: id, name: name, role: role(roleId))..initialize();
    }

    final supportedToggleOptionIds = <String>{
      'medic_setup_choice',
      'wallflower_act',
    };

    // Night 0: medic setup choice.
    final night0 = ScriptBuilder.buildNightScript(
      [
        player('m', 'Medic', 'medic'),
        player('p', 'Party', 'party_animal'),
        player('p2', 'Party2', 'party_animal'),
        player('d', 'Dealer', 'dealer'),
      ],
      0,
    );

    // Night 1: wallflower witness choice if murders can happen.
    final night1 = ScriptBuilder.buildNightScript(
      [
        player('d', 'Dealer', 'dealer'),
        player('wf', 'Wallflower', 'wallflower'),
        player('p', 'Party', 'party_animal'),
        player('p2', 'Party2', 'party_animal'),
      ],
      1,
    );

    final allToggleIds = <String>{
      ...night0
          .where((s) => s.actionType == ScriptActionType.toggleOption)
          .map((s) => s.id),
      ...night1
          .where((s) => s.actionType == ScriptActionType.toggleOption)
          .map((s) => s.id),
    };

    expect(allToggleIds.difference(supportedToggleOptionIds), isEmpty,
        reason:
            'A new toggleOption step was added without updating UI support.');
  });

  test('Engine binaryChoice ids are known (GameEngine)', () async {
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

    engine.dayCount = 2;
    engine.currentPhase = GamePhase.day;

    final secondWind = engine.players.firstWhere((p) => p.name == 'SecondWind');
    secondWind.secondWindPendingConversion = true;
    secondWind.secondWindConverted = false;
    secondWind.secondWindRefusedConversion = false;
    secondWind.secondWindConversionNight = 2;

    engine.skipToNextPhase();
    expect(engine.currentPhase, GamePhase.night);

    final supportedBinaryChoiceIds = <String>{
      'second_wind_conversion_choice',
      // legacy ids (older saves)
      'second_wind_conversion_vote',
    };

    final binaryIds = engine.scriptQueue
        .where((s) => s.actionType == ScriptActionType.binaryChoice)
        .map((s) => s.id)
        .toSet();

    expect(binaryIds.difference(supportedBinaryChoiceIds), isEmpty,
        reason:
            'A new binaryChoice step was added without updating UI support.');
  });
}
