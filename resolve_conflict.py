import os

file_path = r"c:\Users\kimro\Documents\Codex\Club Blackout 3\Club-Blackout-3-main\lib\ui\widgets\unified_player_tile.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
in_conflict_1 = False
in_conflict_2 = False
skip_lines = False

# We will rewrite the _buildNightPhaseVariant function entirely when we hit it
# But finding the function start and end is tricky if we just iterate.
# Instead, let's identify the conflict blocks and replace them.

# However, the structure I want requires rewriting the surrounding code (variable definitions).
# So I should rewrite the whole function.

# Let's find the start and end of _buildNightPhaseVariant
start_line = -1
end_line = -1

for i, line in enumerate(lines):
    if "Widget _buildNightPhaseVariant(BuildContext context) {" in line:
        start_line = i
    if start_line != -1 and "Widget _buildBannerVariant(BuildContext context) {" in line:
        end_line = i
        break

if start_line != -1 and end_line != -1:
    print(f"Function found from {start_line} to {end_line}")
    
    # Construct the new function body
    new_func = """  /// Build night phase variant with enhanced animations and glow
  Widget _buildNightPhaseVariant(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = config.statsText ?? player.role.name;
    final accent = player.role.color;
    final isEnabled = config.enabledOverride ?? player.isEnabled;
    final isInteractive = config.isInteractive && isEnabled;

    // Collect status chips for Night Phase too
    final effectChips = config.showStatusChips
        ? _collectEffectChips(player: player, engine: gameEngine)
        : const <_EffectChip>[];

    Widget content = InkWell(
      onTap: isInteractive ? config.onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Standardized Icon container
            Hero(
              tag: 'player_icon_${player.id}',
              child: PlayerIcon(
                assetPath: player.role.assetPath,
                glowColor: accent,
                size: 48,
                isAlive: player.isAlive,
                isEnabled: isEnabled,
                glowIntensity: config.isSelected && isEnabled ? 1.5 : 1.0,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: isEnabled
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                      shadows: config.isSelected && isEnabled
                          ? ClubBlackoutTheme.textGlow(accent)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent.withValues(alpha: isEnabled ? 0.85 : 0.3),
                    ),
                  ),
                  // Add Chips for Night Phase
                  if (effectChips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    AutoScrollHStack(
                      autoScroll: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < effectChips.length; i++) ...[
                            _buildChip(context, effectChips[i]),
                            if (i != effectChips.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (config.isSelected && config.onConfirm != null && isEnabled)
              IconButton(
                icon: Icon(Icons.check_circle_rounded, color: accent),
                iconSize: 32,
                onPressed: config.onConfirm,
              ),
          ],
        ),
      ),
    );

    // Use NeonGlassCard for consistent aesthetics
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: NeonGlassCard(
        glowColor: accent,
        opacity: config.isSelected ? 0.85 : (isEnabled ? 0.70 : 0.60),
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: content,
      ),
    );
  }

"""
    # Replace the lines
    # Note: start_line includes the definition. end_line includes the next function definition.
    # We want to keep the next function definition.
    # So we replace up to end_line - 1.
    # Wait, the new_func string ends with a newline.
    
    # Check if there are blank lines before _buildBannerVariant in the file
    # The grep output showed:
    # 795.   }
    # 796. 
    # 797.   /// Build banner variant...
    # 798.   Widget _buildBannerVariant...
    
    # So end_line is 798 (0-indexed? No grep was 1-indexed).
    # Python enumerate is 0-indexed.
    # Grep said 798. Python will say 797.
    
    # We want to replace from start_line (including comments?)
    # The comment for _buildNightPhaseVariant is above start_line.
    # Let's include the comment in new_func and find where the comment starts in lines.
    
    # Actually, simply replacing from start_line to end_line (exclusive of end_line) is safer if we include the comment in new_func or not.
    # My new_func has the comment at the top.
    # So I should find the comment line.
    
    comment_line = start_line - 1
    if "/// Build night phase variant" in lines[comment_line]:
        start_line = comment_line
    
    # Look for previous line just in case
    elif "/// Build night phase variant" in lines[start_line - 2]:
        start_line = start_line - 2
        
    final_lines = lines[:start_line] + [new_func] + lines[end_line:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(final_lines)
    
    print("Successfully updated file.")
else:
    print("Could not find function bounds.")
