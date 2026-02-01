# Role Implementation Status

Legend:
- ✅ Engine + UI consistent
- 🟡 Partially (UI-only or missing engine resolution)
- ❌ Not implemented

| Role | Status | Notes |
|---|---:|---|
| Dealer | ✅ | Canonical key `kill` bridged from `dealer_act` |
| Medic | ✅ | Protect via engine; revive via Host/FAB triggers engine logic |
| Bouncer | ✅ | Sets flags; Minor interaction present |
| Roofi | ✅ | Silence + dealer block flags |
| Second Wind | ✅ | Now only triggers on Dealer kill |
| Creep | ✅ | Inheritance via `processDeath` |
| Clinger | ✅ | Vote sync + heartbreak + Attack Dog supported |
| Drama Queen | ✅ | Swap is queued on death; host completes swap in HostOverview |
| Tea Spiller | ✅ | Mark stored in engine; death reveal resolved via engine logging/host flow |
| Predator | ✅ | Mark stored; retaliation resolved via HostOverview |

## ✅ Fully Implemented Roles

### The Dealer
- ✅ Night kill action (priority 5)
- ✅ Team coordination
- ✅ Script steps generated

### The Whore
- ✅ Wakes with Dealers
- ✅ Deflection setup (Night Step)
- ✅ Vote deflection mechanic (GameEngine & Vote UI)
- ✅ Notification when vote deflected

### The Medic  
- ✅ Binary choice at Night 1 (PROTECT vs REVIVE)
- ✅ Protect action (priority 2)
- ✅ REVIVE implemented via FAB Menu

### The Bouncer
- ✅ ID check action (priority 2)
- ✅ Marks Minor as ID'd (removes death protection)
- ✅ Can challenge Roofi (one-time): success steals paralysis; failure revokes ID checks

### The Messy Bitch
- ✅ Rumor spreading (priority 6)
- ✅ Win condition check
- ✅ Special kill after win condition

### The Roofi
- ✅ Silence/paralyze action (priority 4)
- ℹ️ Optional enhancement: extended paralyze for Dealers (2 rounds) (not implemented)
- ✅ Can be challenged by Bouncer (and can lose ability)

### The Creep
- ✅ Mimic target selection (Night 0)
- ✅ Role inheritance on target death
- ✅ Alliance copying

### Seasoned Drinker
- ✅ Multiple lives (2 lives)

### Ally Cat
- ✅ Nine lives implementation
- ✅ Wakes with Bouncer during ID checks (scripted)
- ✅ Meow prompt/logging supported; enforcement remains a real-table rule

### Drama Queen
- ✅ Mark two players during night
- ✅ Swap on death trigger
- ✅ Card viewing on swap

### Tea Spiller
- ✅ Mark player during night
- ✅ Reveal on death

### Predator
- ✅ Mark player during night
- ✅ Retaliation on vote-out

### The Wallflower ✨ NEW
- ✅ Priority 5 (after Dealer kill)
- ✅ Optional eye-opening mechanic during murder phase
- ✅ Script step allowing optional observation
- ✅ Can witness who Dealers targeted

### The Club Manager ✨ NEW
- ✅ Priority 3 (before Roofi)
- ✅ Night vision of player cards
- ✅ Script step to select player and view role
- ✅ Host shows selected player's character card

### The Silver Fox ✨ NEW
- ✅ Priority 1 (early in night)
- ✅ Nightly alibi: choose a player to be vote-immune the following day
- ✅ Script step writes `alibiDay = dayCount + 1` and votes against them do not count

### The Minor ✨ NEW
- ✅ Passive death protection until ID'd
- ✅ Bouncer ID check integration
- ✅ First attack triggers ID'd status (survives)
- ✅ Subsequent attacks kill normally
- ✅ Special logging for Minor protection

### The Sober ✨ NEW
- ✅ Priority 1 (early, before kills)
- ✅ Nightly "send home" ability
- ✅ Protection queued with priority 1
- ✅ No murders if Dealer sent home (special logic)
- ✅ Ability usage tracking

---

## ℹ️ Notes

- Older “missing mechanics” sections in this file are now obsolete; see ROLE_IMPLEMENTATION_GAP_REGISTER.md and ROLE_TEST_CHECKLIST.md for up-to-date coverage and remaining manual-only mechanics.

---

## 🔧 Required Updates

### Remaining Gaps / Optional Enhancements

1. **Roofi** - Extended paralyze for Dealers (2 rounds) (if desired)
2. **Ally Cat / Lightweight** - Speech enforcement is manual by design (no automated validation)

### Player Model

- Player already contains the role-state fields for the mechanics listed above (Clinger, Lightweight, Minor, Sober, Silver Fox, Second Wind, etc.).

### Game Engine

- Core high-priority mechanics listed in this doc are implemented.

---

## Priority Implementation Order

### High Priority (Core Mechanics)
1. ✅ Wallflower optional observation
2. ✅ Club Manager card viewing
3. ✅ Silver Fox forced reveal
4. ✅ Minor death protection

### Medium Priority (Complex Mechanics)
5. Sober send-home ability
6. Ally Cat seeing Bouncer checks
7. Whore vote deflection
8. Second Wind conversion

### Low Priority (Social/Manual Mechanics)
9. Clinger partner mechanics
10. Lightweight taboo names
11. Bouncer vs Roofi challenge
12. Extended Roofi paralyze for Dealers

---

## Notes

- Some mechanics (like Lightweight's taboo names) are primarily social/manual and may not need full digital implementation
- Clinger mechanics require careful UI/UX design to avoid revealing the role
- Wallflower's "optional" observation is a player choice, not automated
- Many day-phase abilities need voting system updates

## Role Implementation Status (Current)

| Area | Status | Notes |
|---|---:|---|
| Engine compile | ✅ | `game_engine.dart` present |
| UI compile | 🟡 | Depends on assets/fonts present locally |
| Script builder | ✅ | `script_builder.dart` exists |
| Voting telemetry | ✅ | Engine has `recordVote()` + insights |
| Reaction system | ✅ | `reaction_system.dart` present |
| Night resolver | ✅ | `night_resolver.dart` compiles |
