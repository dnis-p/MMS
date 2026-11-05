# Game structure

How DIG fits together, as diagrams. GitHub draws them from the text below (Mermaid), so edit the text, not a picture.
Boxes with a dashed border are **planned** (owner's decisions not built yet, see docs/DESIGN.md section 7); everything
else is how the game works now. Numbers and formulas are in docs/MECHANICS.md. Update this file in the same commit as
any change to the structure it shows.

## 1. The big loop

```mermaid
flowchart LR
    menu["Main menu"] --> pick["Pick a character<br/>(starting tool + one rule)"]
    pick --> run["A run in the mine<br/>about 10 minutes"]
    run --> ends["Run ends:<br/>Heart, lift, death or give up"]
    ends --> bank["Bank the gems you kept"]
    ends --> goals["Goals checked<br/>pay gems or unlock things"]
    bank --> shop["Shop:<br/>permanent stat upgrades"]
    goals --> unlocks["Unlocks:<br/>tools and characters"]
    shop --> menu
    unlocks --> menu
    run -. "relic touched:<br/>kept at once, even if you die" .-> unlocks
```

## 2. Inside a run

```mermaid
flowchart TD
    move["You move, the mouse aims"] --> tools["Tools fire by themselves"]
    tools --> cubes["Cubes pop"]
    tools --> enemies["Enemies die"]
    cubes --> xp["XP"]
    cubes --> gems["Gems from ore, geodes, vaults"]
    enemies --> gems
    gems --> xp
    gems --> carried["Gems carried<br/>(banked only when the run ends)"]
    xp --> level["Level-up: pick 1 of 3 cards<br/>plus a blast and a heal"]
    level --> build["Your build: tools, boosts,<br/>evolutions, the Dash Drive"]
    build --> tools
    build --> scale["Enemies scale with your cards,<br/>distance and time:<br/>more, faster, tougher"]
    scale --> enemies
    cubes --> combo["Combo"] --> frenzy["Frenzy: every cube<br/>breaks in one hit for 5 s"]
```

**What the mine holds**, found by digging, all random each run: ore and crystal, geodes, vaults, shrines (a trade for this
run), relic rooms, fuel seams, cracked rock that caves in, gas rock, nests and spike plates. The Heart is 190 m away in a
random direction: you find it by its beat and the pink veins.

## 3. A run's timeline and how it ends

```mermaid
stateDiagram-v2
    direction TB
    [*] --> Run
    state Run {
        direction LR
        [*] --> Digging: start, a lift beside you
        Digging --> Swarm: swarm from 20 s, hordes from 75 s
        Swarm --> Borer: at 3 min 30 s
        Borer --> Brood: at 7 min, or 90 s after the Borer dies
        Brood --> HeartOpen: both bosses dead
    }
    HeartOpen --> Won: a Heart cube breaks
    Run --> Lift: any time from 30 s, carrying gems
    Run --> Dead: health runs out, or give up
    Won --> [*]: all gems plus 500
    Lift --> [*]: all gems
    Dead --> [*]: half the gems, more with Insurance
```

## 4. Where your strength comes from

```mermaid
flowchart LR
    char["Character<br/>health, speed, gems"] --> stats["Your stats for this run"]
    shop["Shop<br/>lasts forever"] --> stats
    relics["Relics<br/>last forever"] --> stats
    shrines["Shrines<br/>this run only"] --> stats
    boosts["Boost cards<br/>this run only"] --> stats
    stats --> tools["Tools and the Dash Drive"]
    sheet["One stat sheet shared by all of these<br/>(suggested categories in DESIGN 7)"]:::planned -.-> stats

    classDef planned stroke-dasharray: 6 4
```

Enemies scale with the cards you picked in this run (tool, boost and Dash Drive levels), with distance from the start and with time. The shop, relics and evolutions don't count, so they are a true edge over enemies.

## 5. Unlocks

**Now:**

```mermaid
flowchart LR
    start["Open from the start:<br/>Shovel, Drill, Saw Blades,<br/>the Dash Drive, Digger"]
    g1["Goal: get out by lift"] --> bombs["Bombs"]
    g2["Goal: break 25,000 cubes"] --> pulse["Shock Pulse"]
    g3["Goal: kill a boss"] --> spark["Spark Coil"]
    g4["Goal: burn 5 fuel seams"] --> moles["Mole Pack"]
    lens["Relic: Strange Lens"] --> beam["Mining Beam"]
    g5["Goal: reach the Stone layer"] --> prospector["Prospector<br/>(Shovel)"]
    g6["Goal: bank 3,000 gems"] --> rig["Rig<br/>(Drill)"]
```

**Planned** (owner, 2026-11-05): each character brings their own tool. You find the tool in the mine, and that unlocks
the character, and the tool for every other character too. At least 4 tools are open from the start, so the first
character can play a whole run.

```mermaid
flowchart LR
    start["Open from the start:<br/>4 tools and the first character"]:::planned
    find["Find a tool in the mine"]:::planned --> char["Its character unlocks<br/>(that tool + own stats + one rule)"]:::planned
    find --> pool["The tool joins everyone's card pool"]:::planned

    classDef planned stroke-dasharray: 6 4
```
