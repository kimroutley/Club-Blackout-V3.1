import 'dart:async';

import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/player.dart';
import '../../services/sound_service.dart';
import '../animations.dart';
import '../styles.dart';
import 'unified_player_tile.dart';

class VotingWidget extends StatefulWidget {
  final List<Player> players;
  final GameEngine gameEngine;
  final Function(Player eliminated, String verdict) onComplete;
  final ValueChanged<int>? onMaxVotesChanged;
  final bool isVotingEnabled;

  const VotingWidget({
    super.key,
    required this.players,
    required this.gameEngine,
    required this.onComplete,
    this.onMaxVotesChanged,
    this.isVotingEnabled = true,
  });

  @override
  State<VotingWidget> createState() => _VotingWidgetState();
}

class _VotingWidgetState extends State<VotingWidget> {
  // Candidate ID -> List of Voter IDs
  final Map<String, List<String>> _manualVotes = {};

  List<Player> _eligibleVoters() {
    // Excludes: Host, Ally Cat, Sober-sent-home, and Roofi/Paralyzed targets.
    return widget.gameEngine.players.where((p) {
      if (!p.isActive) return false;
      if (p.id == GameEngine.hostPlayerId ||
          p.role.id == GameEngine.hostRoleId) {
        return false;
      }
      if (p.role.id == 'ally_cat') return false;
      if (p.soberSentHome) return false;
      if (p.silencedDay == widget.gameEngine.dayCount) return false;
      return true;
    }).toList();
  }

  int _requiredVotesToReachVerdict({required int eligibleVoterCount}) {
    // Majority of eligible voters; keep a minimum of 2.
    final majority = (eligibleVoterCount ~/ 2) + 1;
    return majority < 2 ? 2 : majority;
  }

  Player? _findEnginePlayer(String id) {
    try {
      return widget.gameEngine.players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _removeVoterFromAll(String voterId) {
    final toRemove = <String>[];
    for (final entry in _manualVotes.entries) {
      entry.value.removeWhere((id) => id == voterId);
      if (entry.value.isEmpty) {
        toRemove.add(entry.key);
      }
    }
    for (final key in toRemove) {
      _manualVotes.remove(key);
    }
  }

  void _syncClingerBinding({required String triggerVoterId}) {
    Player clinger;
    try {
      clinger =
          widget.gameEngine.players.firstWhere((p) => p.role.id == 'clinger');
    } catch (_) {
      return;
    }

    if (clinger.id.isEmpty) return;
    if (!clinger.isActive) return;
    if (clinger.clingerFreedAsAttackDog) return;
    final partnerId = clinger.clingerPartnerId;
    if (partnerId == null || partnerId.isEmpty) return;

    if (triggerVoterId == partnerId) {
      String? partnerTargetId;
      for (final entry in _manualVotes.entries) {
        if (entry.value.contains(partnerId)) {
          partnerTargetId = entry.key;
          break;
        }
      }

      _removeVoterFromAll(clinger.id);
      if (partnerTargetId != null) {
        (_manualVotes[partnerTargetId] ??= <String>[]).add(clinger.id);
      }
    }
  }

  void _onVoterChanged(String candidateId, String voterId, bool select) {
    // Gentle tactile feedback for vote interactions.
    unawaited(
        select ? SoundService().playSelect() : SoundService().playClick());

    Player? clinger;
    try {
      clinger =
          widget.gameEngine.players.firstWhere((p) => p.role.id == 'clinger');
    } catch (_) {
      clinger = null;
    }

    final isClingerBound = clinger != null &&
        clinger.id.isNotEmpty &&
        clinger.isActive &&
        !clinger.clingerFreedAsAttackDog &&
        clinger.clingerPartnerId != null;

    if (isClingerBound && voterId == clinger.id) {
      return;
    }

    setState(() {
      if (select) {
        _removeVoterFromAll(voterId);
        (_manualVotes[candidateId] ??= <String>[]).add(voterId);
      } else {
        _manualVotes[candidateId]?.removeWhere((id) => id == voterId);
        if (_manualVotes[candidateId]?.isEmpty ?? false) {
          _manualVotes.remove(candidateId);
        }
      }

      _syncClingerBinding(triggerVoterId: voterId);

      widget.onMaxVotesChanged?.call(
        _manualVotes.values
            .fold<int>(0, (max, v) => v.length > max ? v.length : max),
      );
    });
  }

  bool _canFinalize() {
    final requiredVotes = _requiredVotesToReachVerdict(
      eligibleVoterCount: _eligibleVoters().length,
    );
    final currentDay = widget.gameEngine.dayCount;
    return _manualVotes.entries.any((e) {
      final candidate = _findEnginePlayer(e.key);
      if (candidate != null && candidate.alibiDay == currentDay) return false;
      return e.value.length >= requiredVotes;
    });
  }

  void _submit() {
    String? eliminatedId;
    int maxVotes = -1;
    bool tie = false;

    final requiredVotes = _requiredVotesToReachVerdict(
      eligibleVoterCount: _eligibleVoters().length,
    );

    final currentDay = widget.gameEngine.dayCount;
    final eligibleCandidates = _manualVotes.entries.where((e) {
      if (e.value.length < requiredVotes) return false;
      final candidate = _findEnginePlayer(e.key);
      return candidate == null || candidate.alibiDay != currentDay;
    }).toList();

    if (eligibleCandidates.isEmpty) return;

    for (final entry in eligibleCandidates) {
      if (entry.value.length > maxVotes) {
        maxVotes = entry.value.length;
        eliminatedId = entry.key;
        tie = false;
      } else if (entry.value.length == maxVotes) {
        tie = true;
      }
    }

    if (tie || eliminatedId == null) {
      unawaited(SoundService().playError());
      widget.gameEngine.showToast(
        'Tie vote or no majority.',
        title: 'Voting',
      );
      return;
    }

    unawaited(SoundService().playActionComplete());

    final eliminated = widget.players.firstWhere((p) => p.id == eliminatedId);

    widget.gameEngine.clearDayVotes();
    for (final entry in _manualVotes.entries) {
      for (final voterId in entry.value) {
        widget.gameEngine.recordVote(voterId: voterId, targetId: entry.key);
      }
    }

    String verdict = 'INNOCENT';
    if (eliminated.role.alliance == 'The Dealers' ||
        eliminated.role.alliance == 'The Dealers (Converted)') {
      verdict = 'DEALER';
    } else if (eliminated.role.id == 'whore') {
      verdict = 'DEALER ALLY';
    }

    widget.onComplete(eliminated, verdict);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Filter out silenced players from the voting pool entirely to reduce clutter.
    // Includes: Ally Cat (mechanic), Sober-sent-home, Roofi/Paralyzed targets, and Host.
    final voters = _eligibleVoters();
    final requiredVotes = _requiredVotesToReachVerdict(
      eligibleVoterCount: voters.length,
    );

    // Collect silenced players for display
    final silencedPlayers = widget.gameEngine.players.where((p) {
      if (!p.isActive) return false;
      return p.silencedDay == widget.gameEngine.dayCount;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'VOTING',
                style: ClubBlackoutTheme.neonGlowTextStyle(
                  base: ClubBlackoutTheme.headingStyle.copyWith(fontSize: 22),
                  color: ClubBlackoutTheme.neonBlue,
                  glowIntensity: 0.8,
                ),
              ),
            ),
            Text(
              'Need $requiredVotes+ votes',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        ClubBlackoutTheme.gap8,
        if (!widget.isVotingEnabled)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  color: cs.onSurface.withValues(alpha: 0.75),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Voting is locked. Start or resume the discussion timer to enable voting.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Silenced players notice
        if (silencedPlayers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ClubBlackoutTheme.neonGreen.withValues(alpha: 0.15),
                  ClubBlackoutTheme.neonGreen.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.voice_over_off_rounded,
                    color: ClubBlackoutTheme.neonGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SILENCED FROM VOTING',
                        style: ClubBlackoutTheme.headingStyle.copyWith(
                          fontSize: 14,
                          color: ClubBlackoutTheme.neonGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        silencedPlayers.map((p) => p.name).join(', '),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: widget.players.length,
          separatorBuilder: (_, __) => ClubBlackoutTheme.gap12,
          itemBuilder: (_, i) {
            final candidate = widget.players[i];
            final currentVotes = _manualVotes[candidate.id] ?? const <String>[];
            final voteCount = currentVotes.length;
            final isVoteImmune = candidate.alibiDay != null &&
                candidate.alibiDay == widget.gameEngine.dayCount;

            final clinger = widget.gameEngine.players.firstWhere(
              (p) => p.role.id == 'clinger',
              orElse: () => Player(id: '', name: '', role: candidate.role),
            );
            final isClingerBound = clinger.id != '' &&
                !clinger.clingerFreedAsAttackDog &&
                clinger.clingerPartnerId != null;

            final accentColor = voteCount >= requiredVotes
                ? ClubBlackoutTheme.neonRed
                : ClubBlackoutTheme.neonBlue;

            return AnimatedContainer(
              duration: ClubMotion.short,
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: voteCount > 0
                    ? LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.15),
                          accentColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: voteCount == 0
                    ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
                    : null,
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: voteCount >= requiredVotes ? 0.6 : 0.35,
                  ),
                  width: voteCount >= requiredVotes ? 2.5 : 1.5,
                ),
                boxShadow: voteCount >= requiredVotes
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    title: UnifiedPlayerTile.compact(
                      player: candidate,
                      gameEngine: widget.gameEngine,
                      wrapInCard: false,
                      showStatusChips: true,
                      enabledOverride: widget.isVotingEnabled,
                      trailing: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: voteCount >= requiredVotes
                                ? [
                                    Colors.redAccent.withValues(alpha: 0.4),
                                    Colors.red.withValues(alpha: 0.2),
                                  ]
                                : [
                                    accentColor.withValues(alpha: 0.25),
                                    accentColor.withValues(alpha: 0.15),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: voteCount >= requiredVotes
                                ? Colors.redAccent.withValues(alpha: 0.8)
                                : accentColor.withValues(alpha: 0.6),
                            width: voteCount >= requiredVotes ? 3 : 2,
                          ),
                          boxShadow: voteCount >= requiredVotes
                              ? [
                                  BoxShadow(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.6),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Icon(
                                voteCount >= requiredVotes
                                    ? Icons.gavel_rounded
                                    : Icons.person_outline,
                                key: ValueKey(voteCount >= requiredVotes),
                                color: voteCount >= requiredVotes
                                    ? Colors.white
                                    : accentColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                color: voteCount >= requiredVotes
                                    ? Colors.white
                                    : accentColor,
                                fontSize: voteCount >= requiredVotes ? 22 : 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                shadows: voteCount >= requiredVotes
                                    ? [
                                        const Shadow(
                                          color: Colors.black87,
                                          blurRadius: 4,
                                        ),
                                        Shadow(
                                          color: Colors.redAccent.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [
                                        Shadow(
                                          color: accentColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 3,
                                        ),
                                      ],
                              ),
                              child: Text('$voteCount'),
                            ),
                            if (voteCount >= requiredVotes) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.warning_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.40)),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: voters.map((voter) {
                        final isSelected = currentVotes.contains(voter.id);
                        final isThisVoterBoundClinger =
                            isClingerBound && voter.id == clinger.id;

                        if (isThisVoterBoundClinger && !isSelected) {
                          return const SizedBox.shrink();
                        }

                        final isTapDisabled = isVoteImmune ||
                            isThisVoterBoundClinger ||
                            !widget.isVotingEnabled;

                        return _VoterChip(
                          voter: voter,
                          isSelected: isSelected,
                          isDisabled: isTapDisabled,
                          accent: accentColor,
                          onTap: isTapDisabled
                              ? null
                              : () {
                                  if (voter.id == candidate.id) return;
                                  _onVoterChanged(
                                      candidate.id, voter.id, !isSelected);
                                },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        AnimatedSwitcher(
          duration: ClubMotion.short,
          child: !_canFinalize()
              ? const SizedBox.shrink()
              : Container(
                  key: const ValueKey('finalize'),
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: ClubBlackoutTheme.neonRed.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: ClubBlackoutTheme.neonRed,
                        foregroundColor: ClubBlackoutTheme.contrastOn(
                          ClubBlackoutTheme.neonRed,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.gavel_rounded, size: 24),
                      label: Text(
                        'FINALIZE ELIMINATION',
                        style: ClubBlackoutTheme.headingStyle.copyWith(
                          fontSize: 16,
                          color: ClubBlackoutTheme.contrastOn(
                            ClubBlackoutTheme.neonRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _VoterChip extends StatelessWidget {
  final Player voter;
  final bool isSelected;
  final bool isDisabled;
  final Color accent;
  final VoidCallback? onTap;

  const _VoterChip({
    required this.voter,
    required this.isSelected,
    required this.isDisabled,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bg = isSelected
        ? accent.withValues(alpha: 0.25)
        : cs.surfaceContainerHighest.withValues(alpha: 0.6);

    final border = isSelected
        ? accent.withValues(alpha: 0.8)
        : cs.outlineVariant.withValues(alpha: 0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        onSelected: isDisabled ? null : (_) => onTap?.call(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        label: Text(
          voter.name,
          overflow: TextOverflow.ellipsis,
          style: tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDisabled
                ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                : (isSelected ? accent : cs.onSurface),
            letterSpacing: 0.3,
          ),
        ),
        avatar: Container(
          padding: const EdgeInsets.all(2),
          decoration: isSelected
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                )
              : null,
          child: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 20,
            color: isSelected ? accent : cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
        side: BorderSide(
          color: border,
          width: isSelected ? 2.0 : 1.2,
        ),
        backgroundColor: bg,
        selectedColor: bg,
        disabledColor: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
