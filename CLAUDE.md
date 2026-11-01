# DIG (working title), branch `prototype/dig`

Top-down 3D digging prototype in Godot 4.7, GDScript only, placeholder art and sound. It started from the car game (MMS),
which stays unchanged on the default branch `claude/sleepy-davinci-fxgwnn`: don't change that game from this branch.
See README.md for controls and layout. **Ideas and decisions are in docs/DESIGN.md: read the branch note at its top, and add any
new idea or decision the owner gives you there (mark owner's words vs your suggestions).**

## Design goals (from the owner, keep these in mind for every change)
- It should feel like popping bubble wrap, with Vampire Survivors rewards: juicy visuals and sound come first.
- Hit cubes flash white and vibrate; broken cubes explode into bits; ore leaves something shiny you pick up when close.
- Top-down 3D for now. World of small cubes, smaller than Minecraft's.
- Movement is instantly responsive, like 2D games such as VS or Enter the Gungeon, and separate from aiming: the mouse aims.
- Even the starter shovel hits multiple cubes.
- Enemies and traps exist now (owner, 2026-11-01), but digging feel still comes first. No theme yet, so no specific models.
- Fog of war, like an ARPG dungeon: the digger's light shows what is near, and you can only dig what you can see. It has a switch in the menus.
- The fog follows what you have opened or seen: rings thickening with distance, square and on the cube grid, over rock and unseen caves alike, and the path behind you stays clear but dims away from your lamp (owner's mockups, 2026-11-01).
- PC only for now (owner, 2026-10-31). Keep input as actions and UI anchored.

## Technical rules
- Cubes, gems and chips are packed arrays drawn with MultiMesh: no node per cube. Keep per-frame GDScript cheap.
- All balance numbers live in scripts/data/defs.gd. Prefer data over code for new content.
- Renderer is GL Compatibility.
- Match existing code style (tabs, typed GDScript, short doc comments only where non-obvious).

## Verify changes
Run from the repo root after the project has been imported once (`godot --headless --path . --import`):
- Rules: `godot --headless --path . res://tests/dig_check.tscn` must end with `DIG CHECK PASSED`.
- Bots can die: check `died:` and `hits=` over several `--seed` values when changing threats. `--give=all` tests late game, `--goal=heart` and `--goal=lift` test how a run ends, `--unlocked --shop=<n> --char=<id>` test a later profile.
- Smoke test: `godot --headless --path . -- --autotest --quit-after-sec=60`. Output ends with `level= cubes= score=`; any
  `SCRIPT ERROR` is a failure. Add `--seed=<n>` to fix the rolls.
- Screenshots of a bot playing (needs a display): `godot --path . -- --autotest --quit-after-sec=20 --shots=<dir>`
Parse errors that mention `Sfx` only occur when scripts are checked standalone (autoloads missing).

## Release flow
- Every push to this branch is built and tested by CI (.github/workflows/android-apk.yml), then published at
  https://dnis-p.github.io/MMS/dig/ by the default branch's workflow, which this branch's workflow starts. The car game stays at /MMS/.

## Known gaps / next ideas
- Feel and sound are unproven until the owner plays: nobody has listened to the sounds.
- Progression (Heart, lifts, gem bank, shop, goals, characters, rooms, evolutions) is a first version for testing. Prices, goals and difficulty are first guesses, and there are no bosses and no new tools yet.
- The map is small for its digging speed: a run lasts as long as the Heart fight, not as long as the walk.
- Mouse aiming is untested with a real mouse.

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
- Godot 4.7.2 lives in the folder `../Godot_v4.7.2-stable_win64.exe/`
  (the folder name ends in .exe). Binaries inside: `Godot_v4.7.2-stable_win64.exe` (GUI) and
  `Godot_v4.7.2-stable_win64_console.exe` (use this one for headless runs so output reaches the terminal).
  It is not on PATH. In Git Bash:
  `G="../Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"`
  then `"$G" --headless --path . --import` and `"$G" --headless --path . -- --autotest --quit-after-sec=60`.
- Android Studio is installed; the Android SDK and Java are set in the Godot editor, so APKs can be exported
  from the editor (Project > Export). `tools/android/build_apk.sh` and `tools/web/build_web.sh` call `godot`
  from PATH, so they need a `godot` alias/shim to the console exe in Git Bash (bash itself is available).
- The car game's saves are in `%APPDATA%/MMS` (scores.cfg, profile.cfg). Real progress: don't delete it without asking. This branch uses `MMS-Dig`, where `profile.cfg` holds the owner's dig progress.
- `icon.svg.import` shows as modified after imports (line endings); ignore it, don't commit it.
