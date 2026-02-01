import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/logic/monte_carlo_simulator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/file_role_repository.dart';

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
    if (methodCall.method.startsWith('set') ||
        methodCall.method == 'commit' ||
        methodCall.method == 'remove') {
      return true;
    }
    return null;
  });

  test('MonteCarloSimulator Benchmark', () async {
    final repo = FileRoleRepository();
    await repo.loadRoles();

    final engine = GameEngine(
      roleRepository: repo,
      loadNameHistory: false,
      loadArchivedSnapshot: false,
    );

    // Setup a basic game
    await engine.createTestGame(fullRoster: true);
    await engine.startGame();

    print('Starting Monte Carlo simulation benchmark...');
    final stopwatch = Stopwatch()..start();

    final result = await MonteCarloSimulator.simulateWinOdds(
      engine,
      runs: 500, // Reasonable number for benchmark
      seed: 12345,
    );

    stopwatch.stop();

    print(
        'Simulation completed: ${result.runs} runs in ${stopwatch.elapsedMilliseconds}ms');
    print('Wins: ${result.wins}');
  });
}
