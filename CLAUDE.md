# MMS (working title: Motorhead Madness Survival)

Mobile-first (later PC) roguelike prototype in Godot 4.7, GDScript only, placeholder art/sound.
You drive a vehicle automatically along a path through biomes; weapons auto-fire at hordes; the
player steers and picks upgrades. Boss fights happen in a ring arena. See README.md for gameplay,
content tables and project layout; this file is the design intent and working agreements.
**The full vision, decisions and idea backlog are in docs/DESIGN.md. Read it, and add any new idea or
decision the owner gives you there (mark owner's words vs your suggestions).**

## Design goals (from the owner, keep these in mind for every change)
- Satisfying, simple, scalable. Vampire Survivors feel: play "without thinking", no complex builds,
  juicy feedback (hit flash, shake, damage numbers, combo, rising-pitch pickups).
- One input during a run: drag to steer on the road. No ability buttons.
- Boss arena: camera locked to the vehicle, vehicle circles the boss automatically on 3 rings;
  swipe left/right to dash (invulnerable), up/down to switch ring. Attacks are designed around the ring.
- Upgrades: pick 1 of 3; max-level weapon + matching passive evolves (via salvage crate).
- Salvage crate is the "Redline" tachometer (1/3/5 rewards) - deliberately not a slot machine.
- Themes/biomes: Mad Max wasteland first, then cyberpunk, frost, toxic; more classes later
  (tank, fast raider, hauler exist). Difficulty rises each stage; leaderboards/rankings planned
  (currently local only; ideas: seeded daily runs, per-class boards, ghost runs).
- Must stay multiplatform: Android first, then web and PC. Keep input as actions, UI anchored,
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
  Output ends with `stage= level= kills= score= phase=`; any `SCRIPT ERROR` is a failure.
- Screenshots of every screen (needs a display or xvfb): `godot --path . res://tests/ui_shots.tscn -- --shots=<dir>`
- Builds: `tools/android/build_apk.sh` (signed APK), `tools/web/build_web.sh` (browser build).
Parse errors that mention `Sfx`/`Save` only occur when scripts are checked standalone (autoloads missing).

## Release flow
- CI (.github/workflows/android-apk.yml) smoke-tests, builds APK + web on every push, and deploys
  the web build to GitHub Pages from the default branch (needs repo public + Pages source "GitHub Actions").
- The APK is signed with the committed debug key (tools/android/debug-key, test builds only).
  Android export uses tools/android/sign_apk_v2.py so no Android SDK is required.

## Known gaps / next ideas
- Never tested on a real phone yet: check touch feel, FPS, pacing, balance (War Rig and Interceptor
  bots die before the first boss, Juggernaut clears it).
- More classes, enemy types and biomes; real art/audio; online leaderboard; PC controls polish.
