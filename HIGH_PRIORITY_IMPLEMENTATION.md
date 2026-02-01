# High Priority Role Mechanics - Implementation Summary

## Completed Implementation (Phase 1)

### 1. Club Manager - View Role Card ✅
**Status:** COMPLETE

**Changes:**
- `roles.json`: Updated night_priority from 4 to 3, added `"ability": "view_role"`
- `script_builder.dart`: Added custom script step with clear instructions to show the selected player's character card
- `game_engine.dart`: Added handler in `handleScriptAction` to log which role was viewed

**How it works:**
- Club Manager wakes at priority 3 (before Roofi)
- Selects one player
- Host shows that player's character card to the Club Manager
- Logged for game review

---

### 2. Silver Fox - Force Reveal ✅
### 2. Silver Fox - Nightly Alibi ✅
**Status:** COMPLETE

**Changes:**
- `roles.json`: Defines “NIGHTLY ALIBI” (priority 1)
- `player.dart`: Tracks alibi state via `alibiDay`
- `script_builder.dart`: Adds Silver Fox selection step
- `game_engine.dart`: Applies alibi to target and makes votes against them not count

**How it works:**
- Silver Fox wakes at priority 1
- Chooses one player
- During the following day: votes against that player do not count; `voteOutPlayer` refuses elimination

---

### 3. Wallflower - Witness Murder ✅
**Status:** COMPLETE

**Changes:**
- `roles.json`: Updated night_priority from 4 to 5, added `"ability": "witness_murder"`
- `script_step.dart`: Added `ScriptActionType.optional` enum value
- `script_builder.dart`: Added custom script step for optional witnessing
- `game_engine.dart`: Added handler that checks if Wallflower chose to witness, reveals dealer target

**How it works:**
- Wallflower wakes at priority 5 (after Dealer kill at priority 5)
- Optional action: can choose to witness or not
- If they witness, host reveals who the Dealers targeted
- Information is logged

---

### 4. The Sober - Send Home ✅
**Status:** COMPLETE

**Changes:**
- `roles.json`: Updated night_priority from 0 to 1, added `"ability": "send_home"`
- `player.dart`: Added `soberSentHome` (night-scoped) state + retained `soberAbilityUsed` for backwards-compatibility
- `script_builder.dart`: Added custom script step for Sober (priority 1)
- `game_engine.dart`: Added handler that:
  - Marks the target as sent home for the night
  - Cancels night murders (and Dealer murders) against sent-home targets
  - Special logic: if target is a Dealer, cancels ALL Dealer murders that night

**How it works:**
- Sober wakes at priority 1 (very early, before kills)
- Each night, sends one player home (protected from death)
- If the sent-home player is a Dealer, NO murders happen that night
- The sent-home state is tracked via `Player.soberSentHome` (cleared when the Day ends)

---

### 5. Minor - Death Protection ✅
**Status:** COMPLETE

**Changes:**
- `player.dart`: Added `minorHasBeenIDd` boolean field (already existed from previous work)
- `ability_system.dart`: Updated `_resolveKill` method to check for Minor
  - If target is Minor AND not yet ID'd, survives but becomes ID'd
  - If Minor is ID'd, dies normally
- `game_engine.dart`: Updated `_resolveNightPhase` to handle Minor protection logging
  - Shows special message when Minor survives an attack
  - Announces they've been ID'd

**How it works:**
- Minor is passive (no night action)
- First time Dealers target Minor, they survive but become "ID'd"
- `minorHasBeenIDd` is set to true, removing protection
- Second attack kills Minor normally
- Bouncer checking Minor's ID also sets this flag (already implemented)

---

## Priority Order (Night Phase)

1. **Silver Fox** (priority 1) - Force reveal
2. **The Sober** (priority 1) - Send home / protection
3. **Medic/Bouncer** (priority 2) - Protection
4. **Club Manager** (priority 3) - View role
5. **Roofi** (priority 4) - Silence
6. **Dealer** (priority 5) - Kill
7. **Wallflower** (priority 5) - Witness (after Dealer)
8. **Messy Bitch** (priority 6) - Spread rumour

---

## Testing Checklist

- [x] Club Manager can view a role card each night
- [x] Silver Fox can apply nightly alibi
- [x] Votes against an alibied target do not count
- [x] Wallflower can optionally witness Dealer target
- [x] Sober can send someone home each night
- [x] Sober sending a Dealer home cancels all kills
- [x] Minor survives first attack
- [x] Minor becomes vulnerable after first attack
- [x] Minor protection message appears correctly
- [x] Bouncer ID'ing Minor removes protection

---

## Next Steps (Medium Priority)

1. Add/extend widget tests for key host UI flows (optional)
2. Keep tightening edge-case coverage via scenario/matrix tests
3. Maintain analyzer + tests as a hard gate

---

## High Priority Implementation

1. ✅ Green `flutter analyze`
2. ✅ Script UI + engine wiring locked in
3. ✅ Added unit coverage for canonicalization, Second Wind, and save/load consistency

