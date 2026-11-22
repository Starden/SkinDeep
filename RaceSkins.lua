local _, ns = ...

-- Race skins: one for each race, earned by reaching level 10 on a
-- character of that race (Feats.lua). race: UnitRace's English token.

local F = ns.Fonts
local add = ns.AddSkin

local GOLD = { 1, 0.82, 0.3 }
local WHITE = { 1, 1, 1 }

---------------------------------------------------------------------------
-- Human: Royal Seal. Steel-blue numbers; crits stamp a red wax seal.
---------------------------------------------------------------------------
add("royalseal", {
    group = "race", race = "Human", listNote = "Human",
    name = "Royal Seal", tagline = "Human: steel-blue numbers with a gold glint; crits stamp a red wax seal under two gold ribbons.",
    font = F.friz, size = 25, outline = "OUTLINE",
    color = { 0.82, 0.88, 1 }, physColor = { 0.9, 0.93, 1 }, spellColor = { 1, 0.85, 0.42 },
    layers = { { x = 2, y = -2, color = { 0.05, 0.1, 0.28, 1 } } },
    motion = "rise", motionArgs = { speed = 24 },
    dur = 1.15, critDur = 1.6, critScale = 1.5, pop = 0.25, shake = 3, shakeAt = 0.05,
    critPieces = {
        { tex = "ribbon", size = { 56, 14 }, x = -18, y = -40, rot = 1.15, delay = 0.08, snap = 0.4, snapTime = 0.12, hold = true,
          color = GOLD, alpha = 1, blend = "BLEND" },
        { tex = "ribbon", size = { 56, 14 }, x = 18, y = -40, rot = -1.15, delay = 0.08, snap = 0.4, snapTime = 0.12, hold = true,
          color = GOLD, alpha = 1, blend = "BLEND" },
        { tex = "waxseal", size = 78, snap = 1.8, snapTime = 0.12, hold = true, color = { 0.66, 0.07, 0.1 }, alpha = 1, blend = "BLEND" },
    },
    particles = { tex = "twinkle", count = 1, critCount = 8, size = { 7, 12 }, speed = { 15, 60 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.4, 0.8 }, delay = 0.05, color = GOLD, altColor = WHITE },
})

---------------------------------------------------------------------------
-- Dwarf: Hearth Ale. Amber numbers on rising foam; crits clink two mugs.
---------------------------------------------------------------------------
local ALE = { 1, 0.8, 0.45 }
add("hearthale", {
    group = "race", race = "Dwarf", listNote = "Dwarf",
    name = "Hearth Ale", tagline = "Dwarf: amber numbers rise on foam bubbles; crits clink two mugs in a splash of foam and call CHEERS!",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.76, 0.3 }, physColor = { 1, 0.86, 0.56 }, spellColor = { 1, 0.6, 0.22 },
    layers = { { x = 2, y = -2, color = { 0.35, 0.15, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 24 },
    dur = 1.2, critDur = 1.7, critScale = 1.5, pop = 0.2, shake = 2, shakeAt = 0.18,
    critPieces = {
        { tex = "mug", size = 42, x = -24, y = 34, rot = 0.3, from = { -90, 30 }, fromRot = 0, move = 0.18, ease = "in", life = 1.0,
          wobble = { 0.15, 40, 8 }, color = ALE, alpha = 1, blend = "BLEND" },
        { tex = "mugleft", size = 42, x = 24, y = 34, rot = -0.3, from = { 90, 30 }, fromRot = 0, move = 0.18, ease = "in", life = 1.0,
          wobble = { 0.15, 40, 8 }, color = ALE, alpha = 1, blend = "BLEND" },
    },
    critTitle = { text = "CHEERS!", y = 64, size = 16, font = F.skurri, pop = 1.5, delay = 0.2,
                  colors = { { 1, 0.86, 0.45 }, { 1, 1, 1 }, { 1, 0.6, 0.2 } }, shadowColor = { 0.3, 0.12, 0 } },
    particles = { tex = "bubble", count = 3, critCount = 4, size = { 5, 9 }, speed = { 20, 40 }, dir = { 80, 100 },
                  spread = { 60, 10 }, origin = { 0, -12 }, gravity = 10, life = { 0.6, 1.0 }, color = { 1, 0.95, 0.8 }, sway = true },
    particles2 = { tex = "glow", count = 0, critCount = 12, size = { 5, 9 }, speed = { 60, 130 }, dir = { 30, 150 },
                   origin = { 0, 50 }, delay = 0.18, gravity = -260, life = { 0.5, 0.8 }, color = { 1, 0.97, 0.88 } },
})

---------------------------------------------------------------------------
-- Night Elf: Moonwell. Silver-violet numbers over a rippling pool; crits
-- raise a crescent moon as wisps drift up.
---------------------------------------------------------------------------
local LILAC, WISP = { 0.72, 0.62, 1 }, { 0.6, 1, 0.92 }
add("moonwell", {
    group = "race", race = "NightElf", listNote = "Night Elf",
    name = "Moonwell", tagline = "Night Elf: silver-violet numbers over a rippling pool; crits raise a crescent moon as wisps drift up.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.86, 0.8, 1 }, physColor = { 0.93, 0.9, 1 }, spellColor = { 0.62, 0.95, 0.9 },
    layers = { { x = 2, y = -2, color = { 0.12, 0.05, 0.3, 1 } } },
    motion = "rise", motionArgs = { speed = 22, sway = 2, freq = 3 },
    dur = 1.3, critDur = 1.8, critScale = 1.5, pop = 0.2,
    hitPieces = {
        { tex = "ripple", size = { 64, 18 }, y = -20, grow = 0.8, life = 0.7, color = LILAC, alpha = 0.7 },
    },
    critPieces = {
        { tex = "moon", size = 36, y = 46, from = { 0, 22 }, move = 0.5, hold = true, color = { 0.95, 0.93, 1 }, alpha = 1 },
        { tex = "ripple", size = { 90, 24 }, y = -24, grow = 1.2, life = 0.7, color = LILAC, alpha = 0.8 },
        { tex = "ripple", size = { 90, 24 }, y = -24, grow = 1.2, delay = 0.2, life = 0.7, color = LILAC, alpha = 0.7 },
        { tex = "ripple", size = { 90, 24 }, y = -24, grow = 1.2, delay = 0.4, life = 0.7, color = WISP, alpha = 0.6 },
    },
    particles = { tex = "glow", count = 0, critCount = 10, size = { 5, 8 }, speed = { 20, 40 }, dir = { 80, 100 },
                  spread = { 120, 10 }, origin = { 0, -20 }, gravity = 5, life = { 0.9, 1.4 }, color = WISP, altColor = LILAC, sway = true, drag = 0 },
})

---------------------------------------------------------------------------
-- Gnome: Pocket Rocket. Numbers launch on a tiny rocket; crits burst in
-- sparkles and confetti.
---------------------------------------------------------------------------
add("pocketrocket", {
    group = "race", race = "Gnome", listNote = "Gnome",
    name = "Pocket Rocket", tagline = "Gnome: numbers launch on a tiny rocket with a smoke trail; crits burst in sparkles and confetti.",
    font = F.block, size = 23, outline = "OUTLINE",
    color = { 0.5, 0.95, 0.9 }, physColor = { 0.76, 1, 0.95 }, spellColor = { 1, 0.56, 0.86 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.2, 0.22, 1 } } },
    motion = "rise", motionArgs = { speed = 46 },
    dur = 1.1, critDur = 1.6, critScale = 1.55, pop = 0.2,
    hitPieces = {
        { tex = "rocket", size = { 16, 32 }, x = -34, y = -2, hold = true, color = { 0.92, 0.94, 0.97 }, alpha = 1, blend = "BLEND" },
        { tex = "flame", size = { 9, 15 }, x = -34, y = -24, rot = math.pi, hold = true, flicker = true, color = { 1, 0.65, 0.2 }, alpha = 1 },
    },
    critPieces = {
        { tex = "rocket", size = { 18, 36 }, y = -36, from = { 0, -60 }, move = 0.3, life = 0.42, color = { 0.92, 0.94, 0.97 }, alpha = 1, blend = "BLEND" },
        { tex = "burst", size = 120, y = 6, delay = 0.33, life = 0.4, snap = 0.3, snapTime = 0.1, color = { 1, 0.95, 0.7 }, alpha = 0.8 },
    },
    -- Smoke left behind as it climbs (particles stay where the hit began).
    particles = { tex = "puff", count = 4, critCount = 5, size = { 7, 12 }, speed = { 5, 15 }, dir = { 250, 290 },
                  origin = { -10, -20 }, delay = { 0, 0.4 }, gravity = 0, life = { 0.4, 0.7 }, color = { 0.82, 0.84, 0.88 }, blend = "BLEND" },
    particles2 = { tex = "pixel", count = 0, critCount = 16, size = { 4, 6 }, speed = { 60, 150 }, dir = { 0, 360 },
                   delay = 0.33, origin = { 0, 10 }, gravity = -170, life = { 0.6, 1.0 }, randomColor = true, spin = 8, blend = "BLEND", shrink = 0 },
})

---------------------------------------------------------------------------
-- Orc: Axe and Fury. A thrown axe thunks in beside each hit; crits cleave
-- a red slash and roar.
---------------------------------------------------------------------------
add("axefury", {
    group = "race", race = "Orc", listNote = "Orc",
    name = "Axe and Fury", tagline = "Orc: a thrown axe spins in and thunks beside each hit; crits cleave a jagged red slash and roar LOK'TAR!",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 1, 0.6, 0.42 }, physColor = { 1, 0.8, 0.68 }, spellColor = { 1, 0.42, 0.3 },
    layers = { { x = 2, y = -2, color = { 0.35, 0.04, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 22 },
    dur = 1.15, critDur = 1.6, critScale = 1.55, pop = 0.2, shake = 6,
    hitPieces = {
        { tex = "throwaxe", size = 30, x = 44, y = 6, rot = 0.5, from = { 120, 40 }, fromRot = -12, move = 0.15, delay = 0.04,
          life = 0.75, wobble = { 0.15, 45, 9 }, color = { 0.86, 0.86, 0.9 }, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "slash", size = { 180, 30 }, rot = -0.45, from = { -40, 20 }, move = 0.08, life = 0.4, front = true, color = { 1, 0.15, 0.1 }, alpha = 1 },
        { tex = "crack", size = 110, delay = 0.05, life = 0.6, snap = 0.5, snapTime = 0.1, color = { 0.9, 0.2, 0.1 }, alpha = 0.8 },
    },
    critTitle = { text = "LOK'TAR!", y = 46, size = 18, font = F.skurri, pop = 1.5, delay = 0.12,
                  colors = { { 1, 0.35, 0.2 }, { 1, 0.85, 0.5 }, { 1, 1, 1 } }, shadowColor = { 0.3, 0.02, 0 } },
    particles = { tex = "spark", count = 0, critCount = 10, size = { 6, 10 }, aspect = 0.4, speed = { 100, 200 }, dir = { 0, 360 },
                  gravity = -200, life = { 0.25, 0.45 }, color = { 1, 0.6, 0.3 }, orient = true, drag = 0 },
})

---------------------------------------------------------------------------
-- Undead: Banshee Wail. Pale, flickering numbers; crits pulse out rings of
-- sound as spirit streaks fly off.
---------------------------------------------------------------------------
local GHOST = { 0.62, 1, 0.88 }
add("bansheewail", {
    group = "race", race = "Scourge", listNote = "Undead",
    name = "Banshee Wail", tagline = "Undead: pale, flickering numbers drift up; crits pulse out rings of sound as spirit streaks fly off.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.72, 1, 0.9 }, physColor = { 0.86, 1, 0.95 }, spellColor = { 0.6, 1, 0.76 },
    layers = { { x = 2, y = -2, color = { 0.02, 0.15, 0.12, 1 } } },
    motion = "rise", motionArgs = { speed = 26, sway = 4, freq = 9 },
    flicker = true, fadeIn = 0.15,
    dur = 1.25, critDur = 1.7, critScale = 1.5, pop = 0.2, shake = 3,
    critPieces = {
        { tex = "soundwave", size = { 150, 64 }, grow = 0.6, life = 0.45, color = GHOST, alpha = 0.9 },
        { tex = "soundwave", size = { 150, 64 }, grow = 0.6, delay = 0.13, life = 0.45, color = GHOST, alpha = 0.8 },
        { tex = "soundwave", size = { 150, 64 }, grow = 0.6, delay = 0.26, life = 0.45, color = WHITE, alpha = 0.6 },
    },
    particles = { tex = "glow", count = 1, critCount = 4, size = { 6, 10 }, speed = { 10, 25 }, dir = { 80, 100 },
                  gravity = 0, life = { 0.6, 1.0 }, color = GHOST, sway = true },
    particles2 = { tex = "spark", count = 0, critCount = 8, size = { 10, 18 }, aspect = 0.25, speed = { 120, 200 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.35, 0.6 }, color = { 0.85, 1, 0.95 }, orient = true, drag = 1 },
})

---------------------------------------------------------------------------
-- Tauren: Totem Stomp. A small totem rises behind each hit; crits raise
-- two and stomp the ground.
---------------------------------------------------------------------------
local WOOD, DUST = { 0.66, 0.44, 0.26 }, { 0.78, 0.66, 0.48 }
add("totemstomp", {
    group = "race", race = "Tauren", listNote = "Tauren",
    name = "Totem Stomp", tagline = "Tauren: a small totem rises beside each hit; crits raise two tall totems, stomp the ground and kick up dust.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 0.95, 0.85, 0.62 }, physColor = { 1, 0.92, 0.76 }, spellColor = { 0.62, 0.86, 1 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.16, 0.05, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.2, critDur = 1.7, critScale = 1.55, pop = 0, noSpring = true, shake = 7, shakeAt = 0.25,
    -- Held big, then the stomp.
    critScaleKeys = { { 0, 1.25 }, { 0.24, 1.25 }, { 0.29, 0.88 }, { 0.45, 1 } },
    hitPieces = {
        { tex = "totem", size = { 14, 42 }, x = 44, y = 2, reveal = "up", move = 0.25, life = 0.8, color = WOOD, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "totem", size = { 22, 66 }, x = -46, y = 12, reveal = "up", move = 0.22, hold = true, color = WOOD, alpha = 1, blend = "BLEND" },
        { tex = "totem", size = { 22, 66 }, x = 46, y = 12, reveal = "up", move = 0.22, delay = 0.06, hold = true, color = WOOD, alpha = 1, blend = "BLEND" },
        { tex = "crack", size = { 140, 50 }, y = -26, delay = 0.25, life = 0.7, snap = 0.5, snapTime = 0.1, color = { 0.45, 0.3, 0.15 }, alpha = 0.9, blend = "BLEND" },
        { tex = "ripple", size = { 150, 40 }, y = -26, grow = 0.8, delay = 0.25, life = 0.5, color = DUST, alpha = 0.8 },
    },
    particles = { tex = "puff", count = 0, critCount = 10, size = { 10, 18 }, speed = { 40, 100 }, dir = { 10, 170 },
                  origin = { 0, -26 }, delay = 0.25, gravity = -90, life = { 0.5, 0.9 }, color = DUST, blend = "BLEND", drag = 2 },
})

---------------------------------------------------------------------------
-- Troll: Berserk. Two tusks bracket each hit; crits snap them shut in a
-- red flare.
---------------------------------------------------------------------------
local IVORY = { 0.96, 0.93, 0.84 }
add("berserk", {
    group = "race", race = "Troll", listNote = "Troll",
    name = "Berserk", tagline = "Troll: two tusks bracket each hit; crits snap the tusks shut in a red flare and call BERSERK!",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.6, 1, 0.72 }, physColor = { 0.82, 1, 0.87 }, spellColor = { 0.42, 0.95, 0.86 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.25, 0.12, 1 } } },
    motion = "rise", motionArgs = { speed = 22 },
    dur = 1.15, critDur = 1.6, critScale = 1.5, pop = 0.2, shake = 6, shakeAt = 0.12,
    -- Crits see red.
    critCycle = { { 1, 0.6, 0.42 } },
    glowColor = { 1, 0.35, 0.15 },
    hitPieces = {
        { tex = "tusk", size = { 14, 28 }, x = -42, hold = true, color = IVORY, alpha = 1, blend = "BLEND" },
        { tex = "tuskright", size = { 14, 28 }, x = 42, hold = true, color = IVORY, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "glow", size = 170, delay = 0.12, life = 0.5, color = { 1, 0.32, 0.12 }, alpha = 0.85 },
        { tex = "tusk", size = { 22, 44 }, x = -36, from = { -80, 0 }, move = 0.13, ease = "in", hold = true, color = IVORY, alpha = 1, blend = "BLEND" },
        { tex = "tuskright", size = { 22, 44 }, x = 36, from = { 80, 0 }, move = 0.13, ease = "in", hold = true, color = IVORY, alpha = 1, blend = "BLEND" },
    },
    critTitle = { text = "BERSERK!", y = 46, size = 17, font = F.skurri, pop = 1.5, delay = 0.15,
                  colors = { { 1, 0.45, 0.25 }, { 1, 0.9, 0.5 }, { 1, 1, 1 } }, shadowColor = { 0.3, 0.05, 0 } },
    particles = { tex = "spark", count = 0, critCount = 10, size = { 4, 8 }, speed = { 80, 160 }, dir = { 0, 360 },
                  delay = 0.12, gravity = -120, life = { 0.3, 0.5 }, color = { 1, 0.5, 0.25 } },
})
