import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/player.dart';
import '../styles.dart';
import 'auto_scroll_text.dart';
import 'player_icon.dart';

/// Configuration for how a player tile should be displayed and behave
class PlayerTileConfig {
  /// Visual variant of the tile
  final PlayerTileVariant variant;

  /// Whether the tile is in a selected state
  final bool isSelected;

  /// Whether the tile is interactive (tappable)
  final bool isInteractive;

  /// Show status chips (effects, marks, etc)
  final bool showStatusChips;

  /// Render status chips as a banner overlay instead of inline
  final bool statusChipsAsBanner;

  /// Show vote count badge
  final int? voteCount;

  /// Custom subtitle text (overrides default role/alliance)
  final String? subtitleOverride;

  /// Custom stats text (for night phase, scoring, etc)
  final String? statsText;

  /// Leading widget (replaces role icon if provided)
  final Widget? leading;

  /// Trailing widget (replaces vote badge if provided)
  final Widget? trailing;

  /// Custom tile background color
  final Color? tileColor;

  /// Override the enabled state
  final bool? enabledOverride;

  /// Custom content padding
  final EdgeInsets? contentPadding;

  /// Wrap tile in a card/container
  final bool wrapInCard;

  /// Show role icon
  final bool showRoleIcon;

  /// Show player name
  final bool showPlayerName;

  /// Show role/alliance subtitle
  final bool showSubtitle;

  /// Callbacks
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onConfirm;

  const PlayerTileConfig({
    this.variant = PlayerTileVariant.standard,
    this.isSelected = false,
    this.isInteractive = true,
    this.showStatusChips = true,
    this.statusChipsAsBanner = false,
    this.voteCount,
    this.subtitleOverride,
    this.statsText,
    this.leading,
    this.trailing,
    this.tileColor,
    this.enabledOverride,
    this.contentPadding,
    this.wrapInCard = true,
    this.showRoleIcon = true,
    this.showPlayerName = true,
    this.showSubtitle = true,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onConfirm,
  });

  /// Compact variant for lists
  factory PlayerTileConfig.compact({
    bool isSelected = false,
    VoidCallback? onTap,
    bool showStatusChips = true,
    int? voteCount,
  }) {
    return PlayerTileConfig(
      variant: PlayerTileVariant.compact,
      isSelected: isSelected,
      onTap: onTap,
      showStatusChips: showStatusChips,
      voteCount: voteCount,
    );
  }

  /// Standard variant (default)
  factory PlayerTileConfig.standard({
    bool isSelected = false,
    VoidCallback? onTap,
    bool showStatusChips = true,
    int? voteCount,
  }) {
    return PlayerTileConfig(
      variant: PlayerTileVariant.standard,
      isSelected: isSelected,
      onTap: onTap,
      showStatusChips: showStatusChips,
      voteCount: voteCount,
    );
  }

  /// Night phase variant with enhanced visuals
  factory PlayerTileConfig.nightPhase({
    required bool isSelected,
    VoidCallback? onTap,
    VoidCallback? onConfirm,
    String? statsText,
  }) {
    return PlayerTileConfig(
      variant: PlayerTileVariant.nightPhase,
      isSelected: isSelected,
      onTap: onTap,
      onConfirm: onConfirm,
      statsText: statsText,
      showStatusChips: false,
    );
  }

  /// Selection mode variant (for picking targets, votes, etc)
  factory PlayerTileConfig.selection({
    required bool isSelected,
    required VoidCallback onTap,
    bool showStatusChips = true,
  }) {
    return PlayerTileConfig(
      variant: PlayerTileVariant.selection,
      isSelected: isSelected,
      onTap: onTap,
      showStatusChips: showStatusChips,
      statusChipsAsBanner: true,
    );
  }

  /// Dashboard variant for host overview
  factory PlayerTileConfig.dashboard({
    VoidCallback? onTap,
    bool showStatusChips = true,
  }) {
    return PlayerTileConfig(
      variant: PlayerTileVariant.dashboard,
      onTap: onTap,
      showStatusChips: showStatusChips,
      statusChipsAsBanner: false,
    );
  }

  /// Banner variant for live updates
  factory PlayerTileConfig.banner({
    bool showStatusChips = true,
    VoidCallback? onTap,
  }) {
    return PlayerTileConfig(
      variant: PlayerTileVariant.banner,
      showStatusChips: showStatusChips,
      statusChipsAsBanner: true,
      onTap: onTap,
      wrapInCard: false,
    );
  }

  /// Minimal variant (just icon and name)
  factory PlayerTileConfig.minimal({
    VoidCallback? onTap,
  }) {
    return PlayerTileConfig(
      variant: PlayerTileVariant.minimal,
      onTap: onTap,
      showStatusChips: false,
      showSubtitle: false,
      wrapInCard: false,
    );
  }
}

/// Visual variants for player tiles
enum PlayerTileVariant {
  /// Compact tile for dense lists
  compact,

  /// Standard tile (default)
  standard,

  /// Enhanced tile for night phase selection
  nightPhase,

  /// Tile optimized for selection/voting
  selection,

  /// Tile for host dashboard display
  dashboard,

  /// Banner style for notifications/live updates
  banner,

  /// Minimal tile (icon + name only)
  minimal,
}

/// Unified player/role tile component that can be used throughout the game
/// Supports multiple variants, status chips, selection states, and callbacks
class UnifiedPlayerTile extends StatelessWidget {
  final Player player;
  final GameEngine? gameEngine;
  final PlayerTileConfig config;

  const UnifiedPlayerTile({
    super.key,
    required this.player,
    this.gameEngine,
    this.config = const PlayerTileConfig(),
  });

  /// Quick constructor for compact variant
  const UnifiedPlayerTile.compact({
    super.key,
    required this.player,
    this.gameEngine,
    bool isSelected = false,
    VoidCallback? onTap,
    int? voteCount,
  }) : config = const PlayerTileConfig(variant: PlayerTileVariant.compact);

  /// Quick constructor for selection variant
  const UnifiedPlayerTile.selection({
    super.key,
    required this.player,
    this.gameEngine,
    required bool isSelected,
    required VoidCallback onTap,
  }) : config = const PlayerTileConfig(variant: PlayerTileVariant.selection);

  @override
  Widget build(BuildContext context) {
    switch (config.variant) {
      case PlayerTileVariant.nightPhase:
        return _buildNightPhaseVariant(context);
      case PlayerTileVariant.banner:
        return _buildBannerVariant(context);
      case PlayerTileVariant.minimal:
        return _buildMinimalVariant(context);
      default:
        return _buildStandardVariant(context);
    }
  }

  /// Build standard/compact/selection/dashboard variants (all similar structure)
  Widget _buildStandardVariant(BuildContext context) {
    final roleColor = player.role.color;
    final subtitleText = config.subtitleOverride ??
        config.statsText ??
        '${player.role.name} · ${player.alliance}';
    final isEnabled = config.enabledOverride ?? player.isEnabled;
    final isCompact = config.variant == PlayerTileVariant.compact;

    final effectChips = config.showStatusChips
        ? _collectEffectChips(player: player, engine: gameEngine)
        : const <_EffectChip>[];

    final showBanner = config.statusChipsAsBanner && effectChips.isNotEmpty;

    final badge = config.voteCount == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: roleColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Text(
              config.voteCount.toString(),
              style: ClubBlackoutTheme.glowTextStyle(
                color: roleColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          );

    final resolvedTrailing = config.trailing ?? badge;

    Widget content = InkWell(
      onTap: config.isInteractive ? config.onTap : null,
      onLongPress: config.isInteractive ? config.onLongPress : null,
      onDoubleTap: config.isInteractive ? config.onDoubleTap : null,
      borderRadius: ClubBlackoutTheme.borderRadiusSmAll,
      child: Padding(
        padding: config.contentPadding ??
            EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 8 : 12,
            ),
        child: Row(
          children: [
            // Leading (role icon by default)
            if (config.showRoleIcon)
              config.leading ??
                  PlayerIcon(
                    assetPath: player.role.assetPath,
                    glowColor: roleColor,
                    size: isCompact ? 38 : 48,
                    isAlive: player.isAlive,
                    isEnabled: isEnabled,
                    glowIntensity: config.isSelected ? 1.2 : 0.8,
                  ),
            const SizedBox(width: 16),
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (config.showPlayerName)
                    AutoScrollText(
                      player.name,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: isCompact ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isEnabled
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                        shadows: isEnabled && config.isSelected
                            ? ClubBlackoutTheme.textGlow(roleColor)
                            : null,
                      ),
                    ),
                  if (config.showPlayerName && config.showSubtitle)
                    const SizedBox(height: 2),
                  if (config.showSubtitle)
                    AutoScrollText(
                      subtitleText,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isEnabled
                            ? roleColor.withValues(alpha: 0.7)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                      ),
                    ),
                  if (!showBanner && effectChips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    AutoScrollHStack(
                      autoScroll: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < effectChips.length; i++) ...[
                            _buildChip(context, effectChips[i]),
                            if (i != effectChips.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (showBanner) const SizedBox(height: 28),
                ],
              ),
            ),
            if (resolvedTrailing != null) ...[
              const SizedBox(width: 8),
              resolvedTrailing,
            ],
          ],
        ),
      ),
    );

    if (showBanner) {
      content = ClipRRect(
        borderRadius: ClubBlackoutTheme.borderRadiusSmAll,
        child: Stack(
          children: [
            content,
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < effectChips.length; i++) ...[
                      _buildChip(context, effectChips[i]),
                      if (i != effectChips.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!config.wrapInCard) return content;

    final baseColor = config.tileColor ?? roleColor;

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      child: Container(
        decoration: ClubBlackoutTheme.neonFrame(
          color: config.isSelected
              ? baseColor
              : baseColor.withValues(alpha: 0.5),
          borderRadius: 16,
          opacity: config.isSelected ? 0.3 : (isEnabled ? 0.6 : 0.3),
          borderWidth: config.isSelected ? 1.5 : 0.5,
          showGlow: config.isSelected,
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }

  /// Build night phase variant with enhanced animations and glow
  Widget _buildNightPhaseVariant(BuildContext context) {
    final subtitle = config.statsText ?? player.role.name;
    final accent = player.role.color;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: config.isSelected
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
            color: config.isSelected
                ? accent
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: config.isSelected ? 2.5 : 1.5,
          ),
          boxShadow: config.isSelected
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
            onTap: config.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: config.isSelected
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
                      size: 56,
                      isAlive: player.isAlive,
                      isEnabled: player.isEnabled,
                      glowIntensity: config.isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: cs.onSurface,
                            shadows: config.isSelected
                                ? ClubBlackoutTheme.textGlow(accent)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (config.isSelected && config.onConfirm != null)
                    IconButton(
                      icon: Icon(Icons.check_circle_rounded, color: accent),
                      iconSize: 32,
                      onPressed: config.onConfirm,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build banner variant for live updates
  Widget _buildBannerVariant(BuildContext context) {
    final roleColor = player.role.color;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleColor.withValues(alpha: 0.2),
            roleColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: config.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PlayerIcon(
                assetPath: player.role.assetPath,
                glowColor: roleColor,
                size: 40,
                isAlive: player.isAlive,
                isEnabled: player.isEnabled,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    if (config.showStatusChips) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _collectEffectChips(
                          player: player,
                          engine: gameEngine,
                        ).map((chip) => _buildChip(context, chip)).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build minimal variant (icon + name only)
  Widget _buildMinimalVariant(BuildContext context) {
    final roleColor = player.role.color;

    return InkWell(
      onTap: config.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerIcon(
              assetPath: player.role.assetPath,
              glowColor: roleColor,
              size: 32,
              isAlive: player.isAlive,
              isEnabled: player.isEnabled,
            ),
            const SizedBox(width: 8),
            Text(
              player.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Status chip collection logic (extracted from original PlayerTile)
  static List<_EffectChip> _collectEffectChips({
    required Player player,
    required GameEngine? engine,
  }) {
    final chips = <_EffectChip>[];
    final seen = <String>{};

    Color? roleColor(String roleId) {
      if (engine == null) return null;
      try {
        return engine.players
            .where((p) => p.role.id == roleId)
            .first
            .role
            .color;
      } catch (_) {
        return null;
      }
    }

    Color? byRoleOrTheme(String roleId, Color fallback) {
      return roleColor(roleId) ?? fallback;
    }

    void add(String label, {Color? color}) {
      final key = label.trim();
      if (key.isEmpty) return;
      if (seen.add(key)) {
        chips.add(_EffectChip(label: key, color: color));
      }
    }

    // Player-local status flags
    if (!player.isAlive) add('Dead');
    if (!player.isEnabled) add('Disabled');
    if (player.lives > 1) {
      add('${player.lives} Lives',
          color: player.role.id == 'seasoned_drinker'
              ? ClubBlackoutTheme.neonMint
              : player.role.color);
    }
    if (player.joinsNextNight) add('Joins Next Night');
    if (player.soberSentHome) {
      add('Sent Home',
          color: byRoleOrTheme('sober', ClubBlackoutTheme.neonBlue));
    }

    // Role-specific status
    if (player.idCheckedByBouncer) {
      add('Checked ID',
          color: byRoleOrTheme('bouncer', ClubBlackoutTheme.neonBlue));
    }

    if (player.role.id == 'clinger') {
      if (player.clingerFreedAsAttackDog) {
        add('Unleashed', color: ClubBlackoutTheme.neonRed);
      } else if (player.clingerPartnerId != null) {
        final obsessionLabel = (engine == null)
            ? 'Obsessed'
            : (() {
                try {
                  final partner = engine.players
                      .where((p) => p.id == player.clingerPartnerId)
                      .firstOrNull;
                  return partner == null
                      ? 'Obsessed'
                      : 'Obsessed: ${partner.name}';
                } catch (_) {
                  return 'Obsessed';
                }
              })();
        add(obsessionLabel, color: ClubBlackoutTheme.neonPink);
      }
      if (player.clingerAttackDogUsed) {
        add('Attack Used', color: ClubBlackoutTheme.neonOrange);
      }
    }

    if (player.role.id == 'minor') {
      if (player.minorHasBeenIDd) {
        add('Vulnerable to Dealers', color: ClubBlackoutTheme.neonRed);
      } else {
        add('Immune', color: ClubBlackoutTheme.neonMint);
      }
    }

    // Time-sensitive status
    if (engine != null) {
      final currentDay = engine.dayCount;
      if (player.alibiDay != null && player.alibiDay == currentDay) {
        add('Alibi: Vote Immunity (Today)',
            color: byRoleOrTheme('silver_fox', ClubBlackoutTheme.neonBlue));
      }
      if (player.silencedDay != null && player.silencedDay == currentDay) {
        add('Silenced',
            color: byRoleOrTheme('roofi', ClubBlackoutTheme.neonGreen));
      }
      if (player.blockedKillNight != null &&
          player.blockedKillNight == currentDay) {
        add('No Kill',
            color: byRoleOrTheme('roofi', ClubBlackoutTheme.neonGreen));
      }

      // Check if this player is a taboo name for any Lightweight
      final isTabooName = engine.players
          .where((p) => p.isAlive && p.isEnabled && p.role.id == 'lightweight')
          .any((lw) => lw.tabooNames.contains(player.name));
      if (isTabooName) {
        add('Taboo',
            color: byRoleOrTheme('lightweight', ClubBlackoutTheme.neonOrange));
      }
    }

    return chips;
  }

  static Widget _buildChip(BuildContext context, _EffectChip chip) {
    final c = chip.color ?? ClubBlackoutTheme.neonBlue;
    final bg = c.withValues(alpha: 0.18);
    final border = c.withValues(alpha: 0.45);

    // Determine text color for better contrast
    final textColor = _getContrastColor(c);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        chip.label,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  static Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance < 0.4 ? Colors.white : Colors.black;
  }
}

class _EffectChip {
  final String label;
  final Color? color;

  const _EffectChip({required this.label, this.color});
}
