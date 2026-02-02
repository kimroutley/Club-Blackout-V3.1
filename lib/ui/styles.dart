import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClubBlackoutTheme {
  static const neonBlue = Color(0xFF00D1FF);
  static const electricBlue = Color(0xFF2E5BFF);

  static final String neonGlowFontFamily = GoogleFonts.audiowide().fontFamily!;
  static final TextStyle neonGlowFont = GoogleFonts.audiowide();

  static final TextStyle neonGlowTitle = GoogleFonts.audiowide(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  static const neonRed = Color(0xFFFF2E63);
  static const crimsonRed = neonRed;

  static const neonGreen = Color(0xFF00FF9A);
  static const neonMint = Color(0xFF98FF98);
  static const neonPurple = Color(0xFFB400FF);
  static const neonPink = Color(0xFFFF4FD8);
  static const neonOrange = Color(0xFFFFA500);
  static const neonGold = Color(0xFFFFD700);
  static const neonSilver = Color(0xFFC0C0C0);

  // Role / feature accents
  static const secondWindPink = Color(0xFFDE3163);

  // UI accents / effects
  static const rumourLavender = Color(0xFFE6E6FA);
  static const hologramRedChannel = Color(0xFFFF0000);
  static const hologramCyanChannel = Color(0xFF00FFFF);

  // Contrast primitives
  static const pureWhite = Color(0xFFFFFFFF);
  static const pureBlack = Color(0xFF000000);

  // Design Language Constants
  static const double defaultGlowSpread = 2.0;
  static const double defaultGlowBlur = 18.0;
  static const double thinBorderWidth = 1.0;
  static const double thickBorderWidth = 2.5;

  // Material 3 State Layer Opacities
  // Reference: https://m3.material.io/foundations/interaction/states/state-layers
  static const double stateLayerOpacityHover = 0.08;
  static const double stateLayerOpacityFocus = 0.12;
  static const double stateLayerOpacityPressed = 0.12;
  static const double stateLayerOpacityDragged = 0.16;

  // Material 3 Elevation levels (for reference)
  static const double elevationLevel0 = 0.0; // Surface
  static const double elevationLevel1 = 1.0; // Cards at rest
  static const double elevationLevel2 = 3.0; // FAB at rest
  static const double elevationLevel3 = 6.0; // Modal bottom sheets
  static const double elevationLevel4 = 8.0; // Navigation drawer
  static const double elevationLevel5 = 12.0; // Dialogs

  // Material 3 Motion/Animation Durations
  // Reference: https://m3.material.io/styles/motion/easing-and-duration
  static const Duration motionDurationShort1 = Duration(milliseconds: 50);
  static const Duration motionDurationShort2 = Duration(milliseconds: 100);
  static const Duration motionDurationShort3 = Duration(milliseconds: 150);
  static const Duration motionDurationShort4 = Duration(milliseconds: 200);
  static const Duration motionDurationMedium1 = Duration(milliseconds: 250);
  static const Duration motionDurationMedium2 = Duration(milliseconds: 300);
  static const Duration motionDurationMedium3 = Duration(milliseconds: 350);
  static const Duration motionDurationMedium4 = Duration(milliseconds: 400);
  static const Duration motionDurationLong1 = Duration(milliseconds: 450);
  static const Duration motionDurationLong2 = Duration(milliseconds: 500);
  static const Duration motionDurationLong3 = Duration(milliseconds: 550);
  static const Duration motionDurationLong4 = Duration(milliseconds: 600);
  static const Duration motionDurationExtraLong1 = Duration(milliseconds: 700);
  static const Duration motionDurationExtraLong2 = Duration(milliseconds: 800);
  static const Duration motionDurationExtraLong3 = Duration(milliseconds: 900);
  static const Duration motionDurationExtraLong4 = Duration(milliseconds: 1000);

  // Material 3 Easing Curves
  static const Curve motionEasingStandard = Curves.easeInOutCubicEmphasized;
  static const Curve motionEasingStandardDecelerate = Curves.easeOutCubic;
  static const Curve motionEasingStandardAccelerate = Curves.easeInCubic;
  static const Curve motionEasingEmphasized = Curves.easeInOutCubicEmphasized;
  static const Curve motionEasingEmphasizedDecelerate = Curves.easeOutCubic;
  static const Curve motionEasingEmphasizedAccelerate = Curves.easeInCubic;

  // Global layout constants
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusSheet = 28;

  static const BorderRadius borderRadiusXs =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusSmAll =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMdAll =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLgAll =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusControl =
      BorderRadius.all(Radius.circular(14));

  static const RoundedRectangleBorder roundedShapeMd =
      RoundedRectangleBorder(borderRadius: borderRadiusMdAll);

  static const double controlHeight = 48;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 0, 16, 24);
  static const EdgeInsets sheetPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(12);

  static const EdgeInsets controlPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets fieldPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  static const EdgeInsets fieldPaddingLoose =
      EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  static const EdgeInsets inset12 = EdgeInsets.all(12);
  static const EdgeInsets inset16 = EdgeInsets.all(16);
  static const EdgeInsets inset24 = EdgeInsets.all(24);
  static const EdgeInsets insetH16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets insetH16V24 =
      EdgeInsets.symmetric(horizontal: 16, vertical: 24);
  static const EdgeInsets sectionDividerPadding =
      EdgeInsets.fromLTRB(16, 16, 16, 8);
  static const EdgeInsets bottomInset8 = EdgeInsets.only(bottom: 8);
  static const EdgeInsets buttonPaddingTall =
      EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets buttonPaddingWide =
      EdgeInsets.symmetric(horizontal: 32, vertical: 16);
  static const EdgeInsets topInset16 = EdgeInsets.only(top: 16);
  static const EdgeInsets topInset24 = EdgeInsets.only(top: 24);

  // Common card paddings (use these instead of ad-hoc EdgeInsets)
  static const EdgeInsets scriptCardPaddingBulletin =
      EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const EdgeInsets scriptCardPaddingDense =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const EdgeInsets scriptCardPadding =
      EdgeInsets.symmetric(horizontal: 18, vertical: 16);

  static const EdgeInsets cardMarginVertical8 =
      EdgeInsets.symmetric(vertical: 8);

  // Common screen/building-block paddings
  static const EdgeInsets rowPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets dialogInsetPadding = inset16;
  static const EdgeInsets alertTitlePadding =
      EdgeInsets.fromLTRB(24, 20, 24, 0);
  static const EdgeInsets alertContentPadding =
      EdgeInsets.fromLTRB(24, 16, 24, 0);
  static const EdgeInsets alertActionsPadding =
      EdgeInsets.fromLTRB(16, 8, 16, 12);

  static const SizedBox gap4 = SizedBox(height: 4);
  static const SizedBox gap8 = SizedBox(height: 8);
  static const SizedBox gap12 = SizedBox(height: 12);
  static const SizedBox gap16 = SizedBox(height: 16);
  static const SizedBox gap24 = SizedBox(height: 24);
  static const SizedBox gap28 = SizedBox(height: 28);
  static const SizedBox gap32 = SizedBox(height: 32);
  static const SizedBox gap40 = SizedBox(height: 40);

  static const SizedBox hGap4 = SizedBox(width: 4);
  static const SizedBox hGap8 = SizedBox(width: 8);
  static const SizedBox hGap12 = SizedBox(width: 12);
  static const SizedBox hGap16 = SizedBox(width: 16);

  static Color contrastOn(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? pureWhite
        : pureBlack;
  }

  static TextStyle get primaryFont => const TextStyle();

  static TextStyle get headingStyle => GoogleFonts.audiowide(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      );

  // --- Bulletin / Report Styling ---

  static TextStyle bulletinHeaderStyle(Color color) {
    return headingStyle.copyWith(
      fontSize: 20,
      color: color,
      shadows: textGlow(color),
    );
  }

  static TextStyle bulletinBodyStyle(Color onSurface) {
    return TextStyle(
      color: onSurface.withValues(alpha: 0.95),
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      height: 1.4,
    );
  }

  static BoxDecoration bulletinItemDecoration({
    required Color color,
    double opacity = 0.15,
  }) {
    return neonFrame(
      color: color,
      opacity: opacity,
      borderRadius: 16,
      borderWidth: 1.2,
      showGlow: true,
    );
  }

  static List<Shadow> textGlow(Color c, {double intensity = 1.0}) => [
        Shadow(
          color: c.withValues(alpha: 0.65 * intensity),
          blurRadius: 10 * intensity,
        ),
        Shadow(
          color: c.withValues(alpha: 0.35 * intensity),
          blurRadius: 20 * intensity,
        ),
      ];

  /// Convenience style for glowing text.
  ///
  /// Use [glowColor] when the glow should differ from the text color.
  static TextStyle glowTextStyle({
    TextStyle? base,
    required Color color,
    Color? glowColor,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double glowIntensity = 1.0,
    bool glow = true,
  }) {
    final effectiveBase = base ?? const TextStyle();
    final effectiveGlowColor = glowColor ?? color;
    return effectiveBase.copyWith(
      color: color,
      fontSize: fontSize ?? effectiveBase.fontSize,
      fontWeight: fontWeight ?? effectiveBase.fontWeight,
      letterSpacing: letterSpacing ?? effectiveBase.letterSpacing,
      shadows:
          glow ? textGlow(effectiveGlowColor, intensity: glowIntensity) : null,
    );
  }

  /// Convenience style for the NeonGlow brand font.
  ///
  /// Intended for headings and key labels that should read as "neon" text.
  /// Uses [textGlow] by default; set [glow] to false for non-glowing labels.
  static TextStyle neonGlowTextStyle({
    TextStyle? base,
    required Color color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double glowIntensity = 1.0,
    bool glow = true,
  }) {
    return glowTextStyle(
      base:
          (base ?? const TextStyle()).copyWith(fontFamily: neonGlowFontFamily),
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      glowIntensity: glowIntensity,
      glow: glow,
    ).copyWith(
      fontFamily: neonGlowFontFamily,
    );
  }

  static List<Shadow> iconGlow(Color c, {double intensity = 1.0}) =>
      textGlow(c, intensity: intensity);

  static List<BoxShadow> circleGlow(Color c, {double intensity = 1.0}) => [
        BoxShadow(
          color: c.withValues(alpha: 0.40 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  /// Glow shadow list for rectangular surfaces.
  ///
  /// Some legacy widgets in the app expect this helper.
  static List<BoxShadow> boxGlow(Color c, {double intensity = 1.0}) => [
        BoxShadow(
          color: c.withValues(alpha: 0.35 * intensity),
          blurRadius: 18 * intensity,
          spreadRadius: 2 * intensity,
        ),
        BoxShadow(
          color: c.withValues(alpha: 0.18 * intensity),
          blurRadius: 36 * intensity,
          spreadRadius: 4 * intensity,
        ),
      ];

  /// The standard "Neon Frame" decoration for the Club Blackout design language.
  /// Combines a dark surface, a neon border, and an outer glow.
  static BoxDecoration neonFrame({
    required Color color,
    double opacity = 0.85,
    double borderRadius = 16,
    double borderWidth = 1.2,
    bool showGlow = true,
  }) {
    return BoxDecoration(
      color: pureBlack.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderWidth > 0
          ? Border.all(
              color: color.withValues(alpha: 0.8),
              width: borderWidth,
            )
          : null,
      boxShadow: showGlow && borderWidth > 0
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
  }

  /// Neon styling for Bottom Sheets.
  static BoxDecoration neonSheet({
    required BuildContext context,
    Color? color,
  }) {
    final accent = color ?? ClubBlackoutTheme.neonBlue;
    return BoxDecoration(
      color: pureBlack.withValues(alpha: 0.90),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      border: Border.all(
        color: accent.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, -4),
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({
    required Color glowColor,
    double glowIntensity = 1.0,
    double borderRadius = 16,
    Color? surfaceColor,
  }) {
    final baseSurface = surfaceColor ?? pureBlack;
    return BoxDecoration(
      color: baseSurface.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glowColor.withValues(alpha: 0.8), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.3 * glowIntensity),
          blurRadius: 15 * glowIntensity,
          spreadRadius: 1 * glowIntensity,
        ),
      ],
    );
  }

  static BoxDecoration glassmorphism({
    required Color color,
    double opacity = 0.85,
    Color borderColor = const Color(0x3DFFFFFF),
    double borderRadius = 16,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }

  static Widget centeredConstrained(
      {required Widget child, double maxWidth = 820}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static ButtonStyle neonButtonStyle(Color color, {bool isPrimary = false}) {
    final fg = contrastOn(color);

    return FilledButton.styleFrom(
      backgroundColor: color.withValues(alpha: isPrimary ? 0.95 : 0.85),
      foregroundColor: fg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static ShapeBorder neonDialogShape(Color accent) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
      side: BorderSide(color: accent.withValues(alpha: 0.55), width: 1.5),
    );
  }

  static BoxDecoration neonBottomSheetDecoration(
    BuildContext context, {
    required Color accent,
    double opacity = 0.92,
  }) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: pureBlack.withValues(alpha: opacity),
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(radiusSheet)),
      border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.18),
          blurRadius: 18,
          spreadRadius: 1,
        ),
      ],
    ).copyWith(
      // Slight lift from the background if surface tint differs.
      color: cs.surface.withValues(alpha: 0.90),
    );
  }

  static Widget blurredBackdrop({required Widget child, double sigma = 12}) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }

  static ThemeData createTheme(ColorScheme colorScheme) {
    // Material 3: theme should be derived from a ColorScheme.
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
    );

    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final primary = colorScheme.primary;

    // Material 3 Typography Scale with proper font weights
    // Reference: https://m3.material.io/styles/typography/type-scale-tokens
    final textTheme = base.textTheme
        .apply(
          bodyColor: onSurface,
          displayColor: onSurface,
        )
        .copyWith(
          // Display styles (57/45/36)
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: -0.25,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          // Headline styles (32/28/24)
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          // Title styles (22/16/14)
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          // Label styles (14/12/11)
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          labelSmall: base.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          // Body styles (16/14/12)
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          ),
        );

    final defaultRadius = BorderRadius.circular(16);

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textSelectionTheme: base.textSelectionTheme.copyWith(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.28),
        selectionHandleColor: primary,
      ),
      iconTheme: base.iconTheme.copyWith(
        color: onSurface.withValues(alpha: 0.9),
        size: 22,
      ),
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        scrolledUnderElevation: elevationLevel2,
        elevation: 0,
        centerTitle: true,
        foregroundColor: onSurface,
        titleTextStyle: neonGlowTextStyle(
          base: textTheme.titleLarge,
          color: primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
        ),
        iconTheme: IconThemeData(
          color: onSurface.withValues(alpha: 0.92),
          size: 24,
        ),
      ),
      drawerTheme: base.drawerTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: onSurface,
        selectedColor: colorScheme.onSecondaryContainer,
        selectedTileColor: colorScheme.secondaryContainer,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 8,
        titleTextStyle:
            textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: textTheme.labelSmall,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: elevationLevel5,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        insetPadding: dialogInsetPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: primary.withValues(alpha: 0.3), width: 1.0),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor:
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primary, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerLow,
          foregroundColor: colorScheme.primary,
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(borderRadius: defaultRadius),
          elevation: elevationLevel1,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return elevationLevel1;
            if (states.contains(WidgetState.hovered)) return elevationLevel2;
            return elevationLevel1;
          }),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.pressed)) {
                return primary.withValues(alpha: stateLayerOpacityPressed);
              }
              if (states.contains(WidgetState.hovered)) {
                return primary.withValues(alpha: stateLayerOpacityHover);
              }
              if (states.contains(WidgetState.focused)) {
                return primary.withValues(alpha: stateLayerOpacityFocus);
              }
              return null;
            },
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurface.withValues(alpha: 0.92),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: defaultRadius),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.secondaryContainer;
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSecondaryContainer;
            }
            return onSurface.withValues(alpha: 0.92);
          }),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.pressed)) {
                return onSurface.withValues(alpha: stateLayerOpacityPressed);
              }
              if (states.contains(WidgetState.hovered)) {
                return onSurface.withValues(alpha: stateLayerOpacityHover);
              }
              if (states.contains(WidgetState.focused)) {
                return onSurface.withValues(alpha: stateLayerOpacityFocus);
              }
              return null;
            },
          ),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: elevationLevel1,
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onPrimary
                  .withValues(alpha: stateLayerOpacityPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onPrimary
                  .withValues(alpha: stateLayerOpacityHover);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.onPrimary
                  .withValues(alpha: stateLayerOpacityFocus);
            }
            return null;
          }),
        ),
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 16,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        secondarySelectedColor: colorScheme.secondaryContainer,
        checkmarkColor: colorScheme.onSecondaryContainer,
        deleteIconColor: colorScheme.onSecondaryContainer,
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide.none;
          }
          return BorderSide(
            color: colorScheme.outline,
            width: 1,
          );
        }),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: elevationLevel2,
        focusElevation: elevationLevel2,
        hoverElevation: elevationLevel3,
        highlightElevation: elevationLevel2,
        disabledElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        modalElevation: elevationLevel3,
        elevation: elevationLevel1,
        shadowColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(32, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        elevation: elevationLevel2,
        shadowColor: Colors.transparent,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          );
          if (states.contains(WidgetState.selected)) {
            return style?.copyWith(color: colorScheme.onSurface);
          }
          return style?.copyWith(color: colorScheme.onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationDrawerTheme: base.navigationDrawerTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        elevation: elevationLevel1,
        shadowColor: Colors.transparent,
        tileHeight: 56,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          );
          if (states.contains(WidgetState.selected)) {
            return style?.copyWith(color: colorScheme.onSecondaryContainer);
          }
          return style?.copyWith(color: colorScheme.onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: colorScheme.surfaceContainer,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: elevationLevel2,
        shadowColor: Colors.transparent,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const CircularNotchedRectangle(),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: primary,
        unselectedLabelColor: onSurface.withValues(alpha: 0.75),
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: primary,
        dividerColor: colorScheme.outlineVariant,
      ),
      tooltipTheme: base.tooltipTheme.copyWith(
        decoration: BoxDecoration(
          color: pureBlack.withValues(alpha: 0.92),
          borderRadius: ClubBlackoutTheme.borderRadiusSmAll,
          border: Border.all(color: primary.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: onSurface.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: pureBlack.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primary.withValues(alpha: 0.45), width: 1),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            pureBlack.withValues(alpha: 0.92),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:
                  BorderSide(color: primary.withValues(alpha: 0.45), width: 1),
            ),
          ),
          padding:
              const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: base.inputDecorationTheme,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            pureBlack.withValues(alpha: 0.92),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:
                  BorderSide(color: primary.withValues(alpha: 0.45), width: 1),
            ),
          ),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: defaultRadius),
          side: BorderSide(color: colorScheme.outline, width: 1),
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: colorScheme.primary, width: 1.5);
            }
            return BorderSide(color: colorScheme.outline, width: 1);
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: stateLayerOpacityPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return primary.withValues(alpha: stateLayerOpacityHover);
            }
            if (states.contains(WidgetState.focused)) {
              return primary.withValues(alpha: stateLayerOpacityFocus);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: defaultRadius),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(48, 40),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: stateLayerOpacityPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return primary.withValues(alpha: stateLayerOpacityHover);
            }
            if (states.contains(WidgetState.focused)) {
              return primary.withValues(alpha: stateLayerOpacityFocus);
            }
            return null;
          }),
        ),
      ),
      checkboxTheme: base.checkboxTheme.copyWith(
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: onSurface.withValues(alpha: 0.38),
              width: 2,
            );
          }
          if (states.contains(WidgetState.error)) {
            return BorderSide(
              color: colorScheme.error,
              width: 2,
            );
          }
          return BorderSide(
            color: onSurface.withValues(alpha: 0.6),
            width: 2,
          );
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              if (states.contains(WidgetState.selected)) {
                return onSurface.withValues(alpha: 0.38);
              }
              return Colors.transparent;
            }
            if (states.contains(WidgetState.selected)) {
              return primary;
            }
            return Colors.transparent;
          },
        ),
        checkColor: const WidgetStatePropertyAll(pureWhite),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: stateLayerOpacityPressed);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: stateLayerOpacityHover);
          }
          if (states.contains(WidgetState.focused)) {
            return primary.withValues(alpha: stateLayerOpacityFocus);
          }
          return null;
        }),
      ),
      radioTheme: base.radioTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              return onSurface.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.selected)) {
              return primary;
            }
            return onSurface.withValues(alpha: 0.6);
          },
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: stateLayerOpacityPressed);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: stateLayerOpacityHover);
          }
          if (states.contains(WidgetState.focused)) {
            return primary.withValues(alpha: stateLayerOpacityFocus);
          }
          return null;
        }),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.outline;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary.withValues(alpha: 0.5);
            }
            return colorScheme.surfaceContainerHighest;
          },
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.transparent;
            }
            return colorScheme.outline;
          },
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: stateLayerOpacityPressed);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: stateLayerOpacityHover);
          }
          if (states.contains(WidgetState.focused)) {
            return primary.withValues(alpha: stateLayerOpacityFocus);
          }
          return null;
        }),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        secondaryActiveTrackColor: primary.withValues(alpha: 0.54),
        thumbColor: primary,
        disabledThumbColor: colorScheme.onSurface.withValues(alpha: 0.38),
        overlayColor: primary.withValues(alpha: stateLayerOpacityHover),
        valueIndicatorColor: colorScheme.inverseSurface,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: fieldPadding,
        border: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: primary,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static InputDecoration neonInputDecoration(
    BuildContext context, {
    String? hint,
    String? labelText,
    required Color color,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      labelText: labelText,
      hintStyle: TextStyle(
        color: cs.onSurface.withValues(alpha: 0.3),
        letterSpacing: 1.2,
      ),
      labelStyle: TextStyle(
        color: cs.onSurface.withValues(alpha: 0.7),
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: color.withValues(alpha: 0.6),
            )
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cs.surface.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: color,
          width: 2,
        ),
      ),
    );
  }

  // ==================== Material 3 Animation Helpers ====================

  /// Create an M3-compliant fade-in animation
  static Animation<double> createFadeIn(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: motionEasingStandardDecelerate,
    );
  }

  /// Create an M3-compliant fade-out animation
  static Animation<double> createFadeOut(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: motionEasingStandardAccelerate,
    );
  }

  /// Create an M3-compliant slide animation
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, 0.05),
    Offset end = Offset.zero,
    Curve? curve,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve ?? motionEasingEmphasizedDecelerate,
      ),
    );
  }

  /// Create an M3-compliant scale animation
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 0.8,
    double end = 1.0,
    Curve? curve,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve ?? motionEasingEmphasizedDecelerate,
      ),
    );
  }

  /// Get the recommended duration for an animation based on travel distance
  /// Reference: M3 motion guidance
  static Duration getMotionDuration({required double distance}) {
    if (distance < 50) return motionDurationShort2;
    if (distance < 100) return motionDurationShort4;
    if (distance < 200) return motionDurationMedium2;
    if (distance < 300) return motionDurationMedium4;
    return motionDurationLong2;
  }
}
