# ROLE IMPLEMENTATION AUDIT - Club Blackout Android Game

**Date:** February 1, 2026  
**Status:** UPDATED (post-implementation refresh)

---

## EXECUTIVE SUMMARY

This audit was originally written during an earlier gap-analysis pass. As of the date above, the previously flagged gameplay-critical gaps (Whore deflection, Clinger vote sync/Attack Dog, Lightweight taboo assignment + violation handling, Second Wind conversion choice, and Bouncer↔Roofi challenge) have been implemented and covered by tests.

**Current state:**
- The only remaining true “missing role” is **The Host**, which is intentionally excluded from selection (facilitator role).
- A small number of mechanics remain **host-mediated** by design (e.g., Lightweight taboo speech violations; Ally Cat “meow-only” communication).

---

## ROLE-BY-ROLE IMPLEMENTATION STATUS

### ✅ FULLY IMPLEMENTED ROLES (13)

#### 1. **THE DEALER** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Kill one Party Animal each night via consensus
- **Script Implementation:** `_buildDealerSteps()` - explicit handler
  - dealer_wake, dealer_act (selectPlayer), dealer_sleep
  - Integrated with Whore and Wallflower wake calls
- **Ability Resolution:** YES - `dealerKill` (priority 5, effect: kill)
- **Night Flow:** Dealers wake first (priority 5), agree on target, kill resolved
- **Status:** ✅ Fully functional

---

#### 2. **THE PARTY ANIMAL** - ✅ FULLY IMPLEMENTED
- **Role Definition:** No abilities; survive and vote out Dealers
- **Script Implementation:** NONE (no night actions, nightPriority = 0)
- **Ability Resolution:** NONE (correct - passive role)
- **Status:** ✅ Correctly implemented as passive role

---

#### 3. **THE MEDIC** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Choose PROTECT (daily shield) OR REVIVE (once per game)
- **Script Implementation:** `_buildMedicSteps()` - explicit handler + Night 0 setup
  - medic_setup_choice (toggleOption on Night 0)
  - medic_mode (toggleOption during standard nights)
  - medic_target (selectPlayer with different rules for PROTECT vs REVIVE)
- **Ability Resolution:** YES
  - `medicProtect` (priority 2, effect: protect)
  - `medicRevive` (priority 1, effect: heal)
- **Night Flow:** Medic wakes at priority 2, chooses mode, selects target
- **Status:** ✅ Fully functional with binary choice persistence

---

#### 4. **THE BOUNCER - ID CHECK** - ✅ FULLY IMPLEMENTED
- **Role Definition:** 
  - Check I.D.: Investigate players to identify Dealers (nod if Dealer, shake if not)
  - Roofi Powers: Can challenge Roofi to steal their ability
- **Script Implementation:** `_buildBouncerSteps()` - explicit handler + Night 0 setup
  - bouncer_setup_acknowledge (confirms rules about Minor vulnerability)
  - bouncer_act (selectPlayer for ID check)
- **Ability Resolution:** ✅
  - ID checking logic: handled in game_engine.dart `handleScriptAction()`
  - Roofi challenge: handled in game_engine.dart `resolveBouncerRoofiChallenge()` (triggered via GameScreen FAB)
- **Night Flow:** Bouncer wakes at priority 2, selects player to ID, receives feedback
- **Status:** ✅ ID check + Roofi challenge mechanic implemented (with tests)

---

#### 5. **THE MINOR** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Cannot die unless Bouncer has I.D.'d her (checked identity)
- **Script Implementation:** NONE (passive mechanic)
- **Ability Resolution:** YES - special logic in `_resolveKill()` 
  - If Dealer targets Minor who hasn't been I.D.'d: kill fails, Minor marked as I.D.'d
  - If Dealer targets Minor after I.D.: kill succeeds
- **Game Engine:** `minorHasBeenIDd` flag properly tracked
- **Status:** ✅ Fully functional passive mechanic

---

#### 6. **THE SEASONED DRINKER** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Extra lives equal to number of Dealers; survives multiple kills
- **Script Implementation:** NONE (passive ability)
- **Ability Resolution:** YES - lives automatically set via `setLivesBasedOnDealers()`
- **Game Engine:** Kill logic respects `player.lives` counter
- **Status:** ✅ Fully functional - tested in 27-test suite

---

#### 7. **THE SOBER** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Once per night, send one player home → protected from night murders; if Dealer sent home, no murders occur
- **Script Implementation:** `_buildRoleSteps()` special case
  - sober_act (selectPlayer)
- **Ability Resolution:** YES - `soberSendHome` (priority 1, effect: protect)
- **Special Rule:** If Dealer target, no kills happen that night (handled in game_engine.dart)
- **Status:** ✅ Fully functional including special "no murders" rule

---

#### 8. **THE WALLFLOWER** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Optionally witness Dealer's murder during night to provide hints without getting caught
- **Script Implementation:** `_buildRoleSteps()` special case + integrated with Dealer wake
  - wallflower_act (optional choice to witness)
  - Wakes with Dealers (priority 5) to see the murder happen
- **Ability Resolution:** YES - information-only; no resolver needed
- **Night Flow:** Dealer target + Murder call → Wallflower may open eyes to see → provides hints next day
- **Status:** ✅ Fully functional

---

#### 9. **THE ROOFI** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Paralyze one player each night; cannot speak/act that round
- **Script Implementation:** `_buildRoleSteps()` special case
  - roofi_act (selectPlayer)
- **Ability Resolution:** YES - `roofiSilence` (priority 4, effect: silence)
- **Game Engine:** Silenced players have status effect applied; voting/speaking blocked
- **Status:** ✅ Fully functional

---

#### 10. **THE CLUB MANAGER** - ✅ FULLY IMPLEMENTED
- **Role Definition:** View one player's role card each night; help whichever side ensures own survival
- **Script Implementation:** `_buildRoleSteps()` special case
  - club_manager_act (selectPlayer to view)
- **Ability Resolution:** YES - information-only ability (no resolver needed)
- **Night Flow:** Club Manager views target's card each night
- **Status:** ✅ Fully functional as informational role

---

#### 11. **THE SILVER FOX** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Once per game, force a player to reveal role at night; entire club sees
- **Script Implementation:** `_buildRoleSteps()` special case
  - silver_fox_act (selectPlayer)
  - Flag: `silverFoxAbilityUsed` prevents reuse
- **Ability Resolution:** YES - `silverFoxReveal` (priority 1, effect: reveal)
- **Game Engine:** Reveal happens during morning announcement
- **Status:** ✅ Fully functional one-time ability

---

#### 12. **THE PREDATOR** - ✅ FULLY IMPLEMENTED
- **Role Definition:** If voted out during day, choose one voter to die with them (retaliation)
- **Script Implementation:** Handled in game_engine.dart `voteOutPlayer()` method
- **Ability Resolution:** YES - `predatorRetaliate` (trigger: onVoted, effect: kill)
- **Game Engine:** When Predator voted out, selects one voter to take down
- **Status:** ✅ Fully functional day-phase mechanic

---

#### 13. **THE TEA SPILLER** - ✅ FULLY IMPLEMENTED
- **Role Definition:** When dies, expose one player's role as either Dealer or Not
- **Script Implementation:** NONE (no night actions)
- **Ability Resolution:** YES - `teaSpillerReveal` (trigger: onDeath, effect: reveal)
- **Game Engine:** Death event triggers reveal ability
- **Status:** ✅ Fully functional death-trigger mechanic

---

### ⚠️ ROLES WITH LIMITATIONS / EXCLUSIONS

#### 1. **THE HOST** - ❌ NOT IMPLEMENTED
- **Role Definition:** Game Master; facilitate, refresh memory, set themes
- **Current State:** EXCLUDED FROM GAME
  - roleRepository filters: `r.id != 'host'`
  - No script generation
  - No ability resolution
- **Gap:** Entire role is non-functional; exists in roles.json but cannot be selected
- **Severity:** 🔴 CRITICAL (Role cannot be played at all)

---

#### 2. **THE WHORE** - ✅ FULLY IMPLEMENTED
- **Role Definition:** Defend Dealers; redirect a vote-out of a Dealer (or herself) onto a chosen scapegoat.
- **Current State:** ✅ IMPLEMENTED
  - Deflection target selection: `whore_deflect` script step (Night 1 only; one-time choice).
  - Selection constraints: alive, not the Whore, not a Dealer.
  - Vote deflection resolution: applied when a Dealer or the Whore would be voted out.
  - Persistence: stored on the player and survives save/load.
- **Game Engine:** Vote-out handling applies the deflection, marks it used, clears the target, and kills the scapegoat.
- **Tests:** `test/whore_deflection_test.dart`, `test/whore_test.dart`, `test/whore_save_load_test.dart`.

---

#### 3. **THE CLINGER** - ✅ FULLY IMPLEMENTED
- **Role Definition:**
  1. Must vote exactly as obsession partner does
  2. If partner dies, Clinger dies too
  3. If called "controller" by obsession, freed from obsession and gains ability to kill one player
- **Current State:** ✅ IMPLEMENTED
  - Night 0 obsession selection: `clinger_obsession` step sets the obsession and shows the role card.
  - Vote sync: enforced in the day phase via vote synchronization logic (Clinger must match the obsession’s vote).
  - Heartbreak death sync: `_handleClingerObsessionDeath()` kills the Clinger when the obsession dies.
  - “Controller” liberation: host-triggered via `freeClingerFromObsession(...)` (real-world call).
  - Attack Dog: when freed, Clinger receives `clinger_act` (one-time kill) and the engine enforces single-use.
- **Tests:** `test/gameplay_scenarios_test.dart`, `test/role_eventualities_matrix_test.dart`.

---

#### 4. **THE LIGHTWEIGHT** - ✅ FULLY IMPLEMENTED (HOST-MEDIATED)
- **Role Definition:** After each night, Host assigns a taboo name; if the Lightweight speaks that name, they die immediately.
- **Current State:** ✅ IMPLEMENTED
  - Night script step: `lightweight_act` (host points IRL, then selects the player in-app) adds the name to `tabooNames`.
  - Taboo tracking: stored on the Lightweight player and visible via status/tags.
  - Enforcement: `markLightweightTabooViolation(...)` lets the host trigger the instant-death rule (real-world speech).
- **Notes:** Automated speech detection is not in scope; enforcement is explicitly host-triggered.
- **Tests:** `test/lightweight_taboo_violation_test.dart`.

---

#### 5. **THE ALLY CAT** - ✅ FULLY IMPLEMENTED (AS-SCRIPTED)
- **Role Definition:**
  1. Vantage Point: Open eyes when Bouncer checks I.D.; only communicate via 'Meow'
  2. Nine Lives: Has 9 lives; survives 9 kill attempts
- **Current State:** ✅ IMPLEMENTED
  - Nine Lives: implemented via the standard death pipeline (Ally Cat absorbs death attempts until lives reach 0).
  - Vantage Point reminder: Ally Cat is woken alongside the Bouncer, with an explicit `ally_cat_meow` info step (Night 1).
  - Optional host logging/UX: `triggerMeowAlert()` can be used to record/display a meow moment.
- **Notes:** “Meow-only” communication is a real-world table rule; the app provides prompts/logging rather than enforcing speech.
- **Tests:** `test/ally_cat_test.dart` (Nine Lives).

---

#### 6. **THE CREEP** - ✅ FULLY IMPLEMENTED
- **Role Definition:**
  1. Choose one player on Night 0 to pretend to be (mimic their role/alliance)
  2. When mimicked player dies, Creep inherits their role
- **Current State:** ✅ IMPLEMENTED
  - Night 0 selection: `creep_act` (views target role card)
  - Mimicked alliance: Creep mirrors the target's alliance for social play
  - Inheritance: when the mimicked player dies, Creep takes their role and alliance
- **Tests:** `test/gameplay_scenarios_test.dart`

---

#### 7. **THE SECOND WIND** - ✅ FULLY IMPLEMENTED
- **Role Definition:**
  1. Starts as Party Animal
  2. If killed by Dealers, may be converted into a Dealer
  3. If converted: revives as Dealer and no one else dies that night
- **Current State:** ✅ IMPLEMENTED
  - Dealer kill sets pending conversion state.
  - Next night presents a host-only conversion decision (convert vs proceed with a normal Dealer kill).
  - Convert revives as Dealer and forfeits the Dealers’ kill that night.
- **Tests:** `test/second_wind_conversion_choice_test.dart`

---

#### 8. **THE DRAMA QUEEN** - ✅ FULLY IMPLEMENTED
- **Role Definition:** When voted out and dies, can swap two players' role cards.
- **Current State:** ✅ IMPLEMENTED
  - Night script marks two players for swapping.
  - On Drama Queen death, the swap becomes pending and can be completed via the host flow (`completeDramaQueenSwap`).
  - Swap persists for the remainder of the game.
- **Tests:** `test/role_eventualities_matrix_test.dart`, `test/game_engine_save_load_test.dart`, `test/self_targeting_prevention_test.dart`

---

#### 9. **THE BOUNCER - ROOFI CHALLENGE** - ✅ IMPLEMENTED
- Covered above in Bouncer entry; included here historically as a duplicate gap.
 
## DETAILED GAP ANALYSIS (CURRENT)

### 🔴 CRITICAL (1)

| Role | Gap | Notes |
|------|-----|------|
| **The Host** | Excluded from selection | Treated as facilitator, not a player role. |

### 🟡 Host-mediated / Manual Enforcement (by design)

| Mechanic | Why it’s manual |
|---|---|
| Lightweight taboo violations | Real-world speech rule; host triggers violation in-app. |
| Ally Cat “meow-only” communication | Real-world table rule; app provides prompts/logging only. |

---

## SCRIPT FLOW COMPLETENESS

### Night 0 (Setup Night) - Script Coverage

```
✅ Phase transition: "NIGHT FALLS"
✅ Creep: select target + view role card
✅ Clinger: select obsession + view role card
✅ Medic: choose PROTECT/REVIVE strategy
✅ Bouncer: acknowledge rules about Minor vulnerability
⏹️ End setup immediately (no actual actions)
✅ Phase transition: "NIGHT BREAKS" → Morning announcement
```

**Coverage:** 100% ✅

### Night 1+ (Standard Nights) - Script Coverage

```
✅ Phase transition: "NIGHT FALLS"
✅ Role wake notifications in priority order:
   ✅ Dealer (priority 5) - murder selection
   ✅ Medic (priority 2) - protection/revive choice
   ✅ Bouncer (priority 2) - I.D. check
   ✅ Roofi (priority 3) - paralyze selection
   ✅ Club Manager (priority 3) - view role
   ✅ Messy Bitch (priority 1) - spread rumour
   ✅ Silver Fox (priority 1) - force reveal
   ✅ Sober (priority 1) - send home (once per game)
  ✅ Clinger (priority 0) - conditional Attack Dog step when freed
  ✅ Whore (priority 0) - Night 1 deflection selection step
  ✅ Lightweight (priority 0) - taboo assignment step
  ✅ Second Wind - host-only conversion choice when pending
  ✅ Ally Cat - Night 1 reminder info step
   ✅ Others via generic _buildRoleSteps()

⚠️  Lightweight / Ally Cat: enforcement is host-mediated (real-world speech rule)
✅ Messy Bitch: Special kill after win condition

✅ Phase transition: "DAY BREAKS"
✅ Morning announcement with deaths reported
✅ Discussion phase
```

**Coverage:** ~100% (remaining items are host-mediated, not missing)

---

## ABILITY RESOLVER COVERAGE

### Implemented Abilities in AbilityResolver

```dart
✅ dealerKill (priority 5)
✅ medicProtect (priority 2)
✅ medicRevive (priority 1)
✅ roofiSilence (priority 4)
✅ seasonedDrinkerPassive (passive)
✅ minorProtection (passive - kill fail)
✅ messy_bitch_spread (priority 6)
✅ messy_bitch_kill (priority 7)
✅ teaSpillerReveal (onDeath trigger)
✅ predatorRetaliate (onVoted trigger)
✅ allyCatPassive (9 lives - kill respect)
✅ silverFoxReveal (priority 1)
✅ dramaQueenSwap (onDeath trigger)
✅ soberSendHome (priority 1)
```

**Total: 14 ability implementations**

### Notes on AbilityResolver

Several mechanics are implemented directly in `GameEngine` (script step handling, vote processing, and host-mediated flows), so the absence of a dedicated AbilityResolver entry does not indicate missing gameplay.

---

## GAME ENGINE INTEGRATION POINTS

### Phase Resolution - Properly Integrated ✅

- `_resolveNightPhase()` calls `abilityResolver.resolveAllAbilities()`
- Death reactions trigger properly via `reactionSystem.triggerEvent()`
- Late-joiner activation on night transition ✅
- Win condition checks via `checkGameEnd()`

### Missing Integration Points ⚠️

- **Speech enforcement:** Lightweight taboo and Ally Cat “meow-only” remain host-mediated.

---

## RECOMMENDATION PRIORITY

### Tier 1: CRITICAL
1. **Clarify The Host** - Keep excluded (recommended) or formally remove from selection/roles list.

### Tier 2: OPTIONAL UX
2. **Improve host-mediated affordances** - streamline taboo violation and “meow” logging flows.

### Tier 3: QUALITY
3. **Keep regression coverage green** - analyzer + `flutter test` remain the gate.

---

## SUMMARY TABLE

| Role | Status | Script | Resolver | Engine | Tests |
|------|--------|--------|----------|--------|-------|
| Dealer | ✅ | ✅ | ✅ | ✅ | ✅ |
| Party Animal | ✅ | ✅ | ✅ | ✅ | ✅ |
| Medic | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bouncer | ✅ | ✅ | ✅ | ✅ | ✅ |
| Minor | ✅ | ✅ | ✅ | ✅ | ✅ |
| Seasoned Drinker | ✅ | ✅ | ✅ | ✅ | ✅ |
| Sober | ✅ | ✅ | ✅ | ✅ | ✅ |
| Wallflower | ✅ | ✅ | ✅ | ✅ | ✅ |
| Roofi | ✅ | ✅ | ✅ | ✅ | ✅ |
| Club Manager | ✅ | ✅ | ✅ | ✅ | ✅ |
| Silver Fox | ✅ | ✅ | ✅ | ✅ | ✅ |
| Predator | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tea Spiller | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Host** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Whore** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Clinger** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Lightweight** | 🟡 | ✅ | 🟡 | ✅ | ✅ |
| **Ally Cat** | 🟡 | ✅ | 🟡 | ✅ | ✅ |
| **Creep** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Second Wind** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Drama Queen** | ✅ | ✅ | ✅ | ✅ | ✅ |

**Playable roles:** ✅ fully working  
**Host-mediated:** Lightweight, Ally Cat  
**Excluded from selection:** Host

---

## NEXT STEPS

1. ✅ **Keep regression coverage green** - analyzer + `flutter test` remain the gate.
2. Decide on **Host** handling - keep excluded (recommended) or formally remove from selection/roles list.
3. OPTIONAL: improve UX around host-mediated rules (taboo violation + “meow” logging shortcuts).

---

## Role Implementation Audit (Current)

### Properly wired through GameEngine
- Dealer: selection canonicalized to `kill`
- Medic: protect canonicalized to `protect`; revive handled via UI + dead list sync
- Bouncer: canonicalized to `bouncer_check`; sets `idCheckedByBouncer` and Minor flag
- Roofi: canonicalized to `roofi`; sets `silencedDay` (+ dealer block)
- Creep: canonicalized to `creep_target`; inheritance on victim death
- Clinger: obsession stored; heartbreak double-death on partner death
- Drama Queen / Tea Spiller: death reactions dispatched via ReactionSystem

### Known “UI-driven” (not fully engine-authored)
- Voting telemetry (per-voter) is not captured by current vote UI (uses tap counters, no voter ids).

## Role Implementation Audit

Primary consistency checks:
- `nightActions` step ids are canonicalized into engine keys in `_canonicalizeNightActions()`
- `deadPlayerIds` matches `players.where(!isAlive)`
- String enums: Medic choice is `PROTECT_DAILY` or `REVIVE` (engine + UI must match)

