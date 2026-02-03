import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../logic/game_engine.dart';
import '../styles.dart';
import '../widgets/neon_glass_card.dart';

class PlayerGuideScreen extends StatelessWidget {
  final GameEngine? gameEngine;

  const PlayerGuideScreen({super.key, this.gameEngine});

  @override
  Widget build(BuildContext context) {
    if (gameEngine?.currentPhase == GamePhase.night) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'PLAYER GUIDE',
            style: ClubBlackoutTheme.neonGlowTitle,
          ),
          centerTitle: true,
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

  return NeonGlassCard(
    glowColor: accentColor,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.roboto(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
        if (content != null) ...[
          const SizedBox(height: 16),
          content,
        ],
      ],
    ),
  );
}

Widget _buildWelcomeCard(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return NeonGlassCard(
    glowColor: cs.primary,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.info_outline_rounded,
            color: cs.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUICK REFERENCE',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Everything you need to know',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
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

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: cs.primary,
                  ),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
