import 'dart:ui';
import 'package:flutter/material.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: phaseColor.withValues(alpha: 0.5),
                  blurRadius: 32,
                  spreadRadius: 6,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: phaseColor.withValues(alpha: 0.3),
                  blurRadius: 48,
                  spreadRadius: 12,
                ),
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  phaseColor.withValues(alpha: isActive ? 0.4 : 0.25),
                  phaseColor.withValues(alpha: isActive ? 0.25 : 0.15),
                  cs.scrim.withValues(alpha: isActive ? 0.22 : 0.28),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: phaseColor.withValues(alpha: isActive ? 0.8 : 0.5),
                width: isActive ? 3 : 2,
              ),
            ),
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
                              phaseColor.withValues(alpha: 0.2),
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
                                    color: phaseColor.withValues(alpha: 0.4),
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
                                    phaseName,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: cs.onSurface,
                                      letterSpacing: 1.4,
                                      shadows: [
                                        Shadow(
                                          color:
                                              cs.shadow.withValues(alpha: 0.55),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                        if (isActive) ...[
                                          Shadow(
                                            color: phaseColor.withValues(
                                                alpha: 0.8),
                                            blurRadius: 20,
                                          ),
                                          Shadow(
                                            color: phaseColor.withValues(
                                                alpha: 0.6),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                if (stepNumber != null &&
                                    totalSteps != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: phaseColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            phaseColor.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '$stepNumber/$totalSteps',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: phaseColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            if (subtitle != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: cs.onSurfaceVariant,
                                  letterSpacing: 0.4,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                  shadows: [
                                    Shadow(
                                      color: cs.shadow.withValues(alpha: 0.55),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress bar (if step numbers provided)
                if (stepNumber != null && totalSteps != null && totalSteps! > 0)
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (stepNumber! / totalSteps!).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              phaseColor,
                              phaseColor.withValues(alpha: 0.8),
                            ],
                          ),
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

                // Tips section (expandable)
                if (tips != null && tips!.isNotEmpty && isActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.30),
                      border: Border(
                        top: BorderSide(
                          color: phaseColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates_rounded,
                              color: phaseColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tips',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: phaseColor,
                                letterSpacing: 0.8,
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
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: phaseColor.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurfaceVariant,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
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
            ),
          ),
        ),
      ),
    );
  }
}
