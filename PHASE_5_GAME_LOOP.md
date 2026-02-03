# GAME LOOP REFINEMENTS (Phase 5)

## Objective
Polish the core gameplay loop (Day -> Voting -> Night -> Transition) to feel seamless, immersive, and responsive, using the new Cyber-Club UI system.

## Key Areas

### 1. Transitions
- [x] **Day/Night Switching**: Ensure smooth animated transitions between phases.
- [x] **Alerts**: Using `ClubAlertDialog` instead of system dialogs for all critical game blocking events.

### 2. Interaction
- [x] **Voting UI**: Ensure the `ActiveEventCard` action slot handles voting states clearly (Highlights vote leader).
- [x] **Night Actions**: Verify `UnifiedPlayerTile.nightPhase` provides clear feedback (Verified `UnifiedPlayerTile.nightPhase` variant).

### 3. Dynamic Theme
- [x] **Background**: Verify `NeonBackground` reacts to phase changes (Red/Blue shifts). (Updated `NeonBackground` to use `accentColor`).
- [x] **Typography**: Ensure `Roboto` (new default) is legible on all cards, with `Orbitron` headers glowing correctly. (Switched to `GoogleFonts.orbitron`).

## Implementation Tasks
1. **Audit `GameScreen` Logic**:
   - [x] Check `_processPhaseChange` (Logic verified in `onPhaseChanged`).
   - [x] Check `_onPlayerSelected` during different phases. (Logic verified).
2. **Standardize Dialogs**:
   - [x] Replace any remaining `showDialog(AlertDialog)` with `ClubAlertDialog`.
3. **Refine `ActiveEventCard`**:
   - [x] Ensure the "Action Slot" expands/contracts smoothly. (Verified `AnimatedSize`).
   - [x] Update visual style to match `design_system.md` (glass cards). (Updated `NeonGlassCard` and `ActiveEventCard`).
   - [x] Verify state handling (Voting vs. Result vs. Idle). (Verified in `GameScreen._advanceScript`).

