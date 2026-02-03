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
    return Drawer(
      backgroundColor: ClubBlackoutTheme.kBackground.withValues(alpha: 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                   _buildSectionLabel('Navigation'),
                   _NeoDrawerTile(
                     label: 'Home',
                     icon: Icons.home_rounded,
                     isSelected: selectedIndex == 0,
                     onTap: () {
                       Navigator.pop(context);
                       onNavigate?.call(0);
                     },
                   ),
                   _NeoDrawerTile(
                     label: 'Lobby',
                     icon: Icons.people_alt_rounded,
                     isSelected: selectedIndex == 1,
                     onTap: () {
                       Navigator.pop(context);
                       onNavigate?.call(1);
                     },
                   ),
                   _NeoDrawerTile(
                     label: 'Guides',
                     icon: Icons.menu_book_rounded,
                     isSelected: selectedIndex == 2,
                     onTap: () {
                       Navigator.pop(context);
                       onNavigate?.call(2);
                     },
                   ),
                   
                   const SizedBox(height: 24),
                   _buildSectionLabel('Game Control'),
                   
                   if (gameEngine?.currentPhase != GamePhase.lobby && onContinueGameTap != null)
                      _NeoDrawerTile(
                        label: 'RESUME GAME',
                        icon: Icons.play_arrow_rounded,
                        overrideColor: ClubBlackoutTheme.neonGreen,
                        isStrong: true,
                        onTap: () {
                          Navigator.pop(context);
                          onContinueGameTap?.call();
                        },
                      ),
                      
                   if (onHostDashboardTap != null)
                      _NeoDrawerTile(
                        label: 'Dashboard',
                        icon: Icons.dashboard_rounded,
                        isSelected: false,
                        onTap: () {
                          Navigator.pop(context);
                          onHostDashboardTap?.call();
                        },
                      ),
                   
                   _NeoDrawerTile(
                     label: 'Game Log',
                     icon: Icons.history_edu_rounded,
                     isSelected: false,
                     onTap: () {
                       Navigator.pop(context);
                       onGameLogTap?.call();
                     },
                   ),

                   const SizedBox(height: 24),
                   _buildSectionLabel('System'),

                   _NeoDrawerTile(
                     label: 'Save / Load',
                     icon: Icons.save_rounded,
                     isSelected: false,
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
                   
                   _NeoDrawerTile(
                      label: 'Privacy Mode',
                      icon: Icons.visibility_off_rounded,
                      isSelected: false, 
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HostPrivacyScreen(),
                          ),
                        );
                      }
                   ),
                   
                   _KeepScreenAwakeNeoTile(),
                   
                   const SizedBox(height: 24),
                   Divider(color: Colors.white.withValues(alpha: 0.1)),
                   const SizedBox(height: 16),
                   
                   _NeoDrawerTile(
                      label: 'Restart Lobby',
                      icon: Icons.refresh_rounded,
                      overrideColor: ClubBlackoutTheme.neonOrange,
                      onTap: () async {
                         Navigator.pop(context);
                         final confirm = await _showResetDialog(context, 'RESTART LOBBY?', 
                            'This resets the game state but keeps guest names and roles.', ClubBlackoutTheme.neonOrange);
                         if (confirm == true) {
                            gameEngine!.resetToLobby(keepGuests: true, keepAssignedRoles: false);
                            onNavigate?.call(1);
                         }
                      }
                   ),
                   _NeoDrawerTile(
                      label: 'FULL RESET',
                      icon: Icons.delete_forever_rounded,
                      overrideColor: ClubBlackoutTheme.neonRed,
                      onTap: () async {
                         Navigator.pop(context);
                         final confirm = await _showResetDialog(context, 'FULL WIPE?', 
                            'This permanently deletes all players and resets to scratch.', ClubBlackoutTheme.neonRed);
                         if (confirm == true) {
                            gameEngine!.resetToLobby(keepGuests: false, keepAssignedRoles: false);
                            onNavigate?.call(1);
                         }
                      }
                   ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
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

  Widget _buildHeader(BuildContext context) {
    return Container(
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
  
  Future<bool?> _showResetDialog(BuildContext context, String title, String content, Color accent) {
      return showDialog<bool>(
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

class _NeoDrawerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? overrideColor;
  final bool isStrong;
  
  const _NeoDrawerTile({
     required this.label,
     required this.icon,
     required this.onTap,
     this.isSelected = false,
     this.overrideColor,
     this.isStrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = overrideColor ?? (isSelected ? ClubBlackoutTheme.kNeonCyan : Colors.white60);
    final bg = isSelected 
        ? color.withValues(alpha: 0.1) 
        : (isStrong ? color.withValues(alpha: 0.2) : Colors.transparent);
        
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
             duration: const Duration(milliseconds: 200),
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                   color: isSelected || isStrong ? color.withValues(alpha: 0.5) : Colors.transparent,
                   width: 1,
                )
             ),
             child: Row(
               children: [
                 Icon(icon, color: color, size: 20),
                 const SizedBox(width: 16),
                 Text(
                    label.toUpperCase(),
                    style: TextStyle(
                       color: isSelected ? Colors.white : (overrideColor ?? Colors.white70),
                       fontWeight: isSelected || isStrong ? FontWeight.bold : FontWeight.w500,
                       letterSpacing: 1.0,
                    ),
                 )
               ],
             ),
          ),
        ),
      ),
    );
  }
}

class _KeepScreenAwakeNeoTile extends StatefulWidget {
  @override
  State<_KeepScreenAwakeNeoTile> createState() => _KeepScreenAwakeNeoTileState();
}

class _KeepScreenAwakeNeoTileState extends State<_KeepScreenAwakeNeoTile> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KeepScreenAwakeStatus>(
      valueListenable: KeepScreenAwakeService.status,
      builder: (context, status, _) {
          return _NeoDrawerTile(
             label: status.enabled ? 'Screen Awake: ON' : 'Screen Awake',
             icon: status.enabled ? Icons.wb_sunny_rounded : Icons.nightlight_round,
             isSelected: status.enabled,
             onTap: () async {
                 HapticFeedback.selectionClick();
                 await KeepScreenAwakeService.setEnabled(!status.enabled);
             },
          );
      }
    );
  }
}
