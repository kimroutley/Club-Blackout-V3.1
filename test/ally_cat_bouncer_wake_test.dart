import 'package:club_blackout/logic/script_builder.dart';
import 'package:club_blackout/models/player.dart';
import 'package:club_blackout/models/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScriptBuilder: Ally Cat + Bouncer wake', () {
    Role role(String id, {int nightPriority = 0}) {
      return Role(
        id: id,
        name: id,
        description: 'test role $id',
        alliance: 'test',
        type: 'test',
        nightPriority: nightPriority,
        assetPath: 'assets/test.png',
        colorHex: '0xFF00FF00',
      );
    }

    test('Bouncer ID check wake includes Ally Cat when present', () {
      final bouncer = Player(
        id: 'b1',
        name: 'Bouncer',
        role: role('bouncer', nightPriority: 2),
      )..initialize();
      final allyCat = Player(id: 'a1', name: 'Ally Cat', role: role('ally_cat'))
        ..initialize();
      final victim = Player(id: 'p1', name: 'Party', role: role('party_animal'))
        ..initialize();

      final steps =
          ScriptBuilder.buildNightScript([bouncer, allyCat, victim], 1);

      final bouncerStep = steps.firstWhere(
        (s) => s.id == 'bouncer_act',
        orElse: () =>
            throw StateError('Expected bouncer_act step in night script'),
      );

      expect(bouncerStep.readAloudText, contains('Ally Cat'));
    });

    test('Bouncer ID check wake does not mention Ally Cat when absent', () {
      final bouncer = Player(
        id: 'b1',
        name: 'Bouncer',
        role: role('bouncer', nightPriority: 2),
      )..initialize();
      final victim = Player(id: 'p1', name: 'Party', role: role('party_animal'))
        ..initialize();

      final steps = ScriptBuilder.buildNightScript([bouncer, victim], 1);

      final bouncerStep = steps.firstWhere(
        (s) => s.id == 'bouncer_act',
        orElse: () =>
            throw StateError('Expected bouncer_act step in night script'),
      );

      expect(bouncerStep.readAloudText, isNot(contains('Ally Cat')));
    });
  });
}
