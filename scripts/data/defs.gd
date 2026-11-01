class_name Defs
## All tunable game content lives here so balancing is just editing numbers.

const MAX_TOOL_LEVEL := 6
const MAX_BOOST_LEVEL := 5
const COMBO_WINDOW := 1.2
const FILLER_SCORE := 500

## Camera, fixed orientation, relative to the digger: metres south, metres up, and how many
## seconds of travel it looks ahead. aim_lead: share of the way to the pointer it leans, up to
## aim_lead_max metres.
const CAMERA := {"back": 7.0, "up": 19.0, "lead": 0.12, "aim_lead": 0.18, "aim_lead_max": 3.0, "fov": 60.0}

const DIGGER := {"speed": 7.5, "pickup": 3.5, "hp": 100.0, "invuln": 0.8, "level_heal": 30.0, "color": Color(0.2, 0.75, 0.8)}

## Enemies, in the order of Enemies.CRAWLER and friends. knock: how far hits push it.
const ENEMY_ORDER := ["crawler", "brute", "burrower", "runner"]
const ENEMIES := {
	"crawler": {"hp": 8.0, "speed": 4.6, "radius": 0.34, "dmg": 4.0, "gem": 0.3, "score": 30, "knock": 1.0, "color": Color(0.85, 0.15, 0.3)},
	"brute": {"hp": 130.0, "speed": 3.0, "radius": 0.8, "dmg": 15.0, "gem": 8.0, "score": 300, "knock": 0.2, "color": Color(0.5, 0.2, 0.75)},
	"runner": {"hp": 5.0, "speed": 7.0, "radius": 0.3, "dmg": 3.0, "gem": 0.3, "score": 40, "knock": 1.2, "color": Color(1.0, 0.8, 0.15)},
	"burrower": {"hp": 45.0, "speed": 3.8, "radius": 0.5, "dmg": 8.0, "gem": 3.0, "score": 120, "knock": 0.6, "color": Color(0.1, 0.65, 0.45)},
}
## nests: pockets of sleepers, radius in metres, never within safe_start of the start. Enemies get
## tougher per rock band (hp_band, dmg_band). burrow_*: burrowers tunnel in from burrow_range metres
## away, first after burrow_from seconds, then every burrow_every seconds, less with depth.
## spike_cycle: seconds per up-and-down, spike_up of them dangerous, spike_warn of warning before.
## gas_fuse: seconds from breaking gas rock to the blast. gas_merge: metres one fuse covers.
## The swarm is what surrounds you, as in VS: crawlers that dig. swarm_*: from swarm_from seconds, every
## swarm_every seconds, swarm_size (plus swarm_size_ramp per second) arrive from swarm_range metres
## away, while fewer than swarm_alive (plus swarm_alive_ramp per second, up to swarm_max) are awake.
## horde_*: from horde_from seconds, every horde_every, a full ring of horde_size (plus horde_ramp per
## second, up to horde_max) closes in from horde_range metres.
## Enemies keep up with you. hard_power: their health follows your strongest tool's damage multiplier
## to this power, so 1.0 keeps hits-to-kill steady at any strength. Per upgrade you own past the first
## free_upgrades (tool and boost levels): tough_per adds to their health, crowd_per to how many come,
## pace_per to their speed up to pace_max, harm_per to their damage, nudge_per makes them harder to
## push back, and runner_per to the share of the swarm that are runners, up to runner_max.
const THREATS := {
	"safe_start": 20.0, "nests": 80, "nest_min": 2.5, "nest_max": 5.0, "nest_size": 10, "nest_band": 3, "brutes_from": 2,
	"hp_band": 0.3, "dmg_band": 0.15, "wake_every": 0.2, "wake_range": 12.0, "knock": 8.0, "knock_max": 12.0, "knock_decay": 26.0,
	"burrow_from": 40.0, "burrow_every": 22.0, "burrow_min": 7.0, "burrow_range": 18.0, "carve_every": 0.12,
	"spike_patches": 15, "spike_cycle": 2.6, "spike_up": 0.9, "spike_warn": 0.5, "spike_dmg": 8.0,
	"gas_blobs": 22, "gas_fuse": 0.9, "gas_radius": 3.0, "gas_merge": 3.0, "gas_dmg": 18.0, "gas_hurts_enemies": 150.0,
	"swarm_from": 12.0, "swarm_every": 1.2, "swarm_size": 2.0, "swarm_size_ramp": 0.04, "swarm_range": 15.0,
	"swarm_alive": 25.0, "swarm_alive_ramp": 0.6, "swarm_max": 430.0,
	"horde_from": 35.0, "horde_every": 40.0, "horde_size": 45.0, "horde_ramp": 0.35, "horde_max": 320.0, "horde_range": 13.0,
	"hard_power": 1.0, "free_upgrades": 8, "tough_per": 0.04, "crowd_per": 0.05, "pace_per": 0.012, "pace_max": 1.45,
	"harm_per": 0.02, "nudge_per": 0.05, "runner_per": 0.012, "runner_max": 0.45,
}

## start_clear: open radius around the start. cave_at, ore_at: noise levels above which there is a
## cave or ore (higher = rarer). band_width: metres per rock band; band_warp bends their edges.
## geodes: crystal blobs in the world, radius in cubes. chain_delay: seconds between links of a
## chain reaction. shake: how far a hit cube rattles. *_wave: metres per second a hit spreads at.
## level_blast: radius cleared by a level-up. big_pop: pops in one frame that earn a hitstop, at most
## once per big_pop_every seconds. Fog of war: light is how far you see in metres, rock_shade how bright
## each cube is by how deep it sits from open air (first entry touches the air, last is as deep as
## you can see), memory how bright places you have seen stay (0-1; rock broken in the dark flashes bright first), haze how
## thick the air gets at the edge of your light (0-1), scan_every the seconds between sight updates.
const WORLD := {
	"start_clear": 3.5, "cave_at": 0.5, "band_width": 13.0, "band_warp": 6.0, "ore_at": 0.52,
	"geodes": 55, "geode_min": 2, "geode_max": 5, "chain_delay": 0.028, "shake": 0.05,
	"swing_wave": 22.0, "blast_wave": 20.0, "level_blast": 5.5, "big_pop": 16, "big_pop_every": 0.6,
	"light": 10.0, "rock_shade": [1.0, 0.68, 0.42, 0.25, 0.14, 0.07, 0.025], "memory": 0.13, "haze": 0.4, "scan_every": 0.05,
}

## Index = cube kind, 0 is empty. xp is earned on the spot, gem drops a shiny worth that much XP.
## Every shiny mineral always drops its gem. ring: pitch of the hit sound. chain: goes off with the
## same kind touching it.
const BEDROCK := 14
const CRYSTAL := 13
const GAS := 15
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
## multiplies). size means: shovel reach, drill length, saw orbit, blast radius, beam length.
const TOOLS := {
	"shovel": {"name": "Shovel", "desc": "Swings at everything in front of you.", "color": Color(0.8, 0.82, 0.86),
		"dmg": 9.0, "dmg_up": 0.4, "size": 2.4, "size_up": 0.12, "cd": 0.3, "cd_up": 0.95, "arc": 1.15},
	"drill": {"name": "Drill", "desc": "Bores straight ahead, nonstop.", "color": Color(1.0, 0.6, 0.2),
		"dmg": 3.0, "dmg_up": 0.4, "size": 4.0, "size_up": 0.15, "cd": 0.05, "cd_up": 1.0},
	"saws": {"name": "Saw Blades", "desc": "Blades circle you and cut what they touch.", "color": Color(0.9, 0.9, 0.95),
		"dmg": 8.0, "dmg_up": 0.4, "size": 3.0, "size_up": 0.1, "cd": 0.09, "cd_up": 1.0, "spin": 5.0, "cut": 0.7},
	"bombs": {"name": "Bombs", "desc": "Thrown into nearby rock. Boom.", "color": Color(1.0, 0.3, 0.2),
		"dmg": 60.0, "dmg_up": 0.4, "size": 3.0, "size_up": 0.12, "cd": 2.2, "cd_up": 0.93, "throw": 8.0},
	"pulse": {"name": "Shock Pulse", "desc": "A ring bursts out from you.", "color": Color(0.5, 0.75, 1.0),
		"dmg": 30.0, "dmg_up": 0.4, "size": 5.0, "size_up": 0.12, "cd": 3.0, "cd_up": 0.93, "ring_time": 0.35},
	"beam": {"name": "Mining Beam", "desc": "A long line of rock pops at once.", "color": Color(0.4, 1.0, 0.7),
		"dmg": 40.0, "dmg_up": 0.4, "size": 14.0, "size_up": 0.12, "cd": 2.4, "cd_up": 0.93},
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


static func enemy_def(type_id: int) -> Dictionary:
	return ENEMIES[ENEMY_ORDER[type_id]]


static func xp_to_next(level: int) -> int:
	return 14 + (level - 1) * 10 + maxi(0, level - 20) * 8
