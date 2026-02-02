# Club Blackout 3: M3 Compliance & Game Flow Audit

## 1. M3 Compliance Audit

### Global Styling
- **AppBars**: Many screens use manual transparent AppBars. Recommendation: Use `AppBar` with `scrolledUnderElevation` and `surfaceTintColor` for better M3 depth.
- **Buttons**: Generally good (`FilledButton` used), but some custom `GestureDetector` buttons in `InteractiveScriptCard` and `LobbyScreen` should be replaced with `IconButton` or `FilledButton.tonal`.
- **Cards**: Switch legacy `Container(decoration: ...)` to M3 `Card` with `surfaceContainerLow/High` and `radiusMd`.

### Specific Screen Gaps
- **LobbyScreen**: Uses many manual containers for player list items. Needs migration to `UnifiedPlayerTile` with custom configurations.
- **RolesScreen**: Role tiles are `Material` + `InkWell`. Should use `Card` for better elevation support.
- **Home Screen**: Background handling is manual and slightly clunky.

## 2. Game Flow Polish

### Friction Reduction
- **Host Dashboard**: Currently requires many taps to perform a single action (Tap Player -> Modal -> Tap Action -> Confirm). Recommendation: Add "Quick Action" buttons to the dashboard cards.
- **Lobby Setup**: Adding players is one-by-one. Recommendation: Add "Batch Add" or "Recent Players" chips.
- **Game Screen**: Ability menu is a vertical FAB menu. Recommendation: Change to a `SegmentedButton` or a more modern horizontal dock.

### Interactivity & Feedback
- **Phase Transitions**: Transitions are static. Recommendation: Use `AnimatedSwitcher` for background changes and `Hero` animations for role icons.
- **Visual Cues**: More prominent use of "Glow" effects for active players/steps (using the established `NeonGlassCard`).

## 3. Implementation Roadmap

### Phase 1: M3 Base (The "Polish" Foundation)
- [ ] Standardize `AppBar` across all screens.
- [ ] Migrate `LobbyScreen` player list to `UnifiedPlayerTile`.
- [ ] Update `RoleTileWidget` to use `Card`.

### Phase 2: Flow Streamlining
- [ ] Implement "Quick Actions" on the Host Dashboard.
- [ ] Add "Recent Player" chips to the Lobby.
- [ ] Refactor the Ability FAB Menu to a more interactive Dock.

### Phase 3: Visual Interactivity
- [ ] Add `Hero` animations between Lobby -> Game Screen.
- [ ] Implement smooth background cross-fades during Phase transitions.
