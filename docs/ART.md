# Art: style and model prompts

The art plan for DIG. The style is the owner's choice (2026-11-04); the creature designs and prompts below are
**(suggested)**: change any of them freely. The game still draws everything as plain boxes and spheres; nothing here is in
the game yet. Decisions are logged in docs/DESIGN.md.

## Style: low-poly pixel 3D

Owner: "it has to be lowpoly 100%", and picked **Pixel 3D** from the reference board (2026-11-04). The board is
`https://es.pinterest.com/0xsined/dig-game-style/`; a local copy lives in `art-refs/dig-game-style/` (ignored by git and
Godot, so it is only on the owner's machine).

- **Shapes:** few polygons, hard flat facets, chunky toy-like proportions. Big heads (up to half the body), stubby limbs,
  oversized hands, tools and claws. Each model reads as one clear silhouette.
- **Textures:** low-resolution pixel art with square texels and the shading painted in: a light top, darker sides, a dark
  outline row along edges. No smooth gradients, no photo detail. About 6 to 8 colours per model.
- **Mood:** spooky but cute. Skulls, grubs, goblins, rusty machines, but goofy faces rather than horror.
- **Colour:** dark, desaturated bodies (charcoal, rust, olive, purple-black) with one bright accent each, usually glowing
  eyes or lights. In the fog this means enemies show up as eyes first.
- **Why it fits:** the world is already small cubes (0.5 m), and pixel textures make characters match it.

## Rules every model has to follow (from how the game draws things)

- **Seen from above.** The camera looks down at about 70 degrees, from 19 m up. Put what identifies a model on top: hats,
  lamps, shells, horns, backs. Faces only show a little, so make eyes big and bright.
- **Small on screen.** A crawler is 0.7 m across, under 1.5 cubes. Detail smaller than a texel or two vanishes.
- **Enemies have no skeleton.** Each enemy type is one mesh drawn hundreds of times at once (MultiMesh), so it can bob,
  squash, lean and spin, but not move its legs. Design enemies that look fine frozen: tucked legs, blobs, shells, wheels.
- **Enemy bodies stay dark,** so they never pass for gems. The game tints each type and flashes it white when hit, so keep
  enemy textures mid to dark, with the bright accent only on the eyes or glow parts.
- **Triangle budgets:** crawler and runner 300, mole 300, burrower 600, brute 800, bosses 3,000, playable characters 2,000,
  props 500, tools 300, gems 50.
- **Textures:** 128 x 128 for small things, 256 x 256 for characters and bosses. In Godot set the texture filter to Nearest
  so the pixels stay sharp.

## Meshy workflow

1. Paste the **style block** below, then one model's text, into Meshy's text-to-3D. Together they stay under 600
   characters (Meshy cuts longer prompts).
2. If Meshy offers them: a low-poly or target-triangle setting (use the budget above), triangle topology, symmetry on. For
   playable characters choose an A-pose, in case we rig them later; enemies need no pose.
3. Meshy's textures come out smooth rather than pixel art. Two ways to fix that: retexture inside Meshy using one of the
   board images as the style picture, or shrink the texture afterwards to 64 or 128 px with a small palette (a script can do
   this for every model at once). The flat-colour look is the fallback if neither gets clean pixels.
4. A steadier option for style: make one clean concept picture per model first (any image generator, with the same
   prompt), then use Meshy's image-to-3D on it.
5. Export as **GLB**. Put finished models in `assets/models/` (it does not exist yet) and tell Claude, who wires them in.

Take only the look from the board. Two of its pins are fan art of other games' characters: our creatures stay our own.

### Style block (goes first in every prompt)

```
Low poly 3D game asset, chunky stylized toy proportions, hard flat facets, pixel art texture with square visible texels,
hand-painted shading in the pixels, 6-8 colour palette, no gradients, cute but spooky, one object, centered, no base, no text.
```

## Playable characters

**Digger** (the starting character, teal)
```
Small stout cave miner, huge head, round hard hat with a big glowing headlamp on top, teal overalls, chunky brown gloves,
short legs and boots, big dark eyes, A-pose, empty hands.
```

**Prospector** (unlocked: double gems, half health, gold)
```
Skinny old gem prospector, wide floppy hat, long scruffy beard, yellow scarf, huge backpack stuffed with glittering ore
sacks and a tin lantern on top, bony arms, A-pose, empty hands.
```

**Rig** (unlocked: a drill you drive, slow and tough, orange)
```
Tiny one-seat mining machine, rusty orange tin cockpit like a dented can, round headlight on the roof, a big spiral drill
nose at the front, two chunky tank treads, exhaust pipe, bolts and dents.
```

## Enemies (dark bodies, glowing eyes)

**Crawler** (the swarm; dark red body, red eyes)
```
Small round cave grub monster, dark red hunched body like a pill bug, legs tucked underneath, wide mouth of little teeth,
two big glowing red eyes, ridged back plates on top, low and round.
```

**Runner** (fast and fragile; dark ochre body, yellow eyes)
```
Small skinny cave cricket creature, flat skull-like head pointing forward, long folded legs tucked against the body, dark
ochre shell, two glowing yellow eyes, leaning forward as if sprinting, low and long.
```

**Burrower** (tunnels in from off screen; dark green body, green eyes)
```
Mole-like digging monster, wedge-shaped armoured head like a shovel blade, segmented dark green body, two big digging
claws in front, small glowing green eyes, stones stuck on its back, low and long.
```

**Brute** (big and slow; dark purple body, purple eyes)
```
Big hunched rock golem, huge stone fists resting on the ground, tiny head sunk between massive shoulders, dark purple
stone body, glowing purple eyes, purple crystals growing from its back, wide and heavy.
```

## Bosses

**The Borer** (charges in straight lines through rock; orange)
```
Huge armoured drill beast boss, a giant spiral drill horn for a snout, rusty orange overlapping plates, small glowing
eyes behind the drill, stubby thick legs, dents and bolts, long body built to charge forward.
```

**The Brood** (throws gas, drops crawlers; magenta)
```
Bloated cave mother monster boss, swollen sac body with glowing green gas pockets, a cluster of eggs on its back, tiny
grubs clinging to it, small head with many glowing magenta eyes, short stubby legs.
```

## Minions and tools

**Mole** (Mole Pack: little moles that dig around you)
```
Tiny cute mole helper, round brown body, tiny hard hat, oversized pink digging claws, pink nose, eyes squeezed shut,
low and round.
```

**Shovel** (starting tool, held in the hand)
```
Chunky mining shovel, short thick wooden handle with a D-grip, wide dented steel blade, rope tied around the handle.
```

**Drill** (held tool)
```
Chunky hand drill, orange body with a rubber grip, long spiral steel drill bit, a few bolts and a power cable.
```

**Saw blade** (blades that circle you)
```
Flat circular saw blade, chunky triangular teeth, steel with rusty spots, a bolt in the middle, very flat disc.
```

**Bomb** (thrown tool)
```
Round black bomb, metal band around the middle, short fuse with a spark on top, a small skull painted on the side.
```

Shock Pulse, Mining Beam and Spark Coil are effects, not models.

## World and props

**Lift** (the way out)
```
Square mine elevator platform, wooden plank floor, four corner posts, a pulley wheel and rope above, a hanging lantern,
flat top view, rusty metal brackets.
```

**Blood Shrine**
```
Small stone altar, dark red rock, carved heart on the front dripping red, two bone candles, a shallow bowl on top.
```

**Greed Shrine**
```
Small stone altar heaped with gold coins and gems, a grinning gold idol head on top, yellow glow, cracked stone base.
```

**Wind Shrine**
```
Small stone pillar with spiral carvings, pale blue cloth ribbons blowing around it, little wind chimes, a swirl symbol
on top, light blue glow.
```

**Spike plate** (floor trap, flat)
```
Square metal floor trap plate, rusty iron with a grid of holes, short sharp spikes sticking up through the holes,
very flat, seen from above.
```

**Brood's gas bomb** (thrown at you)
```
Round squishy egg sac, translucent green skin, glowing green gas inside, small veins, a wet drip at the bottom.
```

**Gem** (1,500 can lie on the floor at once: keep it tiny)
```
Small cut gemstone, simple faceted shape, bright saturated colour, one white highlight facet.
```

**Relics** (found once, kept forever: small pickups)
```
Strange Lens: brass magnifying lens with a cracked glowing green glass.
Gold Idol: small squat golden idol figure with a big grin and gem eyes.
Worn Boots: pair of old leather mining boots with patches and laces.
Lucky Charm: small charm on a cord, a red bead and a tiny horseshoe.
Whetstone: grey sharpening stone, worn hollow in the middle, wrapped in cloth.
```
For each relic, use the style block plus one line.

The cubes themselves stay generated by the game, not by Meshy. Pixel textures for them can come later, as small tiles.
