# Cyber-Club UI Implementation (Production Ready)

This document outlines the roadmap to implement the new "Cyber-Club" UI theme and fix existing stability issues.

## Phase 0: Stabilization 🛑
1.  **Resolve Merge Conflicts**:
    *   Repair the 6 detected files to get the codebase compiling cleanly. **This must be done first.**
    *   Files:
        *   `lib/ui/widgets/day_scene_dialog.dart`
        *   `lib/ui/widgets/interactive_script_card.dart`
        *   `lib/ui/widgets/role_reveal_widget.dart`
        *   `lib/ui/widgets/role_tile_widget.dart`
        *   `lib/ui/widgets/setup_phase_helper.dart`
        *   `lib/ui/widgets/death_announcement_widget.dart`

## Phase 1: Foundation 🎨
2.  **Theme System**:
    *   Update [lib/ui/styles.dart](lib/ui/styles.dart): Add `kBackground` (0xFF151026), `kNeonCyan` (0xFF00E5FF), `kNeonPink`, `kCardBg`.
    *   Update [lib/main.dart](lib/main.dart): Set `scaffoldBackgroundColor: kBackground`.
    *   Typography: Add `GoogleFonts.orbitron`.

## Phase 2: Atomic Widgets 🧩
3.  **`ActiveEventCard` (Smart Container)**
    *   Create [lib/ui/widgets/active_event_card.dart](lib/ui/widgets/active_event_card.dart).
    *   **Structure**: Header (Role Icon) -> Body (Read Aloud / Host Notes) -> **Action Slot**.
    *   **Action Slot**: This specialized container will accept the interactive widgets (Selecting Players, Voting, Binary Choices) that currently sit *outside* the card in the game screen.
4.  **`PlayerListItem` (Selection UI)**
    *   Create [lib/ui/widgets/player_list_item.dart](lib/ui/widgets/player_list_item.dart).
    *   Style: Capsule background + Floating Avatar.
    *   Behavior: Handles `isSelected` state for player targeting.
5.  **`BottomGameControls` (Navigation)**
    *   Create [lib/ui/widgets/bottom_game_controls.dart](lib/ui/widgets/bottom_game_controls.dart).
    *   Layout: Back (Circle) - Flash (Menu) - Skip (Capsule) - Flash (Next).

## Phase 3: Game Loop Integration 🎮
6.  **Refactor `GameScreen`**:
    *   **Consolidate**: Move the interactive widgets (`_buildPlayerSelectionList`, `_buildBinaryChoice`) *inside* the `ActiveEventCard`'s Action Slot.
    *   **Script View**: Replace the `ListView` with a focused view of `ActiveEventCard`.
    *   **Navigation**: Implement `BottomGameControls`.
    *   **Drawer**: Replace using `NeoDrawer`.

## Phase 4: Neo-Drawer & Setup 🚪
7.  **`NeoDrawer`**: Port `GameDrawer` logic (Save/Load/Dashboard) into the new dark-themed UI.
8.  **Setup Reveal**: Update the role reveal experience to use a full-screen `ActiveEventCard` variant instead of the small dialog.

## Phase 5: Additional Polish ✨
9.  **Lobby**: Ensure `UnifiedPlayerTile` text styles align with the new theme.
10. **Guides**: Replace background with `kBackground` color.
