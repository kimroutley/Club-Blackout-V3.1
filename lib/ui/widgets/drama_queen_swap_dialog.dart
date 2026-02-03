import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/player.dart';
import '../styles.dart';
import '../widgets/club_alert_dialog.dart';
import 'bulletin_dialog_shell.dart';
import 'swap_setup_flow.dart';
import 'unified_player_tile.dart';

class DramaQueenSwapDialog extends StatefulWidget {
  final GameEngine gameEngine;
  final Function(Player, Player) onConfirm;

  const DramaQueenSwapDialog({
    super.key,
    required this.gameEngine,
    required this.onConfirm,
  });

  @override
  State<DramaQueenSwapDialog> createState() => _DramaQueenSwapDialogState();
}

class _DramaQueenSwapDialogState extends State<DramaQueenSwapDialog> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Pre-select if marked
    if (widget.gameEngine.dramaQueenMarkedAId != null) {
      _selectedIds.add(widget.gameEngine.dramaQueenMarkedAId!);
    }
    if (widget.gameEngine.dramaQueenMarkedBId != null) {
      _selectedIds.add(widget.gameEngine.dramaQueenMarkedBId!);
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length < 2) {
          _selectedIds.add(id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNight = widget.gameEngine.currentPhase == GamePhase.night;
    final cs = Theme.of(context).colorScheme;
    // Filter logic: Living players only. Drama Queen is dead, so she won't be in this list naturally if we filter isAlive.
    // Unless she revived? Unlikely.
    final candidates = widget.gameEngine.players
        .where((p) => p.isAlive && p.isEnabled)
        .toList();

    final canConfirm = _selectedIds.length == 2;

    Widget buildList() {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        itemCount: candidates.length,
        itemBuilder: (context, index) {
          final p = candidates[index];
          final selected = _selectedIds.contains(p.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: UnifiedPlayerTile(
              player: p,
              gameEngine: widget.gameEngine,
              config: PlayerTileConfig.standard(
                isSelected: selected,
                onTap: () => _toggle(p.id),
                isAnonymous: true,
                showStatusChips: false, // Hide chips to further obscure info if needed, though prompt only said hide role name. But status chips might reveal role (e.g. "Bouncer Checked"). Let's hide them to be safe/anonymous.
              ),
            ),
          );
        },
      );
    }

    if (isNight) {
      return ClubAlertDialog(
        title: const Text('Drama Queen Retaliation'),
        content: SizedBox(
          width: 640,
          height: 500, // Increased height for list
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose two players to swap roles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: buildList()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: canConfirm
                ? () async {
                    final list = _selectedIds.toList();
                    final p1 = candidates.firstWhere((p) => p.id == list[0]);
                    final p2 = candidates.firstWhere((p) => p.id == list[1]);
                    widget.onConfirm(p1, p2);

                    await runSwapTriggeredSetup(
                      context: context,
                      gameEngine: widget.gameEngine,
                      swappedPlayers: [p1, p2],
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                : null,
            child: const Text('Confirm Swap'),
          ),
        ],
      );
    }

    const accent = ClubBlackoutTheme.neonPurple;
    return BulletinDialogShell(
      accent: accent,
      maxWidth: 640,
      maxHeight: 800,
      insetPadding: ClubBlackoutTheme.dialogInsetPadding,
      title: Text(
        'DRAMA QUEEN RETALIATION',
        style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose two players to swap roles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.75),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: buildList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('SKIP (NO SWAP)'),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () async {
                  final list = _selectedIds.toList();
                  final p1 = candidates.firstWhere((p) => p.id == list[0]);
                  final p2 = candidates.firstWhere((p) => p.id == list[1]);
                  widget.onConfirm(p1, p2);

                  await runSwapTriggeredSetup(
                    context: context,
                    gameEngine: widget.gameEngine,
                    swappedPlayers: [p1, p2],
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              : null,
          style: ClubBlackoutTheme.neonButtonStyle(accent, isPrimary: true),
          child: const Text('CONFIRM SWAP'),
        ),
      ],
    );
  }
}
