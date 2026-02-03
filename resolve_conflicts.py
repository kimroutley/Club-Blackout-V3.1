import re
import os
import sys

def resolve_git_conflicts(filepath):
    """Resolve Git merge conflicts by keeping 'Stashed changes' version"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Pattern matches: <<<<<<< Updated upstream ... ======= ... >>>>>>> Stashed changes
        pattern = r'<<<<<<< Updated upstream\n(.*?)\n=======\n(.*?)\n>>>>>>> Stashed changes'
        
        # Count conflicts before
        conflicts_before = len(re.findall(pattern, content, re.DOTALL))
        
        if conflicts_before == 0:
            return f"✓ {filepath}: No conflicts"
        
        # Replace with stashed changes (group 2)
        resolved = re.sub(pattern, r'\2', content, flags=re.DOTALL)
        
        # Verify all conflicts resolved
        if '<<<<<<< Updated upstream' in resolved or '>>>>>>> Stashed changes' in resolved:
            return f"✗ {filepath}: Failed to resolve all conflicts"
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(resolved)
        
        return f"✓ {filepath}: Resolved {conflicts_before} conflict(s)"
    
    except Exception as e:
        return f"✗ {filepath}: Error - {str(e)}"

# Files to resolve
files = [
    r'lib\ui\widgets\interactive_script_card.dart',
    r'lib\ui\widgets\day_scene_dialog.dart',
    r'lib\ui\widgets\neo_drawer.dart',
    r'lib\ui\widgets\role_reveal_widget.dart',
    r'lib\ui\widgets\role_tile_widget.dart',
    r'lib\ui\widgets\unified_player_tile.dart',
    r'lib\ui\screens\game_screen.dart',
]

print("Resolving merge conflicts...")
print("=" * 60)

for filepath in files:
    result = resolve_git_conflicts(filepath)
    print(result)

print("=" * 60)
print("Done!")
