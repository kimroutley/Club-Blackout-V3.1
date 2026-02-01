import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/game_engine.dart';
import '../../services/dynamic_theme_service.dart';
import '../styles.dart';

class HomeScreen extends StatefulWidget {
  final GameEngine gameEngine;
  final VoidCallback onNavigateToLobby;
  final VoidCallback onNavigateToGuides;

  const HomeScreen({
    super.key,
    required this.gameEngine,
    required this.onNavigateToLobby,
    required this.onNavigateToGuides,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Update theme from home background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTheme();
    });
  }

  void _updateTheme() {
    if (!mounted) return;
    
    try {
      final themeService = Provider.of<DynamicThemeService>(context, listen: false);
      themeService.updateFromBackground(
        'Backgrounds/Club Blackout V2 Home Menu.png',
      );
    } catch (e) {
      debugPrint('Failed to update home theme: $e');
    }
  }

  void _showStartOptions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surfaceContainerHigh,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ClubBlackoutTheme.neonPurple.withValues(alpha: 0.25),
                          ClubBlackoutTheme.neonPink.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: ClubBlackoutTheme.neonPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Playing',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Choose your game mode',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onNavigateToLobby();
                },
                icon: const Icon(Icons.celebration_rounded, size: 20),
                label: const Text('Games Night'),
                style: FilledButton.styleFrom(
                  backgroundColor: ClubBlackoutTheme.neonPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onNavigateToLobby();
                },
                icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: const Text('Normal Game'),
                style: FilledButton.styleFrom(
                  backgroundColor: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.15),
                  foregroundColor: cs.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
    
    // Phase-aware styling
    final isNight = widget.gameEngine.currentPhase == GamePhase.night;

    // Background
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
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: background),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
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
                    // Welcome card
                    if (!isNight) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ClubBlackoutTheme.neonPurple.withValues(alpha: 0.15),
                              ClubBlackoutTheme.neonBlue.withValues(alpha: 0.12),
                              ClubBlackoutTheme.neonPink.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
                                    ClubBlackoutTheme.neonPink.withValues(alpha: 0.25),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.wb_twilight_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  ClubBlackoutTheme.neonPurple,
                                  ClubBlackoutTheme.neonPink,
                                  ClubBlackoutTheme.neonBlue,
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'Welcome Back',
                                style: tt.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ready for another night of deception?',
                              style: tt.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    // Main action buttons
                    FilledButton.icon(
                      onPressed: () => _showStartOptions(context),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: const Text("Let's Get Started"),
                      style: FilledButton.styleFrom(
                        backgroundColor: ClubBlackoutTheme.neonPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shadowColor: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.5),
                        textStyle: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: widget.onNavigateToGuides,
                      icon: const Icon(Icons.menu_book_rounded, size: 22),
                      label: const Text('Game Guides'),
                      style: FilledButton.styleFrom(
                        backgroundColor: isNight 
                          ? cs.secondaryContainer 
                          : ClubBlackoutTheme.neonBlue.withValues(alpha: 0.2),
                        foregroundColor: isNight 
                          ? cs.onSecondaryContainer 
                          : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                      ),
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
                            color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.3),
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
                              color: (isNight ? cs.outline : Colors.white).withValues(alpha: 0.3),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isNight ? cs.onSurface : Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isNight 
              ? cs.onSurface.withValues(alpha: 0.7) 
              : Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
