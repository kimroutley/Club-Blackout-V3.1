# Self-Targeting Prevention Rules

## Overview
To prevent game logic inconsistencies and ensure balanced gameplay, the game engine implements self-targeting prevention rules that prevent players from targeting themselves with certain abilities.

## Implemented Self-Targeting Prevention Rules

### 🚫 **Voting System**
**Rule:** Players cannot vote for themselves during day phases.  
**Implementation:** `recordVote()` method in GameEngine  
**Error Message:** "Player cannot vote for themselves."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L512-L530)

```dart
// Prevent self-voting
if (targetId == voterId) {
  logAction('Self-Vote Prevention', '${voter?.name ?? 'Player'} cannot vote for themselves.');
  return;
}
```

### 🎯 **Night Action Targeting**

#### **Dealer Kill**
**Rule:** Dealers cannot kill themselves during night actions.  
**Implementation:** `handleScriptAction()` case 'dealer'  
**Error Message:** "Invalid target: Dealers cannot eliminate themselves."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L2670-L2690)

```dart
// Block dealers from killing themselves
if (target.role.id == 'dealer') {
  logAction(step.title, 'Invalid target: Dealers cannot eliminate themselves.');
  break;
}
```

#### **Drama Queen Swap**
**Rule:** Drama Queen cannot include themselves in role swaps.  
**Implementation:** `handleScriptAction()` case 'drama_queen'  
**Error Message:** "Invalid selection: Drama Queen cannot include themselves in the swap."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L3077-L3098)

```dart
// Prevent self-targeting in Drama Queen swap
if (sourcePlayer != null && 
    (a.id == sourcePlayer.id || b.id == sourcePlayer.id)) {
  logAction(step.title, 'Invalid selection: Drama Queen cannot include themselves in the swap.');
  break;
}
```

#### **Bouncer ID Check**
**Rule:** Bouncer cannot perform ID checks on themselves.  
**Implementation:** `handleScriptAction()` case 'bouncer'  
**Error Message:** "Invalid target: Bouncer cannot check themselves."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L2809-L2830)

```dart
// Prevent self-targeting
if (sourcePlayer != null && target.id == sourcePlayer.id) {
  logAction(step.title, 'Invalid target: Bouncer cannot check themselves.');
  break;
}
```

#### **Roofi Silence**
**Rule:** Roofi cannot silence themselves.  
**Implementation:** `handleScriptAction()` case 'roofi'  
**Error Message:** "Invalid target: Roofi cannot silence themselves."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L2890-L2905)

```dart
// Prevent self-targeting  
if (sourcePlayer != null && target.id == sourcePlayer.id) {
  logAction(step.title, 'Invalid target: Roofi cannot silence themselves.');
  break;
}
```

#### **Sober Send Home**
**Rule:** Sober cannot send themselves home.  
**Implementation:** `handleScriptAction()` case 'sober'  
**Error Message:** "Invalid target: Sober cannot send themselves home."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L2790-L2815)

```dart
// Prevent self-targeting
if (sourcePlayer != null && target.id == sourcePlayer.id) {
  logAction(step.title, 'Invalid target: Sober cannot send themselves home.');
  break;
}
```

#### **Medic Protect/Revive**
**Rule:** Medic cannot protect or revive themselves.  
**Implementation:** `handleScriptAction()` case 'medic'  
**Error Message:** "Invalid target: Medic cannot protect or revive themselves."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L2841-L2870)

```dart
// Prevent self-targeting
if (sourcePlayer != null && target.id == sourcePlayer.id) {
  logAction(step.title, 'Invalid target: Medic cannot protect or revive themselves.');
  break;
}
```

#### **Silver Fox Alibi**
**Rule:** Silver Fox cannot give themselves an alibi.  
**Implementation:** `handleScriptAction()` case 'silver_fox'  
**Error Message:** "Invalid target: Silver Fox cannot give themselves an alibi."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L2824-L2845)

```dart
// Prevent self-targeting
if (sourcePlayer != null && silverTarget.id == sourcePlayer.id) {
  logAction(step.title, 'Invalid target: Silver Fox cannot give themselves an alibi.');
  break;
}
```

### ✅ **Already Implemented Prevention**

#### **Club Manager View**
**Rule:** Club Manager cannot view themselves.  
**Implementation:** Already exists in codebase  
**Error Message:** "Club Manager must choose a fellow player."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L3316-L3335)

#### **Messy Bitch Rumour**
**Rule:** Messy Bitch cannot spread rumours about themselves.  
**Implementation:** Already exists in codebase  
**Error Message:** "Messy Bitch must choose another living player."  
**Location:** [lib/logic/game_engine.dart](lib/logic/game_engine.dart#L3129-L3175)

### 🔄 **Roles Without Self-Targeting Issues**

#### **Tea Spiller**
- No self-targeting prevention needed
- Target selection happens on death, not during night actions
- Engine automatically filters to voters who targeted Tea Spiller

#### **Predator**
- No night action in current implementation (commented out)
- Retaliation target chosen by host from eligible voters

#### **Clinger**
- Attack Dog ability targets enemies, not self-selection issue

## Testing

Self-targeting prevention is tested in [test/self_targeting_prevention_test.dart](test/self_targeting_prevention_test.dart) with comprehensive test cases covering:

- ✅ Dealer self-kill prevention
- ✅ Voting self-targeting prevention  
- ✅ Drama Queen swap self-inclusion prevention
- ✅ Bouncer self-check prevention
- ✅ Roofi self-silence prevention
- ✅ Sober self-send-home prevention
- ✅ Silver Fox self-alibi prevention

## Benefits

### **Game Balance**
- Prevents players from accidentally or intentionally undermining their own abilities
- Ensures roles maintain their intended strategic purpose
- Eliminates edge cases that could break game flow

### **User Experience**
- Clear error messages help players understand game rules
- Prevents frustrating misclicks or strategic errors
- Consistent behavior across all targeting abilities

### **Code Reliability**
- Standardized validation pattern across all night actions
- Reduces potential for game state corruption
- Makes debugging easier with clear error logging

## Implementation Pattern

All self-targeting prevention follows this consistent pattern:

```dart
// Standard self-targeting check
if (sourcePlayer != null && target.id == sourcePlayer.id) {
  logAction(step.title, 'Invalid target: [Role] cannot [action] themselves.');
  break;
}
```

This ensures consistent behavior, clear error messages, and maintainable code across the entire game engine.