import 'package:flutter/material.dart';

import '../../logic/game_engine.dart';
import '../styles.dart';
import '../widgets/neon_background.dart';
import 'player_guide_screen.dart';
import 'role_cards_screen.dart';

class GuidesScreen extends StatelessWidget {
  final GameEngine? gameEngine;
  const GuidesScreen({super.key, this.gameEngine});

  @override
  Widget build(BuildContext context) {
    final isNight = gameEngine?.currentPhase == GamePhase.night;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Unified M3 Structure with Theming
    return Stack(
      children: [
        if (!isNight)
          const Positioned.fill(
            child: NeonBackground(
              accentColor: ClubBlackoutTheme.neonOrange,
              backgroundAsset:
                  'Backgrounds/Club Blackout V2 Game Background.png',
              blurSigma: 12.0,
              showOverlay: true,
              child: SizedBox.expand(),
            ),
          ),
        DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: isNight ? null : Colors.transparent,
            appBar: AppBar(
              backgroundColor:
                  isNight ? cs.surface : Colors.black.withValues(alpha: 0.3),
              surfaceTintColor: isNight ? cs.surfaceTint : Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(
                color: isNight ? cs.onSurface : Colors.white,
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              title: Text(
                'GUIDES',
                style: ClubBlackoutTheme.neonGlowTitle,
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isNight
                            ? cs.outlineVariant.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    labelColor:
                        isNight ? cs.primary : ClubBlackoutTheme.neonOrange,
                    unselectedLabelColor: isNight
                        ? cs.onSurfaceVariant
                        : Colors.white.withValues(alpha: 0.7),
                    indicatorColor:
                        isNight ? cs.primary : ClubBlackoutTheme.neonOrange,
                    indicatorWeight: 3,
                    labelStyle: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                    tabs: const [
                      Tab(text: 'HOST'),
                      Tab(text: 'PLAYER'),
                      Tab(text: 'ROLES'),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                const HostGuideBody(),
                const PlayerGuideBody(),
                RoleCardsScreen(
                  roles: gameEngine?.roleRepository.roles ?? const [],
                  embedded: true,
                  isNight: isNight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
