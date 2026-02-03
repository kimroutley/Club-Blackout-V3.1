import 'package:flutter/material.dart';
import '../styles.dart';
import 'neon_glass_card.dart';

class ActiveEventCard extends StatelessWidget {
  final String title;
  final Widget? icon;
  final String? subtitle; // e.g. "Read Aloud" or "Active"
  final String? bodyText; // The script text
  final Widget? actionSlot; // The interactive part (player list, buttons)
  final Color? accentColor;

  const ActiveEventCard({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.bodyText,
    this.actionSlot,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? ClubBlackoutTheme.kNeonCyan;
    
    return NeonGlassCard(
      glowColor: color,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
           // Header
           Row(
             children: [
               if (icon != null) ...[
                 // Ensure icon is sized appropriately or wrapped? 
                 // Assuming caller handles sizing or we enforce it here.
                 SizedBox(
                   width: 48, 
                   height: 48,
                   child: icon,
                 ), 
                 const SizedBox(width: 16),
               ],
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       title.toUpperCase(),
                       style: ClubBlackoutTheme.neonGlowTitle.copyWith(
                         color: color,
                         shadows: [
                           Shadow(color: color, blurRadius: 12),
                         ],
                       ),
                     ),
                     if (subtitle != null) ...[
                       const SizedBox(height: 4),
                       Text(
                         subtitle!,
                         style: ClubBlackoutTheme.mainFont.copyWith(
                           fontSize: 14,
                           fontWeight: FontWeight.w500,
                           color: ClubBlackoutTheme.pureWhite.withValues(alpha: 0.7),
                           letterSpacing: 1.5,
                         ),
                       ),
                     ],
                   ],
                 ),
               ),
             ],
           ),
           
           if (bodyText != null) ...[
             const SizedBox(height: 24),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.black12,
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(
                 bodyText!,
                 style: ClubBlackoutTheme.mainFont.copyWith(
                   color: ClubBlackoutTheme.pureWhite.withValues(alpha: 0.9),
                   fontSize: 16,
                   height: 1.5,
                 ),
               ),
             ),
           ],

           if (actionSlot != null) ...[
             const SizedBox(height: 24),
             Divider(color: color.withValues(alpha: 0.2)),
             const SizedBox(height: 16),
             AnimatedSize(
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOutQuart,
               child: actionSlot!,
             ),
           ]
        ],
      ),
    );
  }
}
