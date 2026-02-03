import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/game_engine.dart';
import '../screens/host_privacy_screen.dart';
import '../screens/lobby_screen.dart';
import '../styles.dart';
import '../utils/keep_screen_awake_service.dart';
import 'club_alert_dialog.dart';
import 'save_load_dialog.dart';

class NeoDrawer extends StatelessWidget {
  final GameEngine? gameEngine;
  final VoidCallback? onGameLogTap;
  final VoidCallback? onHostDashboardTap;
  final VoidCallback? onContinueGameTap;
  final void Function(int index)? onNavigate;
  final int selectedIndex;

  const NeoDrawer({
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


      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
           color: ClubBlackoutTheme.kNeonCyan.withValues(alpha: 0.5),
           fontSize: 10,
           letterSpacing: 1.5,
           fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
             ClubBlackoutTheme.kNeonCyan.withValues(alpha: 0.05),
             Colors.transparent,
          ]
        )
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ClubBlackoutTheme.kNeonCyan, width: 2),
              boxShadow: [
                BoxShadow(
                  color: ClubBlackoutTheme.kNeonCyan.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            ),
            child: const Icon(Icons.nightlife_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'CLUB BLACKOUT',
                 style: ClubBlackoutTheme.neonGlowTitle.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                 ),
               ),
               const SizedBox(height: 4),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(
                    color: ClubBlackoutTheme.kNeonPink,
                    borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   'HOST CONSOLE',
                   style: ClubBlackoutTheme.mainFont.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                   ),
                 ),
               )
             ],
          )
        ],
      )
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Text(
        'v3.0.0 CYBER EDITION',
        style: TextStyle(
           color: Colors.white.withValues(alpha: 0.2),
           fontSize: 10,
           letterSpacing: 2.0,
        ),
      ),
    );
  }
  
        context: context,
        builder: (ctx) => ClubAlertDialog(
           title: Text(title, style: TextStyle(color: accent)),
           content: Text(content),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
              FilledButton(
                 style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
                 onPressed: () => Navigator.pop(ctx, true), 
                 child: const Text('CONFIRM')
              ),
           ],
        ),
      );
  }
}

  final IconData icon;
  final bool isSelected;
  
    final cs = Theme.of(context).colorScheme;
    final accent = ClubBlackoutTheme.kNeonCyan; // Neo theme accent

    final canContinueGame = onContinueGameTap != null &&
        gameEngine != null &&
        gameEngine!.currentPhase != GamePhase.lobby;

    return NavigationDrawerTheme(
      data: NavigationDrawerThemeData(
        backgroundColor: ClubBlackoutTheme.kBackground.withOpacity(0.95),
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withOpacity(0.2),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return ClubBlackoutTheme.neonGlowFont.copyWith(
              color: states.contains(WidgetState.selected)
                  ? accent
                  : Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? accent
                  : Colors.white.withOpacity(0.5),
              size: 22,
            );
        }),
      ),
      child: NavigationDrawer(
        selectedIndex: selectedIndex.clamp(0, 3),
        onDestinationSelected: (index) {
          Navigator.pop(context);
          onNavigate?.call(index);
        },
        children: [
          _buildHeader(context, accent),
          const SizedBox(height: 16),
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
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // ... Logic copied from GameDrawer but using Neo styles ...
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'GAME CONTROLS',
                style: ClubBlackoutTheme.neonGlowFont.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (canContinueGame)
              _DrawerTile(
                label: 'Continue Game',
                icon: Icons.play_arrow_rounded,
                accent: accent,
                onTap: () {
                  Navigator.pop(context);
                  onContinueGameTap?.call();
                },
              ),
            
            if (onHostDashboardTap != null)
              _DrawerTile(
                label: 'Host Dashboard',
                icon: Icons.dashboard_customize_outlined,
                accent: accent,
                onTap: () {
                  Navigator.pop(context);
                  onHostDashboardTap?.call();
                },
              ),

             _DrawerTile(
                label: 'Save / Load',
                icon: Icons.save_outlined,
                accent: ClubBlackoutTheme.neonPurple,
                onTap: () async {
                  Navigator.pop(context);
                  final loaded = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => SaveLoadDialog(engine: gameEngine!),
                  );
                  if (loaded == true && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LobbyScreen(gameEngine: gameEngine!),
                      ),
                    );
                  }
                },
              ),

             _DrawerTile(
                label: 'Privacy Mode',
                icon: Icons.visibility_off_outlined,
                accent: ClubBlackoutTheme.neonPink,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HostPrivacyScreen(),
                    ),
                  );
                },
              ),

             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
               child: _KeepScreenAwakeDrawerTile(accent: accent),
             ),

             _DrawerTile(
                label: 'Game Log',
                icon: Icons.receipt_long_outlined,
                accent: accent,
                onTap: () {
                  Navigator.pop(context);
                  onGameLogTap?.call();
                },
              ),

             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            _DrawerTile(
              label: 'Restart Lobby',
              icon: Icons.restart_alt_rounded,
              accent: ClubBlackoutTheme.neonOrange,
              onTap: () async {
                  Navigator.pop(context);
                  // ... logic ...
                  // Simplified for brevity, reusing logic
                   final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => ClubAlertDialog(
                        title: const Text('START NEW GAME?'),
                        content: const Text('Resets to lobby.'),
                        actions: [
                          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text('CANCEL')),
                          FilledButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text('START NEW')),
                        ],
                    ),
                  );
                  if (confirm != true) return;
                  gameEngine!.resetToLobby(keepGuests: true, keepAssignedRoles: false);
                  onNavigate?.call(1);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
     return Container(
       padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 24, 20, 24),
       decoration: BoxDecoration(
         color: Colors.black.withOpacity(0.3),
         border: Border(bottom: BorderSide(color: accent.withOpacity(0.2))),
       ),
       child: Row(
         children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Icon(Icons.local_bar_rounded, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLUB BLACKOUT', style: ClubBlackoutTheme.neonGlowFont.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (gameEngine != null)
                  Text('${gameEngine!.guests.length} GUESTS', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ],
            ),
         ],
       ),
     );
  }
}

class _DrawerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _DrawerTile({required this.label, required this.icon, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white.withOpacity(0.05),
        leading: Icon(icon, color: accent, size: 20),
        title: Text(label.toUpperCase(), style: ClubBlackoutTheme.neonGlowFont.copyWith(fontSize: 12, color: Colors.white)),
        trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 18),
      ),
    );
  }
}

class _KeepScreenAwakeDrawerTile extends StatefulWidget {
  final Color accent;
  const _KeepScreenAwakeDrawerTile({required this.accent});
  @override
  State<_KeepScreenAwakeDrawerTile> createState() => _KeepScreenAwakeDrawerTileState();
}

class _KeepScreenAwakeDrawerTileState extends State<_KeepScreenAwakeDrawerTile> {
  Future<void> _toggle() async {
    final next = !KeepScreenAwakeService.status.value.enabled;
    HapticFeedback.selectionClick();
    await KeepScreenAwakeService.setEnabled(next);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KeepScreenAwakeStatus>(
      valueListenable: KeepScreenAwakeService.status,
      builder: (context, status, _) {
         return ListTile(
            onTap: _toggle,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white.withOpacity(0.05),
            leading: Icon(status.enabled ? Icons.screen_lock_portrait : Icons.screen_lock_portrait_outlined, color: widget.accent, size: 20),
            title: Text(status.enabled ? 'SCREEN AWAKE: ON' : 'SCREEN AWAKE: OFF', style: ClubBlackoutTheme.neonGlowFont.copyWith(fontSize: 12, color: Colors.white)),
         );
      },
    );
  }
}
