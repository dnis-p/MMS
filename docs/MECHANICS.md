# DIG: how the game works

Technical reference for DIG: the rules as they are now, not how they got there. Written so a person or a model can reason about tweaks without reading all the code.

- **The code wins.** All balance numbers live in `scripts/data/defs.gd`. If this file and `defs.gd` disagree, `defs.gd` is right, and this file needs fixing.
- **Names.** `RUN.cave_r` means key `cave_r` in the `Defs.RUN` dictionary. The same goes for `THREATS`, `WORLD`, `FRENZY`, `DIGGER`, `CAMERA`, `AIM` and `PAD`.
- **Units.** Distances are metres, times are seconds. One cube is 0.5 m wide.
- **Status.** Numbers are first guesses for testing. Section 15 says what has been measured.
- **History and ideas.** `docs/DESIGN.md` keeps decisions, the done list (section 6) and the to-do list (section 7).

## 1. The game in short
Top-down 3D digging roguelite, in Godot 4.7, GDScript, GL Compatibility renderer. The target feel is popping bubble wrap with Vampire Survivors rewards. You move, and your tools dig and fight by themselves where you aim. Each level-up offers 3 upgrades. Break the Heart at the far end of the mine, or leave early by lift, to keep what you carried. Gems banked between runs buy permanent upgrades. The target run length is about 10 minutes (owner).

## 2. Timeline of a run
All times are `run_time`, game seconds.

| Time | What happens |
| --- | --- |
| 0 | Start in a clear circle of radius `WORLD.start_clear` = 3.5 m, with a lift beside you |
| 7 | Hint about the Heart's beat and the pink veins |
| 20 | Swarm begins (`THREATS.swarm_from` = 20) |
| 30 | Lifts work (`RUN.lift_from` = 30) |
| 60 | First burrowers (`THREATS.burrow_from` = 60) |
| 75 | First horde (`THREATS.horde_from` = 75) |
| 210 | The Borer arrives |
| 420 | The Brood arrives, or `RUN.boss_gap` = 90 s after the Borer died if that is later |
| After both | The Heart can be damaged |

## 3. How a run ends

| End | Gems kept | Notes |
| --- | --- | --- |
| Heart broken | 100% + `RUN.heart_bonus` = 500 | Results appear 1.8 s later |
| Lift | 100% | Stand on a pad for `RUN.lift_hold` = 1.5 s, within `RUN.lift_pad` = 1.7 m. Needs at least 1 gem carried |
| Death | `RUN.death_keep` = 0.5 + Insurance | Results appear 1.2 s later |
| Give up | Same as death | From the pause menu |

Goals are checked and paid only here, at the end of a run, and their gems are not cut by the death share. A run can only bank once.

## 4. Levelling
- XP to the next level: `24 + (level - 1) * 10 + max(0, level - 15) * 10` (`Defs.xp_to_next`).
- XP comes from cubes (their `xp` value, most of it small) and gems: `gem value * RUN.gem_xp`, with `RUN.gem_xp` = 0.35. Geode gems count for only `RUN.geode_xp` = 0.4 of that. Enemies give no XP directly, only through the gem they drop.
- Gem pickups do both jobs at once: XP as above, and carried gems of `gem value * gem_rate * RUN.gem_bank`, with `RUN.gem_bank` = 0.12. So 1 gem value is 0.35 XP and 0.12 gems. `gem_rate` affects gems only, never XP.
- `gem_rate` is `character gems * (1 + shop greed + relics)`, times 1.5 after a Greed Shrine.
- **Gems on the floor:** at most 1,500 (`Pickups.MAX`). When full, a new gem still lands where it fell: of 8 random gems not flying to you, the two farthest from you merge into one worth both, keeping the value. Strong builds reach the cap: a bot with drill, Shock Pulse and Spark Coil filled it by 2:00, mostly with gems from rock broken out of sight.

| Level | XP to next | Total XP to reach it |
| --- | --- | --- |
| 1 | 24 | 0 |
| 2 | 34 | 24 |
| 5 | 64 | 156 |
| 10 | 114 | 576 |
| 15 | 164 | 1246 |
| 16 | 184 | 1410 |
| 20 | 264 | 2266 |
| 25 | 364 | 3786 |
| 30 | 464 | 5806 |

**A level-up:** the game pauses and offers 3 cards. After you pick, a blast clears rock within `WORLD.level_blast` = 3.5 m, through fog, does a fixed 60 to enemies there, and heals `DIGGER.level_heal` = 30.

**Cards:** eligible evolutions always come first, then random picks. Each unlocked tool or boost below max is in the draw, and owned tools count twice, so you tend to get what you already have. If nothing is left you get +500 score (`Defs.FILLER_SCORE`).

**Slots:** a run holds at most `SLOTS.tools` = 4 different tools and `SLOTS.boosts` = 4 boosts, the starting tool included, plus 1 of each per Tool Belt level (up to 6 and 6). When a kind is full, new ones of that kind leave the draw and only levels of what you hold are offered. Evolutions don't need a slot. A NEW card for the last free slot carries the hint "Last tool slot" or "Last boost slot". The HUD shows free slots as dim empty boxes, and the level-up screen shows `Tools n/max · Boosts n/max`. Bots' `--give` ignores slots. The Dash Drive (section 6) takes one of the tool slots, and counts in all of those.

## 5. The digger

| Stat | Formula |
| --- | --- |
| Max health | `(DIGGER.hp + shop health + relics) * character hp * wind + Thick Skin * 20` |
| Speed | `DIGGER.speed * character speed * (1 + shop legs + relics) * wind * (1 + Light Boots * 0.08)` |
| Pickup range | `DIGGER.pickup * (1 + shop magnet) * (1 + Magnet * 0.4)` |

- `DIGGER.hp` = 100, `DIGGER.speed` = 7.5, `DIGGER.pickup` = 3.5. A Wind Shrine sets wind to 1.2 for speed and 0.75 for health.
- Movement is instant, full speed in any direction, with no acceleration. Aim is separate. With no aim input, tools point the way you walk.
- **Mouse aim.** During a run the mouse is captured and hidden. It moves a hidden pointer that stays within `AIM.reach` = 160 pixels of mouse travel from the digger, and only the pointer's angle aims, so a bigger reach turns slower: walking doesn't turn it, pushing the mouse outward holds it on the ring, and a push across (320 px) turns it around. A white arrow (`AIM.arrow_alpha` = 60% opacity, no outline) on a faint ring (`AIM.ring_alpha` = 14%) `AIM.ring` = 2.6 m from the digger shows the aim, for the mouse and the right stick alike. Menus, level-ups and the pause menu give the mouse back. If the capture is lost while playing (Esc in a browser), the game pauses; a click in the game asks for it again.
- **Camera.** It looks `CAMERA.lead` = 0.12 s of travel ahead, plus `CAMERA.aim_lean` = 1.5 m the way you aim while the mouse or right stick aims.
- After a hit you can't be hurt for `DIGGER.invuln` = 0.8 s. This caps all damage to one hit per 0.8 s, however many enemies touch you.
- Regen: `DIGGER.regen` = 3 health per second after `DIGGER.regen_after` = 4 s without a hit.
- Killing a boss heals you fully.

| Id | Starts with | HP x | Speed x | Gems x | Other | Unlock |
| --- | --- | --- | --- | --- | --- | --- |
| digger | shovel | 1 | 1 | 1 |  | start |
| prospector | shovel | 0.5 | 1 | 2 |  | Reach the Stone layer |
| rig | drill | 1.6 | 0.85 | 1 | no aiming | Bank 3,000 gems in total |

## 6. Tools
Tools fire by themselves. You start with one (see characters) and can own all of them.

| Stat | Formula |
| --- | --- |
| Damage | `base dmg * power_of * evolution * (1 + shop power + relics)` |
| `power_of` | `(1 + 0.4 * (level - 1)) * (1 + 0.15 * Hard Edge)` |
| Size | `base size * (1 + size_up * (level - 1)) * (1 + 0.08 * Long Handle)` |
| Cooldown | `base cd * cd_up^(level - 1) * 0.93^Quick Hands` |

Tools max at level 6 (`Defs.MAX_TOOL_LEVEL`), boosts at 5 (`Defs.MAX_BOOST_LEVEL`).

**Countdowns and frame rate.** Every repeating countdown (tool cooldowns, boss attacks, enemy spawns, enemy wake and dig checks, the heartbeat, fog scans, goal checks) restarts with `Defs.restart(left, every, delta)`. It keeps the part of the frame that went past zero, at most one frame's worth, so things fire equally often at any frame rate. Each still fires on a frame, so a single hit can land up to one frame late, and nothing fires more than once per frame: below `1 / cooldown` fps a tool slows down. A tool that waited for something to hit (shovel, bombs) starts a fresh countdown.

| Tool | Unlock | Dmg | Size | Cooldown | Cooldown per level | Size per level | Extra |
| --- | --- | --- | --- | --- | --- | --- | --- |
| shovel | start | 9 | 2.4 | 0.3 | x0.95 | +12% | arc 1.15 |
| drill | start | 3 | 4 | 0.065 | x0.95 | +15% |  |
| saws | start | 8 | 3 | 0.09 | x1 | +10% | spin 5.0, cut 0.7 |
| bombs | Get out by lift | 60 | 3 | 2.2 | x0.93 | +12% | throw 8, pick 3, ahead 45, retry 0.2 |
| pulse | Break 25,000 cubes | 30 | 5 | 3 | x0.93 | +12% | ring_time 0.35 |
| beam | find it in the rock | 40 | 14 | 2.4 | x0.93 | +12% |  |
| spark | Kill a boss | 16 | 9 | 1 | x0.93 | +10% | hops 3, bite 1.2 |
| moles | Burn 5 fuel seams | 7 | 8 | 0.14 | x0.97 | +12% | bite 0.9, speed 7 |

| Tool | How it behaves | Reaches through fog? |
| --- | --- | --- |
| shovel | Fan in front of you, half-angle `arc` in radians. Swings only when something is in reach | No |
| drill | Straight strip ahead, half-width 0.5 (3 cubes across, 7 when evolved), `size` long. Hits every cooldown without pausing. Pale chevrons running forward lie over the cells it bites, fading out towards the sides and tip so the strip has no hard edge, brighter while it hits (`strip` opacity, `strip_speed`) | No |
| saws | `min(2 + level / 2, 6)` blades orbit you, each cutting a circle of radius `cut` | No |
| bombs | Aim themselves, within `throw` m: at one of the `pick` closest awake enemies, at random; with none, at the nearest seen rock, rock within `ahead` degrees of your aim first; with neither, no throw, and they look again after `retry` s. Up to 6 in the air | No, the target must be seen |
| pulse | Ring bursting out from you | Yes |
| beam | Long line along your aim, half-width 0.6 | Yes |
| spark | Jumps between awake enemies, `hops + level / 2` of them, biting rock under each. With no enemy in reach it bites rock ahead | No |
| moles | `1 + level / 2` moles roam around you, biting what they pass. Up to 6 | Yes |

### Boosts
| Boost | Effect per level |
| --- | --- |
| power (Hard Edge) | +15% digging damage |
| reach (Long Handle) | +8% tool size |
| haste (Quick Hands) | -7% tool cooldowns |
| legs (Light Boots) | +8% move speed |
| magnet (Magnet) | +40% pickup range |
| tough (Thick Skin) | +20 max health |

### Evolutions
A tool at max level plus `Defs.EVOLVE_BOOST` = 3 levels of the named boost offers an evolution card at the next level-up.

| Tool | Needs boost | Becomes | Effect |
| --- | --- | --- | --- |
| shovel | reach | Great Scoop | Swings all the way around you. +50% damage. |
| drill | haste | Tunnel Borer | Bores a corridor three times wider. +50% damage. |
| bombs | power | Cluster Bombs | Every blast throws four smaller ones. |
| spark | magnet | Storm Coil | Twice as many jumps. +50% damage. |
| moles | tough | Mole Army | Two more moles, biting twice as hard. |

### Dash Drive
The one thing you press: Space or Shift, or the gamepad's A (`dash` action). It takes one tool slot, is a level-up card like a tool, is never locked, and has no evolution. It levels up like a tool, from 1 to 6. All numbers are in `Defs.DASH`, the code in `scripts/game/dash.gd` and `Player.move`.

| Stat | Formula |
| --- | --- |
| Dash | `DASH.base.speed` = 30 m/s for `DASH.base.time` = 0.2 s, so 6 m |
| Speed | `30 * (1 + 0.15 * speed steps)` |
| Time | `0.2 * (1 + 0.2 * length steps)`. Distance is speed times time |
| Untouchable | The dash's time plus `DASH.base.grace` = 0.15 s. This sets `Player.invuln`, so it also blinks you |
| Cooldown | `3 * (1 - 0.15 * recharge steps)`, counted from the moment you press |
| Direction | The way you are steering. With no input, the way you last walked (`Player.last_move`). Mouse aim and the right stick don't matter |

- **While dashing** you can't steer, tools keep firing, and your facing follows your aim as always. Rock stops you, and the move is split into steps of at most 0.2 m (`Mine.CELL * 0.4`) so it can't skip a wall.
- **Levels** (`DASH.levels`, each adding steps worth `DASH.step`). One card per level, always titled Dash Drive. Level 1 says NEW, as it takes the slot; the rest say "Lv 1 > 2" and so on, take no slot, and are favoured in the draw like a tool you hold. At level 6 no more cards come.

| Level | Adds | Dash | Cooldown |
| --- | --- | --- | --- |
| 1 | The dash | 6 m | 3 s |
| 2 | +20% dash time, -15% cooldown | 7.2 m | 2.55 s |
| 3 | The decoy clone, +15% dash speed | 8.3 m | 2.55 s |
| 4 | +20% dash time, -15% cooldown, +50% clone health | 9.7 m | 2.1 s |
| 5 | The clone explodes when it falls, +15% dash speed | 10.9 m | 2.1 s |
| 6 | -15% cooldown, +50% clone health, +40% blast damage, a wider blast | 10.9 m | 1.65 s |

At level 6 the clone has `1.2 * 2` = 2.4 times your max health, and the blast does 140 damage in 3.9 m (before Hard Edge, Long Handle and the shop).
- **Not while** dead or leaving by lift, or in the middle of a dash.
- **The clone.** From level 3 each dash leaves one where you stood: a translucent copy of your body with a health bar. Health is `max health * DASH.clone.hp_frac` = 1.2 `* (1 + 0.5 * clone_hp steps)`. It lasts `DASH.clone.life` = 8 s and blinks for the last 1.5. A new dash pops a clone that still stands before it makes the next. It goes at the end of a run without a blast.
- **Who goes for it.** Every awake enemy, bosses included, compares its distance to you with its distance to the clone: if the clone is closer than `DASH.clone.taunt` = 0.7 times the distance to you, the enemy walks to the clone and attacks that. Sleepers don't care. Enemies not near the clone still come for you. Touching it hurts it by the enemy's own damage (`Enemies.dmg`, already scaled by your build and depth), at most once per `DASH.clone.hit_gate` = 0.2 s, however many touch it.
- **The blast** (from level 5; `clone_boom` steps: 1 at level 5, 2 at level 6). When the clone falls, from health or time or being replaced, it breaks rock and hurts enemies in `DASH.clone.boom_radius` = 3.5 m `* (1 + 0.12 * (steps - 1)) * Long Handle` for `boom_dmg` = 100 `* (1 + 0.4 * (steps - 1)) * Hard Edge * shop damage`. Through fog only the rock you can see breaks, as with Bombs. Enemies hit are pushed away like any hit.
- **Scaling.** Each level counts as one upgrade in `upgrades` (section 8), as a tool's levels do, so a full drive is worth 6.

## 7. Enemies

| Enemy | HP | Speed | Radius | Contact dmg | Gem value | Score | Knock |
| --- | --- | --- | --- | --- | --- | --- | --- |
| crawler | 8 | 4.6 | 0.34 | 4 | 0.3 | 30 | 1 |
| brute | 130 | 3 | 0.8 | 15 | 8 | 300 | 0.2 |
| burrower | 45 | 3.8 | 0.5 | 8 | 3 | 120 | 0.6 |
| runner | 5 | 7 | 0.3 | 3 | 0.3 | 40 | 1.2 |
| borer | 900 | 3.6 | 1.5 | 14 | 0 | 5000 | 0 |
| brood | 1600 | 2.4 | 2 | 18 | 0 | 10000 | 0 |

All of these are multiplied by the scaling in section 8. Colours are in `Defs.ENEMIES`: bodies stay dark so they don't look like gems, and `shine` is the colour of the gem dropped.

| Source | How they come | Through rock? |
| --- | --- | --- |
| Nests | `THREATS.nests` = 220 open pockets, none within `THREATS.safe_start` = 20 m of the start. They fill with sleepers when you come within `THREATS.nest_fill` = 50 m. `THREATS.nest_size` = 10 plus `THREATS.nest_band` = 2 per band, with one brute from band `THREATS.brutes_from` = 3 | No, stopped by rock |
| Swarm | Off screen, in a burst every `THREATS.swarm_every` = 1.2 s | Yes |
| Horde | `THREATS.horde_waves` = 3 full rings off screen, `THREATS.horde_gap` = 4 s apart, with one "SWARM!" banner. Once the Heart wakes, one ring each time | Yes |
| Burrowers | `1 + band / 2` of them, off screen, every `max(7, 22 - band * 2)` s | Yes |
| The Brood | Drops 12 crawlers around itself each cycle | Yes |

- **Off screen:** the swarm, hordes, burrowers and bosses start `THREATS.spawn_margin` = 2.5 m past the edge of what the camera shows, plus up to `THREATS.spawn_depth` = 3 m. The edge is where the screen's corners meet the ground, at 16:9 about 16 m above the digger on the screen, 10 m below and 12 m to each side, more toward the corners, so hordes are not round: the ring is shaped like the screen. Near the mine's edge, a spot that would be pulled into view is skipped. Bosses also start at least `RUN.boss_range` = 24 m away. The Brood's crawlers are the exception: they come out of the Brood.
- **Waking:** with fog on, a sleeper wakes when its spot has been seen. With fog off, within `THREATS.wake_range` = 12 m. Checked every `THREATS.wake_every` = 0.2 s. One waking, or being hit, wakes its whole nest.
- **Forgetting:** anything past 70 m is removed (`Enemies.FORGET_RANGE`), bosses aside, and a nest that lost a sleeper this way can fill again.
- **Limits:** 1,500 enemies alive (`Enemies.MAX`), 640 of them sleepers (`Enemies.SLEEPERS`), so swarms always have room.
- **Digging enemies** remove rock in `carve()`, with no XP, gems or chain reactions. They can't dig the Heart or bedrock.
- **Damage:** nothing shoots yet. All enemy damage is by touch, apart from the Brood's gas.

## 8. Scaling
Three things scale the threat: your build, distance from the start, and run time. Player level has no direct effect, and only the upgrades you own count.

**From your build.** Recomputed every frame in `Run._update_power()`:

```
upgrades = max(0, (sum of tool levels + sum of boost levels + Dash Drive level) - 1 - free_upgrades)
best     = highest power_of among owned tools

hardness = best ^ hard_power * (1 + tough_per * upgrades)   enemy health
crowd    = 1 + crowd_per * upgrades                         how many come
pace     = min(1 + pace_per * upgrades, pace_max)           enemy speed
harm     = (1 + harm_per * upgrades) * greed_harm           enemy damage
nudge    = 1 / (1 + nudge_per * upgrades)                   how far hits push them
runners  = min(runner_per * upgrades, runner_max)           share of the swarm that are runners
```

Current values: `THREATS.hard_power` = 1.0, `THREATS.free_upgrades` = 8, `THREATS.tough_per` = 0.04, `THREATS.crowd_per` = 0.05, `THREATS.pace_per` = 0.012, `THREATS.pace_max` = 1.45, `THREATS.harm_per` = 0.02, `THREATS.nudge_per` = 0.05, `THREATS.runner_per` = 0.012, `THREATS.runner_max` = 0.45. A Greed Shrine sets `greed_harm` to 1.3.

With `hard_power` at 1.0, hits-to-kill stays about the same as your tool's level and Hard Edge grow. Shop damage, relic damage and evolutions are not in `power_of`, so they are a true edge over enemies.

Example at level 17 with 16 picks and no shrines: `upgrades` = 8, so `crowd` 1.4, `pace` 1.096, `harm` 1.16, plus 32% health on top of `best`. A level 6 tool with 5 levels of Hard Edge has `best` = 5.25, so `hardness` = 6.93.

**From distance.** `band` comes from straight-line distance from the start (section 12).

```
enemy health = base hp  * (1 + hp_band * band)  * hardness
enemy damage = base dmg * (1 + dmg_band * band) * harm
enemy speed  = base speed * pace * random 0.9 to 1.1
```

`THREATS.hp_band` = 0.2, `THREATS.dmg_band` = 0.1. An enemy's stats are set once, when it spawns, and again when a sleeper wakes. Enemies already awake don't get stronger when you do.

**From time.**

```
swarm burst = (swarm_size + swarm_size_ramp * t) * crowd
awake limit = min((swarm_alive + swarm_alive_ramp * t) * crowd, swarm_max)   no burst while at the limit
horde size  = min((horde_size + horde_ramp * t) * crowd, horde_max)   per ring, horde_waves rings
horde every = horde_every / sqrt(crowd), or heart_horde once the Heart wakes
```

`THREATS.swarm_size` = 2, `THREATS.swarm_size_ramp` = 0.012, `THREATS.swarm_alive` = 25, `THREATS.swarm_alive_ramp` = 0.3, `THREATS.swarm_max` = 430, `THREATS.horde_size` = 40, `THREATS.horde_ramp` = 0.12, `THREATS.horde_max` = 320, `THREATS.horde_waves` = 3, `THREATS.horde_gap` = 4, `THREATS.horde_every` = 55, `RUN.heart_horde` = 12.

Build and time multiply each other. At 10 minutes with `crowd` 1.4, the awake limit is about 287 and each horde ring is about 156, so about 470 in a horde.

## 9. Bosses and the Heart
**Bosses** (`Defs.BOSSES`, `scripts/game/bosses.gd`) always come in order, on a timer, starting off screen and at least `RUN.boss_range` = 24 m away, digging towards you. Past `RUN.boss_leash` = 45 m they are pulled back to the same distance, so you can't lose them.

- Health is `base hp * hardness`, set when it arrives. Distance doesn't count. Damage is `base dmg * harm`.
- **The Borer** chases for 5 s, stops for 0.9 s and shows its line, then charges along it at 16 m/s for 0.9 s, carving rock. Sidestep it and it hits nothing.
- **The Brood** every 4.5 s lobs 3 gas bombs, one on you and two 3 to 7 m from you, and drops 12 crawlers around itself.
- **A kill** drops `RUN.boss_gems` = 40 gems worth `RUN.boss_gem` = 12 each, gives `RUN.boss_levels` = 2 level-ups, and heals you fully. That is 480 gem value: 168 XP and about 58 gems at `gem_rate` 1.

**The Heart** (`RUN.heart_dist` = 190 m from the start, in a random direction, radius `RUN.heart_r` = 5 cubes) takes no damage while a boss is left. Hitting it shows how many remain.

- Once open, the first hit wakes it: a horde at once, then one every 12 s, each a single ring.
- Each hit does at most `RUN.heart_hit` = 25 to a Heart cube, and a Frenzy doesn't help, so nothing skips the fight.
- **The run ends when the first Heart cube breaks**, not the whole Heart. A cube has 6,000 health, varied per cube by 0.75 to 1.25, so 180 to 300 capped hits on the same cube.

**Finding it.** Nothing on screen points at it.
- It beats within `RUN.heart_hear` = 120 m, faster and louder as you get closer, 2 s down to 0.55 s apart.
- `RUN.vein_arms` = 7 pink veins run out from it, `RUN.vein_len` = 130 m long, `RUN.vein_r` = 3 cubes thick at the Heart and thinning to nothing, so a thick vein means you are close.

## 10. Combo and Frenzy
- Each broken cube or kill adds 1 to the combo. It resets after `Defs.COMBO_WINDOW` = 1.2 s with neither.
- Score multiplier: `1 + min(combo, 300) / 60`, up to 6x, doubled in a Frenzy.
- **Frenzy** starts when the combo reaches `FRENZY.at` = 800 above where the last Frenzy ended. For `FRENZY.time` = 5 s every cube breaks in one hit, except the Heart and bedrock. Then at least `FRENZY.rest` = 15 s until the next.
- Score is shown on the HUD and affects nothing else.

## 11. Mine features
Each of these is built when the mine is generated, in `Mine.generate()`.

**Chain reactions.** A cube with the `chain` flag that breaks also breaks touching cubes of the same kind, in all 8 directions. The delay is `WORLD.chain_delay` = 0.028 s per link, or `RUN.seam_burn` = 0.05 s for fuel. Chains apply to crystal, gas rock, geodes, fuel and loose rock.

**Crystal.** `WORLD.crystals` = 350 blobs. Fragile, chain-reacting, and each cube drops a small gem.

**Geodes.** `RUN.geodes` = 120 hard shells that sparkle through the fog. Each cube drops a gem worth `4 * (1 + RUN.geode_band * band)`, with `RUN.geode_band` = 0.3, and one break sets off the whole shell.

**Vaults.** `RUN.vaults` = 40 walled boxes full of gold, or ruby from band 4. Walls have 130 health.

**Shrines.** `RUN.shrines` = 14 open rooms. Walking up offers a choice, once each.

| Shrine | Effect for this run |
| --- | --- |
| Blood | Lose half your health, gain 2 level-ups |
| Greed | Gems x1.5, enemies hit 30% harder |
| Wind | Speed x1.2, max health x0.75 |

**Relics.** Up to `RUN.relic_rooms` = 2 walled rooms per run, holding relics you haven't found. A relic is kept and saved the moment you touch it, even if you die later.

| Id | Name | Effect |
| --- | --- | --- |
| lens | Strange Lens | Mining Beam unlocked |
| idol | Gold Idol | +10% gems found, for good |
| boots | Worn Boots | +5% move speed, for good |
| charm | Lucky Charm | +25 max health, for good |
| stone | Whetstone | +10% digging damage, for good |

**Lifts.** 16 in all: one at the start and `RUN.lifts` = 15 spread around at 40, 127.5 and 215 m.

**Fuel seams.** `RUN.seams` = 60 crooked orange lines, `RUN.seam_min` = 40 to `RUN.seam_max` = 110 m long.
- Breaking any fuel cube lights the seam, and fire runs along it at 10 m/s.
- Every `RUN.seam_every` = 4 burned cubes, a blast of `RUN.seam_r` = 1.6 m does `RUN.seam_dmg` = 60 to rock and enemies, through fog. It does `RUN.seam_hurt` = 6 to you if you are that close.
- Burning cubes count for your combo, so seams feed Frenzy. A new seam counts for the goal after 1 s with nothing burning.

**Cave-ins.** `RUN.cave_blobs` = 500 small pale, speckled patches of loose rock.
1. Breaking one, by any means, starts a cave-in. One patch makes one cave-in, and up to 4 can run at once.
2. For `RUN.cave_warn` = 0.8 s a dark shadow and falling dust cover `RUN.cave_r` = 5 m.
3. Rubble fills all open ground in that circle, except within `RUN.cave_spare` = 1.4 m of you and around lifts. You always keep a pocket.
4. Enemies inside take `RUN.cave_crush * hardness`, with `RUN.cave_crush` = 400, unless they are in your pocket. That kills anything but a boss.
5. You take `RUN.cave_hurt` = 12 if you are still within 5 m.

Rubble has 6 health and gives no XP. Enemies that dig go through it, so its use is the crush, not blocking them.

**Spike plates.** `THREATS.spike_patches` = 80 patches on a 1 m grid, often buried until you open the floor. Each patch shares a cycle of `THREATS.spike_cycle` = 2.6 s: spikes are up for `THREATS.spike_up` = 0.9 s after a `THREATS.spike_warn` = 0.5 s warning, and do `THREATS.spike_dmg` = 8. Enemies are not hurt.

**Gas rock.** `THREATS.gas_blobs` = 150 small blobs. Blows `THREATS.gas_fuse` = 0.9 s after breaking, radius `THREATS.gas_radius` = 3 m, clearing all rock through fog. It does `THREATS.gas_dmg` = 18 to you and `THREATS.gas_hurts_enemies` = 150 to enemies. One fuse covers a pocket within `THREATS.gas_merge` = 3 m.

## 12. The world
- 960 by 960 cubes of 0.5 m, so 480 m across (`Mine.SIZE`, `Mine.CELL`), one layer, with the start in the centre and a bedrock border.
- "Depth" is **straight-line distance from the start**, not height. The HUD's metres, bands and scaling all use it.
- Rock changes in bands `WORLD.band_width` = 33 m wide, with edges bent by up to `WORLD.band_warp` = 12 m for the rock you see. Enemy scaling uses the straight band, without the bend. Past 198 m stays band 6.
- Caves are noise above `WORLD.cave_at` = 0.5, ore is noise above `WORLD.ore_at` = 0.52.
- Each cube's health is varied by 0.75 to 1.25, so a swing doesn't break a flat front all at once.
- Generation runs in steps with short pauses so the loading screen moves. Chunks are built only when you come near (`WORLD.draw_chunks` = 3).

| Band | Name | From (m) | Rock | Ore |
| --- | --- | --- | --- | --- |
| 0 | TOPSOIL | 0 | Dirt, Clay | Copper |
| 1 | SANDSTONE | 33 | Clay, Sandstone | Copper |
| 2 | GRAVEL BEDS | 66 | Sandstone, Gravel | Silver |
| 3 | STONE | 99 | Gravel, Stone | Silver |
| 4 | SLATE | 132 | Stone, Slate | Gold |
| 5 | BASALT | 165 | Slate, Basalt | Ruby |
| 6 | MAGMA ROCK | 198 | Basalt, Magma Rock | Ruby |

| # | Cube | HP | XP | Score | Gem value | Flags |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Dirt | 10 | 0.01 | 1 |  |  |
| 2 | Clay | 15 | 0.012 | 1 |  |  |
| 3 | Sandstone | 22 | 0.015 | 2 |  |  |
| 4 | Gravel | 28 | 0.02 | 2 |  |  |
| 5 | Stone | 40 | 0.025 | 3 |  |  |
| 6 | Slate | 55 | 0.03 | 4 |  |  |
| 7 | Basalt | 80 | 0.04 | 6 |  |  |
| 8 | Magma Rock | 110 | 0.05 | 8 |  |  |
| 9 | Copper | 18 | 0 | 10 | 1 |  |
| 10 | Silver | 40 | 0 | 20 | 2 |  |
| 11 | Gold | 60 | 0 | 40 | 4 |  |
| 12 | Ruby | 90 | 0 | 70 | 7 |  |
| 13 | Crystal | 12 | 0 | 15 | 0.15 | chain |
| 14 | Bedrock | unbreakable | 0 | 0 |  |  |
| 15 | Gas Rock | 8 | 0.01 | 5 |  | chain, gas |
| 16 | Heart | 6000 | 0 | 2000 |  | heart |
| 17 | Geode | 150 | 0 | 60 | 4 | chain, geode |
| 18 | Vault Wall | 130 | 0.02 | 5 |  |  |
| 19 | Fuel | 20 | 0.01 | 5 |  | chain, fuel |
| 20 | Heart Vein | 35 | 0.03 | 8 |  |  |
| 21 | Loose Rock | 6 | 0 | 2 |  | chain, loose |
| 22 | Rubble | 6 | 0 | 1 |  |  |

**Fog of war** (on by default, switch in menus). Open ground you have seen or broken is known for good.
- Sight runs rays along open ground to `WORLD.light` = 10 m and stops at rock.
- The fog thickens in rings from what is known, by `WORLD.fog_bands`, each `WORLD.fog_band` = 1.3 cubes wide.
- Tools can dig `WORLD.fog_reach` = 7 cubes into the fog, unless section 6 says they go through it.
- Treasure sparkles through fog and rock within `RUN.glint_range` = 20 m.
- Awake enemies in the dark show only their eyes.

**Map** (`Defs.MAP`, `scripts/game/mine_map.gd`, `scripts/ui/map_view.gd`). With fog on, it shows open ground you have opened or seen, and rock up to `MAP.wall` = 2 cubes from it. With fog off it shows the whole mine. Lifts show once seen, the current boss always, and your digger as an arrow.
- **Minimap:** bottom right, `MAP.mini_size` = 200 px wide, `MAP.mini_range` = 36 m each way, always solid.
- **Full map:** the `map` action (M, Tab, gamepad Back). A tap under `MAP.hold` = 0.3 s keeps it open until the next tap; holding shows it until you let go. It is drawn over the game, centred so the digger on the map sits on the digger on screen, at `MAP.zooms` = 1, 2, 4 or 8 px per cube, starting at 4. The game under it is darkened by `MAP.shade` = 0.5 times its opacity. Any pause or level-up closes it.
- **Opacity:** `Options.map_opacity`, saved in `user://options.cfg`, steps through `MAP.opacities` = 35, 50, 65, 80 and 100%, starting at 65%.
- **Cost:** the mine is cut into 900 tiles of 32 by 32 cubes, one texture each. A changed cell marks its tile, and marked tiles are redrawn nearest first within `MAP.budget` = 0.6 ms a frame, each at most every `MAP.every` = 0.1 s. One tile takes about 0.4 ms. With fog off the whole mine is drawn this way, nearest first, which takes several seconds.

## 13. Between runs
The main menu's How to play page (`scripts/ui/help.gd`) explains this to players in plain words. Its numbers are read from `Defs`, but its sentences are written by hand, so update them when a rule they describe changes.

Saved in `user://profile.cfg`: gems, shop levels, unlocks, finished goals, relics and lifetime stats. On Windows that is `%APPDATA%/Dig`. The menu has a Reset progress button.

| Id | Name | Per level | Max | Prices |
| --- | --- | --- | --- | --- |
| power | Sharper Edge | +6% digging damage | 5 | 240, 480, 960, 1920, 3840 |
| health | Hard Hat | +15 max health | 5 | 200, 400, 800, 1600, 3200 |
| legs | Good Boots | +3% move speed | 5 | 200, 400, 800, 1600, 3200 |
| magnet | Long Reach | +12% pickup range | 5 | 150, 300, 600, 1200, 2400 |
| greed | Deep Pockets | +8% gems found | 5 | 300, 600, 1200, 2400, 4800 |
| cover | Insurance | +6% gems kept if you don't get out | 5 | 260, 520, 1040, 2080, 4160 |
| slots | Tool Belt | +1 tool slot and +1 boost slot | 2 | 500, 1500 |

Every price doubles per level, except the Tool Belt, which triples. The whole shop costs 43,850 gems. The owner's rule is to keep it reachable in hours, not days.

| Id | Goal | Stat | Need | Reward |
| --- | --- | --- | --- | --- |
| lift | Get out by lift | lifts | 1 | Bombs |
| geodes | Open 5 geodes | geodes | 5 | 100 gems |
| stone | Reach the Stone layer | band | 3 | Prospector |
| frenzies | Set off 3 Frenzies | frenzies | 3 | 150 gems |
| cubes | Break 25,000 cubes | cubes | 25000 | Shock Pulse |
| kills | Kill 3,000 enemies | kills | 3000 | 200 gems |
| boss | Kill a boss | bosses | 1 | Spark Coil |
| seams | Burn 5 fuel seams | seams | 5 | Mole Pack |
| banked | Bank 3,000 gems in total | banked | 3000 | Rig |
| basalt | Reach the Basalt layer | band | 5 | 300 gems |
| combo | Reach a x3,000 combo | combo | 3000 | 300 gems |
| relics | Find 3 relics | relics | 3 | 400 gems |
| evolve | Evolve a tool | evolutions | 1 | 300 gems |
| crushed | Crush 50 enemies in cave-ins | crushed | 50 | 250 gems |
| bosses | Kill 5 bosses | bosses | 5 | 800 gems |
| heart | Break the Heart | hearts | 1 | 1000 gems |

Beam has no goal: it comes from the Strange Lens relic. Stats add up across runs, except `band` and `combo`, which keep the best run. The `banked` stat counts gems kept from runs, including the Heart bonus, but not goal payouts.

**The objectives panel** (`Defs.OBJECTIVES`, built in `Hud._build_goals`). During a run the top left, under the tool and boost boxes, lists the `OBJECTIVES.shown` = 3 unfinished goals nearest to done: the goal's text, `count / need` (or DONE), and a thin bar.
- **What it counts:** the stat as it stands before the run plus this run so far (`Run.live_stats`, then `Profile.goal_total`), so `kills`, `cubes`, `geodes`, `bosses` and the like add up and `band` and `combo` take the larger. `banked` counts **all** the gems you carry, as if you got out now: dying would keep only `RUN.death_keep` of them. `lifts` and `hearts` stay 0 until the run ends that way. The banner that announces a goal during the run is stricter: it uses the death share (`Run._announce_goals`).
- **Which goals:** most of the goal met first, goals already finished (`Profile.done`) left out, ties in the order of `Defs.GOALS` (`Profile.closest_goals`, which the results screen uses too). A goal this run has already met reads DONE and keeps its row until the run ends, when it is paid. With every goal finished there is no panel.
- **When:** redrawn every `OBJECTIVES.every` = 0.25 s of run time. Hidden while the full map is open.

## 14. Where to change what

| To change | Edit |
| --- | --- |
| Levelling speed | `Defs.xp_to_next`, `RUN.gem_xp`, cube `xp` |
| Gems earned per run | `RUN.gem_bank`, `RUN.death_keep`, `RUN.heart_bonus` |
| Shop and goal pace | `Defs.SHOP`, `Defs.GOALS` |
| The objectives panel | `Defs.OBJECTIVES`: how many goals, how often it redraws, its width and backing |
| Enemy toughness | `THREATS.hard_power`, `tough_per`, `hp_band` |
| Enemy numbers | `THREATS.crowd_per`, the `swarm_*` and `horde_*` values |
| How far off enemies arrive | `THREATS.spawn_margin`, `spawn_depth` |
| Early game pressure | `THREATS.free_upgrades`, `swarm_from`, `horde_from` |
| Run length | `Defs.BOSSES` `at`, `RUN.boss_gap`, boss `hp`, `RUN.heart_hit` |
| Map size or the walk | `RUN.heart_dist`, `WORLD.band_width`. `Mine.SIZE` must be a multiple of `Mine.CHUNK` |
| Feature density | `RUN.seams`, `RUN.cave_blobs`, `RUN.geodes`, `THREATS.nests`, `THREATS.spike_patches`, `THREATS.gas_blobs` |
| Map look and reach | `Defs.MAP` |
| Upgrade slots | `Defs.SLOTS`, the Tool Belt in `Defs.SHOP` |
| Aim feel and marker | `Defs.AIM`, `CAMERA.aim_lean` |
| New tool | `Defs.TOOLS`, plus its firing in `scripts/game/tools.gd` |
| The dash and its clone | `Defs.DASH`: base dash, each mod, the clone and its blast. The code is in `scripts/game/dash.gd` |
| New enemy | `Defs.ENEMIES`, `Defs.ENEMY_ORDER`, plus a mesh and constant in `scripts/game/enemies.gd` |

**Numbers still in code, not in `defs.gd`:** level blast damage of 60 (`Run.level_blast`), the combo curve (`Run.combo_mult`), shrine effects (`Run.take_shrine`), burrower timing (`Run._update_burrowers`), saw, mole and spark counts (`scripts/game/tools.gd`), enemy limits (`scripts/game/enemies.gd`), and the 1,500 gems on the floor (`Pickups.MAX`).

## 15. Measured results and quirks
**Measured, 2026-11-02, by bots, not people.** Bots play at double speed and play worse than a person, so treat these as rough.
- Six bot runs: a bot that can't die broke the Heart at 9:26, level 18. Fresh bots died at 2:13 and 3:45.
- A fully upgraded Prospector died to the Brood at 7:14.
- Bots cross the map in about 90 s, so the bosses set the run length, not the walk.

**From the owner's test.** One run ended in death at level 16, 165 m out, with 3,172 kills, one boss killed and 505 gems carried.

**Unproven.** How the game feels, the sounds, real difficulty, and shop pace. Gamepad play is tested only with simulated input.

**Quirks to know before tuning.** These follow from the rules above. None of them is decided as right or wrong.
1. **Cave-ins hit bosses hard.** The crush is 400 × `hardness` and boss health is base × `hardness`, so one cave-in takes 44% of the Borer and 25% of the Brood, unless your build grew since it arrived.
2. **Fixed damage fades.** The level blast (60), seam fire (60) and gas (150) don't scale, so they matter less as `hardness` grows.
3. **Every upgrade feeds scaling.** A Light Boots pick raises `crowd` and `harm` as much as a damage pick does, without adding damage.
4. **Awake enemies keep their spawn stats.** A big upgrade only affects enemies that spawn or wake after it.
5. **Death after a goal still pays it.** Goal gems are paid in full on any ending, which softens death for a new player.
6. **"Kill 5 bosses" takes at least 3 runs,** as a run has only 2 bosses.
7. **A run may end with the Heart mostly whole,** since one cube breaking ends it. Tools that hit one spot quickly do this fastest.
8. **Boss health is set on arrival.** Upgrades taken during the fight don't make that boss tougher.

## 16. Testing
`CLAUDE.md` has the full commands. Rule checks are in `tests/dig_check.gd`. Bots play with `--autotest`, with options listed at the top of `scripts/main.gd`, and they never touch the save.
