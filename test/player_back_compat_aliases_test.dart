import 'package:club_blackout/models/player.dart';
import 'package:club_blackout/models/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Role makeRole(String id) {
    return Role(
      id: id,
      name: id.toUpperCase(),
      description: 'Test role',
      alliance: 'test',
      type: 'test',
      nightPriority: 0,
      assetPath: 'assets/test.png',
      colorHex: '0xFFFFFFFF',
    );
  }

  test('Player reviveUsed alias mirrors hasReviveToken', () {
    final p = Player(id: 'p1', name: 'P1', role: makeRole('medic'));

    expect(p.hasReviveToken, isFalse);
    expect(p.reviveUsed, isFalse);

    p.reviveUsed = true;
    expect(p.hasReviveToken, isTrue);
    expect(p.reviveUsed, isTrue);

    p.hasReviveToken = false;
    expect(p.reviveUsed, isFalse);
  });

  test('Player teaSpillerMarkId alias mirrors teaSpillerTargetId', () {
    final p = Player(id: 'p1', name: 'P1', role: makeRole('tea_spiller'));

    expect(p.teaSpillerTargetId, isNull);
    expect(p.teaSpillerMarkId, isNull);

    p.teaSpillerMarkId = 't1';
    expect(p.teaSpillerTargetId, 't1');

    p.teaSpillerTargetId = 't2';
    expect(p.teaSpillerMarkId, 't2');
  });

  test('Player predatorMarkId alias mirrors predatorTargetId', () {
    final p = Player(id: 'p1', name: 'P1', role: makeRole('predator'));

    expect(p.predatorTargetId, isNull);
    expect(p.predatorMarkId, isNull);

    p.predatorMarkId = 'x1';
    expect(p.predatorTargetId, 'x1');

    p.predatorTargetId = 'x2';
    expect(p.predatorMarkId, 'x2');
  });
}
