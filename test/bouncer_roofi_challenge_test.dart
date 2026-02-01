import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/script_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  group('Bouncer ↔ Roofi challenge', () {
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

    test('Correct challenge revokes Roofi and grants stolen power', () async {
      await startWithMinimumPlayers(
          ['bouncer', 'roofi', 'dealer', 'party_animal']);

      final bouncer = engine.players.firstWhere((p) => p.role.id == 'bouncer');
      final roofi = engine.players.firstWhere((p) => p.role.id == 'roofi');
      final target =
          engine.players.firstWhere((p) => p.role.id == 'party_animal');

      final ok = engine.resolveBouncerRoofiChallenge(roofi.id);
      expect(ok, isTrue);
      expect(roofi.roofiAbilityRevoked, isTrue);
      expect(bouncer.bouncerHasRoofiAbility, isTrue);
      expect(bouncer.bouncerAbilityRevoked, isFalse);

      engine.nightActions.clear();
      const step = ScriptStep(
        id: 'bouncer_roofi_act',
        title: 'Stolen Roofi Powers',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'roofi',
        isNight: true,
      );

      engine.handleScriptAction(step, [target.id]);

      expect(engine.nightActions['roofi'], target.id);
      expect(target.silencedDay, engine.dayCount + 1);
    });

    test('Stolen Roofi powers cannot self-target the Bouncer', () async {
      await startWithMinimumPlayers(
          ['bouncer', 'roofi', 'dealer', 'party_animal']);

      final bouncer = engine.players.firstWhere((p) => p.role.id == 'bouncer');
      final roofi = engine.players.firstWhere((p) => p.role.id == 'roofi');

      expect(engine.resolveBouncerRoofiChallenge(roofi.id), isTrue);

      engine.nightActions.clear();
      const step = ScriptStep(
        id: 'bouncer_roofi_act',
        title: 'Stolen Roofi Powers',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'roofi',
        isNight: true,
      );

      engine.handleScriptAction(step, [bouncer.id]);

      expect(engine.nightActions.containsKey('roofi'), isFalse);
      expect(
        engine.gameLog.any(
          (log) => log.description.contains('cannot silence themselves'),
        ),
        isTrue,
      );
    });

    test('Incorrect challenge revokes Bouncer ID checks', () async {
      await startWithMinimumPlayers(
          ['bouncer', 'roofi', 'dealer', 'party_animal']);

      final bouncer = engine.players.firstWhere((p) => p.role.id == 'bouncer');
      final roofi = engine.players.firstWhere((p) => p.role.id == 'roofi');
      final suspect =
          engine.players.firstWhere((p) => p.role.id == 'party_animal');

      final ok = engine.resolveBouncerRoofiChallenge(suspect.id);
      expect(ok, isTrue);

      expect(bouncer.bouncerAbilityRevoked, isTrue);
      expect(bouncer.bouncerHasRoofiAbility, isFalse);
      expect(roofi.roofiAbilityRevoked, isFalse);

      // Once revoked, the Bouncer cannot challenge again.
      expect(engine.resolveBouncerRoofiChallenge(roofi.id), isFalse);
    });
  });
}
