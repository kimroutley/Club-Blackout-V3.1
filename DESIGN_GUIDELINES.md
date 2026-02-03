# Club Blackout 3 - Design Guidelines

> **Theme Name:** Cyber-Club / Neo-Arcade
> **Core Concept:** A high-contrast, neon-soaked nightclub UI that feels like an arcade cabinet from the future.
> **Typography:** **Roboto Only** (Single font family for cleaner look).

This document serves as the extended reference for the style rules defined in `DESIGN_SYSTEM.md`.

---

## 1. Core Principles

1.  **Deep Backgrounds:** UI surfaces are almost never pure black. Use the "Void Purple" (`#151026`) to give depth.
2.  **Neon Accents:** Interactable elements must glow. If it clicks, it glows.
3.  **Glass Material:** Containers use semi-transparent backgrounds with thin, glowing borders to simulate glass or holographic projections.
4.  **Legibility First:** High contrast text against dark backgrounds.

---

## 2. Color Palette

The official source of truth is `lib/ui/styles.dart`.

### Primary Colors
| Token | Hex | Usage |
| :--- | :--- | :--- |
| **`kBackground`** | `#151026` | Main scaffold background (Deep Void Purple). |
| **`kNeonCyan`** | `#00E5FF` | Primary action color, selection states, "Good" status. |
| **`kNeonPink`** | `#FF00FF` | Secondary accent, "Attention" states, special roles. |

### Semantic Neons
| Token | Hex | Usage |
| :--- | :--- | :--- |
| `neonRed` | `#FF2E63` | Danger, Mafia roles, Elimination. |
| `neonGreen` | `#00FF9A` | Success, Confirmed, Safe. |
| `neonPurple` | `#B400FF` | Magic, Mystery, Neutral roles. |
| `neonGold` | `#FFD700` | MVP, Winners, High value items. |

---

## 3. Typography

**All text uses Roboto.** Hierarchy is established via font weight and color.

### Headers: **Roboto (Black / w900)**
Used for screen titles, button labels, and significant role names.
*   **Token:** `ClubBlackoutTheme.headingStyle`, `ClubBlackoutTheme.neonGlowTitle`
*   **Weight:** Black (900).
*   **Effect:** Often paired with a shadow/glow to mimic a neon tube.

### Body: **Roboto (Regular / Medium)**
Used for game rules, lore descriptions, and long-form text.
*   **Token:** `ClubBlackoutTheme.mainFont`
*   **Weight:** Regular (400) or Medium (500). Avoid thin weights on dark backgrounds.

---

## 4. UI Component Library

When building new screens, prefer these existing widgets over custom containers.

### A. Containers
*   **`NeonGlassCard`**: The default container for grouped content.
    *   *Properties:* Translucent dark background, thin neon border, rounded corners.
*   **`ActiveEventCard`**: Specialized container for the main game loop.
    *   *Usage:* Displaying current game events, voting prompts, or role abilities.

### B. Buttons & Inputs
*   **`GlowButton`**: Primary call-to-action.
    *   *Behavior:* Pulses gently; brightens on tap.
*   **`NeoTextField`**: Input fields with an "underline" glow style.

### C. Lists
*   **`UnifiedPlayerTile`**: The standard row for displaying a player.
    *   *States:* Alive (Bright), Dead (Dimmed/Red), Selected (Cyan Border).

---

## 5. Spacing & Layout System

Avoid magic numbers. Use the strictly defined spacing tokens in `ClubBlackoutTheme`.

### Padding
*   `pagePadding`: Standard screen edge insets (usually 16.0 or 24.0).
*   `cardPadding`: Inner padding for Glass Cards.
*   `inset16` / `inset24`: Standard separators.

### Radius
*   `borderRadiusSmAll`: Small elements like buttons or tags.
*   `borderRadiusMdAll`: Standard cards and dialogs.
*   **Rule:** Standardize on consistent corner radii to avoid a "jagged" UI feel.

---

## 6. Implementation Checklist

Before submitting a UI PR:

- [ ] **Background Check:** Is the `Scaffold` background `kBackground`?
- [ ] **Text Contrast:** Is all body text readable against the dark background?
- [ ] **Font Check:** Are headers and body text both Roboto?
- [ ] **Token Usage:** Did you use `ClubBlackoutTheme.gap16` instead of `SizedBox(height: 15)`?
- [ ] **Safe Area:** Does the UI respect top/bottom notches (using `SafeArea`)?
