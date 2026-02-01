import 'package:flutter/material.dart';

import '../models/player.dart';
import '../ui/styles.dart';
import 'game_engine.dart';

/// Represents a consolidated status to be displayed in the UI.
class PlayerStatusDisplay {
  final String label;
  final Color color;
  final String? description;
  final IconData? icon;

  PlayerStatusDisplay({
    required this.label,
    required this.color,
    this.description,
    this.icon,
  });
}

/// Centralizes logic for resolving all player statuses (Effects + Role State).
class PlayerStatusResolver {
  /// Returns a list of all active statuses for a player.
  /// Used by Host Status Cards, Voting Tiles, and Act screens.
  static List<PlayerStatusDisplay> resolveStatus(
    Player player,
    GameEngine gameEngine,
  ) {
    final List<PlayerStatusDisplay> statuses = [];

    // 1. Messy Bitch - Rumour
    if (player.hasRumour) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'RUMOUR',
          color: ClubBlackoutTheme.neonPurple,
          description: 'This player has heard a dirty rumour.',
          icon: Icons.record_voice_over,
        ),
      );
    }

    // 2. Generic Status Effects (from StatusEffectManager)
    final effects = gameEngine.statusEffectManager.getEffects(player.id);
    for (var effect in effects) {
      // Skip legacy silenced flag if duplicately applied (handled by role state below)
      if (effect.name.contains('SILENCED') &&
          player.silencedDay == gameEngine.dayCount) {
        continue;
      }

      String label = effect.name.toUpperCase();
      if (effect.duration > 0) {
        label += " (${effect.duration} TURN${effect.duration > 1 ? 'S' : ''})";
      } else if (effect.isPermanent) {
        label += ' (PERM)';
      }

      statuses.add(
        PlayerStatusDisplay(
          label: label,
          color: ClubBlackoutTheme.neonBlue,
          description: effect.description,
          icon: Icons.info_outline,
        ),
      );
    }

    // 3. Sober - Sent Home
    if (player.soberSentHome) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'SENT HOME',
          color: ClubBlackoutTheme.neonBlue,
          description: 'Sent home by the Sober. Cannot act or vote.',
          icon: Icons.home,
        ),
      );
    }

    // 4. Clinger - Obsession
    if (player.clingerPartnerId != null) {
      final target = gameEngine.players.firstWhere(
        (p) => p.id == player.clingerPartnerId,
        orElse: () => player,
      );
      statuses.add(
        PlayerStatusDisplay(
          label: 'OBSESSED: ${target.name}',
          color: ClubBlackoutTheme.neonPink,
          description: 'Bound to ${target.name}. If they die, you die.',
          icon: Icons.favorite,
        ),
      );
    }

    // 5. Creep - Target
    if (player.creepTargetId != null) {
      final target = gameEngine.players.firstWhere(
        (p) => p.id == player.creepTargetId,
        orElse: () => player,
      );
      statuses.add(
        PlayerStatusDisplay(
          label: 'CREEPING: ${target.name}',
          color: ClubBlackoutTheme.neonGreen,
          description: 'Mimicking ${target.name}.',
          icon: Icons.remove_red_eye,
        ),
      );
    }

    // 6. Clinger - Unleashed (Attack Dog)
    if (player.clingerFreedAsAttackDog) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'UNLEASHED',
          color: ClubBlackoutTheme.neonRed,
          description: 'Freed from obsession. Can kill once.',
          icon: Icons.dangerous,
        ),
      );
    }

    // 7. Medic - Choice
    if (player.medicChoice != null) {
      statuses.add(
        PlayerStatusDisplay(
          label: player.medicChoice == 'PROTECT_DAILY'
              ? 'MEDIC: PROTECT'
              : 'MEDIC: REVIVE',
          color: ClubBlackoutTheme.neonBlue,
          description:
              'Permanent Night 0 Choice: ${player.medicChoice == 'PROTECT_DAILY' ? 'Protect one player each night' : 'Revive one player once per game'}',
          icon: Icons.medical_services,
        ),
      );
    }

    // Show medic protection status
    final medicWithProtection = gameEngine.players
        .where((p) => p.role.id == 'medic' && 
                      p.isActive && 
                      p.medicProtectedPlayerId == player.id)
        .firstOrNull;
    if (medicWithProtection != null) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'PROTECTED',
          color: ClubBlackoutTheme.neonGreen,
          description: 'Under medic protection - safe from night kills until medic changes target.',
          icon: Icons.shield,
        ),
      );
    }

    // 8. Bouncer - ID Checked
    if (player.idCheckedByBouncer) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'CHECKED',
          color: Colors.grey,
          description: 'ID has been checked by the Bouncer.',
          icon: Icons.check,
        ),
      );
    }

    // 9. Roofi - Silenced
    if (player.silencedDay == gameEngine.dayCount) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'SILENCED',
          color: ClubBlackoutTheme.pureWhite,
          description: 'Silenced for today.',
          icon: Icons.mic_off,
        ),
      );
    }

    // 10. Minor - Immunity / Vulnerable state
    if (player.role.id == 'minor') {
      if (player.minorHasBeenIDd) {
        statuses.add(
          PlayerStatusDisplay(
            label: 'VULNERABLE',
            color: ClubBlackoutTheme.neonRed,
            description: 'The Minor can now be killed by the Dealers.',
            icon: Icons.warning_amber_rounded,
          ),
        );
      } else {
        statuses.add(
          PlayerStatusDisplay(
            label: 'IMMUNE',
            color: ClubBlackoutTheme.neonMint,
            description:
                'Immune to Dealer kills until ID checked by the Bouncer.',
            icon: Icons.shield_outlined,
          ),
        );
      }
    }

    // 10b. Silver Fox - Alibi (Vote Immunity)
    if (player.alibiDay == gameEngine.dayCount) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'ALIBI (TODAY ONLY)',
          color: ClubBlackoutTheme.neonBlue,
          description: 'Votes against this player do not count today.',
          icon: Icons.verified_user,
        ),
      );
    }

    // 11. Second Wind - Status
    if (player.secondWindConverted) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'CONVERTED FROM SECOND',
          color: ClubBlackoutTheme.neonOrange,
          description: 'Converted to Dealer team.',
          icon: Icons.cached,
        ),
      );
    } else if (player.secondWindPendingConversion) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'PENDING CONV',
          color: ClubBlackoutTheme.neonOrange,
          description: 'Pending Dealer conversion decision.',
          icon: Icons.hourglass_empty,
        ),
      );
    }

    // 12. Late Joiner
    if (player.joinsNextNight) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'LATE JOIN',
          color: ClubBlackoutTheme.neonGreen,
          description: 'Will join the game next night.',
          icon: Icons.person_add,
        ),
      );
    }

    // 13. Whore - Deflection Target
    if (player.whoreDeflectionTargetId != null) {
      final target = gameEngine.players.firstWhere(
        (p) => p.id == player.whoreDeflectionTargetId,
        orElse: () => player,
      );
      statuses.add(
        PlayerStatusDisplay(
          label: player.whoreDeflectionUsed
              ? 'BITCH (USED): ${target.name}'
              : 'BITCH: ${target.name}',
          color: player.whoreDeflectionUsed
              ? Colors.grey
              : ClubBlackoutTheme.neonPink,
          description: player.whoreDeflectionUsed
              ? 'Deflection was already used on ${target.name}.'
              : '${target.name} will take the fall if Whore or Dealer is voted out.',
          icon: player.whoreDeflectionUsed ? Icons.check_circle : Icons.shield,
        ),
      );
    }

    // 14. Tea Spiller - Mark
    if (player.teaSpillerTargetId != null) {
      final target = gameEngine.players.firstWhere(
        (p) => p.id == player.teaSpillerTargetId,
        orElse: () => player,
      );
      statuses.add(
        PlayerStatusDisplay(
          label: 'MARKED: ${target.name}',
          color: ClubBlackoutTheme.neonOrange,
          description: 'Will expose ${target.name} if voted out.',
          icon: Icons.visibility,
        ),
      );
    }

    // 15. Predator - Retaliation Target
    if (player.predatorTargetId != null) {
      final target = gameEngine.players.firstWhere(
        (p) => p.id == player.predatorTargetId,
        orElse: () => player,
      );
      statuses.add(
        PlayerStatusDisplay(
          label: 'RETALIATE: ${target.name}',
          color: ClubBlackoutTheme.neonRed,
          description: 'Will kill ${target.name} if voted out.',
          icon: Icons.gavel,
        ),
      );
    }

    // 16. Drama Queen - Pending Swap
    if (player.dramaQueenTargetAId != null ||
        player.dramaQueenTargetBId != null) {
      final targetA = player.dramaQueenTargetAId != null
          ? gameEngine.players.firstWhere(
              (p) => p.id == player.dramaQueenTargetAId,
              orElse: () => player,
            )
          : null;
      final targetB = player.dramaQueenTargetBId != null
          ? gameEngine.players.firstWhere(
              (p) => p.id == player.dramaQueenTargetBId,
              orElse: () => player,
            )
          : null;
      final label = targetA != null && targetB != null
          ? 'SWAP: ${targetA.name} ↔ ${targetB.name}'
          : 'SWAP PENDING';
      statuses.add(
        PlayerStatusDisplay(
          label: label,
          color: ClubBlackoutTheme.neonPurple,
          description: 'Drama Queen swap queued for next day.',
          icon: Icons.swap_horiz,
        ),
      );
    }

    // 17. Lightweight - Taboo Names
    if (player.tabooNames.isNotEmpty) {
      statuses.add(
        PlayerStatusDisplay(
          label: 'TABOO: ${player.tabooNames.join(', ')}',
          color: ClubBlackoutTheme.neonGold,
          description:
              'Cannot say these names aloud. If caught, dies immediately.',
          icon: Icons.error_outline,
        ),
      );
    }

    // 18. One-Time Abilities - Used
    if (player.silverFoxAbilityUsed && player.role.id == 'silver_fox') {
      statuses.add(
        PlayerStatusDisplay(
          label: 'ABILITY USED',
          color: Colors.grey,
          description: 'Silver Fox alibi already used.',
          icon: Icons.check_circle_outline,
        ),
      );
    }

    if (player.clingerAttackDogUsed && player.role.id == 'clinger') {
      statuses.add(
        PlayerStatusDisplay(
          label: 'ATTACK DOG USED',
          color: Colors.grey,
          description: 'Attack Dog kill already used.',
          icon: Icons.check_circle_outline,
        ),
      );
    }

    if (player.hasReviveToken && player.role.id == 'medic') {
      statuses.add(
        PlayerStatusDisplay(
          label: 'REVIVE USED',
          color: Colors.grey,
          description: 'One-time revive ability already used.',
          icon: Icons.check_circle_outline,
        ),
      );
    }

    // 19. Roofi/Bouncer - Ability State
    if (player.roofiAbilityRevoked && player.role.id == 'roofi') {
      statuses.add(
        PlayerStatusDisplay(
          label: 'ABILITY REVOKED',
          color: ClubBlackoutTheme.neonRed,
          description: 'Lost Roofi ability to Bouncer challenge.',
          icon: Icons.block,
        ),
      );
    }

    if (player.bouncerAbilityRevoked && player.role.id == 'bouncer') {
      statuses.add(
        PlayerStatusDisplay(
          label: 'ID CHECK REVOKED',
          color: ClubBlackoutTheme.neonRed,
          description: 'Lost ID check ability due to failed challenge.',
          icon: Icons.block,
        ),
      );
    }

    if (player.bouncerHasRoofiAbility && player.role.id == 'bouncer') {
      statuses.add(
        PlayerStatusDisplay(
          label: 'GAINED ROOFI POWER',
          color: ClubBlackoutTheme.neonGreen,
          description: 'Won Roofi ability from successful challenge.',
          icon: Icons.add_circle,
        ),
      );
    }

    return statuses;
  }
}
