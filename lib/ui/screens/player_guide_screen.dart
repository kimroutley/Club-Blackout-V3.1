import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';
import '../styles.dart';

class PlayerGuideScreen extends StatelessWidget {
  final GameEngine? gameEngine;

  const PlayerGuideScreen({super.key, this.gameEngine});

  @override
  Widget build(BuildContext context) {
    if (gameEngine?.currentPhase == GamePhase.night) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Player Guide'),
        ),
        body: const SafeArea(
          child: PlayerGuideBody(),
        ),
      );
    }

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
          appBar: AppBar(
            title: null,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            child: const PlayerGuideBody(),
          ),
        ),
      ],
    );
  }
}

class PlayerGuideBody extends StatelessWidget {
  const PlayerGuideBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _buildWelcomeCard(context),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'Welcome to Club Blackout',
          'Where the music is loud, the drinks are strong, and the survival rate is... debatable. '
              'You are either a PARTY ANIMAL looking for a good time, or a DEALER looking for your next victim. '
              'Try not to get thrown out (or worse).',
          ClubBlackoutTheme.neonPink,
          icon: Icons.local_bar_rounded,
        ),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'The vibe (flow)',
          null,
          ClubBlackoutTheme.neonBlue,
          icon: Icons.timeline_rounded,
          content: Column(
            children: [
              _buildFlowStep(context, 'Pre-game',
                  'Lobby screen. Pick a name, grab a selfie, pray for a good role.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'NIGHT 0',
                  'Setup phase. No dying yet. Just awkward introductions.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'Blackout',
                  'Night phase. Eyes shut. Killers creep. Chaos ensues.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'Morning after',
                  'Host spills the tea on who died or got lucky.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'Vote',
                  'Accuse your friends. Lie to your family. Throw someone out.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'Repeat',
                  'Until the Dealers are gone or the Party is dead.'),
            ],
          ),
        ),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'Eyes & ears',
          'When the Host says "Sleep", you sleep. No peeking, no twitching. '
              'If you cheat, you ruin the vibe, and nobody likes a buzzkill.',
          ClubBlackoutTheme.neonPurple,
          icon: Icons.visibility_off_rounded,
        ),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'The throw out',
          'During the day, figure out who the Dealers are. If you vote correctly, they get booted. '
              'If you vote wrong... well, sorry Dave, but you looked suspicious.',
          ClubBlackoutTheme.neonOrange,
          icon: Icons.how_to_vote_rounded,
        ),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'House rules',
          null,
          ClubBlackoutTheme.neonPurple,
          icon: Icons.gavel_rounded,
          content: Column(
            children: [
              _buildFlowStep(context, 'Don\'t be that guy',
                  'Don\'t peek. Don\'t cheat. It\'s a party game, chill.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'Play the role',
                  'Attack the character, not the player. Unless it\'s Steve. Steve knows what he did.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'Dead men tell no tales',
                  'If you die, shut up. Ghosts can\'t talk, they just haunt.'),
            ],
          ),
        ),
      ],
    );
  }
}

class HostGuideBody extends StatelessWidget {
  const HostGuideBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _buildWelcomeCard(context),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'You are the DJ',
          'You run the Club. You control the chaos. You are the Host. '
              'Your job is to keep the energy high and the game moving. '
              'Think "Master of Ceremonies" meets "Grim Reaper".',
          ClubBlackoutTheme.neonBlue,
          icon: Icons.headset_mic_rounded,
        ),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'Your gig',
          null,
          ClubBlackoutTheme.neonPink,
          icon: Icons.work_outline_rounded,
          content: Column(
            children: [
              _buildFlowStep(context, 'Set the tone',
                  'Use your "spooky narrator voice". Make them nervous.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'Keep tempo',
                  'Don\'t let them sleep all night. Wake \'em up, kill \'em off.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'God mode',
                  'The app tracks the logic. You bring the drama.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'Pause button',
                  'Need a break? Send everyone to sleep. Power trip approved.'),
            ],
          ),
        ),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'Setup night (Night 0)',
          'The soft opening. Special roles (Medic, Clinger) do their thing. '
              'Nobody dies tonight. It\'s just a vibe check.',
          ClubBlackoutTheme.neonGold,
          icon: Icons.nightlight_round_rounded,
        ),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'Blackout phase',
          'Follow the app prompts. Call roles by name. If they snore, wake them up. '
              'If they peek, shame them publicly.',
          ClubBlackoutTheme.neonPurple,
          icon: Icons.dark_mode_rounded,
        ),
        ClubBlackoutTheme.gap16,
        _buildSection(
          context,
          'Daylight drama',
          null,
          ClubBlackoutTheme.neonOrange,
          icon: Icons.wb_sunny_rounded,
          content: Column(
            children: [
              _buildFlowStep(context, 'The reveal',
                  'Read the Morning Bulletin like it\'s breaking news.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'The showdown',
                  'Let them argue. Fuel the fire. Then call the vote.'),
              ClubBlackoutTheme.gap8,
              _buildFlowStep(context, 'The flush',
                  'When someone gets voted out, take their badge. They\'re done.'),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _buildSection(
  BuildContext context,
  String title,
  String? description,
  Color accentColor, {
  Widget? content,
  IconData? icon,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return Card(
    elevation: 0,
    color: cs.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: accentColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.15),
                accentColor.withValues(alpha: 0.08),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: accentColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  title,
                  style: tt.titleMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null)
                Text(
                  description,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.9),
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
              if (content != null) content,
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildWelcomeCard(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ClubBlackoutTheme.neonPurple.withValues(alpha: 0.15),
          ClubBlackoutTheme.neonBlue.withValues(alpha: 0.15),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
        width: 2,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
            ),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: ClubBlackoutTheme.neonPurple,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Reference Guide',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Everything you need to know',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFlowStep(BuildContext context, String label, String desc) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: cs.outline.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSecondaryContainer,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            desc,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ),
        Icon(
          Icons.arrow_forward_rounded,
          size: 18,
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ],
    ),
  );
}
