import 'package:flutter/material.dart';

import '../../models/role.dart';
import '../styles.dart';
import 'active_event_card.dart';
import 'role_card_widget.dart';
import 'role_facts_context.dart';

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
    barrierColor: Colors.black.withOpacity(0.95),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ActiveEventCard(
                  title: 'ROLE ASSIGNMENT',
                  subtitle: 'CONFIDENTIAL: ${playerName.toUpperCase()}',
                  accentColor: accentColor,
                  icon: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.asset(role.assetPath, fit: BoxFit.contain),
                  ),
                  // Instructions
                  bodyText:
                      "Tap the card below to reveal your identity. Keep your screen hidden from others.",
                  // The interactive part
                  actionSlot: Column(
                    children: [
                      const SizedBox(height: 24),
                      // The Role Card
                      SizedBox(
                        height: 480, // Taller for better visibility
                        child: Center(
                          child: RoleCardWidget(
                            role: role,
                            compact: false,
                            factsContext: factsContext,
                            initiallyFlipped: false, // Start hidden
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Confirmation Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onComplete?.call();
                          },
                          style: ClubBlackoutTheme.neonButtonStyle(
                            accentColor,
                            isPrimary: true,
                          ).copyWith(
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(vertical: 20),
                            ),
                          ),
                          child: const Text(
                            "I UNDERSTAND MY ROLE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

