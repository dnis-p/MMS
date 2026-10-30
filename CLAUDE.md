# MMS (working title: Motorhead Madness Survival)

Mobile-first (later PC) roguelike prototype in Godot 4.7, GDScript only, placeholder art/sound.
You drive freely around walled biome maps; weapons auto-fire at hordes; the
player steers and picks upgrades. Boss fights happen in a ring arena. See README.md for gameplay,
content tables and project layout; this file is the design intent and working agreements.
**The full vision, decisions and idea backlog are in docs/DESIGN.md. Read it, and add any new idea or
decision the owner gives you there (mark owner's words vs your suggestions).**

## Design goals (from the owner, keep these in mind for every change)
- Satisfying, simple, scalable. Vampire Survivors feel: play "without thinking", no complex builds,
  juicy feedback (hit flash, shake, damage numbers, combo, rising-pitch pickups).
- One input during a run: driving with smooth, tight steering (keys, or drag for a virtual stick). No ability buttons.
- Fast paced and vehicle-first: the Redline meter rewards keeping speed; nitro fires by itself.
- Permanent upgrades (Garage) must never need a long grind (owner: no 80-hour goals).
- Maps: walled rectangles, roads optional. Nothing inside may cover the player or enemies; buildings only as walls.
- The boss arrives at a random moment in `Defs.BOSS_WINDOW`.
- Boss arena: camera locked to the vehicle, vehicle circles the boss automatically on 3 rings;
  swipe left/right to dash (invulnerable, also sets circling direction), up/down to switch ring. Attacks are designed around the ring.
- Upgrades: pick 1 of 3; max-level weapon + matching passive evolves (via salvage crate).
- Salvage crate is the "Redline" tachometer (1/3/5 rewards) - deliberately not a slot machine.
- Themes/biomes: Mad Max wasteland first, then cyberpunk, frost, toxic; more classes later
  (tank, fast raider, hauler exist). Difficulty rises each stage; leaderboards/rankings planned
  (currently local only; ideas: seeded daily runs, per-class boards, ghost runs).
- Must stay multiplatform: PC is now the priority (owner, 2026-10-30), then Android and web. Keep input as actions, UI anchored,
  platform services behind one interface.

## Technical rules
- Enemies, projectiles and pickups are packed arrays drawn with MultiMesh: no node per enemy.
  Keep per-frame GDScript cheap; phones are the target. HUD shows FPS/enemy count for device testing.
- All balance numbers live in scripts/data/defs.gd. Prefer data over code for new content.
- Renderer is GL Compatibility; Web uses the single-threaded template (no special headers needed).
- Match existing code style (tabs, typed GDScript, short doc comments only where non-obvious).

## Verify changes
Run from the repo root after the project has been imported once (`godot --headless --path . --import`):
- Smoke test (god mode, short stages, all weapons): `godot --headless --path . -- --autotest --quit-after-sec=60`
- Balance check (normal rules): `godot --headless --path . -- --autotest --fair --class=interceptor --quit-after-sec=120`
  Output ends with `stage= level= kills= score= phase=`; any `SCRIPT ERROR` is a failure. Add `--seed=<n>` to fix the rolls.
- Boss arena checks: `godot --headless --path . res://tests/boss_check.tscn` must end with `BOSS CHECK PASSED`.
- Open-world checks: `godot --headless --path . res://tests/map_check.tscn` must end with `MAP CHECK PASSED`.
- Combat, menus, Redline, Garage: `godot --headless --path . res://tests/game_check.tscn` must end with `GAME CHECK PASSED`.
- Raccoon prototype rules: `godot --headless --path . res://tests/eat_check.tscn` must end with `EAT CHECK PASSED`.
  Run the checks one at a time: `game_check` has tight timings and can fail when the machine is busy.
- Pictures of the raccoon forms (needs a display): `godot --path . res://tests/raccoon_forms.tscn -- --shots=<dir>`
- Bots (--autotest) play through scripts/game/bot.gd, ignore the Garage and do not write to the leaderboard or profile. Compare classes on several
  `--seed` values; a single run varies a lot.
- Screenshots of every screen (needs a display or xvfb): `godot --path . res://tests/ui_shots.tscn -- --shots=<dir>`
- Builds: `tools/android/build_apk.sh` (signed APK), `tools/web/build_web.sh` (browser build).
Parse errors that mention `Sfx`/`Save` only occur when scripts are checked standalone (autoloads missing).

## Release flow
- CI (.github/workflows/android-apk.yml) smoke-tests, builds APK + web on every push, and deploys
  the web build to GitHub Pages from the default branch (needs repo public + Pages source "GitHub Actions").
- The APK is signed with the committed debug key (tools/android/debug-key, test builds only).
  Android export uses tools/android/sign_apk_v2.py so no Android SDK is required.

## Known gaps / next ideas
- Speed, steering, Redline, Garage and balance are bot-tested only: need a human playtest for pacing and feel.
- Never tested on a real phone yet: touch feel and FPS.
- More classes, enemy types and biomes; real art/audio; online leaderboard; PC controls polish.

## How we work (agreed with the owner)
docs/DESIGN.md ends with two tracking sections: **9 = owner's to-do list**, **8 = done list** (since v1.0).
1. When an item from section 9 is completed, **move it to section 8** (remove it from 9).
2. In section 8 write an accurate description of what was actually implemented and how it behaves.
   If it differs from the proposal (different approach, changed number, dropped/added part, limitation),
   say so explicitly and say why. Keep the owner's original wording if it helps, then add what really happened.
3. Describe real behavior, not intentions. Check the code; don't claim something works if it wasn't verified.
4. If an item can't be done as proposed, don't silently change it: tell the owner, explain options, wait.
5. New ideas/decisions the owner gives in chat go into docs/DESIGN.md (section 9 for improvements, plus the
   relevant section for decisions), marked as the owner's. Claude's own suggestions are marked "(suggested)".
   Anything marked "Decided" stays unless the owner says otherwise.
6. Update README.md and CLAUDE.md when something they describe changes (controls, content, commands, gaps).
7. Keep entries concise, dated, in the style of the rest of the file.
8. Git: small, clearly named commits. Run `git pull` before starting work (the owner may edit on GitHub).
   Don't push unless asked (owner pushes about daily). Ask before force-pushing/rewriting history.
   Don't commit export_presets.cfg changes (e.g. "Signed" on) unless asked. Ask before anything destructive,
   anything that costs money, or anything that changes a "Decided" item.

## Local setup (owner's Windows machine)
- Godot 4.7.2 lives in the folder `C:\Users\Denis\Desktop\Repos\GAMES\Godot_v4.7.2-stable_win64.exe\`
  (the folder name ends in .exe). Binaries inside: `Godot_v4.7.2-stable_win64.exe` (GUI) and
  `Godot_v4.7.2-stable_win64_console.exe` (use this one for headless runs so output reaches the terminal).
  It is not on PATH. In Git Bash:
  `G="/c/Users/Denis/Desktop/Repos/GAMES/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"`
  then `"$G" --headless --path . --import` and `"$G" --headless --path . -- --autotest --quit-after-sec=60`.
- Android Studio is installed; the Android SDK and Java are set in the Godot editor, so APKs can be exported
  from the editor (Project > Export). `tools/android/build_apk.sh` and `tools/web/build_web.sh` call `godot`
  from PATH, so they need a `godot` alias/shim to the console exe in Git Bash (bash itself is available).
- Saves are in `%APPDATA%/MMS` (scores.cfg, profile.cfg). Real progress: don't delete it without asking.
- `icon.svg.import` shows as modified after imports (line endings); ignore it, don't commit it.
