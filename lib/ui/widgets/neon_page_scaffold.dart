import 'package:flutter/material.dart';

import '../styles.dart';
import 'neon_background.dart';

class NeonPageScaffold extends StatelessWidget {
  final String? backgroundAsset;
  final Color accentColor;
  final Widget child;
  final double maxWidth;
  final bool scroll;
  final bool showOverlay;
  final EdgeInsets? padding;
  final bool applyAppBarOffset;

  const NeonPageScaffold({
    super.key,
    required this.child,
    required this.accentColor,
    this.backgroundAsset,
    this.maxWidth = 820,
    this.scroll = true,
    this.showOverlay = true,
    this.padding,
    this.applyAppBarOffset = true,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final defaultPadding = padding ?? ClubBlackoutTheme.pagePadding;
    final topOffset = applyAppBarOffset ? (kToolbarHeight - 12) : 8.0;

    final content = SafeArea(
      top: false,
      child: Padding(
        // Account for the transparent AppBar in the main shell.
        // Pulled up slightly to maximize screen real estate.
        padding: EdgeInsets.only(top: topInset + topOffset),
        child: ClubBlackoutTheme.centeredConstrained(
          maxWidth: maxWidth,
          child: scroll
              ? SingleChildScrollView(
                  padding: defaultPadding,
                  child: child,
                )
              : Padding(
                  padding: defaultPadding,
                  child: SizedBox.expand(child: child),
                ),
        ),
      ),
    );

    return NeonBackground(
      backgroundAsset: backgroundAsset,
      accentColor: accentColor,
      showOverlay: showOverlay,
      child: content,
    );
  }
}


