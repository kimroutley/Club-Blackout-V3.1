import 'dart:ui';

import 'package:flutter/material.dart';

import '../styles.dart';

class NeonBackground extends StatelessWidget {
  final String? backgroundAsset;
  final Color accentColor;
  final Widget child;
  final double? blurSigma;
  final bool showOverlay;

  const NeonBackground({
    super.key,
    required this.child,
    required this.accentColor,
    this.backgroundAsset,
    this.blurSigma,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: backgroundAsset == null
              ? Container(color: cs.surface)
              : Image.asset(
                  backgroundAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: cs.surface),
                ),
        ),
        if (blurSigma != null)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurSigma!,
                sigmaY: blurSigma!,
              ),
              child: Container(color: Colors.transparent),
            ),
          ),

        // Grade for readability with accent tint
        if (showOverlay)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // Top: Accent tint + darkness
                    accentColor.withValues(alpha: 0.15),
                    // Middle: mostly black for content readability
                    ClubBlackoutTheme.pureBlack.withValues(alpha: 0.9),
                    // Bottom: subtle accent return
                    accentColor.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

        child,
      ],
    );
  }
}
