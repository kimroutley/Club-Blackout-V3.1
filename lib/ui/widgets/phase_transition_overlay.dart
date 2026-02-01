import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/sound_service.dart';

class PhaseTransitionOverlay extends StatefulWidget {
  final String phaseName;
  final Color phaseColor;
  final IconData phaseIcon;
  final VoidCallback onComplete;
  final String? tip;
  final int? dayNumber;
  final int? playersAlive;

  const PhaseTransitionOverlay({
    super.key,
    required this.phaseName,
    required this.phaseColor,
    required this.phaseIcon,
    required this.onComplete,
    this.tip,
    this.dayNumber,
    this.playersAlive,
  });

  @override
  State<PhaseTransitionOverlay> createState() => _PhaseTransitionOverlayState();
}

class _PhaseTransitionOverlayState extends State<PhaseTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Play dramatic phase transition sound
    SoundService().playPhaseTransition();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.1),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Stack(
            children: [
              // Backdrop blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10 * _fadeAnimation.value,
                    sigmaY: 10 * _fadeAnimation.value,
                  ),
                  child: Container(
                    color:
                        cs.scrim.withValues(alpha: 0.7 * _fadeAnimation.value),
                  ),
                ),
              ),

              // Phase announcement
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      elevation: 24,
                      color: cs.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: BorderSide(
                          color: widget.phaseColor.withValues(alpha: 0.5 * _fadeAnimation.value),
                          width: 2,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            colors: [
                              widget.phaseColor.withValues(alpha: 0.12),
                              widget.phaseColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon with animated glow
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.phaseColor.withValues(alpha: 0.3),
                                      widget.phaseColor.withValues(alpha: 0.15),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.phaseColor.withValues(alpha: 0.4 * _fadeAnimation.value),
                                      blurRadius: 32,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.phaseIcon,
                                  size: 64,
                                  color: widget.phaseColor,
                                  shadows: [
                                    Shadow(
                                      color: widget.phaseColor.withValues(alpha: 0.8),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Phase name
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    widget.phaseColor,
                                    widget.phaseColor.withValues(alpha: 0.8),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  widget.phaseName,
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                    fontSize: 36,
                                  ),
                                ),
                              ),
                              
                              // Stats row
                              if (widget.dayNumber != null || widget.playersAlive != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: widget.phaseColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.dayNumber != null) ...[
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 18,
                                          color: widget.phaseColor.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Day ${widget.dayNumber}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                      if (widget.dayNumber != null && widget.playersAlive != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Container(
                                            width: 1,
                                            height: 20,
                                            color: cs.outline.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      if (widget.playersAlive != null) ...[
                                        Icon(
                                          Icons.groups_rounded,
                                          size: 18,
                                          color: widget.phaseColor.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${widget.playersAlive} Alive',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              
                              // Tip/instruction
                              if (widget.tip != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: widget.phaseColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: widget.phaseColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline_rounded,
                                        color: widget.phaseColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          widget.tip!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface.withValues(alpha: 0.9),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper function to show phase transition
void showPhaseTransition(
  BuildContext context, {
  required String phaseName,
  required Color phaseColor,
  required IconData phaseIcon,
  String? tip,
  int? dayNumber,
  int? playersAlive,
  VoidCallback? onComplete,
}) {
  bool removed = false;
  void removeOnce(OverlayEntry entry) {
    if (removed) return;
    removed = true;
    entry.remove();
  }

  late final OverlayEntry overlay;
  overlay = OverlayEntry(
    builder: (context) => PhaseTransitionOverlay(
      phaseName: phaseName,
      phaseColor: phaseColor,
      phaseIcon: phaseIcon,
      tip: tip,
      dayNumber: dayNumber,
      playersAlive: playersAlive,
      onComplete: () {
        removeOnce(overlay);
        onComplete?.call();
      },
    ),
  );

  Overlay.of(context).insert(overlay);

  // Fallback cleanup in case the overlay is still mounted (e.g. route change).
  Future.delayed(const Duration(milliseconds: 2200), () {
    if (!removed) {
      removeOnce(overlay);
    }
  });
}
