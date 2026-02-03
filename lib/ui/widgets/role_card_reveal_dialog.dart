import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../styles.dart';
import 'active_event_card.dart';
import 'player_icon.dart';
import 'role_card_widget.dart';
import 'role_facts_context.dart';

class RoleCardRevealDialog extends StatelessWidget {
  final Player player;
  final VoidCallback onConfirm;
  final RoleFactsContext? factsContext;

  const RoleCardRevealDialog({
    super.key,
    required this.player,
    required this.onConfirm,
    this.factsContext,
  });

  @override
  Widget build(BuildContext context) {
    final role = player.role;
    final accent = role.color;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ActiveEventCard(
        header: Row(
          children: [
            PlayerIcon(
              assetPath: role.assetPath,
              glowColor: accent,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROLE REVEAL',
                    style: ClubBlackoutTheme.neonGlowFont.copyWith(
                      color: accent,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player.name.toUpperCase(),
                    style: ClubBlackoutTheme.neonGlowFont.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            RoleCardWidget(
              role: role,
              compact: false,
              allowFlip: false,
              tapToFlip: false,
              factsContext: factsContext,
            ),
          ],
        ),
        actionSlot: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: ClubBlackoutTheme.neonButtonStyle(accent, isPrimary: true),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('CONFIRM & CONTINUE'),
            ),
          ),
        ),
      ),
    );
  }
}
