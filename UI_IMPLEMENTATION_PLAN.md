# UI Implementation Plan

## 1. Material 3 Migration Verification
Ensure all screens are fully utilizing the new `ClubBlackoutTheme` and M3 components.

- [ ] **Game Screen**: Verify `UnifiedPlayerTile` usage and M3 buttons.
- [ ] **Roles Screen**: Check for legacy `RoleTileWidget` usage and migrate if necessary.
- [ ] **Guides Screen**: Ensure M3 typography and colors.
- [ ] **Hall of Fame**: Verify list styling and empty states.
- [ ] **Rumour Mill**: Check for specific styling consistency.

## 2. Host Dashboard Polish
Review `HostOverviewScreen` for any missing M3 elements or pending features.

- [ ] **Privacy Screen**: Ensure it matches the new design system.
- [ ] **Alerts & Toasts**: Verify they use the new `ClubAlertDialog` and toast styling.

## 3. Role-Specific UI Finalization
Confirm specialized UI for complex roles is robust.

- [ ] **Predator Retaliation**: Verify the retaliation panel styling in Host Dashboard.
- [ ] **Tea Spiller Reveal**: Verify the reveal panel styling.
- [ ] **Drama Queen Swap**: Verify the swap dialog styling.

## 4. Component Standardization
- [ ] Replace any remaining ad-hoc "Neon" containers with `ClubBlackoutTheme.neonFrame`.
- [ ] Standardize dialogs to use `BulletinDialogShell` or `ClubAlertDialog`.
