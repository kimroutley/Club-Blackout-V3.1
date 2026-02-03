import re
import os

file_path = r"lib\ui\screens\game_screen.dart"

if not os.path.exists(file_path):
    print(f"File not found: {file_path}")
    exit(1)

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Regex to replace .withValues(alpha: X) with .withOpacity(X)
new_content = re.sub(r'\.withValues\(\s*alpha:\s*([^)]+)\)', r'.withOpacity(\1)', content)

if content != new_content:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Fixed {file_path}")
else:
    print(f"No changes in {file_path}")
