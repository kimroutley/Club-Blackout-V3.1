import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/script_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  group('Predator mark persistence', () {
    late GameEngine engine;
    late FileRoleRepository roleRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      roleRepo = FileRoleRepository();
      await roleRepo.loadRoles();
      engine = GameEngine(
        roleRepository: roleRepo,
        loadNameHistory: false,
        loadArchivedSnapshot: false,
      );
    });

    void addPlayer(String name, String roleId) {
      final role = roleRepo.getRoleById(roleId);
      if (role == null) throw StateError('Missing role: $roleId');
      engine.addPlayer(name, role: role);
    }

    Future<void> startWithMinimumPlayers(List<String> roleIds) async {
      for (var i = 0; i < roleIds.length; i++) {
        addPlayer('P${i + 1}', roleIds[i]);
      }

      final fillerRoleIds = <String>[
        'medic',
        'wallflower',
        'bartender',
        'bouncer',
        'party_animal',
      ];

      var fillerIndex = 0;
      while (engine.players.where((p) => p.isEnabled).length < 4) {
        addPlayer(
          'Filler${engine.players.length + 1}',
          fillerRoleIds[fillerIndex % fillerRoleIds.length],
        );
        fillerIndex++;
      }

      await engine.startGame();
    }

    test(
        'Predator mark survives nightActions clear and is used as preferred retaliation target',
        () async {
      await startWithMinimumPlayers(['predator', 'party_animal']);

      engine.skipToNextPhase(); // setup -> night

      final predator =
          engine.players.firstWhere((p) => p.role.id == 'predator');
      final target =
          engine.players.where((p) => p.role.id == 'party_animal').first;

      const step = ScriptStep(
        id: 'predator_act',
        title: 'Predator',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'predator',
        isNight: true,
      );

      engine.handleScriptAction(step, [target.id]);

      expect(predator.predatorMarkId, target.id);
      expect(engine.nightActions['predator_mark'], target.id);

      engine.skipToNextPhase(); // night -> day (clears nightActions)

      expect(engine.nightActions.containsKey('predator_mark'), isFalse);
      expect(predator.predatorMarkId, target.id);

      engine.voteOutPlayer(predator.id);

      expect(engine.pendingPredatorPreferredTargetId, target.id);
    });
  });
}
