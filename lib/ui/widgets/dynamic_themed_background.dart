import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/role.dart';
import '../../services/dynamic_theme_service.dart';

/// Widget that automatically updates theme when background changes
class DynamicThemedBackground extends StatefulWidget {
  final String backgroundAsset;
  final Widget child;
  final List<Role>? activeRoles;
  final bool useRoleColors;

  const DynamicThemedBackground({
    super.key,
    required this.backgroundAsset,
    required this.child,
    this.activeRoles,
    this.useRoleColors = false,
  });

  @override
  State<DynamicThemedBackground> createState() =>
      _DynamicThemedBackgroundState();
}

class _DynamicThemedBackgroundState extends State<DynamicThemedBackground> {
  @override
  void initState() {
    super.initState();
    _updateTheme();
  }

  @override
  void didUpdateWidget(DynamicThemedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update theme if background or roles changed
    if (oldWidget.backgroundAsset != widget.backgroundAsset ||
        oldWidget.activeRoles != widget.activeRoles ||
        oldWidget.useRoleColors != widget.useRoleColors) {
      _updateTheme();
    }
  }

  Future<void> _updateTheme() async {
    if (!mounted) return;

    late final DynamicThemeService themeService;
    try {
      themeService = Provider.of<DynamicThemeService>(context, listen: false);
    } on ProviderNotFoundException {
      // Tests or preview widgets may not provide DynamicThemeService.
      // In that case, just render the child without attempting theme updates.
      return;
    }

    if (widget.useRoleColors &&
        widget.activeRoles != null &&
        widget.activeRoles!.isNotEmpty) {
      // Hybrid mode: combine background and role colors
      await themeService.updateFromBackgroundAndRoles(
        widget.backgroundAsset,
        widget.activeRoles!,
      );
    } else if (widget.activeRoles != null && widget.activeRoles!.isNotEmpty) {
      // Role-only mode (fallback if needed)
      themeService.updateFromRoles(widget.activeRoles!);
    } else {
      // Background-only mode
      await themeService.updateFromBackground(widget.backgroundAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to easily access theme updates from anywhere
extension DynamicThemeContext on BuildContext {
  /// Update theme from background image
  Future<void> updateThemeFromBackground(String assetPath) async {
    try {
      final service = Provider.of<DynamicThemeService>(this, listen: false);
      await service.updateFromBackground(assetPath);
    } on ProviderNotFoundException {
      return;
    }
  }

  /// Update theme from role colors
  void updateThemeFromRoles(List<Role> roles) {
    try {
      final service = Provider.of<DynamicThemeService>(this, listen: false);
      service.updateFromRoles(roles);
    } on ProviderNotFoundException {
      return;
    }
  }

  /// Update theme from both background and roles
  Future<void> updateThemeFromBackgroundAndRoles(
    String assetPath,
    List<Role> roles,
  ) async {
    try {
      final service = Provider.of<DynamicThemeService>(this, listen: false);
      await service.updateFromBackgroundAndRoles(assetPath, roles);
    } on ProviderNotFoundException {
      return;
    }
  }

  /// Reset theme to default
  void resetTheme() {
    try {
      final service = Provider.of<DynamicThemeService>(this, listen: false);
      service.reset();
    } on ProviderNotFoundException {
      return;
    }
  }
}
