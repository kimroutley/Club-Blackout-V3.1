import 'package:flutter/material.dart';
import '../styles.dart';

class BottomGameControls extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;
  final VoidCallback? onMenu; 
  final bool nextEnabled;
  final String nextLabel;

  const BottomGameControls({
    super.key,
    this.onBack,
    this.onSkip,
    this.onNext,
    this.onMenu,
    this.nextEnabled = true,
    this.nextLabel = 'NEXT',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Extra bottom padding for safe area
      decoration: BoxDecoration(
        color: ClubBlackoutTheme.kBackground.withValues(alpha: 0.95),
        border: Border(
           top: BorderSide(color: ClubBlackoutTheme.kNeonCyan.withValues(alpha: 0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ]
      ),
      child: Row(
        children: [
           // Back (Circle)
           IconButton.filledTonal(
             onPressed: onBack,
             tooltip: 'Back',
             style: IconButton.styleFrom(
               backgroundColor: Colors.white.withValues(alpha: 0.05),
               foregroundColor: Colors.white,
               side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
             ),
             icon: const Icon(Icons.arrow_back_rounded),
           ),
           
           const SizedBox(width: 12),

           // Menu (Flash)
           IconButton.filled(
             onPressed: onMenu,
             tooltip: 'Menu',
             style: IconButton.styleFrom(
               backgroundColor: ClubBlackoutTheme.kNeonPink.withValues(alpha: 0.2),
               foregroundColor: ClubBlackoutTheme.kNeonPink,
               side: const BorderSide(color: ClubBlackoutTheme.kNeonPink),
             ),
             icon: const Icon(Icons.bolt_rounded), // Flash/Bolt
           ),
           
           const SizedBox(width: 12),

           // Skip (Capsule) - if permissible
           if (onSkip != null)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                 onPressed: onSkip,
                 style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                 ),
                 child: Text(
                   'SKIP', 
                   style: ClubBlackoutTheme.mainFont.copyWith(fontSize: 12),
                 ),
               ),
            ),

           const Spacer(),

           // Next (Flash/Primary)
           FilledButton.icon(
             onPressed: nextEnabled ? onNext : null,
             style: FilledButton.styleFrom(
               backgroundColor: ClubBlackoutTheme.kNeonCyan,
               foregroundColor: Colors.black,
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
               textStyle: ClubBlackoutTheme.mainFont.copyWith(
                 fontWeight: FontWeight.bold,
                 letterSpacing: 1.0,
               ),
               elevation: nextEnabled ? 8 : 0,
               shadowColor: ClubBlackoutTheme.kNeonCyan.withValues(alpha: 0.5),
             ),
             icon: const Icon(Icons.arrow_forward_rounded, size: 20),
             label: Text(nextLabel),
           ),
        ],
      ),
    );
  }
}
