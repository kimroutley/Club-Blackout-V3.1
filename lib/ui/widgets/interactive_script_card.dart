import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/player.dart';
import '../../models/role.dart';
import '../../models/script_step.dart';
import '../styles.dart';
import 'player_icon.dart';
import 'unified_player_tile.dart';
import 'neon_glass_card.dart';

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
    // Prefer the provided player object; fall back to a lookup by name so tiles render
    // even when only the name is passed down.
    Player? tilePlayer = player;
    if (tilePlayer == null && gameEngine != null && (playerName ?? '').isNotEmpty) {
      try {
        tilePlayer = gameEngine!.players.firstWhere(
          (p) => p.name.trim().toLowerCase() ==
              (playerName ?? '').trim().toLowerCase(),
        );
      } catch (_) {
        tilePlayer = null;
      }
    }
    final showPlayerTile = tilePlayer != null;
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
        decoration: BoxDecoration(
          color: color.withValues(alpha: isActive ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(12),
          // No border, just a subtle left indicator
          border: Border(
            left: BorderSide(
              color: color.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
        ),
        padding: pad,
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: ClubBlackoutTheme.headingStyle.copyWith(
                        color: color.withValues(alpha: 0.95),
                        fontSize: 12,
                        letterSpacing: 1.2,
                        shadows: isActive
                            ? ClubBlackoutTheme.textGlow(color, intensity: 0.5)
                            : null,
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

    final byline = (playerName ?? tilePlayer?.name)?.trim();

    final contentPadding = bulletin
        ? ClubBlackoutTheme.scriptCardPaddingBulletin
        : (dense
            ? ClubBlackoutTheme.scriptCardPaddingDense
            : ClubBlackoutTheme.scriptCardPadding);

    var readAloudText = step.readAloudText.trim();
    var instructionText = step.instructionText.trim();

    // Strip "Read aloud:" prefix to prevent double-labeling
    final readAloudPrefix = RegExp(r'^read\s*aloud\s*:', caseSensitive: false);
    if (readAloudPrefix.hasMatch(readAloudText)) {
      readAloudText = readAloudText.replaceFirst(readAloudPrefix, '').trim();
    }

    // Strip "Host:" or "Host Only:" prefixes
    final hostPrefix = RegExp(
      '^(${RegExp.escape(hostLabel.trim())}|host)(\\s+only)?\\s*:',
      caseSensitive: false,
    );
    if (hostPrefix.hasMatch(instructionText)) {
      instructionText = instructionText.replaceFirst(hostPrefix, '').trim();
    }

    final headerStyle = (dense ? tt.titleMedium : tt.titleLarge)?.copyWith(
      fontWeight: FontWeight.w700,
      color: isActive ? accent : cs.onSurface,
    );

    final bodyStyle = tt.bodyLarge?.copyWith(
      color: cs.onSurface.withValues(alpha: isActive ? 0.90 : 0.75),
      height: 1.35,
    );

    return NeonGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
      decoration: ClubBlackoutTheme.neonFrame(
        color: isActive ? accent : cs.surfaceContainer,
        opacity: isActive ? 0.15 : 0.0, // surface container handles bg if inactive
        borderRadius: bulletin ? 16 : 20,
        borderWidth: isActive ? 2 : 1,
        showGlow: isActive,
      ),
      child: Padding(
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
      glowColor: isActive ? accent : cs.surfaceContainer,
      opacity: isActive ? 0.95 : 0.5,
      borderRadius: bulletin ? 16 : 20,
      showBorder: false, // Explicitly no border
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
<<<<<<< Updated upstream
<<<<<<< Updated upstream
            children: [ isInteractive: false,
=======
=======
>>>>>>> Stashed changes
            children: [
                if (showPlayerTile) ...[
                  Flexible(
                    flex: 0,
                    child: UnifiedPlayerTile(
                      player: tilePlayer!,
                      gameEngine: gameEngine,
                      config: const PlayerTileConfig(
                        variant: PlayerTileVariant.minimal,
                        isInteractive: false,
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
                        showStatusChips: false,
                        showSubtitle: false,
                        wrapInCard: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ] else if (isActive && role != null) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.2),
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
                  if (!showPlayerTile)
                    Expanded(
                      child: Text(
                        (byline == null || byline.isEmpty)
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
                  showHeader: true,
                  child: Text(
                    readAloudText,
                    style: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              if (instructionText.isNotEmpty) ...[
                ClubBlackoutTheme.gap12,
                buildScriptSection(
                  label: hostLabel.trim().isEmpty ? 'Host' : hostLabel.trim(),
                  icon: Icons.support_agent_rounded,
                  color: isActive ? accent : cs.onSurfaceVariant,
                  showHeader: true,
                  child: Text(
                    instructionText,
                    style: bodyStyle,
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
