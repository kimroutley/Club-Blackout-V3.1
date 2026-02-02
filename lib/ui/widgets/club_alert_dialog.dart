import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../styles.dart';

/// AlertDialog wrapper that applies Club Blackout default paddings and M3 styling.
class ClubAlertDialog extends StatelessWidget {
  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? neonBorderColor; // New parameter for neon border
  final ShapeBorder? shape;
  final EdgeInsets? insetPadding;

  const ClubAlertDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions,
    this.backgroundColor,
    this.neonBorderColor,
    this.shape,
    this.insetPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final Color borderCol = neonBorderColor ?? colorScheme.primary.withValues(alpha: 0.5);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: AlertDialog(
        icon: icon != null 
            ? IconTheme.merge(
                data: IconThemeData(
                  color: borderCol,
                  shadows: [
                    Shadow(
                      color: borderCol.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: icon!,
              )
            : null,
        title: title != null 
            ? DefaultTextStyle(
                style: ClubBlackoutTheme.headingStyle.copyWith(
                  fontSize: 20,
                  color: borderCol,
                  shadows: [
                    Shadow(
                      color: borderCol.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: _uppercaseIfText(title!),
              ) 
            : null,
        content: content != null
            ? DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                ),
                child: content!, 
              ) 
            : null,
        actions: actions,
        backgroundColor: ClubBlackoutTheme.pureBlack.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
          side: BorderSide(
            color: borderCol.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        elevation: 0,
        scrollable: true,
        insetPadding: insetPadding ?? ClubBlackoutTheme.dialogInsetPadding,
      ),
    );
  }

  Widget singleChildScrollViewIfNeeded(Widget content) {
    // If content is already scrollable (like ListView), don't wrap.
    // However, AlertDialog's scrollable=true wraps content in SingleChildScrollView.
    // We'll rely on AlertDialog's scrollable property for simple cases.
    return content;
  }

  Widget _uppercaseIfText(Widget widget) {
    if (widget is Text) {
      return Text(
        (widget.data ?? '').toUpperCase(),
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      );
    }
    return widget;
  }
}

