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

## 4. Decisions made so far
| Topic | Decision |
|---|---|
| Camera | 3D scene with a tilted top-down camera (about 50-65 degrees). Can still be changed to isometric by moving the camera. |
| Engine / language | Godot 4.7, GDScript. Compatibility renderer for phones and web. |
| Orientation | Landscape (works on phone and PC). Portrait was mentioned as a possibility, not chosen. |
| Chest | Not a slot machine. A tachometer ("Redline"): needle lands on green = 1, orange = 3, red = 5 rewards. Owner asked for a different twist. Open to a better idea. |
| Prototype scope | 1 stage loop, 3 classes, 6 weapons, 5 passives, 6 evolutions, 4 biomes, ring boss. |
| Leaderboard | Local top-10 only for now. |
| Distribution | APK from GitHub Actions, web via GitHub Pages (needs public repo), itch.io possible later. |

## 5. Future features (owner's direction)
- More classes, themes/biomes and enemy types; bosses per biome.
- Path that is not perfectly straight in the finished product (curves exist already; more variety later).
- Online **leaderboards and rankings** to drive competition.
- Possible **PC version** as a full-scale game; keep input, UI and services platform-independent.

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

## 9. ALL IMPROVEMENTS PROPOSED SO FAR by owner (not counting ver 1.0 features)
- Zoom out camera so you have a better view of the enemies that are coming. For enemies that come from behind im not sure if it would be better to have the camera placed a bit more aback or if that would leave too little camera space on the front to see incoming enemies, bu i say this because when enemies come from the back usually u can't see very far.
- Balance the different classes. Juggernaut is too op for example. Interceptor is the weakest of all, speaking in terms of playability. So choosing juggernaut always has an advantage right now.
- Enemies should scale in difficulty with the player's level.
- The pace of the game has to get faster at higher levels. (speed, either through upgrades or just normal game progression, and enemy scaling)
- In boss fights maybe its better if the dash makes the vehicle change direction too instead of always going in the same direction. Also the attack of the balls that come out in a ring from the boss is imposible to dodge unless the opening spawns close to you. If the opening spawn on the other side of the arena then you always get hit by the ring, or at least I haven't been able to dodge it in any way.
- Also regarding gems, when you kill enemies outside of the road if they are far away its impossible to get their gems, you can't get as close as needed, we should fix that somehow.
- The mine upgrade throws mines towards the back but since there's so little space between the vehicle and the camera frame u can't really see if they will explode on an enemy or not. I've thought about making it throw mines in any direction instead of just towards the back. In the future I may change this upgrade to another thing.