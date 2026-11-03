# Design vision and idea backlog

Living document. The owner's words and decisions come first; Claude's suggestions are marked
**(suggested)** and are only ideas until the owner says yes. Anything marked **Decided** should not be
changed without asking. Add new ideas at the bottom of the right section, with the date if useful.

**Branch `prototype/dig` (2026-10-31):** this branch is the digging prototype. The car game lives on, unchanged, on the default
branch `claude/sleepy-davinci-fxgwnn`, so sections 1-5 and the older entries below describe that game, not this one. The digging
entries are the first ones in sections 8 and 9.

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

**Food-chain flip (suggested 2026-10-30, reaction to the owner's monster idea in section 9)**
- Anything smaller than you is eaten by touching it; bigger things hurt you. Auto attacks weaken big ones until they glow, then
  you drive into them to finish. One input stays one input. Today's threat becomes tomorrow's snack as you grow.
- Test the rule in the current project with placeholders before choosing a theme. Raccoon that eats its way up from dumpster to
  city suits the escalation best. Car version: ram wrecks and weld them on.
- Boss length: aim for a target fight time and set boss HP from it, and check level pace first, since level 25 by 90-150 s is one
  level every 4-6 s.

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

**Digging ideas not built yet (suggested 2026-10-31)**
- Rhythm in three beats once enemies are wanted: calm digging, breaking into a nest and getting surrounded, then the reward. Enemies
  live in pockets, so the owner's "surrounded and shredding" phase comes from your own digging.
- A slow threat rising behind you (collapse, lava), so standing still is never safe.
- Runs of about 20 minutes, one descent, with meta progression between runs. Not an open world: it costs saving and streaming and
  loses the VS shape. Buried finds that unlock forever also give the Hades-style mystery.
- Themes: digging down through a landfill into what is buried under it (raccoons love shiny things), or drill rigs for Motorhead.
- Close games to study: Deep Rock Galactic: Survivor (VS plus mining), Dome Keeper (digging plus waves), Motherload, Noita.

**Digging brainstorm (suggested 2026-11-01, asked for by the owner, nothing approved yet; none of it needs a new button)**
- Core idea: the fog is a scratch card. Digging scratches it off, so what is hidden under it should be worth scratching for.
- Run goal: reach the Heart at the outer edge of the map, about 15-20 minutes, with a boss at some band gates. Leaving through a lift keeps all your gems, dying keeps about half.
- Hidden in the rock: geodes (hard shell, a burst of gems, like VS chests), a huge motherlode, vaults, shrines with a trade-off, relics that unlock forever the first time you dig them up. Shapes or sparkles show faintly through the outer rings.
- Frenzy: a long cube combo turns the screen gold and every cube pops in one hit for a few seconds.
- Your tunnels are the level: cave-ins crush enemies behind you, fuel seams burn along their length, and a hunter worm that hears digging arrives late in a run, like the VS Reaper.
- Unlocks: characters are a starting tool plus one rule that changes digging. Tools and boosts join the shared pool when unlocked. Every unlock has a visible goal, as in VS.
- Character ideas: Digger (shovel), Mole (tiny light, feels ore through fog), Rig (no aim, breaks rock by driving into it), Demolisher (bombs, immune to own blasts, gas rock heals), Prospector (double gems, half health), Foreman (a helper bot digs on its own).
- Tool ideas: Acid (spreads through rock), Tesla Pick (jumps along ore), Dynamite Trail (dropped as you walk), Tunnel Worm (a pet that eats a winding tunnel), Echo (pings reveal the fog), Jackhammer (shockwave along walls).
- Evolutions: a maxed tool plus a maxed boost, for example Drill plus Quick Hands becomes a Tunnel Borer that leaves a wide corridor.
- Meta: a short gem shop with no long grind (owner, section 6), a Collection of everything found, a camp that visibly grows, lifts that start you deeper, new mines with their own rules, and a Curse setting that trades danger for gems.
- Themes, in order of Claude's preference: raccoon in a landfill digging down through layers of history (bubble wrap really is trash, tools are junk taped together); gravedigger from cemetery to Hell (fits the lamp and fog, closest to VS); prison escape starting with a spoon (being caught explains every restart); inside a sleeping giant (skin to Heart, gross popping); ant colony (workers fill the tunnels you dig); mole (blindness explains the fog, cute); corporate asteroid mine (disposable staff); dwarves (safe, least original).

## 7. Open questions
- Is portrait or landscape better for phones? Test on a real device.
- Are the pacing, difficulty and touch controls right? Not yet tested on a phone.
- Final name, art direction and sound direction.
- Which of the section 6 ideas does the owner want first?

## 8. ALL IMPROVEMENTS IMPLEMENTED SO FAR (since v1.0)
**2026-11-04, enemies arrive off screen, and a swarm is three waves** (owner: "Id like for all enemies to spawn outside of the camera because right now the player can see they just appear out of nowhere", and "lets try making the swarm last at least 2/3 waves and see if its manageable")
- Before, enemies came in at fixed distances: the swarm 15 m from the digger, horde rings 13 to 16 m, burrowers 18 m, bosses 24 m. The camera shows about 16 m above the digger, 10 m below and 12 m to each side, more toward the corners (at 16:9), so many of them appeared on screen.
- Now the swarm, hordes, burrowers and bosses start 2.5 m past the edge of what the camera shows, plus up to 3 m more (`THREATS.spawn_margin`, `spawn_depth`). The edge comes from where the screen's corners meet the ground, so it follows the real camera and window shape. A horde ring is no longer round but shaped like the screen. Bosses still start at least 24 m away, and when one is pulled back after you outrun it, it lands off screen too. Near the mine's edge, a spot that would be pulled into view is skipped.
- **Not changed:** sleepers in nests are placed when you come within 50 m, mostly far off and in the dark. The Brood's crawlers still come out of the Brood, since you see where they come from.
- **A swarm ("SWARM!") is now 3 rings, 4 s apart** (`THREATS.horde_waves`, `horde_gap`), each as big as a whole horde was, from a new side each time. One banner, and a quieter warning sound for each later ring. Hordes still start every 55 s (less with a strong build). **Differs (suggested):** once the Heart wakes, hordes stay one ring each, since they already come every 12 s and three rings in each would almost never stop.
- Checked in the rule check: no horde ring, swarm burst, burrower or boss starts on screen, a second and third ring follow, then it stops. Bots on 4 seeds against the previous commit on the same seeds: about the same survival (old: three died at t=226-240, one hid near the start; new: three died at t=233-235, one at t=98 after going 139 m deep), and about 30% more kills. A god-mode bot with everything woke the Heart at 12 minutes, with no errors. **Not checked:** how it feels to play, and whether three rings is too much for a person.

**2026-11-03, a Controls page in the main menu and in the game** (owner: "add the tab for the map to the controls explanation and also maybe a controls section both in main menu and in game")
- How to play already listed "Map: M or Tab", but nothing in a run did. Now a **Controls** page opens from the main menu (in the small row with Options and Reset progress, so the page still fits the screen) and from the pause menu. It is a table: action, keyboard and mouse, gamepad, with the map's keys (M or Tab, Back), zoom, aim, pause and menus, and two notes (no attack button; the game follows whichever input you used last).
- One list feeds the Controls pages and the Controls section of How to play, so they can't disagree (`Help.controls()`).
- In the pause menu, Back, Esc or B on the Controls page go back to the pause menu rather than into the game.
- The hint at the start of a run now ends with "M or Tab for the map" ("Back for the map" on a gamepad).
- Checked in the rule check (the pause page shows the table, Esc goes back, the map keys are listed, the menu page fits 598 of 720) and in screenshots of both pages.

**2026-11-03, aiming by angle, with the mouse hidden on a ring** (owner: "theres no point in having a free cursor when the character's attack doesnt depend on range/position of the cursor but on direction/angle"; then "the cursor should be hidden, and lets try the ring system", "having the cursor hidden but locked on that ring path", and Bombs "should switch to automatic and target any enemy within a specific close range ... If no enemies, they should target closest cubes. If no cubes either then i guess it shouldnt throw any bombs")
- During a run the mouse is captured and hidden, so it can't leave the window or click outside it. Menus, level-ups and the pause menu give it back. If the capture is lost while playing (Esc in a browser takes it), the game pauses.
- The mouse moves a hidden pointer kept within 160 pixels of mouse travel around the digger (`Defs.AIM.reach`), and only its angle aims. How the "locked on the ring" idea was built: pushing outward holds the pointer on the edge, so the aim stays steady there, but it is not held on the ring itself: a push across goes through the middle and turns you around in 320 px. **Why:** a pointer held exactly on the ring could only slide around it, so flicking the mouse to the other side of the screen would do nothing. Near the middle the aim still swings, but only while you are crossing over.
- The pointer moves with the digger, so walking no longer turns your aim, as it did when you walked past a free cursor.
- The aim shows as a solid white arrow on a faint ring 2.6 m out. The first arrow was an open chevron, but in a screenshot it looked like the drill's chevrons, so it is a solid triangle. **Also changed (suggested):** the right stick uses the same arrow and ring instead of its crosshair 7 m out.
- The camera leans a fixed 1.5 m the way you aim (`CAMERA.aim_lean`), instead of a share of the distance to the cursor.
- **Bombs aim themselves** within their 8 m throw: at one of the 3 closest awake enemies, picked at random so a crowd gets spread hits. With no enemy, at the nearest rock you can see. With neither, they don't throw and look again after 0.2 s. **Differs (suggested):** rock within 45 degrees of your aim comes first, nearest of those, before closer rock elsewhere, so in a tunnel they blast the way you are going rather than the wall beside you. Before, they were thrown at the cursor, or at random rock 4-8 m away.
- **Fainter marker** (owner: the ring needs "a bit less opacity", the arrow too, and "get rid of the black outline of the arrow, if its posible"): the ring went from 22% to 14% opacity, the arrow from solid to 60%, and the arrow has no outline now, only a soft edge (`AIM.ring_alpha`, `AIM.arrow_alpha`). Without the outline it may be harder to see on pale rock; not tried by the owner yet.
- **Turning speed** (owner, after trying it: "the sensitivity or turning speed of the aiming seems too fast"): the reach went from 120 to 160 pixels, so the same mouse movement turns the aim 25% less. Not tried by the owner yet.
- Checked in the rule check: the pointer stays within its reach, walking doesn't turn it, a push across turns it, the arrow sits on the ring, the camera lean, and the bomb choices. Bots ran with Bombs and with everything, with no errors. **Not checked:** how it feels with a real mouse, and the capture in a browser (it can't be tested without pushing). The old free cursor is gone; the previous commit has it if the ring doesn't feel right.

**2026-11-03, upgrade slots: 4 of each, up to 6** (owner: "the powerups should have a count limit ... after you have all of the slots full you cant get any new ones"; then "new game starts with 4 and as you meta progress you can get up to 6 slots for now", accepting that leaderboards then favour players with more progress)
- A run holds at most 4 different tools and 4 different boosts, the starting tool included (`Defs.SLOTS`). Tools and boosts have separate slots, so every tool slot can still have the boost that evolves it (suggested, built that way). Once a kind is full, cards offer only levels of what you hold, as in Vampire Survivors; evolutions are not affected.
- The meta progression is a new shop row, **Tool Belt** (suggested: the owner didn't say how it unlocks): each of its 2 levels adds one tool slot and one boost slot, so 4+4, then 5+5, then 6+6. Prices are first guesses, 500 and 1,500 gems, meant to be reached in an hour or two (the owner's run that died at level 16 carried 505 gems and kept half).
- You can see it: free slots show as dim empty boxes next to your tool and boost icons at the top left, the level-up screen says "Tools 2/4 · Boosts 1/4" under the cards, and a NEW card for the last free slot says "Last tool slot" or "Last boost slot". How to play explains it.
- At 6 boost slots every boost fits, as there are 6, so a full Tool Belt only limits tools (6 of 8).
- Room is plenty for a run: 4 tools to level 6 and 4 boosts to level 5 are 44 picks plus evolutions. A bot that can't die, with nothing bought, reached level 19 in 10 minutes holding 4 tools; with the Tool Belt full, level 32 holding 6. Level-ups never ran out of cards.
- The shop page now has 7 rows, so its rows use a smaller font to fit the 720 high screen without scrolling.
- `--give` (for bots) ignores the slots, so `--give=all` still tests the late game with everything.

**2026-11-03, the drill shows its reach** (owner: "add a visual effect to the drill that can somewhat show the hitbox or range of it")
- A flat strip lies over the cells the drill bites, turning with you: a faint orange fill and pale chevrons running forward, fading out towards the sides and the tip. While it is hitting, the chevrons run twice as fast and the strip brightens; it fades back in about 0.2 s. The strip is sized to the hit area, checked in the rule check: 3 cubes wide (7 with the Tunnel Borer) and as long as the drill reaches, so it grows with levels and Long Handle.
- At first the chevrons ran forward but pointed back at you, which the owner said looked "like a conveyor belt that leads debris to you"; they now point away, the way they move and the drill bores.
- It also had a pale outline at first. The owner asked to drop it ("i dont want the drill effect to be exactly like its hitbox, i like the effect inside tho"), so the colours now fade out over the outer part of the width and the last third of its length. So the visible strip looks a little shorter and narrower than what the drill really hits.
- The first try in the drill's orange vanished on orange rock and white hit flashes, so the chevrons are pale and fairly opaque (`strip` = 0.75). It is drawn over the fog, as the shovel's swing is. Not yet seen by the owner in play: it may need to be fainter if it clutters.

**2026-11-03, enemies kept dropping gems in strong runs** (owner: with drill, pulse, spark, Quick Hands and Long Handle, at level 26 around 6 to 7 minutes, "the enemies were not dropping gems anymore")
- **Cause.** At most 1,500 gems can lie on the floor. When full, a new gem was added to a random gem anywhere in the mine, so drops vanished from where they fell. Shock Pulse breaks ore and crystal out of sight, which fills the floor: a bot with drill, Shock Pulse and Spark Coil hit 1,500 by 2:00 and stayed there.
- **Fix.** A new gem now always lands where it fell. To make room, the two farthest of 8 random idle gems merge into one worth both. No value is lost, and it costs a few checks per drop instead of raising the cap, which would slow every frame.
- **Effect, one bot, same seed and build, can't die.** At 7:00: before, level 23 and 459 gems carried; after, level 31 and 1,720 gems. So strong builds now earn and level up much faster than before, as their kills pay again. The randomness differs after the change, so this is a rough comparison. Shop prices and `RUN.gem_bank` may need a look once the owner has played it (suggested).
- The bot's status line each minute now also shows `floor=`, the gems on the floor.

**2026-11-03, minimap and full map** (owner: "adding a minimap and also a toggle to open the whole map but make it overlay the game itself. Maybe opacity could be a setting in the options. So you can hold the map button while still playing and moving ... your character in the game also lined up with the character in the map itself ... the minimap will also have the fog of war and will only show parts you already discovered")
- **Minimap.** Bottom right, 200 px, about 36 m each way, centred on you. It shows open ground you have opened or seen in a light colour, the rock at its edge (2 cubes) in its own colour darkened, and nothing else. Lifts appear once seen, the boss always (as on the compass), you as an arrow pointing where you face.
- **Full map.** M or Tab (gamepad Back). Both ways the owner described work: a quick tap keeps it open while you play, and holding it shows it only while held, so you can peek while moving. It is drawn over the game, centred so the arrow sits right on your digger, as the owner described. Zoom with the mouse wheel, + and -, or the shoulder buttons: 1, 2, 4 or 8 px per cube, starting at 4. Pausing or a level-up closes it, because a paused run can't hear the button being let go.
- **Opacity.** A new Options page on the main menu holds the fog switch and Map opacity (35, 50, 65, 80, 100%, starting at 65%), and the pause menu has the same button. It is saved. The game under the full map is darkened a little more the more solid it is (suggested), as it was hard to read over a busy screen in screenshots.
- **Changed to make room (suggested).** The main menu's Fog of war button became Options, which holds it. The bottom hint is narrower and wraps, so it stays clear of the minimap.
- **Fog.** With fog on, the map shows only what you know; with it off, the whole mine. A switch mid-run redraws it.
- **How it is built.** One small texture per 32 by 32 cube chunk, redrawn when something in it changes, nearest first, within 0.6 ms a frame. A chunk takes about 0.4 ms. Checked by rule checks (what shows with and without fog, tap, hold, menus close it, opacity steps) and bot screenshots; the owner hasn't tried it, and it hasn't been checked with a real gamepad.

**2026-11-03, faster web publishing** (owner asked whether the default branch rebuilding every time slows the web build; chose options 1 and 2)
- **Why it rebuilds at all.** GitHub Pages publishes the whole site as one package, the car game at /MMS/ and this game at /MMS/dig/, so a DIG push still needs the default branch's workflow to rebuild and publish everything. Reusing its old build isn't possible without changing how the site is published (a `gh-pages` branch and a Pages setting), which was not chosen.
- **Option 1, default branch.** Its workflow has a `dig_only` input. When this branch starts it with `dig_only=true`, the car game's 31 s smoke test and its APK are skipped; its web build (about 9 s) still runs, as the site needs it. Its own pushes and manual runs still do everything.
- **Option 2, this branch.** The request to republish now goes out as soon as the smoke test and web build pass, before the APK, instead of from a second job after the whole build. If the APK then fails, the site is already updated and the run shows red.
- **Measured.** Push to live was about 3 minutes before. The first push after the change (2026-11-03, 12:33 UTC) was live 2 min 9 s later: the republish skipped the car game's test and APK as planned.
- **Seen once: a deploy that didn't go live.** At 12:15 a republish built and deployed the map, and GitHub reported success, but Pages kept serving the deploy from 12:12, for both games, until the next one. It came right after a full deploy of the same car-game commit; the cause isn't visible without a login. An empty commit pushed to this branch republished it. If it happens again, the workflow could check the live site after deploying (suggested).

**2026-11-03, main menu fits the screen again** (owner: on the web the main menu "cuts at the bottom ... dont add a scroll bar to the main menu")
- **Cause.** The screen is always 720 units tall; a window wider than 16:9 only adds room at the sides. The new How to play button took the main menu to 758, so the last button was cut off, on the web and in the desktop build alike.
- **Fix.** Fog of war and Reset progress now share one row under the other buttons, in the same total width, with slightly smaller text, and the DIG title is 80 instead of 96. The menu now needs 654 of 720, with no scrolling. Checked in a screenshot at your browser's size, 1920x920.
- **Guard.** A new rule check measures every menu page against the screen height (main 654, shop 645, goals and How to play 635), so a page that grows too tall fails the tests.

**2026-11-03, How to play page** (owner: "an explanation on how the game works and what are the main objectives right now ... for testers. I mean only in writing not like a proper tutorial. In game")
- **What it is.** A How to play button on the main menu, under Start digging, opens a scrolling page of short bullet points: the idea, controls, a run, the goal (finding and breaking the Heart), other ways out, enemies and dangers, things worth finding, between runs, and a note for testers asking for feedback. Back, Esc or B returns to the menu; the mouse wheel, arrows or stick scroll it.
- **Keeping it true.** Times and numbers in it (Heart distance, boss times, lift time, gems kept on death, Frenzy, evolutions) are read from `defs.gd`, so balance changes show up by themselves. The sentences are by hand in `scripts/ui/help.gd`, so a changed rule needs its line changed too; `MECHANICS.md` says so. Each line was checked against the code.
- **Not done.** It is not in the pause menu, and nothing points new players to it beyond the button. Checked at 1280x720 in screenshots; the owner has not seen it yet.
- **Small fix found on the way.** Menu pages grab focus a frame late. If the page was swapped before then, the engine logged an error; it now checks the button is still there.

**2026-11-03, all countdowns keep the leftover frame** (owner: "do the same fix for all tools/weapons or systems that depend on that type of counting")
- **Change.** The drill's timer fix is now one shared helper, `Defs.restart`, used by every repeating countdown: all eight tools, both bosses' attacks, enemy spawns (swarms, hordes, burrowers), enemy wake and dig checks, the heartbeat, fog scans, goal checks and the lift ring. Each keeps the part of a frame that went past zero, so it fires equally often at any frame rate.
- **What changes in play.** Fast tools used to lose hits depending on how their cooldown divided into frames. Simulated from the cooldowns, not measured in play: level 1 saws hit about 10% less often at 60 fps and 1% less at 165 fps, moles 6% and 3%. They now hit at their full rate everywhere, so on a 60 fps screen saws and moles are a bit stronger than before. Slow timers (spawns, bosses, a 3 s pulse) lost at most one frame per cycle, under 1%, so they barely change. Enemy toughness follows tool levels, not hits, so it is not affected.
- **Limits.** The carry is at most one frame, so a tool or shovel that waited for something to hit starts a fresh countdown instead of firing at once twice. Nothing fires more than once per frame, so below `1 / cooldown` fps (about 15 fps for the drill) fast tools still slow down. Short visual timers (hit flashes, slash fade, number pop-ups) and one-off timers (combo window, Frenzy, fuses, cave-ins) don't repeat and were left as they are. The bot's and screenshot's own timers were left too, as they are test tools.
- **Checked.** A new rule check runs a 0.065 s countdown at 30, 60, 144, 165 and 240 fps for 10 s: it fires 154 times at each. Before, the same countdown would fire 144 to 150 times.

**2026-11-03, level 1 drill slightly weaker** (owner: "the drill is a bit too OP early game ... let's try making level1 drill just slightly less op"; measured with a scripted dig through plain rock, the owner has not played it)
- **Change.** The drill now hits every 0.065 s at level 1 instead of 0.05 s, and each level makes that 5% shorter, so by level 6 it is back to 0.05 s. Its damage, length and damage per level are unchanged, so enemy toughness, which follows tool damage, is not affected.
- **Timer fix.** The drill's timer used to drop the part of a frame left over when it fired, so it hit less often at some frame rates: at 165 fps about 18 times a second instead of 20. It now keeps that part, so the rate is the same everywhere.
- **Measured** (metres walked in 2 s into plain rock, before > after). Level 1: dirt 13.9 > 13.5, clay 13.4 > 12.9, sandstone 12.3 > 10.7, stone 7.4 > 5.3. Level 2: sandstone 13.1 > 12.6, stone 11.6 > 9.6. From level 3 the difference is 4% or less. A level 1 shovel walks 5.8, 5.8, 4.0 and 2.3.
- **Limit.** In dirt and clay the level 1 drill still breaks rock faster than you walk, so you barely notice the change there. Slowing it in topsoil would need a much bigger cut, for example about a third of today's damage times rate. A version that was also 15% shorter (sandstone 7.9, stone 4.3) was tried and not used, as it is more than "slightly". The Rig, which starts with the drill, is slowed the same way.

**2026-11-03, mechanics reference** (owner: a doc with the technical side of the game, to share with other models)
- `docs/MECHANICS.md` describes how the game works now: rules, formulas, scaling, features, what to edit for a tweak, and what is measured. Its tables were generated from `defs.gd` and its quoted values checked against it. It is kept up by hand, by a rule in `CLAUDE.md`, so `defs.gd` wins if they ever differ.

**2026-11-02, results screen fits** (owner: "the end game screen cuts at the bottom"; rule checks and a 1280x720 window with all 16 goals, the owner has not played it)
- **Cause.** The panel grew with every goal a run finished, and the Dig again and Camp buttons sat below them, so a run with many goals pushed the buttons off screen.
- **Fix.** The title, gems and buttons stay put, and goals and progress bars go in a list between them, which scrolls when it doesn't fit. It follows each goal as it lands, ending on the bars. Mouse wheel, up and down (keys, left stick, d-pad) scroll it by hand. A short list has no scrollbar and looks as it did.

**2026-11-02, gamepad support** (owner: "can you add controller support to the game?"; rule checks and a windowed run fed with simulated gamepad input, no real controller has been tried, and the owner has not played it)
- **Controls.** Left stick or d-pad moves, at full speed in any direction past a small dead zone. Right stick aims, with a target ring 7 m out on the rock (since 2026-11-03 the arrow on the aim ring instead). A confirms, B goes back, Start pauses. Menus and cards move with the left stick or d-pad, one step per push.
- **Aiming without the right stick.** The aim stays 0.6 s after you let go of the stick, then tools point the way you walk, so the game plays with one stick. The Rig, which has no aiming, ignores the right stick as it ignores the mouse.
- **Swapping.** Whichever you used last counts: a gamepad hides the mouse pointer and turns the start hint into stick controls, and moving the mouse more than 3 pixels brings it back. Any gamepad works, in any slot.
- **Also changed for keyboard and mouse:** the move input now has a dead zone, as it had none and a drifting stick would have walked at full speed. Esc and P now resume from the pause menu, as they could only open it before. In the shop the cursor stays on the row you just bought. Up and down scroll the Goals list.
- **(suggested) Added, not asked for:** rumble on any screen shake of 0.1 or more, 0.16 s long, only while using a gamepad. Not felt by anyone yet. Numbers are in `Defs.PAD`.

**2026-11-02, slow upgrade cards fixed** (owner: the cards sometimes took 5-6 seconds to appear; rule checks and bots, the owner has not played it)
- **Cause.** A level-up that came during a hitstop (the short freeze on a big kill or a burst of pops) paused the game before the hitstop could end, so the cards played at 1/20 speed: a 0.3 s fade took 6 s. The same could happen to shrines, the pause menu and the results screen.
- **Fix.** Pausing now always ends the hitstop first, in one place. The rule check fails without the fix and covers all four screens.

**2026-11-02, loading screen, darker enemies, cave-ins** (owner, after testing: levelling feels good so far, more testing to come; rule checks, bots and screenshots, and a short browser start, the owner has not played it)
- **Loading screen.** A bar with the stage it is on ("Packing the rock", "Burying the Heart") while the mine generates. The work now stops for a frame every 120 ms, so the bar moves and the browser tab doesn't look frozen. It started and ran in the browser with no console errors; loading took about 25 s there in a hidden, throttled pane before this interval went up from 40 ms, and the real time in a normal tab is not measured.
- **Darker enemies.** Crawlers, brutes, runners and burrowers have dark bodies, so they are not confused with gems; their red eyes stayed. The gems they drop keep the old bright colours. Hit flashes stay white. Bosses stayed bright, as the owner said most enemies.
- **Cave-ins.** 500 pale patches of cracked loose rock. Break one and the ground in 5 m shakes for 0.8 s under a dark shadow with dust coming down, then rubble drops from above the camera onto all open ground there. It crushes what stands there, and bosses only take a hit. You take 12 if you stayed, but always keep a 1.4 m pocket, so you are never buried. Rubble breaks in a hit or two, gives no XP, and lifts stay clear. A patch is one cave-in, and fire or blasts can set one off too.
- **Differs from the proposal:** 500 patches, not the first guess of 180, because a bot met almost none. Enemies that dig go through rubble quickly, so crushing them is what counts, not blocking them. A new goal pays 250 gems for crushing 50 enemies.

**2026-11-02, 10-minute runs on a much bigger map** (owner: slower progression, runs of about 10 minutes, a much bigger map, soft clues instead of the Heart arrow, a reset button, a boss or two, new tools, dearer meta progression, fuel seams; rule checks, bots and screenshots, the owner has not played it, and the browser version has not been tried)
- **Map.** 960 cubes wide instead of 320 (480 m, nine times the area). Rock bands are 33 m wide instead of 13, the Heart is 190 m out, 15 lifts up to 215 m out. Generating it takes about 1.6 s on the owner's PC. Cube chunks are only built once you come near, nests only fill within 50 m of you and empty again when you leave, and the fog map on the GPU only covers 128 m around you. About 150 fps at 1080p.
- **Slower progression.** Gems give 35% of their worth as XP, the level curve is 24 + 10 per level (20 per level after 15), and a level-up blast is 3.5 m instead of 5.5 m, which ends the chain of blast, ore, level. Bots are at level 3-7 after 2 minutes. The unkillable bot that finished on this curve was level 18 at 8:36. Rare ore is also further away, since the bands are wider.
- **Run length.** Differs from just a bigger map: on its own the map would not last 10 minutes, a bot crosses it in 90 s. **The Heart is sealed until both bosses are dead**, which gives the run its length: boss at 3:30, boss at 7:00 (or 90 s after the first dies), then the Heart. Unkillable bots broke it at 8:36 and 9:37, and two more were only starting on it at about 10:30. Breaking it needs both guardians gone; hitting it before says how many are left.
- **Clues instead of the arrow** (my pick, the owner left it open). No arrow and no distance. Within 120 m you hear the Heart beat and the screen pulses pink, faster and stronger as you get closer, with no direction. Seven pink veins run up to 130 m out from it and get thicker toward it, so a vein tells you which way to go. A hint at 7 s says both. The lift arrow stayed.
- **Reset button.** "Reset progress" on the main menu, with a confirm screen. It deletes the save file (shop, gems, unlocks, goals, relics, totals). The fog setting stays.
- **Bosses.** The Borer stops, marks a red line, then charges 14 m down it through rock. The Brood is slow, throws three gas bombs at you and drops 12 crawlers every 4.5 s. Both tunnel, follow you if you run, and have a health bar and a red arrow. A kill pays 40 big gems, two free level-ups and a full heal. Health follows your strongest tool, not depth. Bots needed 20-100 s for each.
- **New tools, both locked.** Spark Coil (lightning jumps from enemy to enemy, bites rock if there are none, from killing a boss). Mole Pack (little moles chew tunnels around you, through the fog too, from burning 5 seams). Each has an evolution: Storm Coil (with Magnet) and Mole Army (with Thick Skin).
- **Fuel seams.** 60 winding orange lines, 40-110 m long. Break one cube and fire runs along the whole seam at about 10 m/s, opens the rock beside it, kills what stands there, clears the fog along it and hurts you for 6 if you stand beside it. A seam can give 1,000+ cubes of combo in seconds.
- **Prices.** First shop levels cost 150-300 gems instead of 40-80, and gems bank at 12% of their worth. A full run pays about 1,000 gems with the Heart bonus, a run that dies early 30-100. The whole shop costs about 42,000, so about 40 full runs. Bank goal for Rig raised to 3,000.
- **Added, not asked:** you regain 3 health per second after 4 s without being hurt, because level-ups, the old healing, became rarer. Frenzy now takes 800 combo and rests 15 s, as seams would otherwise set it off nonstop.
- Bots, last round (7 runs, 0 script errors): 3 fresh ones died at 1:34-4:06, 2 with the shop maxed reached the Brood and died at about 7:20, 1 unkillable one won at 8:36, and 1 unkillable one left by the start lift at 1:28 by accident. Bots don't dodge, so this says little about how hard it is for a person. Humans did far better than bots on the last build.

**2026-11-01, a first full loop of progression** (owner: build the four points of the brainstorm without a theme, not a whole game, just to test progression and sense of achievement; rule checks, bots and screenshots of every new screen, the owner has not played it, and the browser version has not been tried)
- **Run goal.** The Heart is a blob of bright cubes 66 m out in a random direction. A pink arrow shows the way and the distance, a green one the nearest lift. The first hit wakes it: a horde arrives, then another every 12 s. No hit takes more than 25 off a Heart cube, so bombs and blasts can't skip the fight, and Frenzy doesn't work on it. Breaking it ends the run and pays 500 gems.
- **Differs from the proposal:** I suggested 15-20 minutes with bosses at some layers. Digging is almost as fast as walking, so a bot reaches the Heart in 4-30 s and the map is too small for 15 minutes. The Heart got a lot of health instead (6,000 per cube), which makes the length of a run the fight itself: a fresh bot won at 167 s, others died in the fight at 128-139 s. Bosses at the layers were left out.
- **Lifts.** One next to the start and eight around the mine, hidden by the fog. Stand on one for 1.5 s to leave with everything you carry. They work from 30 s on, added after a bot left by accident while digging at the start. Dying or giving up keeps 50%. Gems also still give XP.
- **Saving.** Banked gems, shop levels, unlocks, finished goals, relics and lifetime totals are in `user://profile.cfg`. Bots and rule checks don't touch it.
- **Geodes.** 40 per mine, teal shells that take 150 damage, then burst as a chain into a gem per cube, worth more further out. Only 10% of a geode's worth counts as XP, because full XP made a bot reach level 42 in about two minutes.
- **Frenzy.** 500 combo fills the bar under the combo counter, then for 5 s every cube pops in one hit, score doubles and the screen glows gold. The next one takes another 500 combo, and at least 8 s of rest. Bots got 0-2 per Heart run and 7-11 in about two to three minutes of free digging. The first try at 150 combo would have fired almost nonstop.
- **Hints in the fog.** Geodes, vaults, shrines and relics sparkle through the fog from 20 m away, in their own colours.
- **Results screen.** Gems count up, finished goals land one by one, then the three nearest goals fill their bars. A goal you reach in a run also shows in the run itself.
- **Shop.** Six upgrades of 5 levels each, 40-80 gems for the first, doubling per level, about 11,000 gems in all. Bots earned 14-300 on bad runs and 1,200-3,500 on good ones, up to 6,400 with everything unlocked. Enemies don't scale with what you buy, so it stays an edge.
- **Unlocks.** Twelve goals. Prospector (double gems, half health) and Rig (Drill, goes where you drive with no aiming, tougher, slower) are the two characters, picked in the menu. Bombs and Shock Pulse open through goals and Mining Beam through a relic. No new tools: the existing three were locked instead, so these unlocks show nothing new to someone who has already played. Saw Blades and Drill stay free.
- **Vaults, shrines and relics.** 12 vaults per mine (walled, full of gold or ruby), 6 shrines (Blood: half your health for two upgrades. Greed: +50% gems, enemies hit 30% harder. Wind: +20% speed, -25% health) and up to 2 relic rooms. Five relics exist; touching one keeps it for good even if you die that run. A relic that adds health, speed or similar starts working on the next run.
- **Evolutions.** Great Scoop (Shovel + Long Handle: swings all around, +50% damage), Tunnel Borer (Drill + Quick Hands: three times wider, +50%), Cluster Bombs (Bombs + Hard Edge: four smaller blasts). They appear at the next level-up once the tool is maxed and its boost is at level 3. **Differs from the proposal,** which said a maxed boost, so they can show up in a normal run.
- **Bug found: swarms and hordes hardly came.** Sleeping nests filled the whole enemy pool of 640, so a swarm or horde could only spawn into slots freed by kills. A bot could fight the Heart with no enemies at all. The pool is now 1,500 with nests stopping at 640. This also means **every run the owner has played so far had far fewer enemies than intended**, and the balance entries below were measured with this bug.
- Bots with the bug fixed (15 runs, 0 script errors): 4 fresh Heart runs: 1 won, 2 died in the fight, 1 died at 12 s rushing into a nest. 2 with the shop maxed: 1 won at 146 s, 1 was still fighting when the test ended. Lifts, a shrine, a relic and all three evolutions worked in play. 165 fps at 1080p.

**2026-11-01, the fog follows the cube grid** (owner: like the soft fog below, but squared and following the cubes, which is what the Terraria picture meant; rule check, a bot and screenshots, the owner has not played it)
- Each cell of the fog now has one flat darkness, and its squares line up with the rock, so the rings have stair-stepped edges instead of brush-like curves. The lamp's dimming is per cell too.
- Same rings, opacities, colours and rules as the entry below. Only the look changed, so difficulty was not re-measured.
- The owner has since seen it and likes it better than the soft version: tagged `fog-grid-squares` (commit 6c11ab4). The soft version is kept as tag `fog-soft-rings` (commit e94d055). Both tags are on GitHub.

**2026-11-01, the fog follows what you have mined** (owner's Photoshop mockups and a video of their layers: a fog through all the terrain you haven't mined through, your path clear, the player's light kept so the path is darker away from you; rule checks, bots and screenshots, the owner has not played it)
- Replaces the rock shading of the entry below: cubes keep their own colours, and the fog is one dark sheet over everything, built like the owner's layer stack. Seven soft rings thicken with
  distance from what you know (25%, 42%, 58%, 72%, 84%, 93%, then black), a 2-cube clear rim and about 1.3 cubes per ring, so black starts about 10 cubes out. Ring edges are smooth curves, not block steps. The fog has the mockups' navy black and cools what is under it a little, like their blue layer.
- **What counts as known:** anything you break, and open ground your light reaches in a straight line (10 m). It stays known for good, so your path stays clear behind you. Places out of your lamp's reach are up to 40% darker (owner) instead of the old dim memory.
- **Air pockets** (owner unsure; decided to match the mockups, tell me if it should change): a cave you haven't reached is covered exactly like rock, so one near your tunnel shows faintly through the rings. Its nest wakes only when you actually see into it or hit it.
- Tools dig up to 7 cubes into the fog, so the outer rings are visible but out of reach. Beam, Pulse and anything else that breaks rock in the dark clears the fog there at once. The rings glide outward as you dig instead of jumping.
- Removed: light through rock, the bright flash on rock broken in the dark (the fog just clears now), the dim-memory look. The haze stays, thinner and only outside the fog.
- Bots: everything maxed (10 seeds, 120 s of game time, 0 script errors): 8 survived with 2-10 hits taken, 2 died at 42 and 44 s, deep down early. Normal runs (4 seeds, 200 s): 3 survived, 1 died at 93 s. 148-165 fps at 1080p. The browser version has not been tried with this.

**2026-11-01, Terraria-style rock shading and a textured floor** (the rock shading was replaced the same day, see the entry above; the floor stays) (owner: blocks get darker the further they are from the open edge, 5-6 fading blocks and a 7th that is black or nearly; texture on the ground so moving reads visually; rule checks, bots and screenshots, the owner has not played it)
- **Rock shading** (owner). With fog on, each cube's colour depends on how many cubes it sits from open air: full brightness at the edge, six steps
  darker, and the 7th almost black (`rock_shade` in Defs). It updates as you dig, so the bright edge follows you in. It is off with fog off, or everything inside the rock would be black.
- **Changed from before, not in the request:** light no longer passes through rock. Rays stop at the first cube, and rock shows up along with the open cell nearest to it, up to
  7 cubes deep. This replaces "4 cubes along each ray", which made the band thin to 1-2 cubes along tunnel walls. So you can dig up to 7 cubes into a wall you can see, and you can no longer
  see through thin walls into the next cave. A hidden cave near your wall shows only as a dark notch in the band.
- **Haze** now stays off rock, and the grey fringe at the edge of the light is gone, because both turned deep rock grey instead of black.
- **Ground** (owner). The flat floor is now chunky dirt fixed to the world: dark stains, grain, long cracks and scattered stones that catch the lamp. Enough shows at once to see it slide past as you move.
- Bots: everything maxed (6 seeds, 120 s of game time, 0 script errors): 5 survived with 2-11 hits taken, mostly 7-11, against 4-7 before; 1 died at 78 s. Enemies were not touched, so the new sight rules
  are the likely cause, but that is not confirmed. Normal runs (4 seeds, 200 s): 2 survived, 2 died at 98 and 116 s. 156-165 fps at 1280x720 in a maxed run. The browser version has not been tried with this.

**2026-11-01, enemies scale with you** (owner: late game enemies can't get close; more and tougher as you get stronger, but still satisfying to kill, keep the player on edge; rule checks, bots and screenshots, the owner has not played it)
- Scaling comes from what you own, not from time. Enemy health follows your strongest tool's damage. Past your first 8 upgrades, each
  tool or boost level adds 4% health, 5% more enemies, 1.2% speed (up to +45%), 2% damage, and less pushback; hordes come sooner too.
  Sleeping nests take your current strength when they wake. Caps: 430 awake in the swarm, 320 in a horde. Rock bands add less health than before (30% per band, was 50%).
- **Runner** (suggested), a new yellow enemy: frail and faster than you once you have many upgrades, up to 45% of the swarm late, so
  something always gets through the gaps between Pulses. Maxed Pulse (157 damage) was why more enemies alone changed nothing.
- Killing stays quick: a crawler takes 1 starter-shovel hit and about 3 from a maxed shovel on the first band, more deeper down.
- Bots with everything maxed (120 s of game time): 4-7 hits taken on most runs, one 19, none died, against 0-5 hits before; about 2,000 kills,
  not 700. With enemy damage 3% per upgrade instead of 2%, 2 of 4 died, so that is the number to raise for more danger. Normal runs at the final numbers: 3 of 6 survived 200 s, the others died at 74, 93 and 146 s.
  About 165 fps at 1080p in a late fight.

**2026-11-01, the swarm** (owner: much less traps, more enemies, sometimes feel surrounded as in VS; rule checks, bots and screenshots, the owner has not played it)
- Traps cut to about a sixth: 15 spike patches and 22 gas blobs. Nests: 80 instead of 55, about twice as full.
- **Swarm** (suggested): from 12 s, crawlers arrive steadily from past your light, digging their own tunnels. **Hordes** (suggested): from
  35 s, every 40 s, "SWARM!" and a full ring of 45 or more crawlers closes in from about 13 m, up to 170.
- Crawlers now die to one starter shovel hit (8 health, was 14) and give less XP each. Kills count for the combo and play the rising notes.
- Brutes now start from the third rock band, about 26 m out, because one caught a bot at level 1.
- Bots (6 seeds, 200 s of game time, 0 script errors): 3 survived with 1,300-1,500 kills, 3 died at 14, 53 and 86 s. The 14 s one had run 28 m straight into a nest. Still about 150 fps with a horde on screen.

**2026-11-01, enemies and traps** (owner: "traps and enemies you can run into"; rule checks, bots and screenshots, the owner has not played it)
- **Health and death, added because threats need them.** 100 health, a short blink after each hit, a red screen flash. At 0 the run
  ends with "YOU DIED", your stats, and Dig again. Level-ups heal 30. New boost: Thick Skin, +20 max health. No other healing yet.
- **Nests** (suggested). 55 open pockets, none within 20 m of the start, hold sleeping enemies. They wake together once you can see
  one or hit one, then chase you and are stopped by rock like you are. Deeper nests hold more, and enemies get tougher per rock band.
- **Enemies.** Crawler: small, in numbers. Brute: slow, big, 130 health, pays well. Burrower: tunnels through rock to you, first after
  40 s and then every 22 s or less, so no spot stays safe. All tools hurt them, kills drop gems. Beam and Pulse reach them through the
  fog; the other tools have no sight limit on enemies. Awake enemies in the dark show only red eyes.
- **Traps.** Spike plates: 90 patches on the floor, many hidden under rock, that rise on a beat with a small warning first. Gas Rock:
  yellow-green cubes that blow 0.9 s after breaking, with a growing blinking ball. The blast hurts you for 18, clears rock, and hits
  enemies hard, so it can be used against them. Blobs chain, and one fuse covers a whole pocket.
- Tools: the shovel also swings when only enemies are in its fan. Pulse hits enemies as its ring reaches them.
- Bots (6 seeds, 150 s of game time, 0 script errors): 3 survived, 3 died at 27, 89 and 115 s. The bot backs away but doesn't avoid traps
  or nests. Difficulty is a first guess. Screenshots show nests and fights; spike plates and the gas fuse were tested by checks but not looked at.

**2026-11-01, playable in a browser** (owner)
- Published at https://dnis-p.github.io/MMS/dig/, with the car game staying at /MMS/. A push to this branch builds it and then starts the
  default branch's workflow, which builds both games and publishes them. The only changes on the default branch are its workflow
  file and CLAUDE.md, not the car game.

**2026-11-01, fog of war and Pulse** (branch `prototype/dig`; rule checks, a bot and screenshots, the owner has not played it)
- **Fog of war** (owner), on by default. You see 10 m at most and the rest is black, like an ARPG dungeon. Light follows real sight
  lines: it passes through 4 cubes of rock and then stops, so you see into the wall ahead and down open caves, but not through the
  mountain. The owner asked for blocks in proximity; the sight lines are how "only what you can directly see" was read.
- **Atmosphere** (owner). The air gets hazier and dustier toward the edge of your light. **Player light** (owner): a warm, slightly
  flickering light around the digger.
- **Dig only what you see** (owner). Shovel, Drill, Saws and Bombs can't touch unlit cubes, so upgrading them stops at the edge of
  what you can see. Beam and Pulse go through the fog (owner), and so do crystal chain reactions and the level-up blast.
- **Breaking reveals** (owner: the beam should unlock that new area visually). Rock broken in the dark and the cubes around it flash
  bright, then fade over about 1.2 s to the dim remembered look. It works for anything that breaks there, not only Beam and Pulse.
- **Added, not proposed:** places you have seen stay dimly visible, so your tunnels can be read on the way back. Gem stars show through
  the dark, so a lost gem can still be spotted.
- **Switch** (owner). "Fog of war: ON/OFF" is on the main menu and the pause menu, and is remembered between sessions. There is no
  separate options screen yet. With it off, the game plays as before and the player light is off too.
- **Pulse** (owner: effect and animation didn't match). The ring keeps its 0.35 s speed, and each cube is hit at the moment the ring
  reaches it, using the ring's own growth curve. A first try that broke everything at once with a faster ring felt too fast, the owner
  said. Bombs and the level-up blast keep their own ripple.
- About 150 fps at 1080p on this PC with a bot.

**2026-10-31, digging prototype** (branch `prototype/dig`; rule checks, a bot and screenshots, the owner has not played it and nobody has listened to the sounds)
- **Raccoon deleted** (owner): the branch `prototype/raccoon-eat` is gone from this PC and GitHub. Lessons kept: hunting alone wasn't
  satisfying; what the owner liked was density, lots of things dying at once.
- **Base** (owner): car game code on its own branch, so the car game is untouched. Cars, enemies, bosses, weapons, Garage, crates
  and saves were removed from this branch only. Effects, sounds, gems, level-up screen, HUD pieces and the bot are reused. Saves
  would go to a separate folder, `MMS-Dig`, so real car progress can't be touched; nothing is saved yet.
- **World.** Top-down 3D (owner). One flat layer of 102,400 cubes of 0.5 m, each hit point stored per cube, drawn in chunks. Random
  every run: rock changes every 13 m out from the start through 7 bands, with caves, 4 ores and 55 crystal blobs. Bedrock edge.
- **Movement** (owner): instant. Full speed, new direction and stopping all happen on the next frame. Rock blocks you.
- **Shovel** (owner: hits many cubes). Swings by itself at everything in a 2.4 m fan ahead of you, 28 cubes in the test, only when
  there is rock there. The hit ripples outward instead of landing all at once.
- **Feel** (owner). Hit cubes flash white, rattle and swell for 0.13 s, then stay darker as they wear down. Broken cubes burst into
  chips that bounce on the floor. Ore leaves shiny gems that hop out and fly to you when close. Added, suggested: each pop plays the
  next note of a rising scale, so digging runs up a keyboard, plus swing arc, camera punch, hitstop on big pops and a bubble-pop sound.
- **Chain reactions** (suggested twist). Crystal goes off as a whole blob in a ripple. Levelling up blasts 5.5 m of rock around you.
- **Tools and upgrades.** Level-ups give 1 of 3: Shovel, Drill, Saw Blades, Bombs, Shock Pulse, Mining Beam, all automatic, plus 5 boosts.
  Evolutions and unlocks found in the map are not built yet.
- No threats (owner), no goal and no way to lose yet. No theme or models (owner): the digger is plain boxes. Nothing is saved.
- Limits: a bot reaches about level 5 in 35 s and level 8-16 in 90 s of game time, so pacing is a first guess. About 150 fps at 1080p on this PC with a bot;
  never run on a phone. Cubes have no gaps: gaps showed dark lines along chunk edges, cause not found.
- Test: `tests/dig_check.tscn`.
- **Buzz removed** (owner: a really annoying deep buzzing while digging). The Drill's looping engine sound, left over from the cars,
  is deleted, so the Drill has no sound of its own now. Pops and hit ticks could repeat every frame, which blurs into a low hum, so
  they now wait 40-72 ms and 70-126 ms at random. Found by reading the code; Claude can't hear the result.
- **Gems** (owner). Every shiny mineral now drops a gem every time: crystal used to drop one in eight, and at most 500 gems could lie
  around. Each crystal gem is worth 0.15 XP so blobs don't level you too fast; the limit is 1,500. Gems have a twinkling star that shows
  through rock, keep their mineral's colour and throw sparks when collected.
- **Mouse aim** (owner's idea, Enter the Gungeon). Tools point at the mouse and WASD moves separately. Shovel, Drill and Beam follow the
  aim and bombs land on the pointer when rock is in range; Saws and Pulse go all around. Tools still fire by themselves with no click,
  Claude's choice: holding a button would be one small change. The camera leans up to 3 m toward the pointer. There is a ring-and-cross
  cursor, and until the mouse moves, tools point the way you walk. Tested by checks and a bot, not with a real mouse.
- **PC only on this branch** (owner). Touch controls and the virtual stick are removed.
- **Constant shake** (owner: way too much late game, shouldn't grow with upgrades). Shakes no longer add up: the strongest current
  one wins. Single cube pops no longer shake at all. Biggest shake is the level-up blast, 0.4 at most even with every tool at max,
  about 11 cm of camera movement. Also capped the camera punch and limited the big-pop freeze and thud to once per 0.6 s, which would have stuttered late game.

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
**Owner, 2026-11-03, Frenzy feels too easy to set off** ("i kinda feel like its set off too easily"). Not changed yet: the owner asked when it starts, options are in the chat of that day.

**Owner, 2026-11-01, plans for the digging game (a first version is built, see section 8; the rest of these stay open)**
- Unlockables, as in VS, where you unlock characters that give items or abilities you didn't have before. Not decided yet whether there will be several characters or just tools. Test first, then iterate.
- Theme still undecided, not picked for now. Some mechanics could come from choosing it.

**Owner, 2026-10-31, the refocus (the prototype is built, see section 8; these are still open)**
- After playing: the late game of the car prototype is pretty satisfying, so the VS formula is probably better. The raccoon's theme
  wasn't bad, but being the hunter wasn't that satisfying. Games may need phases where you get surrounded and just shred through.
- A digging game with the feel of popping bubble wrap. Keep top-down 3D for now. No threats for now: first make it very satisfying
  in sound and visuals. No theme yet, so no specific models.
- Still open: start slow and find equipment in the map that unlocks forever, like VS. Skills that auto-dig. Start as a person and
  unlock vehicles, or only tools. Runs or a whole open underground world. Enemies or something else later. Ranged digging tools or
  weapons (Enter the Gungeon). A twist in gameplay and theme. Likes VS rewards, VFX and sounds, and Megabonk from its trailer.

- Procedural levels: idea only, not to be implemented yet (see section 5).

- Leaderboard: multiplayer entries with build, time, score and kills; whether permanent upgrades count is undecided (see section 6).
- Burnout ring and roads as fast lanes: saved for later review (see section 6).

**Future, not to be implemented yet (owner, 2026-10-30)**
- Upgrades specific to each vehicle class, both in runs and in the permanent upgrades between runs.

**Owner feedback after playing, 2026-10-30 (ideas only, nothing decided or implemented)**
- Works: evolved minigun killing a lot of enemies; kills that make satisfying sounds, explode into bits and show damage
  numbers, flashes and a colour-coded combo.
- Boss maybe sooner: the owner reaches it at about level 25 and it dies in 5 seconds or less.
- Dash in boss arenas is too strong. Either make it less strong, or drop arenas and spawn bosses in the world like VS (the
  owner was going to do that for some or all bosses anyway), which also removes the dash.
- Willing to change most of the game or start over for something addictive with some originality.
- Twist idea: play a monster that attacks and absorbs NPCs, agar.io style. Bigger ones are fought by circling, VS style, with
  auto attacks; the player picks when to absorb. Absorbing grows you; when strong enough you can destroy the environment.
  Absorbed bosses change your appearance and give new attacks. People run, some fight back; this part needs more thought.
- Theme ideas: a dragonfly eating insects and evolving (like Cell in DBZ or the ants in HxH); or something absurd, like a raccoon
  in a garbage container whose food runs away, with other animals attacking, or a raccoon in a lab eating mutated animals.
