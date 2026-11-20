local _, ns = ...

-- Loot skins: earned by looting an item of a quality (or better), and by
-- wearing every piece of an item set (Feats.lua). Colors follow the game's
-- item quality colors.

local F = ns.Fonts
local add = ns.AddSkin

local UNCOMMON, UNCOMMON_LT = { 0.3, 1, 0.22 }, { 0.92, 1, 0.87 }
local RARE, RARE_LT = { 0.24, 0.6, 1 }, { 0.72, 0.86, 1 }
local EPIC, EPIC_LT = { 0.7, 0.42, 1 }, { 0.9, 0.8, 1 }
-- Physical hits: a lighter shade that still reads as the quality color.
local UNCOMMON_PHYS, RARE_PHYS, EPIC_PHYS = { 0.62, 1, 0.55 }, { 0.55, 0.78, 1 }, { 0.82, 0.64, 1 }
local LEGEND, LEGEND_LT = { 1, 0.6, 0.18 }, { 1, 0.85, 0.5 }
local SETGOLD, SETGREEN = { 1, 0.82, 0.29 }, { 0.3, 1, 0.22 }

add("freshfind", {
    group = "loot", listNote = "Uncommon",
    name = "Fresh Find", tagline = "Loot: crisp green numbers with a glint; crits pop a little burst of loot sparkle.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = UNCOMMON, physColor = UNCOMMON_PHYS, spellColor = UNCOMMON,
    layers = { { x = 2, y = -2, color = { 0.03, 0.16, 0.02, 1 } } },
    motion = "rise", motionArgs = { speed = 34 },
    dur = 1.15, critDur = 1.45, critScale = 1.5, pop = 0.25,
    decor = { tex = "twinkle", size = 14, x = -16, y = 8, color = UNCOMMON_LT, alpha = 0.9, flicker = true },
    critReplacesDecor = true,
    critDecor = { tex = "twinkle", size = 64, color = UNCOMMON_LT, alpha = 1, spin = 1.5, snap = 0.2, snapTime = 0.12 },
    ring = { size = 52, color = UNCOMMON, grow = 1.6, alpha = 0.8 },
    particles = { tex = "twinkle", count = 0, critCount = 12, size = { 10, 16 }, speed = { 40, 110 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 0.9 }, color = UNCOMMON, altColor = UNCOMMON_LT },
})

add("rarefind", {
    group = "loot", listNote = "Rare",
    name = "Rare Find", tagline = "Loot: sapphire numbers cut like gems; crits flash a faceted gem that bursts into shards.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = RARE, physColor = RARE_PHYS, spellColor = RARE,
    layers = { { x = 2, y = -2, color = { 0.02, 0.08, 0.25, 1 } }, { x = -1, y = 1, color = { 0.8, 0.9, 1, 0.35 } } },
    motion = "rise", motionArgs = { speed = 34 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.25,
    critDecor = { tex = "gem", size = 56, color = RARE, alpha = 0.9, blend = "BLEND", snap = 0.3, snapTime = 0.12 },
    ring = { size = 56, color = RARE_LT, grow = 1.6, alpha = 0.8 },
    particles = { tex = "gem", count = 0, critCount = 10, size = { 7, 11 }, speed = { 50, 130 }, dir = { 0, 360 },
                  gravity = -120, life = { 0.5, 0.9 }, color = RARE, altColor = RARE_LT, blend = "BLEND", spin = 8 },
})

add("epichaul", {
    group = "loot", listNote = "Epic",
    name = "Epic Haul", tagline = "Loot: violet numbers in a swirling aura; crits drop a beam of light and scatter stars.",
    font = F.morpheus, size = 24, outline = "OUTLINE",
    color = EPIC, physColor = EPIC_PHYS, spellColor = EPIC,
    layers = { { x = 2, y = -2, color = { 0.1, 0.02, 0.22, 1 } } },
    motion = "rise", motionArgs = { speed = 30 },
    dur = 1.25, critDur = 1.6, critScale = 1.55, pop = 0.3,
    decor = { tex = "orbit", size = 56, color = EPIC, alpha = 0.7, spin = 4 },
    critReplacesDecor = true,
    critDecor = { tex = "beam", size = { 56, 170 }, y = 70, color = EPIC, alpha = 0.8, snap = 0.2, snapTime = 0.12 },
    ring = { size = 60, color = EPIC_LT, grow = 1.6, alpha = 0.8 },
    critDecor2 = { tex = "beam", size = { 14, 170 }, y = 70, color = EPIC_LT, alpha = 0.9, snap = 0.2, snapTime = 0.12 },
    particles = { tex = "star", count = 0, critCount = 12, size = { 7, 12 }, speed = { 40, 110 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.1 }, color = EPIC_LT, altColor = EPIC, spin = 4 },
})

add("legendary", {
    group = "loot", listNote = "Legendary",
    name = "Legendary", tagline = "Loot: burning orange numbers trailing embers; crits raise a pillar of light, rays and a LEGENDARY banner.",
    font = F.morpheus, size = 25, outline = "THICKOUTLINE",
    color = LEGEND, physColor = LEGEND_LT, spellColor = LEGEND,
    layers = { { x = 2, y = -2, color = { 0.25, 0.08, 0, 1 } }, { x = -1, y = 1, color = { 1, 0.9, 0.6, 0.4 } } },
    motion = "rise", motionArgs = { speed = 30 },
    dur = 1.3, critDur = 1.8, critScale = 1.65, pop = 0.35,
    critDecor = { tex = "burst", size = 200, color = LEGEND, alpha = 0.6, spin = 0.5, snap = 0.2, snapTime = 0.15 },
    critDecor2 = { tex = "beam", size = { 44, 180 }, y = 74, color = LEGEND_LT, alpha = 0.85, snap = 0.2, snapTime = 0.12 },
    ring = { size = 80, color = LEGEND_LT, grow = 2.0, alpha = 0.9 },
    critTitle = { text = "LEGENDARY", y = 50, size = 18, font = F.morpheus, pop = 1.5,
                  colors = { LEGEND_LT, { 1, 1, 1 }, LEGEND }, shadowColor = { 0.25, 0.08, 0 } },
    particles = { tex = "glow", count = 3, critCount = 18, size = { 3, 6 }, speed = { 20, 140 }, dir = { 0, 360 },
                  gravity = 30, life = { 0.5, 1.1 }, color = LEGEND, altColor = LEGEND_LT },
    particles2 = { tex = "twinkle", count = 0, critCount = 4, size = { 14, 22 }, speed = { 10, 40 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.7, 1.2 }, color = LEGEND_LT },
})

add("fullset", {
    group = "loot", listNote = "Item set",
    name = "Full Set", tagline = "Set: gold numbers circled by eight set pieces; crits snap them together and call SET BONUS.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = SETGOLD, physColor = { 1, 0.9, 0.6 }, spellColor = SETGOLD,
    layers = { { x = 2, y = -2, color = { 0.22, 0.15, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 28 },
    dur = 1.2, critDur = 1.6, critScale = 1.5, pop = 0.25,
    decor = { tex = "setring", size = 66, color = SETGOLD, alpha = 0.55, spin = 1.2 },
    critReplacesDecor = true,
    critDecor = { tex = "setring", size = 96, color = SETGOLD, alpha = 1, snap = 1.8, snapTime = 0.22, unwind = 3 },
    ring = { size = 70, color = { 1, 0.93, 0.65 }, grow = 1.6, alpha = 0.9 },
    critTitle = { text = "SET BONUS", y = 50, size = 16, font = F.morpheus, pop = 1.4,
                  colors = { SETGREEN, { 1, 1, 1 }, SETGOLD }, shadowColor = { 0.03, 0.16, 0.02 } },
    particles = { tex = "twinkle", count = 0, critCount = 10, size = { 8, 13 }, speed = { 40, 100 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 0.9 }, color = { 1, 0.93, 0.65 } },
})
