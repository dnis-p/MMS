# DIG (working title)

Top-down 3D digging prototype in Godot 4.7, GDScript only, placeholder art and sound. The goal right now is
one thing: breaking cubes should feel like popping bubble wrap. There is now a first loop around it: a goal, gems to bank, a shop and unlocks.

Play it in a browser: https://dnis-p.github.io/dig/ (mouse and keyboard, or a gamepad). Each push to `main` updates it.

## How it plays
PC only for now.

| Action | Control |
| --- | --- |
| Move | WASD or arrows, or left stick or d-pad |
| Dash | Space or Shift, or A: once you hold the Dash Drive (a level-up card), a burst of speed the way you move |
| Aim | Mouse (only the direction counts), or right stick |
| Menus and upgrades | Mouse, or arrows and Enter, or left stick or d-pad and A (B goes back) |
| Pause | Esc or P, or Start |
| Map | M or Tab, or Back: tap to keep it open over the game, hold to peek. Mouse wheel, + and -, or the shoulder buttons zoom it |

The game follows whichever you used last, so you can swap between gamepad and mouse at any time. Without aiming, tools point the way you walk. During a run the mouse pointer is hidden: an arrow on a ring around the digger shows where you aim, and Bombs pick their own targets.

The same list is on the **Controls** page, on the main menu and in the pause menu (`Help.controls()` in `scripts/ui/help.gd`). The hint at the start of a run names the map key too.

New players and testers: **How to play** on the main menu explains the goal, ways out, dangers and what to look for. Its text is in `scripts/ui/help.gd`, with numbers read from `defs.gd`.

Fog of war is on by default: it thickens in rings around what you have mined or seen, your path stays clear behind you, and you can dig up to 7 cubes into it, except Mining Beam and Shock Pulse, which go through it. Switch it in Options on the main menu, or in the pause menu.

The minimap in the bottom right and the full map show only what you have opened or seen, plus the rock at its edge. The full map lies over the game with your digger on the map right on top of your digger; its opacity is in Options and the pause menu.

Movement is instant, like a 2D game, and separate from aiming. Tools dig by themselves where you aim. Cubes give a little XP, ore drops shiny gems worth more,
and each level-up lets you pick 1 of 3 tools or boosts and blasts the rock around you. Crystal goes off as a chain reaction.

A run ends when you break the Heart, leave by lift (green arrow, stand on it, from 30 s on), die or give up. Lifts and the Heart keep all your gems, the others half. Nothing points at the Heart: you hear it beat from 120 m away, and pink veins in the rock get thicker toward it. It is sealed until two bosses are dead, who come for you at 3:30 and 7:00.
Each run holds 4 different tools and 4 boosts; the Tool Belt in the shop raises that to 6. The Dash Drive is a card that takes a tool slot: it is the one thing you press, a short untouchable dash. It levels up like a tool: longer, faster, a shorter wait, then a decoy clone that enemies attack, which gains health and later explodes. Banked gems buy upgrades in the shop, and goals unlock characters and tools. Geodes burst into gems, vaults hold ore, shrines offer a trade and relics are yours for good: they all sparkle through the fog. Orange fuel seams burn along their whole length once lit, and cracked pale rock brings rubble down on the tunnels around it, crushing what stands there. A long combo starts a Frenzy. "Reset progress" on the main menu erases your save.

## Commands
Run from the repo root after importing once (`godot --headless --path . --import`):
```
godot --headless --path . res://tests/dig_check.tscn              # digging rules, ends with DIG CHECK PASSED
godot --headless --path . -- --autotest --quit-after-sec=60       # smoke test: a bot plays
godot --path . -- --autotest --quit-after-sec=20 --shots=<dir>    # screenshots of a bot playing (needs a display)
```
Options after `--`: `--autotest`, `--seed=<n>`, `--give=<tools>` (or `all`; `dash` is the Dash Drive at its top level), `--goal=<heart|lift>`, `--char=<id>`, `--unlocked`, `--shop=<level>`, `--god`, `--near-heart`, `--boss-at=<s>`, `--shots=<dir>`, `--quit-after-sec=<n>`. Bots never touch your save.

## Layout
- `scripts/data/defs.gd`: every number: cubes, bands, tools, boosts, shop, goals, camera.
- `scripts/data/profile.gd`: what carries over between runs, the save file.
- `scripts/game/mine.gd`: the cube world, hits, ripples, chain reactions, collision.
- `scripts/game/tools.gd`: tools, boosts and level-up choices.
- `scripts/game/dash.gd`: the Dash Drive: dash, its levels and the decoy clone.
- `scripts/game/enemies.gd`, `traps.gd`: enemies and nests, spike plates and gas rock.
- `scripts/game/sites.gd`: lifts, shrines and relics.
- `scripts/game/bosses.gd`: the two guardians and when they come.
- `scripts/ui/loading.gd`: the loading screen.
- `scripts/game/run.gd`: one dig; routes events, how it ends, camera, input.
- `scripts/game/debris.gd`, `fx.gd`, `pickups.gd`: chips, rings and shake, gems.
- `docs/DESIGN.md`: ideas and decisions; sections 8 and 9 track done and to-do.
- `docs/MECHANICS.md`: how the game works now: rules, formulas, scaling and what to edit for a tweak.
- `docs/ART.md`: the art style (low-poly pixel 3D) and a Meshy AI prompt for every model.
