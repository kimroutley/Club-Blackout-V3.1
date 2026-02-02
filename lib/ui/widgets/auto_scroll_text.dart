import 'dart:async';

import 'package:flutter/material.dart';

/// A lightweight marquee that auto-scrolls horizontally when text overflows.
///
/// - If the text fits, it renders a normal [Text].
/// - If it overflows, it gently scrolls left/right in a loop.
class AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  /// Pixels per second when scrolling.
  final double speed;

  /// Pause at each end of the scroll.
  final Duration endPause;

  /// Extra gap after the text before looping.
  final double gap;

  const AutoScrollText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.speed = 36,
    this.endPause = const Duration(milliseconds: 650),
    this.gap = 24,
  });

  @override
  State<AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> {
  final _controller = ScrollController();
  bool _shouldScroll = false;
  bool _running = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runMarquee() async {
    if (_running) return;
    _running = true;

    // Wait for layout.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    while (mounted && _shouldScroll) {
      if (!_controller.hasClients) break;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) break;

      await Future<void>.delayed(widget.endPause);
      if (!mounted) break;

      final toEndMs = (max / widget.speed * 1000).clamp(200, 20000).toInt();
      await _controller.animateTo(
        max,
        duration: Duration(milliseconds: toEndMs),
        curve: Curves.linear,
      );
      if (!mounted) break;

      await Future<void>.delayed(widget.endPause);
      if (!mounted) break;

      final backMs = (max / widget.speed * 1000).clamp(200, 20000).toInt();
      await _controller.animateTo(
        0,
        duration: Duration(milliseconds: backMs),
        curve: Curves.linear,
      );
    }

    _running = false;
  }

  bool _computeShouldScroll(
      BoxConstraints constraints, TextStyle effectiveStyle) {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: effectiveStyle),
      maxLines: widget.maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: constraints.maxWidth);

    return tp.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;

    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: TextOverflow.visible,
            textAlign: widget.textAlign,
            style: effectiveStyle,
          ),
          // We always add a gap and a post-frame check to see if we should scroll.
          // This avoids LayoutBuilder intrinsic dimension issues.
          Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !_controller.hasClients) return;
                final max = _controller.position.maxScrollExtent;
                final should = max > 0;
                if (should != _shouldScroll) {
                  setState(() => _shouldScroll = should);
                  if (should) _runMarquee();
                }
              });
              return SizedBox(width: _shouldScroll ? widget.gap : 0.1);
            },
          ),
        ],
      ),
    );
  }
}
}

/// A horizontally-scrollable container that can optionally auto-pan when
/// its content overflows.
class AutoScrollHStack extends StatefulWidget {
  final Widget child;
  final bool autoScroll;
  final double speed;
  final Duration endPause;

  const AutoScrollHStack({
    super.key,
    required this.child,
    this.autoScroll = true,
    this.speed = 48,
    this.endPause = const Duration(milliseconds: 650),
  });

  @override
  State<AutoScrollHStack> createState() => _AutoScrollHStackState();
}

class _AutoScrollHStackState extends State<AutoScrollHStack> {
  final ScrollController _controller = ScrollController();
  bool _running = false;
  DateTime _lastUserScroll = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _userRecentlyInteracted {
    final dt = DateTime.now().difference(_lastUserScroll);
    return dt < const Duration(seconds: 3);
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    while (mounted && widget.autoScroll) {
      if (!_controller.hasClients) break;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) break;
      if (_userRecentlyInteracted) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        continue;
      }

      await Future<void>.delayed(widget.endPause);
      if (!mounted) break;

      final toEndMs = (max / widget.speed * 1000).clamp(200, 20000).toInt();
      await _controller.animateTo(
        max,
        duration: Duration(milliseconds: toEndMs),
        curve: Curves.linear,
      );
      if (!mounted) break;

      await Future<void>.delayed(widget.endPause);
      if (!mounted) break;

      final backMs = (max / widget.speed * 1000).clamp(200, 20000).toInt();
      await _controller.animateTo(
        0,
        duration: Duration(milliseconds: backMs),
        curve: Curves.linear,
      );
    }

    _running = false;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.autoScroll) return;
      _run();
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is UserScrollNotification || n is ScrollUpdateNotification) {
          _lastUserScroll = DateTime.now();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: widget.child,
      ),
    );
  }
}
