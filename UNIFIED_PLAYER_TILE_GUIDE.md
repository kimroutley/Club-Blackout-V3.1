# Unified Player Tile System - Usage Guide

## Overview

The `UnifiedPlayerTile` component is a flexible, reusable player/role tile that can be used throughout Club Blackout for:
- **Live update banners** - Real-time status notifications
- **Selection tools** - Vote targeting, night action selection
- **Status displays** - Player lists, dashboards, scoreboards
- **Interactive elements** - Tappable tiles with callbacks

---

## Quick Start

### Basic Usage

```dart
UnifiedPlayerTile(
  player: myPlayer,
  gameEngine: gameEngine,
  config: PlayerTileConfig.standard(
    isSelected: false,
    onTap: () => print('Tapped ${myPlayer.name}'),
  ),
)
```

### Compact Named Constructor

```dart
UnifiedPlayerTile.compact(
  player: myPlayer,
  gameEngine: gameEngine,
  isSelected: isSelected,
  onTap: () => selectPlayer(myPlayer),
)
```

---

## Available Variants

### 1. **Standard** (Default)
Full-featured tile with role icon, name, subtitle, and status chips.

```dart
UnifiedPlayerTile(
  player: player,
  gameEngine: engine,
  config: PlayerTileConfig.standard(
    isSelected: selectedPlayer == player,
    onTap: () => setState(() => selectedPlayer = player),
    showStatusChips: true,
    voteCount: voteMap[player.id], // Optional vote badge
  ),
)
```

**Use cases:** Lobby lists, player rosters, general displays

---

### 2. **Compact**
Smaller version for dense lists.

```dart
UnifiedPlayerTile(
  player: player,
  gameEngine: engine,
  config: PlayerTileConfig.compact(
    isSelected: false,
    onTap: () => viewPlayerDetails(player),
  ),
)
```

**Use cases:** Side panels, dropdown lists, compact views

---

### 3. **Night Phase**
Enhanced visuals with gradients, glows, and animations for night selection.

```dart
UnifiedPlayerTile(
  player: player,
  gameEngine: engine,
  config: PlayerTileConfig.nightPhase(
    isSelected: selectedTargetId == player.id,
    onTap: () => selectTarget(player),
    onConfirm: () => confirmSelection(player),
    statsText: 'Target for protection', // Optional custom text
  ),
)
```

**Features:**
- Animated glow on selection
- Gradient background
- Optional confirm button when selected
- Enhanced shadows

**Use cases:** Night action target selection, role-specific choices

---

### 4. **Selection**
Optimized for voting and target selection with banner-style status chips.

```dart
UnifiedPlayerTile(
  player: player,
  gameEngine: engine,
  config: PlayerTileConfig.selection(
    isSelected: selectedVotes.contains(player.id),
    onTap: () => toggleVote(player),
    showStatusChips: true,
  ),
)
```

**Features:**
- Status chips displayed as banner overlay
- Clear selection state
- Tap to toggle

**Use cases:** Voting screens, multi-selection lists, target picking

---

### 5. **Dashboard**
Clean display for host dashboard and overview screens.

```dart
UnifiedPlayerTile(
  player: player,
  gameEngine: engine,
  config: PlayerTileConfig.dashboard(
    onTap: () => showPlayerDetails(player),
    showStatusChips: true,
  ),
)
```

**Use cases:** Host dashboard, player overview, status monitoring

---

### 6. **Banner**
Lightweight banner for notifications and live updates.

```dart
UnifiedPlayerTile(
  player: player,
  gameEngine: engine,
  config: PlayerTileConfig.banner(
    showStatusChips: true,
    onTap: () => dismissNotification(),
  ),
)
```

**Features:**
- Horizontal gradient background
- Minimal padding
- Status chips in wrap layout
- No card wrapper (flat design)

**Use cases:** Notifications, toast messages, live update feeds

---

### 7. **Minimal**
Just icon and name - ultra-compact.

```dart
UnifiedPlayerTile(
  player: player,
  config: PlayerTileConfig.minimal(
    onTap: () => quickAction(player),
  ),
)
```

**Features:**
- No subtitle
- No status chips
- No card wrapper
- Smallest footprint

**Use cases:** Quick lists, inline mentions, compact references

---

## Configuration Options

### PlayerTileConfig Properties

#### Visual
```dart
PlayerTileConfig(
  variant: PlayerTileVariant.standard,
  isSelected: false,
  showStatusChips: true,
  statusChipsAsBanner: false, // Overlay vs inline
  showRoleIcon: true,
  showPlayerName: true,
  showSubtitle: true,
  wrapInCard: true,
  tileColor: Colors.blue, // Override role color
)
```

#### Content
```dart
PlayerTileConfig(
  subtitleOverride: 'Custom subtitle',
  statsText: 'Day 3 - Protected',
  voteCount: 5, // Show vote badge
  leading: CustomWidget(), // Replace icon
  trailing: CustomWidget(), // Replace badge
)
```

#### Interaction
```dart
PlayerTileConfig(
  isInteractive: true,
  onTap: () => handleTap(),
  onLongPress: () => handleLongPress(),
  onDoubleTap: () => handleDoubleTap(),
  onConfirm: () => handleConfirm(), // Night phase only
)
```

#### Layout
```dart
PlayerTileConfig(
  contentPadding: EdgeInsets.all(12),
  enabledOverride: true, // Override player.isEnabled
)
```

---

## Status Chips

Status chips automatically display based on:

### Player State
- ✅ **Dead** - Player is not alive
- ✅ **Disabled** - Player is not enabled
- ✅ **Lives** - Multiple lives (Seasoned Drinker, Ally Cat)
- ✅ **Joins Next Night** - New player joining

### Active Effects
- ✅ **Sent Home** - Sober ability
- ✅ **Silenced** - Roofi ability
- ✅ **No Kill** - Dealer blocked by Roofi
- ✅ **Alibi: Vote Immunity** - Silver Fox protection
- ✅ **Checked ID** - Bouncer has ID'd this player
- ✅ **Taboo** - Name is taboo for Lightweight

### Role-Specific
- ✅ **Minor**: Immune / Vulnerable
- ✅ **Clinger**: Obsessed / Unleashed / Attack Used
- ✅ **Creep**: Target of mimicry
- ✅ **Whore**: Deflection target
- ✅ **Drama Queen**: Swap target A/B
- ✅ **Predator**: Marked for retaliation

### Night Actions (if engine provided)
- ✅ **Marked** - Dealer kill target
- ✅ **Protected** - Medic protection
- ✅ **Roofied** - Roofi target
- ✅ **ID Check** - Bouncer investigation
- ✅ **Rumour** - Messy Bitch rumor spread
- ✅ And many more...

---

## Common Patterns

### 1. Voting List

```dart
ListView.builder(
  itemCount: eligiblePlayers.length,
  itemBuilder: (context, index) {
    final player = eligiblePlayers[index];
    return UnifiedPlayerTile(
      player: player,
      gameEngine: engine,
      config: PlayerTileConfig.selection(
        isSelected: selectedVote == player.id,
        onTap: () => setState(() => selectedVote = player.id),
      ),
    );
  },
)
```

### 2. Night Phase Target Selection

```dart
Column(
  children: engine.alivePlayers.map((player) {
    final isSelected = nightTarget == player.id;
    return UnifiedPlayerTile(
      player: player,
      gameEngine: engine,
      config: PlayerTileConfig.nightPhase(
        isSelected: isSelected,
        onTap: () => setState(() => nightTarget = player.id),
        onConfirm: isSelected ? () => confirmTarget() : null,
        statsText: player.role.name,
      ),
    );
  }).toList(),
)
```

### 3. Live Update Banner

```dart
// Show notification when player gets marked
if (markedPlayer != null)
  UnifiedPlayerTile(
    player: markedPlayer,
    gameEngine: engine,
    config: PlayerTileConfig.banner(
      showStatusChips: true,
      onTap: () => dismissBanner(),
    ),
  )
```

### 4. Dashboard Player List

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 2.5,
  ),
  itemCount: engine.players.length,
  itemBuilder: (context, index) {
    return UnifiedPlayerTile(
      player: engine.players[index],
      gameEngine: engine,
      config: PlayerTileConfig.dashboard(
        onTap: () => showPlayerDialog(engine.players[index]),
      ),
    );
  },
)
```

### 5. Compact Sidebar

```dart
Drawer(
  child: ListView(
    children: engine.alivePlayers.map((player) {
      return UnifiedPlayerTile.compact(
        player: player,
        gameEngine: engine,
        onTap: () => viewPlayer(player),
      );
    }).toList(),
  ),
)
```

---

## Migration from Old PlayerTile

### Before
```dart
PlayerTile(
  player: player,
  gameEngine: engine,
  isCompact: true,
  isSelected: selected,
  onTap: onTap,
  showEffectChips: true,
)
```

### After
```dart
UnifiedPlayerTile(
  player: player,
  gameEngine: engine,
  config: PlayerTileConfig.compact(
    isSelected: selected,
    onTap: onTap,
    showStatusChips: true,
  ),
)
```

---

## Advanced Customization

### Custom Leading Widget
```dart
UnifiedPlayerTile(
  player: player,
  config: PlayerTileConfig(
    leading: CircleAvatar(
      backgroundImage: NetworkImage(player.avatarUrl),
    ),
  ),
)
```

### Custom Trailing Widget
```dart
UnifiedPlayerTile(
  player: player,
  config: PlayerTileConfig(
    trailing: IconButton(
      icon: Icon(Icons.more_vert),
      onPressed: () => showMenu(player),
    ),
  ),
)
```

### No Card Wrapper (Flat Design)
```dart
UnifiedPlayerTile(
  player: player,
  config: PlayerTileConfig(
    wrapInCard: false,
    contentPadding: EdgeInsets.symmetric(vertical: 8),
  ),
)
```

### Hide Specific Elements
```dart
UnifiedPlayerTile(
  player: player,
  config: PlayerTileConfig(
    showRoleIcon: false, // Hide icon
    showSubtitle: false, // Hide role/alliance
    showStatusChips: false, // Hide chips
  ),
)
```

---

## Performance Tips

1. **Reuse configs** - Create config instances once and reuse
2. **Provide engine** - Status chips are richer with GameEngine context
3. **Limit status chips** - Set `showStatusChips: false` in large lists if performance is critical
4. **Use variants appropriately** - `minimal` and `compact` are more performant than `nightPhase`

---

## Best Practices

✅ **DO:**
- Use appropriate variant for context (compact for lists, nightPhase for selections)
- Provide `gameEngine` when available for full status chip richness
- Use named constructors for common patterns (`UnifiedPlayerTile.compact()`)
- Set `isInteractive: false` for display-only tiles

❌ **DON'T:**
- Mix variants inconsistently in the same list
- Forget to handle `null` gameEngine in some contexts
- Override colors unnecessarily - role colors are thematic
- Use nightPhase variant in non-night contexts (confusing UX)

---

## Examples in Codebase

### Replacing PlayerTile
```dart
// Find in: game_screen.dart, lobby_screen.dart, etc.
// Old: PlayerTile(...)
// New: UnifiedPlayerTile(...)
```

### Replacing NightPhasePlayerTile
```dart
// Find in: game_screen.dart night phase sections
// Old: NightPhasePlayerTile(...)
// New: UnifiedPlayerTile(..., config: PlayerTileConfig.nightPhase(...))
```

---

## Future Extensions

The system is designed to be extended with:
- Custom chip types
- Animation options
- Layout variants
- Theme overrides
- Accessibility features

To add new features, extend `PlayerTileConfig` with new properties and update the build methods in `UnifiedPlayerTile`.

---

**Created:** January 31, 2026  
**Component:** `lib/ui/widgets/unified_player_tile.dart`  
**Configuration:** `PlayerTileConfig` + `PlayerTileVariant` enum
