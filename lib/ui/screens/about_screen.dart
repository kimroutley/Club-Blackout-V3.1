import 'package:flutter/material.dart';
import '../styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1433),
                  Color(0xFF05030A),
                ],
              ),
            ),
          ),
          
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo / Icon placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_bar_rounded,
                      size: 48,
                      color: ClubBlackoutTheme.neonPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // App Name
                Text(
                  'CLUB BLACKOUT',
                  style: ClubBlackoutTheme.neonGlowTitle.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'MAFIA NARRATOR COMPANION',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Version Info
                _buildInfoCard(context, 'VERSION', '1.0.0+1'),
                const SizedBox(height: 16),
                
                // Credits
                _buildInfoCard(
                  context, 
                  'DEVELOPED BY', 
                  'Kyrian Co.',
                  subtitle: 'Designed & Built with Flutter',
                ),
                 const SizedBox(height: 16),
                 
                 _buildInfoCard(
                   context,
                   'SPECIAL THANKS',
                   'The Mafia Community\nFlutter Team\nGemini 2.0 Flash',
                 ),

                const SizedBox(height: 48),
                
                // Copyright
                Text(
                  '© ${DateTime.now().year} Kyrian Co. All rights reserved.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content, {String? subtitle}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: ClubBlackoutTheme.neonBlue,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
