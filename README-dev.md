# Dev workflow for Godot 4 on Windows

1. Point to your Godot executable (one-time)

- Option A: set env var GODOT4 to full path, e.g. `C:\\Tools\\Godot\\Godot_v4.4-stable_win64.exe`
- Option B: create file `scripts\\win\\godot-path.txt` with one line containing the full path.
- Option C: put `godot4` on PATH (winget install `godot-latest`).

1. Import assets

- Run VS Code task: `godot: import`
  - This runs Godot headless to (re)import assets (fixes missing .ctex errors).

1. Play

- Run VS Code task: `godot: play`
- Or run `godot: dev` to import+launch in one go.

## Notes

- Project path is `cybertd` (res:// points there).
- If you rename/move assets, prefer doing it inside Godot editor so references are updated automatically.
