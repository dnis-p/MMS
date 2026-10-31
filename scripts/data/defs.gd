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

const DIGGER := {"speed": 7.5, "pickup": 3.5, "color": Color(0.2, 0.75, 0.8)}

## start_clear: open radius around the start. cave_at, ore_at: noise levels above which there is a
## cave or ore (higher = rarer). band_width: metres per rock band; band_warp bends their edges.
## geodes: crystal blobs in the world, radius in cubes. chain_delay: seconds between links of a
## chain reaction. shake: how far a hit cube rattles. *_wave: metres per second a hit spreads at.
## level_blast: radius cleared by a level-up. big_pop: pops in one frame that earn a hitstop, at most
## once per big_pop_every seconds. Fog of war: light is how far you see in metres, see_into how many
## cubes of rock your light gets through, memory how bright places you have seen stay (0-1), haze how
## thick the air gets at the edge of your light (0-1), scan_every the seconds between sight updates.
const WORLD := {
	"start_clear": 3.5, "cave_at": 0.5, "band_width": 13.0, "band_warp": 6.0, "ore_at": 0.52,
	"geodes": 55, "geode_min": 2, "geode_max": 5, "chain_delay": 0.028, "shake": 0.05,
	"swing_wave": 22.0, "blast_wave": 20.0, "level_blast": 5.5, "big_pop": 16, "big_pop_every": 0.6,
	"light": 10.0, "see_into": 4, "memory": 0.13, "haze": 0.4, "scan_every": 0.05,
}

## Index = cube kind, 0 is empty. xp is earned on the spot, gem drops a shiny worth that much XP.
## Every shiny mineral always drops its gem. ring: pitch of the hit sound. chain: goes off with the
## same kind touching it.
const BEDROCK := 14
const CRYSTAL := 13
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
}


static func xp_to_next(level: int) -> int:
	return 14 + (level - 1) * 10 + maxi(0, level - 20) * 8
