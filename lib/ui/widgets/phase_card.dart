import 'package:flutter/material.dart';
import '../styles.dart';
import 'neon_glass_card.dart';

class PhaseCard extends StatelessWidget {
  final String phaseName;
  final String? subtitle;
  final Color phaseColor;
  final IconData phaseIcon;
  final bool isActive;
  final int? stepNumber;
  final int? totalSteps;
  final List<String>? tips;

  const PhaseCard({
    super.key,
    required this.phaseName,
    this.subtitle,
    required this.phaseColor,
    required this.phaseIcon,
    required this.isActive,
    this.stepNumber,
    this.totalSteps,
    this.tips,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NeonGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      glowColor: phaseColor,
      opacity: isActive ? 0.85 : 0.65,
      borderRadius: 28,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        phaseColor.withValues(alpha: 0.3),
                        phaseColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: phaseColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: phaseColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    phaseIcon,
                    color: phaseColor,
                    size: 36,
                    shadows: isActive
                        ? [
                            Shadow(
                              color: phaseColor.withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 20),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phase name with optional step indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              phaseName.toUpperCase(),
                              style: ClubBlackoutTheme.headingStyle.copyWith(
                                fontSize: 20,
                                color: cs.onSurface,
                                shadows: [
                                  if (isActive)
                                    ...ClubBlackoutTheme.textGlow(phaseColor,
                                        intensity: 1.2),
                                ],
                              ),
                            ),
                          ),
                          if (stepNumber != null && totalSteps != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: phaseColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: phaseColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '$stepNumber/$totalSteps',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: phaseColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (subtitle != null)
                        Text(
                          subtitle!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: phaseColor.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress bar (if step numbers provided)
          if (stepNumber != null && totalSteps != null && totalSteps! > 0)
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (stepNumber! / totalSteps!).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: phaseColor,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: phaseColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          if (isActive && tips != null && tips!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 16,
                        color: phaseColor.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HOST TIPS',
                        style: ClubBlackoutTheme.headingStyle.copyWith(
                          fontSize: 12,
                          color: phaseColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...tips!.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•',
                              style: TextStyle(
                                  color: phaseColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.85),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
