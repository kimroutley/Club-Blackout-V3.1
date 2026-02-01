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
    while (gameEngine.currentScriptIndex < gameEngine.scriptQueue.length &&
        safety < 600) {
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
      'If Sober sends someone home, they dodge Roofi paralysis and the morning report explains it',
      () async {
    // Advance: Setup night -> Night 1.
    fastForwardPhaseChange();
    expect(gameEngine.currentPhase, GamePhase.night);
    expect(gameEngine.dayCount, 1);

    final victim =
        gameEngine.players.firstWhere((p) => p.role.id == 'party_animal');

    // Sober acts at the start of the night.
    executeStepById('sober_act', [victim.id]);

    expect(gameEngine.nightActions['sober_sent_home'], equals(victim.id),
        reason: 'Sober selection should be recorded in nightActions.');

    // Roofi attempts to paralyze the sent-home player, but it should not apply.
    executeStepById('roofi_act', [victim.id]);

    expect(gameEngine.nightActions['roofi'], equals(victim.id),
        reason: 'Roofi selection should be recorded in nightActions.');
    expect(victim.silencedDay, isNull,
        reason: 'Sent-home players dodge Roofi paralysis.');

    // Resolve the rest of the night to day (builds the morning report).
    fastForwardPhaseChange();

    expect(gameEngine.nightHistory, isNotEmpty);
    final archived = gameEngine.nightHistory.last;
    expect(archived['sober_sent_home'], equals(victim.id));
    expect(archived['roofi'], equals(victim.id));

    expect(victim.soberSentHome, isTrue,
        reason: 'Victim should still be marked as sent home for this night.');

    // Critically: Roofi paralysis should not apply for tomorrow.
    expect(victim.silencedDay, isNull,
        reason: 'Sent-home players dodge Roofi paralysis.');

    final summaryLower = gameEngine.lastNightSummary.toLowerCase();
    expect(summaryLower, contains('sent home'));
    expect(summaryLower, contains('roofi tried to paralyze'));
    expect(summaryLower, contains(victim.name.toLowerCase()));
    expect(summaryLower, contains("didn't get to them fast enough"));
  });
}
