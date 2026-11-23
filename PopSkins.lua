local _, ns = ...

-- Pop skins: fairytale films and the phones in your pocket, as original
-- homages (a castle-and-shooting-star intro, a glass slipper at midnight,
-- a notification pill, a charging battery...), never a studio's or a
-- brand's own names, logos or characters. Each is earned by a secret feat
-- (Feats.lua) and has its own Pop tab.

local F = ns.Fonts
local add = ns.AddSkin

local WHITE = { 1, 1, 1 }
local GOLD = { 1, 0.85, 0.4 }

---------------------------------------------------------------------------
-- Wishing Star: hits leave sparkle dust; a crit arcs a shooting star over a
-- castle and bursts into fireworks.
---------------------------------------------------------------------------
local STARLIGHT = { 1, 0.94, 0.72 }
local wishPieces = {
    { tex = "castle", size = 112, y = 12, reveal = "up", move = 0.4, hold = true, color = { 0.7, 0.74, 1 }, alpha = 0.45, blend = "BLEND" },
    { tex = "shootstar", size = { 120, 26 }, x = 84, y = 62, rot = 0.34, from = { -116, -10 }, move = 0.5, delay = 0.08,
      life = 0.75, color = STARLIGHT, alpha = 1 },
}
-- Sparkles left along its path, each as the star passes.
for i = 1, 6 do
    local e = i / 7
    local m = 1 - (1 - e) ^ (1 / 3)
    wishPieces[#wishPieces + 1] = { tex = "twinkle", size = 12 - i * 0.6, x = -116 + 200 * e, y = -10 + 72 * e,
                                    delay = 0.08 + 0.5 * m, life = 0.5, snap = 1.8, snapTime = 0.12, color = STARLIGHT, alpha = 0.9 }
end
for _, fw in ipairs({ { 62, 56, 72, 0.58, { 1, 0.55, 0.85 } }, { -54, 50, 58, 0.72, { 0.5, 0.9, 1 } }, { 6, 82, 64, 0.86, GOLD } }) do
    wishPieces[#wishPieces + 1] = { tex = "firework", size = fw[3], x = fw[1], y = fw[2], delay = fw[4], life = 0.75,
                                    snap = 0.3, snapTime = 0.22, grow = 0.35, color = fw[5], alpha = 1 }
end
add("wishingstar", {
    group = "pop", listNote = "Secret",
    name = "Wishing Star", tagline = "Hits leave a trail of sparkle dust; crits arc a shooting star over a fairytale castle and burst into fireworks.",
    font = F.morpheus, size = 26, outline = "OUTLINE",
    color = { 1, 0.9, 0.62 }, physColor = { 1, 0.95, 0.84 }, spellColor = { 0.82, 0.76, 1 },
    layers = { { x = 2, y = -2, color = { 0.22, 0.12, 0.45, 1 } } },
    motion = "rise", motionArgs = { speed = 22, sway = 3, freq = 3 },
    dur = 1.25, critDur = 1.95, critScale = 1.5, pop = 0.25,
    hitPieces = {
        { tex = "shootstar", size = { 70, 16 }, x = 36, y = 16, rot = 0.25, from = { -50, -6 }, move = 0.3, life = 0.45, color = STARLIGHT, alpha = 0.9 },
    },
    critPieces = wishPieces,
    glowColor = { 0.7, 0.65, 1 },
    particles = { tex = "twinkle", count = 3, critCount = 0, size = { 6, 10 }, speed = { 10, 30 }, dir = { 200, 340 },
                  spread = { 60, 10 }, gravity = -30, life = { 0.5, 0.9 }, color = STARLIGHT, altColor = { 0.85, 0.8, 1 } },
    particles2 = { tex = "star", count = 0, critCount = 10, size = { 6, 10 }, speed = { 40, 100 }, dir = { 20, 160 },
                   origin = { 0, 50 }, delay = 0.6, gravity = -120, life = { 0.6, 1.0 }, color = { 1, 0.7, 0.9 }, altColor = GOLD, spin = 4 },
})

---------------------------------------------------------------------------
-- Midnight Chime: glassy numbers glint; a crit sweeps a clock to twelve,
-- chimes, and leaves a glass slipper sparkling.
---------------------------------------------------------------------------
local GLASS = { 0.78, 0.93, 1 }
add("midnightchime", {
    group = "pop", listNote = "Secret",
    name = "Midnight Chime", tagline = "Numbers glint like spun glass; crits sweep a clock to twelve, chime, and leave a glass slipper sparkling.",
    font = F.morpheus, size = 26, outline = "OUTLINE",
    color = { 0.86, 0.95, 1 }, physColor = { 0.94, 0.98, 1 }, spellColor = { 0.68, 0.8, 1 },
    layers = { { x = -1, y = 1, color = { 1, 1, 1, 0.55 } }, { x = 2, y = -2, color = { 0.08, 0.16, 0.42, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.25, critDur = 1.95, critScale = 1.5, pop = 0.2,
    hitPieces = {
        { tex = "twinkle", size = 16, x = 34, y = 12, delay = 0.08, snap = 2, snapTime = 0.1, life = 0.35, color = WHITE, alpha = 1, front = true },
    },
    critPieces = {
        { tex = "clockface", size = 116, snap = 0.6, snapTime = 0.2, hold = true, color = GLASS, alpha = 0.7 },
        -- The hour hand nudges up; the minute hand sweeps round to twelve.
        { tex = "clockhand", size = { 10, 34 }, rot = 0, fromRot = 0.5, pivot = { 0, -13.6 }, move = 0.55, hold = true,
          color = GLASS, alpha = 1 },
        { tex = "clockhand", size = { 12, 50 }, rot = 0, fromRot = 4.7, pivot = { 0, -20 }, move = 0.55, hold = true,
          color = WHITE, alpha = 1 },
        { tex = "ring", size = 116, grow = 0.5, delay = 0.56, life = 0.45, color = GLASS, alpha = 0.9 },
        { tex = "ring", size = 116, grow = 0.9, delay = 0.7, life = 0.45, color = GLASS, alpha = 0.6 },
        { tex = "slipper", size = { 58, 29 }, x = 58, y = -34, delay = 0.62, snap = 0.4, snapTime = 0.16, hold = true,
          color = GLASS, alpha = 1 },
        { tex = "twinkle", size = 24, x = 82, y = -40, delay = 0.78, snap = 2.2, snapTime = 0.12, life = 0.45, color = WHITE, alpha = 1, front = true },
    },
    glowColor = { 0.6, 0.8, 1 },
    particles = { tex = "twinkle", count = 1, critCount = 12, size = { 7, 12 }, speed = { 20, 70 }, dir = { 0, 360 },
                  delay = 0.56, gravity = 0, life = { 0.5, 0.9 }, color = WHITE, altColor = GLASS },
})

---------------------------------------------------------------------------
-- Snow Queen: frost flakes spin by each hit; crits unfurl a giant
-- snowflake in a swirl of ice glitter.
---------------------------------------------------------------------------
local ICE = { 0.62, 0.86, 1 }
local snowPieces = {
    { tex = "ring", size = 70, grow = 1.4, life = 0.4, color = ICE, alpha = 0.6 },
    { tex = "flakeornate", size = 156, spin = 0.5, snap = 0.08, snapTime = 0.45, life = 1.45, color = ICE, alpha = 0.9 },
    { tex = "flakeornate", size = 92, rot = 0.52, spin = -0.8, snap = 0.1, snapTime = 0.35, delay = 0.08, life = 1.35, color = WHITE, alpha = 0.55 },
}
for i = 1, 6 do
    local a = math.pi / 2 + (i - 1) * math.pi / 3
    snowPieces[#snowPieces + 1] = { tex = "twinkle", size = 18, x = math.cos(a) * 74, y = math.sin(a) * 74, delay = 0.34 + i * 0.04,
                                    snap = 2, snapTime = 0.1, life = 0.4, front = true, color = WHITE, alpha = 1 }
end
add("snowqueen", {
    group = "pop", listNote = "Secret",
    name = "Snow Queen", tagline = "A frost flake spins by every hit; crits unfurl a giant snowflake in a swirl of ice glitter.",
    font = F.morpheus, size = 26, outline = "OUTLINE",
    color = { 0.88, 0.97, 1 }, physColor = { 0.95, 0.99, 1 }, spellColor = { 0.55, 0.82, 1 },
    layers = { { x = 2, y = -2, color = { 0.06, 0.22, 0.52, 1 } } },
    motion = "rise", motionArgs = { speed = 20, sway = 4, freq = 3 },
    dur = 1.25, critDur = 1.8, critScale = 1.5, pop = 0.25,
    hitPieces = {
        { tex = "flakeornate", size = 30, x = -42, y = 6, spin = 1.6, snap = 0.3, snapTime = 0.25, life = 0.8, color = ICE, alpha = 0.95 },
    },
    critPieces = snowPieces,
    glowColor = ICE,
    particles = { tex = "twinkle", count = 2, critCount = 16, size = { 6, 11 }, speed = { 30, 90 }, dir = { 0, 360 },
                  gravity = -10, life = { 0.6, 1.1 }, color = WHITE, altColor = ICE, drag = 1.5, sway = true },
    particles2 = { tex = "shard", count = 0, critCount = 8, size = { 5, 9 }, speed = { 50, 110 }, dir = { 0, 360 },
                   gravity = -80, life = { 0.4, 0.7 }, color = ICE, spin = 5 },
})

---------------------------------------------------------------------------
-- Savanna Sunrise: a little sun climbs behind each hit; a crit is raised
-- on a rock ledge as a huge sun rises and birds cross it.
---------------------------------------------------------------------------
local SUN, ROCK = { 1, 0.52, 0.16 }, { 0.12, 0.06, 0.035 }
add("savannasunrise", {
    group = "pop", listNote = "Secret",
    name = "Savanna Sunrise", tagline = "A little sun climbs behind each hit; crits stand on a rock ledge as a huge sun rises and birds cross it.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.86, 0.55 }, physColor = { 1, 0.93, 0.76 }, spellColor = { 1, 0.62, 0.26 },
    layers = { { x = 2, y = -2, color = { 0.35, 0.12, 0.02, 1 } } },
    motion = "rise", motionArgs = { speed = 18 },
    dur = 1.25, critDur = 1.9, critScale = 1.5, pop = 0.2,
    hitPieces = {
        { tex = "sundisc", size = 46, y = 2, from = { 0, -24 }, move = 0.5, life = 0.85, color = SUN, alpha = 0.6 },
    },
    critPieces = {
        { tex = "glow", size = { 190, 110 }, y = 4, delay = 0.15, life = 1.2, color = { 1, 0.45, 0.1 }, alpha = 0.4 },
        { tex = "sundisc", size = 140, y = 12, from = { 0, -70 }, move = 0.75, hold = true, color = SUN, alpha = 0.82 },
        { tex = "ledge", size = { 136, 68 }, x = -12, y = -38, reveal = "right", move = 0.3, hold = true, color = ROCK, alpha = 1, blend = "BLEND" },
    },
    glowColor = SUN,
    particles = { tex = "puff", count = 2, critCount = 8, size = { 8, 14 }, speed = { 10, 30 }, dir = { 60, 120 },
                  origin = { 0, -14 }, spread = { 50, 6 }, gravity = 10, life = { 0.6, 1.0 }, color = { 0.92, 0.7, 0.42 }, blend = "BLEND", drag = 1 },
    particles2 = { tex = "bird", count = 0, critCount = 4, size = { 9, 13 }, speed = { 34, 50 }, dir = { 168, 192 },
                   origin = { 70, 34 }, spread = { 20, 24 }, delay = { 0.45, 0.8 }, gravity = 0, life = { 1.0, 1.3 }, color = ROCK, blend = "BLEND",
                   drag = 0, shrink = 0, sway = true },
})

---------------------------------------------------------------------------
-- Rubber Hose: a black-and-white cartoon. Numbers bounce on the beat; a
-- crit gets film scratches and closes with an iris-out.
---------------------------------------------------------------------------
local INK, PAPER = { 0, 0, 0 }, { 0.96, 0.95, 0.9 }
add("rubberhose", {
    group = "pop", listNote = "Secret",
    name = "Rubber Hose", tagline = "An old black-and-white cartoon: numbers bounce on the beat; crits flicker with film scratches and close with an iris-out.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = PAPER, physColor = PAPER, spellColor = { 0.8, 0.8, 0.76 },
    layers = { { x = 2, y = -2, color = { 0, 0, 0, 1 } }, { x = 3.5, y = -3.5, color = { 0.3, 0.3, 0.3, 1 } } },
    motion = "beat", motionArgs = { period = 0.28, height = 12, speed = 10, squash = 0.14 },
    dur = 1.3, critDur = 1.95, critScale = 1.5, pop = 0, noGlow = true,
    hitPieces = {
        { tex = "arc", size = 34, y = -16, rot = math.pi, snap = 0.5, snapTime = 0.1, life = 0.25, color = PAPER, alpha = 0.7 },
        { tex = "speedlines", size = { 22, 14 }, x = -38, y = 2, life = 0.3, color = PAPER, alpha = 0.7 },
    },
    critPieces = {
        { tex = "filmscratch", size = { 170, 120 }, hold = true, flicker = true, color = PAPER, alpha = 0.4 },
        { tex = "impact", size = 62, snap = 0.4, snapTime = 0.1, life = 0.26, color = PAPER, alpha = 0.45 },
        { tex = "iris", size = 190, delay = 0.85, snap = 4, snapTime = 0.55, hold = true, color = INK, alpha = 0.95, blend = "BLEND" },
    },
    critTitle = { text = "THE END", y = -40, size = 13, font = F.morpheus, pop = 0.4, delay = 1.25,
                  colors = { PAPER }, shadowColor = { 0, 0, 0 } },
    particles = { tex = "star", count = 0, critCount = 6, size = { 7, 11 }, speed = { 50, 110 }, dir = { 20, 160 },
                  gravity = -150, life = { 0.4, 0.7 }, color = PAPER, blend = "BLEND", spin = 5 },
})

---------------------------------------------------------------------------
-- Toy Box: hits pop up on a letter block; crits stack a row of blocks that
-- wobble, then topple.
---------------------------------------------------------------------------
local TOY = { { 0.92, 0.3, 0.25 }, { 1, 0.78, 0.2 }, { 0.3, 0.58, 0.96 }, { 0.42, 0.8, 0.35 } }
local function block(tex, color, x, delay, after)
    return { tex = tex, size = 34, x = x, y = -30, from = { x, 46 }, ease = "in", move = 0.16, delay = delay,
             wobble = { 0.25, 34, 7 }, hold = true, after = after, color = color, alpha = 1, blend = "BLEND" }
end
add("toybox", {
    group = "pop", listNote = "Secret",
    name = "Toy Box", tagline = "Hits pop up on a wooden letter block; crits drop a row of blocks that wobbles, then topples.",
    font = F.block, size = 23, outline = "OUTLINE",
    color = { 1, 0.96, 0.86 }, physColor = { 1, 0.98, 0.92 }, spellColor = { 1, 0.78, 0.3 },
    layers = { { x = 2, y = -2, color = { 0.24, 0.12, 0.03, 1 } } },
    motion = "rise", motionArgs = { speed = 12 },
    dur = 1.2, critDur = 1.9, critScale = 1.5, pop = 0.2,
    hitPieces = {
        { tex = "blockA", size = 24, y = -24, from = { 0, -40 }, move = 0.14, wobble = { 0.25, 30, 8 }, life = 0.75,
          color = TOY[1], alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        block("blockA", TOY[1], -32, 0, { at = 1.1, move = 0.45, x = -70, y = -90, rot = 1.3, ease = "in" }),
        block("blockB", TOY[2], 0, 0.08, { at = 1.16, move = 0.45, x = 6, y = -100, rot = -0.6, ease = "in" }),
        block("blockC", TOY[3], 32, 0.16, { at = 1.12, move = 0.45, x = 72, y = -92, rot = -1.4, ease = "in" }),
        { tex = "blockA", size = 28, x = 58, y = 2, from = { 58, 70 }, ease = "in", move = 0.16, delay = 0.26, wobble = { 0.35, 30, 4 },
          hold = true, after = { at = 0.95, move = 0.4, x = 96, y = -70, rot = -1.8, ease = "in" }, color = TOY[4], alpha = 1, blend = "BLEND" },
    },
    glowColor = { 1, 0.8, 0.4 }, glowAlpha = 0.2,
    particles = { tex = "star", count = 0, critCount = 9, size = { 6, 10 }, speed = { 60, 130 }, dir = { 30, 150 },
                  delay = 0.24, gravity = -200, life = { 0.5, 0.9 }, randomColor = true, spin = 5 },
})

---------------------------------------------------------------------------
-- Island Alert: a black notification pill stretches open round each hit;
-- crits stretch it wide, spin a loader and tick it done.
---------------------------------------------------------------------------
local PILL, OK = { 0.02, 0.02, 0.03 }, { 0.3, 0.9, 0.5 }
add("islandalert", {
    group = "pop", listNote = "Secret",
    name = "Island Alert", tagline = "A black notification pill stretches open round each hit; crits stretch it wide, spin a loader and tick it done.",
    font = F.arialn, size = 20, outline = "OUTLINE",
    color = WHITE, physColor = WHITE, spellColor = { 0.62, 0.86, 1 },
    motion = "rise", motionArgs = { speed = 6 },
    dur = 1.15, critDur = 1.7, critScale = 1.45, pop = 0, noSpring = true, noGlow = true,
    hitPieces = {
        { tex = "pill", size = { 96, 28 }, fromSize = { 30, 14 }, move = 0.22, hold = true,
          after = { at = 0.85, move = 0.2, size = { 30, 14 } }, color = PILL, alpha = 0.95, blend = "BLEND" },
        { tex = "dot", size = 8, x = -36, delay = 0.18, snap = 2, snapTime = 0.1, life = 0.6, color = OK, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "pill", size = { 144, 38 }, fromSize = { 40, 20 }, move = 0.3, hold = true,
          after = { at = 1.35, move = 0.22, size = { 40, 20 } }, color = PILL, alpha = 0.96, blend = "BLEND" },
        { tex = "spinner", size = 24, x = -56, spin = -11, delay = 0.12, life = 0.55, color = OK, alpha = 1, blend = "BLEND" },
        { tex = "check", size = 22, x = -56, delay = 0.62, snap = 0.3, snapTime = 0.15, hold = true,
          after = { at = 1.3, move = 0.15, size = 1 }, color = OK, alpha = 1, blend = "BLEND" },
        { tex = "ring", size = 30, x = -56, grow = 0.8, delay = 0.62, life = 0.35, color = OK, alpha = 0.8 },
    },
    critTitle = { text = "now", x = 56, y = 0, size = 10, font = F.arialn, pop = 0.1, delay = 0.3,
                  colors = { { 0.62, 0.62, 0.68 } }, shadowColor = PILL },
})

---------------------------------------------------------------------------
-- Frosted Glass: clean thin numbers on a frosted tile; crits catch a
-- rainbow sheen that sweeps across.
---------------------------------------------------------------------------
local FROST = { 0.92, 0.95, 1 }
local function sheen(color, dx, delay)
    return { tex = "sheen", size = { 24, 50 }, x = 52 + dx, from = { -52 + dx, 0 }, ease = "linear", move = 0.5,
             delay = delay, life = 0.62, color = color, alpha = 0.6 }
end
add("frostedglass", {
    group = "pop", listNote = "Secret",
    name = "Frosted Glass", tagline = "Clean thin numbers on a frosted glass tile; crits catch a rainbow sheen that sweeps across.",
    font = F.arialn, size = 22, outline = "OUTLINE",
    color = WHITE, physColor = WHITE, spellColor = { 0.84, 0.9, 1 },
    layers = { { x = 0, y = -1.5, color = { 0, 0, 0, 0.4 } } },
    motion = "rise", motionArgs = { speed = 16 },
    dur = 1.2, critDur = 1.65, critScale = 1.45, pop = 0.15,
    hitPieces = {
        { tex = "glasstile", size = { 84, 36 }, snap = 0.85, snapTime = 0.15, life = 0.8, color = FROST, alpha = 0.6, blend = "BLEND" },
    },
    critPieces = {
        { tex = "glasstile", size = { 124, 50 }, snap = 0.8, snapTime = 0.2, hold = true, color = FROST, alpha = 0.65, blend = "BLEND" },
        sheen({ 1, 0.5, 0.78 }, -7, 0.22),
        sheen({ 1, 0.9, 0.45 }, 0, 0.24),
        sheen({ 0.45, 0.9, 1 }, 7, 0.26),
        { tex = "twinkle", size = 16, x = -48, y = 18, delay = 0.7, snap = 2, snapTime = 0.1, life = 0.4, front = true, color = WHITE, alpha = 1 },
    },
    glowColor = WHITE, glowAlpha = 0.18,
})

---------------------------------------------------------------------------
-- Edge Glow: a light races round each hit's rounded frame; crits send it
-- round twice in every color.
---------------------------------------------------------------------------
local RAINBOW = { { 1, 0.3, 0.35 }, { 1, 0.6, 0.2 }, { 1, 0.92, 0.3 }, { 0.4, 1, 0.45 }, { 0.3, 0.9, 1 },
                  { 0.35, 0.5, 1 }, { 0.7, 0.4, 1 }, { 1, 0.4, 0.85 } }
-- Streaks racing clockwise round a w x h frame, one leg per edge.
local function laps(list, w, h, t0, speed, n, colors, thick)
    local hw, hh = w / 2 - 1.5, h / 2 - 1.5
    local legs = {
        { -hw, hh, hw, hh, 0 }, { hw, hh, hw, -hh, -math.pi / 2 },
        { hw, -hh, -hw, -hh, math.pi }, { -hw, -hh, -hw, hh, math.pi / 2 },
    }
    local t = t0
    for i = 1, n * 4 do
        local L = legs[(i - 1) % 4 + 1]
        local time = math.abs(L[3] - L[1] + L[4] - L[2]) / speed
        list[#list + 1] = { tex = "streak", size = { w * 0.55, thick }, from = { L[1], L[2] }, x = L[3], y = L[4], rot = L[5],
                            ease = "linear", move = time, delay = t, life = time * 1.7, color = colors[(i - 1) % #colors + 1], alpha = 1 }
        t = t + time
    end
    return t
end
local edgeHit = { { tex = "edgeframe", size = { 96, 40 }, snap = 0.9, snapTime = 0.12, hold = true, color = { 0.4, 0.7, 1 }, alpha = 0.55 } }
laps(edgeHit, 96, 40, 0.02, 560, 1, { { 0.5, 0.82, 1 } }, 9)
local edgeCrit = { { tex = "edgeframe", size = { 128, 52 }, snap = 0.85, snapTime = 0.15, hold = true, color = WHITE, alpha = 0.6 } }
local lapEnd = laps(edgeCrit, 128, 52, 0.04, 640, 2, RAINBOW, 12)
edgeCrit[#edgeCrit + 1] = { tex = "glow", size = { 180, 90 }, delay = lapEnd, life = 0.45, color = { 0.6, 0.8, 1 }, alpha = 0.55 }
add("edgeglow", {
    group = "pop", listNote = "Secret",
    name = "Edge Glow", tagline = "A light races round each hit's rounded frame; crits send it round twice in every color.",
    font = F.arialn, size = 21, outline = "OUTLINE",
    color = { 0.88, 0.96, 1 }, physColor = { 0.95, 0.98, 1 }, spellColor = { 0.55, 0.82, 1 },
    layers = { { x = 0, y = -1.5, color = { 0, 0.05, 0.15, 0.6 } } },
    motion = "rise", motionArgs = { speed = 14 },
    dur = 1.15, critDur = 1.7, critScale = 1.45, pop = 0.15,
    hitPieces = edgeHit,
    critPieces = edgeCrit,
    glowColor = { 0.5, 0.75, 1 }, glowAlpha = 0.2,
})

---------------------------------------------------------------------------
-- Fast Charge: a battery under each hit charges a little; crits fill it,
-- flash a bolt and call 100%.
---------------------------------------------------------------------------
local CHARGE, FULL = { 1, 0.82, 0.25 }, { 0.3, 0.95, 0.45 }
add("fastcharge", {
    group = "pop", listNote = "Secret",
    name = "Fast Charge", tagline = "A battery under each hit charges a little; crits fill it to the top, flash a bolt and call 100%.",
    font = F.arialn, size = 22, outline = "OUTLINE",
    color = { 0.88, 1, 0.9 }, physColor = { 0.94, 1, 0.95 }, spellColor = { 0.45, 1, 0.6 },
    layers = { { x = 1, y = -1.5, color = { 0, 0.15, 0.05, 1 } } },
    motion = "rise", motionArgs = { speed = 14 },
    dur = 1.2, critDur = 1.75, critScale = 1.45, pop = 0.15,
    hitPieces = {
        { tex = "battery", size = { 44, 22 }, y = -22, life = 0.85, color = WHITE, alpha = 0.9 },
        { tex = "pixel", size = { 11.6, 8.5 }, x = -11.7, y = -22, reveal = "right", move = 0.3, life = 0.85, color = CHARGE, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "battery", size = { 72, 36 }, y = -32, hold = true, color = WHITE, alpha = 0.95 },
        { tex = "pixel", size = { 47, 14 }, x = -5, y = -32, reveal = "right", move = 0.5, hold = true, color = CHARGE, alpha = 1, blend = "BLEND" },
        { tex = "pixel", size = { 47, 14 }, x = -5, y = -32, delay = 0.52, hold = true, color = FULL, alpha = 1, blend = "BLEND" },
        { tex = "bolt", size = { 14, 28 }, x = -5, y = -32, rot = -0.3, delay = 0.52, snap = 2, snapTime = 0.12, hold = true,
          front = true, color = { 1, 1, 0.6 }, alpha = 1 },
        { tex = "ring", size = 70, y = -32, grow = 0.9, delay = 0.52, life = 0.45, color = FULL, alpha = 0.8 },
    },
    critTitle = { text = "100%", y = 32, size = 12, font = F.arialn, pop = 0.9, delay = 0.54,
                  colors = { FULL, WHITE }, shadowColor = { 0, 0.15, 0.05 } },
    glowColor = FULL, glowAlpha = 0.25,
    particles = { tex = "spark", count = 0, critCount = 10, size = { 3, 6 }, speed = { 60, 130 }, dir = { 0, 360 },
                  origin = { 0, -32 }, delay = 0.52, gravity = 0, life = { 0.25, 0.45 }, color = { 1, 1, 0.6 } },
})

---------------------------------------------------------------------------
-- Read Receipt: hits arrive in a grey chat bubble; on a crit the typing
-- dots bounce first, then it lands in a big blue bubble: Delivered.
---------------------------------------------------------------------------
local BUBBLE, SENT, DOTS = { 0.24, 0.24, 0.27 }, { 0.16, 0.52, 1 }, { 0.7, 0.7, 0.76 }
local function typingDot(x, delay)
    return { tex = "dot", size = 6, x = x, steady = true, delay = delay, life = 0.4, pulse = { 0.5, 22 }, color = DOTS, alpha = 1, blend = "BLEND" }
end
add("readreceipt", {
    group = "pop", listNote = "Secret",
    name = "Read Receipt", tagline = "Hits arrive in a chat bubble; on crits the typing dots bounce, then it lands in a big blue bubble: Delivered.",
    font = F.arialn, size = 21, outline = "OUTLINE",
    color = WHITE, physColor = WHITE, spellColor = { 0.82, 0.92, 1 },
    motion = "rise", motionArgs = { speed = 12 },
    dur = 1.2, critDur = 1.8, critScale = 1.45, pop = 0, noSpring = true, noGlow = true, noFlash = true,
    critScaleKeys = { { 0, 0.02 }, { 0.4, 0.02 }, { 0.48, 1.15 }, { 0.58, 1 } },
    hitPieces = {
        { tex = "chatbubbleL", size = { 84, 38 }, snap = 0.6, snapTime = 0.15, life = 0.85, color = BUBBLE, alpha = 0.95, blend = "BLEND" },
    },
    critPieces = {
        { tex = "chatbubbleL", size = { 46, 26 }, x = -24, steady = true, snap = 0.6, snapTime = 0.12, life = 0.44, color = BUBBLE, alpha = 0.95, blend = "BLEND" },
        typingDot(-33, 0.04), typingDot(-24, 0.1), typingDot(-15, 0.16),
        { tex = "chatbubble", size = { 104, 42 }, steady = true, delay = 0.4, snap = 0.4, snapTime = 0.15, hold = true,
          color = SENT, alpha = 1, blend = "BLEND" },
    },
    critTitle = { text = "Delivered", x = 26, y = -30, size = 8, font = F.arialn, pop = 0.1, delay = 0.72,
                  colors = { { 0.7, 0.7, 0.76 } }, shadowColor = { 0, 0, 0 } },
})

---------------------------------------------------------------------------
-- Ring Closer: an activity ring ticks round beside each hit; crits close
-- all three rings round the number.
---------------------------------------------------------------------------
local MOVE, EXER, STAND = { 1, 0.16, 0.36 }, { 0.62, 1, 0.12 }, { 0.12, 0.88, 1 }
local function ring(list, n, size, color, x, t0, step, count)
    list[#list + 1] = { tex = "fittrk" .. n, size = size, x = x, hold = true, color = color, alpha = 0.22, blend = "BLEND" }
    for i = 0, count - 1 do
        list[#list + 1] = { tex = "fitseg" .. n, size = size, x = x, rot = -i * math.pi / 6, delay = t0 + i * step, hold = true,
                            color = color, alpha = 1, blend = "BLEND" }
    end
end
local ringHit, ringCrit = {}, {}
ring(ringHit, 3, 30, MOVE, -46, 0.02, 0.035, 8)
ring(ringCrit, 1, 116, MOVE, 0, 0.04, 0.034, 12)
ring(ringCrit, 2, 90, EXER, 0, 0.14, 0.034, 12)
ring(ringCrit, 3, 64, STAND, 0, 0.24, 0.034, 12)
ringCrit[#ringCrit + 1] = { tex = "ring", size = 120, grow = 0.4, delay = 0.66, life = 0.4, color = WHITE, alpha = 0.8 }
add("ringcloser", {
    group = "pop", listNote = "Secret",
    name = "Ring Closer", tagline = "An activity ring ticks round beside each hit; crits close all three rings round the number.",
    font = F.arialn, size = 22, outline = "OUTLINE",
    color = WHITE, physColor = WHITE, spellColor = { 0.7, 1, 0.4 },
    layers = { { x = 1, y = -1.5, color = { 0, 0, 0, 0.8 } } },
    motion = "rise", motionArgs = { speed = 10 },
    dur = 1.2, critDur = 1.75, critScale = 1.45, pop = 0.15,
    hitPieces = ringHit,
    critPieces = ringCrit,
    glowColor = STAND, glowAlpha = 0.15,
    particles = { tex = "twinkle", count = 0, critCount = 10, size = { 7, 11 }, speed = { 50, 110 }, dir = { 0, 360 },
                  delay = 0.66, gravity = 0, life = { 0.4, 0.7 }, color = WHITE, altColor = EXER },
})
