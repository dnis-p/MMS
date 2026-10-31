# DIG (working title)

Top-down 3D digging prototype in Godot 4.7, GDScript only, placeholder art and sound. The goal right now is
one thing: breaking cubes should feel like popping bubble wrap. There are no threats and no way to lose yet.

This is the `prototype/dig` branch. The car game (MMS) is on the default branch, unchanged.

## How it plays
PC only for now.

| Action | Control |
| --- | --- |
| Move | WASD or arrows |
| Aim | Mouse |
| Menus and upgrades | Mouse, or arrows and Enter |
| Pause | Esc or P |

Fog of war is on by default: you see and dig only what your light reaches, except Mining Beam and Shock Pulse, which go through it. Switch it on the main menu or pause menu.

Movement is instant, like a 2D game, and separate from aiming. Tools dig by themselves where you aim. Cubes give a little XP, ore drops shiny gems worth more,
and each level-up lets you pick 1 of 3 tools or boosts and blasts the rock around you. Crystal goes off as a chain reaction.

## Commands
Run from the repo root after importing once (`godot --headless --path . --import`):
```
godot --headless --path . res://tests/dig_check.tscn              # digging rules, ends with DIG CHECK PASSED
godot --headless --path . -- --autotest --quit-after-sec=60       # smoke test: a bot plays
godot --path . -- --autotest --quit-after-sec=20 --shots=<dir>    # screenshots of a bot playing (needs a display)
```
Options after `--`: `--autotest`, `--seed=<n>`, `--give=<tools>`, `--shots=<dir>`, `--quit-after-sec=<n>`.

## Layout
- `scripts/data/defs.gd`: every number: cubes, bands, tools, boosts, camera.
- `scripts/game/mine.gd`: the cube world, hits, ripples, chain reactions, collision.
- `scripts/game/tools.gd`: tools, boosts and level-up choices.
- `scripts/game/run.gd`: one dig; routes events, camera, input.
- `scripts/game/debris.gd`, `fx.gd`, `pickups.gd`: chips, rings and shake, gems.
- `docs/DESIGN.md`: ideas and decisions; sections 8 and 9 track done and to-do.
