# UI Implementation Plan

## 1. Material 3 Migration Verification
Ensure all screens are fully utilizing the new `ClubBlackoutTheme` and M3 components.

- [x] **Game Screen**: Verify `UnifiedPlayerTile` usage and M3 buttons.
- [x] **Roles Screen**: Check for legacy `RoleTileWidget` usage and migrate if necessary.
- [x] **Guides Screen**: Ensure M3 typography and colors.
- [x] **Hall of Fame**: Verify list styling and empty states.
- [x] **Rumour Mill**: Check for specific styling consistency.

## 2. Host Dashboard Polish
Review `HostOverviewScreen` for any missing M3 elements or pending features.

- [x] **Privacy Screen**: Ensure it matches the new design system.
- [x] **Alerts & Toasts**: Verify they use the new `ClubAlertDialog` and toast styling.

## 3. Role-Specific UI Finalization
Confirm specialized UI for complex roles is robust.

- [x] **Predator Retaliation**: Verify the retaliation panel styling in Host Dashboard.
- [x] **Tea Spiller Reveal**: Verify the reveal panel styling.
- [x] **Drama Queen Swap**: Verify the swap dialog styling.

## 4. Component Standardization
- [x] Replace any remaining ad-hoc "Neon" containers with `ClubBlackoutTheme.neonFrame`.
- [x] Standardize dialogs to use `BulletinDialogShell` or `ClubAlertDialog`.

## 5. Documentation & Cleanup
Final housekeeping tasks.

- [x] **M3 Flow Audit**: Update the audit document to reflect the completed migration.
- [x] **Code Cleanup**: Remove any unused legacy widgets or styles.
