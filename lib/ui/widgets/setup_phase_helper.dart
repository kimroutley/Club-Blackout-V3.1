import 'dart:ui';

import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../styles.dart';

/// Interactive setup phase widget with validations and helpful tips.
///
/// This is displayed during setup to guide the host through the minimum
/// requirements before the game can begin.
class SetupPhaseHelper extends StatelessWidget {
  final GameEngine gameEngine;
  final VoidCallback? onStartGame;

  const SetupPhaseHelper({
    super.key,
    required this.gameEngine,
    this.onStartGame,
  });

  bool get _hasMinimumPlayers => gameEngine.guests.length >= 5;

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

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.22),
            blurRadius: 34,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.55),
                width: 2,
              ),
              gradient: LinearGradient(
                colors: [
                  ClubBlackoutTheme.neonGreen.withValues(alpha: 0.14),
                  ClubBlackoutTheme.neonBlue.withValues(alpha: 0.10),
                  cs.scrim.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(tt, cs),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ChecklistItem(
                        icon: Icons.person_rounded,
                        label: 'Assign a Host',
                        isComplete: _hasHost,
                        detail: _hasHost
                            ? 'Host: ${gameEngine.hostName}'
                            : 'Required to manage the game',
                      ),
                      const SizedBox(height: 12),
                      _ChecklistItem(
                        icon: Icons.groups_rounded,
                        label: 'Add Players (Min. 5)',
                        isComplete: _hasMinimumPlayers,
                        detail:
                            '${gameEngine.guests.length} player${gameEngine.guests.length == 1 ? '' : 's'} added',
                        progress: (gameEngine.guests.isEmpty)
                            ? 0
                            : (gameEngine.guests.length / 5.0),
                      ),
                      const SizedBox(height: 12),
                      _ChecklistItem(
                        icon: Icons.badge_rounded,
                        label: 'Name All Players',
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
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: ClubBlackoutTheme.neonBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Quick Tips',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: ClubBlackoutTheme.neonBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _TipItem(tip: 'Recommended: 7-12 players for best experience'),
                      _TipItem(tip: 'The Host doesn\'t play but manages the game'),
                      _TipItem(tip: 'Roles are assigned automatically after setup'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: FilledButton.icon(
                    onPressed: _canStartGame ? onStartGame : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ClubBlackoutTheme.neonGreen,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: cs.surfaceContainerHighest,
                      disabledForegroundColor: cs.onSurface.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: _canStartGame ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      _canStartGame
                          ? Icons.play_arrow_rounded
                          : Icons.lock_rounded,
                      size: 24,
                    ),
                    label: Text(
                      _canStartGame ? 'Start Game!' : 'Complete Setup First',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme tt, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ClubBlackoutTheme.neonGreen.withValues(alpha: 0.18),
            ClubBlackoutTheme.neonBlue.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ClubBlackoutTheme.neonGreen.withValues(alpha: 0.3),
                  ClubBlackoutTheme.neonBlue.withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: ClubBlackoutTheme.neonGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      ClubBlackoutTheme.neonGreen,
                      ClubBlackoutTheme.neonBlue,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Setup Checklist',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: cs.onSurface,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          color: cs.shadow.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete these steps to start',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        color: cs.shadow.withValues(alpha: 0.45),
                      ),
                    ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? ClubBlackoutTheme.neonGreen.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: isComplete ? 0.35 : 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isComplete
                ? Icon(
                    Icons.check_circle_rounded,
                    color: statusColor,
                    size: 24,
                  )
                : Icon(
                    icon,
                    color: statusColor,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (progress != null && !isComplete) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.75),
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
