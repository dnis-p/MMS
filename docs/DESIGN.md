# Design vision and idea backlog

Living document. The owner's words and decisions come first; Claude's suggestions are marked
**(suggested)** and are only ideas until the owner says yes. Anything marked **Decided** should not be
changed without asking. Add new ideas at the bottom of the right section, with the date if useful.

## 1. Vision (owner)
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
| Camera | 3D scene with a tilted top-down camera (about 50-65 degrees). Can still be changed to isometric by moving the camera. |
| Engine / language | Godot 4.7, GDScript. Compatibility renderer for phones and web. |
| Orientation | Landscape (works on phone and PC). Portrait was mentioned as a possibility, not chosen. |
| Chest | Not a slot machine. A tachometer ("Redline"): needle lands on green = 1, orange = 3, red = 5 rewards. Owner asked for a different twist. Open to a better idea. |
| Prototype scope | 1 stage loop, 3 classes, 6 weapons, 6 passives, 6 evolutions, 4 biomes, ring boss. |
| Leaderboard | Local top-10 only for now. |
| Distribution | APK from GitHub Actions, web via GitHub Pages (needs public repo), itch.io possible later. |

## 5. Future features (owner's direction)
- More classes, themes/biomes and enemy types; bosses per biome.
- Path that is not perfectly straight in the finished product (curves exist already; more variety later).
- Online **leaderboards and rankings** to drive competition.
- Possible **PC version** as a full-scale game; keep input, UI and services platform-independent.
- (owner, 2026-10-30) **PC is now the priority.** The owner mainly tests on PC; phone stays a target but comes after it.
- (owner, 2026-10-30) Future PC direction: get rid of the fixed path and let the player **move freely**.
  Talk only, not to be implemented now. Keep movement/camera code separable from the road so this stays possible.
  Owner's answers on how it would work:
  - Movement: **8 directions, changed instantly** when the buttons are pressed, no turning animation, like Vampire Survivors.
  - Progress to the boss: either by **enemies killed**, or the boss **appears at a random moment in a time window**
    (for example between 90 and 150 s, the screen changes and says "[boss name] incoming").
  - Phone: same game as PC for now, using a virtual controller to move, as Vampire Survivors does.
  - (suggested) Free movement would also solve the far-gem problem (item deferred in section 9).

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
- Balance the different classes. Juggernaut is too op for example. Interceptor is the weakest of all, speaking in terms of playability. So choosing juggernaut always has an advantage right now.
- Enemies should scale in difficulty with the player's level.
- Also regarding gems, when you kill enemies outside of the road if they are far away its impossible to get their gems, you can't get as close as needed, we should fix that somehow.

**Owner answers, 2026-10-30**
- Enemy scaling: when the player gets faster/stronger, enemies must scale too, otherwise you outrun or melt them.
  Enemy speed is done (section 8); scaling enemy strength with player level is still open.
- Far gems: **deferred**, leave as is for now.
- Order: difficulty scaling next, then class balance.

**Future, not to be implemented yet (owner, 2026-10-30)**
- Free movement replacing the fixed path: 8 directions with instant turning, boss triggered by kills or a random
  time window, phone uses a virtual controller. Details in section 5.
