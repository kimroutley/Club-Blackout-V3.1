import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/role.dart';
import '../styles.dart';

/// Interactive guide for night phase showing active roles and order
class NightPhaseGuide extends StatelessWidget {
  final GameEngine gameEngine;
  final int currentStepIndex;
  final VoidCallback? onDismiss;

  const NightPhaseGuide({
    super.key,
    required this.gameEngine,
    this.currentStepIndex = 0,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Get active roles in night priority order.
    // Keep this aligned with ScriptBuilder's explicit Night 1+ ordering, so the
    // guide never shows Sober after other priority-1 roles.
    const priorityRoleIds = <String>['sober', 'dealer', 'bouncer', 'medic'];

    int sortKey(Role role) {
      final idx = priorityRoleIds.indexOf(role.id);
      if (idx != -1) return idx;
      if (role.id == 'silver_fox') return 999;
      return 100 + role.nightPriority;
    }

    final activeRoles = gameEngine.guests
        .where((p) => p.isAlive && p.isEnabled && p.role.nightPriority > 0)
        .map((p) => p.role)
        .toSet()
        .toList()
      ..sort((a, b) {
        final ka = sortKey(a);
        final kb = sortKey(b);
        if (ka != kb) return ka.compareTo(kb);

        // Deterministic tie-breaker (Dart's List.sort is not stable).
        final pa = a.nightPriority;
        final pb = b.nightPriority;
        if (pa != pb) return pa.compareTo(pb);
        return a.id.compareTo(b.id);
      });

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              ClubBlackoutTheme.neonPurple.withValues(alpha: 0.12),
              ClubBlackoutTheme.neonBlue.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ClubBlackoutTheme.neonPurple.withValues(alpha: 0.2),
                    ClubBlackoutTheme.neonBlue.withValues(alpha: 0.15),
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
                          ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
                          ClubBlackoutTheme.neonBlue.withValues(alpha: 0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            ClubBlackoutTheme.neonPurple.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: ClubBlackoutTheme.neonPurple,
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
                              ClubBlackoutTheme.neonPurple,
                              ClubBlackoutTheme.neonBlue,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'NIGHT PHASE GUIDE',
                            style: ClubBlackoutTheme.headingStyle.copyWith(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activeRoles.length} ROLES ACTIVE TONIGHT',
                          style: ClubBlackoutTheme.headingStyle.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close_rounded),
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),

            // Role list
            if (activeRoles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.bedtime_rounded,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active night roles',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The night is quiet...',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: activeRoles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final role = activeRoles[index];
                  final isCompleted = index < currentStepIndex;
                  final isCurrent = index == currentStepIndex;
                  final isPending = index > currentStepIndex;

                  return _RoleStepTile(
                    role: role,
                    stepNumber: index + 1,
                    totalSteps: activeRoles.length,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isPending: isPending,
                  );
                },
              ),

            // Footer tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.30),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: ClubBlackoutTheme.neonBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Follow the order from top to bottom. Each role acts once per night.',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleStepTile extends StatelessWidget {
  final Role role;
  final int stepNumber;
  final int totalSteps;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;

  const _RoleStepTile({
    required this.role,
    required this.stepNumber,
    required this.totalSteps,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roleColor = role.color;

    Color bgColor;
    Color borderColor;
    double opacity;

    if (isCompleted) {
      bgColor = ClubBlackoutTheme.neonGreen.withValues(alpha: 0.12);
      borderColor = ClubBlackoutTheme.neonGreen.withValues(alpha: 0.4);
      opacity = 0.6;
    } else if (isCurrent) {
      bgColor = roleColor.withValues(alpha: 0.15);
      borderColor = roleColor.withValues(alpha: 0.6);
      opacity = 1.0;
    } else {
      bgColor = cs.surfaceContainerHighest.withValues(alpha: 0.3);
      borderColor = cs.outline.withValues(alpha: 0.2);
      opacity = 0.5;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: opacity,
        child: Row(
          children: [
            // Step indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? ClubBlackoutTheme.neonGreen.withValues(alpha: 0.2)
                    : (isCurrent
                        ? roleColor.withValues(alpha: 0.2)
                        : cs.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCompleted
                      ? ClubBlackoutTheme.neonGreen
                      : (isCurrent
                          ? roleColor
                          : cs.outline.withValues(alpha: 0.3)),
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: ClubBlackoutTheme.neonGreen,
                        size: 20,
                      )
                    : Text(
                        '$stepNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isCurrent
                              ? roleColor
                              : cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Role info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isCurrent ? roleColor : cs.onSurface,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (role.ability != null && role.ability!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      role.ability!,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Status icon
            if (isCurrent)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: roleColor,
                  size: 20,
                ),
              )
            else if (isCompleted)
              const Icon(
                Icons.check_circle_rounded,
                color: ClubBlackoutTheme.neonGreen,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
