class_name Help
## The How to play page for testers: what to do, what is out there, and how a run ends.
## Numbers are read from Defs, so the text follows balance changes.


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
		["Controls", [
			"Move: WASD or arrows. Gamepad: left stick or d-pad.",
			"Aim: mouse. Gamepad: right stick. Without aiming, your tools point the way you walk.",
			"Pause: Esc or P. Gamepad: Start.",
			"Map: M or Tab. Gamepad: Back. Tap it to keep the map over the game, hold it to peek while you keep moving. Zoom with the mouse wheel, + and -, or the shoulder buttons. Its opacity is in Options.",
			"Menus and upgrades: mouse, or arrows and Enter. Gamepad: A picks, B goes back.",
		]],
		["A run", [
			"Your tools hit whenever they are ready. The shovel only swings when there is something in front of you.",
			"Ore and gems leave shiny bits: walk close to collect them. They give you XP and gems to carry.",
			"Each level-up pauses the game and offers 3 cards: a new tool, a tool level or a boost. Picking one also blasts the rock around you and heals you.",
			"A tool at max level evolves into a stronger form once you also have %d levels of the boost that goes with it. Evolutions show up first among the cards." % Defs.EVOLVE_BOOST,
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
			"Crawlers keep coming at you, and now and then a whole ring of them (\"SWARM!\"). Nests sleep in caves until you spot them. Burrowers and bosses dig through rock to reach you.",
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
