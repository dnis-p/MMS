class_name Defs
## All tunable game content lives here so balancing is just editing numbers.

const MAX_WEAPON_LEVEL := 5
const MAX_PASSIVE_LEVEL := 5
const MAX_WEAPON_SLOTS := 4
const MAX_PASSIVE_SLOTS := 4

## The boss turns up at a random moment in this window (seconds into the stage).
const BOSS_WINDOW := [90.0, 150.0]

const CRIT_CHANCE := 0.08
const CRIT_MULT := 2.0
const MAX_ALIVE := 420
const PICKUP_RADIUS := 6.0
const RAM_COOLDOWN := 0.4
const HIT_INVULN := 0.6
## Each armor point blocks this share of a hit, up to the cap.
const ARMOR_BLOCK := 0.06
const ARMOR_BLOCK_MAX := 0.6
const REPAIR_CHANCE := 0.02
const REPAIR_HEAL := 25
const STAGE_CLEAR_HEAL := 0.3
const FILLER_HEAL := 40.0
const FILLER_SCORE := 500
const COMBO_WINDOW := 2.5
const BOSS_KILL_SCORE := 5000

## Redline meter (0-1): fills while driving fast, drains when slow, drops when hit, and
## boosts fire rate and ram damage. When full, nitro fires by itself.
const REDLINE := {
	"fill": 0.09, "min_speed": 0.7, "drain": 0.35, "hit_loss": 0.3, "fire_bonus": 0.35, "ram_bonus": 1.5,
	"nitro_time": 2.5, "nitro_speed": 1.4, "nitro_ram": 4.0, "after_nitro": 0.25,
}

## Enemies hit by an attack are pushed away and stagger (walk slower) until the push fades.
## Each enemy type has its own "knock" factor; the push strength is set per weapon.
## Fast-firing weapons push less per hit, or the closest enemy flies out of reach.
const KNOCK := {"decay": 18.0, "stagger": 0.35, "max": 14.0, "ram": 16.0, "blast": 12.0}

## Map camera, fixed orientation, relative to the car: metres south, metres up,
## and how many seconds of travel it looks ahead.
const MAP_CAMERA := {"back": 9.0, "up": 30.0, "lead": 0.35, "fov": 60.0}

## Vehicle handling. Turn rates (radians per second) are per class. Grip is how fast the
## direction of travel catches up with the nose; high means almost no drift.
## steer_speed: how fast the front wheels turn (radians per second). Each class's "turn" is
## its turning radius in metres, measured at the rear axle.
const DRIVE := {"accel_time": 0.25, "brake_time": 0.15, "steer_speed": 6.0, "turn_slow": 0.2, "lean": 0.03}

## Spawn director. `t` below means seconds into the stage. Distances are metres from the car.
const SPAWN := {
	"rate_base": 3.0, "rate_ramp": 0.1,  # enemies per second = base + ramp * t, while below the alive target
	"alive_base": 15.0, "alive_ramp": 0.35,  # alive target = (base + ramp * t) * stage and level spawn factors
	"hp_ramp": 0.6,  # extra enemy HP by the latest moment the boss can appear
	"cluster_every": 1.4, "cluster_jitter": 4.0,
	"runner_from": 15.0, "runner_weight": 0.18, "runner_ramp": 1.0 / 500.0,
	"spitter_from": 40.0, "spitter_weight": 0.1, "spitter_ramp": 1.0 / 900.0,
	"elite_times": [40.0, 80.0],
	"horde_times": [30.0, 60.0, 85.0, 115.0], "horde_count": 20,
	# Enemies appear this far from the car, just off screen. Side distance is per unit of aspect ratio.
	"screen_side": 28.0, "screen_up": 34.0, "screen_down": 26.0,
	"ahead_chance": 0.65, "ahead_spread": 1.0,  # most spawns are in the direction of travel
}

## Boss arena. Damage and HP also grow per stage through the *_stage values.
const ARENA := {
	"rings": [5.8, 10.0, 14.0], "start_ring": 1, "ring_switch_speed": 16.0, "ring_invuln": 0.2,
	"floor_radius": 16.5, "summon_radius": 17.5,
	"speed_scale": 0.72, "dash_time": 0.22, "dash_cooldown": 0.5, "dash_speed": 3.5, "dash_invuln": 0.4, "dash_buffer": 0.5,
}
const BOSS := {
	"hp_stage": 0.25, "dmg_stage": 0.2, "first_attack": 2.5,
	"rest": 1.6, "rest_enraged": 1.0, "enrage_at": 0.5, "enrage_rush": 1.6,
	"burst_telegraph": 0.7, "burst_dmg": 18.0, "burst_shots": 22, "burst_shots_enraged": 26, "burst_gap": 3,
	"burst_speed": 7.0, "burst_speed_enraged": 8.5, "burst_volleys": 3, "burst_volleys_enraged": 4,
	"burst_interval": 0.7, "burst_interval_enraged": 0.55, "burst_shot_radius": 0.5, "burst_life": 4.0,
	# First gap: within this share of what the car can reach before the shots arrive. Later gaps drift (radians).
	"burst_reach": 0.8, "burst_drift": 0.3,
	"slam_telegraph": 1.3, "slam_dmg": 35.0, "slam_width": 1.6,
	"sweep_telegraph": 1.1, "sweep_dmg": 26.0, "sweep_speed": 1.55, "sweep_speed_enraged": 2.0, "sweep_turns": 1.15,
	"summon_telegraph": 0.6, "summon_count": 8, "summon_count_enraged": 12,
}

const CLASSES := {
	"juggernaut": {
		"name": "Juggernaut",
		"tagline": "Heavy tank",
		"desc": "Slow, armored, rams hard.\nStarts with Rocket Pod.",
		"max_hp": 150.0, "armor": 2.0, "speed": 10.0, "turn": 4.0, "ram": 35.0, "might": 1.05,
		"weapon": "rockets",
		"color": Color(0.42, 0.5, 0.28),
		"size": Vector3(2.6, 1.2, 3.8),
	},
	"interceptor": {
		"name": "Interceptor",
		"tagline": "Fast raider",
		"desc": "Fragile but quick.\nStarts with Hood MG.",
		"max_hp": 110.0, "armor": 1.0, "speed": 13.0, "turn": 3.0, "ram": 20.0, "might": 1.05,
		"weapon": "mg",
		"color": Color(0.85, 0.2, 0.18),
		"size": Vector3(1.5, 0.8, 3.0),
	},
	"warrig": {
		"name": "War Rig",
		"tagline": "Armed hauler",
		"desc": "Balanced and sturdy.\nStarts with Saw Blades.",
		"max_hp": 130.0, "armor": 1.0, "speed": 11.5, "turn": 3.8, "ram": 28.0, "might": 1.05,
		"weapon": "saws",
		"color": Color(0.9, 0.55, 0.15),
		"size": Vector3(2.2, 1.5, 4.6),
	},
}

## "up" is the description of reaching level N (index N-1).
## "evo" is the passive that, once owned, lets a max-level weapon evolve in a salvage crate.
const WEAPONS := {
	"mg": {
		"name": "Hood MG", "desc": "Auto-fires at the nearest enemy.",
		"up": ["", "+40% damage", "+1 barrel", "+30% fire rate", "+1 barrel, bullets pierce"],
		"evo": "hot", "evo_name": "Shredder Minigun", "evo_desc": "A piercing storm of lead.",
		"color": Color(1.0, 0.85, 0.3),
		"range": 20.0, "bullet_speed": 36.0, "bullet_life": 0.7, "barrel_gap": 0.35, "evo_jitter": 0.025,
		"levels": [
			{"dmg": 8.0, "barrels": 1, "pierce": 0, "cd": 0.42, "knock": 9.0},
			{"dmg": 11.2, "barrels": 1, "pierce": 0, "cd": 0.42, "knock": 9.0},
			{"dmg": 11.2, "barrels": 2, "pierce": 0, "cd": 0.42, "knock": 5.0},
			{"dmg": 11.2, "barrels": 2, "pierce": 0, "cd": 0.294, "knock": 4.0},
			{"dmg": 11.2, "barrels": 3, "pierce": 1, "cd": 0.294, "knock": 3.0},
		],
		"evolved": {"dmg": 16.0, "barrels": 2, "pierce": 3, "cd": 0.07, "knock": 1.2},
	},
	"rockets": {
		"name": "Rocket Pod", "desc": "Homing rockets at the closest enemies.",
		"up": ["", "+30% damage", "+1 rocket", "+25% blast radius", "+1 rocket, faster reload"],
		"evo": "turbo", "evo_name": "Swarm Barrage", "evo_desc": "Endless homing rockets.",
		"color": Color(1.0, 0.5, 0.15),
		"range": 22.0, "rocket_speed": 16.0, "rocket_life": 2.2, "swerve": 1.5,
		"levels": [
			{"dmg": 22.0, "count": 1, "aoe": 2.4, "cd": 1.7},
			{"dmg": 28.6, "count": 1, "aoe": 2.4, "cd": 1.7},
			{"dmg": 28.6, "count": 2, "aoe": 2.4, "cd": 1.7},
			{"dmg": 28.6, "count": 2, "aoe": 3.0, "cd": 1.7},
			{"dmg": 28.6, "count": 3, "aoe": 3.0, "cd": 1.3},
		],
		"evolved": {"dmg": 34.0, "count": 4, "aoe": 3.2, "cd": 0.75},
	},
	"saws": {
		"name": "Saw Blades", "desc": "Blades orbit your vehicle.",
		"up": ["", "+40% damage", "+1 blade", "+wider orbit", "+1 blade, faster spin"],
		"evo": "blast", "evo_name": "Buzzkill Halo", "evo_desc": "A huge ring of screaming saws.",
		"color": Color(0.8, 0.85, 0.9),
		"hit_cd": 0.28, "knock": 10.0,
		"levels": [
			{"dmg": 13.0, "count": 2, "orbit": 3.2, "spin": 3.0, "size": 1.0},
			{"dmg": 17.6, "count": 2, "orbit": 3.2, "spin": 3.0, "size": 1.0},
			{"dmg": 17.6, "count": 3, "orbit": 3.2, "spin": 3.0, "size": 1.0},
			{"dmg": 17.6, "count": 3, "orbit": 4.0, "spin": 3.0, "size": 1.0},
			{"dmg": 17.6, "count": 4, "orbit": 4.0, "spin": 4.0, "size": 1.0},
		],
		"evolved": {"dmg": 26.0, "count": 6, "orbit": 4.8, "spin": 4.5, "size": 1.6},
	},
	"mines": {
		"name": "Mine Dropper", "desc": "Throws mines at the closest enemy.",
		"up": ["", "+40% damage", "faster drops", "+30% blast radius", "drops 2 mines"],
		"evo": "hot", "evo_name": "Napalm Mines", "evo_desc": "Mines leave burning pools.",
		"color": Color(0.95, 0.25, 0.25),
		"life": 9.0, "arm_time": 0.4, "trigger_radius": 1.3, "range": 18.0, "throw_min": 5.0, "throw_max": 12.0, "throw_arc": 3.0,
		"levels": [
			{"dmg": 30.0, "count": 1, "aoe": 2.6, "cd": 1.3},
			{"dmg": 42.0, "count": 1, "aoe": 2.6, "cd": 1.3},
			{"dmg": 42.0, "count": 1, "aoe": 2.6, "cd": 0.95},
			{"dmg": 42.0, "count": 1, "aoe": 3.38, "cd": 0.95},
			{"dmg": 42.0, "count": 2, "aoe": 3.38, "cd": 0.95},
		],
		"evolved": {"dmg": 45.0, "count": 2, "aoe": 4.056, "cd": 0.8},
		"napalm_dps": 22.0, "napalm_life": 3.0, "napalm_radius": 0.8,
	},
	"tesla": {
		"name": "Tesla Coil", "desc": "Lightning that chains between enemies.",
		"up": ["", "+2 chains", "+40% damage", "faster recharge", "+3 chains"],
		"evo": "magnet", "evo_name": "Storm Rod", "evo_desc": "Lightning arcs everywhere.",
		"color": Color(0.45, 0.8, 1.0),
		"range": 14.0, "chain_range": 6.5, "knock": 5.0,
		"levels": [
			{"dmg": 14.0, "chains": 3, "heads": 1, "cd": 1.5},
			{"dmg": 14.0, "chains": 5, "heads": 1, "cd": 1.5},
			{"dmg": 19.6, "chains": 5, "heads": 1, "cd": 1.5},
			{"dmg": 19.6, "chains": 5, "heads": 1, "cd": 1.1},
			{"dmg": 19.6, "chains": 8, "heads": 1, "cd": 1.1},
		],
		"evolved": {"dmg": 24.0, "chains": 12, "heads": 2, "cd": 0.55},
	},
	"shock": {
		"name": "Shock Plating", "desc": "Pulses damage around the vehicle.",
		"up": ["", "+30% radius", "+50% damage", "faster pulses", "+30% radius, +damage"],
		"evo": "plating", "evo_name": "Thunder Hull", "evo_desc": "Massive knockback pulses.",
		"color": Color(0.6, 0.5, 1.0),
		"levels": [
			{"dmg": 7.0, "radius": 3.2, "knock": 12.0, "cd": 1.2},
			{"dmg": 7.0, "radius": 4.16, "knock": 12.0, "cd": 1.2},
			{"dmg": 10.5, "radius": 4.16, "knock": 12.0, "cd": 1.2},
			{"dmg": 10.5, "radius": 4.16, "knock": 12.0, "cd": 0.9},
			{"dmg": 13.65, "radius": 5.408, "knock": 12.0, "cd": 0.9},
		],
		"evolved": {"dmg": 20.0, "radius": 6.5, "knock": 22.0, "cd": 0.8},
	},
}

const PASSIVES := {
	"plating": {"name": "Armor Plating", "desc": "+12% max HP, 6% less damage", "hp": 0.12, "armor": 1.0, "color": Color(0.6, 0.6, 0.65)},
	"turbo": {"name": "Turbocharger", "desc": "-8% weapon cooldowns", "cooldown": 0.92, "color": Color(0.3, 0.9, 0.5)},
	"magnet": {"name": "Scrap Magnet", "desc": "+35% pickup range", "range": 0.35, "color": Color(0.3, 0.6, 1.0)},
	"blast": {"name": "Blast Compound", "desc": "+12% area of effect", "area": 0.12, "color": Color(1.0, 0.6, 0.2)},
	"nitro": {"name": "Nitro Injector", "desc": "+6% vehicle speed", "speed": 0.06, "color": Color(0.2, 0.95, 0.9)},
	"hot": {"name": "Hot Rounds", "desc": "+10% damage", "damage": 0.1, "color": Color(1.0, 0.3, 0.2)},
}

## Permanent upgrades bought between runs. Cost of the next level = "cost" * (level + 1).
## "class" limits an upgrade to one vehicle class; empty means all of them.
const GARAGE := {
	"hull": {"name": "Reinforced Hull", "desc": "+5% max HP", "max": 5, "cost": 40, "value": 0.05, "class": ""},
	"guns": {"name": "Heavy Calibers", "desc": "+4% damage", "max": 5, "cost": 40, "value": 0.04, "class": ""},
	"engine": {"name": "Tuned Engine", "desc": "+3% vehicle speed", "max": 5, "cost": 30, "value": 0.03, "class": ""},
	"magnet": {"name": "Scrap Sweep", "desc": "+8% pickup range", "max": 4, "cost": 25, "value": 0.08, "class": ""},
	"xp": {"name": "Field Manual", "desc": "+5% XP", "max": 5, "cost": 30, "value": 0.05, "class": ""},
	"armor": {"name": "Bolt-on Armor", "desc": "+1 armor", "max": 3, "cost": 60, "value": 1.0, "class": ""},
	"redline": {"name": "Hot Start", "desc": "Start with +10% Redline", "max": 3, "cost": 40, "value": 0.1, "class": ""},
	"revive": {"name": "Spare Engine", "desc": "Revive once per run at 50% HP", "max": 1, "cost": 300, "value": 0.5, "class": ""},
}
## Parts earned: one per "per_kills" kills, "stage" per stage reached, "boss" per boss (times its stage).
const PARTS := {"per_kills": 10, "stage": 15, "boss": 40}

## Enemy type ids index into ENEMY_ORDER.
const ENEMY_ORDER := ["crawler", "runner", "spitter", "brute", "boss"]
const ENEMIES := {
	"crawler": {"hp": 10.0, "speed": 5.5, "radius": 0.65, "dmg": 5.0, "xp": 1, "score": 10, "knock": 1.0, "color": Color(0.55, 0.78, 0.3), "scale": 1.1},
	"runner": {"hp": 20.0, "speed": 11.5, "radius": 0.7, "dmg": 7.0, "xp": 2, "score": 20, "knock": 0.8, "color": Color(0.95, 0.35, 0.25), "scale": 1.25},
	"spitter": {"hp": 30.0, "speed": 10.5, "radius": 0.75, "dmg": 6.0, "xp": 3, "score": 30, "knock": 1.0,
		"range": 11.0, "pace": 0.6, "hold": 1.5, "back_off": 0.5, "hold_inside": 8.0, "color": Color(0.72, 0.38, 0.95), "scale": 1.2},
	"brute": {"hp": 300.0, "speed": 6.0, "radius": 1.3, "dmg": 14.0, "xp": 15, "score": 300, "knock": 0.25, "color": Color(1.0, 0.78, 0.2), "scale": 2.2},
	"boss": {"hp": 3000.0, "speed": 0.0, "radius": 2.8, "dmg": 25.0, "xp": 0, "score": 5000, "knock": 0.0, "color": Color(1, 1, 1), "scale": 1.0},
}

const BIOMES := [
	{
		"name": "Rust Wastes", "boss": "WARLORD MAXIMUS", "half": [255.0, 225.0], "roads": "winding", "solids": 240, "decor": 320,
		"sky": Color(0.86, 0.6, 0.38), "fog": Color(0.86, 0.62, 0.4),
		"ground_a": Color(0.72, 0.5, 0.3), "ground_b": Color(0.58, 0.38, 0.22),
		"road": Color(0.32, 0.29, 0.27), "line": Color(0.95, 0.85, 0.5), "edge": Color(0.5, 0.42, 0.35),
		"grid": 0.0, "grid_color": Color(0, 0, 0), "props": "waste", "boss_color": Color(0.75, 0.3, 0.15),
	},
	{
		"name": "Neon Sprawl", "boss": "NEON HYDRA", "half": [225.0, 225.0], "roads": "grid", "solids": 180, "decor": 240,
		"sky": Color(0.08, 0.04, 0.16), "fog": Color(0.18, 0.06, 0.3),
		"ground_a": Color(0.1, 0.08, 0.16), "ground_b": Color(0.06, 0.05, 0.1),
		"road": Color(0.12, 0.12, 0.16), "line": Color(0.1, 1.0, 0.95), "edge": Color(1.0, 0.2, 0.75),
		"grid": 1.0, "grid_color": Color(0.9, 0.2, 1.0), "props": "neon", "boss_color": Color(0.2, 0.95, 1.0),
	},
	{
		"name": "Frost Line", "boss": "FROST TITAN", "half": [270.0, 210.0], "roads": "none", "solids": 280, "decor": 320,
		"sky": Color(0.72, 0.84, 0.95), "fog": Color(0.8, 0.88, 0.96),
		"ground_a": Color(0.9, 0.94, 1.0), "ground_b": Color(0.72, 0.8, 0.9),
		"road": Color(0.4, 0.45, 0.52), "line": Color(0.95, 0.95, 1.0), "edge": Color(0.6, 0.68, 0.78),
		"grid": 0.0, "grid_color": Color(0, 0, 0), "props": "frost", "boss_color": Color(0.5, 0.75, 1.0),
	},
	{
		"name": "Toxic Bog", "boss": "BOG MOTHER", "half": [225.0, 195.0], "roads": "none", "solids": 220, "decor": 360,
		"sky": Color(0.3, 0.38, 0.2), "fog": Color(0.36, 0.45, 0.22),
		"ground_a": Color(0.25, 0.35, 0.15), "ground_b": Color(0.35, 0.5, 0.12),
		"road": Color(0.24, 0.22, 0.2), "line": Color(0.7, 1.0, 0.2), "edge": Color(0.3, 0.3, 0.25),
		"grid": 0.0, "grid_color": Color(0, 0, 0), "props": "toxic", "boss_color": Color(0.5, 0.9, 0.2),
	},
]


static func enemy_def(type_id: int) -> Dictionary:
	return ENEMIES[ENEMY_ORDER[type_id]]


static func biome(stage: int) -> Dictionary:
	return BIOMES[(stage - 1) % BIOMES.size()]


## Enemy HP / count multipliers grow every stage; loops through biomes forever.
static func stage_hp_mult(stage: int) -> float:
	return 1.0 + 0.45 * (stage - 1)


static func stage_spawn_mult(stage: int) -> float:
	return 1.0 + 0.3 * (stage - 1)


## Enemies spawned from now on scale with the player's level, on top of the stage.
static func level_hp_mult(level: int) -> float:
	return 1.0 + 0.03 * (level - 1)


static func level_dmg_mult(level: int) -> float:
	return 1.0 + 0.012 * (level - 1)


static func level_spawn_mult(level: int) -> float:
	return 1.0 + 0.015 * (level - 1)


## Everything moves faster each stage: the vehicle and, by the same factor, the enemies.
static func stage_speed_mult(stage: int) -> float:
	return 1.0 + 0.06 * (stage - 1)


## Player damage taken grows with the stage.
static func stage_dmg_mult(stage: int) -> float:
	return 1.0 + 0.1 * (stage - 1)


## Stats of a weapon at `level` (1-based), or its evolved form.
static func weapon_stats(id: String, level: int, evolved: bool) -> Dictionary:
	var w: Dictionary = WEAPONS[id]
	return w["evolved"] if evolved else w["levels"][level - 1]


static func xp_to_next(level: int) -> int:
	return 5 + (level - 1) * 5 + maxi(0, level - 20) * 8
