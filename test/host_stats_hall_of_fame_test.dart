import 'package:club_blackout/logic/hall_of_fame_service.dart';
import 'package:club_blackout/models/game_log_entry.dart';
import 'package:club_blackout/models/game_story_snapshot.dart';
import 'package:club_blackout/models/vote_cast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _clearHallOfFame() async {
  final service = HallOfFameService.instance;

  // Give the constructor's async _loadProfiles() a chance to complete.
  await Future<void>.delayed(const Duration(milliseconds: 1));

  final existing = List.of(service.allProfiles);
  for (final p in existing) {
    await service.deleteProfile(p.id);
  }
}

GameStorySnapshot _snapshot({
  required String? hostName,
  required List<StoryPlayerSnapshot> players,
  required String? winner,
}) {
  return GameStorySnapshot(
    exportedAt: DateTime.utc(2026, 1, 1),
    dayCount: 1,
    phase: 'end',
    hostName: hostName,
    players: players,
    gameLog: const <GameLogEntry>[],
    voteHistory: const <VoteCast>[],
    currentDayVotesByVoter: const <String, String?>{},
    reactionEventHistory: const <Map<String, dynamic>>[],
    nightHistory: const <Map<String, dynamic>>[],
    voteChanges: const <VoteCast>[],
    winner: winner,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _clearHallOfFame();
  });

  test('Host-only profile accumulates hosted Dealer wins', () async {
    final service = HallOfFameService.instance;

    final game = _snapshot(
      hostName: 'Alex',
      winner: 'The Dealers',
      players: const <StoryPlayerSnapshot>[
        StoryPlayerSnapshot(
          id: 'p1',
          name: 'Bob',
          roleId: 'dealer',
          roleName: 'The Dealer',
          alliance: 'The Dealers',
          isAlive: true,
          isEnabled: true,
        ),
      ],
    );

    await service.processGameStats(game, const []);

    final host =
        service.allProfiles.firstWhere((p) => p.name.toLowerCase() == 'alex');

    expect(host.totalHostedGames, 1);
    expect(host.hostedDealerWins, 1);
    expect(host.hostedPartyWins, 0);
    expect(host.hostedOtherWins, 0);
    expect(host.dealerWinRateWhileHosting, 1.0);

    // Host is not a gameplay player in this snapshot.
    expect(host.totalGames, 0);
    expect(host.totalWins, 0);
  });

  test('If host is also a player, both play + host stats merge', () async {
    final service = HallOfFameService.instance;

    final game = _snapshot(
      hostName: 'Casey',
      winner: 'The Party Animals',
      players: const <StoryPlayerSnapshot>[
        StoryPlayerSnapshot(
          id: 'p1',
          name: 'Casey',
          roleId: 'party_animal',
          roleName: 'The Party Animal',
          alliance: 'The Party Animals',
          isAlive: true,
          isEnabled: true,
        ),
      ],
    );

    await service.processGameStats(game, const []);

    final profile =
        service.allProfiles.firstWhere((p) => p.name.toLowerCase() == 'casey');

    expect(profile.totalHostedGames, 1);
    expect(profile.hostedPartyWins, 1);

    expect(profile.totalGames, 1);
    expect(profile.totalWins, 1);
  });

  test('Unknown/other winners count toward hostedOtherWins', () async {
    final service = HallOfFameService.instance;

    final game = _snapshot(
      hostName: 'Dana',
      winner: 'The Fool',
      players: const <StoryPlayerSnapshot>[],
    );

    await service.processGameStats(game, const []);

    final host =
        service.allProfiles.firstWhere((p) => p.name.toLowerCase() == 'dana');

    expect(host.totalHostedGames, 1);
    expect(host.hostedDealerWins, 0);
    expect(host.hostedPartyWins, 0);
    expect(host.hostedOtherWins, 1);
  });
}
