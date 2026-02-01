import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/player.dart';
import '../../models/role.dart';
import '../../models/script_step.dart';
import '../styles.dart';
import 'player_icon.dart';

class InteractiveScriptCard extends StatelessWidget {
  final ScriptStep step;
  final bool isActive;
  final Role? role;

  // Back-compat inputs still used by GameScreen.
  final Color? stepColor;
  final String? playerName;
  final Player? player;
  final GameEngine? gameEngine;

  final String hostLabel;
  final bool dense;
  final bool bulletin;
  final Widget? roleContext;
  final Widget? footer;

  const InteractiveScriptCard({
    super.key,
    required this.step,
    required this.isActive,
    this.role,
    this.stepColor,
    this.playerName,
    this.player,
    this.gameEngine,
    this.hostLabel = 'Host',
    this.dense = false,
    this.bulletin = false,
    this.roleContext,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent =
        isActive ? (stepColor ?? role?.color ?? cs.primary) : cs.outline;
    final tt = Theme.of(context).textTheme;

    Widget buildScriptSection({
      required String label,
      required IconData icon,
      required Color color,
      required Widget child,
      required bool showHeader,
    }) {
      final pad = bulletin
          ? const EdgeInsets.all(10)
          : (dense ? const EdgeInsets.all(12) : const EdgeInsets.all(14));

      return Container(
        width: double.infinity,
        padding: pad,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: isActive ? 0.14 : 0.10),
              color.withValues(alpha: isActive ? 0.06 : 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withValues(alpha: isActive ? 0.35 : 0.20),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: color.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: (tt.labelMedium ?? const TextStyle()).copyWith(
                        color: color.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        shadows: const [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      );
    }

    final byline = (playerName ?? player?.name)?.trim();

    final contentPadding = bulletin
        ? ClubBlackoutTheme.scriptCardPaddingBulletin
        : (dense
            ? ClubBlackoutTheme.scriptCardPaddingDense
            : ClubBlackoutTheme.scriptCardPadding);

    final readAloudText = step.readAloudText.trim();
    final rawInstructionText = step.instructionText.trim();

    var instructionText = rawInstructionText;
    if (hostLabel.trim().isNotEmpty &&
        hostLabel.trim().toLowerCase() != 'host') {
      instructionText = instructionText
          .replaceFirst(
            RegExp(r'^host\s*:', caseSensitive: false),
            '${hostLabel.trim()}:',
          )
          .replaceFirst(
            RegExp(r'^host(\s+only\b)', caseSensitive: false),
            '${hostLabel.trim()}${r'$1'}',
          );
    }

    final readAloudHasPrefix =
        RegExp(r'^read\s*aloud\s*:', caseSensitive: false)
            .hasMatch(readAloudText);
    final instructionHasPrefix = RegExp(
      '^(${RegExp.escape(hostLabel.trim())}|host)\\s*:',
      caseSensitive: false,
    ).hasMatch(instructionText);

    final headerStyle = (dense ? tt.titleMedium : tt.titleLarge)?.copyWith(
      fontWeight: FontWeight.w700,
      color: isActive ? accent : cs.onSurface,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.7),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        if (isActive)
          Shadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
      ],
    );

    final bodyStyle = tt.bodyMedium?.copyWith(
      color: cs.onSurface.withValues(alpha: isActive ? 0.90 : 0.75),
      height: 1.35,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(bulletin ? 16 : 20),
        gradient: isActive
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.15),
                  accent.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : cs.surfaceContainer,
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.2),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isActive && role != null) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: PlayerIcon(
                      assetPath: role!.assetPath,
                      glowColor: accent,
                      glowIntensity: 0.4,
                      size: bulletin ? 30 : 36,
                    ),
                  ),
                  const SizedBox(width: 14),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accent.withValues(alpha: 0.2)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isActive ? Icons.play_circle_filled : Icons.check_circle,
                      color: isActive
                          ? accent
                          : cs.onSurfaceVariant.withValues(alpha: 0.5),
                      size: bulletin ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    byline == null || byline.isEmpty
                        ? step.title
                        : '${step.title} · $byline',
                    style: headerStyle,
                  ),
                ),
              ],
            ),
            if (roleContext != null) ...[
              ClubBlackoutTheme.gap12,
              roleContext!,
            ],
            if (readAloudText.isNotEmpty) ...[
              ClubBlackoutTheme.gap12,
              buildScriptSection(
                label: 'Read aloud',
                icon: Icons.record_voice_over_rounded,
                color: ClubBlackoutTheme.neonBlue,
                showHeader: !readAloudHasPrefix,
                child: Text(
                  readAloudText,
                  style: bodyStyle?.copyWith(
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (instructionText.isNotEmpty) ...[
              ClubBlackoutTheme.gap12,
              buildScriptSection(
                label: hostLabel.trim().isEmpty ? 'Host' : hostLabel.trim(),
                icon: Icons.support_agent_rounded,
                color: isActive ? accent : cs.onSurfaceVariant,
                showHeader: !instructionHasPrefix,
                child: Text(
                  instructionText,
                  style: bodyStyle?.copyWith(
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (footer != null) ...[
              ClubBlackoutTheme.gap12,
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
