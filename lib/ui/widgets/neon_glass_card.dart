import 'package:flutter/material.dart';
import '../styles.dart';

class NeonGlassCard extends StatelessWidget {
  final Color glowColor;
  final Widget child;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showBorder;
  final double? borderRadius;

  const NeonGlassCard({
    super.key,
    required this.glowColor,
    required this.child,
    this.opacity = 0.95, // Solid card default
    this.padding,
    this.margin,
    this.showBorder = false, // No border by default
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 20;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: showBorder
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 6,
                ),
              ],
            )
          : const BoxDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          color: ClubBlackoutTheme.kCardBg.withValues(alpha: opacity), // Use kCardBg
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: showBorder
                ? BorderSide(color: glowColor.withValues(alpha: 0.5), width: 1.0) // Thinner, subtler border if enabled
                : BorderSide.none,
          ),
          child: Padding(
            padding: padding ?? ClubBlackoutTheme.cardPadding,
            child: child,
          ),
        ),
      ),
    ),
  );
}
}
