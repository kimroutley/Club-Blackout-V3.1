import 'package:flutter/material.dart';

import '../../models/role.dart';
import '../styles.dart';
import 'player_icon.dart';
import 'neon_glass_card.dart';

enum RoleTileVariant { compact, card }

class RoleTileWidget extends StatelessWidget {
  final Role role;
  final RoleTileVariant variant;
  final VoidCallback? onTap;

  const RoleTileWidget({
    super.key,
    required this.role,
    this.variant = RoleTileVariant.compact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final title = Text(
      role.name.toUpperCase(),
      textAlign: variant == RoleTileVariant.card
          ? TextAlign.center
          : TextAlign.start,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: ClubBlackoutTheme.headingStyle.copyWith(
        fontSize: variant == RoleTileVariant.card ? 15 : 13,
        color: role.color,
      ),
    );

    final subtitle = Text(
      role.alliance.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ClubBlackoutTheme.headingStyle.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        fontSize: 9,
        letterSpacing: 0.5,
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: variant == RoleTileVariant.card
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayerIcon(
                  assetPath: role.assetPath,
                  glowColor: role.color,
                  size: 48,
                ),
                const SizedBox(height: 12),
                title,
                const SizedBox(height: 8),
                subtitle,
              ],
            )
          : Row(
              children: [
                PlayerIcon(
                  assetPath: role.assetPath,
                  glowColor: role.color,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title,
                      subtitle,
                    ],
                  ),
                ),
              ],
            ),
    );

    return Semantics(
      button: onTap != null,
      label: '${role.name}, ${role.alliance}',
      child: NeonGlassCard(
        glowColor: role.color,
        padding: EdgeInsets.zero,
        borderRadius: 20,
        child: InkWell(
          onTap: onTap,
          splashFactory: InkSparkle.splashFactory,
          splashColor: role.color.withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  role.color.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
