# Design vision and idea backlog

Living document. The owner's words and decisions come first; Claude's suggestions are marked
**(suggested)** and are only ideas until the owner says yes. Anything marked **Decided** should not be
changed without asking. Add new ideas at the bottom of the right section, with the date if useful.

**DIG:** a top-down 3D digging roguelite, on branch `main`. How it works right now is in docs/MECHANICS.md, the art
style in docs/ART.md.

## 1. Vision (owner)
- A digging game that feels like **popping bubble wrap**, with Vampire Survivors rewards: juicy visuals and sound come first
  (2026-10-31).
- Top-down 3D, a world of small cubes. Hit cubes flash and vibrate, broken ones burst into bits, ore leaves something shiny.
- Movement is instant, like 2D games such as VS or Enter the Gungeon, and separate from aiming: the mouse aims.
- Enemies and traps exist (2026-11-01), but the digging feel still comes first. No theme yet.
- PC only for now (2026-10-31).

## 2. Feel principles (owner)
- **Satisfying, simple, scalable**, like Vampire Survivors: play almost without thinking, anyone can play,
  no deep build theory (not Path of Exile).
- Satisfaction comes from juicy feedback: hits, sounds with slot-machine-like rewards, visual impact.
- Upgrades stay simple; max-level items **combine into evolved versions** (as in Vampire Survivors).
- Tools fire by themselves, no ability buttons: **Decided** (keep it like Vampire Survivors). One exception (owner, 2026-11-04):
  the Dash Drive, which you press.
- Permanent upgrades must not take too long to earn: no 80-hour grind for the best one.

## 3. Decisions made so far
| Topic | Decision |
|---|---|
| Engine / language | Godot 4.7, GDScript, GL Compatibility renderer. |
| Platform | PC only for now (owner, 2026-10-31): mouse and keyboard, or a gamepad. Input stays as actions and UI anchored. |
| Camera | Top-down 3D (owner), fixed orientation, looking about 70 degrees down (`Defs.CAMERA`). |
| Movement | Instant, separate from aiming (owner). |
| Art | Low-poly pixel 3D (owner, 2026-11-04), see docs/ART.md. |
| Fog | Fog of war like an ARPG dungeon, on by default, with a switch (owner). |
| Distribution | Web build on GitHub Pages and an APK from GitHub Actions; itch.io possible later. |

## 4. Ideas backlog (suggested by Claude, not yet approved)
**Digging ideas not built yet (suggested 2026-10-31)**
- Rhythm in three beats once enemies are wanted: calm digging, breaking into a nest and getting surrounded, then the reward. Enemies
  live in pockets, so the owner's "surrounded and shredding" phase comes from your own digging.
- A slow threat rising behind you (collapse, lava), so standing still is never safe.
- Runs of about 20 minutes, one descent, with meta progression between runs. Not an open world: it costs saving and streaming and
  loses the VS shape. Buried finds that unlock forever also give the Hades-style mystery.
- Themes: digging down through a landfill into what is buried under it (raccoons love shiny things).
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
- Meta: a short gem shop with no long grind (owner, section 2), a Collection of everything found, a camp that visibly grows, lifts that start you deeper, new mines with their own rules, and a Curse setting that trades danger for gems.
- Themes, in order of Claude's preference: raccoon in a landfill digging down through layers of history (bubble wrap really is trash, tools are junk taped together); gravedigger from cemetery to Hell (fits the lamp and fog, closest to VS); prison escape starting with a spoon (being caught explains every restart); inside a sleeping giant (skin to Heart, gross popping); ant colony (workers fill the tunnels you dig); mole (blindness explains the fog, cute); corporate asteroid mine (disposable staff); dwarves (safe, least original).

## 5. Open questions
- Final name, theme and sound direction.
- Which of the section 4 ideas does the owner want first?

## 6. ALL IMPROVEMENTS IMPLEMENTED SO FAR
**2026-11-05, the car game's leftovers removed** (owner: "delete everything from the car game that isn't needed for the dig game, whether it be code or info in the docs")
- Code: floating damage numbers (40 hidden labels updated every frame, never shown in DIG) and four sounds nothing played (shot, saw, jackpot, slam). The web build's second, "packed" version is gone with its loading page, which still said Motorhead Madness Survival; nothing published it, as GitHub Pages and the itch.io zip use the standard build.
- Docs: the car game's vision, boss arena, decisions, future features, ideas, open questions, its done entries (2026-10-30) and its to-do items. DESIGN now starts with DIG's own vision, feel principles and decisions, taken from what the owner said for DIG, and the sections are renumbered: 6 is the done list, 7 the to-do list.
- Kept from the car game's feel principles, as the owner's and true for DIG: VS-like simplicity, juicy feedback, evolutions, no ability buttons (with the Dash Drive as the exception), and no long grind.
- Not touched: the tag `car-game` on GitHub and the old commits in `main`'s history.

**2026-11-05, an objectives panel in the run** (owner: "add an objectives panel inside the gameplay while i play i can see objective status. like it shows at the end when run ends. for example 1/3 bosses defeated, 1000/3000 gems mined etc."; rule checks, a bot's screenshots, the owner has not played it)
- **What it is.** A translucent panel at the top left, under the tool and boost boxes, titled OBJECTIVES, with the three goals you are closest to. Each row has the goal's own text (the same as the results screen and the Goals page, for example "Kill 5 bosses"), the count (`1 / 5`, thousands separated) and a thin bar. It redraws four times a second.
- **Counts this run as it goes.** The number is the lifetime stat plus what this run has done so far, so the bosses and kills you have now show at once, and `band` and `combo` show the better of the two, as they do when the run is banked. A goal you meet during the run reads DONE and keeps its row until the run ends, where it is paid as before. Goals already finished are left out, and with all 16 done the panel is gone.
- **Differs from the example (suggested):** the rows use the goals' wording ("Bank 3,000 gems in total") instead of "gems mined", because those are the real goals and the results screen says the same. "Gems mined" is the **banked** goal, which counts the gems you carry **in full**, as if you got out now. **Limit:** if you die you keep only half (more with Insurance), so that bar can drop at the end. The "GOAL:" banner that already announced finished goals is stricter and uses the death share, and I left it alone.
- **Which three (suggested).** Most of the goal met first, like the results screen, with ties in the goals' list order, so a fresh profile shows "Get out by lift", "Open 5 geodes", "Reach the Stone layer". The results screen left ties unordered before; it now uses the same order.
- **Out of the way (suggested).** It steps aside while the full map is open. There is no switch to hide it, and it adds nothing to the Options page; say so if it gets in the way.
- **Checked** (rule check, 12 new checks): the first goals in order and the same every time, nearest-to-done first, a row's text, count and bar, earlier runs adding in, carried gems counting as banked, a best-of stat taking the larger, DONE, finished goals left out, the full map hiding it, and no panel with every goal done. A bot ran with it and a screenshot shows it. **Not checked:** how it feels to play with it, whether three rows are the right number, and whether it covers anything on small windows (looked at 1280x720 only).

**2026-11-04, the Dash Drive levels up like a tool, one card per level** (owner: dash upgrades had "slightly different name (like long dash) and it still says NEW on those cards"; then "Dash lvl 1 when you first get it ... ->lvl2, 3, 4 etc", "idc if each level the dash changes name but i dont want to see a different name and a separate level from the main upgrade branch it has")
- Checked: the owner was right. Each of the six upgrades (Long Dash, Dash Speed, Quick Recharge, Decoy Clone, Reinforced Clone, Volatile Clone) was its own card with its own levels, drawn at random, and the first level of each said NEW, though none took a slot. A first fix only changed NEW to "Lv 0 > 1"; the owner then asked for one line, so the upgrades are now levels of the Dash Drive.
- Now: one card, always titled Dash Drive. Level 1 says NEW and takes the tool slot; then "Lv 1 > 2" up to level 6, the same top level as a tool. It is favoured in the draw like a tool you hold, and only one Dash Drive card shows at a time.
- **(suggested) The order of levels**, mine: 2 is +20% dash time and -15% cooldown, 3 the decoy clone and +15% speed, 4 +20% time, -15% cooldown and +50% clone health, 5 the clone explodes and +15% speed, 6 -15% cooldown, +50% clone health and a 40% bigger blast. Change it in `Defs.DASH.levels`.
- **Strength** (owner: keep 6 levels and fit the other dev's upgrades in, "if the values of the other dev are not too op you can use them but if they do feel like that nerf it a bit"). Each step is worth what the other dev set. The first version of this change fitted only 9 of the 16 steps; now 12 are in. My judgement (suggested) was that the full set was a bit strong: a 13.9 m dash is about half the screen, and a 1.65 s wait with a clone that blasts each time you dash replaces it is close to a free bomb. So I kept the full cooldown (1.65 s) and the clone, and left out one step each of dash time, dash speed, clone health and blast. At level 6: 10.9 m dash (other dev's full set 13.9 m), 1.65 s wait (same), clone health +100% (+150%), blast +40% damage and +12% size (+80%, +24%). Bots that start with the top level (seeds 1 to 3, 240 s) did not show the full set to be stronger: with it all three died, at 305 to 396 s; with these levels one died at 459 s and two lived; without a dash they died at 146 to 302 s. Bots dash differently from people, and nobody has played it, so this is still a guess.
- **Enemies scale less with it**: a full Dash Drive now counts 6 upgrades, like a tool, not 17.
- The HUD box shows its level ("D3"), like the tools' numbers. Rule checks cover each level and that no other dash card shows. Bots ran, but nobody has played it.

**2026-11-04, DIG is the whole repo now: branch `main`, repo `dnis-p/dig`** (owner: "make the dig one the main branch", "rename the branch to main", "rename the repo to dig or something like that")
- The digging branch `prototype/dig` became `main`, the default branch.
- The repo is renamed to `dig`, so the game is at https://dnis-p.github.io/dig/.
- DIG's own workflow publishes the site on every push to `main`, after the smoke test, web build and APK.
- The Android app shows as DIG and builds as `dig.apk`. Its app ID is `com.dnisp.dig`: the owner has no copy on a phone yet, so nothing was lost by changing it, but it should stay fixed from now on.
- Saves moved from `%APPDATA%/MMS-Dig` to `%APPDATA%/Dig` (owner: "could it be just Dig"). The old folder held only `options.cfg` (no dig progress: the owner plays in the browser), which was copied over. The old folder is still there.
- Builds no longer run when only a tag is pushed.
- The owner's local folder path was removed from CLAUDE.md, and from every old commit (owner's choice), which changed all commit IDs. The tags `fog-grid-squares` and `fog-soft-rings` were moved to the rewritten commits.

**2026-11-04, the Dash Drive: a dash that takes a tool slot, with a decoy clone** (owner: "add a dash ability for the player ... it should work like a slot, like it occupies a slot and can receive upgrades. for example dash speed and length, dash leaves a clone behind which enemies attack until it dies. And if dash clone is unlocked u can unlock extra upgrades such as improve dash clone health or make the clone explode"; "by button Space or shift and should dash towards [where] you are moving". Built on the branch `prototype/dig-dash`, made from `prototype/dig` before it became `main`, then moved onto `main` for a pull request; rule checks, bots and screenshots, the owner has not played it)
- **A button, on purpose.** It is the first thing in this game you press: Space or Shift (the gamepad's A). Tools still fire by themselves, and the Controls page, How to play and the start of a run say so. **(suggested) Gamepad A**, not asked for: there had to be a button for the gamepad, and A is free in a run (it only confirms in menus, where the game is paused).
- **The dash.** A burst of 30 m/s for 0.2 s, so 6 m, with no hit able to land for 0.15 s longer, then a 3 s wait. You can't steer during it, tools keep firing, and rock still stops you: it moves in steps of at most 0.2 m, so a fast dash can't skip a wall (checked against a block of cubes). Direction (owner): the way you are steering when you press it; standing still, the way you last walked (suggested: the owner didn't say what to do with no input). The mouse aim doesn't count, so you can dash one way and shoot another.
- **A slot.** The Dash Drive is a card in the level-up pool and takes one of the tool slots (4, up to 6 with the Tool Belt). The "Tools 2/4" line, the "Last tool slot" hint and the empty boxes at the top left count it, and a cyan **D** box shows it. With all tool slots full it isn't offered. It is not locked behind a goal (suggested: a goal could unlock it later). It has no levels and no evolution.
- **Replaced the same day** (owner) by six levels of the Dash Drive itself, see the entry above. What was first built:
- **Its upgrades come as cards**, once you hold it (numbers in `Defs.DASH`): Long Dash (+20% dash time, so farther and untouchable for longer), Dash Speed (+15% speed, so farther), Quick Recharge (-15% cooldown), each three times; Decoy Clone, once. **Differs from "speed and length":** both lengthen the dash, since the dash lasts a fixed time; only Long Dash also lengthens the time you can't be hit. I kept them apart that way because a faster dash over the same distance would be shorter and so safer for less time, a worse upgrade.
- **Decoy Clone** (owner). Each dash leaves a translucent copy of the digger where you stood, with a health bar over it. Health is 120% of your max health (144 at the start), it stays 8 s, and it blinks for the last 1.5 s. An awake enemy goes for the clone instead of you when the clone is closer than 70% of its distance to you, so those near you still come for you. Enemies touching it hurt it with their own damage, one hit per 0.2 s at most, the same rule that protects you. A new dash while one stands makes the old one pop first. It goes away, with no blast, when the run ends. Bosses are enemies like the rest, so they go for it too (not tried with a boss), and the Borer's charge still lines up on you.
- **Clone upgrades** (owner), only shown once you hold the clone: Reinforced Clone (+50% health, three times) and Volatile Clone (it explodes when it falls, through health or time, 100 damage in 3.5 m to rock and enemies; each level after the first adds 40% damage and 12% radius, three levels). The blast grows with Hard Edge, the shop's damage bonus and Long Handle, as a tool does. A dash that takes the clone away for a new one also sets it off.
- **Cards.** A level-up offers at most two Dash Drive cards, picked at random, so it competes with the tools for the three cards instead of filling them (checked: never three).
- **Enemies scale with it:** the drive counts one upgrade and every mod level another, like tool and boost levels (`Run._update_power`), so a full Dash Drive adds 17 upgrades' worth of crowd, speed and toughness. **Limit:** I did not retune the free upgrades or difficulty for this.
- **HUD.** A bar at the bottom left fills while the dash recharges, with the countdown on it, and says `[Space]` (`[A]` on a gamepad) when it is ready.
- **Bots** dash toward where they were walking when two awake enemies are within 5 m. `--give=dash` or `--give=all` gives them the whole Dash Drive.
- **Checked** (rule check, 305 checks in all, 36 of them new): slot use and the last-slot hint, cards and their lock, the dash's distance, direction and invulnerability, rock stopping it, which enemies go for the clone, its damage and damage gap, health upgrade, falling, the blast and its level, the cooldown and distance mods, scaling, the bar and the keys. A bot with everything dashed 15 times in 60 s of game time and 14 clones popped, with no script errors; three more normal bot runs on seeds 3-5 had none. Screenshots show the bar, the D box and the clone with its health bar. **Not checked:** how it feels, whether 3 s, 6 m or the clone's health are right, a real gamepad, how three rings of a swarm treat the clone, and whether the mid-run hint is enough to teach the button.

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
- Each push builds the web version and publishes it on GitHub Pages, now at https://dnis-p.github.io/dig/.

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
- **Buzz removed** (owner: a really annoying deep buzzing while digging). The Drill's looping engine sound
  is deleted, so the Drill has no sound of its own now. Pops and hit ticks could repeat every frame, which blurs into a low hum, so
  they now wait 40-72 ms and 70-126 ms at random. Found by reading the code; Claude can't hear the result.
- **Gems** (owner). Every shiny mineral now drops a gem every time: crystal used to drop one in eight, and at most 500 gems could lie
  around. Each crystal gem is worth 0.15 XP so blobs don't level you too fast; the limit is 1,500. Gems have a twinkling star that shows
  through rock, keep their mineral's colour and throw sparks when collected.
- **Mouse aim** (owner's idea, Enter the Gungeon). Tools point at the mouse and WASD moves separately. Shovel, Drill and Beam follow the
  aim and bombs land on the pointer when rock is in range; Saws and Pulse go all around. Tools still fire by themselves with no click,
  Claude's choice: holding a button would be one small change. The camera leans up to 3 m toward the pointer. There is a ring-and-cross
  cursor, and until the mouse moves, tools point the way you walk. Tested by checks and a bot, not with a real mouse.
- **PC only** (owner). Touch controls and the virtual stick are removed.
- **Constant shake** (owner: way too much late game, shouldn't grow with upgrades). Shakes no longer add up: the strongest current
  one wins. Single cube pops no longer shake at all. Biggest shake is the level-up blast, 0.4 at most even with every tool at max,
  about 11 cm of camera movement. Also capped the camera punch and limited the big-pop freeze and thud to once per 0.6 s, which would have stuttered late game.

## 7. ALL IMPROVEMENTS PROPOSED SO FAR by owner
**Owner, 2026-11-05, characters like VS, each bringing a tool** ("adding multiple unlockable characters just like in VS, each with their own stats and starting tool. Unlocking a character will also unlock that tool so the other characters can use it in their runs"). The owner wants to grow the prototype slowly into a full game to publish. Not built yet.
- Today: 3 characters (Digger, Prospector, Rig), and they start with Shovel or Drill, which everyone has. Tools are unlocked separately, by goals (Bombs, Shock Pulse, Spark Coil, Mole Pack) and a relic (Mining Beam). With the owner's rule, each locked tool would come with its own character instead, so goals would unlock characters (suggested).
- **Stat categories (suggested 2026-11-05, not chosen):** one stat sheet shared by characters, boosts, the shop, relics and shrines. Survival: max health, recovery, armour, revivals. Offence: might, area, cooldown, amount, duration, projectile speed. DIG's own: light (sight and how far you dig into fog). Movement: move speed. Economy: magnet, growth (XP), greed (gems), luck, curse. Run control: rerolls, skips, banishes, slots. A character is a starting tool, small changes to 2-3 stats, and one passive rule.

**Owner, 2026-11-04, art style: Decided, low-poly pixel 3D** ("it has to be lowpoly 100%"; picked "Pixel 3D" after Claude described the owner's Pinterest board). Low-poly models with low-res pixel-art textures, chunky toy proportions, a spooky-but-cute mood, dark bodies with one glowing accent. Textures were undecided between little and more detail, and pixel art was the owner's own option. The owner makes the models with Meshy AI. The style guide, the rules from how the game draws things, and a prompt for every model the game has are in docs/ART.md. The creature designs in those prompts are **(suggested)**, and the theme is still open. No model is in the game yet.
**Owner, 2026-11-04, about 10 tools and 10 boosts** ("i need ideas for new tools and boosts. I want to have about 10 of each"). There are 8 tools and 6 boosts now, so this means 2 more tools and 4 more boosts. Not picked or built yet. The ideas below are all **(suggested)**, to choose from:
- Tools (suggested):
  - **Runaway Cart:** a mine cart shoots off the way you aim and ploughs through rock, bouncing off bedrock and hard rock a few times. It crosses the whole screen.
  - **Dynamite Trail:** drops a lit stick behind you every few steps, and it blows a moment later. It covers behind you, so running from a swarm becomes an attack.
  - **Acid Flask:** lobs a flask that leaves a puddle. The acid eats outward through rock cube by cube for a few seconds and burns enemies in it (like VS's Santa Water).
  - **Boomerang Pick:** a thrown pick flies out, turns and comes back, hitting everything it passes both ways.
  - **Jackhammer:** pounds the ground, and a shockwave runs along the walls of the tunnel you're in, popping them. It widens old tunnels and hits enemies coming down them.
  - **Cryo Spray:** a cone of frost. Frozen rock breaks in one hit from anything, and frozen enemies slow down. It works with every other tool.
  - **Ore Hook:** shoots at the nearest ore you can see, breaking the cubes in the way, and pulls the gem back to you.
  - **Echo Pinger:** a ping that lights up the fog further for a moment and marks ore. It does a little damage.
  - Claude's pick for the two: Runaway Cart and Dynamite Trail, the most different from the current tools and both easy to read on screen. Tesla Pick and Tunnel Worm (section 4) were left out because they overlap Spark Coil and Mole Pack.
- Boosts (suggested), with the evolution each could unlock:
  - **Extra Hands:** +1 of whatever a tool throws: blades, bombs, moles, jumps (like VS's Duplicator), with few levels because it's strong. Saw Blades.
  - **Bright Lamp:** +15% light radius, and you can dig further into the fog. Mining Beam.
  - **Aftershock:** broken cubes sometimes pop a neighbour, so you get small chain reactions. Shock Pulse.
  - **Sweet Spot:** a chance for a critical hit: double damage, a bigger pop and its own sound. Boomerang Pick or Runaway Cart.
  - **Lucky Pick:** more ore and gem drops, and geodes are a bit more common. Ore Hook.
  - **Rhythm:** the combo lasts longer before it drops, and Frenzy builds faster. Dynamite Trail.
  - **Hot Coffee:** slowly heals over time, faster while your combo is high. No evolution.
  - **Padding:** take 8% less damage from every hit. Jackhammer.
  - Claude's pick for the four: Extra Hands, Aftershock, Bright Lamp and Sweet Spot. Aftershock and Sweet Spot add to the popping feel, and Bright Lamp works with the fog.
- Saw Blades, Shock Pulse and Mining Beam have no evolution yet, so new boosts could give them one.
- A run holds only 4 tools and 4 boosts (`Defs.SLOTS`), so a bigger pool means each run sees a different mix, and a particular evolution comes up less often.

**Owner, 2026-11-03, Frenzy feels too easy to set off** ("i kinda feel like its set off too easily"). Not changed yet: the owner asked when it starts, options are in the chat of that day.

**Owner, 2026-11-01, plans for the digging game (a first version is built, see section 6; the rest of these stay open)**
- Unlockables, as in VS, where you unlock characters that give items or abilities you didn't have before. Not decided yet whether there will be several characters or just tools. Test first, then iterate.
- Theme still undecided, not picked for now. Some mechanics could come from choosing it.

**Owner, 2026-10-31, the refocus (the prototype is built, see section 6; these are still open)**
- The VS formula is probably the better one. The raccoon's theme wasn't bad, but being the hunter wasn't that satisfying. Games
  may need phases where you get surrounded and just shred through.
- A digging game with the feel of popping bubble wrap. Keep top-down 3D for now. No threats for now: first make it very satisfying
  in sound and visuals. No theme yet, so no specific models.
- Still open: start slow and find equipment in the map that unlocks forever, like VS. Skills that auto-dig. Start as a person and
  unlock vehicles, or only tools. Runs or a whole open underground world. Enemies or something else later. Ranged digging tools or
  weapons (Enter the Gungeon). A twist in gameplay and theme. Likes VS rewards, VFX and sounds, and Megabonk from its trailer.
