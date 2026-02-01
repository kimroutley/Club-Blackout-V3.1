import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';
import '../styles.dart';

class PersistentToastListener extends StatefulWidget {
  final Widget child;
  final GameEngine gameEngine;

  const PersistentToastListener({
    super.key,
    required this.child,
    required this.gameEngine,
  });

  @override
  State<PersistentToastListener> createState() =>
      _PersistentToastListenerState();
}

class _PersistentToastListenerState extends State<PersistentToastListener>
    with SingleTickerProviderStateMixin {
  int _lastVersion = 0;
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    widget.gameEngine.addListener(_handleToastUpdate);
  }

  @override
  void dispose() {
    widget.gameEngine.removeListener(_handleToastUpdate);
    _animationController.dispose();
    _dismissToast(animate: false);
    super.dispose();
  }

  void _handleToastUpdate() {
    if (!mounted) return;

    final version = widget.gameEngine.persistentToastVersion;
    final hasPersistent = widget.gameEngine.hasPersistentToast;

    if (version != _lastVersion) {
      _lastVersion = version;

      if (hasPersistent) {
        _showPersistentToast();
      } else {
        _dismissToast();
      }
    } else if (!hasPersistent && _overlayEntry != null) {
      _dismissToast();
    }
  }

  void _showPersistentToast() {
    final title = widget.gameEngine.persistentToastTitle;
    final message = widget.gameEngine.persistentToastMessage;
    final onShare = widget.gameEngine.persistentToastShareAction;
    final onIgnore = widget.gameEngine.persistentToastIgnoreAction;

    if (title == null || message == null) return;

    _dismissToast(animate: false);

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _PersistentToastOverlay(
        title: title,
        message: message,
        onShare: onShare,
        onIgnore: onIgnore,
        scaleAnimation: _scaleAnimation,
        slideAnimation: _slideAnimation,
      ),
    );

    overlay.insert(_overlayEntry!);
    _animationController.forward();
  }

  void _dismissToast({bool animate = true}) {
    if (_overlayEntry == null) return;

    if (animate) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _animationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _PersistentToastOverlay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onShare;
  final VoidCallback? onIgnore;
  final Animation<double> scaleAnimation;
  final Animation<Offset> slideAnimation;

  const _PersistentToastOverlay({
    required this.title,
    required this.message,
    required this.onShare,
    required this.onIgnore,
    required this.scaleAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: Listenable.merge([scaleAnimation, slideAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: SlideTransition(
              position: slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ClubBlackoutTheme.neonPurple
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.save_alt,
                            color: ClubBlackoutTheme.neonPurple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: ClubBlackoutTheme.neonPurple,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onIgnore,
                          style: TextButton.styleFrom(
                            foregroundColor: cs.onSurfaceVariant,
                          ),
                          child: const Text('IGNORE'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: onShare,
                          style: FilledButton.styleFrom(
                            backgroundColor: ClubBlackoutTheme.neonPurple,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('SHARE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
