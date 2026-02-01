# Sober "Sent Home" Complete Exemption Implementation

## Overview
When the Sober sends a player home at the start of the night, that player is **completely exempt** from all night phase interactions. They cannot perform actions, and most actions cannot affect them. Investigation roles (Bouncer, Roofi, Club Manager, Bartender) can target sent-home players but receive a special immunity message instead of normal results.

## Behavior by Role Type

### 🚫 Blocked Actions (Cannot Target Sent-Home Players)
These roles cannot target sent-home players at all:
- **Dealer** - Cannot kill
- **Medic** - Cannot protect or revive
- **Clinger** - Cannot attack
- **Lightweight** - Cannot add taboo
- **Messy Bitch** - Cannot spread rumor
- **Silver Fox** - Cannot give alibi
- **Creep** - Cannot choose mimic target
- **Drama Queen** - Cannot mark for swap

**Result:** Action is rejected with log message: *"Invalid target: {name} was sent home by The Sober — cannot be targeted tonight."*

### 🔍 Investigation Actions (Show Immunity Message)
These roles can target sent-home players but get an immunity message instead of their normal result:
- **Bouncer** - Instead of revealing alliance/dealer status
- **Roofi** - Instead of silencing the player
- **Club Manager** - Instead of revealing role
- **Bartender** - Instead of revealing team comparison

**Result:** 
- Action is logged in `nightActions`
- Host receives alert: *"{name} was sent home early and is immune to all night requests."*
- No actual effect occurs (no ID check, no silence, no role reveal)

## Implementation Details

### 1. Script Generation Protection (script_builder.dart)
**Location:** Line 166  
**Code:**
```dart
if (p.soberSentHome) continue; // Skip players sent home by Sober
```
**Effect:** Players with `soberSentHome = true` are skipped when building the night script, preventing them from waking up to perform their role actions.

### 2. UI Selection Protection (game_screen.dart)
**Location:** Line 2485  
**Code:**
```dart
final players = sortedPlayersByDisplayName(
  widget.gameEngine.players
      .where((p) => p.isAlive && p.role.id != 'host' && !p.soberSentHome)
      .toList(),
);
```
**Effect:** Sent-home players are filtered out from the player selection list in the UI, making them unselectable as targets.

### 3. Action Source Protection (game_engine.dart)
**Location:** Line 2448  
**Code:**
```dart
if (sourcePlayer != null && sourcePlayer.soberSentHome) {
  logAction(step.title,
      '${sourcePlayer.name} is SENT HOME and cannot act right now.');
  return;
}
```
**Effect:** If a sent-home player somehow tries to perform an action, it's blocked and logged.

### 4. Action Target Protection (game_engine.dart) - **UPDATED**
**Locations:** Various role handlers (Dealer, Medic, Clinger, etc.)

**Harmful/Manipulation Actions - Blocked:**
```dart
// Example: Dealer kill
if (target.soberSentHome) {
  logAction(step.title,
      'Invalid target: ${target.name} was sent home by The Sober — cannot be targeted tonight.');
  break;
}
```

**Investigation Actions - Show Immunity Message:**
```dart
// Example: Bouncer ID check
if (target.soberSentHome) {
  nightActions['bouncer_check'] = target.id;
  queueHostAlert(
    title: 'Sent Home Early',
    message: '${target.name} was sent home early and is immune to all night requests.',
  );
  logAction(step.title,
      'Bouncer tried to ID ${target.name}, but they were sent home by The Sober.',
      toast: _currentPhase == GamePhase.night);
  break;
}
```

**Effect:** 
- **Harmful actions** (kills, protections, manipulations) are completely blocked
- **Investigation actions** (Bouncer, Roofi, Club Manager, Bartender) show immunity message instead of normal results
- This prevents ALL night actions from affecting sent-home players while still providing feedback to investigation roles

### 5. Death Protection (game_engine.dart)
**Location:** Line 1334  
**Code:**
```dart
if ((isDealerKillAttempt || isClingerKill) && victim.soberSentHome) {
  logAction(
    'Sober',
    '${victim.name} would have died, but was sent home by The Sober.',
  );
  return;
}
```
**Effect:** Sent-home players cannot die from night murders (Dealer kills, Clinger attacks).

### 6. Status Reset (game_engine.dart)
**Location:** Lines 1202 and 1258  
**Code:**
```dart
for (final p in players) {
  p.soberSentHome = false;
}
```
**Effect:** The `soberSentHome` flag is automatically reset when transitioning from night to day, allowing players to participate normally in the next day phase and subsequent nights.

## Test Coverage

### Existing Tests (sober_test.dart)
- ✅ Sent-home player excluded from night script
- ✅ Dealer sent home triggers blocked kill message
- ✅ Wallflower skipped if Dealer sent home

### New Tests (sober_sent_home_targeting_test.dart)
- ✅ Sent-home player cannot be targeted by Dealer kill (blocked)
- ✅ Sent-home player cannot be targeted by Bouncer ID check (shows immunity message)
- ✅ Sent-home player cannot be targeted by Roofi silence (shows immunity message)
- ✅ Sent-home player cannot be targeted by Medic protection (blocked)
- ✅ Multiple target actions show immunity if any target is sent home (Bartender)
- ✅ Sent-home status resets during phase transition

### Integration Tests (gameplay_scenarios_test.dart)
- ✅ All 41 gameplay scenario tests pass with new protection logic

## Behavior Summary

When the Sober sends a player home:

1. **Script Phase:** Player's role action is removed from the night script
2. **Selection Phase:** Player cannot be selected as a target in the UI
3. **Action Phase:** 
   - Player cannot perform their own night action
   - **Harmful/manipulation actions** cannot target them (blocked)
   - **Investigation actions** can target them but show immunity message instead
4. **Resolution Phase:** Player cannot die from night murders
5. **Transition Phase:** `soberSentHome` status resets when day begins

## Edge Cases Handled

- ✅ **Investigation roles:** Bouncer, Roofi, Club Manager, Bartender can target sent-home players but receive immunity message instead of normal results
- ✅ **Harmful actions:** Dealer kills, Medic protection, Clinger attacks, etc. are completely blocked
- ✅ **Multiple targets:** Bartender shows immunity if any target is sent home
- ✅ **UI bypass protection:** Even if the UI filter is bypassed somehow, the game engine validates and blocks/shows immunity
- ✅ **Death attempts:** All night kill attempts (Dealer, Clinger) are blocked at the action handler level
- ✅ **Beneficial actions:** Protective actions (Medic) cannot target sent-home players
- ✅ **Special cases:** Dealer sent home cancels ALL Dealer kills that night (existing behavior preserved)

## Game Balance Impact

- **Sober's power:** Remains as intended - once per night, send one player home to protect them
- **Counter-play:** Investigation roles can still try to target sent-home players to learn they were protected
- **Information asymmetry:** Investigation roles get feedback that player was sent home, adding strategic depth
- **Absolute protection:** Harmful actions cannot bypass the protection
- **Strategic depth:** Players must consider that sent-home players are protected from manipulation but investigation attempts reveal the protection
- **Reset timing:** Status clears at day start, maintaining phase boundaries

## Files Modified

1. **lib/logic/game_engine.dart** - Added target validation in `handleScriptAction`
2. **test/sober_sent_home_targeting_test.dart** - New comprehensive test file

## Test Results

```
All tests passed!
- 3 Sober mechanic tests
- 6 Sent-home targeting tests
- 41 Gameplay scenario tests
Total: 50 tests passing
```

## Migration Notes

**No breaking changes** - This is a defensive enhancement that adds additional validation. Existing games will continue to work correctly, and the new protection layer prevents edge cases that could theoretically occur through UI manipulation or future feature additions.
