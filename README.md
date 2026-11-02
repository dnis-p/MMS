# DIG (working title)

Top-down 3D digging prototype in Godot 4.7, GDScript only, placeholder art and sound. The goal right now is
one thing: breaking cubes should feel like popping bubble wrap. There is now a first loop around it: a goal, gems to bank, a shop and unlocks.

This is the `prototype/dig` branch. The car game (MMS) is on the default branch, unchanged.

Play it in a browser: https://dnis-p.github.io/MMS/dig/ (mouse and keyboard). Each push to this branch updates it.

## How it plays
PC only for now.

| Action | Control |
| --- | --- |
| Move | WASD or arrows |
| Aim | Mouse |
| Menus and upgrades | Mouse, or arrows and Enter |
| Pause | Esc or P |

Fog of war is on by default: it thickens in rings around what you have mined or seen, your path stays clear behind you, and you can dig up to 7 cubes into it, except Mining Beam and Shock Pulse, which go through it. Switch it on the main menu or pause menu.

Movement is instant, like a 2D game, and separate from aiming. Tools dig by themselves where you aim. Cubes give a little XP, ore drops shiny gems worth more,
and each level-up lets you pick 1 of 3 tools or boosts and blasts the rock around you. Crystal goes off as a chain reaction.

A run ends when you break the Heart, leave by lift (green arrow, stand on it, from 30 s on), die or give up. Lifts and the Heart keep all your gems, the others half. Nothing points at the Heart: you hear it beat from 120 m away, and pink veins in the rock get thicker toward it. It is sealed until two bosses are dead, who come for you at 3:30 and 7:00.
Banked gems buy upgrades in the shop, and goals unlock characters and tools. Geodes burst into gems, vaults hold ore, shrines offer a trade and relics are yours for good: they all sparkle through the fog. Orange fuel seams burn along their whole length once lit. A long combo starts a Frenzy. "Reset progress" on the main menu erases your save.

## Commands
Run from the repo root after importing once (`godot --headless --path . --import`):
```
godot --headless --path . res://tests/dig_check.tscn              # digging rules, ends with DIG CHECK PASSED
godot --headless --path . -- --autotest --quit-after-sec=60       # smoke test: a bot plays
godot --path . -- --autotest --quit-after-sec=20 --shots=<dir>    # screenshots of a bot playing (needs a display)
```
Options after `--`: `--autotest`, `--seed=<n>`, `--give=<tools>` (or `all`), `--goal=<heart|lift>`, `--char=<id>`, `--unlocked`, `--shop=<level>`, `--god`, `--near-heart`, `--boss-at=<s>`, `--shots=<dir>`, `--quit-after-sec=<n>`. Bots never touch your save.

## Layout
- `scripts/data/defs.gd`: every number: cubes, bands, tools, boosts, shop, goals, camera.
- `scripts/data/profile.gd`: what carries over between runs, the save file.
- `scripts/game/mine.gd`: the cube world, hits, ripples, chain reactions, collision.
- `scripts/game/tools.gd`: tools, boosts and level-up choices.
- `scripts/game/enemies.gd`, `traps.gd`: enemies and nests, spike plates and gas rock.
- `scripts/game/sites.gd`: lifts, shrines and relics.
- `scripts/game/bosses.gd`: the two guardians and when they come.
- `scripts/game/run.gd`: one dig; routes events, how it ends, camera, input.
- `scripts/game/debris.gd`, `fx.gd`, `pickups.gd`: chips, rings and shake, gems.
- `docs/DESIGN.md`: ideas and decisions; sections 8 and 9 track done and to-do.
