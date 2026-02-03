import 'package:flutter/material.dart';
import '../styles.dart';

class BottomGameControls extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;
  final bool canSkip;
  final bool canNext;

  const BottomGameControls({
    super.key,
    this.onBack,
    this.onMenu,
    this.onSkip,
    this.onNext,
    this.canSkip = false,
    this.canNext = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        children: [
          // Back (Circle)
          if (onBack != null)
            _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack!,
              color: Colors.white.withOpacity(0.1),
            )
          else
            const SizedBox(width: 48),

          const Spacer(),

          // Menu (Flash style - placeholder for now, using Icon)
          if (onMenu != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: onMenu,
            ),

          const SizedBox(width: 16),

          // Skip (Capsule)
          if (canSkip && onSkip != null)
            FilledButton(
              onPressed: onSkip,
              style: FilledButton.styleFrom(
                backgroundColor: ClubBlackoutTheme.kCardBg,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                'SKIP',
                style: ClubBlackoutTheme.neonGlowFont.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          const SizedBox(width: 16),

          // Next (Flash style / Circle)
          if (onNext != null)
            _CircleButton(
              icon: Icons.arrow_forward_rounded,
              onTap: onNext!,
              color: canNext ? ClubBlackoutTheme.kNeonCyan : Colors.white.withOpacity(0.1),
              iconColor: canNext ? Colors.black : Colors.white.withOpacity(0.5),
            )
          else
             const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color? iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white),
      ),
    );
  }
}
