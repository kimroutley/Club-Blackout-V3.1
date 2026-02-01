import 'dart:ui';

import 'package:flutter/material.dart';

import '../../logic/game_state.dart';
import '../styles.dart';

/// Centralized phase-specific theming system for visual consistency
class PhaseTheme {
  static const Duration transitionDuration = Duration(milliseconds: 400);
  static const Curve transitionCurve = Curves.easeInOutCubic;

  /// Get theme configuration for the current phase
  static PhaseThemeData getThemeForPhase(GamePhase phase) {
    switch (phase) {
      case GamePhase.night:
        return const PhaseThemeData.night();
      case GamePhase.day:
        return const PhaseThemeData.day();
      case GamePhase.setup:
        return const PhaseThemeData.setup();
      case GamePhase.lobby:
        return const PhaseThemeData.lobby();
      case GamePhase.resolution:
        return const PhaseThemeData.day();
      case GamePhase.endGame:
        return const PhaseThemeData.lobby();
    }
  }

  /// Enhanced AppBar styling that adapts to current phase
  static AppBar buildPhaseAppBar({
    required BuildContext context,
    required GamePhase phase,
    required String title,
    Widget? leading,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    bool showPhaseIndicator = false,
    int? dayNumber,
  }) {
    final themeData = getThemeForPhase(phase);

    final finalActions = [...?actions];

    // Add phase indicator if requested
    if (showPhaseIndicator) {
      finalActions.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Chip(
            label: Text(
              '${phase == GamePhase.night ? 'NIGHT' : 'DAY'} ${dayNumber ?? '?'}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: 12,
              ),
            ),
            avatar: Icon(
              phase == GamePhase.night
                  ? Icons.nightlight_round
                  : Icons.wb_sunny_rounded,
              size: 16,
              color: themeData.accentColor,
            ),
            backgroundColor: themeData.accentColor.withValues(alpha: 0.15),
            side: BorderSide(
              color: themeData.accentColor.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    if (themeData.useTransparentAppBar) {
      // Neon style with backdrop filter for day phase
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        foregroundColor: Colors.white,
        leading: leading,
        title: Text(title),
        centerTitle: true,
        actions: finalActions,
        bottom: bottom,
      );
    } else {
      // Material 3 style for night phase
      return AppBar(
        backgroundColor: themeData.surfaceColor,
        surfaceTintColor: themeData.surfaceTintColor,
        elevation: 0,
        foregroundColor: themeData.onSurfaceColor,
        leading: leading,
        title: Text(title),
        centerTitle: true,
        actions: finalActions,
        bottom: bottom,
      );
    }
  }

  /// Enhanced container styling that adapts to current phase
  static BoxDecoration buildPhaseContainer({
    required GamePhase phase,
    Color? customColor,
    double borderRadius = 16,
    bool isSelected = false,
    bool showGlow = false,
  }) {
    final themeData = getThemeForPhase(phase);
    final color = customColor ?? themeData.accentColor;

    if (themeData.useNeonEffects) {
      // Neon glass effect for day phase
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isSelected ? 0.25 : 0.15),
            color.withValues(alpha: isSelected ? 0.15 : 0.08),
            Colors.black.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: isSelected ? 0.8 : 0.5),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: showGlow || isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: showGlow ? 20 : 12,
                  spreadRadius: showGlow ? 4 : 2,
                ),
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      );
    } else {
      // Material 3 effect for night phase
      final cs = ThemeData().colorScheme; // Could be passed from context
      return BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isSelected
            ? Border.all(
                color: color.withValues(alpha: 0.6),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
  }

  /// Enhanced button styling that adapts to current phase
  static ButtonStyle buildPhaseButtonStyle({
    required GamePhase phase,
    Color? customColor,
    bool isPrimary = false,
  }) {
    final themeData = getThemeForPhase(phase);
    final color = customColor ?? themeData.accentColor;

    if (themeData.useNeonEffects) {
      // Neon button style for day phase
      return FilledButton.styleFrom(
        backgroundColor: isPrimary
            ? color.withValues(alpha: 0.9)
            : color.withValues(alpha: 0.15),
        foregroundColor: isPrimary ? Colors.black : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: color.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        elevation: isPrimary ? 8 : 4,
        shadowColor: color.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      );
    } else {
      // Material 3 button style for night phase
      return FilledButton.styleFrom(
        backgroundColor: isPrimary ? color : null,
        foregroundColor: isPrimary ? Colors.white : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      );
    }
  }
}

/// Configuration data for phase-specific theming
class PhaseThemeData {
  final Color accentColor;
  final Color surfaceColor;
  final Color? surfaceTintColor;
  final Color onSurfaceColor;
  final bool useNeonEffects;
  final bool useTransparentAppBar;
  final String backgroundAsset;

  const PhaseThemeData({
    required this.accentColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.useNeonEffects,
    required this.useTransparentAppBar,
    required this.backgroundAsset,
    this.surfaceTintColor,
  });

  const PhaseThemeData.night()
      : accentColor = ClubBlackoutTheme.neonPurple,
        surfaceColor = Colors.black,
        surfaceTintColor = ClubBlackoutTheme.neonPurple,
        onSurfaceColor = Colors.white,
        useNeonEffects = false,
        useTransparentAppBar = false,
        backgroundAsset = '';

  const PhaseThemeData.day()
      : accentColor = ClubBlackoutTheme.neonOrange,
        surfaceColor = Colors.transparent,
        surfaceTintColor = null,
        onSurfaceColor = Colors.white,
        useNeonEffects = true,
        useTransparentAppBar = true,
        backgroundAsset = 'Backgrounds/Club Blackout V2 Game Background.png';

  const PhaseThemeData.setup()
      : accentColor = ClubBlackoutTheme.neonGreen,
        surfaceColor = Colors.transparent,
        surfaceTintColor = null,
        onSurfaceColor = Colors.white,
        useNeonEffects = true,
        useTransparentAppBar = true,
        backgroundAsset = 'Backgrounds/Club Blackout V2 Home Menu.png';

  const PhaseThemeData.lobby()
      : accentColor = ClubBlackoutTheme.neonBlue,
        surfaceColor = Colors.transparent,
        surfaceTintColor = null,
        onSurfaceColor = Colors.white,
        useNeonEffects = true,
        useTransparentAppBar = true,
        backgroundAsset = 'Backgrounds/Club Blackout V2 Home Menu.png';
}

/// Extension to make phase theming easier to use
extension GamePhaseThemeExtension on GamePhase {
  PhaseThemeData get theme => PhaseTheme.getThemeForPhase(this);

  Color get primaryColor {
    switch (this) {
      case GamePhase.night:
        return ClubBlackoutTheme.neonPurple;
      case GamePhase.day:
        return ClubBlackoutTheme.neonOrange;
      case GamePhase.setup:
        return ClubBlackoutTheme.neonGreen;
      case GamePhase.lobby:
        return ClubBlackoutTheme.neonBlue;
      default:
        return ClubBlackoutTheme.neonBlue;
    }
  }
}
