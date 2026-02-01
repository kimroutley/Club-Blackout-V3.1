// ignore_for_file: avoid_print

import 'package:club_blackout/data/role_repository.dart';
import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/player.dart';
import 'package:club_blackout/models/role.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
  const sharedPrefsChannel =
      MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(sharedPrefsChannel,
          (MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{};
    }
    return null;
  });

  test('Benchmark eligibleDayVotesByTarget', () async {
    final engine = GameEngine(roleRepository: RoleRepository());
    final partyRole = Role(
      id: 'party_animal',
      name: 'Party Animal',
      alliance: 'The Party Animals',
      type: 'basic',
      description: 'Just vibing',
      nightPriority: 0,
      assetPath: '',
      colorHex: '#FFFFFF',
    );

    // Setup 20 players
    for (int i = 0; i < 20; i++) {
      final player = Player(
        id: 'p$i',
        name: 'Player $i',
        role: partyRole,
      )..initialize();
      engine.players.add(player);
    }

    // Setup some votes
    // p0->p1, p1->p2, ... p18->p19, p19->p0
    for (int i = 0; i < 20; i++) {
      final voter = 'p$i';
      final target = 'p${(i + 1) % 20}';
      engine.currentDayVotesByVoter[voter] = target;
      if (!engine.currentDayVotesByTarget.containsKey(target)) {
        engine.currentDayVotesByTarget[target] = [];
      }
      engine.currentDayVotesByTarget[target]!.add(voter);
    }

    // Benchmark loop
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100000; i++) {
      final votes = engine.eligibleDayVotesByTarget;
      // Access map to ensure it's not optimized away (though unlikely in Dart VM unless pure)
      if (votes.isEmpty) throw Exception('Should not be empty');
    }
    stopwatch.stop();

    print(
        'Benchmark eligibleDayVotesByTarget: ${stopwatch.elapsedMilliseconds} ms for 100,000 calls');
  });
}
