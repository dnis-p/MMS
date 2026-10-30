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
| Movement | (owner, 2026-10-30) Free driving on walled open maps with smooth, tight steering ("flowy", no drift): the car follows its front wheels like a real car. Replaces instant 8-direction turning. Touch uses an analog virtual stick. |
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
**2026-10-30, third batch** (checked by automated tests and bots; the owner has not played these yet)
- **MG firing at far enemies** (owner saw this). There was no bug in choosing the target: it was always the closest at
  the moment of firing. The bullets just missed it, for two reasons, and flew on to enemies behind. (1) They aimed where
  the enemy was, not where it was going, and extra barrels fanned outward. With a moving car and no kickback in the test,
  high-level MG hit 56-75% of the time. Now it leads the target and all barrels converge: 90%, and all 3 barrels on target
  in game_check. (2) The kickback added last batch pushed the closest enemy out of reach at high fire rates, so MG kick now
  drops as the MG levels up (9 per bullet down to 1.2 evolved), and the kick cap went from 22 to 14. Level 1 stayed about
  the same, around 80-90%. Other weapons do not lead targets except mines, and rockets home in anyway.
- **Closest-enemy firing** (owner). Rockets now take the closest enemy, then the next closest; spare rockets go to the
  closest. Their random launch swerve is much smaller. Mines are thrown at the closest enemy within 18 m, where it will be
  on landing, and only go in a random direction when nothing is in range. This replaces last batch's "any direction".
  Hood MG and Tesla already used the closest. Saw Blades and Shock Plating hit all around you, so no targeting applies.
- **Keyboard menus** (owner). Arrows or WASD move, Space or Enter confirm, on level-ups, the main menu, Garage and all
  panels. The selected button has a gold border. Level-up keeps a 0.35 s delay so a key press can't pick by accident. The
  crate screen now closes only on Space or Enter (any key closed it before; the on-screen text still says "Tap to continue").
  Tested on level-ups with simulated input; the others use the same system but were not tested one by one.
- **Skip to boss** (owner) is in the pause menu in every build again. Runs that use it stay off the leaderboard but still
  earn parts while we are testing.
- **Vehicle speed** (owner). Juggernaut 7 to 10, War Rig 8.2 to 11.5, Interceptor 9.5 to 13. Enemy speed went up less, about
  20%: crawler 5.5, runner 11.5, spitter 10.5, brute 6. Maps are 1.5 times larger with twice the obstacles. The camera sits a
  little higher and looks ahead by 0.35 s of travel. The boss arena uses 72% of vehicle speed, so it plays as before.
- **Smooth steering** (owner, replaces the instant 8-direction decision). Keys still give 8 target directions; the stick is
  fully analog. The car takes 0.25 s to reach speed, brakes in 0.15 s, slows up to 20% in hard turns and leans a little.
  The first version spun the car around its centre, which the owner found unrealistic after playing it. **Front-wheel steering**
  (owner, 2026-10-30) replaced that: the front wheels turn toward the input, visibly on the model, and the car follows them. The
  rear axle rolls straight along the car and the nose swings around it. There is no drift or slip any more. Turning radius is the
  class "turn" stat: Juggernaut 4 m, War Rig 3.8 m, Interceptor 3 m. Consequences: a stopped car cannot turn on the spot, there
  is no reverse, and a full U-turn is an arc taking roughly 0.8-1.4 s by calculation (it was about 0.5 s). A car pinned against a
  wall can still rotate, so it can't get stuck. Tuning is in `Defs.DRIVE` and "turn"; feel needs the owner's judgment. Bots with
  this steering, same test as below: past the first boss, Juggernaut 5, War Rig 4, Interceptor 2 of 6, no worse than before.
- **Redline meter** (owner approved, my proposal). A bar at the bottom of the screen fills in about 11 s of driving at 70%+ speed,
  drains when slower, and loses 30% per hit. It raises fire rate by up to 35% and ram damage up to 2.5x. When full, **nitro**
  fires by itself: 2.5 s of 1.4x speed, no damage taken, 4x ram damage, then the meter restarts at 25%. It only fills on the map;
  in the boss arena it stays at its last value and still gives its bonus, with no nitro.
- **Garage** (owner: permanent progress). Parts are earned every run, even failed ones: 1 per 10 kills, 15 per stage reached,
  40 per boss (times its stage). The Garage opens from the main menu and has 8 upgrades (hull, damage, speed, pickup range,
  XP, armor, starting Redline, one revive). Costs rise with level. About 3,250 parts buys everything, which at the rough 70
  parts per run the bots suggest is around 45 runs, or 2-3 hours. That is an estimate, not measured. There is a reset button
  that needs two presses, and a "+500 parts" test button in debug builds. Bots ignore the Garage, so balance checks measure
  the base game. Upgrades have a "class" field ready for class-specific ones, not used yet.
- **Saving.** Progress is in a local profile file handled only by `scripts/autoload/save.gd`, with a version number. It is saved
  after every boss, death and quit. Saves now live in a fixed folder (`%APPDATA%/MMS` on Windows) so renaming the project can't
  lose them; the existing scores were copied there. Progress is per device: per browser on web, and lost on uninstalling on Android.
- Bot results after all of this, 6 seeds per class, 220 s limit at double speed: past the first boss, Juggernaut 3, War Rig 2,
  Interceptor 1. Small sample, and the bot doesn't use speed well. Balance not retuned, on purpose, until the owner has played it.

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

- Leaderboard: multiplayer entries with build, time, score and kills; whether permanent upgrades count is undecided (see section 6).
- Burnout ring and roads as fast lanes: saved for later review (see section 6).

**Future, not to be implemented yet (owner, 2026-10-30)**
- Upgrades specific to each vehicle class, both in runs and in the permanent upgrades between runs.
