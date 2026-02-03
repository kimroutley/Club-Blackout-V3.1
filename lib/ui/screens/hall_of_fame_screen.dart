import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../logic/hall_of_fame_service.dart';
import '../styles.dart';
import '../utils/export_file_service.dart';
import '../widgets/bulletin_dialog_shell.dart';
import '../widgets/club_alert_dialog.dart';
import '../widgets/neon_glass_card.dart';
import '../widgets/player_management_dialog.dart';

class HallOfFameScreen extends StatefulWidget {
  final bool isNight;
  const HallOfFameScreen({super.key, this.isNight = false});

  @override
  State<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends State<HallOfFameScreen> {
  bool _mergeMode = false;
  String? _mergeFromId;
  bool _showSuspended = false;

  void _exitMergeMode() {
    setState(() {
      _mergeMode = false;
      _mergeFromId = null;
    });
  }

  void _managePlayer(String playerId) {
    showDialog(
      context: context,
      builder: (context) => PlayerManagementDialog(playerId: playerId),
    );
  }

  Future<void> _confirmAndMerge({
    required BuildContext context,
    required String fromId,
    required String intoId,
    required String fromName,
    required String intoName,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return ClubAlertDialog(
          title: const Text('Merge profiles?'),
          content: Text(
            'Merge "$fromName" into "$intoName"?\n\nThis combines stats and deletes the source profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: ClubBlackoutTheme.neonGold,
                foregroundColor:
                    ClubBlackoutTheme.contrastOn(ClubBlackoutTheme.neonGold),
              ),
              child: const Text('MERGE'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await HallOfFameService.instance
        .mergeProfiles(fromId: fromId, intoId: intoId);
    _exitMergeMode();
  }

  void _showImportExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ImportExportDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    // Unified AppBar for both night and day modes
    AppBar buildAppBar() {
      return AppBar(
        title: Text(
          'HALL OF FAME',
          style: ClubBlackoutTheme.neonGlowTitle,
        ),
        centerTitle: true,
        backgroundColor: widget.isNight ? null : Colors.transparent,
        elevation: 0,
        iconTheme:
            widget.isNight ? null : const IconThemeData(color: Colors.white),
        actions: [
          if (!_mergeMode)
            IconButton(
              tooltip: 'Import / Export',
              icon: const Icon(Icons.import_export_rounded),
              onPressed: () => _showImportExportDialog(context),
            ),
          if (_mergeMode)
            TextButton(
              onPressed: _exitMergeMode,
              child: Text(
                widget.isNight ? 'Done' : 'DONE',
                style: TextStyle(
                  color: widget.isNight ? null : Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    if (widget.isNight) {
      return Scaffold(
        appBar: buildAppBar(),
        body: _buildBody(context, isNight: true),
      );
    }

    // Day Phase M3 conversion
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'Backgrounds/Club Blackout V2 Game Background.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: canPop ? buildAppBar() : null,
          body: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            child: _buildBody(context, isNight: false),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, {required bool isNight}) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListenableBuilder(
          listenable: HallOfFameService.instance,
          builder: (context, _) {
            final activeProfiles = HallOfFameService.instance.allProfiles;
            final suspendedProfiles =
                HallOfFameService.instance.suspendedProfiles;
            final profiles = _showSuspended ? suspendedProfiles : activeProfiles;

            if (profiles.isEmpty && !_showSuspended) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No legends yet.\nPlay complete games to record stats.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (suspendedProfiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          _showSuspended
                              ? 'SUSPENDED RECORDS'
                              : 'LEGENDS ONLY',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _showSuspended = !_showSuspended),
                          icon: Icon(
                            _showSuspended
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _showSuspended
                                ? 'Show Active'
                                : 'Show Paused (${suspendedProfiles.length})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_mergeMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Card(
                      elevation: 0,
                      color: cs.surfaceContainerHighest
                          .withValues(alpha: isNight ? 0.70 : 0.55),
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ClubBlackoutTheme.radiusMd),
                        side: BorderSide(
                            color: ClubBlackoutTheme.neonGold
                                .withValues(alpha: 0.35)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.merge_rounded,
                                color: ClubBlackoutTheme.neonGold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _mergeFromId == null
                                    ? 'Merge mode: tap a profile to pick the source.'
                                    : 'Merge mode: tap a profile to merge into (source selected).',
                                style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: _exitMergeMode,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final p = profiles[index];
                      final rank = index + 1;

                      final isMergeFrom = _mergeMode && _mergeFromId == p.id;
                      final isMergePickable = _mergeMode &&
                          (_mergeFromId == null || _mergeFromId != p.id);

                      return InkWell(
                        borderRadius:
                            BorderRadius.circular(ClubBlackoutTheme.radiusMd),
                        onLongPress: () {
                          if (!_mergeMode) {
                            _managePlayer(p.id);
                          }
                        },
                        onDoubleTap: () {
                          if (!_mergeMode) {
                            setState(() {
                              _mergeMode = true;
                              _mergeFromId = p.id;
                            });
                          }
                        },
                        onTap: !_mergeMode
                            ? null
                            : () {
                                if (_mergeFromId == null) {
                                  setState(() => _mergeFromId = p.id);
                                  return;
                                }
                                if (_mergeFromId == p.id) return;

                                final fromId = _mergeFromId!;
                                final fromIndex =
                                    profiles.indexWhere((x) => x.id == fromId);
                                if (fromIndex == -1) {
                                  _exitMergeMode();
                                  return;
                                }

                                final fromProfile = profiles[fromIndex];
                                _confirmAndMerge(
                                  context: context,
                                  fromId: fromId,
                                  intoId: p.id,
                                  fromName: fromProfile.name,
                                  intoName: p.name,
                                );
                              },
                        child: NeonGlassCard(
                          glowColor: isMergeFrom
                              ? ClubBlackoutTheme.neonGold
                              : (index == 0
                                  ? ClubBlackoutTheme.neonGold
                                  : (index < 3
                                      ? ClubBlackoutTheme.neonSilver
                                      : cs.outline.withValues(alpha: 0.3))),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                _RankBadge(rank: rank, highlight: index < 3),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: cs.onSurface,
                                          shadows: index < 3
                                              ? [
                                                  Shadow(
                                                    color: (index == 0
                                                            ? ClubBlackoutTheme
                                                                .neonGold
                                                            : cs.onSurface)
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                  )
                                                ]
                                              : null,
                                        ),
                                      ),
                                      if (_mergeMode)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            isMergeFrom
                                                ? 'Merge FROM'
                                                : (_mergeFromId == null
                                                    ? 'Tap to pick as source'
                                                    : (isMergePickable
                                                        ? 'Tap to merge INTO'
                                                        : '')),
                                            style: TextStyle(
                                              color: ClubBlackoutTheme.neonGold
                                                  .withValues(alpha: 0.95),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          _StatBadge(
                                              icon: Icons.casino_rounded,
                                              label: '${p.totalGames} Games',
                                              color: Colors.blueAccent),
                                          _StatBadge(
                                              icon: Icons.emoji_events_rounded,
                                              label: '${p.totalWins} Wins',
                                              color:
                                                  ClubBlackoutTheme.neonGold),
                                          if (p.totalGames > 0)
                                            _StatBadge(
                                                icon: Icons.pie_chart_rounded,
                                                label:
                                                    '${(p.winRate * 100).toInt()}% Rate',
                                                color: Colors.greenAccent),
                                          if (p.totalHostedGames > 0)
                                            _StatBadge(
                                                icon: Icons.mic_rounded,
                                                label:
                                                    '${p.totalHostedGames} Hosted',
                                                color:
                                                    ClubBlackoutTheme.neonPink),
                                          if (p.totalHostedGames > 0)
                                            _StatBadge(
                                              icon: Icons
                                                  .local_fire_department_rounded,
                                              label:
                                                  '${(p.dealerWinRateWhileHosting * 100).toInt()}% Dealer (host)',
                                              color: ClubBlackoutTheme.neonRed,
                                              tooltip:
                                                  'Dealer wins while hosting: ${p.hostedDealerWins}/${p.totalHostedGames}\nParty wins while hosting: ${p.hostedPartyWins}/${p.totalHostedGames}\nOther wins while hosting: ${p.hostedOtherWins}/${p.totalHostedGames}',
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (p.awardStats.isNotEmpty)
                                  Tooltip(
                                    message: 'Awards',
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.star_rounded,
                                          color: ClubBlackoutTheme.neonGold,
                                          size: 20),
                                    ),
                                  ),
                                if (!_mergeMode)
                                  IconButton(
                                    tooltip: 'Delete profile',
                                    icon: Icon(Icons.delete_outline_rounded,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.65)),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) {
                                          return ClubAlertDialog(
                                            title:
                                                const Text('Delete profile?'),
                                            content: Text(
                                                'Delete "${p.name}" from the Hall of Fame?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('CANCEL')),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      ClubBlackoutTheme.neonRed,
                                                  foregroundColor:
                                                      ClubBlackoutTheme
                                                          .contrastOn(
                                                              ClubBlackoutTheme
                                                                  .neonRed),
                                                ),
                                                child: const Text('DELETE'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (ok == true) {
                                        await HallOfFameService.instance
                                            .deleteProfile(p.id);
                                      }
                                    },
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
            );
          },
        ),
      ),
    );
  }
}

class _ImportExportDialog extends StatefulWidget {
  @override
  State<_ImportExportDialog> createState() => _ImportExportDialogState();
}

class _ImportExportDialogState extends State<_ImportExportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importController = TextEditingController();
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      setState(() {
        _statusMessage = 'Data copied to clipboard!';
        _isError = false;
      });
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _importController.text = data!.text!;
      });
    }
  }

  Future<void> _pickImportFile() async {
    try {
      final content = await ExportFileService.pickAndReadFile();

      if (content != null) {
        setState(() {
          _importController.text = content;
          _statusMessage = 'File loaded.';
          _isError = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error reading file: $e';
        _isError = true;
      });
    }
  }

  Future<void> _runImport() async {
    final text = _importController.text.trim();
    if (text.isEmpty) return;

    try {
      final count =
          await HallOfFameService.instance.importProfilesFromJson(text);
      if (mounted) {
        setState(() {
          _statusMessage = 'Success! Updated/Added $count profiles.';
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Import failed. Invalid data format.';
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = ClubBlackoutTheme.neonBlue;

    return BulletinDialogShell(
      accent: accent,
      maxWidth: 600,
      padding: EdgeInsets.zero,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATA TRANSFER',
            style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: accent,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
            indicatorColor: accent,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'EXPORT (BACKUP)'),
              Tab(text: 'IMPORT (RESTORE)'),
            ],
          ),
        ],
      ),
      content: SizedBox(
        height: 350,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildExportTab(context),
            _buildImportTab(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }

  Widget _buildExportTab(BuildContext context) {
    final jsonStr = HallOfFameService.instance.exportProfilesToJson();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Transfer your Hall of Fame to another device.',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Copy the code below and paste it into the Import tab on the new device.',
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.1)),
              ),
              child: SelectableText(
                jsonStr,
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_statusMessage != null && _tabController.index == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _statusMessage!,
                style: const TextStyle(
                    color: ClubBlackoutTheme.neonGreen,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _copyToClipboard(jsonStr),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('COPY'),
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonBlue,
                    isPrimary: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Share.share(jsonStr,
                      subject: 'Club Blackout Hall of Fame Stats'),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('SHARE'),
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonPurple,
                    isPrimary: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paste data from another device.',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This will merge stats for existing players (keeping the higher play count) and add new ones.',
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _importController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                hintText: 'Paste JSON data here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: cs.onSurface.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_statusMessage != null && _tabController.index == 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                    color: _isError
                        ? ClubBlackoutTheme.neonRed
                        : ClubBlackoutTheme.neonGreen,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste_rounded),
                  label: const Text('PASTE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImportFile,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('OPEN FILE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _runImport,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('IMPORT'),
                  style: ClubBlackoutTheme.neonButtonStyle(
                    ClubBlackoutTheme.neonBlue,
                    isPrimary: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool highlight;
  const _RankBadge({required this.rank, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlight
            ? ClubBlackoutTheme.neonGold.withValues(alpha: 0.18)
            : cs.onSurface.withValues(alpha: 0.10),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: highlight
              ? ClubBlackoutTheme.neonGold
              : cs.onSurface.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? tooltip;

  const _StatBadge(
      {required this.icon,
      required this.label,
      required this.color,
      this.tooltip});

  @override
  Widget build(BuildContext context) {
    final badge = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final tip = tooltip?.trim();
    if (tip == null || tip.isEmpty) return badge;
    return Tooltip(message: tip, child: badge);
  }
}
