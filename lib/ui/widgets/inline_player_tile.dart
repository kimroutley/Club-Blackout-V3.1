import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../styles.dart';
import 'player_icon.dart';

class InlinePlayerTile extends StatelessWidget {
  final Player player;

  const InlinePlayerTile({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roleColor = player.role.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            roleColor.withValues(alpha: 0.22),
            roleColor.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerIcon(
            assetPath: player.role.assetPath,
            glowColor: roleColor,
            size: 18,
            isAlive: player.isAlive,
            isEnabled: player.isEnabled,
            glowIntensity: 0.55,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              player.name,
              overflow: TextOverflow.ellipsis,
              style: ClubBlackoutTheme.glowTextStyle(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ).copyWith(
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
