import 'package:flutter/material.dart';

import '../../models/role.dart';
import '../styles.dart';
import 'active_event_card.dart';

Future<void> showRoleReveal(
  BuildContext context,
  Role role,
  String playerName, {
  String? subtitle,
  Widget? body,
  VoidCallback? onComplete,
  RoleFactsContext? factsContext,
}) async {
  final accentColor = role.color;

  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'Role Reveal',
    barrierDismissible: false,
    // Full screen opaque barrier
    barrierColor: ClubBlackoutTheme.kBackground,
    builder: (BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      
      // We build a UI that mimics ActiveEventCard but for a Role
      return Scaffold(
        backgroundColor: ClubBlackoutTheme.kBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header (Icon + Title)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color: role.color.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: role.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: role.color,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: role.color.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          role.assetPath,
                          width: 48,
                          height: 48,
                          color: role.color, // Tint icon
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerName.toUpperCase(),
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role.name.toUpperCase(),
                              style: ClubBlackoutTheme.headingStyle.copyWith(
                                fontSize: 28,
                                color: role.color,
                                shadows: ClubBlackoutTheme.textGlow(role.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Body (Description + Details)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(0.3),
                      border: Border(
                        left: BorderSide(color: role.color.withOpacity(0.5), width: 2),
                        right: BorderSide(color: role.color.withOpacity(0.5), width: 2),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subtitle != null) ...[
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Role Description
                          Text(
                            role.description,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: cs.onSurface.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Team / Alliance
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.surface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.groups_rounded, color: role.color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ALLIANCE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: cs.onSurface.withOpacity(0.6),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      Text(
                                        role.alliance,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (body != null) ...[
                            const SizedBox(height: 24),
                            body,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Footer (Action)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    border: Border.all(
                      color: role.color.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onComplete?.call();
                      },
                      style: ClubBlackoutTheme.neonButtonStyle(role.color, isPrimary: true).copyWith(
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                      ),
                      child: const Text('I UNDERSTAND'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

