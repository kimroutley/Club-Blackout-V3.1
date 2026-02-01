# Club Blackout

Club Blackout is a host companion app for the Club Blackout social deduction game, built with Flutter and Material 3. It assists the game host in managing roles, game phases (night/day), and tracking game state and player abilities.

## Features

*   **Role Management**: Automatically handles role assignments and abilities loaded from `assets/data/roles.json`.
*   **Game Loop**: seamless management of game phases:
    *   **Lobby**: Add players and assign roles.
    *   **Setup (Night 0)**: Initial setup for roles like Clinger, Creep, and Medic.
    *   **Night Phase**: Process prioritized night actions (kills, protections, status effects).
    *   **Day Phase**: Manage discussion, voting, and eliminations.
*   **Dynamic Theme**: Implements a neon aesthetic that adapts based on role types and game state.
*   **Ability System**: Complex resolution logic for role interactions (e.g., protections blocking kills, retaliation effects).

## Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (version >=3.3.0 <4.0.0)
*   Android Studio or VS Code with Flutter extensions.

### Installation

1.  Clone the repository.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```

### Running the App

Run the app on a connected device or emulator:
```bash
flutter run
```

## Development

### Project Structure

*   `lib/models`: Data models for `Role`, `Player`, and game state.
*   `lib/logic`: Core game logic (`GameEngine`), state management, and ability resolution.
*   `lib/data`: Data repositories and JSON handling.
*   `lib/ui`: Screens, widgets, and styles.
*   `assets`: Game assets including images, fonts, and `roles.json`.

### Documentation

For detailed information on specific systems, refer to the following documentation:

*   [**Gameplay Flow**](GAMEPLAY_FLOW.md): Detailed breakdown of the game loop, phases, and win conditions.
*   [**Ability System**](ABILITY_SYSTEM.md): Technical details on how abilities and interactions are resolved.
*   [**Design System**](DESIGN_SYSTEM.md): Guidelines on the app's visual style and theming.
*   [**Dynamic Theme System**](DYNAMIC_THEME_SYSTEM.md): Deep dive into the color generation logic.

### Testing

Run the test suite to verify changes:

```bash
flutter test
```

For a more detailed output:
```bash
flutter test -r expanded
```

### Linting

Ensure code quality by running the analyzer:
```bash
flutter analyze
```

## Building

### Android Build (Gradle)

This project uses the Gradle wrapper under `android/`.

**Verify Gradle Version:**
Check the wrapper version:
```bash
cd android
./gradlew.bat --version
```

**Build APKs:**
From the project root:
```bash
flutter build apk --debug
flutter build apk --release
```
Outputs can be found in `build/app/outputs/flutter-apk/`.

### Device Debugging (ADB)

To analyze logs or debug on a physical device:
*   Ensure USB debugging is enabled.
*   Use `flutter run` for live debugging.
*   For advanced log analysis, check `analyze.ps1` if you are on Windows.

## Troubleshooting

### Gradle/VS Code Issues

If VS Code reports incorrect Gradle versions or other build errors:

1.  Run **Developer: Reload Window**.
2.  Run **Java: Clean Java Language Server Workspace**.
3.  Run **Gradle: Refresh Gradle Project**.
4.  If issues persist:
    ```bash
    cd android
    ./gradlew.bat --stop
    rm -rf .gradle
    ./gradlew.bat :app:tasks
    ```

## Customization

*   **Roles**: Modify `assets/data/roles.json` to tweak role attributes.
*   **Game Logic**: Core logic resides in `lib/logic/game_engine.dart`.

