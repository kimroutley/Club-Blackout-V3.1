import '../models/player.dart';
import '../models/vote_cast.dart';
import 'game_engine.dart';

class DayVoteSnapshot {
  final int day;

  /// Final votes for the day: targetId -> voterIds
  final Map<String, List<String>> votesByTarget;

  /// Voters who participated in voting telemetry this day (cast or cleared).
  final List<String> participatingVoterIds;

  /// Voters whose final vote for the day is null.
  final List<String> abstainedVoterIds;

  /// Raw count of vote events recorded that day.
  final int voteActions;

  const DayVoteSnapshot({
    required this.day,
    required this.votesByTarget,
    required this.participatingVoterIds,
    required this.abstainedVoterIds,
    required this.voteActions,
  });
}

class VotingTargetBreakdown {
  final String targetId;
  final String targetName;
  final int voteCount;
  final List<String> voterIds;
  final List<String> voterNames;

  const VotingTargetBreakdown({
    required this.targetId,
    required this.targetName,
    required this.voteCount,
    required this.voterIds,
    required this.voterNames,
  });
}

class VotingVoterStat {
  final String voterId;
  final String voterName;
  final int voteActions;
  final int changes;

  const VotingVoterStat({
    required this.voterId,
    required this.voterName,
    required this.voteActions,
    required this.changes,
  });
}

/// Host-focused read model for voting.
///
/// This intentionally leans into "fun stats" rather than strict game rules.
class VotingInsights {
  final int day;

  /// How many players currently have a non-null vote.
  final int votesCastToday;

  /// Per-target breakdown of current votes (sorted desc by vote count).
  final List<VotingTargetBreakdown> currentBreakdown;

  /// Total count of vote actions recorded so far (over the whole game).
  final int totalVoteActions;

  /// Top "most active" voters (by vote actions), for commentary.
  final List<VotingVoterStat> topVoters;

  /// Most targeted players over time (based on vote actions towards them).
  final List<VotingTargetBreakdown> mostTargetedAllTime;

  /// Per-day final vote snapshots derived from vote telemetry.
  ///
  /// Note: this includes players who participated in voting telemetry that day.
  /// It cannot perfectly infer players who were eligible but never voted.
  final List<DayVoteSnapshot> daySnapshots;

  const VotingInsights({
    required this.day,
    required this.votesCastToday,
    required this.currentBreakdown,
    required this.totalVoteActions,
    required this.topVoters,
    required this.mostTargetedAllTime,
    required this.daySnapshots,
  });

  factory VotingInsights.fromEngine(
    GameEngine engine, {
    int topVoterLimit = 3,
    int topTargetLimit = 3,
  }) {
    final playersById = <String, Player>{
      for (final p in engine.players) p.id: p,
    };

    // Current breakdown (uses current-day voter->target mapping).
    final breakdown = <VotingTargetBreakdown>[];
    final byTarget = engine.eligibleDayVotesByTarget;

    for (final entry in byTarget.entries) {
      final targetId = entry.key;
      final voterIds = List<String>.from(entry.value);
      final target = playersById[targetId];
      if (target == null) continue;

      voterIds.sort((a, b) {
        final an = playersById[a]?.name ?? '';
        final bn = playersById[b]?.name ?? '';
        return an.compareTo(bn);
      });

      final voterNames = voterIds
          .map((id) => playersById[id]?.name ?? id)
          .toList(growable: false);

      breakdown.add(
        VotingTargetBreakdown(
          targetId: targetId,
          targetName: target.name,
          voteCount: voterIds.length,
          voterIds: voterIds,
          voterNames: voterNames,
        ),
      );
    }

    breakdown.sort((a, b) => b.voteCount.compareTo(a.voteCount));

    // History stats.
    final history = engine.voteHistory;

    // Per-day final vote snapshots.
    final sortedHistory = List<VoteCast>.from(history)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final finalByDay = <int, Map<String, String?>>{};
    final actionsByDay = <int, int>{};
    for (final v in sortedHistory) {
      finalByDay.putIfAbsent(v.day, () => <String, String?>{});
      // Later events overwrite earlier ones, so this becomes the final state.
      finalByDay[v.day]![v.voterId] = v.targetId;
      actionsByDay[v.day] = (actionsByDay[v.day] ?? 0) + 1;
    }

    final daySnapshots = finalByDay.entries
        .map((entry) {
          final day = entry.key;
          final finalByVoter = entry.value;
          final votesByTarget = <String, List<String>>{};
          final abstained = <String>[];

          for (final row in finalByVoter.entries) {
            final voterId = row.key;
            final targetId = row.value;
            if (targetId == null) {
              abstained.add(voterId);
            } else {
              votesByTarget.putIfAbsent(targetId, () => <String>[]).add(voterId);
            }
          }

          // Stable ordering for deterministic UI/tests.
          for (final voters in votesByTarget.values) {
            voters.sort();
          }
          abstained.sort();

          final participating = finalByVoter.keys.toList(growable: false)..sort();

          return DayVoteSnapshot(
            day: day,
            votesByTarget: votesByTarget,
            participatingVoterIds: participating,
            abstainedVoterIds: abstained,
            voteActions: actionsByDay[day] ?? 0,
          );
        })
        .toList(growable: false);

    daySnapshots.sort((a, b) => b.day.compareTo(a.day));

    // Vote actions per voter, plus "changes" (target changes over time).
    final actionsByVoter = <String, int>{};
    final changesByVoter = <String, int>{};
    final lastTargetByVoter = <String, String?>{};

    for (final v in sortedHistory) {
      // Only count explicit votes (ignore clears as an action for stats by default).
      if (v.targetId != null) {
        actionsByVoter[v.voterId] = (actionsByVoter[v.voterId] ?? 0) + 1;
      }

      final last = lastTargetByVoter[v.voterId];
      if (last != null && v.targetId != null && v.targetId != last) {
        changesByVoter[v.voterId] = (changesByVoter[v.voterId] ?? 0) + 1;
      }
      if (v.targetId != null) {
        lastTargetByVoter[v.voterId] = v.targetId;
      }
    }

    final topVoters = actionsByVoter.entries
        .map(
          (e) => VotingVoterStat(
            voterId: e.key,
            voterName: playersById[e.key]?.name ?? e.key,
            voteActions: e.value,
            changes: changesByVoter[e.key] ?? 0,
          ),
        )
        .toList();

    topVoters.sort((a, b) {
      final byActions = b.voteActions.compareTo(a.voteActions);
      if (byActions != 0) return byActions;
      return b.changes.compareTo(a.changes);
    });

    // Most targeted all-time: count vote actions that pointed at the target.
    final targetActions = <String, int>{};
    for (final v in history) {
      final t = v.targetId;
      if (t == null) continue;
      targetActions[t] = (targetActions[t] ?? 0) + 1;
    }

    final mostTargeted = targetActions.entries
        .map((e) {
          final target = playersById[e.key];
          if (target == null) return null;
          return VotingTargetBreakdown(
            targetId: e.key,
            targetName: target.name,
            voteCount: e.value,
            voterIds: const [],
            voterNames: const [],
          );
        })
        .whereType<VotingTargetBreakdown>()
        .toList();

    mostTargeted.sort((a, b) => b.voteCount.compareTo(a.voteCount));

    final votesCastToday = engine.currentDayVotesByVoter.entries
        .where((e) => e.value != null)
        .where((e) => !(playersById[e.key]?.soberSentHome ?? false))
        .length;

    return VotingInsights(
      day: engine.dayCount,
      votesCastToday: votesCastToday,
      currentBreakdown: breakdown,
      totalVoteActions: history.where((v) => v.targetId != null).length,
      topVoters: topVoters.take(topVoterLimit).toList(growable: false),
      mostTargetedAllTime:
          mostTargeted.take(topTargetLimit).toList(growable: false),
      daySnapshots: daySnapshots,
    );
  }
}
