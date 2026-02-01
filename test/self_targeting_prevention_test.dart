import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/script_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  group('Self-Targeting Prevention Tests', () {
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

    test('Dealers cannot kill themselves', () async {
      await startWithMinimumPlayers(['dealer', 'party_animal']);
      final dealer = engine.players.firstWhere((p) => p.role.id == 'dealer');

      const step = ScriptStep(
        id: 'dealer_act',
        title: 'Dealer',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'dealer',
        isNight: true,
      );

      engine.handleScriptAction(step, [dealer.id]);

      expect(engine.nightActions.containsKey('kill'), isFalse);
      expect(
        engine.gameLog.any(
          (log) =>
              log.description.contains('Dealers cannot eliminate themselves'),
        ),
        isTrue,
      );
    });

    test('Players cannot vote for themselves', () async {
      await startWithMinimumPlayers(['dealer', 'party_animal']);
      final dealer = engine.players.firstWhere((p) => p.role.id == 'dealer');

      engine.recordVote(voterId: dealer.id, targetId: dealer.id);

      expect(engine.currentDayVotesByVoter[dealer.id], isNull);
      expect(
        engine.gameLog.any(
          (log) => log.description.contains('cannot vote for themselves'),
        ),
        isTrue,
      );
    });

    test('Drama Queen cannot include themselves in swap', () async {
      await startWithMinimumPlayers(['drama_queen', 'dealer', 'party_animal']);
      final drama =
          engine.players.firstWhere((p) => p.role.id == 'drama_queen');
      final dealer = engine.players.firstWhere((p) => p.role.id == 'dealer');

      const step = ScriptStep(
        id: 'drama_queen_act',
        title: 'Drama Queen',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectTwoPlayers,
        roleId: 'drama_queen',
        isNight: true,
      );

      engine.handleScriptAction(step, [drama.id, dealer.id]);

      expect(engine.nightActions.containsKey('drama_swap_a'), isFalse);
      expect(engine.nightActions.containsKey('drama_swap_b'), isFalse);
      expect(
        engine.gameLog.any(
          (log) =>
              log.description.contains('Drama Queen cannot include themselves'),
        ),
        isTrue,
      );
    });

    test('Bouncer cannot check themselves', () async {
      await startWithMinimumPlayers(['bouncer', 'party_animal']);
      final bouncer = engine.players.firstWhere((p) => p.role.id == 'bouncer');

      const step = ScriptStep(
        id: 'bouncer_act',
        title: 'Bouncer',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'bouncer',
        isNight: true,
      );

      engine.handleScriptAction(step, [bouncer.id]);

      expect(engine.nightActions.containsKey('bouncer_check'), isFalse);
      expect(
        engine.gameLog.any(
          (log) => log.description.contains('Bouncer cannot check themselves'),
        ),
        isTrue,
      );
    });

    test('Roofi cannot silence themselves', () async {
      await startWithMinimumPlayers(['roofi', 'party_animal']);
      final roofi = engine.players.firstWhere((p) => p.role.id == 'roofi');

      const step = ScriptStep(
        id: 'roofi_act',
        title: 'Roofi',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'roofi',
        isNight: true,
      );

      engine.handleScriptAction(step, [roofi.id]);

      expect(engine.nightActions.containsKey('roofi'), isFalse);
      expect(
        engine.gameLog.any(
          (log) => log.description.contains('Roofi cannot silence themselves'),
        ),
        isTrue,
      );
    });

    test('Sober cannot send themselves home', () async {
      await startWithMinimumPlayers(['sober', 'party_animal']);
      final sober = engine.players.firstWhere((p) => p.role.id == 'sober');

      const step = ScriptStep(
        id: 'sober_act',
        title: 'Sober',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'sober',
        isNight: true,
      );

      engine.handleScriptAction(step, [sober.id]);

      expect(engine.nightActions.containsKey('sober_sent_home'), isFalse);
      expect(
        engine.gameLog.any(
          (log) =>
              log.description.contains('Sober cannot send themselves home'),
        ),
        isTrue,
      );
    });

    test('Silver Fox cannot give themselves an alibi', () async {
      await startWithMinimumPlayers(['silver_fox', 'party_animal']);
      final fox = engine.players.firstWhere((p) => p.role.id == 'silver_fox');

      const step = ScriptStep(
        id: 'silver_fox_act',
        title: 'Silver Fox',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'silver_fox',
        isNight: true,
      );

      engine.handleScriptAction(step, [fox.id]);

      expect(engine.nightActions.containsKey('silver_fox_alibi'), isFalse);
      expect(fox.alibiDay, isNull);
      expect(
        engine.gameLog.any(
          (log) => log.description
              .contains('Silver Fox cannot give themselves an alibi'),
        ),
        isTrue,
      );
    });

    test('Club Manager cannot reveal themselves', () async {
      await startWithMinimumPlayers(['club_manager', 'party_animal']);
      final clubManager =
          engine.players.firstWhere((p) => p.role.id == 'club_manager');

      const step = ScriptStep(
        id: 'club_manager_act',
        title: 'Club Manager',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'club_manager',
        isNight: true,
      );

      engine.handleScriptAction(step, [clubManager.id]);

      expect(
        engine.gameLog.any(
          (log) => log.description
              .contains('Club Manager must choose a fellow player.'),
        ),
        isTrue,
      );
    });

    test('Club Manager cannot view the host', () async {
      await startWithMinimumPlayers(['club_manager', 'party_animal']);
      engine.setHostName('Hosty');

      // The host is represented by a synthetic id, not a real player in engine.players.
      const hostId = GameEngine.hostPlayerId;

      const step = ScriptStep(
        id: 'club_manager_act',
        title: 'Club Manager',
        readAloudText: '',
        instructionText: '',
        actionType: ScriptActionType.selectPlayer,
        roleId: 'club_manager',
        isNight: true,
      );

      engine.handleScriptAction(step, [hostId]);

      expect(
        engine.gameLog.any(
          (log) =>
              log.description.contains('Club Manager cannot view the host.'),
        ),
        isTrue,
      );
    });
  });
}
