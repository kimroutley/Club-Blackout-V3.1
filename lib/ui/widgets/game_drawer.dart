import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/game_engine.dart';
import '../screens/host_privacy_screen.dart';
import '../screens/lobby_screen.dart';
import '../styles.dart';
import '../utils/keep_screen_awake_service.dart';
import 'club_alert_dialog.dart';
import 'save_load_dialog.dart';

class GameDrawer extends StatelessWidget {
  final GameEngine? gameEngine;
  final VoidCallback? onGameLogTap;
  final VoidCallback? onHostDashboardTap;
  final VoidCallback? onContinueGameTap;
  final void Function(int index)? onNavigate;
  final int selectedIndex;

  const GameDrawer({
    super.key,
    this.gameEngine,
    this.onGameLogTap,
    this.onHostDashboardTap,
    this.onContinueGameTap,
    this.onNavigate,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Default accent to primary for M3 consistency
    final accent = cs.primary;

    final labelStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5);

    final canContinueGame = onContinueGameTap != null &&
        gameEngine != null &&
        gameEngine!.currentPhase != GamePhase.lobby;

    return NavigationDrawerTheme(
      data: NavigationDrawerThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: cs.surfaceTint,
        indicatorColor: cs.secondaryContainer.withValues(alpha: 0.75),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return labelStyle?.copyWith(
              color: selected
                  ? cs.onSecondaryContainer
                  : cs.onSurface.withValues(alpha: 0.70),
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? cs.onSecondaryContainer
                  : cs.onSurface.withValues(alpha: 0.45),
              size: 22,
            );
          },
        ),
      ),
      child: NavigationDrawer(
        selectedIndex: selectedIndex.clamp(0, 3),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onDestinationSelected: (index) {
          Navigator.pop(context);
          onNavigate?.call(index);
        },
        children: [
          _buildHeader(context, accent),
          ClubBlackoutTheme.gap16,
          const NavigationDrawerDestination(
            label: Text('HOME'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
          ),
          const NavigationDrawerDestination(
            label: Text('LOBBY'),
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_alt_rounded),
          ),
          const NavigationDrawerDestination(
            label: Text('GUIDES'),
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
          ),
          const NavigationDrawerDestination(
            label: Text('GAMES NIGHT'),
            icon: Icon(Icons.nights_stay_outlined),
            selectedIcon: Icon(Icons.nights_stay_rounded),
          ),
          if (gameEngine != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GAME CONTROLS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            if (canContinueGame)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DrawerTile(
                  label: 'Continue Game',
                  icon: Icons.play_arrow_rounded,
                  accent: cs.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onContinueGameTap?.call();
                  },
                ),
              ),
            if (onHostDashboardTap != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DrawerTile(
                  label: 'Host Dashboard',
                  icon: Icons.dashboard_customize_outlined,
                  accent: cs.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onHostDashboardTap?.call();
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DrawerTile(
                label: 'Save / Load',
                icon: Icons.save_outlined,
                accent: cs.tertiary,
                onTap: () async {
                  Navigator.pop(context);
                  final loaded = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => SaveLoadDialog(engine: gameEngine!),
                  );
                  
                  // If a game was loaded, navigate to Lobby to review/edit before starting
                  if (loaded == true && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LobbyScreen(gameEngine: gameEngine!),
                      ),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DrawerTile(
                label: 'Privacy Mode',
                icon: Icons.visibility_off_outlined,
                accent: cs.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HostPrivacyScreen(),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _KeepScreenAwakeDrawerTile(accent: cs.tertiary),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DrawerTile(
                label: 'Game Log',
                icon: Icons.receipt_long_outlined,
                accent: cs.primary,
                onTap: () {
                  Navigator.pop(context);
                  onGameLogTap?.call();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DrawerTile(
                label: 'Restart Lobby',
                icon: Icons.restart_alt_rounded,
                accent: cs.secondary,
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      final cs = Theme.of(ctx).colorScheme;
                      final tt = Theme.of(ctx).textTheme;
                      const accent = ClubBlackoutTheme.neonPurple;
                      return ClubAlertDialog(
                        title: Text(
                          'Start new game?',
                          style: (tt.titleLarge ?? const TextStyle()).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        content: Text(
                          'This resets the current game back to the lobby and clears roles, but keeps the guest list.',
                          style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                            color: cs.onSurface.withValues(alpha: 0.88),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent.withValues(alpha: 0.18),
                              foregroundColor: cs.onSurface,
                            ),
                            child: const Text('Start new'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm != true) return;
                  gameEngine!
                      .resetToLobby(keepGuests: true, keepAssignedRoles: false);
                  onNavigate?.call(1);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DrawerTile(
                label: 'Full Reset',
                icon: Icons.delete_forever_outlined,
                accent: cs.error,
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      final cs = Theme.of(ctx).colorScheme;
                      final tt = Theme.of(ctx).textTheme;
                      const accent = ClubBlackoutTheme.neonRed;
                      return ClubAlertDialog(
                        title: Text(
                          'Full reset?',
                          style: (tt.titleLarge ?? const TextStyle()).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        content: Text(
                          'This clears the entire roster and resets back to the lobby.',
                          style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                            color: cs.onSurface.withValues(alpha: 0.88),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent.withValues(alpha: 0.18),
                              foregroundColor: cs.onSurface,
                            ),
                            child: const Text('Reset'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm != true) return;
                  gameEngine!.resetToLobby(
                    keepGuests: false,
                    keepAssignedRoles: false,
                    clearArchived: true,
                  );
                  onNavigate?.call(1);
                },
              ),
            ),
          ],
          ClubBlackoutTheme.gap8,
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 24,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerLow,
            scheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.local_bar_rounded,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          ClubBlackoutTheme.neonPurple,
                          ClubBlackoutTheme.neonPink,
                          ClubBlackoutTheme.neonBlue,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'CLUB BLACKOUT',
                        style: (tt.headlineSmall ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(
                          width: 4,
                          height: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: ClubBlackoutTheme.neonGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Host Dashboard',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (gameEngine != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ClubBlackoutTheme.neonBlue.withValues(alpha: 0.15),
                          ClubBlackoutTheme.neonBlue.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: ClubBlackoutTheme.neonBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${gameEngine!.guests.length}',
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'Guests',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (gameEngine!.currentPhase != GamePhase.lobby) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ClubBlackoutTheme.neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_filled_rounded,
                          size: 14,
                          color: ClubBlackoutTheme.neonGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: ClubBlackoutTheme.neonGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.code_rounded,
                size: 12,
                color: scheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 6),
              Text(
                'v1.0.0',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A GAME BY KYRIAN CO.',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.35),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepScreenAwakeDrawerTile extends StatefulWidget {
  final Color accent;

  const _KeepScreenAwakeDrawerTile({required this.accent});

  @override
  State<_KeepScreenAwakeDrawerTile> createState() =>
      _KeepScreenAwakeDrawerTileState();
}

class _KeepScreenAwakeDrawerTileState extends State<_KeepScreenAwakeDrawerTile> {
  Future<void> _toggle() async {
    final messenger = ScaffoldMessenger.of(context);
    final next = !KeepScreenAwakeService.status.value.enabled;

    HapticFeedback.selectionClick();
    await KeepScreenAwakeService.setEnabled(next);

    messenger.showSnackBar(
      SnackBar(
        content: Text(next ? 'Keep screen awake: ON' : 'Keep screen awake: OFF'),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: KeepScreenAwakeService.status,
      builder: (context, status, _) {
        final label = status.loaded
            ? (status.enabled
                ? 'Keep Screen Awake (On)'
                : 'Keep Screen Awake (Off)')
            : 'Keep Screen Awake';

        return _DrawerTile(
          label: label,
          icon: status.enabled
              ? Icons.screen_lock_portrait_rounded
              : Icons.screen_lock_portrait_outlined,
          accent: widget.accent,
          onTap: _toggle,
        );
      },
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
