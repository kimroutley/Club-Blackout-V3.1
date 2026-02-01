import 'package:flutter/material.dart';

import '../styles.dart';

/// A host-only "cover screen" to quickly hide sensitive information.
///
/// Exit requires a long-press to avoid accidental dismissals.
class HostPrivacyScreen extends StatelessWidget {
  final String? hint;

  const HostPrivacyScreen({
    super.key,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => Navigator.of(context).maybePop(),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle neon glow to keep the "Club Blackout" vibe, but still
              // fully obscuring content.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -0.2),
                        radius: 1.0,
                        colors: [
                          ClubBlackoutTheme.neonPurple.withValues(alpha: 0.18),
                          ClubBlackoutTheme.neonBlue.withValues(alpha: 0.10),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface.withValues(alpha: 0.10),
                          border: Border.all(
                            color: ClubBlackoutTheme.neonPurple
                                .withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ClubBlackoutTheme.neonPurple
                                  .withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility_off_rounded,
                          size: 44,
                          color: ClubBlackoutTheme.neonPurple,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'PRIVACY MODE',
                        style: ClubBlackoutTheme.glowTextStyle(
                          color: ClubBlackoutTheme.neonPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ).copyWith(letterSpacing: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hint ??
                            'Long-press anywhere\nwhen it\'s safe to return.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.70),
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nothing on this screen is interactive.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
