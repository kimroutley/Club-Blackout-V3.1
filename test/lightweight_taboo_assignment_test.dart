import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/script_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameEngine engine;
  late FileRoleRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = FileRoleRepository();
    await repo.loadRoles();

    engine = GameEngine(roleRepository: repo);
    await engine.createTestGame(fullRoster: true);
    await engine.startGame();
  });

  void fastForwardPhaseChange() {
    int safety = 0;
    final initialPhase = engine.currentPhase;
    final initialDay = engine.dayCount;

    while (
        engine.currentScriptIndex < engine.scriptQueue.length && safety < 800) {
      engine.advanceScript();
      safety++;
      if (engine.currentPhase != initialPhase ||
          engine.dayCount != initialDay) {
        return;
      }
    }
    throw StateError('Failed to reach next phase change.');
  }

  void executeStepById(String stepId, List<String> selections) {
    int safety = 0;
    final initialPhase = engine.currentPhase;
    final initialDay = engine.dayCount;

    while (
        engine.currentScriptIndex < engine.scriptQueue.length && safety < 800) {
      if (engine.currentPhase != initialPhase ||
          engine.dayCount != initialDay) {
        throw StateError(
            'Step $stepId not found before phase/day change (phase=$initialPhase day=$initialDay).');
      }

      final step = engine.scriptQueue[engine.currentScriptIndex];
      if (step.id == stepId) {
        if (step.actionType == ScriptActionType.toggleOption) {
          engine.handleScriptOption(step, selections.first);
        } else {
          engine.handleScriptAction(step, selections);
        }
        engine.advanceScript();
        return;
      }

      engine.advanceScript();
      safety++;
    }

    throw StateError('Step $stepId not found in script queue.');
  }

  test('Lightweight selection adds taboo name and accumulates across nights',
      () async {
    // Setup night -> Night 1.
    fastForwardPhaseChange();
    expect(engine.currentPhase, GamePhase.night);

    final lightweight =
        engine.players.firstWhere((p) => p.role.id == 'lightweight');

    final target1 = engine.players.firstWhere(
      (p) => p.isAlive && p.isEnabled && p.id != lightweight.id,
    );
    final target2 = engine.players.firstWhere(
      (p) =>
          p.isAlive &&
          p.isEnabled &&
          p.id != lightweight.id &&
          p.id != target1.id,
    );

    // Night 1: assign taboo.
    executeStepById('lightweight_act', [target1.id]);

    expect(engine.nightActions['lightweight_taboo'], equals(target1.id));
    expect(lightweight.tabooNames, contains(target1.name));

    // Finish Night 1 -> Day.
    fastForwardPhaseChange();
    expect(engine.currentPhase, GamePhase.day);

    // Finish Day -> Night 2.
    fastForwardPhaseChange();
    expect(engine.currentPhase, GamePhase.night);

    // Night 2: assign another taboo.
    executeStepById('lightweight_act', [target2.id]);

    expect(engine.nightActions['lightweight_taboo'], equals(target2.id));
    expect(lightweight.tabooNames,
        containsAll(<String>[target1.name, target2.name]));
  });

  test('Lightweight does not duplicate the same taboo name', () {
    final lightweight =
        engine.players.firstWhere((p) => p.role.id == 'lightweight');
    final target =
        engine.players.firstWhere((p) => p.role.id == 'party_animal');

    const step = ScriptStep(
      id: 'lightweight_act',
      title: 'New Taboo Name',
      readAloudText: 'Text',
      instructionText: 'Text',
      actionType: ScriptActionType.selectPlayer,
      roleId: 'lightweight',
    );

    engine.handleScriptAction(step, [target.id]);
    engine.handleScriptAction(step, [target.id]);

    final occurrences =
        lightweight.tabooNames.where((n) => n == target.name).length;
    expect(occurrences, equals(1));
  });
}
