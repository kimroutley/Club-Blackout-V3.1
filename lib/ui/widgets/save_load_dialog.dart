import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../../models/saved_game.dart';
import '../styles.dart';
import 'bulletin_dialog_shell.dart';

/// Material 3 save/load dialog.
class SaveLoadDialog extends StatefulWidget {
  final GameEngine engine;

  const SaveLoadDialog({super.key, required this.engine});

  @override
  State<SaveLoadDialog> createState() => _SaveLoadDialogState();
}

class _SaveLoadDialogState extends State<SaveLoadDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;
  List<SavedGame> _saves = const [];
  String? _selectedSaveId;

  static const String _testSaveName = 'Test Game (All Roles)';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final saves = await widget.engine.getSavedGames();
    // Present newest first, but don’t change stored ordering.
    saves.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    if (!mounted) return;
    setState(() {
      _saves = saves;
      _loading = false;
      _selectedSaveId ??= _saves.isNotEmpty ? _saves.first.id : null;
    });
  }

  Future<void> _save({String? overwriteId}) async {
    final raw = _nameController.text.trim();
    final name = raw.isEmpty ? 'Save ${DateTime.now().toIso8601String()}' : raw;

    await widget.engine.saveGame(name, overwriteId: overwriteId);
    if (!mounted) return;
    await _refresh();

    if (!mounted) return;
    widget.engine.showToast(
      overwriteId == null ? 'Saved "$name"' : 'Overwrote "$name"',
    );
  }

  Future<void> _loadSelected() async {
    final id = _selectedSaveId;
    if (id == null) return;

    final ok = await widget.engine.loadGame(id);
    if (!mounted) return;

    if (!ok) {
      widget.engine.showToast('Load failed (corrupt or missing save).');
      await _refresh();
      return;
    }

    Navigator.of(context).pop(true);
    widget.engine.showToast('Game loaded.');
  }

  Future<void> _deleteSelected() async {
    final id = _selectedSaveId;
    if (id == null) return;

    final save = _saves.where((s) => s.id == id).firstOrNull;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        const accent = ClubBlackoutTheme.neonRed;
        return BulletinDialogShell(
          accent: accent,
          maxWidth: 520,
          title: Text(
            'DELETE SAVE?',
            style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
          ),
          content: Text(
            'Delete "${save?.name ?? 'this save'}"?\n\nThis cannot be undone.',
            style: ClubBlackoutTheme.bulletinBodyStyle(cs.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.7),
              ),
              child: Text(
                'CANCEL',
                style: ClubBlackoutTheme.headingStyle.copyWith(
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ClubBlackoutTheme.neonButtonStyle(accent, isPrimary: true),
              child: Text(
                'DELETE',
                style: ClubBlackoutTheme.headingStyle.copyWith(
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: ClubBlackoutTheme.pureBlack,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await widget.engine.deleteSavedGame(id);
    if (!mounted) return;

    setState(() {
      _selectedSaveId = null;
    });
    await _refresh();

    if (!mounted) return;
    widget.engine.showToast('Save deleted.');
  }

  Widget _buildInfoTag(ColorScheme cs, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: ClubBlackoutTheme.headingStyle.copyWith(
              fontSize: 9,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = ClubBlackoutTheme.neonBlue;

    return BulletinDialogShell(
      accent: accent,
      maxWidth: 560,
      maxHeight: 740,
      title: Text(
        'SAVE / LOAD',
        style: ClubBlackoutTheme.bulletinHeaderStyle(accent).copyWith(
          letterSpacing: 2.0,
        ),
      ),
      showCloseButton: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurface.withValues(alpha: 0.7),
          ),
          child: Text(
            'CLOSE',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed:
              (_loading || _selectedSaveId == null) ? null : _deleteSelected,
          style: TextButton.styleFrom(
            foregroundColor: ClubBlackoutTheme.neonRed,
          ),
          child: Text(
            'DELETE',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed:
              (_loading || _selectedSaveId == null) ? null : _loadSelected,
          style: ClubBlackoutTheme.neonButtonStyle(
            ClubBlackoutTheme.neonGreen,
            isPrimary: true,
          ),
          child: Text(
            'LOAD',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              fontSize: 13,
              letterSpacing: 1.2,
              color: ClubBlackoutTheme.pureBlack,
            ),
          ),
        ),
      ],
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: ClubBlackoutTheme.neonGreen,
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create a new save or load an existing one.',
                    style: ClubBlackoutTheme.bulletinBodyStyle(cs.onSurface),
                  ),
                  const SizedBox(height: 12),

                  // Always-visible entry: creates/overwrites and loads a named test save.
                  InkWell(
                    onTap: _loading
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                final cs = Theme.of(ctx).colorScheme;
                                const accent = ClubBlackoutTheme.neonGreen;
                                return BulletinDialogShell(
                                  accent: accent,
                                  maxWidth: 520,
                                  title: Text(
                                    'LOAD TEST GAME?',
                                    style:
                                        ClubBlackoutTheme.bulletinHeaderStyle(
                                            accent),
                                  ),
                                  content: Text(
                                    'Creates (or overwrites) a test save with one of each role, then loads it.',
                                    style: ClubBlackoutTheme.bulletinBodyStyle(
                                        cs.onSurface),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            cs.onSurface.withValues(alpha: 0.7),
                                      ),
                                      child: Text(
                                        'CANCEL',
                                        style: ClubBlackoutTheme.headingStyle
                                            .copyWith(
                                          fontSize: 13,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ClubBlackoutTheme.neonButtonStyle(
                                          accent,
                                          isPrimary: true),
                                      child: Text(
                                        'LOAD',
                                        style: ClubBlackoutTheme.headingStyle
                                            .copyWith(
                                          fontSize: 13,
                                          letterSpacing: 1.2,
                                          color: ClubBlackoutTheme.pureBlack,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm != true) return;
                            if (!context.mounted) return;

                            showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const BulletinDialogShell(
                                accent: ClubBlackoutTheme.neonBlue,
                                maxWidth: 360,
                                title: SizedBox.shrink(),
                                content: SizedBox(
                                  height: 72,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: ClubBlackoutTheme.neonGreen,
                                    ),
                                  ),
                                ),
                              ),
                            );

                            try {
                              final saves = await widget.engine.getSavedGames();
                              final existing = saves
                                  .where((s) => s.name == _testSaveName)
                                  .firstOrNull;

                              await widget.engine
                                  .createTestGame(fullRoster: true);
                              await widget.engine.startGame();
                              await widget.engine.saveGame(
                                _testSaveName,
                                overwriteId: existing?.id,
                              );

                              // Prefer the known id (if overwriting), else re-query.
                              String? saveId = existing?.id;
                              if (saveId == null) {
                                final saves2 =
                                    await widget.engine.getSavedGames();
                                final created = saves2
                                    .where((s) => s.name == _testSaveName)
                                    .toList()
                                  ..sort(
                                      (a, b) => b.savedAt.compareTo(a.savedAt));
                                saveId = created.firstOrNull?.id;
                              }

                              if (saveId != null) {
                                await widget.engine.loadGame(saveId);
                              }

                              if (!context.mounted) return;
                              navigator.pop(); // progress dialog
                              await _refresh();
                              if (!context.mounted) return;
                              setState(() => _selectedSaveId = saveId);
                              navigator.pop(true);
                              widget.engine.showToast('Test game loaded.');
                            } catch (_) {
                              if (!context.mounted) return;
                              navigator.pop(); // progress dialog
                              widget.engine
                                  .showToast('Failed to load test game.');
                              await _refresh();
                            }
                          },
                    child: DecoratedBox(
                      decoration: ClubBlackoutTheme.bulletinItemDecoration(
                        color: ClubBlackoutTheme.neonGreen,
                        opacity: 0.10,
                      ),
                      child: Padding(
                        padding: ClubBlackoutTheme.fieldPaddingLoose,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.science_rounded,
                              color: ClubBlackoutTheme.neonGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'LOAD TEST GAME (DEV MODE)',
                                style: ClubBlackoutTheme.glowTextStyle(
                                  base: ClubBlackoutTheme.headingStyle.copyWith(
                                    fontSize: 14,
                                    color: cs.onSurface,
                                  ),
                                  color: ClubBlackoutTheme.neonGreen,
                                  fontWeight: FontWeight.w900,
                                  glowIntensity: 0.8,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: ClubBlackoutTheme.neonGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      color: cs.onSurface,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                    decoration: ClubBlackoutTheme.neonInputDecoration(
                      context,
                      hint: 'ENTER SAVE IDENTIFIER...',
                      color: accent,
                      icon: Icons.terminal_rounded,
                    ).copyWith(
                      labelText: 'COMMAND: SAVE_DATA',
                      labelStyle: ClubBlackoutTheme.headingStyle.copyWith(
                        color: accent.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        style: ClubBlackoutTheme.neonButtonStyle(accent,
                            isPrimary: true),
                        onPressed: () => _save(),
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          'SAVE NEW',
                          style: ClubBlackoutTheme.headingStyle.copyWith(
                            fontSize: 12,
                            letterSpacing: 1.0,
                            color: ClubBlackoutTheme.pureBlack,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        style: ClubBlackoutTheme.neonButtonStyle(
                          accent,
                          isPrimary: false,
                        ),
                        onPressed: _selectedSaveId == null
                            ? null
                            : () => _save(overwriteId: _selectedSaveId),
                        icon: const Icon(Icons.save_as_rounded),
                        label: Text(
                          'OVERWRITE SELECTED',
                          style: ClubBlackoutTheme.headingStyle.copyWith(
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 16,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved games',
                    style: ClubBlackoutTheme.bulletinBodyStyle(cs.onSurface)
                        .copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_saves.isEmpty)
                    Text(
                      'No saves yet.',
                      style: ClubBlackoutTheme.bulletinBodyStyle(
                              cs.onSurfaceVariant)
                          .copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _saves.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = _saves[index];
                          final selected = s.id == _selectedSaveId;

                          return InkWell(
                            onTap: () => setState(() => _selectedSaveId = s.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration:
                                  ClubBlackoutTheme.bulletinItemDecoration(
                                color: selected ? accent : cs.outline,
                                opacity: selected ? 0.20 : 0.05,
                              ).copyWith(
                                border: Border(
                                  left: BorderSide(
                                    color:
                                        selected ? accent : Colors.transparent,
                                    width: 4,
                                  ),
                                  right: BorderSide(
                                      color: accent.withValues(alpha: 0.1),
                                      width: 1),
                                  top: BorderSide(
                                      color: accent.withValues(alpha: 0.1),
                                      width: 1),
                                  bottom: BorderSide(
                                      color: accent.withValues(alpha: 0.1),
                                      width: 1),
                                ),
                              ),
                              child: Padding(
                                padding: ClubBlackoutTheme.fieldPaddingLoose,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'DATA SLOT #${(index + 1).toString().padLeft(2, '0')}',
                                          style: ClubBlackoutTheme.headingStyle
                                              .copyWith(
                                            fontSize: 10,
                                            color: selected
                                                ? accent
                                                : cs.onSurfaceVariant,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (selected)
                                          Text(
                                            'SELECTED_ACCESS_OK',
                                            style: ClubBlackoutTheme
                                                .headingStyle
                                                .copyWith(
                                              fontSize: 10,
                                              color: accent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      s.name.toUpperCase(),
                                      style: ClubBlackoutTheme.headingStyle
                                          .copyWith(
                                        fontSize: 15,
                                        color: cs.onSurface,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildInfoTag(
                                          cs,
                                          'DAY ${s.dayCount}',
                                          Icons.wb_sunny_rounded,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildInfoTag(
                                          cs,
                                          '${s.alivePlayers}/${s.totalPlayers} ALIVE',
                                          Icons.people_alt_rounded,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildInfoTag(
                                          cs,
                                          'PHASE: ${s.currentPhase.toUpperCase()}',
                                          Icons.access_time_rounded,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'TIMESTAMP: ${s.savedAt.toLocal().toString().toUpperCase()}',
                                      style:
                                          ClubBlackoutTheme.bulletinBodyStyle(
                                        cs.onSurfaceVariant
                                            .withValues(alpha: 0.8),
                                      ).copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

extension _FirstOrNullX<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
