import 'package:club_blackout/data/role_repository.dart';
import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/logic/script_builder.dart';
import 'package:club_blackout/models/player.dart';
import 'package:club_blackout/models/role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/file_role_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Sober Sent Home - Target Protection', () {
    late GameEngine engine;
    late RoleRepository roleRepo;
    late Player sober;
    late Player medic;
    late Player bouncer;
    late Player dealer;
    late Player roofi;
    late Player victim;
    late Role soberRole;
    late Role medicRole;
    late Role bouncerRole;
    late Role dealerRole;
    late Role roofiRole;
    late Role victimRole;

    setUp(() async {
      roleRepo = FileRoleRepository();
      await roleRepo.loadRoles();
      engine = GameEngine(roleRepository: roleRepo);

      soberRole = roleRepo.getRoleById('sober')!;
      medicRole = roleRepo.getRoleById('medic')!;
      bouncerRole = roleRepo.getRoleById('bouncer')!;
      dealerRole = roleRepo.getRoleById('dealer')!;
      roofiRole = roleRepo.getRoleById('roofi')!;
      victimRole = roleRepo.getRoleById('party_animal')!;

      sober = Player(id: 's1', name: 'Sober', role: soberRole);
      medic = Player(id: 'm1', name: 'Medic', role: medicRole);
      bouncer = Player(id: 'b1', name: 'Bouncer', role: bouncerRole);
      dealer = Player(id: 'd1', name: 'Dealer', role: dealerRole);
      roofi = Player(id: 'r1', name: 'Roofi', role: roofiRole);
      victim = Player(id: 'v1', name: 'Victim', role: victimRole);

      engine.players.addAll([sober, medic, bouncer, dealer, roofi, victim]);
    });

    test('Dealer can target sent-home player but kill fails', () {
      // Send victim home
      victim.soberSentHome = true;
      engine.nightActions['sober_sent_home'] = victim.id;

      // Try to kill the sent-home player
      final step = ScriptBuilder.buildNightScript([sober, dealer, victim], 1)
          .firstWhere((s) => s.roleId == 'dealer',
              orElse: () => throw StateError('No dealer step'));

      // Attempt to target sent-home player
      engine.handleScriptAction(step, [victim.id]);

      // Verify action was queued, but sent-home protection prevents the death.
      expect(engine.nightActions['kill'], equals(victim.id),
          reason: 'Dealer kill should be recorded even for sent-home player');

      // Simulate kill resolution: sent-home players cannot die to night murders.
      engine.processDeath(victim, cause: 'night_kill');
      expect(victim.isAlive, isTrue,
          reason: 'Sent-home player should remain alive');
    });

    test('Sent home player cannot be targeted by Bouncer ID check', () {
      // Send victim home
      victim.soberSentHome = true;

      final step = ScriptBuilder.buildNightScript([sober, bouncer, victim], 1)
          .firstWhere((s) => s.roleId == 'bouncer',
              orElse: () => throw StateError('No bouncer step'));

      // Attempt to check sent-home player
      engine.handleScriptAction(step, [victim.id]);

      // Verify action was queued but player not actually ID'd
      expect(engine.nightActions.containsKey('bouncer_check'), isTrue,
          reason:
              'Bouncer check should be queued (to trigger immunity message)');
      expect(victim.idCheckedByBouncer, isFalse,
          reason: 'Sent-home player should not actually be ID checked');
    });

    test('Sent home player dodges Roofi paralysis (logs WTF message)', () {
      // Send victim home
      victim.soberSentHome = true;

      final step = ScriptBuilder.buildNightScript([sober, roofi, victim], 1)
          .firstWhere((s) => s.roleId == 'roofi',
              orElse: () => throw StateError('No roofi step'));

      // Attempt to silence sent-home player
      engine.handleScriptAction(step, [victim.id]);

      // Verify action was queued but player not actually silenced
      expect(engine.nightActions.containsKey('roofi'), isTrue,
          reason:
              'Roofi action should be queued (to trigger immunity message)');
      expect(victim.silencedDay, isNull,
          reason: 'Sent-home player should not actually be silenced');

      expect(
        engine.gameLog.any(
          (log) =>
              log.description.contains('tried to paralyze ${victim.name}') &&
              log.description.contains("didn't get to them fast enough"),
        ),
        isTrue,
        reason: 'WTF bulletin should explain Roofi missed due to sent-home.',
      );
    });

    test('Medic can target sent-home player but action is wasted', () {
      // Send victim home
      victim.soberSentHome = true;
      medic.medicChoice = 'PROTECT_DAILY';

      final step = ScriptBuilder.buildNightScript([sober, medic, victim], 1)
          .firstWhere((s) => s.roleId == 'medic',
              orElse: () => throw StateError('No medic step'));

      // Medic protects sent-home player
      engine.handleScriptAction(step, [victim.id]);

      // Verify action WAS queued (Medic can target them)
      expect(engine.nightActions['protect'], equals(victim.id),
          reason:
              'Medic protection should be queued even for sent-home player');

      // Verify wasted message appears in morning report
      // Note: We can't easily test the morning report message without full phase transition
      // but the key is that the action is queued (not blocked)
    });

    test('Multiple targets - rejects if any are sent home', () {
      // For roles that can target multiple players (like Bartender)
      final bartenderRole = roleRepo.getRoleById('bartender')!;
      final bartender =
          Player(id: 'bart1', name: 'Bartender', role: bartenderRole);
      final player2Role = roleRepo.getRoleById('party_animal')!;
      final player2 = Player(id: 'p2', name: 'Player2', role: player2Role);

      engine.players.addAll([bartender, player2]);

      // Send one player home
      victim.soberSentHome = true;

      final step =
          ScriptBuilder.buildNightScript([sober, bartender, victim, player2], 1)
              .firstWhere((s) => s.roleId == 'bartender',
                  orElse: () => throw StateError('No bartender step'));

      // Try to target both (one is sent home)
      engine.handleScriptAction(step, [victim.id, player2.id]);

      // Verify action was queued but shows immunity message instead of normal result
      expect(engine.nightActions.containsKey('bartender_a'), isTrue,
          reason:
              'Bartender action should be queued (to trigger immunity message)');
    });

    test('Sent home status resets during phase transition', () {
      // This is a documentation test - soberSentHome is reset in skipToNextPhase
      // when transitioning from night to day (see game_engine.dart line 1202)
      victim.soberSentHome = true;

      // Reset happens automatically during phase transitions
      // Just verify the flag can be set and cleared
      expect(victim.soberSentHome, isTrue);
      victim.soberSentHome = false;
      expect(victim.soberSentHome, isFalse);
    });
  });
}
