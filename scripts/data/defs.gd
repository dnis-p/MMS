class_name Defs
## All tunable game content lives here so balancing is just editing numbers.

const MAX_TOOL_LEVEL := 6
const MAX_BOOST_LEVEL := 5
const COMBO_WINDOW := 1.2
const FILLER_SCORE := 500

## Camera, fixed orientation, relative to the digger: metres south, metres up, and how many
## seconds of travel it looks ahead. aim_lean: metres it leans the way you aim.
const CAMERA := {"back": 7.0, "up": 19.0, "lead": 0.12, "aim_lean": 1.5, "fov": 60.0}
## Aiming. reach: pixels of mouse travel from the digger to the ring; the hidden pointer stays within
## it, so a push outward keeps the aim steady and a push across turns it around. ring: metres from the
## digger to the arrow, which is arrow metres wide; arrow_alpha and ring_alpha: how opaque each is.
const AIM := {"reach": 160.0, "ring": 2.6, "arrow": 1.2, "arrow_alpha": 0.6, "ring_alpha": 0.14}
## Gamepad. deadzone: how far a stick must lean to count, so a worn one doesn't drift. aim_hold: seconds
## the tools keep pointing after you let go of the right stick.
## stick_wake and mouse_wake: how far a push, or how many pixels of mouse, swaps the two. rumble_from:
## the smallest screen shake felt in the hands, for rumble_time seconds.
const PAD := {"deadzone": 0.25, "aim_hold": 0.6, "stick_wake": 0.5, "mouse_wake": 3.0,
	"rumble_from": 0.1, "rumble_time": 0.16}
## The map. wall: how many cubes of rock it shows past what you have opened or seen. floor: open ground
## you know; rock is its own colour darkened by rock_dim. mini_size: the minimap's side in pixels,
## covering mini_range metres each way. zooms: pixels per cube on the full map, starting at zoom.
## hold: seconds on the map button that count as holding it (it closes on release) rather than a tap
## (it stays open). opacities: the full map's settings, opacity the first one; shade darkens the game
## under the full map by that share of its opacity, so the map reads over a busy screen. budget:
## milliseconds a frame may spend redrawing it; every: seconds before the same piece is redrawn again.
const MAP := {"wall": 2.0, "floor": Color(0.86, 0.81, 0.71), "rock_dim": 0.5, "mini_size": 200.0, "mini_range": 36.0,
	"zooms": [1.0, 2.0, 4.0, 8.0], "zoom": 2, "shade": 0.5, "hold": 0.3, "opacities": [0.35, 0.5, 0.65, 0.8, 1.0], "opacity": 0.65,
	"budget": 0.6, "every": 0.1}

## The objectives panel in a run: always the two main goals, the steps that finish the map (the guardians, then the Heart, bars in
## map_color), and below them the `shown` unfinished goals nearest to done, counting this run so far, which come and go as
## refreshed every `every` seconds. width: pixels. bg: the panel's backing, so the text reads over bright rock.
const OBJECTIVES := {"shown": 3, "every": 0.25, "width": 330.0, "bg": Color(0.04, 0.04, 0.06, 0.55), "map_color": Color(0.4, 0.9, 1.0)}

## regen: health per second once nothing has hurt you for regen_after seconds.
const DIGGER := {"speed": 7.5, "pickup": 3.5, "hp": 100.0, "invuln": 0.8, "level_heal": 30.0, "regen": 3.0, "regen_after": 4.0, "color": Color(0.2, 0.75, 0.8)}

## Enemies, in the order of Enemies.CRAWLER and friends. knock: how far hits push it. Bodies stay dark
## so they never pass for gems; shine is the colour of the gem they drop.
const ENEMY_ORDER := ["crawler", "brute", "burrower", "runner", "borer", "brood"]
const ENEMIES := {
	"crawler": {"hp": 8.0, "speed": 4.6, "radius": 0.34, "dmg": 4.0, "gem": 0.3, "score": 30, "knock": 1.0, "color": Color(0.34, 0.1, 0.13), "shine": Color(0.95, 0.2, 0.35)},
	"brute": {"hp": 130.0, "speed": 3.0, "radius": 0.8, "dmg": 15.0, "gem": 8.0, "score": 300, "knock": 0.2, "color": Color(0.2, 0.11, 0.32), "shine": Color(0.6, 0.3, 0.9)},
	"runner": {"hp": 5.0, "speed": 7.0, "radius": 0.3, "dmg": 3.0, "gem": 0.3, "score": 40, "knock": 1.2, "color": Color(0.36, 0.25, 0.08), "shine": Color(1.0, 0.8, 0.15)},
	"burrower": {"hp": 45.0, "speed": 3.8, "radius": 0.5, "dmg": 8.0, "gem": 3.0, "score": 120, "knock": 0.6, "color": Color(0.07, 0.24, 0.18), "shine": Color(0.1, 0.8, 0.55)},
	"borer": {"hp": 900.0, "speed": 3.6, "radius": 1.5, "dmg": 14.0, "gem": 0.0, "score": 5000, "knock": 0.0, "color": Color(0.85, 0.55, 0.2)},
	"brood": {"hp": 1600.0, "speed": 2.4, "radius": 2.0, "dmg": 18.0, "gem": 0.0, "score": 10000, "knock": 0.0, "color": Color(0.75, 0.2, 0.6)},
}
## Guardians come for you on a timer, in this order, and dig through rock to do it. at: seconds into
## the run, and never sooner than boss_gap seconds after the last one died. The Borer stops for `aim`
## seconds, then charges in a straight line at `charge` m/s for charge_time, every `every` seconds. The
## Brood throws `lob` gas bombs at you and drops `brood` crawlers around itself every `every` seconds.
const BOSSES := [
	{"enemy": "borer", "name": "THE BORER", "at": 210.0, "every": 5.0, "aim": 0.9, "charge": 16.0, "charge_time": 0.9},
	{"enemy": "brood", "name": "THE BROOD", "at": 420.0, "every": 4.5, "lob": 3, "brood": 12},
]
## nests: pockets of sleepers, radius in metres, never within safe_start of the start. They only fill
## once you are within nest_fill metres, since the mine holds far more than you ever meet. Enemies get
## tougher per rock band (hp_band, dmg_band). Everything that arrives (burrowers, the swarm, hordes,
## bosses) starts off screen: spawn_margin metres past the edge of what the camera shows, and up to
## spawn_depth metres further. burrow_*: burrowers tunnel in, first after burrow_from seconds, then
## every burrow_every seconds, less with depth.
## spike_cycle: seconds per up-and-down, spike_up of them dangerous, spike_warn of warning before.
## gas_fuse: seconds from breaking gas rock to the blast. gas_merge: metres one fuse covers.
## The swarm is what surrounds you, as in VS: crawlers that dig. swarm_*: from swarm_from seconds, every
## swarm_every seconds, swarm_size (plus swarm_size_ramp per second) arrive, while fewer than
## swarm_alive (plus swarm_alive_ramp per second, up to swarm_max) are awake.
## horde_*: from horde_from seconds, every horde_every, horde_waves full rings of horde_size (plus
## horde_ramp per second, up to horde_max) close in, horde_gap seconds apart.
## Enemies keep up with you. hard_power: their health follows your strongest tool's damage multiplier
## to this power, so 1.0 keeps hits-to-kill steady at any strength. Per upgrade you own past the first
## free_upgrades (tool and boost levels): tough_per adds to their health, crowd_per to how many come,
## pace_per to their speed up to pace_max, harm_per to their damage, nudge_per makes them harder to
## push back, and runner_per to the share of the swarm that are runners, up to runner_max.
const THREATS := {
	"safe_start": 20.0, "nests": 220, "nest_fill": 50.0, "nest_min": 2.5, "nest_max": 5.0, "nest_size": 10, "nest_band": 2, "brutes_from": 3,
	"hp_band": 0.2, "dmg_band": 0.1, "wake_every": 0.2, "wake_range": 12.0, "knock": 8.0, "knock_max": 12.0, "knock_decay": 26.0,
	"burrow_from": 60.0, "burrow_every": 22.0, "burrow_min": 7.0, "carve_every": 0.12,
	"spike_patches": 80, "spike_cycle": 2.6, "spike_up": 0.9, "spike_warn": 0.5, "spike_dmg": 8.0,
	"gas_blobs": 150, "gas_fuse": 0.9, "gas_radius": 3.0, "gas_merge": 3.0, "gas_dmg": 18.0, "gas_hurts_enemies": 150.0,
	"swarm_from": 20.0, "swarm_every": 1.2, "swarm_size": 2.0, "swarm_size_ramp": 0.012, "spawn_margin": 2.5, "spawn_depth": 3.0,
	"swarm_alive": 25.0, "swarm_alive_ramp": 0.3, "swarm_max": 430.0,
	"horde_from": 75.0, "horde_every": 55.0, "horde_size": 40.0, "horde_ramp": 0.12, "horde_max": 320.0, "horde_waves": 3, "horde_gap": 4.0,
	"hard_power": 1.0, "free_upgrades": 8, "tough_per": 0.04, "crowd_per": 0.05, "pace_per": 0.012, "pace_max": 1.45,
	"harm_per": 0.02, "nudge_per": 0.05, "runner_per": 0.012, "runner_max": 0.45,
}

## start_clear: open radius around the start. cave_at, ore_at: noise levels above which there is a
## cave or ore (higher = rarer). band_width: metres per rock band; band_warp bends their edges.
## crystals: crystal blobs in the world, radius in cubes. chain_delay: seconds between links of a
## chain reaction. shake: how far a hit cube rattles. *_wave: metres per second a hit spreads at.
## level_blast: radius cleared by a level-up. big_pop: pops in one frame that earn a hitstop, at most
## once per big_pop_every seconds. Fog of war: light is how far your sight reaches along open ground in
## metres and how far your lamp shines. fog_bands is how thick each ring of fog is (0-1), from the clear
## rim outward, each fog_band cubes wide after a clear fog_rim, measured from everywhere you have opened
## or seen. fog_reach: how many cubes into the fog tools can dig. fog_tint: how much the fog cools what
## is under it. fog_dim: how much darker places out of your lamp's reach get (0-1). haze: how thick
## the air gets toward the edge of your lamp. scan_every: seconds between sight updates. draw_chunks:
## how many chunks around you are drawn.
const WORLD := {
	"start_clear": 3.5, "cave_at": 0.5, "band_width": 33.0, "band_warp": 12.0, "ore_at": 0.52,
	"crystals": 350, "crystal_min": 2, "crystal_max": 5, "chain_delay": 0.028, "shake": 0.05,
	"swing_wave": 22.0, "blast_wave": 20.0, "level_blast": 3.5, "big_pop": 16, "big_pop_every": 0.6,
	"light": 10.0, "fog_bands": [0.0, 0.25, 0.42, 0.58, 0.72, 0.84, 0.93, 1.0], "fog_band": 1.3, "fog_rim": 0.7, "fog_reach": 7.0,
	"fog_tint": 0.1, "fog_dim": 0.4, "haze": 0.15, "scan_every": 0.05, "draw_chunks": 3,
}

## The goal of a run and how it ends. gem_xp and gem_bank: what one gem's worth gives in XP and in
## banked gems. heart_dist: metres from the start, heart_r: its size in cubes. heart_hit: the most one
## hit can take off a Heart cube, so nothing skips the fight. heart_bonus: gems for breaking it.
## heart_horde: seconds between hordes once it wakes. Nothing points at the Heart. Its veins run out
## from it, vein_arms of them, vein_len metres long and vein_r cubes thick at the Heart, thinning to
## nothing. Within heart_hear metres you hear it beat, faster and louder the closer you get.
## boss_gap, boss_range: see BOSSES, and how far off a boss starts; boss_leash keeps it from losing
## you. A dead boss leaves boss_gems gems worth boss_gem each, and boss_levels free level-ups.
## Fuel seams: seams of them, seam_min to seam_max metres long. Once lit they burn at seam_burn seconds
## per cube; every seam_every cubes the fire blasts seam_r metres around for seam_dmg to rock and
## enemies. seam_hurt is what it does to you within that reach.
## Cave-ins: cave_blobs patches of pale loose rock. Break one and after cave_warn seconds rubble drops
## on all open ground within cave_r metres, except cave_spare metres around you. It does cave_crush
## (times how tough enemies are right now) to enemies there, and cave_hurt to you.
## lifts: how many, lift_min to lift_max metres out; lift_pad is their radius and
## lift_hold how long you stand there; lifts run from lift_from seconds, so nobody leaves by accident
## while digging at the start. death_keep: share of your gems you keep without a lift.
## geodes: how many hard shells full of gems, radius in cubes; geode_band adds to their worth per rock
## band; geode_xp is the share of their worth that counts as XP, so a burst pays gems, not ten level-ups.
## glint_range: metres at which treasure sparkles through the fog and rock. vaults, shrines,
## relic_rooms: how many of each per run, room_gap metres apart. site_use: metres from a shrine or
## relic at which you use it.
const RUN := {
	"gem_xp": 0.35, "gem_bank": 0.12,
	"heart_dist": 190.0, "heart_r": 5, "heart_hit": 25.0, "heart_bonus": 500, "heart_horde": 12.0,
	"vein_arms": 7, "vein_len": 130.0, "vein_r": 3.0, "heart_hear": 120.0,
	"boss_gap": 90.0, "boss_range": 24.0, "boss_leash": 45.0, "boss_gems": 40, "boss_gem": 12.0, "boss_levels": 2,
	"seams": 60, "seam_min": 40.0, "seam_max": 110.0, "seam_burn": 0.05, "seam_every": 4, "seam_r": 1.6, "seam_dmg": 60.0, "seam_hurt": 6.0,
	"cave_blobs": 500, "cave_r": 5.0, "cave_warn": 0.8, "cave_spare": 1.4, "cave_crush": 400.0, "cave_hurt": 12.0,
	"lifts": 15, "lift_min": 40.0, "lift_max": 215.0,
	"lift_pad": 1.7, "lift_hold": 1.5, "lift_from": 30.0, "death_keep": 0.5,
	"geodes": 120, "geode_min": 2, "geode_max": 3, "geode_band": 0.3, "geode_xp": 0.4, "glint_range": 20.0,
	"vaults": 40, "shrines": 14, "relic_rooms": 2, "room_gap": 12.0, "site_use": 1.4,
}
## Shrines give something and take something, for this run.
const SHRINES := {
	"blood": {"name": "Blood Shrine", "desc": "Lose half your health now. Two free upgrades.", "color": Color(0.9, 0.15, 0.25)},
	"greed": {"name": "Greed Shrine", "desc": "+50% gems this run. Enemies hit 30% harder.", "color": Color(1.0, 0.8, 0.2)},
	"wind": {"name": "Wind Shrine", "desc": "+20% move speed this run. -25% max health.", "color": Color(0.4, 0.9, 1.0)},
}
## A maxed tool plus EVOLVE_BOOST levels of its boost turns into something new at the next level-up.
const EVOLVE_BOOST := 3
const EVOLUTIONS := {
	"shovel": {"boost": "reach", "name": "Great Scoop", "desc": "Swings all the way around you. +50% damage.", "dmg": 1.5, "arc": PI},
	"drill": {"boost": "haste", "name": "Tunnel Borer", "desc": "Bores a corridor three times wider. +50% damage.", "dmg": 1.5, "width": 1.5},
	"bombs": {"boost": "power", "name": "Cluster Bombs", "desc": "Every blast throws four smaller ones.", "dmg": 1.0, "cluster": 4},
	"spark": {"boost": "magnet", "name": "Storm Coil", "desc": "Twice as many jumps. +50% damage.", "dmg": 1.5, "hops": 2},
	"moles": {"boost": "tough", "name": "Mole Army", "desc": "Two more moles, biting twice as hard.", "dmg": 2.0, "extra": 2},
}
## A long combo starts a Frenzy: every cube pops in one hit for `time` seconds, score times `score`.
## at: how much combo it takes, counted from the end of the last Frenzy. Then at least `rest` seconds
## until the next one.
const FRENZY := {"at": 800, "time": 5.0, "rest": 15.0, "score": 2.0, "color": Color(1.0, 0.8, 0.2)}
## Permanent upgrades bought with banked gems. value: per level. cost: the first level; each next one
## costs `grow` times more. Keep the whole shop reachable in hours, not days (owner: no 80-hour grind).
const SHOP := {
	"power": {"name": "Sharper Edge", "desc": "+6% digging damage", "value": 0.06, "max": 5, "cost": 240, "grow": 2.0},
	"health": {"name": "Hard Hat", "desc": "+15 max health", "value": 15.0, "max": 5, "cost": 200, "grow": 2.0},
	"legs": {"name": "Good Boots", "desc": "+3% move speed", "value": 0.03, "max": 5, "cost": 200, "grow": 2.0},
	"magnet": {"name": "Long Reach", "desc": "+12% pickup range", "value": 0.12, "max": 5, "cost": 150, "grow": 2.0},
	"greed": {"name": "Deep Pockets", "desc": "+8% gems found", "value": 0.08, "max": 5, "cost": 300, "grow": 2.0},
	"cover": {"name": "Insurance", "desc": "+6% gems kept if you don't get out", "value": 0.06, "max": 5, "cost": 260, "grow": 2.0},
	"slots": {"name": "Tool Belt", "desc": "+1 tool slot and +1 boost slot", "value": 1.0, "max": 2, "cost": 500, "grow": 3.0},
}
## How many different tools and boosts a run can hold, the starting tool included, before the Tool Belt.
## Once a kind is full, cards only offer levels of what you hold (owner: start with 4, up to 6).
const SLOTS := {"tools": 4, "boosts": 4}

## Who digs: a starting tool and one rule. hp, speed and gems multiply the base numbers. no_aim: tools
## point where you drive and the mouse does nothing. Locked ones open through Defs.GOALS.
const CHARACTERS := {
	"digger": {"name": "Digger", "desc": "Shovel. No tricks.", "tool": "shovel", "color": Color(0.2, 0.75, 0.8)},
	"prospector": {"name": "Prospector", "desc": "Shovel. Double gems, half health.", "tool": "shovel", "gems": 2.0, "hp": 0.5,
		"color": Color(0.95, 0.75, 0.2), "locked": true},
	"rig": {"name": "Rig", "desc": "Drill. Goes where you drive, no aiming. Tough but slow.", "tool": "drill", "hp": 1.6, "speed": 0.85,
		"no_aim": true, "color": Color(0.85, 0.4, 0.2), "locked": true},
}

## Lifetime goals, the list you work through. stat: a key of the profile's stats. A goal pays gems, an
## unlock, or both. The "unlock" keys match Profile.unlocked: "tool:<id>" or "char:<id>".
const GOALS := [
	{"id": "lift", "text": "Get out by lift", "stat": "lifts", "need": 1, "unlock": "tool:bombs"},
	{"id": "geodes", "text": "Open 5 geodes", "stat": "geodes", "need": 5, "gems": 100},
	{"id": "stone", "text": "Reach the Stone layer", "stat": "band", "need": 3, "unlock": "char:prospector"},
	{"id": "frenzies", "text": "Set off 3 Frenzies", "stat": "frenzies", "need": 3, "gems": 150},
	{"id": "cubes", "text": "Break 25,000 cubes", "stat": "cubes", "need": 25000, "unlock": "tool:pulse"},
	{"id": "kills", "text": "Kill 3,000 enemies", "stat": "kills", "need": 3000, "gems": 200},
	{"id": "boss", "text": "Kill a boss", "stat": "bosses", "need": 1, "unlock": "tool:spark"},
	{"id": "seams", "text": "Burn 5 fuel seams", "stat": "seams", "need": 5, "unlock": "tool:moles"},
	{"id": "banked", "text": "Bank 3,000 gems in total", "stat": "banked", "need": 3000, "unlock": "char:rig"},
	{"id": "basalt", "text": "Reach the Basalt layer", "stat": "band", "need": 5, "gems": 300},
	{"id": "combo", "text": "Reach a x3,000 combo", "stat": "combo", "need": 3000, "gems": 300},
	{"id": "relics", "text": "Find 3 relics", "stat": "relics", "need": 3, "gems": 400},
	{"id": "evolve", "text": "Evolve a tool", "stat": "evolutions", "need": 1, "gems": 300},
	{"id": "crushed", "text": "Crush 50 enemies in cave-ins", "stat": "crushed", "need": 50, "gems": 250},
	{"id": "bosses", "text": "Kill 5 bosses", "stat": "bosses", "need": 5, "gems": 800},
	{"id": "heart", "text": "Break the Heart", "stat": "hearts", "need": 1, "gems": 1000},
]

## Dug up once, kept forever. Either unlocks something or adds value to a shop bonus for good.
const RELICS := {
	"lens": {"name": "Strange Lens", "desc": "Mining Beam unlocked", "unlock": "tool:beam"},
	"idol": {"name": "Gold Idol", "desc": "+10% gems found, for good", "bonus": "greed", "value": 0.1},
	"boots": {"name": "Worn Boots", "desc": "+5% move speed, for good", "bonus": "legs", "value": 0.05},
	"charm": {"name": "Lucky Charm", "desc": "+25 max health, for good", "bonus": "health", "value": 25.0},
	"stone": {"name": "Whetstone", "desc": "+10% digging damage, for good", "bonus": "power", "value": 0.1},
}

## Lifetime stats that keep the best run instead of adding up.
const BEST_STATS := ["band", "combo"]

## Index = cube kind, 0 is empty. xp is earned on the spot, gem drops a shiny of that worth. Every
## shiny mineral always drops its gem. ring: pitch of the hit sound. chain: goes off with the same kind
## touching it.
const BEDROCK := 14
const CRYSTAL := 13
const GAS := 15
const HEART := 16
const GEODE := 17
const VAULT := 18
const FUEL := 19
const VEIN := 20
const LOOSE := 21
const RUBBLE := 22
const CUBES := [
	{},
	{"name": "Dirt", "hp": 10.0, "color": Color(0.56, 0.38, 0.23), "xp": 0.01, "score": 1, "ring": 0.8},
	{"name": "Clay", "hp": 15.0, "color": Color(0.68, 0.42, 0.28), "xp": 0.012, "score": 1, "ring": 0.9},
	{"name": "Sandstone", "hp": 22.0, "color": Color(0.8, 0.65, 0.4), "xp": 0.015, "score": 2, "ring": 1.0},
	{"name": "Gravel", "hp": 28.0, "color": Color(0.52, 0.5, 0.47), "xp": 0.02, "score": 2, "ring": 1.1},
	{"name": "Stone", "hp": 40.0, "color": Color(0.46, 0.47, 0.52), "xp": 0.025, "score": 3, "ring": 1.3},
	{"name": "Slate", "hp": 55.0, "color": Color(0.3, 0.34, 0.42), "xp": 0.03, "score": 4, "ring": 1.4},
	{"name": "Basalt", "hp": 80.0, "color": Color(0.22, 0.21, 0.26), "xp": 0.04, "score": 6, "ring": 1.6},
	{"name": "Magma Rock", "hp": 110.0, "color": Color(0.42, 0.15, 0.1), "xp": 0.05, "score": 8, "ring": 1.7},
	{"name": "Copper", "hp": 18.0, "color": Color(0.95, 0.5, 0.2), "xp": 0.0, "score": 10, "ring": 1.5, "gem": 1},
	{"name": "Silver", "hp": 40.0, "color": Color(0.55, 0.75, 1.0), "xp": 0.0, "score": 20, "ring": 1.7, "gem": 2},
	{"name": "Gold", "hp": 60.0, "color": Color(1.0, 0.8, 0.15), "xp": 0.0, "score": 40, "ring": 1.9, "gem": 4},
	{"name": "Ruby", "hp": 90.0, "color": Color(0.95, 0.12, 0.25), "xp": 0.0, "score": 70, "ring": 2.1, "gem": 7},
	{"name": "Crystal", "hp": 12.0, "color": Color(0.55, 0.35, 1.0), "xp": 0.0, "score": 15, "ring": 2.0, "gem": 0.15, "chain": true},
	{"name": "Bedrock", "hp": 1e9, "color": Color(0.08, 0.07, 0.08), "xp": 0.0, "score": 0},
	{"name": "Gas Rock", "hp": 8.0, "color": Color(0.62, 0.68, 0.32), "xp": 0.01, "score": 5, "ring": 0.7, "chain": true, "gas": true},
	{"name": "Heart", "hp": 6000.0, "color": Color(1.0, 0.15, 0.45), "xp": 0.0, "score": 2000, "ring": 0.6, "heart": true},
	{"name": "Geode", "hp": 150.0, "color": Color(0.25, 0.95, 0.8), "xp": 0.0, "score": 60, "ring": 2.3, "gem": 4.0, "chain": true, "geode": true},
	{"name": "Vault Wall", "hp": 130.0, "color": Color(0.62, 0.55, 0.35), "xp": 0.02, "score": 5, "ring": 1.8},
	{"name": "Fuel", "hp": 20.0, "color": Color(1.0, 0.42, 0.0), "xp": 0.01, "score": 5, "ring": 0.6, "chain": true, "fuel": true},
	{"name": "Heart Vein", "hp": 35.0, "color": Color(0.72, 0.12, 0.34), "xp": 0.03, "score": 8, "ring": 0.5},
	{"name": "Loose Rock", "hp": 6.0, "color": Color(0.8, 0.78, 0.68), "xp": 0.0, "score": 2, "ring": 0.7, "chain": true, "loose": true},
	{"name": "Rubble", "hp": 6.0, "color": Color(0.34, 0.31, 0.28), "xp": 0.0, "score": 1, "ring": 0.6},
]
## Rock changes every band_width metres out from the start.
const BANDS := [
	{"name": "TOPSOIL", "rock": [1, 2], "ore": 9},
	{"name": "SANDSTONE", "rock": [2, 3], "ore": 9},
	{"name": "GRAVEL BEDS", "rock": [3, 4], "ore": 10},
	{"name": "STONE", "rock": [4, 5], "ore": 10},
	{"name": "SLATE", "rock": [5, 6], "ore": 11},
	{"name": "BASALT", "rock": [6, 7], "ore": 12},
	{"name": "MAGMA ROCK", "rock": [7, 8], "ore": 12},
]

## Tools work by themselves. dmg, size and cd are level 1; *_up is what each level adds (cd_up
## multiplies). size means: shovel reach, drill length, saw orbit, blast radius, beam length, how far
## sparks reach, how far moles roam.
## The drill also shows its strip: strip is its opacity, strip_speed how many chevrons pass a point each second.
## Bombs fly up to throw metres, at one of the pick closest awake enemies, else at the nearest rock,
## rock within ahead degrees of your aim first. With neither in reach they look again after retry seconds.
const TOOLS := {
	"shovel": {"name": "Shovel", "desc": "Swings at everything in front of you.", "color": Color(0.8, 0.82, 0.86),
		"dmg": 9.0, "dmg_up": 0.4, "size": 2.4, "size_up": 0.12, "cd": 0.3, "cd_up": 0.95, "arc": 1.15},
	"drill": {"name": "Drill", "desc": "Bores straight ahead, nonstop.", "color": Color(1.0, 0.6, 0.2),
		"dmg": 3.0, "dmg_up": 0.4, "size": 4.0, "size_up": 0.15, "cd": 0.065, "cd_up": 0.95,
		"strip": 0.75, "strip_speed": 2.5},
	"saws": {"name": "Saw Blades", "desc": "Blades circle you and cut what they touch.", "color": Color(0.9, 0.9, 0.95),
		"dmg": 8.0, "dmg_up": 0.4, "size": 3.0, "size_up": 0.1, "cd": 0.09, "cd_up": 1.0, "spin": 5.0, "cut": 0.7},
	"bombs": {"name": "Bombs", "desc": "Thrown at a nearby enemy, or into rock. Boom.", "color": Color(1.0, 0.3, 0.2), "locked": true,
		"dmg": 60.0, "dmg_up": 0.4, "size": 3.0, "size_up": 0.12, "cd": 2.2, "cd_up": 0.93, "throw": 8.0, "pick": 3,
		"ahead": 45.0, "retry": 0.2},
	"pulse": {"name": "Shock Pulse", "desc": "A ring bursts out from you.", "color": Color(0.5, 0.75, 1.0), "locked": true,
		"dmg": 30.0, "dmg_up": 0.4, "size": 5.0, "size_up": 0.12, "cd": 3.0, "cd_up": 0.93, "ring_time": 0.35},
	"beam": {"name": "Mining Beam", "desc": "A long line of rock pops at once.", "color": Color(0.4, 1.0, 0.7), "locked": true,
		"dmg": 40.0, "dmg_up": 0.4, "size": 14.0, "size_up": 0.12, "cd": 2.4, "cd_up": 0.93},
	"spark": {"name": "Spark Coil", "desc": "Lightning jumps from enemy to enemy, or bites rock.", "color": Color(0.7, 0.75, 1.0), "locked": true,
		"dmg": 16.0, "dmg_up": 0.4, "size": 9.0, "size_up": 0.1, "cd": 1.0, "cd_up": 0.93, "hops": 3, "bite": 1.2},
	"moles": {"name": "Mole Pack", "desc": "Little moles chew their own tunnels around you.", "color": Color(0.8, 0.6, 0.35), "locked": true,
		"dmg": 7.0, "dmg_up": 0.4, "size": 8.0, "size_up": 0.12, "cd": 0.14, "cd_up": 0.97, "speed": 7.0, "bite": 0.9},
}

## value: per level, added to 100%. haste multiplies cooldowns instead.
const BOOSTS := {
	"power": {"name": "Hard Edge", "desc": "+15% digging damage", "value": 0.15, "color": Color(1.0, 0.3, 0.2)},
	"reach": {"name": "Long Handle", "desc": "+8% tool size", "value": 0.08, "color": Color(1.0, 0.6, 0.2)},
	"haste": {"name": "Quick Hands", "desc": "-7% tool cooldowns", "value": 0.93, "color": Color(0.3, 0.9, 0.5)},
	"legs": {"name": "Light Boots", "desc": "+8% move speed", "value": 0.08, "color": Color(0.2, 0.95, 0.9)},
	"magnet": {"name": "Magnet", "desc": "+40% pickup range", "value": 0.4, "color": Color(0.3, 0.6, 1.0)},
	"tough": {"name": "Thick Skin", "desc": "+20 max health", "value": 20.0, "color": Color(0.95, 0.3, 0.35)},
}


## The Dash Drive takes one tool slot, and unlike every tool it is a button (Space, Shift or the gamepad's A):
## a short, untouchable burst of speed the way you move, or the way you last moved when you stand still.
## base: speed (m/s) for time (s), then grace more seconds of invulnerability, then cooldown (s).
## It levels up like a tool, one card per level (owner): levels[n] is level n + 1, with the card's text
## and the steps it adds. step: what one step of each is worth (length is dash time, speed dash speed,
## recharge a cut to the cooldown, clone_hp clone health). clone puts the decoy clone in, clone_boom makes
## it explode, and its second and later steps make the blast bigger.
const DASH := {
	"name": "Dash Drive", "desc": "Space or Shift: a burst of speed the way you move. Untouchable while it lasts.",
	"hint": "Takes a tool slot.", "color": Color(0.35, 0.9, 1.0),
	"base": {"speed": 30.0, "time": 0.2, "grace": 0.15, "cooldown": 3.0},
	"step": {"length": 0.2, "speed": 0.15, "recharge": 0.15, "clone_hp": 0.5},
	"levels": [
		{"desc": "", "add": {}},
		{"desc": "+20% dash time and -15% cooldown", "add": {"length": 1, "recharge": 1}},
		{"desc": "Dashing leaves a clone where you stood. Enemies attack it until it falls. +15% dash speed", "add": {"clone": 1, "speed": 1}},
		{"desc": "+20% dash time, -15% cooldown, +50% clone health", "add": {"length": 1, "recharge": 1, "clone_hp": 1}},
		{"desc": "The clone explodes when it falls. +15% dash speed", "add": {"clone_boom": 1, "speed": 1}},
		{"desc": "-15% cooldown, +50% clone health, +40% blast damage and a wider blast", "add": {"recharge": 1, "clone_hp": 1, "clone_boom": 1}},
	],
	# The clone: health is a share of your max health, it stays life seconds, and enemies pick it over you
	# when it is closer than taunt times their distance to you. It takes a hit at most every hit_gate
	# seconds, like you. The blast comes with clone_boom, and each step of it past the first adds the *_up
	# shares. Blast damage and size grow with Hard Edge and Long Handle, as a tool's do.
	"clone": {"hp_frac": 1.2, "life": 8.0, "taunt": 0.7, "hit_gate": 0.2,
		"boom_dmg": 100.0, "boom_radius": 3.5, "boom_dmg_up": 0.4, "boom_radius_up": 0.12},
}


static func enemy_def(type_id: int) -> Dictionary:
	return ENEMIES[ENEMY_ORDER[type_id]]


## "Shock Pulse" for "tool:pulse", "Rig" for "char:rig".
static func unlock_name(key: String) -> String:
	var parts := key.split(":")
	return (TOOLS if parts[0] == "tool" else CHARACTERS)[parts[1]]["name"]


static func reward_text(goal: Dictionary) -> String:
	var bits: Array[String] = []
	if goal.has("unlock"):
		bits.append(unlock_name(goal["unlock"]))
	if goal.has("gems"):
		bits.append("%d gems" % goal["gems"])
	return " + ".join(bits)


## What it takes to unlock this.
static func goal_for(key: String) -> String:
	for g in GOALS:
		if g.get("unlock", "") == key:
			return g["text"]
	return "find it in the rock"


## Restarts a countdown that has run out. It keeps the part of this frame that went past zero, so how often
## something fires doesn't depend on the frame rate, but never more than one frame, so a tool that waited
## for something to hit starts a fresh countdown.
static func restart(left: float, every: float, delta: float) -> float:
	return every + maxf(left, -delta)


static func xp_to_next(level: int) -> int:
	return 24 + (level - 1) * 10 + maxi(0, level - 15) * 10
