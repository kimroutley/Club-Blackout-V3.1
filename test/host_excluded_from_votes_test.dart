import 'package:club_blackout/data/role_repository.dart';
import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/models/player.dart';
import 'package:club_blackout/models/role.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRoleRepository extends RoleRepository {
  @override
  Future<void> loadRoles() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sharedPrefsChannel =
      MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(sharedPrefsChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{};
    }
    return null;
  });

  Role makeRole(String id) {
    return Role(
      id: id,
      name: id.toUpperCase(),
      description: 'Test role $id',
      alliance: 'test',
      type: 'test',
      nightPriority: 0,
      assetPath: 'assets/test.png',
      colorHex: '0xFFFFFFFF',
    );
  }

  group('Voting - Host exclusion', () {
    test('recordVote ignores host voterId (synthetic)', () {
      final engine = GameEngine(roleRepository: MockRoleRepository());
      engine.dayCount = 1;

      final voter = Player(id: 'p1', name: 'Voter', role: makeRole('villager'));
      final target = Player(id: 'p2', name: 'Target', role: makeRole('villager'));
      engine.players.addAll([voter, target]);

      engine.recordVote(voterId: GameEngine.hostPlayerId, targetId: target.id);

      expect(engine.voteHistory, isEmpty);
      expect(engine.currentDayVotesByTarget, isEmpty);
      expect(engine.currentDayVotesByVoter.containsKey(GameEngine.hostPlayerId),
          isFalse);
    });

    test('recordVote ignores a host Player if present in roster', () {
      final engine = GameEngine(roleRepository: MockRoleRepository());
      engine.dayCount = 1;

      final host = Player(
        id: GameEngine.hostPlayerId,
        name: 'Host',
        role: makeRole(GameEngine.hostRoleId),
        isEnabled: true,
        isAlive: true,
      );
      final target = Player(id: 'p2', name: 'Target', role: makeRole('villager'));
      engine.players.addAll([host, target]);

      engine.recordVote(voterId: host.id, targetId: target.id);

      expect(engine.voteHistory, isEmpty);
      expect(engine.currentDayVotesByTarget, isEmpty);

      // Defensive tally should also exclude host even if some stale state exists.
      engine.currentDayVotesByTarget[target.id] = [host.id];
      expect(engine.eligibleDayVotesByTarget[target.id], isNull);
    });
  });
}
