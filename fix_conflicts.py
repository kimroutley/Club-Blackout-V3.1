import re
import os

files = [
    r"lib\ui\widgets\death_announcement_widget.dart",
    r"lib\ui\widgets\day_scene_dialog.dart",
    r"lib\ui\widgets\interactive_script_card.dart",
    r"lib\ui\widgets\role_tile_widget.dart",
    r"lib\ui\widgets\role_reveal_widget.dart",
    r"lib\ui\widgets\setup_phase_helper.dart"
]

def fix_file(path):
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return

    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to replace .withValues(alpha: X) with .withOpacity(X)
    # Handles cases with optional spaces
    new_content = re.sub(r'\.withValues\(\s*alpha:\s*([^)]+)\)', r'.withOpacity(\1)', content)

    if content != new_content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {path}")
    else:
        print(f"No changes in {path}")

for f in files:
    fix_file(f)
