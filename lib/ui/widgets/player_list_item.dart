import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../styles.dart';
import 'player_icon.dart';

class PlayerListItem extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final VoidCallback onTap;

  const PlayerListItem({
    super.key,
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? ClubBlackoutTheme.kNeonCyan.withOpacity(0.15)
              : ClubBlackoutTheme.kCardBg,
          borderRadius: BorderRadius.circular(50), // Capsule
          border: Border.all(
            color: isSelected 
                ? ClubBlackoutTheme.kNeonCyan 
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Floating Avatar
            PlayerIcon(
              assetPath: player.role.assetPath,
              glowColor: isSelected ? ClubBlackoutTheme.kNeonCyan : player.role.color,
              size: 40,
              isAlive: player.isAlive,
              isEnabled: player.isEnabled,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                player.name.toUpperCase(),
                style: ClubBlackoutTheme.neonGlowFont.copyWith(
                  color: isSelected ? ClubBlackoutTheme.kNeonCyan : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.check_circle,
                  color: ClubBlackoutTheme.kNeonCyan,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
