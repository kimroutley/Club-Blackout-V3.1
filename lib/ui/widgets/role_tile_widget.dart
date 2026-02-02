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

    final title = Text(
      role.name.toUpperCase(),
      textAlign: variant == RoleTileVariant.card
          ? TextAlign.center
          : TextAlign.start,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: ClubBlackoutTheme.headingStyle.copyWith(
        fontSize: variant == RoleTileVariant.card ? 16 : 14,
        color: role.color,
      ),
    );

    final subtitle = Text(
      role.alliance.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ClubBlackoutTheme.headingStyle.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        fontSize: 10,
        letterSpacing: 0.5,
      ),
    );

    final content = variant == RoleTileVariant.card
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerIcon(
                assetPath: role.assetPath,
                glowColor: role.color,
                size: 48,
              ),
              const SizedBox(height: 12),
              title,
              const SizedBox(height: 6),
              subtitle,
            ],
          )
        : Row(
            children: [
              PlayerIcon(
                assetPath: role.assetPath,
                glowColor: role.color,
                size: 40, // Standardized icon size (was 32)
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    const SizedBox(height: 2),
                    subtitle,
                  ],
                ),
              ),
            ],
          );

    return Semantics(
      button: onTap != null,
      label: '${role.name}, ${role.alliance}',
      child: NeonGlassCard(
        glowColor: role.color,
        opacity: 0.15,
        borderRadius: 16, // Standardized radius
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: content,
          ),
        ),
      ),
    );
  }
}
