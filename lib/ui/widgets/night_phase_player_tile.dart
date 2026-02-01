import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/player.dart';
import '../styles.dart';
import 'player_icon.dart';

class NightPhasePlayerTile extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final GameEngine gameEngine;
  final String? statsText;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;

  const NightPhasePlayerTile({
    super.key,
    required this.player,
    required this.isSelected,
    required this.gameEngine,
    this.statsText,
    this.onTap,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = statsText ?? player.role.name;
    final accent = player.role.color;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.35),
                    accent.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    cs.surfaceContainerHigh.withValues(alpha: 0.9),
                    cs.surfaceContainerHigh.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isSelected
                ? accent
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: PlayerIcon(
                      assetPath: player.role.assetPath,
                      glowColor: accent,
                      glowIntensity: isSelected ? 0.6 : 0.0,
                      size: 52,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            shadows: isSelected
                                ? [
                                    Shadow(
                                      color: accent.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            subtitle.toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? accent
                                  : Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onConfirm == null && isSelected) ...[
                    const SizedBox(width: 14),
                    Icon(
                      Icons.check_circle_rounded,
                      color: accent,
                      size: 26,
                      shadows: [
                        Shadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ],
                  if (onConfirm != null) ...[
                    const SizedBox(width: 16),
                    AnimatedScale(
                      scale: isSelected ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: FilledButton.icon(
                            onPressed: isSelected ? onConfirm : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor:
                                  ClubBlackoutTheme.contrastOn(accent),
                              disabledBackgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              disabledForegroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: isSelected ? 4 : 0,
                            ),
                            icon: Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: ClubBlackoutTheme.contrastOn(accent),
                            ),
                            label: Text(
                              'CONFIRM',
                              style: TextStyle(
                                color: ClubBlackoutTheme.contrastOn(accent),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
