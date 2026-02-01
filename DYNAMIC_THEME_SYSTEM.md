# Dynamic Theme System

## Overview

Club Blackout now features a sophisticated **dynamic theming system** that extracts colors from background images and role assignments to create vibrant, context-aware themes throughout the app.

## How It Works

The dynamic theme system uses three sources for color generation:

1. **Background Images** - Extracts dominant colors from PNG backgrounds using `palette_generator`
2. **Role Colors** - Uses the color hex values defined for each character role
3. **Hybrid Mode** - Intelligently blends background palette colors with role colors

## Key Components

### DynamicThemeService (`lib/services/dynamic_theme_service.dart`)

A singleton service that manages theme generation and updates:

```dart
// Update theme from background only
await themeService.updateFromBackground('Backgrounds/Club Blackout V2 Home Menu.png');

// Update theme from role colors only
themeService.updateFromRoles(listOfRoles);

// Hybrid mode: blend background + roles (recommended)
await themeService.updateFromBackgroundAndRoles(
  'Backgrounds/Club Blackout V2 Game Background.png',
  activeRoles,
);

// Reset to default theme
themeService.reset();
```

### Features

- **Color Extraction**: Uses `PaletteGenerator` to extract vibrant, muted, light, and dark colors from images
- **Saturation Boost**: Automatically boosts color saturation to match Club Blackout's neon aesthetic (70%+ saturation)
- **Color Blending**: Intelligently blends role colors (70%) with background colors (30%) for harmonious themes
- **Caching**: Background palettes are cached for performance
- **Material 3 Integration**: Generated colors are converted to full Material 3 ColorSchemes

### Color Algorithm

1. **Background Extraction**:
   - Extracts vibrant, dark vibrant, light vibrant, and muted colors
   - Boosts saturation to 60-70% for neon effect
   
2. **Role Color Processing**:
   - Sorts role colors by saturation (most vibrant first)
   - Takes top 3 colors for primary, secondary, tertiary
   
3. **Hybrid Blending**:
   - Primary: 70% role color + 30% background vibrant
   - Secondary: 60% role color + 40% background dark
   - Tertiary: From remaining role colors or background

## Usage in Screens

### Home Screen
Automatically updates theme from home background on load:
```dart
await themeService.updateFromBackground('Backgrounds/Club Blackout V2 Home Menu.png');
```

### Game Screen
Updates theme dynamically when roles are assigned or phase changes:
```dart
final activeRoles = gameEngine.guests
    .where((p) => p.role != null)
    .map((p) => p.role!)
    .toList();

await themeService.updateFromBackgroundAndRoles(
  'Backgrounds/Club Blackout V2 Game Background.png',
  activeRoles,
);
```

### Lobby Screen
Updates theme after game starts and roles are assigned:
```dart
if (activeRoles.isNotEmpty) {
  await themeService.updateFromBackgroundAndRoles(
    'Backgrounds/Club Blackout V2 Game Background.png',
    activeRoles,
  );
}
```

## DynamicThemedBackground Widget

A convenience widget for automatic theme updates:

```dart
DynamicThemedBackground(
  backgroundAsset: 'Backgrounds/Club Blackout V2 Game Background.png',
  activeRoles: gameEngine.activeRoles,
  useRoleColors: true, // Enable hybrid mode
  child: YourScreen(),
)
```

## Context Extensions

Helper methods for easy theme updates from any widget:

```dart
// From any BuildContext:
await context.updateThemeFromBackground(assetPath);
context.updateThemeFromRoles(roles);
await context.updateThemeFromBackgroundAndRoles(assetPath, roles);
context.resetTheme();
```

## Theme Integration with Main App

The app uses `Provider` to make the theme service available throughout the widget tree:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DynamicThemeService()),
  ],
  child: const ClubBlackoutApp(),
)
```

The MaterialApp consumes the theme:

```dart
Consumer<DynamicThemeService>(
  builder: (context, themeService, _) {
    final lightScheme = themeService.lightScheme ?? defaultLight;
    final darkScheme = themeService.darkScheme ?? defaultDark;
    
    return MaterialApp(
      theme: ClubBlackoutTheme.createTheme(lightScheme),
      darkTheme: ClubBlackoutTheme.createTheme(darkScheme),
      // ...
    );
  },
)
```

## Performance Considerations

- **Caching**: Background palettes are cached to avoid reprocessing
- **Lazy Loading**: Themes are only generated when needed
- **Async Processing**: Image decoding and palette generation run asynchronously
- **Memory Management**: `clearCache()` method available if needed

## Color Examples

With the Medic role (red #FF2E63) and game background:
- **Primary**: Vibrant red-pink blend
- **Secondary**: Deep crimson-blue blend
- **Tertiary**: From background palette

With multiple roles (Ally Cat #FFEB3B, Bouncer #2196F3, Creep #9C27B0):
- **Primary**: Vibrant yellow (highest saturation)
- **Secondary**: Deep blue
- **Tertiary**: Rich purple

## Future Enhancements

Potential improvements:
- **Adaptive Contrast**: Ensure WCAG compliance for text readability
- **Animation Transitions**: Smooth color transitions when theme changes
- **User Preferences**: Allow users to override dynamic themes
- **Season/Event Themes**: Special color palettes for holidays/events
- **Accessibility Mode**: High contrast option for visually impaired users

## Dependencies

- `palette_generator: ^0.3.3+7` - Image color extraction
- `provider: ^6.1.5+1` - State management for theme updates
- `dynamic_color: ^1.7.0` - Material You dynamic colors (fallback)

## Technical Notes

- Uses Flutter's new color API (`Color.r`, `Color.g`, `Color.b` instead of deprecated `red`, `green`, `blue`)
- Fully compatible with Material Design 3
- Works in both light and dark modes
- Respects system theme preferences while applying dynamic colors
