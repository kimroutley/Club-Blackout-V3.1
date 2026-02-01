import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../logic/game_engine.dart';
import '../../logic/hall_of_fame_service.dart';
import '../../models/player.dart';
import '../../services/dynamic_theme_service.dart';
import '../styles.dart';
import '../utils/player_sort.dart';
import '../widgets/bulletin_dialog_shell.dart';
import '../widgets/game_toast_listener.dart';
// M3: Removed neon widgets
// import '../widgets/neon_background.dart';
// import '../widgets/neon_page_scaffold.dart';
// import '../widgets/neon_section_header.dart';
import '../widgets/player_tile.dart';
import '../widgets/role_assignment_dialog.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final GameEngine gameEngine;

  const LobbyScreen({super.key, required this.gameEngine});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final TextEditingController _hostController;
  late final FocusNode _nameFocus;
  late final FocusNode _hostFocus;
  final GlobalKey _guestNameFieldKey = GlobalKey();
  OptionsViewOpenDirection _optionsDirection = OptionsViewOpenDirection.down;

  late final AnimationController _notificationController;
  late Animation<Offset> _notificationOffset;
  String? _notificationMessage;
  Color? _notificationColor;

  static const String _quickTestSaveName = 'Quick Test Game';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _hostController =
        TextEditingController(text: widget.gameEngine.hostName ?? '');
    _nameFocus = FocusNode();
    _hostFocus = FocusNode();
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) {
        _recomputeAutocompleteDirection();
      }
    });
    _notificationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _notificationOffset = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _notificationController,
      curve: Curves.elasticOut,
    ));
  }

  void _recomputeAutocompleteDirection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderObject =
          _guestNameFieldKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox) return;

      final media = MediaQuery.of(context);
      final screenHeight = media.size.height;
      final keyboard = media.viewInsets.bottom;

      final fieldOffset = renderObject.localToGlobal(Offset.zero);
      final fieldTop = fieldOffset.dy;
      final fieldBottom = fieldOffset.dy + renderObject.size.height;

      final availableDown = screenHeight - keyboard - fieldBottom - 12;
      final availableUp = fieldTop - media.padding.top - 12;

      final next = (availableDown < 180 && availableUp > availableDown)
          ? OptionsViewOpenDirection.up
          : OptionsViewOpenDirection.down;

      if (next != _optionsDirection) {
        setState(() => _optionsDirection = next);
      }
    });
  }

  double _maxAutocompleteOptionsHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    const desired = 260.0;

    final renderObject = _guestNameFieldKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return desired;

    final screenHeight = media.size.height;
    final keyboard = media.viewInsets.bottom;

    final fieldOffset = renderObject.localToGlobal(Offset.zero);
    final fieldTop = fieldOffset.dy;
    final fieldBottom = fieldOffset.dy + renderObject.size.height;

    final availableDown = screenHeight - keyboard - fieldBottom - 12;
    final availableUp = fieldTop - media.padding.top - 12;
    final available = _optionsDirection == OptionsViewOpenDirection.up
        ? availableUp
        : availableDown;

    // Keep it usable but never huge.
    return math.max(120.0, math.min(desired, available));
  }

  @override
  void dispose() {
    _controller.dispose();
    _hostController.dispose();
    _nameFocus.dispose();
    _hostFocus.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  void _showNotification(String msg, {Color? color}) {
    setState(() {
      _notificationMessage = msg;
      _notificationColor = color;
    });
    _notificationController.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _notificationController.reverse();
      }
    });
  }

  void _showUndoSnackBar({
    required String message,
    required VoidCallback onUndo,
    Color? accent,
  }) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.surface.withValues(alpha: 0.96),
        content: Text(
          message,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: accent ?? ClubBlackoutTheme.neonBlue,
          onPressed: onUndo,
        ),
      ),
    );
  }

  void _removeGuestWithUndo(GameEngine engine, Player player) {
    final existingIndex = engine.players.indexWhere((p) => p.id == player.id);
    final snapshot = Player.fromJson(player.toJson(), player.role);

    engine.removePlayer(player.id);
    _showUndoSnackBar(
      message: 'Removed "${snapshot.name}".',
      accent: ClubBlackoutTheme.neonRed,
      onUndo: () {
        final ok = engine.restorePlayer(snapshot, index: existingIndex);
        if (!ok) {
          _showNotification(
            'Undo failed: name is already taken.',
            color: ClubBlackoutTheme.neonRed,
          );
          return;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gameEngine,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final engine = widget.gameEngine;
        final guests = sortedPlayersByDisplayName(engine.guests);

        // Strict M3 TabBar with neon indicators
        final tabBar = TabBar(
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_2_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Guests'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_suggest_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Setup'),
                ],
              ),
            ),
          ],
          labelStyle: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
          splashFactory: InkSparkle.splashFactory,
          dividerColor: Colors.transparent,
          indicatorColor: ClubBlackoutTheme.neonBlue,
          indicatorWeight: 3,
        );

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ClubBlackoutTheme.neonPurple.withValues(alpha: 0.25),
                          ClubBlackoutTheme.neonPink.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: ClubBlackoutTheme.neonPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Lobby'),
                ],
              ),
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 3,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: tabBar,
              ),
            ),
            body: SafeArea(
              top: false,
              child: Stack(
                children: [
                  // Main Content
                  TabBarView(
                    children: [
                          _buildGuestsTab(context, cs, engine, guests),
                      _buildGameSetupTab(context, cs, engine, guests),
                    ],
                  ),

                  // Overlays
                  GameToastListener(engine: engine),
                  _buildNotificationOverlay(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationOverlay(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardOpen) return const SizedBox.shrink();
    if (_notificationMessage == null) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _notificationOffset,
        child: Padding(
          padding: ClubBlackoutTheme.rowPadding,
          child: _buildNotificationCard(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    if (_notificationMessage == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final color = _notificationColor ?? cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _notificationMessage!,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsTab(
    BuildContext context,
    ColorScheme cs,
    GameEngine engine,
    List<Player> guests,
  ) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final totalGuests = guests.length;

    return Column(
      children: [
        if (engine.players.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ClubBlackoutTheme.neonBlue.withValues(alpha: 0.1),
                  ClubBlackoutTheme.neonPurple.withValues(alpha: 0.08),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    size: 20,
                    color: ClubBlackoutTheme.neonBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$totalGuests Guest${totalGuests != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showClearAllConfirm(context, engine),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: keyboardOpen
              ? const SizedBox.shrink()
              : (guests.isEmpty)
                  ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                colors: [
                                  ClubBlackoutTheme.neonPurple.withValues(alpha: 0.15),
                                  ClubBlackoutTheme.neonPurple.withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_add_outlined,
                                size: 64, color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Guests Yet',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add at least 4 guests to start the game',
                            style: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showSavedPlayersPicker(context),
                                icon: const Icon(Icons.history_rounded, size: 18),
                                label: const Text('From History'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () async {
                                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                                  final text = data?.text ?? '';
                                  if (!context.mounted) return;
                                  _addGuestsFromText(context, text);
                                },
                                icon: const Icon(Icons.content_paste_rounded, size: 18),
                                label: const Text('Paste List'),
                              ),
                            ],
                          ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: guests.length,
                      itemBuilder: (context, index) {
                        final player = guests[index];

                        return Dismissible(
                          key: Key(player.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) =>
                              _removeGuestWithUndo(engine, player),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cs.errorContainer.withValues(alpha: 0.3),
                                  cs.errorContainer,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_rounded,
                                  color: cs.onErrorContainer,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: cs.onErrorContainer,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: Card(
                            elevation: 1,
                            color: cs.surface,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            child: PlayerTile(
                              player: player,
                              gameEngine: engine,
                              isCompact: true,
                              subtitleOverride: player.role.id == 'temp'
                                  ? 'Awaiting assignment'
                                  : player.role.name,
                              showEffectChips: false,
                              wrapInCard: false,
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 20),
                                onPressed: () => _renameGuest(context, player),
                                tooltip: 'Rename Guest',
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Add',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHostNameRow(context),
                const SizedBox(height: 12),
                _buildAddPlayerRow(context),
                const SizedBox(height: 8),
                Text(
                  'Tip: Press Enter to add quickly, or paste a list of names',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHostNameRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasHost = widget.gameEngine.hostName?.isNotEmpty ?? false;
    
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _hostController,
            focusNode: _hostFocus,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Host Name (Optional)',
              hintText: 'Who\'s hosting?',
              prefixIcon: Icon(
                hasHost ? Icons.person : Icons.person_outline,
                color: hasHost ? cs.primary : null,
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: cs.outline.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: cs.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: cs.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (val) => _setHostName(context, val),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () => _setHostName(context, _hostController.text),
          icon: const Icon(Icons.check_rounded),
          tooltip: 'Set host name',
          style: IconButton.styleFrom(
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  void _setHostName(BuildContext context, String raw) {
    try {
      final prev = widget.gameEngine.hostName;
      widget.gameEngine.setHostName(raw);
      final name = widget.gameEngine.hostName;
      _hostController.text = name ?? '';

      // Offer undo for set/clear changes.
      final changed = (prev ?? '') != (name ?? '');
      if (changed) {
        widget.gameEngine.showToast(
          name == null ? 'Host cleared.' : 'Host set to $name.',
          title: 'Host',
          actionLabel: 'UNDO',
          onAction: () {
            try {
              widget.gameEngine.setHostName(prev ?? '');
              _hostController.text = widget.gameEngine.hostName ?? '';
            } catch (_) {
              widget.gameEngine
                  .showToast('Undo failed: name is already taken.');
            }
          },
        );
      } else {
        widget.gameEngine.showToast(
          name == null ? 'Host cleared.' : 'Host set to $name.',
          title: 'Host',
        );
      }
      _hostFocus.unfocus();
    } catch (e) {
      var msg = e.toString();
      msg = msg.replaceFirst(RegExp(r'^.*Exception: '), '');
      msg = msg.replaceFirst(RegExp(r'^.*ArgumentError: '), '');
      widget.gameEngine.showToast(msg);
    }
  }

  Widget _buildGameSetupTab(
    BuildContext context,
    ColorScheme cs,
    GameEngine engine,
    List<Player> players,
  ) {
    const showTestTools = kDebugMode || bool.fromEnvironment('SHOW_TEST_GAME');

    return Column(
      children: [
        // Top Card: Main Action & Info
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ClubBlackoutTheme.neonGreen.withValues(alpha: 0.12),
                ClubBlackoutTheme.neonBlue.withValues(alpha: 0.1),
                ClubBlackoutTheme.neonPurple.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: players.length < 4 ? [
                            ClubBlackoutTheme.neonOrange.withValues(alpha: 0.25),
                            ClubBlackoutTheme.neonRed.withValues(alpha: 0.2),
                          ] : [
                            ClubBlackoutTheme.neonGreen.withValues(alpha: 0.25),
                            ClubBlackoutTheme.neonBlue.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (players.length < 4 ? ClubBlackoutTheme.neonOrange : ClubBlackoutTheme.neonGreen).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        players.length < 4 ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                        size: 28,
                        color: players.length < 4 ? ClubBlackoutTheme.neonOrange : ClubBlackoutTheme.neonGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            players.length < 4 ? 'Need More Guests' : 'Ready to Start!',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            players.length < 4 
                              ? 'Minimum 4 guests required • ${players.length} added'
                              : '${players.length} guests ready for role assignment',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Button
                FilledButton.icon(
                  onPressed: players.length < 4
                      ? null
                      : () => _showRoleAssignment(context),
                  label: const Text('ASSIGN ROLES & START GAME'),
                  icon: const Icon(Icons.casino_rounded, size: 22),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (engine.lastArchivedGameBlobJson != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLastGameSnapshotCard(context, cs, engine),
          ),
        if (engine.lastArchivedGameBlobJson != null)
          const SizedBox(height: 12),

        // Middle: Player List (Expanded)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline_rounded, 
                        size: 20, 
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Guest Roster',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${players.length}',
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                Expanded(
                  child: players.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 56,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No guests added yet',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Go to the Guests tab to add players',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: players.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = players[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(alpha: 0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: PlayerTile(
                                player: p,
                                gameEngine: engine,
                                isCompact: true,
                                subtitleOverride: p.role.id == 'temp'
                                    ? 'Awaiting assignment'
                                    : p.role.name,
                                showEffectChips: false,
                                wrapInCard: false,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Bottom: Test Tools (if enabled)
        if (showTestTools) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.orange.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                Text('DEBUG TOOLS',
                    style: TextStyle(color: cs.onSurface, fontSize: 10)),
                Wrap(spacing: 8, children: [
                  TextButton(
                      onPressed: () =>
                          _loadOrCreateQuickTestGame(context, recreate: false),
                      child: const Text('Load')),
                  TextButton(
                      onPressed: () =>
                          _loadOrCreateQuickTestGame(context, recreate: true),
                      child: const Text('Reset')),
                ])
              ]),
            ),
          ),
        ],

        SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
      ],
    );
  }

  Widget _buildLastGameSnapshotCard(
    BuildContext context,
    ColorScheme cs,
    GameEngine engine,
  ) {
    final raw = engine.lastArchivedGameBlobJson;
    Map<String, dynamic>? blob;
    if (raw != null) {
      try {
        blob = (jsonDecode(raw) as Map).cast<String, dynamic>();
      } catch (_) {
        blob = null;
      }
    }

    final savedAtStr = blob?['savedAt'] as String?;
    final savedAt = savedAtStr == null ? null : DateTime.tryParse(savedAtStr);
    final winner = blob?['winner'] as String?;
    final winMessage = blob?['winMessage'] as String?;
    final dayCount = blob?['dayCount'];

    final playersJson = blob?['players'];
    int totalPlayers = 0;
    int alivePlayers = 0;
    if (playersJson is List) {
      final enabled = playersJson.whereType<Map>().map((m) => m.cast<String, dynamic>()).where(
            (p) => (p['isEnabled'] as bool?) ?? true,
          );
      totalPlayers = enabled
          .where((p) => (p['roleId'] as String?) != GameEngine.hostRoleId)
          .length;
      alivePlayers = enabled
          .where((p) => (p['roleId'] as String?) != GameEngine.hostRoleId)
          .where((p) => (p['isAlive'] as bool?) ?? true)
          .length;
    }

    const accent = ClubBlackoutTheme.neonBlue;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.archive_rounded, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Game Snapshot',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        savedAt == null
                            ? 'Saved when you reset to the lobby'
                            : 'Saved: ${savedAt.toLocal()}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _snapshotChip(
                  cs,
                  label: 'Alive',
                  value: '$alivePlayers/$totalPlayers',
                  color: ClubBlackoutTheme.neonGreen,
                ),
                _snapshotChip(
                  cs,
                  label: 'Day',
                  value: '${dayCount ?? 0}',
                  color: ClubBlackoutTheme.neonPurple,
                ),
                if (winner != null)
                  _snapshotChip(
                    cs,
                    label: 'Winner',
                    value: winner,
                    color: ClubBlackoutTheme.neonPink,
                  ),
              ],
            ),
            if (winMessage != null && winMessage.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                winMessage,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: blob == null
                      ? null
                      : () => _showArchivedGameSnapshotDialog(context, engine),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('VIEW'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: raw == null
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: raw));
                          if (!context.mounted) return;
                          engine.showToast('Snapshot copied to clipboard.',
                              title: 'Copied');
                        },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('COPY JSON'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear snapshot',
                  onPressed: () async {
                    await engine.clearArchivedGameBlob();
                    if (!context.mounted) return;
                    engine.showToast('Last game snapshot cleared.',
                        title: 'Snapshot');
                  },
                  icon: Icon(Icons.delete_outline_rounded,
                      color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _snapshotChip(
    ColorScheme cs, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Future<void> _showArchivedGameSnapshotDialog(
    BuildContext context,
    GameEngine engine,
  ) async {
    final raw = engine.lastArchivedGameBlobJson;
    if (raw == null) return;

    Map<String, dynamic> blob;
    try {
      blob = (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      engine.showToast('Snapshot is corrupted.', title: 'Snapshot');
      return;
    }

    final cs = Theme.of(context).colorScheme;
    const accent = ClubBlackoutTheme.neonBlue;

    final savedAt = DateTime.tryParse((blob['savedAt'] as String?) ?? '');
    final winner = blob['winner'] as String?;
    final winMessage = blob['winMessage'] as String?;
    final lastNightHostRecap = blob['lastNightHostRecap'] as String?;
    final lastNightSummary = blob['lastNightSummary'] as String?;
    final stats = (blob['lastNightStats'] is Map)
        ? (blob['lastNightStats'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final playersJson = blob['players'];
    final rows = <String>[];
    if (playersJson is List) {
      for (final entry in playersJson.whereType<Map>()) {
        final p = entry.cast<String, dynamic>();
        final roleId = (p['roleId'] as String?) ?? 'temp';
        if (roleId == GameEngine.hostRoleId) continue;
        final roleName =
            engine.roleRepository.getRoleById(roleId)?.name ?? roleId;
        final name = (p['name'] as String?) ?? 'Unknown';
        final alive = (p['isAlive'] as bool?) ?? true;
        final enabled = (p['isEnabled'] as bool?) ?? true;
        if (!enabled) continue;
        rows.add('${alive ? 'ALIVE' : 'DEAD'} • $name — $roleName');
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return BulletinDialogShell(
          accent: accent,
          maxWidth: 700,
          title: Text(
            'LAST GAME SNAPSHOT',
            style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  savedAt == null ? 'Saved snapshot' : 'Saved: ${savedAt.toLocal()}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (winner != null) ...[
                  Text(
                    'Winner: $winner',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  if (winMessage != null && winMessage.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      winMessage,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.9),
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
                if ((lastNightHostRecap ?? '').trim().isNotEmpty) ...[
                  Text(
                    'Host recap:',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastNightHostRecap!,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.9),
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if ((lastNightSummary ?? '').trim().isNotEmpty) ...[
                  Text(
                    'Public summary:',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastNightSummary!,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.9),
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (stats.isNotEmpty) ...[
                  Text(
                    'Night stats:',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stats.entries.map((e) => '• ${e.key}: ${e.value}').join('\n'),
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  'Players:',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rows.isEmpty ? 'No player data.' : rows.join('\n'),
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.75),
              ),
              child: const Text('CLOSE'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: ClubBlackoutTheme.neonButtonStyle(accent, isPrimary: true),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: raw));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                engine.showToast('Snapshot copied to clipboard.', title: 'Copied');
              },
              child: const Text('COPY JSON'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameGuest(BuildContext context, Player player) async {
    final controller = TextEditingController(text: player.name);
    final cs = Theme.of(context).colorScheme;
    final prevName = player.name;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        const accent = ClubBlackoutTheme.neonPink;
        return BulletinDialogShell(
          accent: accent,
          maxWidth: 520,
          title: Text(
            'RENAME GUEST',
            style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: cs.onSurface),
            decoration: ClubBlackoutTheme.neonInputDecoration(
              context,
              hint: 'Enter new name',
              color: accent,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.7),
              ),
              child: const Text('CANCEL'),
            ),
            ClubBlackoutTheme.hGap8,
            FilledButton(
              style: ClubBlackoutTheme.neonButtonStyle(
                accent,
                isPrimary: true,
              ),
              onPressed: () {
                try {
                  widget.gameEngine.renamePlayer(player.id, controller.text);
                  Navigator.pop(ctx);

                  final nextName = controller.text.trim();
                  if (nextName.isNotEmpty && nextName != prevName) {
                    _showUndoSnackBar(
                      message: 'Renamed "$prevName" to "$nextName".',
                      accent: accent,
                      onUndo: () {
                        try {
                          widget.gameEngine.renamePlayer(player.id, prevName);
                        } catch (_) {
                          _showNotification(
                            'Undo failed: name is already taken.',
                            color: ClubBlackoutTheme.neonRed,
                          );
                        }
                      },
                    );
                  } else {
                    _showNotification('Guest renamed to "$nextName"');
                  }
                } catch (e) {
                  _showNotification(
                    e
                        .toString()
                        .replaceFirst('Exception: ', '')
                        .replaceFirst('ArgumentError: ', ''),
                    color: ClubBlackoutTheme.neonRed,
                  );
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadOrCreateQuickTestGame(
    BuildContext context, {
    required bool recreate,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        const accent = ClubBlackoutTheme.neonOrange;
        return BulletinDialogShell(
          accent: accent,
          maxWidth: 560,
          title: Text(
            recreate ? 'RECREATE TEST' : 'LOAD TEST',
            style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
          ),
          content: Text(
            recreate
                ? 'This will overwrite the "$_quickTestSaveName" save with a fresh deterministic game and jump into gameplay.'
                : 'This will load the "$_quickTestSaveName" save (or create it if missing) and jump into gameplay.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.7),
              ),
              child: const Text('CANCEL'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: ClubBlackoutTheme.neonButtonStyle(accent, isPrimary: true),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('CONTINUE'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    bool ok = true;
    Object? error;

    await _runBlockingProgressDialog(context, () async {
      final engine = widget.gameEngine;
      final saves = await engine.getSavedGames();
      saves.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      final existing =
          saves.where((s) => s.name == _quickTestSaveName).firstOrNull;

      if (!recreate && existing != null) {
        ok = await engine.loadGame(existing.id);
        if (!ok) {
          throw StateError('Failed to load quick test save.');
        }
        return;
      }

      // Create a fresh deterministic game, start it, and persist it as a single slot.
      await engine.createTestGame(fullRoster: false);
      await engine.startGame();
      await engine.saveGame(_quickTestSaveName, overwriteId: existing?.id);
      
      // Update theme based on assigned roles
      if (context.mounted) {
        final themeService = Provider.of<DynamicThemeService>(context, listen: false);
        final activeRoles = engine.guests.map((p) => p.role).toList();
        if (activeRoles.isNotEmpty) {
          await themeService.updateFromBackgroundAndRoles(
            'Backgrounds/Club Blackout V2 Game Background.png',
            activeRoles,
          );
        }
      }
    }).catchError((e) {
      ok = false;
      error = e;
    });

    if (!context.mounted) return;
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
            content:
                Text('Could not load test game: ${error ?? 'Unknown error'}')),
      );
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute(
          builder: (_) => GameScreen(gameEngine: widget.gameEngine)),
    );
  }

  Future<void> _runBlockingProgressDialog(
    BuildContext context,
    Future<void> Function() op,
  ) async {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);

    // Show themed progress dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: ClubBlackoutTheme.neonFrame(
                color: ClubBlackoutTheme.neonPink,
                opacity: 0.9,
                showGlow: true,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: ClubBlackoutTheme.neonPink,
                      strokeWidth: 3,
                    ),
                  ),
                  ClubBlackoutTheme.gap24,
                  Text(
                    'Processing',
                    style: ClubBlackoutTheme.glowTextStyle(
                      base: ClubBlackoutTheme.headingStyle,
                      color: ClubBlackoutTheme.neonPink,
                      fontSize: 22,
                    ),
                  ),
                  ClubBlackoutTheme.gap8,
                  Text(
                    'Please wait',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      await op();
    } finally {
      if (mounted) {
        navigator.pop();
      }
    }
  }

  Widget _buildAddPlayerRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<String>(
                    optionsViewOpenDirection: _optionsDirection,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return HallOfFameService.instance.allProfiles
                          .map((p) => p.name)
                          .where((name) => name
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _addGuestsFromText(context, selection);
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      _recomputeAutocompleteDirection();
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          color: cs.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: _maxAutocompleteOptionsHeight(context),
                            ),
                            child: Container(
                              width: constraints.maxWidth,
                              margin: const EdgeInsets.only(top: 8),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (context, index) =>
                                    Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      option,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    leading: Icon(Icons.history_rounded, 
                                      color: cs.primary,
                                      size: 20,
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      controller.addListener(() {
                        if (_controller.text != controller.text) {
                          _controller.text = controller.text;
                        }
                      });
                      _controller.addListener(() {
                        if (controller.text != _controller.text) {
                          controller.text = _controller.text;
                        }
                      });

                      return TextField(
                        key: _guestNameFieldKey,
                        controller: controller,
                        focusNode: focusNode,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Guest Name',
                          hintText: 'Add a guest...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: cs.outline.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: cs.surface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          prefixIcon: const Icon(Icons.person_add_rounded),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (val) {
                          _addGuestsFromText(context, val);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _addGuestsFromText(context, _controller.text),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showSavedPlayersPicker(context),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('From History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text ?? '';
                  if (!context.mounted) return;
                  _addGuestsFromText(context, text);
                },
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: const Text('Paste List'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addGuestsFromText(BuildContext context, String raw) {
    final names = _parseGuestNames(raw);
    if (names.isEmpty) {
      _nameFocus.requestFocus();
      return;
    }

    var added = 0;
    var skipped = 0;
    String? lastError;

    for (final name in names) {
      try {
        widget.gameEngine.addPlayer(name);
        added++;
      } catch (e) {
        skipped++;
        lastError = e.toString();
        // Remove 'Exception: ' or 'ArgumentError: ' prefix if present
        lastError = lastError.replaceFirst(RegExp(r'^.*Exception: '), '');
        lastError = lastError.replaceFirst(RegExp(r'^.*ArgumentError: '), '');
      }
    }

    _controller.clear();
    _nameFocus.requestFocus();

    String msg;
    if (added > 0 && skipped == 0) {
      if (names.length == 1) {
        msg = 'Guest "${names.first}" added.';
      } else {
        msg = 'Added $added guests.';
      }
    } else if (added > 0 && skipped > 0) {
      msg = 'Added $added, skipped $skipped duplicates.';
    } else {
      msg = skipped == 1 && lastError != null ? lastError : 'No guests added.';
    }

    _showNotification(msg,
        color: skipped > 0
            ? ClubBlackoutTheme.neonRed
            : ClubBlackoutTheme.neonPink);
  }

  List<String> _parseGuestNames(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return const [];

    // If the user pasted (Name) (Name) (Name), treat parenthesis groups as items.
    final parenMatches = RegExp(r'\(([^)]+)\)')
        .allMatches(input)
        .map((m) => (m.group(1) ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parenMatches.length >= 2) return parenMatches;

    var normalized = input.replaceAll('\r\n', '\n');

    // Bullets / dot bullets
    normalized = normalized.replaceAll(RegExp(r'[•·\u2022\u00b7]+'), '\n');

    // Common separators
    normalized = normalized.replaceAll(RegExp(r'[,;|/]+'), '\n');

    // Brackets/parentheses as separators
    normalized = normalized.replaceAll(RegExp(r'[\[\](){}]'), '\n');

    // "dot form" like: John. Mary. Alex
    if (RegExp(r'\.[ \t]+').hasMatch(normalized)) {
      final segs = normalized.split(RegExp(r'\.[ \t]+'));
      if (segs.length >= 2) normalized = segs.join('\n');
    } else if (normalized.contains('.') &&
        !normalized.contains('\n') &&
        normalized.split('.').length >= 3) {
      // Also handle: John.Mary.Alex
      normalized = normalized.split('.').join('\n');
    }

    final parts = normalized.split('\n');
    final out = <String>[];
    for (var part in parts) {
      var s = part.trim();
      if (s.isEmpty) continue;

      // Strip common list prefixes: "- ", "* ", "1)", "1."
      s = s.replaceFirst(RegExp(r'^(?:[-*]+\s+|\d+[.)]\s*)'), '').trim();
      if (s.isEmpty) continue;

      out.add(s);
    }

    return out;
  }

  void _showSavedPlayersPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final selected = <String>{};
        final cs = Theme.of(ctx).colorScheme;

        return StatefulBuilder(builder: (ctx, setState) {
          return ListenableBuilder(
            listenable: Listenable.merge([
              HallOfFameService.instance,
              widget.gameEngine,
            ]),
            builder: (ctx, _) {
              final profiles = HallOfFameService.instance.allProfiles;
              final profileNameSet = profiles
                  .map((p) => p.name.trim().toLowerCase())
                  .where((n) => n.isNotEmpty)
                  .toSet();

              final recentNames = widget.gameEngine.nameHistory
                  .where((n) => n.trim().isNotEmpty)
                  .map((n) => n.trim())
                  .where((n) => !profileNameSet.contains(n.toLowerCase()))
                  .toList(growable: false)
                  .reversed
                  .take(50)
                  .toList(growable: false);

              return BulletinDialogShell(
                accent: ClubBlackoutTheme.neonBlue,
                maxWidth: 560,
                title: Text(
                  'INVITE LIST',
                  style: ClubBlackoutTheme.bulletinHeaderStyle(
                      ClubBlackoutTheme.neonBlue),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 8, bottom: 8),
                        child: Text(
                          'HALL OF FAME',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      if (profiles.isEmpty)
                        Padding(
                          padding: ClubBlackoutTheme.rowPadding,
                          child: Text(
                            'No Hall of Fame entries yet.\nComplete a game to start building stats.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.54)),
                          ),
                        )
                      else
                        ...profiles.map((p) {
                          final normalizedName = p.name.trim().toLowerCase();
                          final alreadyIn = widget.gameEngine.players.any((x) =>
                              x.name.trim().toLowerCase() == normalizedName);
                          final isSelected = selected.contains(p.name);

                          return CheckboxListTile(
                            title: Text(
                              p.name,
                              style: TextStyle(
                                color: alreadyIn
                                    ? cs.onSurface.withValues(alpha: 0.3)
                                    : cs.onSurface,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              '${p.totalGames} games • ${(p.winRate * 100).toStringAsFixed(0)}% wins',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                            value: isSelected || alreadyIn,
                            activeColor: ClubBlackoutTheme.neonBlue,
                            checkColor: cs.surface,
                            onChanged: alreadyIn
                                ? null
                                : (v) {
                                    setState(() {
                                      if (v == true) {
                                        selected.add(p.name);
                                      } else {
                                        selected.remove(p.name);
                                      }
                                    });
                                  },
                          );
                        }),
                      Padding(
                        padding: ClubBlackoutTheme.rowPadding,
                        child: Divider(
                            color: cs.onSurface.withValues(alpha: 0.15)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 8),
                        child: Text(
                          'RECENT NAMES',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      if (recentNames.isEmpty)
                        Padding(
                          padding: ClubBlackoutTheme.rowPadding,
                          child: Text(
                            'No recent names yet.\nAdd guests to build a quick-pick list.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.54)),
                          ),
                        )
                      else
                        ...recentNames.map((name) {
                          final normalizedName = name.trim().toLowerCase();
                          final alreadyIn = widget.gameEngine.players.any((x) =>
                              x.name.trim().toLowerCase() == normalizedName);
                          final isSelected = selected.contains(name);

                          return CheckboxListTile(
                            title: Text(
                              name,
                              style: TextStyle(
                                color: alreadyIn
                                    ? cs.onSurface.withValues(alpha: 0.3)
                                    : cs.onSurface,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              'Recent',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                            value: isSelected || alreadyIn,
                            activeColor: ClubBlackoutTheme.neonBlue,
                            checkColor: cs.surface,
                            onChanged: alreadyIn
                                ? null
                                : (v) {
                                    setState(() {
                                      if (v == true) {
                                        selected.add(name);
                                      } else {
                                        selected.remove(name);
                                      }
                                    });
                                  },
                          );
                        }),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                    ),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: ClubBlackoutTheme.neonButtonStyle(
                      ClubBlackoutTheme.neonBlue,
                      isPrimary: true,
                    ),
                    onPressed: () {
                      for (final name in selected) {
                        widget.gameEngine.addPlayer(name);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text('ADD CHECKED (${selected.length})'),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }

  void _showClearAllConfirm(BuildContext context, GameEngine engine) {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        const accent = ClubBlackoutTheme.neonRed;
        return BulletinDialogShell(
          accent: accent,
          maxWidth: 520,
          title: Text(
            'CLEAR GUESTS?',
            style: ClubBlackoutTheme.bulletinHeaderStyle(accent),
          ),
          content: Text(
            'This will remove everyone from the guest list. Are you sure?',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.7),
              ),
              child: const Text('CANCEL'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: ClubBlackoutTheme.neonButtonStyle(
                accent,
                isPrimary: true,
              ),
              onPressed: () {
                final snapshot = engine.players
                    .map((p) => Player.fromJson(p.toJson(), p.role))
                    .toList(growable: false);
                engine.clearAllPlayers();
                Navigator.pop(ctx);

                if (snapshot.isNotEmpty) {
                  _showUndoSnackBar(
                    message: 'Guest list cleared.',
                    accent: accent,
                    onUndo: () {
                      final ok = engine.restoreAllPlayers(snapshot);
                      if (!ok) {
                        _showNotification(
                          'Undo failed: roster has changed.',
                          color: ClubBlackoutTheme.neonRed,
                        );
                      } else {
                        _hostController.text = engine.hostName ?? '';
                      }
                    },
                  );
                }
              },
              child: const Text('CLEAR ALL'),
            ),
          ],
        );
      },
    );
  }

  void _showRoleAssignment(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => RoleAssignmentDialog(
        gameEngine: widget.gameEngine,
        players: sortedPlayersByDisplayName(widget.gameEngine.guests),
        onConfirm: () async {
          await widget.gameEngine.startGame();
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => GameScreen(gameEngine: widget.gameEngine)),
            );
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
