import re

path = r'c:\Users\kimro\Documents\Codex\Club Blackout 3\Club-Blackout-3-main.worktrees\copilot-worktree-2026-02-02T09-55-25\lib\ui\screens\lobby_screen.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace .withValues(alpha: X) with .withOpacity(X)
# Handles various spacing
new_content = re.sub(r'\.withValues\(\s*alpha:\s*([\d\.]+)\s*\)', r'.withOpacity(\1)', content)

if content != new_content:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Updated LobbyScreen.dart")
else:
    print("No changes needed in LobbyScreen.dart")
