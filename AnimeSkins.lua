local _, ns = ...

-- Anime skins: original takes on the genre's famous looks (a pirate's
-- bounty, a soul blade's crescent, a ninja's smoke, a dramatic barrage...),
-- never the shows' own characters, symbols or lines. Each is earned by a
-- secret feat (Feats.lua) and has its own Anime tab.

local F = ns.Fonts
local add = ns.AddSkin

local GOLD = { 1, 0.82, 0.3 }
local WHITE = { 1, 1, 1 }

---------------------------------------------------------------------------
-- Most Wanted: rubbery numbers; a crit is the bounty on a wanted poster.
---------------------------------------------------------------------------
add("mostwanted", {
    group = "anime", listNote = "Secret",
    name = "Most Wanted", tagline = "Rubbery numbers stretch and snap back; crits slap down a wanted poster with your crit as the bounty.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.84, 0.35 }, physColor = { 1, 0.92, 0.62 }, spellColor = { 1, 0.6, 0.28 },
    layers = { { x = 2, y = -2, color = { 0.45, 0.08, 0.04, 1 } } },
    motion = "boing", motionArgs = { speed = 24, amp = 0.45, freq = 24, decay = 6 },
    dur = 1.2, critDur = 1.75, critScale = 1.55, pop = 0,
    -- Stretch marks either side as it snaps back.
    hitPieces = {
        { tex = "speedlines", size = { 40, 22 }, x = -46, life = 0.25, color = { 1, 0.9, 0.6 }, alpha = 0.6 },
        { tex = "speedlines", size = { 40, 22 }, x = 46, rot = math.pi, life = 0.25, color = { 1, 0.9, 0.6 }, alpha = 0.6 },
    },
    -- The bounty is written in red ink on the poster.
    critCycle = { { 0.82, 0.14, 0.08 } },
    critPieces = {
        { tex = "poster", size = { 84, 104 }, y = -4, rot = -0.05, fromRot = -0.4, snap = 1.6, snapTime = 0.14, move = 0.14,
          hold = true, color = { 0.95, 0.84, 0.62 }, alpha = 1, blend = "BLEND" },
    },
    critTitle = { text = "WANTED", y = 33, size = 15, font = F.morpheus, pop = 0.8,
                  colors = { { 0.42, 0.24, 0.08 } }, shadowColor = { 0.9, 0.78, 0.52 } },
    glowColor = { 1, 0.85, 0.45 },
    particles2 = { tex = "coin", count = 0, critCount = 9, size = { 9, 13 }, speed = { 60, 140 }, dir = { 30, 150 },
                   gravity = -380, life = { 0.6, 1.0 }, delay = 0.12, spin = 6, color = GOLD, blend = "BLEND" },
})

---------------------------------------------------------------------------
-- Black Crescent: a blade flick on every hit; crits turn black and red as
-- a crescent of energy tears across.
---------------------------------------------------------------------------
add("blackcrescent", {
    group = "anime", listNote = "Secret",
    name = "Black Crescent", tagline = "A thin blade flicks across every hit; crits turn black and red as a crescent wave tears across.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 0.95, 0.95, 0.97 }, physColor = { 0.97, 0.97, 0.99 }, spellColor = { 1, 0.72, 0.78 },
    -- A red rim all round (it edges the black crit), then a dark shadow.
    layers = {
        { x = 1.5, y = 0, color = { 1, 0.12, 0.2, 1 } }, { x = -1.5, y = 0, color = { 1, 0.12, 0.2, 1 } },
        { x = 0, y = 1.5, color = { 1, 0.12, 0.2, 1 } }, { x = 0, y = -1.5, color = { 1, 0.12, 0.2, 1 } },
        { x = 3, y = -3, color = { 0.2, 0, 0.04, 1 } },
    },
    motion = "rise", motionArgs = { speed = 26 },
    dur = 1.1, critDur = 1.6, critScale = 1.55, pop = 0.2, shake = 5,
    hitPieces = {
        { tex = "slash", size = { 110, 10 }, x = 6, y = 2, rot = 0.45, from = { -40, -18 }, move = 0.08, life = 0.2,
          front = true, color = WHITE, alpha = 1 },
    },
    -- A black number in a red aura.
    critCycle = { { 0.07, 0.02, 0.05 } },
    glowColor = { 1, 0.08, 0.18 }, glowAlpha = 0.7,
    critDecor = { tex = "glow", size = { 170, 90 }, color = { 1, 0.1, 0.18 }, alpha = 0.9, snap = 0.5, snapTime = 0.12 },
    critPieces = {
        { tex = "crescent", size = { 64, 128 }, x = 150, from = { -150, 0 }, ease = "linear", move = 0.38, life = 0.45,
          color = { 1, 0.1, 0.18 }, alpha = 1, blend = "BLEND" },
    },
    particles = { tex = "spark", count = 0, critCount = 12, size = { 4, 8 }, aspect = 0.4, speed = { 50, 110 }, dir = { 80, 100 },
                  spread = { 90, 20 }, gravity = 40, life = { 0.5, 0.9 }, color = { 1, 0.15, 0.25 }, drag = 0.5 },
    particles2 = { tex = "shard", count = 0, critCount = 8, size = { 6, 10 }, speed = { 40, 90 }, dir = { 75, 105 },
                   spread = { 100, 20 }, gravity = 30, life = { 0.5, 0.9 }, color = { 0.08, 0.02, 0.04 }, blend = "BLEND" },
})

---------------------------------------------------------------------------
-- Shinobi: numbers pop out of smoke as a kunai thunks in; crits spin up a
-- spiral orb.
---------------------------------------------------------------------------
add("shinobi", {
    group = "anime", listNote = "Secret",
    name = "Shinobi", tagline = "Numbers pop out of a smoke puff as a kunai thunks in; crits spin up a roaring blue spiral orb.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.62, 0.2 }, physColor = { 1, 0.8, 0.52 }, spellColor = { 0.45, 0.78, 1 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.12, 0, 1 } } },
    motion = "implode", motionArgs = { time = 0.1, rise = 26 },
    dur = 1.15, critDur = 1.65, critScale = 1.5, pop = 0,
    hitPieces = {
        { tex = "kunai", size = { 11, 32 }, x = 42, y = 4, rot = -0.6, from = { 90, 44 }, move = 0.07, delay = 0.06,
          life = 0.7, wobble = { 0.12, 50, 9 }, color = { 0.8, 0.83, 0.88 }, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "ring", size = 96, grow = 0.4, life = 0.4, color = { 0.75, 0.9, 1 }, alpha = 0.7 },
        { tex = "spiralorb", size = 84, spin = -14, snap = 0.3, snapTime = 0.18, life = 1.0, color = { 0.3, 0.65, 1 }, alpha = 0.95 },
        { tex = "spiralorb", size = 58, spin = 19, snap = 0.3, snapTime = 0.18, life = 1.0, color = { 0.8, 0.93, 1 }, alpha = 0.8 },
    },
    particles = { tex = "puff", count = 5, critCount = 5, size = { 10, 16 }, speed = { 25, 55 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.3, 0.5 }, color = { 0.86, 0.87, 0.9 }, blend = "BLEND", drag = 3 },
    -- The crit ends in a burst of smoke.
    particles2 = { tex = "puff", count = 0, critCount = 9, size = { 14, 22 }, speed = { 30, 70 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.35, 0.55 }, delay = 0.95, color = { 0.86, 0.87, 0.9 }, blend = "BLEND", drag = 3 },
})

---------------------------------------------------------------------------
-- Menacing: ominous rumble marks drift beside every number; crits land a
-- rapid punch barrage.
---------------------------------------------------------------------------
local barrage = {}
for i, pt in ipairs({ { -38, 14 }, { 30, -12 }, { -8, 22 }, { 44, 16 }, { -44, -14 }, { 10, -20 }, { 34, 26 }, { -22, -4 } }) do
    barrage[i] = { tex = "impact", size = 30, x = pt[1], y = pt[2], rot = i * 0.7, delay = (i - 1) * 0.07, life = 0.2,
                   snap = 0.4, snapTime = 0.08, front = i % 2 == 0, color = { 1, 0.95, 0.72 }, alpha = 0.9 }
end
add("menacing", {
    group = "anime", listNote = "Secret",
    name = "Menacing", tagline = "Ominous rumble marks drift up beside every number; crits land a rapid barrage, impact after impact.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.86, 0.7, 1 }, physColor = { 0.94, 0.88, 1 }, spellColor = { 1, 0.58, 0.86 },
    layers = { { x = 2, y = -2, color = { 0.22, 0.04, 0.36, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.25, critDur = 1.7, critScale = 1.5, pop = 0.1, shake = 4,
    drum = { count = 8, gap = 0.07, amp = 0.12 },
    critPieces = barrage,
    critTitle = { text = "BARRAGE!", y = 46, size = 17, font = F.skurri, pop = 1.4, delay = 0.6,
                  colors = { { 0.8, 0.55, 1 }, { 1, 1, 1 }, { 1, 0.85, 0.4 } }, shadowColor = { 0.2, 0.02, 0.3 } },
    particles = { tex = "rumble", count = 1, critCount = 2, size = { 20, 28 }, speed = { 18, 28 }, dir = { 85, 95 },
                  origin = { -60, -6 }, gravity = 0, life = { 0.9, 1.2 }, color = { 0.82, 0.5, 1 }, blend = "BLEND", sway = true, drag = 0, shrink = 0 },
    particles2 = { tex = "rumble", count = 1, critCount = 2, size = { 20, 28 }, speed = { 18, 28 }, dir = { 85, 95 },
                   origin = { 60, 2 }, gravity = 0, life = { 0.9, 1.2 }, delay = 0.2, color = { 0.82, 0.5, 1 }, blend = "BLEND", sway = true, drag = 0, shrink = 0 },
})

---------------------------------------------------------------------------
-- Flowing Form: every hit trails a woodblock wave; crits roll a great curl.
---------------------------------------------------------------------------
add("flowingform", {
    group = "anime", listNote = "Secret",
    name = "Flowing Form", tagline = "Each hit sweeps on a woodblock-print wave; crits roll a great curling wave in a spray of foam.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.82, 0.92, 1 }, physColor = { 0.92, 0.97, 1 }, spellColor = { 0.5, 0.78, 1 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.1, 0.28, 1 } } },
    motion = "dash", motionArgs = { dist = 36, time = 0.25, rise = 16 },
    dur = 1.15, critDur = 1.65, critScale = 1.55, pop = 0.2,
    hitPieces = {
        { tex = "arc", size = 120, y = 30, reveal = "right", move = 0.2, life = 0.45, color = { 0.22, 0.52, 0.98 }, alpha = 0.9 },
        { tex = "arc", size = 108, y = 26, reveal = "right", move = 0.2, delay = 0.04, life = 0.4, color = { 0.85, 0.95, 1 }, alpha = 0.8 },
    },
    critDecor = { tex = "ripple", size = { 160, 44 }, y = -30, color = { 0.6, 0.85, 1 }, alpha = 0.7, grow = 0.5, snap = 0.5, snapTime = 0.15 },
    critPieces = {
        { tex = "wavecurl", size = 126, x = -8, y = 10, reveal = "right", move = 0.28, life = 1.0,
          color = { 0.2, 0.48, 0.92 }, alpha = 0.95, blend = "BLEND" },
        { tex = "arc", size = 150, y = 40, reveal = "right", move = 0.22, life = 0.5, color = { 0.85, 0.95, 1 }, alpha = 0.85 },
    },
    particles = { tex = "glow", count = 0, critCount = 14, size = { 4, 8 }, speed = { 60, 130 }, dir = { 20, 160 },
                  origin = { 0, 30 }, delay = 0.18, gravity = -200, life = { 0.5, 0.9 }, color = { 0.92, 0.97, 1 } },
})

---------------------------------------------------------------------------
-- Gotcha!: numbers fly like a thrown ball; a crit is caught in a capsule
-- that rocks three times and clicks.
---------------------------------------------------------------------------
local TEAL, CREAM = { 0.12, 0.66, 0.62 }, { 0.98, 0.93, 0.8 }
local capsuleRock = { at = 0.3, n = 3, gap = 0.24, amp = 0.35 }
add("gotcha", {
    group = "anime", listNote = "Secret",
    name = "Gotcha!", tagline = "Numbers fly like a thrown ball; crits snap into a capsule that wobbles three times, clicks and calls GOTCHA!",
    font = F.block, size = 23, outline = "OUTLINE",
    color = { 1, 0.88, 0.42 }, physColor = { 1, 0.95, 0.72 }, spellColor = { 0.55, 0.95, 0.9 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.18, 0.2, 1 } } },
    motion = "bounce", motionArgs = { vx = { 40, 70 }, vy = 150, gravity = 520, floor = -18, damp = 0.45 },
    dur = 1.15, critDur = 2.0, critScale = 1.55, pop = 0, noSpring = true,
    -- Shrinks into the capsule, waits out the wobbles, then pops back out.
    critScaleKeys = { { 0, 1 }, { 0.22, 0.02 }, { 1.0, 0.02 }, { 1.08, 1.35 }, { 1.22, 1 } },
    hitPieces = {
        { tex = "capsuletop", size = 16, x = -36, spin = 12, life = 0.6, color = TEAL, alpha = 1, blend = "BLEND" },
        { tex = "capsulebot", size = 16, x = -36, spin = 12, life = 0.6, color = CREAM, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "capsulebot", size = 40, steady = true, y = -8, pivot = { 0, -17 }, rock = capsuleRock, hold = true, color = CREAM, alpha = 1, blend = "BLEND" },
        { tex = "capsuletop", size = 40, steady = true, y = -8, from = { 0, 8 }, move = 0.22, pivot = { 0, -17 }, rock = capsuleRock,
          hold = true, color = TEAL, alpha = 1, blend = "BLEND" },
        { tex = "star", steady = true, size = 18, x = -30, y = 16, delay = 1.0, life = 0.4, snap = 0.2, snapTime = 0.1, color = GOLD },
        { tex = "star", steady = true, size = 14, x = 30, y = 20, delay = 1.04, life = 0.4, snap = 0.2, snapTime = 0.1, color = WHITE },
        { tex = "star", steady = true, size = 12, x = 2, y = 30, delay = 1.08, life = 0.4, snap = 0.2, snapTime = 0.1, color = GOLD },
    },
    critTitle = { text = "GOTCHA!", y = 40, size = 16, font = F.block, pop = 1.4, delay = 1.02,
                  colors = { { 0.5, 0.95, 0.88 }, { 1, 1, 1 }, { 1, 0.88, 0.42 } }, shadowColor = { 0.02, 0.15, 0.15 } },
    particles = { tex = "star", count = 0, critCount = 8, size = { 7, 11 }, speed = { 60, 120 }, dir = { 20, 160 },
                  gravity = -120, life = { 0.5, 0.8 }, delay = 1.0, color = GOLD, altColor = WHITE, spin = 5 },
})

---------------------------------------------------------------------------
-- Soot Sprites: little sprites carry each number; crits scatter them.
---------------------------------------------------------------------------
local function sprites(size, y, spread)
    return {
        { tex = "soot", size = size, x = -spread, y = y, hold = true, flap = { 0.35, 15 }, color = WHITE, alpha = 1, blend = "BLEND" },
        { tex = "soot", size = size + 2, x = 0, y = y - 2, hold = true, flap = { -0.35, 13 }, color = WHITE, alpha = 1, blend = "BLEND" },
        { tex = "soot", size = size, x = spread, y = y, hold = true, flap = { 0.3, 17 }, color = WHITE, alpha = 1, blend = "BLEND" },
    }
end
add("sootsprites", {
    group = "anime", listNote = "Secret",
    name = "Soot Sprites", tagline = "Little soot sprites carry each number up; crits scatter the swarm and toss star candy.",
    font = F.morpheus, size = 24, outline = "OUTLINE",
    color = { 1, 0.93, 0.78 }, physColor = { 1, 0.96, 0.88 }, spellColor = { 1, 0.75, 0.5 },
    layers = { { x = 2, y = -2, color = { 0.15, 0.1, 0.05, 1 } } },
    motion = "rise", motionArgs = { speed = 26 },
    dur = 1.25, critDur = 1.7, critScale = 1.5, pop = 0.2,
    hitPieces = sprites(26, -22, 25),
    critPieces = sprites(26, -22, 27),
    particles = { tex = "soot", count = 0, critCount = 10, size = { 15, 22 }, speed = { 60, 130 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.7, 1.1 }, color = WHITE, blend = "BLEND", spin = 3, drag = 2, shrink = 0 },
    particles2 = { tex = "star", count = 0, critCount = 9, size = { 7, 10 }, speed = { 70, 130 }, dir = { 30, 150 },
                   gravity = -200, life = { 0.6, 1.0 }, randomColor = true, spin = 5 },
})

---------------------------------------------------------------------------
-- Transmute: a chalk circle draws itself; crits close the array in
-- lightning and raise stone spikes.
---------------------------------------------------------------------------
local CHALK, SPARK = { 0.9, 0.95, 1 }, { 0.45, 0.82, 1 }
add("transmute", {
    group = "anime", listNote = "Secret",
    name = "Transmute", tagline = "A chalk circle draws itself under every hit; crits close the full array in blue lightning and raise stone spikes.",
    font = F.friz, size = 25, outline = "OUTLINE",
    color = { 0.85, 0.92, 1 }, physColor = { 0.93, 0.96, 1 }, spellColor = { 0.5, 0.84, 1 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.1, 0.2, 1 } } },
    motion = "rise", motionArgs = { speed = 22 },
    dur = 1.2, critDur = 1.65, critScale = 1.5, pop = 0.2,
    hitPieces = {
        { tex = "alchemy", size = { 72, 22 }, y = -18, reveal = "right", move = 0.3, life = 0.8, color = CHALK, alpha = 0.8 },
        { tex = "bolt", size = { 8, 26 }, x = -22, y = -6, rot = 0.4, delay = 0.12, life = 0.22, flicker = true, color = SPARK },
    },
    critPieces = {
        { tex = "alchemy", size = { 136, 42 }, y = -24, reveal = "right", move = 0.3, life = 1.0, color = CHALK, alpha = 0.9 },
        { tex = "bolt", size = { 12, 46 }, x = -46, y = -6, rot = 0.5, delay = 0.18, life = 0.5, flicker = true, color = SPARK },
        { tex = "bolt", size = { 12, 46 }, x = 44, y = -4, rot = -0.6, delay = 0.24, life = 0.5, flicker = true, color = SPARK },
        { tex = "bolt", size = { 10, 40 }, x = 4, y = 18, rot = 1.4, delay = 0.3, life = 0.45, flicker = true, color = SPARK },
        { tex = "stonespikes", size = { 110, 50 }, y = -26, reveal = "up", move = 0.14, delay = 0.32, hold = true,
          color = { 0.62, 0.64, 0.7 }, alpha = 1, blend = "BLEND" },
    },
    particles = { tex = "spark", count = 0, critCount = 8, size = { 4, 7 }, speed = { 50, 120 }, dir = { 30, 150 },
                  origin = { 0, -20 }, delay = 0.32, gravity = -160, life = { 0.4, 0.7 }, color = SPARK },
})

---------------------------------------------------------------------------
-- Final Page: numbers scrawled in ink; crits written in red on a torn
-- notebook page.
---------------------------------------------------------------------------
local RED_INK = { 0.62, 0.02, 0.07 }
add("finalpage", {
    group = "anime", listNote = "Secret",
    name = "Final Page", tagline = "Numbers write themselves in scrawled ink; crits are written in red on a torn notebook page that blots.",
    font = F.script, size = 22, outline = "OUTLINE",
    color = { 0.9, 0.88, 1 }, physColor = { 0.94, 0.93, 1 }, spellColor = { 0.78, 0.66, 1 },
    layers = { { x = 2, y = -2, color = { 0.05, 0.03, 0.1, 1 } } },
    motion = "dash", motionArgs = { arrive = true, dist = 14, time = 0.3, rise = 10 },
    fadeIn = 0.25,
    dur = 1.3, critDur = 1.8, critScale = 1.5, pop = 0,
    hitPieces = {
        { tex = "brush", size = { 72, 9 }, y = -14, reveal = "right", move = 0.3, delay = 0.1, life = 0.9, color = { 0.78, 0.66, 1 }, alpha = 0.7 },
    },
    critCycle = { { 0.72, 0.04, 0.1 } },
    noFlash = true,
    glowColor = { 1, 0.95, 0.85 }, glowAlpha = 0.2,
    critPieces = {
        { tex = "notepage", size = { 140, 66 }, y = -2, rot = -0.05, snap = 0.7, snapTime = 0.15, hold = true,
          color = { 0.95, 0.93, 0.87 }, alpha = 1, blend = "BLEND" },
        { tex = "brush", size = { 90, 9 }, y = -16, reveal = "right", move = 0.35, delay = 0.25, hold = true, color = RED_INK, alpha = 0.9, blend = "BLEND" },
        { tex = "splat", size = 24, x = 56, y = -6, delay = 0.55, snap = 0.3, snapTime = 0.12, hold = true, color = RED_INK, alpha = 0.95, blend = "BLEND" },
    },
    particles = { tex = "drop", count = 0, critCount = 4, size = { 4, 7 }, aspect = 0.6, speed = { 5, 15 }, dir = { 260, 280 },
                  origin = { 84, -12 }, delay = 0.6, gravity = -160, life = { 0.5, 0.8 }, color = RED_INK, blend = "BLEND", drag = 0, shrink = 0 },
})

---------------------------------------------------------------------------
-- Steam Blades: numbers zip in on grapple lines; crits cross twin blades
-- in a burst of steam.
---------------------------------------------------------------------------
local STEEL = { 0.85, 0.9, 0.92 }
add("steamblades", {
    group = "anime", listNote = "Secret",
    name = "Steam Blades", tagline = "Numbers zip in on two grapple lines; crits cross twin blades in a burst of steam.",
    font = F.friz, size = 25, outline = "THICKOUTLINE",
    color = { 0.92, 0.95, 0.96 }, physColor = { 0.95, 0.97, 0.98 }, spellColor = { 0.6, 0.92, 0.75 },
    layers = { { x = 2, y = -2, color = { 0.1, 0.18, 0.08, 1 } } },
    motion = "drop", motionArgs = { height = 36, fall = 0.1, squash = 0.15, sinkAt = 0.2, sink = -16 },
    dur = 1.1, critDur = 1.6, critScale = 1.55, pop = 0, shake = 3,
    hitPieces = {
        { tex = "beam", size = { 4, 120 }, x = -52, y = 46, rot = 0.85, life = 0.25, color = STEEL, alpha = 0.85 },
        { tex = "beam", size = { 4, 120 }, x = 52, y = 46, rot = -0.85, life = 0.25, color = STEEL, alpha = 0.85 },
    },
    critPieces = {
        { tex = "slash", size = { 150, 22 }, x = 0, y = 0, rot = -0.75, from = { -50, 46 }, move = 0.08, life = 0.35,
          front = true, color = WHITE, alpha = 1 },
        { tex = "slash", size = { 150, 22 }, x = 0, y = 0, rot = 0.75, from = { 50, 46 }, move = 0.08, delay = 0.07, life = 0.35,
          front = true, color = WHITE, alpha = 1 },
    },
    particles = { tex = "puff", count = 0, critCount = 12, size = { 14, 24 }, speed = { 40, 100 }, dir = { 0, 360 },
                  delay = 0.08, gravity = 20, life = { 0.6, 1.0 }, color = { 0.92, 0.93, 0.95 }, blend = "BLEND", drag = 2 },
    particles2 = { tex = "spark", count = 0, critCount = 6, size = { 3, 6 }, speed = { 80, 160 }, dir = { 0, 360 },
                   gravity = -100, life = { 0.3, 0.5 }, color = { 1, 0.95, 0.8 } },
})

---------------------------------------------------------------------------
-- Seven Stars: a star orb rides along; crits gather all seven and call a
-- beam of light.
---------------------------------------------------------------------------
local ORANGE = { 1, 0.62, 0.15 }
local orbs = {}
for i = 1, 7 do
    local a = math.pi / 2 + (i - 1) * math.pi * 2 / 7
    orbs[i] = { tex = "starorb", size = 18, x = math.cos(a) * 66, y = 4 + math.sin(a) * 30, delay = (i - 1) * 0.06,
                snap = 0.2, snapTime = 0.12, hold = true, color = ORANGE, alpha = 1, blend = "BLEND" }
end
orbs[8] = { tex = "beam", size = { 36, 170 }, y = 86, delay = 0.55, life = 0.7, snap = 0.3, snapTime = 0.12,
            color = { 1, 0.9, 0.55 }, alpha = 0.8 }
add("sevenstars", {
    group = "anime", listNote = "Secret",
    name = "Seven Stars", tagline = "A star orb rides along with each hit; crits gather all seven in a ring and shoot a golden beam skyward.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.8, 0.3 }, physColor = { 1, 0.9, 0.62 }, spellColor = { 1, 0.62, 0.22 },
    layers = { { x = 2, y = -2, color = { 0.42, 0.15, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 24 },
    dur = 1.2, critDur = 1.7, critScale = 1.5, pop = 0.25,
    decor = { tex = "starorb", size = 16, x = 44, y = 4, color = ORANGE, alpha = 1, blend = "BLEND" },
    critReplacesDecor = true,
    critPieces = orbs,
    particles = { tex = "twinkle", count = 0, critCount = 9, size = { 8, 13 }, speed = { 30, 90 }, dir = { 60, 120 },
                  delay = 0.55, gravity = 30, life = { 0.5, 0.9 }, color = { 1, 0.92, 0.6 } },
})

---------------------------------------------------------------------------
-- Smash!: hits punch forward; crits wind up, then blast out rings.
---------------------------------------------------------------------------
add("smash", {
    group = "anime", listNote = "Secret",
    name = "Smash!", tagline = "Hits punch forward on rushing wind; crits wind up, then blast out shockwave rings and call SMASH!",
    font = F.skurri, size = 29, outline = "THICKOUTLINE",
    color = { 1, 1, 1 }, physColor = { 1, 1, 1 }, spellColor = { 1, 0.86, 0.3 },
    layers = { { x = 2, y = -2, color = { 0.1, 0.25, 0.65, 1 } }, { x = 4, y = -4, color = { 0.03, 0.08, 0.25, 1 } } },
    motion = "dash", motionArgs = { arrive = true, dist = 26, time = 0.12, rise = 18 },
    dur = 1.1, critDur = 1.6, critScale = 1.55, pop = 0, noSpring = true, shake = 8, shakeAt = 0.16,
    critScaleKeys = { { 0, 1 }, { 0.14, 0.72 }, { 0.19, 1.45 }, { 0.42, 1 } },
    decor = { tex = "speedlines", size = { 70, 34 }, x = 44, trail = true, color = { 0.8, 0.88, 1 }, alpha = 0.5 },
    critReplacesDecor = true,
    critPieces = {
        { tex = "radial", size = 170, delay = 0.16, life = 0.45, snap = 0.6, snapTime = 0.1, color = WHITE, alpha = 0.7 },
        { tex = "ring", size = 70, grow = 2, delay = 0.16, life = 0.5, color = WHITE, alpha = 1 },
        { tex = "ring", size = 70, grow = 1.4, delay = 0.22, life = 0.5, color = { 1, 0.86, 0.3 }, alpha = 1 },
    },
    critTitle = { text = "SMASH!", y = 48, size = 19, font = F.skurri, pop = 1.6, delay = 0.18,
                  colors = { { 1, 0.86, 0.3 }, { 1, 1, 1 }, { 0.4, 0.6, 1 } }, shadowColor = { 0.03, 0.08, 0.25 } },
    particles = { tex = "shard", count = 0, critCount = 8, size = { 6, 10 }, speed = { 120, 200 }, dir = { 0, 360 },
                  delay = 0.16, gravity = 0, life = { 0.25, 0.45 }, color = WHITE, orient = true },
})

---------------------------------------------------------------------------
-- Moonlit Charm: pastel numbers twinkle; crits twirl a ribbon under a
-- glowing crescent.
---------------------------------------------------------------------------
add("moonlitcharm", {
    group = "anime", listNote = "Secret",
    name = "Moonlit Charm", tagline = "Pastel numbers twinkle as they rise; crits twirl two ribbons under a glowing crescent.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 1, 0.8, 0.93 }, physColor = { 1, 0.9, 0.96 }, spellColor = { 0.82, 0.68, 1 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.06, 0.36, 1 } } },
    motion = "rise", motionArgs = { speed = 24, sway = 3, freq = 4 },
    dur = 1.3, critDur = 1.75, critScale = 1.5, pop = 0.25,
    critPieces = {
        { tex = "moon", size = 34, y = 44, snap = 0.3, snapTime = 0.18, hold = true, color = { 1, 0.95, 0.7 }, alpha = 1 },
        { tex = "twirl", size = { 130, 56 }, y = -2, reveal = "right", move = 0.4, life = 1.0, color = { 1, 0.55, 0.82 }, alpha = 0.95, blend = "BLEND" },
        { tex = "twirl", size = { 120, 50 }, y = 4, rot = math.pi, reveal = "left", move = 0.4, delay = 0.1, life = 0.95,
          color = { 0.78, 0.62, 1 }, alpha = 0.9, blend = "BLEND" },
    },
    particles = { tex = "twinkle", count = 3, critCount = 10, size = { 8, 13 }, speed = { 10, 40 }, dir = { 0, 360 },
                  spread = { 70, 20 }, gravity = 0, life = { 0.5, 0.9 }, color = WHITE, altColor = { 1, 0.75, 0.9 } },
    particles2 = { tex = "star", count = 0, critCount = 6, size = { 7, 10 }, speed = { 40, 90 }, dir = { 30, 150 },
                   gravity = -60, life = { 0.6, 1.0 }, color = { 1, 0.7, 0.88 }, altColor = { 0.82, 0.7, 1 }, spin = 4 },
})

---------------------------------------------------------------------------
-- Hex Barrier: a hexagon flickers behind hits; crits ripple a wall of
-- hexes that shatters.
---------------------------------------------------------------------------
local BARRIER = { 1, 0.55, 0.1 }
local hexes = { { tex = "hex", size = 56, snap = 0.5, snapTime = 0.1, life = 0.9, color = BARRIER, alpha = 0.9 } }
for i = 1, 6 do
    local a = math.pi / 6 + (i - 1) * math.pi / 3
    hexes[#hexes + 1] = { tex = "hex", size = 56, x = math.cos(a) * 42, y = math.sin(a) * 42, delay = 0.05 + (i % 3) * 0.04,
                          snap = 0.5, snapTime = 0.1, life = 0.85, color = BARRIER, alpha = 0.6 }
end
add("hexbarrier", {
    group = "anime", listNote = "Secret",
    name = "Hex Barrier", tagline = "A faint hexagon flickers behind each hit; crits ripple out a wall of orange hexes that shatters.",
    font = F.block, size = 24, outline = "OUTLINE",
    color = { 1, 0.85, 0.65 }, physColor = { 1, 0.93, 0.82 }, spellColor = { 1, 0.62, 0.28 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.12, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 22 },
    dur = 1.15, critDur = 1.6, critScale = 1.5, pop = 0.25,
    decor = { tex = "hex", size = 56, color = BARRIER, alpha = 0.45, flicker = true },
    critReplacesDecor = true,
    critPieces = hexes,
    particles = { tex = "shard", count = 0, critCount = 14, size = { 6, 11 }, speed = { 80, 170 }, dir = { 0, 360 },
                  delay = 0.45, gravity = -150, life = { 0.4, 0.7 }, color = BARRIER, altColor = { 1, 0.85, 0.5 }, spin = 6 },
})

---------------------------------------------------------------------------
-- Chain Rev: numbers judder in a spinning saw ring; crits rip a big
-- sawblade with sparks flying.
---------------------------------------------------------------------------
add("chainrev", {
    group = "anime", listNote = "Secret",
    name = "Chain Rev", tagline = "Numbers judder inside a spinning saw ring; crits rip a big sawblade through with sparks flying.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 1, 0.5, 0.35 }, physColor = { 1, 0.76, 0.64 }, spellColor = { 1, 0.32, 0.26 },
    layers = { { x = 2, y = -2, color = { 0.3, 0, 0, 1 } } },
    motion = "zap", motionArgs = { speed = 22, step = 0.03, jolt = 2 },
    dur = 1.1, critDur = 1.55, critScale = 1.55, pop = 0.2, shake = 6,
    decor = { tex = "sawring", size = 62, spin = 18, color = { 0.75, 0.78, 0.82 }, alpha = 0.9, blend = "BLEND" },
    critReplacesDecor = true,
    critPieces = {
        { tex = "sawring", size = 104, spin = 26, snap = 0.3, snapTime = 0.12, hold = true, color = { 0.86, 0.88, 0.92 }, alpha = 1, blend = "BLEND" },
    },
    particles = { tex = "spark", count = 1, critCount = 14, size = { 8, 13 }, aspect = 0.4, speed = { 120, 220 }, dir = { 15, 75 },
                  origin = { 40, 20 }, gravity = -200, life = { 0.2, 0.4 }, color = { 1, 0.75, 0.3 }, altColor = { 1, 0.3, 0.2 },
                  orient = true, drag = 0, mirror = true },
    particles2 = { tex = "drop", count = 0, critCount = 5, size = { 5, 8 }, aspect = 0.6, speed = { 40, 90 }, dir = { 30, 150 },
                   gravity = -300, life = { 0.4, 0.7 }, color = { 0.6, 0.02, 0.04 }, blend = "BLEND" },
})

---------------------------------------------------------------------------
-- Pressure Point: hits tap two points; crits tap five, pause, then burst.
---------------------------------------------------------------------------
local TAP = { 1, 0.9, 0.45 }
local function tap(x, y, delay, life)
    return { tex = "ring", size = 18, x = x, y = y, delay = delay, life = life, snap = 2, snapTime = 0.08, front = true, color = TAP, alpha = 1 }
end
local taps = {}
for i, pt in ipairs({ { -36, -6 }, { -14, 8 }, { 4, -10 }, { 22, 6 }, { 40, -4 } }) do taps[i] = tap(pt[1], pt[2], 0.05 + (i - 1) * 0.07, 0.72 - (i - 1) * 0.07) end
taps[6] = { tex = "radial", size = 160, delay = 0.7, life = 0.45, snap = 0.6, snapTime = 0.1, color = TAP, alpha = 0.8 }
taps[7] = { tex = "impact", size = 110, delay = 0.7, life = 0.35, snap = 0.4, snapTime = 0.1, color = { 1, 0.95, 0.75 }, alpha = 0.9 }
add("pressurepoint", {
    group = "anime", listNote = "Secret",
    name = "Pressure Point", tagline = "Each hit taps two pressure points; crits tap five, pause for a beat, then burst all at once.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 1, 0.92, 0.78 }, physColor = { 1, 0.96, 0.88 }, spellColor = { 1, 0.75, 0.42 },
    layers = { { x = 2, y = -2, color = { 0.35, 0.1, 0.04, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.15, critDur = 1.75, critScale = 1.5, pop = 0, noSpring = true, shake = 8, shakeAt = 0.7,
    critScaleKeys = { { 0, 1 }, { 0.7, 1 }, { 0.76, 1.55 }, { 0.98, 1 } },
    hitPieces = { tap(-18, 4, 0.06, 0.4), tap(16, -4, 0.14, 0.36) },
    critPieces = taps,
    particles = { tex = "spark", count = 0, critCount = 12, size = { 4, 7 }, speed = { 100, 200 }, dir = { 0, 360 },
                  delay = 0.7, gravity = 0, life = { 0.3, 0.5 }, color = TAP },
})

---------------------------------------------------------------------------
-- Spiral Drill: a drill bores up behind each hit; crits drive a giant one
-- through the number.
---------------------------------------------------------------------------
local DRILL = { 0.95, 0.35, 0.2 }
add("spiraldrill", {
    group = "anime", listNote = "Secret",
    name = "Spiral Drill", tagline = "A drill bores up beside each hit; crits drive a giant spinning drill up through the number and call PIERCE!",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 1, 0.86, 0.72 }, physColor = { 1, 0.93, 0.84 }, spellColor = { 0.5, 0.95, 1 },
    layers = { { x = 2, y = -2, color = { 0.38, 0.08, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 26 },
    dur = 1.15, critDur = 1.65, critScale = 1.5, pop = 0.2, shake = 4, shakeAt = 0.3,
    hitPieces = {
        { tex = "drill", size = { 16, 34 }, x = 42, y = 8, from = { 42, -26 }, move = 0.25, turn = 12, life = 0.55,
          color = DRILL, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "drill", size = { 60, 120 }, y = 18, from = { 0, -110 }, move = 0.38, turn = 16, life = 1.0,
          color = DRILL, alpha = 1, blend = "BLEND" },
    },
    critTitle = { text = "PIERCE!", y = 50, size = 17, font = F.skurri, pop = 1.5, delay = 0.35,
                  colors = { { 0.5, 0.95, 1 }, { 1, 1, 1 }, { 1, 0.86, 0.3 } }, shadowColor = { 0.3, 0.05, 0 } },
    particles = { tex = "twinkle", count = 0, critCount = 12, size = { 8, 12 }, speed = { 60, 130 }, dir = { 60, 120 },
                  delay = 0.25, gravity = 0, life = { 0.4, 0.8 }, color = { 0.5, 0.95, 1 }, altColor = WHITE, spin = 6 },
})

---------------------------------------------------------------------------
-- Link Start: hits drain an HP bar; crits empty it and shatter into
-- polygons.
---------------------------------------------------------------------------
local HUD, DARK = { 0.62, 0.9, 1 }, { 0.08, 0.08, 0.1 }
add("linkstart", {
    group = "anime", listNote = "Secret",
    name = "Link Start", tagline = "Each hit drains a game HP bar; crits empty it and the hit shatters into blue polygons.",
    font = F.friz, size = 24, outline = "OUTLINE",
    color = { 0.82, 0.96, 1 }, physColor = { 0.92, 0.98, 1 }, spellColor = { 0.5, 0.88, 1 },
    layers = { { x = 2, y = -2, color = { 0.02, 0.12, 0.2, 1 } } },
    motion = "rise", motionArgs = { speed = 16 },
    dur = 1.2, critDur = 1.65, critScale = 1.5, pop = 0.2,
    hitPieces = {
        { tex = "pixel", size = { 76, 5 }, y = -20, hold = true, color = { 0.35, 0.85, 0.4 }, alpha = 1, blend = "BLEND" },
        { tex = "pixel", size = { 20, 5 }, x = 28, y = -20, reveal = "left", move = 0.3, delay = 0.05, hold = true, color = DARK, alpha = 1, blend = "BLEND" },
        { tex = "hpframe", size = { 82, 11 }, y = -20, hold = true, color = HUD, alpha = 0.9 },
    },
    critPieces = {
        { tex = "pixel", size = { 76, 5 }, y = -20, hold = true, color = { 0.92, 0.25, 0.22 }, alpha = 1, blend = "BLEND" },
        { tex = "pixel", size = { 76, 5 }, y = -20, reveal = "left", move = 0.35, hold = true, color = DARK, alpha = 1, blend = "BLEND" },
        { tex = "hpframe", size = { 82, 11 }, y = -20, hold = true, color = HUD, alpha = 0.9 },
    },
    particles = { tex = "tri", count = 0, critCount = 18, size = { 10, 16 }, speed = { 50, 130 }, dir = { 0, 360 },
                  delay = 0.35, spread = { 60, 16 }, gravity = -120, life = { 0.5, 0.9 }, color = { 0.5, 0.9, 1 }, altColor = WHITE, spin = 8 },
})

---------------------------------------------------------------------------
-- Neon Slide: numbers power-slide in on a red light trail; crits carve a
-- long glowing arc.
---------------------------------------------------------------------------
local NEON = { 1, 0.15, 0.25 }
add("neonslide", {
    group = "anime", listNote = "Secret",
    name = "Neon Slide", tagline = "Numbers power-slide in on a red tail-light trail; crits carve a long glowing arc and kick up sparks.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.86, 0.88 }, physColor = { 1, 0.93, 0.94 }, spellColor = { 1, 0.42, 0.48 },
    layers = { { x = 2, y = -2, color = { 0.4, 0, 0.06, 1 } } },
    motion = "dash", motionArgs = { arrive = true, dist = 80, time = 0.22, rise = 12 },
    dur = 1.1, critDur = 1.6, critScale = 1.5, pop = 0.15,
    hitPieces = {
        { tex = "slash", size = { 150, 28 }, x = 72, y = -12, trail = true, life = 0.4, color = NEON, alpha = 0.45 },
        { tex = "slash", size = { 130, 10 }, x = 66, y = -12, trail = true, life = 0.4, color = { 1, 0.7, 0.75 }, alpha = 1 },
    },
    critPieces = {
        { tex = "arc", size = 190, y = 36, rot = math.pi, snap = 0.7, snapTime = 0.18, life = 0.9, color = NEON, alpha = 1 },
        { tex = "arc", size = 182, y = 33, rot = math.pi, snap = 0.7, snapTime = 0.18, life = 0.8, color = { 1, 0.75, 0.8 }, alpha = 0.8 },
        { tex = "slash", size = { 150, 12 }, x = 80, y = -12, trail = true, life = 0.5, color = { 1, 0.7, 0.75 }, alpha = 1 },
    },
    particles = { tex = "spark", count = 1, critCount = 12, size = { 3, 6 }, speed = { 80, 160 }, dir = { 100, 170 },
                  origin = { 0, -16 }, gravity = -300, life = { 0.3, 0.5 }, color = { 1, 0.82, 0.45 }, mirror = true },
})

---------------------------------------------------------------------------
-- One and Done: hits are tiny and plain; a crit freezes, then lands one
-- colossal punch and a flat "OK."
---------------------------------------------------------------------------
local PLAIN, PUNCH = { 0.82, 0.82, 0.82 }, { 1, 0.86, 0.25 }
add("oneanddone", {
    group = "anime", listNote = "Secret",
    name = "One and Done", tagline = "Hits are tiny and plain on purpose; a crit freezes for a beat, then lands one colossal punch and a flat OK.",
    font = F.arialn, size = 15, outline = "OUTLINE",
    color = PLAIN, physColor = PLAIN, spellColor = { 0.84, 0.84, 0.9 },
    motion = "rise", motionArgs = { speed = 14 },
    dur = 1.0, critDur = 1.8, critScale = 2.6, pop = 0, noSpring = true, noFlash = true, shake = 10, shakeAt = 0.25,
    -- Plain and normal-sized for a beat, then the punch: gold and huge.
    critScaleKeys = { { 0, 0.4 }, { 0.25, 0.4 }, { 0.28, 1.25 }, { 0.45, 1 } },
    critCycle = { PLAIN, PUNCH, PUNCH, PUNCH, PUNCH, PUNCH, PUNCH, PUNCH }, cyclePeriod = 0.25,
    noGlow = true,
    critPieces = {
        { tex = "glow", size = 260, delay = 0.25, life = 0.14, color = WHITE, alpha = 0.9 },
        { tex = "radial", size = 200, delay = 0.25, life = 0.55, snap = 0.7, snapTime = 0.1, color = WHITE, alpha = 0.85 },
        { tex = "impact", size = 90, delay = 0.25, life = 0.3, snap = 0.4, snapTime = 0.08, color = PUNCH, alpha = 0.9 },
    },
    critTitle = { text = "OK.", x = 44, y = -20, size = 11, font = F.arialn, pop = 0.1, delay = 0.8,
                  colors = { PLAIN }, shadowColor = { 0, 0, 0 } },
})
