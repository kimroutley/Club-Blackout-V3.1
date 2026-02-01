import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/role.dart';
import '../ui/styles.dart';

/// Service that generates dynamic themes from background images and role colors
class DynamicThemeService extends ChangeNotifier {
  static final DynamicThemeService _instance = DynamicThemeService._internal();
  factory DynamicThemeService() => _instance;
  DynamicThemeService._internal();

  // Current theme colors
  ColorScheme? _lightScheme;
  ColorScheme? _darkScheme;

  // Cache for background palettes
  final Map<String, PaletteGenerator> _paletteCache = {};

  // Current active background
  String? _currentBackground;

  ColorScheme? get lightScheme => _lightScheme;
  ColorScheme? get darkScheme => _darkScheme;

  /// Extract colors from a background image and generate theme
  Future<void> updateFromBackground(String assetPath) async {
    if (_currentBackground == assetPath &&
        _paletteCache.containsKey(assetPath)) {
      // Already loaded this background
      return;
    }

    try {
      final palette = await _loadPalette(assetPath);

      _currentBackground = assetPath;
      _generateThemeFromPalette(palette);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to extract colors from $assetPath: $e');
      // Fallback to default theme
      _generateDefaultTheme();
    }
  }

  /// Update theme based on active roles
  void updateFromRoles(List<Role> roles) {
    if (roles.isEmpty) {
      _generateDefaultTheme();
      return;
    }

    _generateThemeFromRoles(roles);
    notifyListeners();
  }

  /// Combine background and role colors for hybrid theming
  Future<void> updateFromBackgroundAndRoles(
    String assetPath,
    List<Role> roles,
  ) async {
    if (roles.isEmpty) {
      await updateFromBackground(assetPath);
      return;
    }

    try {
      final palette = await _loadPalette(assetPath);

      _currentBackground = assetPath;
      _generateHybridTheme(palette, roles);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to create hybrid theme: $e');
      _generateDefaultTheme();
    }
  }

  /// Generate theme from palette
  void _generateThemeFromPalette(PaletteGenerator palette) {
    // Extract dominant colors
    final vibrant = palette.vibrantColor?.color ?? ClubBlackoutTheme.neonPurple;
    final darkVibrant =
        palette.darkVibrantColor?.color ?? ClubBlackoutTheme.neonBlue;
    final lightVibrant =
        palette.lightVibrantColor?.color ?? ClubBlackoutTheme.neonPink;

    // Ensure colors are vibrant enough for Club Blackout aesthetic
    final primary = _boostSaturation(vibrant, targetSaturation: 0.7);
    final secondary = _boostSaturation(darkVibrant, targetSaturation: 0.65);
    final tertiary = _boostSaturation(lightVibrant, targetSaturation: 0.6);

    _lightScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: Brightness.light,
    );

    _darkScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: Brightness.dark,
    );
  }

  Future<PaletteGenerator> _loadPalette(String assetPath) async {
    final cached = _paletteCache[assetPath];
    if (cached != null) return cached;

    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    final palette = await PaletteGenerator.fromImage(
      image,
      maximumColorCount: 20,
    );

    _paletteCache[assetPath] = palette;
    return palette;
  }

  /// Generate theme from role colors
  void _generateThemeFromRoles(List<Role> roles) {
    // Get all role colors
    final roleColors = roles.map((r) => r.color).toList();

    if (roleColors.isEmpty) {
      _generateDefaultTheme();
      return;
    }

    // Find most vibrant role colors
    roleColors.sort((a, b) {
      final satA = HSLColor.fromColor(a).saturation;
      final satB = HSLColor.fromColor(b).saturation;
      return satB.compareTo(satA);
    });

    final primary = roleColors.isNotEmpty
        ? _boostSaturation(roleColors[0], targetSaturation: 0.75)
        : ClubBlackoutTheme.neonPurple;

    final secondary = roleColors.length > 1
        ? _boostSaturation(roleColors[1], targetSaturation: 0.7)
        : ClubBlackoutTheme.neonBlue;

    final tertiary = roleColors.length > 2
        ? _boostSaturation(roleColors[2], targetSaturation: 0.65)
        : ClubBlackoutTheme.neonPink;

    _lightScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: Brightness.light,
    );

    _darkScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: Brightness.dark,
    );
  }

  /// Generate hybrid theme combining background palette and role colors
  void _generateHybridTheme(PaletteGenerator palette, List<Role> roles) {
    // Extract background colors
    final bgVibrant =
        palette.vibrantColor?.color ?? ClubBlackoutTheme.neonPurple;
    final bgDark =
        palette.darkVibrantColor?.color ?? ClubBlackoutTheme.neonBlue;

    // Get role colors
    final roleColors = roles.map((r) => r.color).toList();
    roleColors.sort((a, b) {
      final satA = HSLColor.fromColor(a).saturation;
      final satB = HSLColor.fromColor(b).saturation;
      return satB.compareTo(satA);
    });

    // Blend: Use role color as primary, background colors as accents
    final primary = roleColors.isNotEmpty
        ? _blendColors(
            roleColors[0], bgVibrant, 0.7) // 70% role, 30% background
        : bgVibrant;

    final secondary = roleColors.length > 1
        ? _blendColors(roleColors[1], bgDark, 0.6)
        : bgDark;

    final tertiary = roleColors.length > 2
        ? _boostSaturation(roleColors[2], targetSaturation: 0.65)
        : palette.lightVibrantColor?.color ?? ClubBlackoutTheme.neonPink;

    _lightScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: Brightness.light,
    );

    _darkScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: Brightness.dark,
    );
  }

  /// Generate fallback default theme
  void _generateDefaultTheme() {
    _lightScheme = ColorScheme.fromSeed(
      seedColor: ClubBlackoutTheme.neonPurple,
      primary: ClubBlackoutTheme.neonPurple,
      secondary: ClubBlackoutTheme.neonBlue,
      tertiary: ClubBlackoutTheme.neonPink,
      brightness: Brightness.light,
    );

    _darkScheme = ColorScheme.fromSeed(
      seedColor: ClubBlackoutTheme.neonPurple,
      primary: ClubBlackoutTheme.neonPurple,
      secondary: ClubBlackoutTheme.neonBlue,
      tertiary: ClubBlackoutTheme.neonPink,
      brightness: Brightness.dark,
    );
  }

  /// Boost color saturation to match Club Blackout's vibrant aesthetic
  Color _boostSaturation(Color color, {required double targetSaturation}) {
    final hsl = HSLColor.fromColor(color);

    // If already saturated enough, keep it
    if (hsl.saturation >= targetSaturation) {
      return color;
    }

    // Boost saturation while maintaining hue and lightness
    return hsl.withSaturation(targetSaturation).toColor();
  }

  /// Blend two colors with a given ratio
  Color _blendColors(Color a, Color b, double ratio) {
    assert(ratio >= 0.0 && ratio <= 1.0);

    return Color.fromARGB(
      ((a.a * 255.0 * ratio) + (b.a * 255.0 * (1 - ratio)))
          .round()
          .clamp(0, 255),
      ((a.r * 255.0 * ratio) + (b.r * 255.0 * (1 - ratio)))
          .round()
          .clamp(0, 255),
      ((a.g * 255.0 * ratio) + (b.g * 255.0 * (1 - ratio)))
          .round()
          .clamp(0, 255),
      ((a.b * 255.0 * ratio) + (b.b * 255.0 * (1 - ratio)))
          .round()
          .clamp(0, 255),
    );
  }

  /// Reset to default theme
  void reset() {
    _currentBackground = null;
    _generateDefaultTheme();
    notifyListeners();
  }

  /// Clear cache (useful for testing or memory management)
  void clearCache() {
    _paletteCache.clear();
  }
}
