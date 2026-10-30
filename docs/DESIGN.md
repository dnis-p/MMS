# Design vision and idea backlog

Living document. The owner's words and decisions come first; Claude's suggestions are marked
**(suggested)** and are only ideas until the owner says yes. Anything marked **Decided** should not be
changed without asking. Add new ideas at the bottom of the right section, with the date if useful.

## 1. Vision (owner)
- (owner, 2026-10-30) Update: PC is the priority, and the fixed path is replaced by open maps with free 8-direction
  driving (see 4, 5 and 8). The two points below about phone-first and auto-driving are the original vision.
- A mobile game first (a test of gameplay with placeholder art), possibly a full-scale PC game later.
  Must be **multiplatform** (Android, web, iOS later, PC).
- Linear progression through levels. You **drive a vehicle through different biomes** and kill hordes of
  monsters or enemies that come to you.
- The vehicle **drives automatically along a predetermined path** (straight in the prototype, curving later)
  because it is a phone game. The player attacks and survives with weapons and abilities.
- **Several classes** so players can replay with different characters. Example: a heavy tank that moves
  slowly but has lots of defense and power.
- **Themes**: starts as pure Mad Max / motorhead, then passes through cyberpunk zones and many other
  themes, each with upgrades.
- **Enemy variety and bosses.** Bosses change the gameplay to an arena (see 3).
- **Each level gets harder.** Leaderboards and rankings add competitiveness.
- Name "MMS / Motorhead Madness Survival" is **provisional**.

## 2. Feel principles (owner)
- **Satisfying, simple, scalable**, like Vampire Survivors: play almost without thinking, anyone can play,
  no deep build theory (not Path of Exile).
- Satisfaction comes from juicy feedback: hits, sounds with slot-machine-like rewards, visual impact.
- Upgrades stay simple; max-level items **combine into evolved versions** (as in Vampire Survivors).
- Keep the prototype free of extra mechanics. No ability buttons: **Decided** (keep it like Vampire Survivors).

## 3. Boss arena (owner)
- Camera fixed to the vehicle; the vehicle constantly circles the boss and attacks.
- All weapons and upgrades keep working. The player can swipe to move to an **outer or inner ring**.
- Dash to dodge along the circle; the player only chooses the direction. **Decided** (built).
- (owner, 2026-10-30) The dash direction becomes the circling direction (built, see section 8).

## 4. Decisions made so far
| Topic | Decision |
|---|---|
| Camera | 3D scene, nearly top-down with a slight tilt (about 18 degrees from vertical), fixed orientation. Can still be changed by moving the camera. |
| Movement | (owner, 2026-10-30) Free driving in 8 directions on walled open maps, instant turning. Touch uses a virtual stick. |
| Maps | (owner, 2026-10-30) Roads optional per map. No big structures that cover the player or enemies; buildings only as map walls. |
| Boss trigger | Random moment 90-150 s into a stage (owner offered this or kills; Claude picked this one, not confirmed yet). |
| Engine / language | Godot 4.7, GDScript. Compatibility renderer for phones and web. |
| Orientation | Landscape (works on phone and PC). Portrait was mentioned as a possibility, not chosen. |
| Chest | Not a slot machine. A tachometer ("Redline"): needle lands on green = 1, orange = 3, red = 5 rewards. Owner asked for a different twist. Open to a better idea. |
| Prototype scope | 1 stage loop, 3 classes, 6 weapons, 6 passives, 6 evolutions, 4 biomes, ring boss. |
| Leaderboard | Local top-10 only for now. |
| Distribution | APK from GitHub Actions, web via GitHub Pages (needs public repo), itch.io possible later. |

## 5. Future features (owner's direction)
- More classes, themes/biomes and enemy types; bosses per biome.
- Online **leaderboards and rankings** to drive competition.
- Possible **PC version** as a full-scale game; keep input, UI and services platform-independent.
- (owner, 2026-10-30) **PC is now the priority.** The owner mainly tests on PC; phone stays a target but comes after it.
- (owner, 2026-10-30) Free movement: **built** on owner's request, see section 8. Owner's answers on how it should work:
  - Movement: **8 directions, changed instantly** when the buttons are pressed, no turning animation, like Vampire Survivors.
  - Progress to the boss: either by **enemies killed**, or the boss **appears at a random moment in a time window**
    (for example between 90 and 150 s, the screen changes and says "[boss name] incoming").
  - Phone: same game as PC for now, using a virtual controller to move, as Vampire Survivors does.
- (owner, 2026-10-30) Idea, not to be implemented yet: **procedural levels**, for levels with walls and so on. Asked whether
  it is viable or too complicated and unnecessary.
  - (suggested) Viable if rule-based: keep hand-set size, theme and wall ring, randomise the inside from reusable
    pieces, with a check that the map stays open. Maps already scatter obstacles this way. Avoid full maze or
    room generation; it adds cost without serving the "play without thinking" goal.

## 6. Ideas backlog (suggested by Claude, not yet approved)
**Player agency (keep it light given the "play without thinking" rule)**
- Throttle/brake as the only extra input: risk vs reward (faster = fewer kills and XP, slower = more danger).
- Short lane-shift swipes for rams and dodging hazards.
- Ram damage that scales with speed.

**Build and vehicle**
- Hardpoints with firing arcs (front, sides, rear, roof). Weapons visibly attach to the vehicle (started).
- Trailers/wagons that carry turrets, shields or drones, so the player grows into a convoy.
- Heat/fuel resource for weapons and nitro.
- Cross-theme part combos that unlock hidden evolutions (for example a wasteland flamethrower with cyberpunk drones).

**Run structure**
- Two progression layers: in-run level-ups plus a garage with permanent upgrades between runs.
- Forks in the road: risky route (elite enemies, better loot) vs safe route.
- Biome rules, not just art: EMP zones switch off electronic weapons, sandstorms cut vision,
  ice makes steering slide, toxic swamp damages when slow.

**Mechanic twist (suggested 2026-10-30)**
- (approved by owner 2026-10-30) Redline meter: keeping speed and avoiding hits fills a tachometer that raises fire rate and ram power. Stopping or
  being hit drops it. At full, an automatic short nitro rams through enemies. No button.
- (saved for later review, owner 2026-10-30) Burnout ring: the car leaves a burning trail; closing a loop around enemies blasts everything inside.
- (saved for later review, owner 2026-10-30) Roads as fast lanes: driving on a road gives a speed bonus, so map layout matters.

**Enemies**
- Boarders that climb on the vehicle until rammed off, chasers from behind, roadblocks, enemy rammer cars,
  flying drones, roadside artillery, swarms that slow the vehicle, environmental kills (explosive barrels,
  collapsing bridges, ramps).

**Class ideas**
- Interceptor (motorbike, fast, dash), War Rig (truck, turrets, trailers), Hover/Cyber (shields, energy weapons),
  Hearse/Necro (dead enemies become allies), Engineer buggy (drones, repairs, mines).
- Built so far: Juggernaut, Interceptor, War Rig.

**Boss arena**
- Two or three rings (built). Attack patterns designed around the circle (built: radial bursts with a gap,
  ring slam, sweeping beam, summons). More boss patterns per biome, environmental hazards on the ring
  that damage the boss when the player dashes through them.

**Competition**
- Daily/weekly seeded runs with a fixed loadout and level, so rankings are fair.
- Separate leaderboards per class plus an endless mode.
- Score rewards skill: time, damage taken, combo, not just kills.
- Anti-cheat: store seed and inputs so suspicious runs can be replayed and checked.
- Ghost runs of friends or the player just above you.
- Rankings must not depend on permanent upgrades or money, or they stop being fair.
- (owner, 2026-10-30) For multiplayer versions, a leaderboard entry should also show the player's **build, time, score and kills**.
- (owner, 2026-10-30) Not decided if permanent upgrades count on leaderboards. Owner's view: everyone can earn them by playing,
  so it is not really unfair. They must not take too long: no 80-hour grind for the best upgrade.

**PC / later**
- Manual aim (twin-stick), local co-op where a second player controls the roof turret.
- Business model open: mobile free-to-play with ads/purchases (Unity has the strongest ad support, but Godot
  was chosen for this prototype) vs premium on Steam. Decide after the prototype is playtested.
- Platform services behind one interface (Google Play Games, Game Center, Steamworks).

## 7. Open questions
- Is portrait or landscape better for phones? Test on a real device.
- Are the pacing, difficulty and touch controls right? Not yet tested on a phone.
- Final name, art direction and sound direction.
- Which of the section 6 ideas does the owner want first?

## 8. ALL IMPROVEMENTS IMPLEMENTED SO FAR (since v1.0)
**2026-10-30, second batch** (bot and automated checks only; the owner has not played these yet, so feel is unconfirmed)
- **Enemy kickback** (owner: so they don't swarm you this easily). Every attack except burn pools now pushes enemies
  away and they walk at 35% speed until the push fades. One MG bullet moves a crawler about 2 m. Pushes stack up to a
  cap. Brutes take 25%, runners 80%, the boss none. Tesla had no push before and has one now. Numbers are in `Defs.KNOCK`
  and per weapon. map_check confirms the push.
- **Purple enemies (spitters) can be caught** (owner: slightly slower than the player). They used to match 95% of the
  car's speed; now 60%, and they back off more slowly. At the slowest speed (7) a car closed from 9 m to contact range
  in under 6 s in map_check.
- **Open world** (owner: replaces the fixed path). Each biome is a walled rectangular map, 300-360 m across. The road
  system is gone. **Wastes** has one winding road, **Neon** a street grid, **Frost** and **Toxic** none; roads are
  decoration only. Inside there are only small obstacles (rocks, wrecks, crates, posts, ice spikes, stumps), about 2.5 m
  tall at most and at least 12 m apart, plus flat ground decor. Buildings and cliffs exist only as the outer walls. The
  south wall is 1.4 m tall because the camera looks over it; a tall one would hide the car. Solid obstacles stop the car
  and enemies; bullets and rockets pass over. Enemies are checked against obstacles every other frame to stay cheap. All
  maps use random placement each stage.
- **8-direction driving** (owner: instant, no turning animation, like VS). WASD or arrows; on touch or mouse drag, a
  floating virtual stick appears where you press and snaps to 8 directions. Diagonals keep the same speed. **The car stops
  with no input** (my reading of "like Vampire Survivors"; easy to change if you want it to keep rolling).
  The joystick was tested with simulated input, not on a phone.
- **Boss trigger** (owner offered kills or a random time window). Chosen: the random window, 90-150 s, because kills would
  reward strong builds with less time to level. A banner says "[BOSS NAME] INCOMING". The HUD now shows elapsed time, no
  countdown. The ring arena itself is unchanged except the ring sizes below.
- **Camera for open world.** Fixed orientation, 9 m south and 28 m up, almost centred on the car. This replaces the
  road camera from the first batch. Boss camera unchanged.
- **Enemy scaling with player level** (owner). Per level above 1: +3% enemy HP, +1.2% enemy damage, +1.5% spawn pressure,
  on top of stage scaling. Applies to enemies spawned after the level-up; the boss HP uses the level at the moment it
  appears. Enemy speed already follows the car from the first batch.
- **Spawning changed** (not requested, needed for open world). The old rates relied on driving past enemies; in the open
  every bot was swamped with 200-350 enemies by 80 s. Now the game holds a target number of living enemies, 15 + 0.35 per
  second, times stage and level factors, as VS does. Hordes come on top. Spawns are just off screen, 65% in your direction
  of travel. Enemies left 80 m behind reappear just off screen.
- **Other changes the open world needed.** Crawlers 3.4 to 4.6 speed so they can reach you. Runners 11.5 to 9.5 so you can
  outrun them in the fastest class. Pickup radius 3.8 to 6. Hit recovery 0.45 to 0.6 s. Enemy contact damage about 20%
  lower. Repair drop chance 1.2% to 2%. Boss HP 4500 to 3000, since it can now appear at 90 s. Hordes 36 to 20 enemies.
  Elites at 40 and 80 s, hordes at 30, 60, 85 and 115 s. Rings are now 5.8 / 10 / 14 m (were 7 / 10.5 / 14) because saws
  could not reach the boss from any ring.
- **Far gems** (was deferred). Fixed as a side effect: you can drive to any gem, and gems and crates no longer disappear
  with distance.
- **Class balance** (owner: Juggernaut too strong, Interceptor weakest). Juggernaut: 150 HP, speed 7, ram 35, might 1.05
  (was 165, 6.5, 45, 1.15). Interceptor: 110 HP, armor 1, ram 20, might 1.05 (was 95, 0, 14, 1.0). War Rig: 130 HP, speed
  8.2, might 1.05 (was 125, 7.8, 1.0). Saw Blades stronger: damage 9 to 13, faster hits, wider orbit.
  Measured with a bot on 6 seeds per class, 220 s limit at double speed: runs that got past the first boss were
  Interceptor 2, Juggernaut 2, War Rig 1, and no class stood out. **Small sample with a simple bot, so it only shows
  no class is far ahead for that bot.** It needs your playtest; a human plays melee and kiting differently.
**2026-10-30** (bot and automated checks only; the owner has not played these yet, so feel is unconfirmed)
- **Camera zoom-out** (owner: see more, especially behind). Road camera moved from 9 m back / 16.5 m up / 6.5 m
  look-ahead to 13 / 24 / 3. About 11 m of ground is visible behind the car (was about 5) and about 35 m ahead (was
  about 45), so the view ahead is slightly shorter. Field of view unchanged. Boss arena camera not changed.
  Added so enemies don't appear on screen: crawlers spawn 40-50 m ahead (was 26-36), side runners 30-34 m (was
  17-22), spitters 28-32 m out (was 15-20), elites 42 m ahead (was 30), hordes 26 m around (was 17). Enemies
  take a little longer to arrive. Checked with one gameplay screenshot at 1280x720, not on a phone.
- **Mine direction** (owner: throw in any direction). Mines are now thrown at a random angle, 5-12 m from the car,
  flying 0.4 s in an arc and arming on landing (same 0.4 s arming as before). In the boss arena they land on the
  floor. Random, not aimed at enemies. Mines thrown backward can still end up off screen as the car drives on.
  Renamed nothing; the description now says "Throws mines all around you."
- **Boss dash direction** (owner: swipe right = dodge and keep driving right). The dash sets the circling direction
  and it stays that way until the next dash, on both swipes and keyboard. The car turns instantly. The sweeping
  beam now always starts against the car's current direction.
- **Unavoidable ring burst** (owner: far gap impossible). Confirmed: a far gap could not be reached. Now the first gap
  of an attack is placed within what the car can reach before the shots arrive, on either side, and each later
  gap in that attack moves at most 0.3 rad from the last. Shot speed, count and gap size are unchanged. Tested with a
  driving bot (no dash invulnerability): 0 of 36 bursts hit it, 36 of 36 hit a bot that doesn't steer.
  Limitation: the gap no longer appears anywhere on the ring, only near you, so dodging may feel easier.
- **Faster pace at higher levels** (owner: speed and enemy scaling together, so you can't outrun them). New passive
  **Nitro Injector**, +6% vehicle speed per level (up to +30%); it has no evolution. Each stage adds +6% speed. Enemies
  always get the same speed factor, so the speed difference between car and enemies stays the same in proportion.
  Differs from the proposal: pace rises with stage and upgrades, not with player level, and enemy strength is not
  part of this (that is item "Enemies should scale" in section 9). Boss shots do not get faster, so bursts get easier
  to reach at high speed. Road length now adapts to the fastest possible speed.
- **(suggested) Score save.** The score is now saved when you quit from the pause or stage-clear menu, once per run.
  Bot runs (--autotest) no longer write to the leaderboard.
- **(suggested) Skip to boss** now shows only in debug builds, such as Play in the editor. It will be missing from
  release exports, which is what CI builds. Not checked in an actual release build.
- **(suggested) Dash buffering.** A swipe during the 0.5 s cooldown is remembered and used when it ends; the latest
  swipe wins.
- **(suggested) Balance numbers moved to defs.gd.** Weapon levels, boss attacks, spawn director, arena and camera
  numbers are now data. No gameplay change intended; weapon stats were copied value by value.
- **(suggested) Armor is now a percentage.** Each armor point blocks 6% of a hit, capped at 60%, minimum 1 damage.
  Was a flat reduction. Juggernaut starts at 12%, or 42% with full Armor Plating. Armor Plating text changed to match.
- **(suggested) Seeded randomness.** All gameplay rolls use one generator and `--seed=<n>` sets it (bot/command line
  only, no daily mode yet). Two 20 s runs with the same seed and `--fixed-fps 60` gave identical results. At normal
  frame rates runs will not replay exactly, because timing varies; replays would need more work.
- **Bug found and fixed (not requested).** Bullets knocked enemies slightly upward and the crowd-spacing code amplified
  it until positions became infinite, causing thousands of engine errors in an Interceptor bot run. Enemies are now kept
  on the ground, and all three classes ran with 0 errors. It may have made enemies invisible or weapons miss in
  MG builds, which could be part of why Interceptor felt weak; not confirmed.
- Bot results under normal rules after all of the above: Juggernaut clears the first boss; Interceptor and War Rig die
  in that boss fight. The bot never dashes or switches rings, so this is not a measure of real balance.

## 9. ALL IMPROVEMENTS PROPOSED SO FAR by owner (not counting ver 1.0 features)
- Procedural levels: idea only, not to be implemented yet (see section 5).

**Owner requests, 2026-10-30 (approved, in progress)**
- Permanent progress between runs: points earned in runs, spent on upgrades outside runs, to help get past runs you are stuck on.
- Every upgrade should fire at the closest enemy.
- Pick upgrades with the keyboard: move keys to select, Space or Enter to confirm.
- Skip to boss in the menu again, also in normal builds.
- More starting vehicle speed; gameplay should be fast paced. Check how that affects swarming.
- Less snappy turning: more than 8 directions or smoother transitions, "flowy" like a normal car game, but with good
  control and not too much drifting.
- A gameplay/mechanic twist so it is more addictive and not just a copy of VS.

**Future, not to be implemented yet (owner, 2026-10-30)**
- Upgrades specific to each vehicle class, both in runs and in the permanent upgrades between runs.
