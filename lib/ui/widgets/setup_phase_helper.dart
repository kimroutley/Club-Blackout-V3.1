import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../styles.dart';
import 'neon_glass_card.dart';

/// Interactive setup phase widget with validations and helpful tips.
class SetupPhaseHelper extends StatelessWidget {
  final GameEngine gameEngine;
  final VoidCallback? onStartGame;

  const SetupPhaseHelper({
    super.key,
    required this.gameEngine,
    this.onStartGame,
  });

  bool get _hasMinimumPlayers => gameEngine.guests.length >= 4;

  bool get _hasHost {
    final hostName = gameEngine.hostName;
    return hostName != null && hostName.trim().isNotEmpty;
  }

  bool get _allPlayersNamed =>
      gameEngine.guests.every((p) => p.name.trim().isNotEmpty);

  int get _unnamedCount =>
      gameEngine.guests.where((p) => p.name.trim().isEmpty).length;

  bool get _canStartGame => _hasMinimumPlayers && _hasHost && _allPlayersNamed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return NeonGlassCard(
      glowColor: _canStartGame
          ? ClubBlackoutTheme.neonGreen
          : ClubBlackoutTheme.neonBlue,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.zero,
      borderRadius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(tt, cs),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: [
                _ChecklistItem(
                  icon: Icons.person_rounded,
                  label: 'ASSIGN A HOST',
                  isComplete: _hasHost,
                  detail: _hasHost
                      ? 'Host: ${gameEngine.hostName}'
                      : 'Required to manage the session',
                ),
                const SizedBox(height: 14),
                _ChecklistItem(
                  icon: Icons.groups_rounded,
                  label: 'ADD PLAYERS (MIN. 5)',
                  isComplete: _hasMinimumPlayers,
                  detail:
                      '${gameEngine.guests.length} player${gameEngine.guests.length == 1 ? "" : "s"} added',
                  progress: (gameEngine.guests.isEmpty)
                      ? 0
                      : (gameEngine.guests.length / 5.0),
                ),
                const SizedBox(height: 14),
                _ChecklistItem(
                  icon: Icons.badge_rounded,
                  label: 'NAME ALL PLAYERS',
                  isComplete: _allPlayersNamed,
                  detail: gameEngine.guests.isEmpty
                      ? 'Add players first'
                      : (_allPlayersNamed
                          ? 'All players named'
                          : '$_unnamedCount unnamed'),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ClubBlackoutTheme.neonBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ClubBlackoutTheme.neonBlue.withOpacity(0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      color: ClubBlackoutTheme.neonBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'QUICK TIPS',
                      style: ClubBlackoutTheme.neonGlowFont.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: ClubBlackoutTheme.neonBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _TipItem(
                    tip: 'Recommended: 7-12 players for best experience'),
                const _TipItem(
                    tip: 'The Host doesn\'t play but manages the game'),
                const _TipItem(
                    tip: 'Roles are assigned automatically after setup'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              height: 60,
              child: FilledButton.icon(
                onPressed: _canStartGame ? onStartGame : null,
                style: ClubBlackoutTheme.neonButtonStyle(
                  _canStartGame
                      ? ClubBlackoutTheme.neonGreen
                      : ClubBlackoutTheme.neonBlue,
                  isPrimary: _canStartGame,
                ).copyWith(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),




                ),
                icon: Icon(
                  _canStartGame
                      ? Icons.play_arrow_rounded
                      : Icons.lock_outline_rounded,
                  size: 28,
                ),
                label: Text(
                  (_canStartGame ? 'START GAME!' : 'COMPLETE SETUP')
                      .toUpperCase(),
                  style: ClubBlackoutTheme.neonGlowFont.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme tt, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ClubBlackoutTheme.neonGreen.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(
            color: ClubBlackoutTheme.neonGreen.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ClubBlackoutTheme.neonGreen.withOpacity(0.3),
                  ClubBlackoutTheme.neonBlue.withOpacity(0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ClubBlackoutTheme.neonGreen.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: ClubBlackoutTheme.neonGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GAME SETUP',
                  style: ClubBlackoutTheme.neonGlowFont.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 2.0,
                    color: ClubBlackoutTheme.neonGreen,
                    shadows: [
                      Shadow(
                        color: ClubBlackoutTheme.neonGreen.withOpacity(0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phase 0: Initialization'.toUpperCase(),
                  style: ClubBlackoutTheme.headingStyle.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isComplete;
  final String detail;
  final double? progress;

  const _ChecklistItem({
    required this.icon,
    required this.label,
    required this.isComplete,
    required this.detail,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor =
        isComplete ? ClubBlackoutTheme.neonGreen : ClubBlackoutTheme.neonOrange;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isComplete
            ? ClubBlackoutTheme.neonGreen.withOpacity(0.05)
            : cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(isComplete ? 0.3 : 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isComplete ? Icons.verified_rounded : icon,
              color: statusColor,
              size: 24,
            ),

          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: ClubBlackoutTheme.neonGlowFont.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isComplete ? ClubBlackoutTheme.neonGreen : cs.onSurface,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (progress != null && !isComplete) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: cs.onSurface.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String tip;

  const _TipItem({required this.tip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ClubBlackoutTheme.neonBlue.withOpacity(0.4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.4),
                  blurRadius: 4,
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.8),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
