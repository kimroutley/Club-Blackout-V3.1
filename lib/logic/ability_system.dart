import '../models/player.dart';

/// Defines when an ability can be triggered
enum AbilityTrigger {
  nightAction, // During night phase, player's turn
  dayAction, // During day phase
  onDeath, // When the player dies
  onOtherDeath, // When another player dies
  onVoted, // When player is voted for
  onVoteOther, // When player votes for someone
  onProtected, // When player is protected
  onAttacked, // When player is targeted for kill
  onReveal, // When player's role is revealed
  passive, // Always active (e.g., extra lives)
  startup, // At game start (e.g., Creep choice, Medic choice)
}

/// Coarse-grained effect type for queued abilities.
///
/// This is primarily used for serialization/test introspection.
enum AbilityEffect {
  kill,
  protect,
  reveal,
  block,
  redirect,
  mark,
  silence,
  rumour,
  heartbreak,
  mimic,
  investigate,
  other,
}

/// Represents a game ability with triggers and effects
class Ability {
  final String id;
  final String name;
  final String description;
  final AbilityTrigger trigger;
  final int priority; // Lower = earlier in night phase

  const Ability({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    this.priority = 0,
  });
}

/// Represents an ability instance that has been activated
class ActiveAbility {
  final String abilityId;
  final String sourcePlayerId;
  final List<String> targetPlayerIds;
  final AbilityTrigger? trigger;
  final AbilityEffect? effect;
  final int priority;
  final Map<String, dynamic> metadata;

  const ActiveAbility({
    required this.abilityId,
    required this.sourcePlayerId,
    this.targetPlayerIds = const [],
    this.trigger,
    this.effect,
    this.priority = 0,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'abilityId': abilityId,
        'sourcePlayerId': sourcePlayerId,
        'targetPlayerIds': targetPlayerIds,
        'trigger': trigger?.index,
        'effect': effect?.index,
        'priority': priority,
        'metadata': metadata,
      };

  ActiveAbility copy() {
    return ActiveAbility(
      abilityId: abilityId,
      sourcePlayerId: sourcePlayerId,
      targetPlayerIds: List<String>.from(targetPlayerIds),
      trigger: trigger,
      effect: effect,
      priority: priority,
      metadata: Map<String, dynamic>.from(metadata),
    );
  }

  factory ActiveAbility.fromJson(Map<String, dynamic> json) {
    return ActiveAbility(
      abilityId: json['abilityId'] as String,
      sourcePlayerId: json['sourcePlayerId'] as String,
      targetPlayerIds: (json['targetPlayerIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      trigger: (json['trigger'] is int)
          ? AbilityTrigger.values[(json['trigger'] as int)
              .clamp(0, AbilityTrigger.values.length - 1)]
          : null,
      effect: (json['effect'] is int)
          ? AbilityEffect.values[
              (json['effect'] as int).clamp(0, AbilityEffect.values.length - 1)]
          : null,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

/// Result of an ability resolution
class AbilityResult {
  final String abilityId;
  final bool success;
  final List<String> targets;
  final Map<String, dynamic> metadata;

  const AbilityResult({
    required this.abilityId,
    this.success = true,
    this.targets = const [],
    this.metadata = const {},
  });
}

/// Library of all abilities in the game
class AbilityLibrary {
  static final Map<String, List<Ability>> _roleAbilities = {
    'dealer': [
      const Ability(
          id: 'dealer_kill',
          name: 'Hit',
          description: 'Eliminate a guest.',
          trigger: AbilityTrigger.nightAction,
          priority: 50)
    ],
    'medic': [
      const Ability(
          id: 'medic_protect',
          name: 'Triage',
          description: 'Grant immunity tonight.',
          trigger: AbilityTrigger.nightAction,
          priority: 20)
    ],
    'bouncer': [
      const Ability(
          id: 'bouncer_id_check',
          name: 'ID Check',
          description: 'See faction.',
          trigger: AbilityTrigger.nightAction,
          priority: 30)
    ],
    'sober': [
      const Ability(
          id: 'sober_send_home',
          name: 'Send Home',
          description: 'Blocks all actions against target.',
          trigger: AbilityTrigger.nightAction,
          priority: 1)
    ],
    'roofi': [
      const Ability(
          id: 'roofi_silence',
          name: 'Silence',
          description: 'Silences a player for the next day.',
          trigger: AbilityTrigger.nightAction,
          priority: 35)
    ],
    'clinger': [
      const Ability(
          id: 'clinger_obsession',
          name: 'Obsess',
          description: 'Setup obsess target.',
          trigger: AbilityTrigger.startup,
          priority: 40),
      const Ability(
          id: 'clinger_kill',
          name: 'Attack Dog',
          description: 'Kill ordered by dealer.',
          trigger: AbilityTrigger.nightAction,
          priority: 45)
    ],
    'messy_bitch': [
      const Ability(
          id: 'messy_bitch_rumour',
          name: 'Tumour',
          description: 'Start a rumour about a player.',
          trigger: AbilityTrigger.nightAction,
          priority: 60)
    ],
    'wallflower': [
      const Ability(
          id: 'wallflower_witness',
          name: 'Witness',
          description: 'Observe a player.',
          trigger: AbilityTrigger.nightAction,
          priority: 70)
    ],
    'creep': [
      const Ability(
          id: 'creep_mimic',
          name: 'Mimic',
          description: 'Mimic another role.',
          trigger: AbilityTrigger.startup,
          priority: 80)
    ],
    'drama_queen': [
      const Ability(
          id: 'drama_queen_swap',
          name: 'Scene Stealer',
          description: 'Swap roles on death.',
          trigger: AbilityTrigger.onDeath,
          priority: 10)
    ],
    'tea_spiller': [
      const Ability(
          id: 'tea_spiller_reveal',
          name: 'Spill Tea',
          description: 'Expose role on death.',
          trigger: AbilityTrigger.onDeath,
          priority: 5)
    ],
  };

  /// Get abilities for a specific role
  static List<Ability> getAbilitiesForRole(String roleId) =>
      _roleAbilities[roleId] ?? [];
}

/// Manages ability resolution and interactions
class AbilityResolver {
  final List<ActiveAbility> _queue = [];
  final List<ActiveAbility> _deadLetterQueue = []; // Actions that failed/were invalid

  /// Add an ability to the queue
  void queueAbility(ActiveAbility ability) {
    _queue.add(ability);
  }

  /// Clear all queued abilities and effects
  void clear() {
    _queue.clear();
    _deadLetterQueue.clear();
  }

  // Persistence support
  Map<String, dynamic> toJson() => {
        'queue': _queue.map((a) => a.toJson()).toList(),
        'deadLetterQueue': _deadLetterQueue.map((a) => a.toJson()).toList(),
      };

  void loadFromJson(Map<String, dynamic> json) {
    _queue.clear();
    _deadLetterQueue.clear();
    
    final q = json['queue'];
    if (q is List) {
      for (final entry in q) {
        if (entry is Map<String, dynamic>) {
          _queue.add(ActiveAbility.fromJson(entry));
        } else if (entry is Map) {
          _queue.add(ActiveAbility.fromJson(entry.cast<String, dynamic>()));
        }
      }
    }
    
    final dlq = json['deadLetterQueue'];
    if (dlq is List) {
      for (final entry in dlq) {
        if (entry is Map<String, dynamic>) {
          _deadLetterQueue.add(ActiveAbility.fromJson(entry));
        } else if (entry is Map) {
          _deadLetterQueue.add(ActiveAbility.fromJson(entry.cast<String, dynamic>()));
        }
      }
    }
  }

  AbilityResolver copy() {
    final copy = AbilityResolver();
    copy._queue.addAll(_queue.map((a) => a.copy()));
    copy._deadLetterQueue.addAll(_deadLetterQueue.map((a) => a.copy()));
    return copy;
  }

  void copyFrom(AbilityResolver other) {
    _queue.clear();
    _queue.addAll(other._queue.map((a) => a.copy()));
    _deadLetterQueue.clear();
    _deadLetterQueue.addAll(other._deadLetterQueue.map((a) => a.copy()));
  }

  /// Checks if a player is targeted by a specific ability
  bool isTargetedBy(String abilityId, String targetId) {
    return _queue.any((a) =>
        a.abilityId == abilityId && a.targetPlayerIds.contains(targetId));
  }
  
  /// Gets the first target ID for a specific ability (convenience method)
  String? getActionTarget(String abilityId) {
    final ability = _queue.where((a) => a.abilityId == abilityId).firstOrNull;
    return ability?.targetPlayerIds.firstOrNull;
  }

  /// Removes all abilities queued by a specific source player
  void removeAbilitiesForSource(String sourcePlayerId) {
    _queue.removeWhere((a) => a.sourcePlayerId == sourcePlayerId);
  }

  /// Process all queued abilities in priority order
  List<AbilityResult> resolveAllAbilities(List<Player> players) {
    // 1. Sort by Priority
    _queue.sort((a, b) => a.priority.compareTo(b.priority));

    final List<AbilityResult> results = [];
    final protectedPlayerIds = <String>{}; // Tracks all protected players (for reporting/logic)
    final immuneToAll = <String>{}; // Sober targets (blocks everything)
    final immuneToKill = <String>{}; // Medic targets (blocks kill only)
    final killedPlayerIds = <String>{}; // Tracks players killed this turn
    final blockedSourceIds = <String>{}; // Sources prevented from acting (e.g. Sent Home)

    // Helper to find player by ID
    Player? getPlayer(String id) {
      try {
        return players.firstWhere((p) => p.id == id);
      } catch (e) {
        return null;
      }
    }

    // 2. Iterate through queue
    for (final ability in _queue) {
      // Check if source is blocked (e.g. Sent Home or Paralyzed/Roofied earlier)
      if (blockedSourceIds.contains(ability.sourcePlayerId)) {
        results.add(AbilityResult(
            abilityId: ability.abilityId,
            targets: [],
            success: false,
            metadata: {'blocked_source': true}));
        continue;
      }

      // Logic for Sober (Priority 1)
      if (ability.abilityId == 'sober_send_home') {
        immuneToAll.addAll(ability.targetPlayerIds);
        protectedPlayerIds.addAll(ability.targetPlayerIds);
        blockedSourceIds.addAll(ability.targetPlayerIds); // Sent home = cannot act
        results.add(AbilityResult(
            abilityId: ability.abilityId,
            targets: ability.targetPlayerIds,
            success: true));
        continue;
      }

      // Logic for Medic (Priority 20)
      if (ability.abilityId == 'medic_protect') {
        final validTargets = <String>[];
        for (final tid in ability.targetPlayerIds) {
           if (!immuneToAll.contains(tid)) validTargets.add(tid);
        }

        immuneToKill.addAll(validTargets);
        protectedPlayerIds.addAll(validTargets);
        results.add(AbilityResult(
            abilityId: ability.abilityId,
            targets: validTargets,
            success: validTargets.isNotEmpty));
        continue;
      }

      // Logic for Roofi (Priority 35)
      if (ability.abilityId == 'roofi_silence') {
         final validTargets = <String>[];
         final blockedTargets = <String>[];
         for (final tid in ability.targetPlayerIds) {
             if (immuneToAll.contains(tid)) {
                 blockedTargets.add(tid);
             } else {
                 validTargets.add(tid);
             }
         }
         
         blockedSourceIds.addAll(validTargets); // Paralyzed = cannot act later (e.g. Dealer Kill at 50)
         
         results.add(AbilityResult(
             abilityId: ability.abilityId, 
             targets: validTargets, 
             success: validTargets.isNotEmpty,
             metadata: blockedTargets.isNotEmpty ? {'blocked_by_sober': blockedTargets} : {}
         ));
         continue;
      }

      // Logic for Kills (Dealer/Clinger)
      if (ability.abilityId == 'dealer_kill' ||
          ability.abilityId == 'clinger_kill') {
        final killed = <String>[];
        final saved = <String>[];
        final minorBlocked = <String>[];

        for (final tid in ability.targetPlayerIds) {
          final targetPlayer = getPlayer(tid);

          // Check Sober Protection (Blocks everything)
          if (immuneToAll.contains(tid)) {
            saved.add(tid);
            continue;
          }

          // Check Medic Protection (Blocks Kill)
          if (immuneToKill.contains(tid)) {
            saved.add(tid); // Metadata protected: true
            continue;
          }

          // Check Minor Protection Logic
          // If Target is Minor + !ID'd + Source is Dealer -> Block Kill
          if (targetPlayer != null &&
              ability.abilityId == 'dealer_kill' &&
              targetPlayer.role.id == 'minor' &&
              !targetPlayer.minorHasBeenIDd) {
            minorBlocked.add(tid);
            continue;
          }

          // If no protection, kill succeeds
          killed.add(tid);
          killedPlayerIds.add(tid);
        }

        // Construct Metadata
        final metadata = <String, dynamic>{};
        if (saved.isNotEmpty) metadata['protected'] = saved;
        if (minorBlocked.isNotEmpty) metadata['minor_protected'] = minorBlocked;

        results.add(AbilityResult(
            abilityId: ability.abilityId,
            targets: killed,
            metadata: metadata,
            success: killed.isNotEmpty));
        continue;
      }

      // Logic for Others (Silence, Rumour, etc.)
      // These generally succeed unless target is Sober-protected (immuneToAll)
      final successfulTargets = <String>[];
      final blockedTargets = <String>[];

      for (final tid in ability.targetPlayerIds) {
        if (immuneToAll.contains(tid)) {
          blockedTargets.add(tid);
        } else {
          successfulTargets.add(tid);
        }
      }

      results.add(AbilityResult(
        abilityId: ability.abilityId,
        targets: successfulTargets,
        metadata:
            blockedTargets.isNotEmpty ? {'blocked_by_sober': blockedTargets} : {},
        success: successfulTargets.isNotEmpty,
      ));
    }

    return results;
  }
}
