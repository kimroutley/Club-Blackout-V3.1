import 'package:flutter/material.dart';

import '../styles.dart';

class PlayerManagementDialog extends StatelessWidget {
	final String playerId;

	const PlayerManagementDialog({super.key, required this.playerId});

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			title: const Text('Player Management'),
			content: Text(
				'Management actions for "$playerId" are not implemented yet.',
				style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
			),
			actions: [
				TextButton(
					onPressed: () => Navigator.of(context).pop(),
					child: const Text('CLOSE'),
				),
				FilledButton(
					onPressed: () => Navigator.of(context).pop(),
					style: FilledButton.styleFrom(
						backgroundColor: ClubBlackoutTheme.neonBlue,
						foregroundColor:
								ClubBlackoutTheme.contrastOn(ClubBlackoutTheme.neonBlue),
					),
					child: const Text('OK'),
				),
			],
		);
	}
}
