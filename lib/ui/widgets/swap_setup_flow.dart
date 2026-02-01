import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/player.dart';
import '../../models/script_step.dart';
import '../styles.dart';
import 'bulletin_dialog_shell.dart';
import 'role_reveal_widget.dart';

Future<void> runSwapTriggeredSetup({
  required BuildContext context,
  required GameEngine gameEngine,
  required List<Player> swappedPlayers,
}) async {
  // Only roles that truly need one-time setup should be prompted here.
  // This is intended for mid-game swaps (e.g., Drama Queen retaliation).
  for (final p in swappedPlayers) {
    if (!p.isEnabled || !p.isAlive) continue;
    if (!p.needsSetup) continue;

    switch (p.role.id) {
      case 'clinger':
        await _runClingerSetup(context: context, engine: gameEngine, clinger: p);
        break;
      case 'creep':
        await _runCreepSetup(context: context, engine: gameEngine, creep: p);
        break;
      case 'medic':
        await _runMedicSetup(context: context, engine: gameEngine, medic: p);
        break;
      case 'whore':
        await _runWhoreSetup(context: context, engine: gameEngine, whore: p);
        break;
      default:
        break;
    }
  }
}

Future<void> _runMedicSetup({
  required BuildContext context,
  required GameEngine engine,
  required Player medic,
}) async {
  final choice = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return BulletinDialogShell(
        accent: medic.role.color,
        maxWidth: 560,
        title: Text(
          'MEDIC SETUP',
          style: ClubBlackoutTheme.headingStyle.copyWith(
            color: medic.role.color,
          ),
        ),
        content: Text(
          'Choose the Medic ability for the rest of the game.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('PROTECT_DAILY'),
            style: FilledButton.styleFrom(
              backgroundColor: medic.role.color.withValues(alpha: 0.16),
              foregroundColor: cs.onSurface,
            ),
            child: const Text('PROTECT (DAILY)'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('REVIVE'),
            style: FilledButton.styleFrom(
              backgroundColor: medic.role.color.withValues(alpha: 0.16),
              foregroundColor: cs.onSurface,
            ),
            child: const Text('REVIVE (ONCE)'),
          ),
        ],
      );
    },
  );

  if (choice == null || choice.isEmpty) return;

  engine.handleScriptAction(
    ScriptStep(
      id: 'medic_setup_choice',
      title: 'The Medic - Setup',
      readAloudText: '',
      instructionText: '',
      isNight: engine.currentPhase == GamePhase.night,
      actionType: ScriptActionType.toggleOption,
      roleId: 'medic',
    ),
    [choice],
  );
}

Future<void> _runClingerSetup({
  required BuildContext context,
  required GameEngine engine,
  required Player clinger,
}) async {
  final candidates = engine.players
      .where(
        (p) =>
            p.isEnabled &&
            p.isAlive &&
            p.id != clinger.id,
      )
      .toList();

  if (candidates.isEmpty) {
    clinger.needsSetup = false;
    engine.logAction(
      'The Clinger - Setup',
      'No eligible obsession target exists. Setup skipped.',
    );
    return;
  }

  final chosen = await _pickPlayer(
    context: context,
    title: 'CLINGER SETUP',
    accent: clinger.role.color,
    message: 'Choose the Clinger\'s obsession.',
    candidates: candidates,
    cancelLabel: 'DO LATER',
  );

  if (chosen == null) return;

  engine.handleScriptAction(
    ScriptStep(
      id: 'clinger_obsession',
      title: 'The Clinger - Setup',
      readAloudText: '',
      instructionText: '',
      isNight: engine.currentPhase == GamePhase.night,
      actionType: ScriptActionType.selectPlayer,
      roleId: 'clinger',
    ),
    [chosen.id],
  );

  // Note: the engine will raise a HostAlert with the revealed role name.
}

Future<void> _runCreepSetup({
  required BuildContext context,
  required GameEngine engine,
  required Player creep,
}) async {
  final candidates = engine.players
      .where(
        (p) =>
            p.isEnabled &&
            p.isAlive &&
            p.id != creep.id,
      )
      .toList();

  if (candidates.isEmpty) {
    creep.needsSetup = false;
    engine.logAction(
      'The Creep - Setup',
      'No eligible mimic target exists. Setup skipped.',
    );
    return;
  }

  final chosen = await _pickPlayer(
    context: context,
    title: 'CREEP SETUP',
    accent: creep.role.color,
    message: 'Choose a player whose role the Creep will mimic.',
    candidates: candidates,
    cancelLabel: 'DO LATER',
  );

  if (chosen == null) return;

  engine.handleScriptAction(
    ScriptStep(
      id: 'creep_act',
      title: 'The Creep - Setup',
      readAloudText: '',
      instructionText: '',
      isNight: engine.currentPhase == GamePhase.night,
      actionType: ScriptActionType.selectPlayer,
      roleId: 'creep',
    ),
    [chosen.id],
  );

  if (!context.mounted) return;

  await showRoleReveal(
    context,
    chosen.role,
    chosen.name,
    subtitle: 'Creep Target',
  );
}

Future<void> _runWhoreSetup({
  required BuildContext context,
  required GameEngine engine,
  required Player whore,
}) async {
  final candidates = engine.players
      .where(
        (p) =>
            p.isEnabled &&
            p.isAlive &&
            p.id != whore.id &&
            p.role.id != 'dealer' &&
            !p.alliance.toLowerCase().contains('dealer'),
      )
      .toList();

  if (candidates.isEmpty) {
    whore.whoreDeflectionUsed = true;
    whore.needsSetup = false;
    engine.logAction(
      'The Whore - Setup',
      'No eligible scapegoat exists. Ability forfeited.',
    );
    return;
  }

  final chosen = await _pickPlayer(
    context: context,
    title: 'WHORE SETUP',
    accent: whore.role.color,
    message: 'Choose the Whore\'s permanent scapegoat (must be non-Dealer).',
    candidates: candidates,
    extraActions: [
      (BuildContext ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('FORFEIT'),
          ),
    ],
  );

  if (chosen == null) {
    whore.whoreDeflectionUsed = true;
    whore.needsSetup = false;
    engine.logAction(
      'The Whore - Setup',
      'Whore forfeited scapegoat selection.',
    );
    return;
  }

  engine.handleScriptAction(
    ScriptStep(
      id: 'whore_deflect',
      title: 'The Whore - Setup',
      readAloudText: '',
      instructionText: '',
      isNight: engine.currentPhase == GamePhase.night,
      actionType: ScriptActionType.selectPlayer,
      roleId: 'whore',
    ),
    [chosen.id],
  );
}

typedef _DialogActionBuilder = Widget Function(BuildContext context);

Future<Player?> _pickPlayer({
  required BuildContext context,
  required String title,
  required Color accent,
  required String message,
  required List<Player> candidates,
  List<_DialogActionBuilder> extraActions = const [],
  String? cancelLabel,
}) async {
  return showDialog<Player>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return BulletinDialogShell(
        accent: accent,
        maxWidth: 640,
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
        title: Text(
          title,
          style: ClubBlackoutTheme.headingStyle.copyWith(color: accent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final p = candidates[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: p.role.color,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0] : '?',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      p.role.name,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                    onTap: () => Navigator.of(ctx).pop(p),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          if (cancelLabel != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(cancelLabel),
            ),
          ...extraActions.map((b) => b(ctx)),
        ],
      );
    },
  );
}
