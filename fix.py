#!/usr/bin/env python3
import re

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    pattern = r'<<<<<<< Updated upstream\n(.*?)\n=======\n(.*?)\n>>>>>>> Stashed changes'
    resolved = re.sub(pattern, r'\2', content, flags=re.DOTALL)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(resolved)
    print(f"Fixed: {path}")

files = [
    r'lib\ui\widgets\unified_player_tile.dart',
    r'lib\ui\widgets\role_tile_widget.dart',
    r'lib\ui\widgets\role_reveal_widget.dart',
    r'lib\ui\widgets\neo_drawer.dart',
    r'lib\ui\widgets\day_scene_dialog.dart',
    r'lib\ui\screens\game_screen.dart',
]

for f in files:
    try:
        fix_file(f)
    except Exception as e:
        print(f"Error in {f}: {e}")
