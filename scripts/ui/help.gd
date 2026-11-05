class_name Help
## The How to play page for testers: what to do, what is out there, and how a run ends.
## Numbers are read from Defs, so the text follows balance changes.


const CONTROL_NOTES := [
	"Your tools dig and fight by themselves: there is no attack button. Without aiming, they point the way you walk. The Dash Drive is the one thing you press.",
	"The game follows whichever you used last, keyboard and mouse or gamepad. The map's opacity is in Options.",
]


## [action, keyboard and mouse, gamepad] rows, shown on the Controls page, in the pause menu and in How to play.
static func controls() -> Array:
	return [
		["Move", "WASD or arrows", "left stick or d-pad"],
		["Dash", "Space or Shift, once you hold the Dash Drive: a burst of speed the way you move", "A"],
		["Aim", "mouse. Only the direction counts: the arrow on the ring around you shows it", "right stick"],
		["Map", "M or Tab. Tap it to keep the map open, hold it to peek while you keep moving", "Back"],
		["Zoom the map", "mouse wheel, + and -", "shoulder buttons"],
		["Pause", "Esc or P", "Start"],
		["Menus and upgrades", "mouse, or arrows and Enter. Esc goes back", "left stick or d-pad, A picks, B goes back"],
	]


## The controls as a three-column table, for a page or a panel `width` pixels wide.
static func controls_table(width := 980.0, size := 20) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 10)
	var widths := [width * 0.2, width * 0.5, width * 0.3 - 48.0]
	var head := Color(1.0, 0.65, 0.2)
	var rows := [["", "Keyboard and mouse", "Gamepad"]] + controls()
	for r in rows.size():
		for k in 3:
			var text := String(rows[r][k])
			var l := Ui.label(text.substr(0, 1).to_upper() + text.substr(1), size, head if r == 0 or k == 0 else Color(0.9, 0.88, 0.85))
			l.custom_minimum_size.x = widths[k]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			grid.add_child(l)
	return grid


## [title, [lines]] pairs, in reading order.
static func sections() -> Array:
	var run := Defs.RUN
	var borer: Dictionary = Defs.BOSSES[0]
	var brood: Dictionary = Defs.BOSSES[1]
	return [
		["The idea", [
			"You are a digger in a huge mine. Your tools dig and fight by themselves: you only walk and aim.",
			"Break rock, pick up what shines, level up, and get out alive with as many gems as you can.",
		]],
		["Controls", controls().map(func(c): return "%s: %s. Gamepad: %s." % [c[0], c[1], c[2]]) + CONTROL_NOTES],
		["A run", [
			"Your tools hit whenever they are ready. The shovel only swings when there is something in front of you.",
			"Ore and gems leave shiny bits: walk close to collect them. They give you XP and gems to carry.",
			"Each level-up pauses the game and offers 3 cards: a new tool, a tool level or a boost. Picking one also blasts the rock around you and heals you.",
			"You can hold %d different tools and %d boosts, your first tool included. Empty boxes at the top left show free slots. Once they are full, cards only level up what you hold. The Tool Belt in the Shop adds more, up to %d of each." % [
				int(Defs.SLOTS["tools"]), int(Defs.SLOTS["boosts"]), int(Defs.SLOTS["tools"] + Defs.SHOP["slots"]["max"] * Defs.SHOP["slots"]["value"])],
			"A tool at max level evolves into a stronger form once you also have %d levels of the boost that goes with it. Evolutions show up first among the cards." % Defs.EVOLVE_BOOST,
			"The Dash Drive is a card too and takes a tool slot. Press Space or Shift (A on a gamepad) to burst %d m the way you move, untouchable while it lasts, then wait %d s. It levels up like a tool: the dash gets longer, faster and quicker to recharge, from level 3 it leaves a copy of you behind that enemies attack until it falls, and from level 5 that copy explodes." % [
				int(Defs.DASH["base"]["speed"] * Defs.DASH["base"]["time"]), int(Defs.DASH["base"]["cooldown"])],
			"Fog hides what you haven't seen. Your lamp lights what is near, and you can only dig a few cubes into the dark.",
			"The further you go from the start, the harder the rock, the richer the ore and the tougher the enemies. The top of the screen shows the layer, how far out you are and the time.",
		]],
		["The goal: break the Heart", [
			"About %d m from the start, in a random direction, beats the Heart. Nothing points at it." % int(run["heart_dist"]),
			"Listen: its beat gets faster and louder as you get closer. Look: pink veins run out from it and get thicker near it.",
			"It is sealed until both bosses are dead: %s comes at %s, and %s at %s, or %d s after the first dies if that is later. Bosses follow you, so you can't lose them." % [
				_boss(borer), _clock(borer["at"]), _boss(brood), _clock(brood["at"]), int(run["boss_gap"])],
			"Once it is open, your first hit wakes it, and a swarm comes every %d s. Break a single cube of the Heart to win: you keep all your gems, plus %d." % [
				int(run["heart_horde"]), int(run["heart_bonus"])],
		]],
		["Other ways out", [
			"Lift: from %s, stand on a lift pad for %s s with at least 1 gem to leave with everything you carry. There is one at the start and more around the mine." % [
				_clock(run["lift_from"]), str(run["lift_hold"])],
			"Die, or give up from the pause menu: you keep %d%% of your gems, more with Insurance from the shop." % roundi(run["death_keep"] * 100.0),
		]],
		["Enemies and dangers", [
			"Crawlers keep coming at you, and now and then waves of rings of them (\"SWARM!\"). Nests sleep in caves until you spot them. Burrowers and bosses dig through rock to reach you.",
			"Enemies hurt by touch. After a hit you can't be hurt for %s s, and you heal slowly after %d s without a hit." % [
				str(Defs.DIGGER["invuln"]), int(Defs.DIGGER["regen_after"])],
			"Pale, speckled loose rock starts a cave-in when broken: after a dark shadow, rubble fills the area. It crushes the enemies in it, and hurts you if you stay close, though you always keep a small pocket.",
			"Gas rock blows up a moment after it breaks. Spike plates on the floor rise a little just before the spikes come up.",
		]],
		["Worth finding", [
			"Geodes sparkle through the fog. Break one for a burst of gems.",
			"Orange fuel seams catch fire when broken and burn along their length, blasting rock and enemies.",
			"Vaults are walled boxes full of gold. Shrines offer a deal for this run, like 2 level-ups for half your health.",
			"Relic rooms hold relics: permanent bonuses, kept even if you die.",
			"Break things quickly to build a combo. At %d a Frenzy starts, and for %d s every cube breaks in one hit." % [
				int(Defs.FRENZY["at"]), int(Defs.FRENZY["time"])],
		]],
		["Between runs", [
			"Banked gems buy permanent upgrades in the Shop.",
			"Goals unlock new tools, new characters and gems. They are checked at the end of each run, even one that ends in death.",
			"The OBJECTIVES panel at the top left of a run shows the %d goals you are closest to, with this run counted in as you play. Gems you carry count as banked there, but dying keeps only part of them." % int(Defs.OBJECTIVES["shown"]),
			"Pick who digs on the main menu. Each character plays a little differently.",
		]],
		["For testers", [
			"This is a prototype: art and sound are placeholders and the numbers are first guesses.",
			"Tell us what feels good, what gets boring, what is confusing, and how long your runs last.",
		]],
	]


## "THE BORER" as it reads mid-sentence: "the Borer".
static func _boss(b: Dictionary) -> String:
	return String(b["name"]).capitalize().replace("The ", "the ")


static func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
