import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';
import '../styles.dart';
import '../widgets/dynamic_themed_background.dart';
import '../widgets/neon_glass_card.dart';

class HomeScreen extends StatefulWidget {
  final GameEngine gameEngine;
  final VoidCallback onNavigateToLobby;
  final VoidCallback onNavigateToGuides;
  final VoidCallback? onNavigateToGamesNight;
  final VoidCallback? onOpenDrawer;

  const HomeScreen({
    super.key,
    required this.gameEngine,
    required this.onNavigateToLobby,
    required this.onNavigateToGuides,
    this.onNavigateToGamesNight,
    this.onOpenDrawer,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showStartOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        return NeonGlassCard(
          glowColor: ClubBlackoutTheme.neonPurple,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ClubBlackoutTheme.neonPurple.withValues(alpha: 0.4),
                          ClubBlackoutTheme.neonPink.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'START PLAYING',
                          style: ClubBlackoutTheme.headingStyle.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'CHOOSE YOUR GAME MODE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.onNavigateToGamesNight != null) {
                    widget.onNavigateToGamesNight!();
                  } else {
                    widget.onNavigateToGuides();
                  }
                },
                icon: const Icon(Icons.celebration_rounded, size: 22),
                label: const Text('GAMES NIGHT'),
                style: FilledButton.styleFrom(
                  backgroundColor: ClubBlackoutTheme.neonPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: ClubBlackoutTheme.headingStyle.copyWith(
                    fontSize: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onNavigateToLobby();
                },
                icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                label: const Text('NORMAL GAME'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: ClubBlackoutTheme.headingStyle.copyWith(
                    fontSize: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isNight = widget.gameEngine.currentPhase == GamePhase.night;

    Widget background;
    if (isNight) {
      background = Container(color: cs.surface);
    } else {
      background = Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'Backgrounds/Club Blackout V2 Home Menu.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E1433).withValues(alpha: 0.8),
                  const Color(0xFF05030A).withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return DynamicThemedBackground(
      backgroundAsset: 'Backgrounds/Club Blackout V2 Home Menu.png',
      child: Stack(
        children: [
          Positioned.fill(child: background),
          Builder(
            builder: (context) => Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  'CLUB BLACKOUT',
                  style: ClubBlackoutTheme.neonGlowTitle,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    if (widget.onOpenDrawer != null) {
                      widget.onOpenDrawer!();
                    } else {
                      Scaffold.maybeOf(context)?.openDrawer();
                    }
                  },
                ),
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const SizedBox(height: 40),
                        // Title Simulation
                        Text(
                          "WELCOME TO",
                          style: TextStyle(
                            fontFamily: ClubBlackoutTheme.neonGlowFontFamily,
                            color: ClubBlackoutTheme.neonPink,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                  color: ClubBlackoutTheme.neonPink,
                                  blurRadius: 10)
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        // "CLUB BLACKOUT" striped text with stroke effect
                        Stack(
                          children: [
                            Text(
                              "CLUB\nBLACKOUT",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily:
                                    ClubBlackoutTheme.neonGlowFontFamily,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2
                                  ..color = ClubBlackoutTheme.neonBlue,
                                height: 0.9,
                              ),
                            ),
                            Text(
                              "CLUB\nBLACKOUT",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily:
                                    ClubBlackoutTheme.neonGlowFontFamily,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.transparent, // Fill is transparent
                                shadows: [
                                  Shadow(
                                      color: ClubBlackoutTheme.neonBlue,
                                      blurRadius: 8)
                                ],
                                height: 0.9,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),
                      ],

                      FilledButton(
                        onPressed: () => _showStartOptions(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: ClubBlackoutTheme.neonBlue,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 10,
                          shadowColor:
                              ClubBlackoutTheme.neonBlue.withValues(alpha: 0.5),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("START GAME"),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: widget.onNavigateToGuides,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: ClubBlackoutTheme.neonPink,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: ClubBlackoutTheme.neonPink,
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Text('GUIDES'),
                      ),

                      // Stats row (if available)
                      if (widget.gameEngine.guests.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isNight
                                ? cs.surfaceContainerHighest
                                : Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ClubBlackoutTheme.neonBlue
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                Icons.groups_rounded,
                                widget.gameEngine.guests.length.toString(),
                                'Guests',
                                ClubBlackoutTheme.neonBlue,
                                isNight,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: (isNight ? cs.outline : Colors.white)
                                    .withValues(alpha: 0.3),
                              ),
                              _buildStatItem(
                                context,
                                Icons.nightlight_rounded,
                                widget.gameEngine.dayCount.toString(),
                                'Days',
                                ClubBlackoutTheme.neonPurple,
                                isNight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ), // Padding
              ), // ConstrainedBox
            ), // Center
          ), // Scaffold
        ), // Builder
      ], // Stack children
    ), // Stack
  ); // DynamicThemedBackground
}

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
    bool isNight,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: ClubBlackoutTheme.headingStyle.copyWith(
            fontSize: 24,
            color: isNight ? cs.onSurface : Colors.white,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: (isNight ? cs.onSurface : Colors.white)
                .withValues(alpha: 0.6),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
