local _, ns = ...

-- Profession skins. Each grows with three tiers, earned at 150, 225 and 300
-- skill (Feats.lua): the table below is Journeyman, and tiers[2] (Expert)
-- and tiers[3] (Artisan) add to it in turn (ns.TierSkin; false clears a
-- field). skillLine is the profession's skill line id; prof its English name.

local F = ns.Fonts
local add = ns.AddSkin

local function prof(id, skillLine, profName, skin, expert, artisan)
    skin.group, skin.skillLine, skin.prof = "prof", skillLine, profName
    skin.tiers = { [2] = expert, [3] = artisan }
    add(id, skin)
end

local function title(text, colors, shadow)
    return { text = text, y = 46, size = 15, font = F.morpheus, pop = 1.35, colors = colors, shadowColor = shadow }
end

---------------------------------------------------------------------------
-- Alchemy: Philter
---------------------------------------------------------------------------
local GREEN, VIOLET = { 0.6, 1, 0.55 }, { 0.78, 0.55, 1 }
prof("philter", 171, "Alchemy", {
    name = "Philter", tagline = "Alchemy: numbers bubble up green and violet; crits pop the flask in colored smoke.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 0.55, 0.95, 0.5 }, physColor = { 0.78, 1, 0.68 }, spellColor = VIOLET,
    layers = { { x = 2, y = -2, color = { 0.15, 0.05, 0.25, 1 } } },
    motion = "rise", motionArgs = { speed = 40, sway = 4, freq = 9 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.25,
    particles = { tex = "bubble", count = 0, critCount = 5, size = { 5, 9 }, speed = { 20, 50 }, dir = { 60, 120 },
                  gravity = 30, life = { 0.5, 1.0 }, color = GREEN, altColor = VIOLET },
}, {
    critDecor = { tex = "puff", size = 110, color = GREEN, alpha = 0.55, blend = "BLEND", grow = 0.8, spin = 0.3 },
    critDecor2 = { tex = "puff", size = 84, color = VIOLET, alpha = 0.5, blend = "BLEND", grow = 1.0, spin = -0.3, delay = 0.08 },
    particles = { tex = "bubble", count = 0, critCount = 10, size = { 5, 10 }, speed = { 20, 60 }, dir = { 50, 130 },
                  gravity = 30, life = { 0.6, 1.1 }, color = GREEN, altColor = VIOLET },
}, {
    decor = { tex = "flask", size = 22, y = 24, color = GREEN, alpha = 0.5, blend = "BLEND" },
    critReplacesDecor = true,
    particles = { tex = "bubble", count = 2, critCount = 14, size = { 5, 11 }, speed = { 20, 70 }, dir = { 40, 140 },
                  gravity = 30, life = { 0.6, 1.2 }, color = GREEN, altColor = VIOLET },
    particles2 = { tex = "puff", count = 0, critCount = 4, size = { 26, 38 }, speed = { 30, 60 }, dir = { 0, 360 },
                   gravity = 10, life = { 0.7, 1.1 }, color = VIOLET, altColor = GREEN, blend = "BLEND" },
    critTitle = title("ARTISAN ALCHEMIST", { GREEN, { 1, 1, 1 }, VIOLET }, { 0.15, 0.05, 0.25 }),
})

---------------------------------------------------------------------------
-- Blacksmithing: Anvilstrike
---------------------------------------------------------------------------
local EMBER, SPARK = { 1, 0.6, 0.2 }, { 1, 0.85, 0.45 }
prof("anvilstrike", 164, "Blacksmithing", {
    name = "Anvilstrike", tagline = "Blacksmithing: numbers hammer down; crits ring the anvil and throw forge sparks.",
    font = F.block, size = 24, outline = "THICKOUTLINE",
    color = { 1, 0.75, 0.4 }, physColor = { 1, 0.88, 0.7 }, spellColor = EMBER,
    layers = { { x = 2, y = -2, color = { 0.25, 0.1, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 44, fall = 0.12, squash = 0.35, sinkAt = 0.4, sink = 10 },
    dur = 1.1, critDur = 1.4, critScale = 1.5, pop = 0,
    particles = { tex = "spark", count = 0, critCount = 6, size = { 3, 6 }, speed = { 60, 140 }, dir = { 20, 160 },
                  gravity = -380, life = { 0.4, 0.8 }, color = SPARK, altColor = EMBER },
}, {
    shake = 3,
    ring = { size = 60, color = { 1, 0.95, 0.75 }, grow = 2.0, alpha = 0.9 },
    particles = { tex = "spark", count = 0, critCount = 18, size = { 3, 7 }, speed = { 80, 200 }, dir = { 15, 165 },
                  gravity = -380, life = { 0.4, 0.9 }, color = SPARK, altColor = EMBER },
}, {
    shake = 5,
    decor = { tex = "anvil", size = { 40, 20 }, y = -18, color = { 0.62, 0.62, 0.68 }, alpha = 0.55, blend = "BLEND" },
    critDecor = { tex = "ring", size = 70, color = EMBER, alpha = 0.8, grow = 2.4, delay = 0.12 },
    particles = { tex = "spark", count = 3, critCount = 20, size = { 3, 8 }, speed = { 80, 240 }, dir = { 10, 170 },
                  gravity = -380, life = { 0.4, 1.0 }, color = SPARK, altColor = EMBER },
    particles2 = { tex = "glow", count = 1, critCount = 4, size = { 4, 7 }, speed = { 15, 35 }, dir = { 70, 110 },
                   gravity = 15, life = { 0.6, 1.0 }, color = EMBER },
    critTitle = title("ARTISAN SMITH", { SPARK, { 1, 1, 1 }, EMBER }, { 0.25, 0.1, 0.02 }),
})

---------------------------------------------------------------------------
-- Enchanting: Runethread
---------------------------------------------------------------------------
local ARCANE, PALE = { 0.7, 0.45, 1 }, { 0.9, 0.82, 1 }
prof("runethread", 333, "Enchanting", {
    name = "Runethread", tagline = "Enchanting: violet numbers shed glittering dust; crits trace a turning rune.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 0.8, 0.65, 1 }, physColor = PALE, spellColor = ARCANE,
    layers = { { x = 2, y = -2, color = { 0.15, 0.04, 0.3, 1 } } },
    motion = "rise", motionArgs = { speed = 38, sway = 3, freq = 4 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.25,
    particles = { tex = "twinkle", count = 0, critCount = 5, size = { 6, 10 }, speed = { 10, 40 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 0.9 }, color = PALE },
}, {
    critDecor = { tex = "rune", size = 90, color = ARCANE, alpha = 0.85, spin = 1.2, snap = 0.3, snapTime = 0.15 },
    particles = { tex = "twinkle", count = 1, critCount = 10, size = { 6, 11 }, speed = { 10, 50 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 1.0 }, color = PALE, altColor = ARCANE },
}, {
    decor = { tex = "rune", size = 40, color = ARCANE, alpha = 0.25, spin = 0.8 },
    critReplacesDecor = true,
    critDecor2 = { tex = "ring", size = 70, color = PALE, alpha = 0.8, grow = 1.5 },
    particles = { tex = "twinkle", count = 3, critCount = 16, size = { 6, 12 }, speed = { 10, 60 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.1 }, color = PALE, altColor = ARCANE },
    critTitle = title("ARTISAN ENCHANTER", { PALE, { 1, 1, 1 }, ARCANE }, { 0.15, 0.04, 0.3 }),
})

---------------------------------------------------------------------------
-- Engineering: Blastcap
---------------------------------------------------------------------------
local FUSE, STEEL = { 1, 0.95, 0.6 }, { 0.7, 0.72, 0.76 }
prof("blastcap", 202, "Engineering", {
    name = "Blastcap", tagline = "Engineering: jittery numbers on a lit fuse; crits blow up in smoke and flying sprockets.",
    font = F.led, size = 22, outline = "OUTLINE",
    color = { 1, 0.88, 0.35 }, physColor = { 1, 0.95, 0.6 }, spellColor = { 1, 0.6, 0.2 },
    layers = { { x = 2, y = -2, color = { 0.2, 0.15, 0.02, 1 } } },
    motion = "zap", motionArgs = { speed = 36, step = 0.05, jolt = 3 },
    dur = 1.1, critDur = 1.4, critScale = 1.5, pop = 0.2,
    particles = { tex = "spark", count = 1, critCount = 4, size = { 3, 6 }, speed = { 10, 30 }, dir = { 60, 120 },
                  gravity = 0, life = { 0.2, 0.4 }, color = FUSE },
}, {
    shake = 4,
    critDecor = { tex = "burst", size = 120, color = { 1, 0.55, 0.15 }, alpha = 0.8, snap = 0.3, snapTime = 0.1 },
    particles = { tex = "gear", count = 0, critCount = 6, size = { 8, 12 }, speed = { 70, 150 }, dir = { 0, 360 },
                  gravity = -200, life = { 0.6, 1.0 }, color = STEEL, blend = "BLEND", spin = 6 },
    particles2 = { tex = "spark", count = 1, critCount = 0, size = { 3, 6 }, speed = { 10, 30 }, dir = { 60, 120 },
                   gravity = 0, life = { 0.2, 0.4 }, color = FUSE },
}, {
    shake = 7,
    critDecor2 = { tex = "puff", size = 100, color = { 0.45, 0.45, 0.48 }, alpha = 0.7, blend = "BLEND", grow = 1.0, delay = 0.08 },
    particles = { tex = "gear", count = 0, critCount = 10, size = { 8, 14 }, speed = { 70, 180 }, dir = { 0, 360 },
                  gravity = -200, life = { 0.6, 1.1 }, color = STEEL, blend = "BLEND", spin = 8 },
    particles2 = { tex = "spark", count = 2, critCount = 8, size = { 3, 7 }, speed = { 10, 120 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.2, 0.5 }, color = FUSE },
    critTitle = title("ARTISAN ENGINEER", { FUSE, { 1, 1, 1 }, { 1, 0.6, 0.2 } }, { 0.2, 0.15, 0.02 }),
})

---------------------------------------------------------------------------
-- Herbalism: Wildroot
---------------------------------------------------------------------------
local LEAF, POLLEN = { 0.45, 0.8, 0.3 }, { 1, 0.92, 0.45 }
prof("wildroot", 182, "Herbalism", {
    name = "Wildroot", tagline = "Herbalism: numbers sprout up on a curling stem; crits burst seed pods into pollen.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 0.6, 0.9, 0.4 }, physColor = { 0.82, 0.95, 0.6 }, spellColor = { 0.55, 0.95, 0.45 },
    layers = { { x = 2, y = -2, color = { 0.06, 0.18, 0.03, 1 } } },
    motion = "rise", motionArgs = { speed = 34 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.5,
    particles = { tex = "leaf", count = 0, critCount = 4, size = { 8, 12 }, speed = { 20, 50 }, dir = { 30, 150 },
                  gravity = -40, life = { 0.6, 1.0 }, color = LEAF, blend = "BLEND", spin = 3 },
}, {
    critDecor = { tex = "sprout", size = 70, y = -18, color = LEAF, alpha = 0.9, blend = "BLEND", snap = 0.2, snapTime = 0.25 },
    particles2 = { tex = "glow", count = 0, critCount = 10, size = { 3, 5 }, speed = { 15, 45 }, dir = { 0, 360 },
                   gravity = 8, life = { 0.9, 1.6 }, color = POLLEN },
}, {
    decor = { tex = "sprout", size = 34, y = -16, color = LEAF, alpha = 0.6, blend = "BLEND", snap = 0.2, snapTime = 0.25 },
    critReplacesDecor = true,
    particles = { tex = "leaf", count = 0, critCount = 8, size = { 8, 13 }, speed = { 20, 60 }, dir = { 20, 160 },
                  gravity = -40, life = { 0.6, 1.1 }, color = LEAF, blend = "BLEND", spin = 3 },
    particles2 = { tex = "glow", count = 2, critCount = 14, size = { 3, 6 }, speed = { 15, 50 }, dir = { 0, 360 },
                   gravity = 8, life = { 0.9, 1.7 }, color = POLLEN },
    critTitle = title("ARTISAN HERBALIST", { POLLEN, { 1, 1, 1 }, { 0.6, 0.9, 0.4 } }, { 0.06, 0.18, 0.03 }),
})

---------------------------------------------------------------------------
-- Leatherworking: Stitchwork
---------------------------------------------------------------------------
local TAN, HIDE = { 0.95, 0.8, 0.55 }, { 0.55, 0.35, 0.15 }
prof("stitchwork", 165, "Leatherworking", {
    name = "Stitchwork", tagline = "Leatherworking: tan numbers on a stitched patch; crits stamp a tooled seal and shed scraps.",
    font = F.friz, size = 23, outline = "THICKOUTLINE",
    color = { 0.88, 0.66, 0.42 }, physColor = { 0.92, 0.78, 0.58 }, spellColor = { 0.95, 0.6, 0.3 },
    layers = { { x = 2, y = -2, color = { 0.22, 0.12, 0.04, 1 } } },
    motion = "rise", motionArgs = { speed = 30 },
    dur = 1.15, critDur = 1.45, critScale = 1.5, pop = 0.2,
    decor = { tex = "stitch", size = { 72, 36 }, color = TAN, alpha = 0.55, blend = "BLEND" },
    particles = { tex = "pixel", count = 0, critCount = 4, size = { 4, 7 }, speed = { 30, 80 }, dir = { 20, 160 },
                  gravity = -200, life = { 0.6, 1.0 }, color = HIDE, altColor = { 0.7, 0.48, 0.25 }, blend = "BLEND", spin = 5 },
}, {
    shake = 2,
    critDecor = { tex = "ring", size = 80, color = HIDE, alpha = 1, blend = "BLEND", snap = 1.8, snapTime = 0.08 },
    particles = { tex = "pixel", count = 0, critCount = 8, size = { 4, 8 }, speed = { 30, 100 }, dir = { 20, 160 },
                  gravity = -200, life = { 0.6, 1.1 }, color = HIDE, altColor = { 0.7, 0.48, 0.25 }, blend = "BLEND", spin = 5 },
}, {
    critDecor2 = { tex = "stitch", size = { 124, 62 }, color = { 1, 0.85, 0.55 }, alpha = 0.9, blend = "BLEND", snap = 1.4, snapTime = 0.1 },
    particles = { tex = "pixel", count = 1, critCount = 12, size = { 4, 8 }, speed = { 30, 110 }, dir = { 15, 165 },
                  gravity = -200, life = { 0.6, 1.1 }, color = HIDE, altColor = { 0.7, 0.48, 0.25 }, blend = "BLEND", spin = 5 },
    critTitle = title("ARTISAN LEATHERWORKER", { TAN, { 1, 1, 1 }, { 0.95, 0.6, 0.3 } }, { 0.22, 0.12, 0.04 }),
})

---------------------------------------------------------------------------
-- Mining: Motherlode
---------------------------------------------------------------------------
local STONE, COPPER, GOLDORE = { 0.55, 0.52, 0.48 }, { 0.85, 0.5, 0.3 }, { 0.95, 0.8, 0.3 }
prof("motherlode", 186, "Mining", {
    name = "Motherlode", tagline = "Mining: stone-gray numbers chip loose; crits crack open a vein and spill ore.",
    font = F.block, size = 24, outline = "THICKOUTLINE",
    color = { 0.78, 0.75, 0.7 }, physColor = { 0.85, 0.82, 0.76 }, spellColor = GOLDORE,
    layers = { { x = 2, y = -2, color = { 0.15, 0.13, 0.1, 1 } } },
    motion = "rise", motionArgs = { speed = 28 },
    dur = 1.15, critDur = 1.45, critScale = 1.5, pop = 0.25,
    particles = { tex = "pixel", count = 2, critCount = 6, size = { 3, 5 }, speed = { 40, 90 }, dir = { 30, 150 },
                  gravity = -320, life = { 0.4, 0.8 }, color = STONE, blend = "BLEND", spin = 6 },
}, {
    shake = 3,
    critDecor = { tex = "crack", size = 90, color = GOLDORE, alpha = 0.9, snap = 0.4, snapTime = 0.08 },
    particles2 = { tex = "shard", count = 0, critCount = 8, size = { 7, 10 }, speed = { 70, 150 }, dir = { 30, 150 },
                   gravity = -380, life = { 0.6, 1.0 }, color = COPPER, altColor = GOLDORE, blend = "BLEND", spin = 6 },
}, {
    critDecor2 = { tex = "twinkle", size = 44, color = { 1, 0.95, 0.7 }, alpha = 1, delay = 0.1, snap = 0.3, snapTime = 0.12 },
    particles = { tex = "pixel", count = 3, critCount = 8, size = { 3, 6 }, speed = { 40, 100 }, dir = { 30, 150 },
                  gravity = -320, life = { 0.4, 0.8 }, color = STONE, blend = "BLEND", spin = 6 },
    particles2 = { tex = "shard", count = 0, critCount = 14, size = { 7, 11 }, speed = { 70, 170 }, dir = { 25, 155 },
                   gravity = -380, life = { 0.6, 1.1 }, color = COPPER, altColor = GOLDORE, blend = "BLEND", spin = 6 },
    critTitle = title("ARTISAN MINER", { GOLDORE, { 1, 1, 1 }, COPPER }, { 0.15, 0.13, 0.1 }),
})

---------------------------------------------------------------------------
-- Skinning: Keen Edge
---------------------------------------------------------------------------
local BLADE, FUR = { 0.95, 0.97, 1 }, { 0.6, 0.45, 0.3 }
prof("keenedge", 393, "Skinning", {
    name = "Keen Edge", tagline = "Skinning: numbers slide in on a curved knife stroke; crits flense a wide arc and shed fur.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 0.92, 0.88, 0.82 }, physColor = { 0.95, 0.92, 0.86 }, spellColor = { 0.85, 0.45, 0.3 },
    layers = { { x = 2, y = -2, color = { 0.22, 0.1, 0.06, 1 } } },
    motion = "dash", motionArgs = { arrive = true, dist = 50, time = 0.15, rise = 22 },
    dur = 1.1, critDur = 1.4, critScale = 1.5, pop = 0.15,
    decor = { tex = "arc", size = 70, y = -6, color = BLADE, alpha = 0.7 },
    particles = { tex = "puff", count = 0, critCount = 4, size = { 6, 10 }, speed = { 15, 50 }, dir = { 200, 340 },
                  gravity = -60, life = { 0.8, 1.3 }, color = FUR, blend = "BLEND" },
}, {
    critReplacesDecor = true,
    critDecor = { tex = "arc", size = 130, color = BLADE, alpha = 0.95, snap = 0.6, snapTime = 0.1 },
    particles = { tex = "puff", count = 0, critCount = 8, size = { 6, 11 }, speed = { 15, 60 }, dir = { 200, 340 },
                  gravity = -60, life = { 0.8, 1.4 }, color = FUR, altColor = { 0.78, 0.65, 0.48 }, blend = "BLEND" },
}, {
    critDecor2 = { tex = "arc", size = 110, color = { 0.85, 0.3, 0.25 }, alpha = 0.8, rot = 3.14, delay = 0.06, snap = 0.6, snapTime = 0.1 },
    particles = { tex = "puff", count = 1, critCount = 12, size = { 6, 12 }, speed = { 15, 70 }, dir = { 190, 350 },
                  gravity = -60, life = { 0.8, 1.4 }, color = FUR, altColor = { 0.78, 0.65, 0.48 }, blend = "BLEND" },
    critTitle = title("ARTISAN SKINNER", { BLADE, { 0.95, 0.85, 0.7 }, { 0.85, 0.45, 0.3 } }, { 0.22, 0.1, 0.06 }),
})

---------------------------------------------------------------------------
-- Tailoring: Bolt of Cloth
---------------------------------------------------------------------------
local THREAD, CLOTH, GILT = { 0.95, 0.45, 0.7 }, { 0.55, 0.35, 0.85 }, { 0.95, 0.8, 0.4 }
prof("boltofcloth", 197, "Tailoring", {
    name = "Bolt of Cloth", tagline = "Tailoring: a thread stitches under each number; crits unfurl a ribbon of cloth.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 0.85, 0.7, 1 }, physColor = { 0.95, 0.9, 1 }, spellColor = { 0.9, 0.45, 0.8 },
    layers = { { x = 2, y = -2, color = { 0.18, 0.08, 0.28, 1 } } },
    motion = "spiral", motionArgs = { spin = 3, r0 = 4, grow = 10, rise = 34 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.2,
    decor = { tex = "thread", size = { 80, 20 }, y = -14, color = THREAD, alpha = 0.7, blend = "BLEND" },
    particles = { tex = "twinkle", count = 0, critCount = 3, size = { 6, 10 }, speed = { 10, 40 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 0.9 }, color = { 1, 0.85, 0.95 } },
}, {
    critDecor = { tex = "ribbon", size = { 150, 38 }, y = -10, color = CLOTH, alpha = 0.9, blend = "BLEND", snap = 0.2, snapTime = 0.25 },
    particles = { tex = "twinkle", count = 0, critCount = 6, size = { 6, 10 }, speed = { 10, 50 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 1.0 }, color = { 1, 0.85, 0.95 } },
}, {
    critDecor2 = { tex = "ribbon", size = { 130, 32 }, y = 12, color = GILT, alpha = 0.8, blend = "BLEND", rot = 3.14, snap = 0.2, snapTime = 0.3, delay = 0.08 },
    particles = { tex = "twinkle", count = 1, critCount = 10, size = { 6, 11 }, speed = { 10, 60 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 1.1 }, color = { 1, 0.85, 0.95 }, altColor = GILT },
    critTitle = title("ARTISAN TAILOR", { { 1, 0.85, 0.95 }, { 1, 1, 1 }, GILT }, { 0.18, 0.08, 0.28 }),
})

---------------------------------------------------------------------------
-- Cooking: Sizzle
---------------------------------------------------------------------------
local STEAM, GREASE = { 0.9, 0.9, 0.9 }, { 1, 0.9, 0.55 }
prof("sizzle", 185, "Cooking", {
    name = "Sizzle", tagline = "Cooking: numbers hop like they're in a hot pan, trailing steam; crits spit grease.",
    font = F.block, size = 23, outline = "THICKOUTLINE",
    color = { 1, 0.78, 0.4 }, physColor = { 1, 0.88, 0.6 }, spellColor = { 1, 0.55, 0.2 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.12, 0.02, 1 } } },
    motion = "bounce", motionArgs = { vx = { -10, 10 }, vy = 150, gravity = 600, floor = -4, damp = 0.45 },
    dur = 1.15, critDur = 1.45, critScale = 1.5, pop = 0.1,
    particles = { tex = "puff", count = 1, critCount = 2, size = { 10, 16 }, speed = { 15, 30 }, dir = { 80, 100 },
                  gravity = 10, life = { 0.6, 1.0 }, color = STEAM, blend = "BLEND", sway = true },
}, {
    critDecor = { tex = "splat", size = 70, color = GREASE, alpha = 0.6, blend = "BLEND", snap = 0.4, snapTime = 0.08 },
    particles2 = { tex = "drop", count = 0, critCount = 10, size = { 4, 7 }, speed = { 70, 150 }, dir = { 20, 160 },
                   gravity = -420, life = { 0.4, 0.8 }, color = GREASE },
}, {
    shake = 2, critScale = 1.65,
    particles = { tex = "puff", count = 2, critCount = 4, size = { 10, 18 }, speed = { 15, 35 }, dir = { 75, 105 },
                  gravity = 10, life = { 0.6, 1.1 }, color = STEAM, blend = "BLEND", sway = true },
    particles2 = { tex = "drop", count = 0, critCount = 16, size = { 4, 8 }, speed = { 70, 180 }, dir = { 15, 165 },
                   gravity = -420, life = { 0.4, 0.9 }, color = GREASE },
    critTitle = title("ARTISAN COOK", { GREASE, { 1, 1, 1 }, { 1, 0.55, 0.2 } }, { 0.3, 0.12, 0.02 }),
})

---------------------------------------------------------------------------
-- Fishing: Lucky Bobber
---------------------------------------------------------------------------
local WATER, SPRAY, FISHGOLD = { 0.7, 0.9, 1 }, { 0.75, 0.9, 1 }, { 1, 0.82, 0.3 }
prof("luckybobber", 356, "Fishing", {
    name = "Lucky Bobber", tagline = "Fishing: numbers bob beside a red bobber; crits plunge it with a splash and a leaping fish.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 0.6, 0.85, 1 }, physColor = { 0.78, 0.92, 1 }, spellColor = { 0.4, 0.75, 1 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.12, 0.25, 1 } } },
    motion = "bob", motionArgs = { speed = 22, amp = 3, freq = 8 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.2,
    decor = { tex = "bobber", size = 14, x = 28, y = -10, color = { 1, 0.3, 0.25 }, alpha = 1, blend = "BLEND" },
    particles = { tex = "drop", count = 0, critCount = 5, size = { 4, 7 }, speed = { 60, 120 }, dir = { 50, 130 },
                  gravity = -350, life = { 0.4, 0.8 }, color = SPRAY },
}, {
    critReplacesDecor = true,
    critDecor = { tex = "ripple", size = { 110, 40 }, y = -14, color = WATER, alpha = 0.9, grow = 1.2 },
    particles = { tex = "drop", count = 0, critCount = 10, size = { 4, 7 }, speed = { 60, 140 }, dir = { 50, 130 },
                  gravity = -350, life = { 0.4, 0.9 }, color = SPRAY },
    particles2 = { tex = "fish", count = 0, critCount = 1, size = { 30, 30 }, aspect = 0.5, speed = { 120, 140 }, dir = { 100, 115 },
                   gravity = -300, life = { 0.8, 0.9 }, color = { 0.62, 0.84, 0.78 }, blend = "BLEND", orient = true },
}, {
    decor = { tex = "bobber", size = 15, x = 28, y = -10, color = { 1, 0.3, 0.25 }, alpha = 1, blend = "BLEND" },
    critDecor2 = { tex = "ripple", size = { 150, 52 }, y = -14, color = { 1, 1, 1 }, alpha = 0.6, grow = 1.4, delay = 0.12 },
    particles = { tex = "drop", count = 0, critCount = 14, size = { 4, 8 }, speed = { 60, 160 }, dir = { 45, 135 },
                  gravity = -350, life = { 0.4, 0.9 }, color = SPRAY },
    particles2 = { tex = "fish", count = 0, critCount = 1, size = { 34, 34 }, aspect = 0.5, speed = { 130, 150 }, dir = { 100, 115 },
                   gravity = -300, life = { 0.85, 0.95 }, color = FISHGOLD, orient = true },
    critTitle = title("ARTISAN ANGLER", { FISHGOLD, { 1, 1, 1 }, WATER }, { 0.03, 0.12, 0.25 }),
})

---------------------------------------------------------------------------
-- First Aid: Field Dressing
---------------------------------------------------------------------------
local RED, LINEN = { 0.9, 0.15, 0.15 }, { 0.96, 0.93, 0.86 }
prof("fielddressing", 129, "First Aid", {
    name = "Field Dressing", tagline = "First Aid: clean white numbers under a red cross; crits wrap a bandage round them.",
    font = F.arialn, size = 24, outline = "OUTLINE",
    color = { 1, 1, 1 }, physColor = { 1, 1, 1 }, spellColor = { 1, 0.55, 0.55 },
    layers = { { x = 2, y = -2, color = { 0.25, 0.04, 0.04, 1 } } },
    motion = "rise", motionArgs = { speed = 32 },
    dur = 1.1, critDur = 1.4, critScale = 1.5, pop = 0.2,
    decor = { tex = "cross", size = 12, y = 22, color = RED, alpha = 1, blend = "BLEND" },
    particles = { tex = "cross", count = 0, critCount = 3, size = { 8, 12 }, speed = { 30, 60 }, dir = { 45, 135 },
                  gravity = -60, life = { 0.6, 1.0 }, color = RED, blend = "BLEND" },
}, {
    critDecor = { tex = "bandage", size = { 130, 30 }, color = LINEN, alpha = 0.9, blend = "BLEND", rot = -0.25, snap = 0.3, snapTime = 0.18 },
    particles = { tex = "cross", count = 0, critCount = 5, size = { 8, 12 }, speed = { 30, 70 }, dir = { 40, 140 },
                  gravity = -60, life = { 0.6, 1.0 }, color = RED, blend = "BLEND" },
}, {
    critDecor2 = { tex = "cross", size = 46, y = 30, color = RED, alpha = 0.9, blend = "BLEND", snap = 1.6, snapTime = 0.1 },
    particles = { tex = "cross", count = 0, critCount = 8, size = { 8, 13 }, speed = { 30, 80 }, dir = { 30, 150 },
                  gravity = -60, life = { 0.6, 1.1 }, color = RED, blend = "BLEND" },
    critTitle = title("ARTISAN MEDIC", { { 1, 1, 1 }, LINEN, { 1, 0.55, 0.55 } }, { 0.25, 0.04, 0.04 }),
})
