import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/script_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameEngine gameEngine;
  late FileRoleRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = FileRoleRepository();
    await repo.loadRoles();

    gameEngine = GameEngine(roleRepository: repo);
    await gameEngine.createTestGame(fullRoster: true);
    await gameEngine.startGame();
  });

  void fastForwardPhaseChange() {
    int safety = 0;
    final initialPhase = gameEngine.currentPhase;
    final initialDay = gameEngine.dayCount;

    while (gameEngine.currentScriptIndex < gameEngine.scriptQueue.length &&
        safety < 600) {
      gameEngine.advanceScript();
      safety++;
      if (gameEngine.currentPhase != initialPhase ||
          gameEngine.dayCount != initialDay) {
        return;
      }
    }
    throw StateError('Failed to reach next phase change.');
  }

  void executeStepById(String stepId, List<String> selections) {
    int safety = 0;
    final initialPhase = gameEngine.currentPhase;
    final initialDay = gameEngine.dayCount;
    while (gameEngine.currentScriptIndex < gameEngine.scriptQueue.length &&
        safety < 600) {
      if (gameEngine.currentPhase != initialPhase ||
          gameEngine.dayCount != initialDay) {
        throw StateError(
            'Step $stepId not found before phase/day change (phase=$initialPhase day=$initialDay).');
      }
      final step = gameEngine.scriptQueue[gameEngine.currentScriptIndex];
      if (step.id == stepId) {
        if (step.actionType == ScriptActionType.toggleOption) {
          gameEngine.handleScriptOption(step, selections.first);
        } else {
          gameEngine.handleScriptAction(step, selections);
        }
        gameEngine.advanceScript();
        return;
      }
      gameEngine.advanceScript();
      safety++;
    }
    throw StateError('Step $stepId not found in script queue.');
  }

  test(
    'If Sober sends someone home, Bouncer can still select them but the ID-check has no effect and the morning report explains it',
    () async {
      // Advance: Setup night -> Night 1.
      fastForwardPhaseChange();
      expect(gameEngine.currentPhase, GamePhase.night);
      expect(gameEngine.dayCount, 1);

      final victim =
          gameEngine.players.firstWhere((p) => p.role.id == 'party_animal');

      // Sober sends them home first.
      executeStepById('sober_act', [victim.id]);

      expect(gameEngine.nightActions['sober_sent_home'], equals(victim.id));

      // Bouncer attempts to ID-check the sent-home player; selection is allowed
      // but should not apply.
      executeStepById('bouncer_act', [victim.id]);
      expect(gameEngine.nightActions['bouncer_check'], equals(victim.id));
      expect(victim.idCheckedByBouncer, isFalse,
          reason: 'Sent-home players are immune to Bouncer ID-checks.');

      // Resolve the rest of the night to day (builds the morning report).
      fastForwardPhaseChange();

      final summaryLower = gameEngine.lastNightSummary.toLowerCase();
      expect(summaryLower, contains('sent home'));
      expect(summaryLower, contains('bouncer tried to id'));
      expect(summaryLower, contains(victim.name.toLowerCase()));
    },
  );

  test(
    'If Sober sends Minor home, a Bouncer check should not remove Minor immunity',
    () async {
      // Advance: Setup night -> Night 1.
      fastForwardPhaseChange();
      expect(gameEngine.currentPhase, GamePhase.night);
      expect(gameEngine.dayCount, 1);

      final minor = gameEngine.players.firstWhere((p) => p.role.id == 'minor');
      expect(minor.minorHasBeenIDd, isFalse,
          reason: 'Test assumes Minor starts immune to Dealer kills.');

      // Sober sends Minor home first.
      executeStepById('sober_act', [minor.id]);
      expect(gameEngine.nightActions['sober_sent_home'], equals(minor.id));

      // Bouncer attempts to ID-check the sent-home Minor; should not change immunity.
      executeStepById('bouncer_act', [minor.id]);
      expect(gameEngine.nightActions['bouncer_check'], equals(minor.id));

      final refreshedMinor =
          gameEngine.players.firstWhere((p) => p.id == minor.id);
      expect(refreshedMinor.minorHasBeenIDd, isFalse,
          reason: 'Sent-home Minor should remain immune to Dealer kills.');
      expect(minor.minorHasBeenIDd, isFalse,
          reason: 'Local reference should reflect the same immunity state.');

      // Resolve the rest of the night to day (builds the morning report).
      fastForwardPhaseChange();

      final summaryLower = gameEngine.lastNightSummary.toLowerCase();
      expect(summaryLower, contains('sent home'));
      expect(summaryLower, contains('bouncer tried to id'));
      expect(summaryLower, contains(minor.name.toLowerCase()));
    },
  );
}
