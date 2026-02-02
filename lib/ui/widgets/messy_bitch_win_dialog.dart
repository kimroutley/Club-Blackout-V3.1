import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../styles.dart';
import 'club_alert_dialog.dart';
import 'player_icon.dart';

class MessyBitchWinDialog extends StatelessWidget {
  final Player messyBitch;
  final VoidCallback onContinue;
  final VoidCallback onRestart;

  const MessyBitchWinDialog({
    super.key,
    required this.messyBitch,
    required this.onContinue,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final seed = Theme.of(context).colorScheme.primary;
    final theme = ThemeData.from(
      colorScheme:
          ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      useMaterial3: true,
    );
    final cs = theme.colorScheme;

    final accent = messyBitch.role.color;

    return Theme(
      data: theme,
      child: ClubAlertDialog(
        icon: PlayerIcon(
          assetPath: messyBitch.role.assetPath,
          glowColor: accent,
          glowIntensity: 0.20,
          size: 56,
        ),
        title: const Text('MESSY BITCH VICTORY'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${messyBitch.name.toUpperCase()} HAS SUCCESSFULLY SPREAD A RUMOUR TO EVERY SINGLE GUEST.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'SHE TAKES HER WIN AND LEAVES THE PARTY IN ABSOLUTE CHAOS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: onRestart,
            child: const Text('END GAME & RESTART'),
          ),
          FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.exit_to_app_rounded),
            label: const Text('KICK HER OUT & CONTINUE'),
            style: ClubBlackoutTheme.neonButtonStyle(accent, isPrimary: true),
          ),
        ],
      ),
    );
  }
}
