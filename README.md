# Motorhead Madness Survival (working title) — gameplay prototype

A test of the core gameplay loop with placeholder art and sound. Your vehicle drives itself along a set
path through biomes and auto-fires at hordes of enemies. You steer, pick upgrades, and dodge bosses
in a ring arena. The goal is Vampire Survivors–style "satisfying without thinking" play.

Built with **Godot 4.7** (GDScript, Compatibility renderer), so the same project exports to Android,
iOS, Windows, macOS, Linux and Web.

## How to play

| | Phone | Keyboard |
|---|---|---|
| Steer on the road | Drag left / right anywhere | A / D or ← / → |
| Boss: dash along the ring | Swipe left / right, or tap a screen side | A / D or ← / → |
| Boss: switch ring | Swipe up (inner) / down (outer) | W / S or ↑ / ↓ |
| Pause | ‖ button or Back | Esc / P |

- **Road phase (2:30):** weapons fire on their own. Destroyed enemies drop scrap (XP) and you level up by picking 1 of 3 upgrades.
  Ramming kills weak enemies. A **HORDE** surrounds you about every 30 s, and **ELITES** drop a salvage crate.
- **Salvage crate ("Redline"):** the engine revs and a tachometer needle decides the haul:
  green = 1 item, orange = 3, redline = 5. A max-level weapon plus its partner passive **evolves** here.
- **Boss arena:** you circle the boss automatically on one of 3 rings.
  - Radial bursts: find the gap or dash through.
  - Ring slams: the target ring flashes red, so switch rings.
  - Sweeping beam: dash through it (dashing makes you briefly invulnerable).
  - Summoned adds.
- After the boss you drive on to the next biome (Rust Wastes → Neon Sprawl → Frost Line → Toxic Bog,
  then it loops), and everything gets harder each stage.
- **Score:** kills × combo multiplier (up to 5×) plus boss bonuses. The top 10 are saved on the device
  (a stand-in for an online leaderboard).
- The pause menu has **Skip to boss (test)** to reach the boss fight quickly.

### Content

- **Classes:** Juggernaut (tank, starts with Rocket Pod), Interceptor (fast and fragile, Hood MG),
  War Rig (balanced, Saw Blades).
- **Weapons (max level 5, up to 4 slots):** Hood MG, Rocket Pod, Saw Blades, Mine Dropper, Tesla Coil, Shock Plating.
- **Passives (up to 4 slots):** Armor Plating, Turbocharger, Scrap Magnet, Blast Compound, Hot Rounds.
- **Evolutions:**

  | Weapon | + Passive | Becomes |
  |---|---|---|
  | Hood MG | Hot Rounds | Shredder Minigun |
  | Rocket Pod | Turbocharger | Swarm Barrage |
  | Saw Blades | Blast Compound | Buzzkill Halo |
  | Mine Dropper | Hot Rounds | Napalm Mines |
  | Tesla Coil | Scrap Magnet | Storm Rod |
  | Shock Plating | Armor Plating | Thunder Hull |

All numbers live in [`scripts/data/defs.gd`](scripts/data/defs.gd), so balancing means editing that file.

## Playing in a browser

The Web export needs no code changes (it uses the single-threaded template, so no special server
headers are required). `tools/web/build_web.sh` produces:

- `build/web/` and `build/mms-web.zip`: the standard export. Upload the zip to **itch.io** as an HTML
  game (Kind of project: HTML, "This file will be played in the browser", viewport 1280×720, enable
  the mobile-friendly and fullscreen-button options). It can stay a draft or restricted page with a
  secret link.
- `build/web-packed/`: the same game started by `tools/web/launcher.html`, with the 39 MB engine
  gzipped to about 10 MB and unpacked in the browser. Use this for hosts that cap file size.

Every CI run uploads the itch.io-ready folder as the `mms-web-itch-io` artifact.

**GitHub Pages (auto-deploy):** with the repo public and Settings → Pages → Source set to
"GitHub Actions", every push to the default branch publishes the web build at
`https://<user>.github.io/<repo>/`.
Browsers need WebGL 2: current Chrome, Edge, Firefox and Safari all qualify, on desktop and phone.

## Installing the APK on Android

1. Copy `mms-prototype.apk` to the phone and open it.
2. Allow "install unknown apps" for the app you opened it with (Files, Chrome, …).
3. If Play Protect warns about an unknown developer, choose **Install anyway**. It's a debug-signed build.

Android 7.0+ on a 64-bit (arm64) device. Builds are signed with the same debug key, so newer
builds install over older ones.

## Project layout

```
scenes/main.tscn          entry scene
scripts/main.gd           menu <-> run switching, input map, autotest
scripts/data/defs.gd      classes, weapons, passives, enemies, biomes, curves
scripts/game/run.gd       a playthrough: phases, spawn director, damage/XP/score, camera, input
scripts/game/road.gd      spline path, road mesh, ground shader, roadside props
scripts/game/player.gd    vehicle model + road/arena driving
scripts/game/enemies.gd   horde as packed arrays + MultiMesh + spatial grid
scripts/game/projectiles.gd, pickups.gd, weapons.gd, boss.gd, fx.gd
scripts/ui/               HUD, level-up cards, Redline crate gauge, overlays, menu, theme
scripts/autoload/sfx.gd   procedurally synthesized placeholder sounds
scripts/autoload/save.gd  local leaderboard
tests/ui_shots.tscn       dev tool: screenshots every screen
tools/android/            APK build + v2 signing scripts, debug signing key
tools/web/                web build script and the gzip launcher page
```

Enemies, bullets and pickups are plain data drawn with MultiMesh (no node or physics body per
enemy), which keeps hundreds of them cheap on phones. The HUD shows FPS and enemy count at the
bottom-left so performance on a real device is easy to check.

## Building

Open the folder in Godot 4.7 and press Play, or:

```bash
godot --path .                                         # play on desktop
godot --headless --path . -- --autotest --quit-after-sec=60    # unattended smoke test (god mode, short stages)
godot --headless --path . -- --autotest --fair --class=interceptor --quit-after-sec=120   # balance check
tools/android/build_apk.sh                             # signed arm64 APK -> build/mms-prototype.apk
tools/web/build_web.sh                                 # browser build -> build/web, build/mms-web.zip
```

To export from the Godot editor instead, install the Android export templates, set the Android SDK
and Java paths in Editor Settings, and use **Project → Export → Android**. The preset exports
unsigned, so either sign with `tools/android/sign_apk_v2.py` or turn on **package/signed** and use your own keystore.
The included key in `tools/android/debug-key/` is for test builds only. Don't use it for a store release.
