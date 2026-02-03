# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-02-02
### Changed
- **UI Overhaul**: Complete migration to Material 3 design system using `ClubBlackoutTheme`.
- **Game Screen**: Refactored Ability FAB into a new Horizontal Dock for better accessibility.
- **Lobby**: Enhanced "Quick Add" with smart history merging (Hall of Fame + Recent).
- **Host Dashboard**: Replaced text-heavy tools with "Quick Action" buttons for phase/player management.
- **Visuals**: Added Hero animations for smooth transitions and adaptive background cross-fades.
- **Cleanup**: Standardized dialogs (`ClubAlertDialog`) and removed legacy widget usages.

## [1.0.0+1] - 2024-05-22
### Added
- Initial production release.
- Complete game logic for Mafia/Werewolf style gameplay.
- 50+ Roles with unique abilities.
- Dynamic game engine (Phase management, Voting, Night Actions).
- "Games Night" mode.
- About Screen with credits.

### Fixed
- Resolved self-targeting logic in `SelfTargetingRules`.
- Fixed role interaction bugs (Predator, Mimic, etc.).
- Stabilized UI for various screen sizes.
