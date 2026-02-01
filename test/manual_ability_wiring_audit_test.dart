import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('FAB wiring includes pending retaliation entrypoints', () {
    final gameScreenPath = p.join('lib', 'ui', 'screens', 'game_screen.dart');
    final contents = File(gameScreenPath).readAsStringSync();

    expect(
      contents.contains('widget.gameEngine.hasPendingPredatorRetaliation'),
      isTrue,
      reason:
          'Predator retaliation is an engine-level pending action; the in-game FAB menu must expose an entrypoint so it cannot be missed.',
    );

    expect(
      contents.contains('widget.gameEngine.hasPendingTeaSpillerReveal'),
      isTrue,
      reason:
          'Tea Spiller reveal is an engine-level pending action; the in-game FAB menu must expose it only when actually pending.',
    );

    expect(
      contents.contains('markLightweightTabooViolation'),
      isTrue,
      reason:
          'Lightweight taboo violation is a manual host action; GameScreen must expose an entrypoint to trigger it.',
    );

    expect(
      contents.contains('messyBitchVictoryPending'),
      isTrue,
      reason:
          'Messy Bitch pending victory must be visible in GameScreen so the host can declare the win.',
    );
  });
}
