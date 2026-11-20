local _, ns = ...

-- PvP skins. Same data format as Skins.lua (see its header); group = "pvp".
-- Each id matches its feat in Feats.lua.
--
-- Two rank ladders follow Forever's PvP rank, at the Legacy ranks (3, 7, 10,
-- 13, 14): each keeps its
-- faction's look and adds more, up to the Rank 14 showpieces, which bring
-- everything the engine has: an aura on every hit, and on crits a title
-- banner, two particle systems, layered bursts and (Horde) a war-drum pulse.
-- The rank skins carry the game's own Alliance and Horde crests;
-- every spike, flag, blade and burst is SkinDeep's own art.

local F = ns.Fonts
local add = ns.AddSkin

local GOLD = { 1, 0.84, 0.32 }
local WHITE = { 1, 1, 1 }
-- The game's own faction crests (the battleground countdown emblems).
local ALLIANCE_CREST, HORDE_CREST = "Interface\\Timer\\Alliance-Logo", "Interface\\Timer\\Horde-Logo"
-- The faction symbol, small above every hit (SkinDeep's own art stands in
-- if the client lacks the crest).
local function emblem(file, fallback, size, y, alpha)
    return { file = file, tex = fallback, size = size, y = y, color = WHITE, alpha = alpha or 0.85, blend = "BLEND" }
end
-- The faction crest behind a crit.
local function crest(file, fallback, size, alpha)
    return { file = file, tex = fallback, size = size, color = WHITE, alpha = alpha or 0.95, blend = "BLEND", snap = 1.4, snapTime = 0.14 }
end
-- The crest as a crit piece (Engine.lua: animatePiece), held until the
-- number fades; d gives where it goes and how it gets there.
local function crestPiece(file, fallback, d)
    d.file, d.tex, d.color, d.blend = file, fallback, WHITE, "BLEND"
    if d.hold == nil then d.hold = true end
    return d
end
local A_PHYS, A_SPELL ={ 0.95, 0.93, 0.85 }, { 0.35, 0.6, 1 }   -- Alliance: ivory / royal blue
local H_PHYS, H_SPELL = { 0.9, 0.85, 0.78 }, { 0.92, 0.15, 0.12 } -- Horde: bone / blood red

local function glow(c, a, d)
    d = d or 1.5
    return {
        { x = d, y = d, color = { c[1], c[2], c[3], a } },
        { x = -d, y = -d, color = { c[1], c[2], c[3], a } },
        { x = d, y = -d, color = { c[1], c[2], c[3], a } },
        { x = -d, y = d, color = { c[1], c[2], c[3], a } },
    }
end

---------------------------------------------------------------------------
-- Alliance ranks
---------------------------------------------------------------------------
add("sergeant_a", {
    group = "pvp", faction = "Alliance", rank = 3,
    name = "Sergeant", tagline = "Alliance, Rank 3: blue numbers under the Alliance crest; crits stamp the crest down onto them in a puff of dust.",
    font = F.morpheus, size = 24, outline = "OUTLINE",
    color = { 0.45, 0.65, 1 }, physColor = A_PHYS, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.04, 0.1, 0.3, 1 } } },
    motion = "rise", motionArgs = { speed = 30 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.25, shake = 3, shakeAt = 0.14,
    decor = emblem(ALLIANCE_CREST, "shield", 22, 26),
    critReplacesDecor = true,
    -- The crest falls like a seal and stamps down; dust kicks out both ways.
    critPieces = {
        { tex = "twinkle", size = 70, y = 26, delay = 0.13, life = 0.22, color = { 0.8, 0.88, 1 } },
        crestPiece(ALLIANCE_CREST, "shield", { size = 60, y = 32, from = { 0, 150 }, ease = "in", move = 0.14 }),
    },
    particles = { tex = "puff", count = 0, critCount = 4, size = { 14, 22 }, speed = { 50, 90 }, dir = { 165, 195 },
                  gravity = 15, life = { 0.35, 0.6 }, origin = { -14, 12 }, delay = 0.14, color = { 0.55, 0.58, 0.68 },
                  blend = "BLEND" },
    particles2 = { tex = "puff", count = 0, critCount = 4, size = { 14, 22 }, speed = { 50, 90 }, dir = { -15, 15 },
                   gravity = 15, life = { 0.35, 0.6 }, origin = { 14, 12 }, delay = 0.14, color = { 0.55, 0.58, 0.68 },
                   blend = "BLEND" },
})

add("knight", {
    group = "pvp", faction = "Alliance", rank = 7,
    name = "Knight-Lieutenant", tagline = "Alliance, Rank 7: stately blue-and-gold numbers; crits unroll a war banner behind them bearing the crest.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.35, 0.6, 1 }, physColor = A_PHYS, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.05, 0.12, 0.35, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.3, critDur = 1.7, critScale = 1.5, pop = 0.25,
    decor = emblem(ALLIANCE_CREST, "shield", 22, 26),
    critReplacesDecor = true,
    -- A gold pole, the banner unrolling down from it, then the crest on it.
    critPieces = {
        { tex = "banner", size = { 66, 128 }, y = -2, reveal = "down", move = 0.36, hold = true,
          color = { 0.16, 0.34, 0.85 }, alpha = 0.95, blend = "BLEND" },
        { tex = "pixel", size = { 88, 4 }, y = 62, snap = 0.2, snapTime = 0.1, hold = true, color = GOLD, blend = "BLEND" },
        crestPiece(ALLIANCE_CREST, "shield", { size = 42, y = 34, delay = 0.24, snap = 1.5, snapTime = 0.12 }),
    },
    particles = { tex = "spark", count = 0, critCount = 7, size = { 3, 5 }, speed = { 8, 24 }, dir = { 250, 290 },
                  gravity = -30, sway = true, life = { 0.6, 1.0 }, origin = { 0, 60 }, spread = { 84, 2 },
                  delay = { 0.1, 0.4 }, color = GOLD },
})

add("ltcommander", {
    group = "pvp", faction = "Alliance", rank = 10,
    name = "Lieutenant Commander", tagline = "Alliance, Rank 10: gilded numbers under the crest; crits swing two swords in to cross behind it with a clang of sparks.",
    font = F.morpheus, size = 26, outline = "OUTLINE",
    color = { 0.45, 0.68, 1 }, physColor = A_PHYS, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.05, 0.12, 0.35, 1 } }, { x = -1, y = 1, color = { 1, 0.88, 0.45, 0.6 } } },
    motion = "rise", motionArgs = { speed = 26 },
    dur = 1.35, critDur = 1.7, critScale = 1.55, pop = 0.3,
    decor = emblem(ALLIANCE_CREST, "shield", 24, 27),
    critReplacesDecor = true,
    -- Two longswords swing up from the sides and cross; the crest lands on
    -- the crossing as they clang.
    critPieces = {
        { tex = "sword", size = { 22, 100 }, y = 30, fromRot = 1.6, rot = 0.55, move = 0.2, hold = true,
          color = { 0.9, 0.92, 1 }, blend = "BLEND" },
        { tex = "sword", size = { 22, 100 }, y = 30, fromRot = -1.6, rot = -0.55, move = 0.2, hold = true,
          color = { 0.9, 0.92, 1 }, blend = "BLEND" },
        { tex = "twinkle", size = 64, y = 30, delay = 0.18, life = 0.26, color = GOLD },
        crestPiece(ALLIANCE_CREST, "shield", { size = 48, y = 30, delay = 0.17, snap = 1.5, snapTime = 0.12 }),
    },
    particles = { tex = "spark", count = 0, critCount = 12, size = { 3, 6 }, speed = { 80, 170 }, dir = { 0, 360 },
                  gravity = -200, life = { 0.25, 0.5 }, origin = { 0, 30 }, delay = 0.19, color = { 1, 0.92, 0.6 } },
    particles2 = { tex = "twinkle", count = 1, critCount = 0, size = { 8, 12 }, speed = { 10, 30 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.5, 0.9 }, color = GOLD },
})

add("fieldmarshal", {
    group = "pvp", faction = "Alliance", rank = 13,
    name = "Field Marshal", tagline = "Alliance, Rank 13: silver-and-blue numbers over a laurel; crits cross the swords, flare silver rays and call FIELD MARSHAL.",
    font = F.morpheus, size = 27, outline = "OUTLINE",
    color = { 0.78, 0.86, 1 }, physColor = { 0.93, 0.95, 1 }, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.04, 0.1, 0.3, 1 } }, { x = -1, y = 1, color = { 1, 1, 1, 0.45 } } },
    motion = "rise", motionArgs = { speed = 32 },
    dur = 1.4, critDur = 2.0, critScale = 1.7, pop = 0.3,
    decor = emblem(ALLIANCE_CREST, "shield", 24, 27, 0.9),
    critReplacesDecor = true,
    critDecor = { tex = "laurel", size = 104, y = -4, color = { 0.6, 0.85, 0.55 }, alpha = 0.95, blend = "BLEND", snap = 0.4, snapTime = 0.15 },
    critDecor2 = crest(ALLIANCE_CREST, "shield", 82),
    critTitle = { text = "FIELD MARSHAL", y = 50, size = 16, font = F.morpheus, pop = 1.35,
                  colors = { { 0.86, 0.9, 1 }, { 1, 1, 1 }, { 0.5, 0.7, 1 } }, shadowColor = { 0.04, 0.1, 0.3 } },
    particles = { tex = "twinkle", count = 1, critCount = 12, size = { 9, 15 }, speed = { 30, 90 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.1 }, color = { 0.86, 0.9, 1 }, altColor = { 0.6, 0.75, 1 } },
})

add("grandmarshal", {
    group = "pvp", faction = "Alliance", rank = 14,
    name = "Grand Marshal", tagline = "Alliance, Rank 14: every hit glows in a halo of golden rays. Crits crown the crest under a blazing sunburst, GRAND MARSHAL, and a shower of gold and blue.",
    font = F.morpheus, size = 28, outline = "THICKOUTLINE",
    color = GOLD, physColor = A_PHYS, spellColor = A_SPELL,
    layers = {
        { x = -1, y = 1, color = { 1, 0.95, 0.7, 0.9 } },
        { x = 2, y = -2, color = { 0.6, 0.42, 0.05, 1 } },
        { x = 4, y = -4, color = { 0.05, 0.1, 0.3, 1 } },
    },
    motion = "rise", motionArgs = { speed = 30 },
    dur = 1.5, critDur = 2.4, critScale = 1.8, pop = 0.35,
    decor = { tex = "burst", size = 90, color = GOLD, alpha = 0.3, spin = 0.4 },
    critDecor = { tex = "burst", size = 170, color = GOLD, alpha = 0.75, spin = 0.35, snap = 0.2, snapTime = 0.2 },
    critDecor2 = crest(ALLIANCE_CREST, "shield", 86, 1),
    ring = { size = 100, color = { 1, 0.95, 0.7 }, grow = 1.6, alpha = 1 },
    critTitle = { text = "GRAND MARSHAL", y = 52, size = 17, font = F.morpheus, pop = 1.4,
                  colors = { GOLD, { 1, 1, 1 }, { 0.5, 0.75, 1 } }, shadowColor = { 0.05, 0.1, 0.3 } },
    particles = { tex = "pixel", count = 2, critCount = 22, size = { 4, 7 }, speed = { 90, 220 }, dir = { 40, 140 },
                  gravity = -260, life = { 0.8, 1.5 }, color = GOLD, altColor = { 0.35, 0.6, 1 }, blend = "BLEND", spin = 8 },
    particles2 = { tex = "twinkle", count = 1, critCount = 2, size = { 14, 24 }, speed = { 10, 30 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.8, 1.4 }, color = { 1, 0.95, 0.75 } },
    world = { WorldTextScale = 1.25 },
})

---------------------------------------------------------------------------
-- Horde ranks
---------------------------------------------------------------------------
add("sergeant_h", {
    group = "pvp", faction = "Horde", rank = 3,
    name = "Sergeant", tagline = "Horde, Rank 3: red numbers drop under the Horde crest; crits chisel the crest into stone, chips flying and claw marks fading.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.95, 0.3, 0.2 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 36, fall = 0.1, squash = 0.3, sinkAt = 0.4, sink = 10 },
    dur = 1.15, critDur = 1.45, critScale = 1.5, pop = 0, shake = 3,
    decor = emblem(HORDE_CREST, "spikes", 22, 26),
    critReplacesDecor = true,
    -- Three scratches carve it; the crest shows through as the chips fly.
    critPieces = {
        crestPiece(HORDE_CREST, "spikes", { size = 58, y = 34, delay = 0.04, snap = 0.7, snapTime = 0.2 }),
        { tex = "claws", size = 64, y = 34, life = 0.5, color = { 1, 0.86, 0.72 }, alpha = 0.8, snap = 1.3, snapTime = 0.08 },
    },
    particles = { tex = "shard", count = 0, critCount = 11, size = { 5, 8 }, speed = { 60, 140 }, dir = { 20, 160 },
                  gravity = -420, life = { 0.4, 0.7 }, origin = { 0, 34 }, delay = 0.03, spin = 9,
                  color = { 0.62, 0.56, 0.5 }, blend = "BLEND" },
})

add("stoneguard", {
    group = "pvp", faction = "Horde", rank = 7,
    name = "Blood Guard", tagline = "Horde, Rank 7: heavy numbers slam down; crits swipe three strokes of war paint behind them that run, then stamp the crest on.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 0.92, 0.2, 0.15 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 45, fall = 0.12, squash = 0.3, sinkAt = 0.35, sink = 12 },
    dur = 1.15, critDur = 1.6, critScale = 1.55, pop = 0, shake = 4,
    decor = emblem(HORDE_CREST, "spikes", 22, 26),
    critReplacesDecor = true,
    critPieces = {
        { tex = "brush", size = { 132, 26 }, y = 10, reveal = "right", move = 0.13, life = 1.2,
          color = { 0.6, 0.04, 0.03 }, alpha = 0.92, blend = "BLEND" },
        { tex = "brush", size = { 132, 26 }, x = 4, y = -3, reveal = "right", move = 0.13, delay = 0.08, life = 1.2,
          color = { 0.6, 0.04, 0.03 }, alpha = 0.92, blend = "BLEND" },
        { tex = "brush", size = { 132, 26 }, x = -2, y = -16, reveal = "right", move = 0.13, delay = 0.16, life = 1.2,
          color = { 0.6, 0.04, 0.03 }, alpha = 0.92, blend = "BLEND" },
        crestPiece(HORDE_CREST, "spikes", { size = 50, y = 40, delay = 0.3, snap = 1.6, snapTime = 0.1 }),
    },
    -- The paint runs.
    particles = { tex = "drop", count = 0, critCount = 7, size = { 6, 9 }, aspect = 0.55, speed = { 0, 8 }, dir = { 265, 275 },
                  gravity = -90, drag = 0, life = { 0.5, 0.8 }, origin = { 0, -4 }, spread = { 110, 26 },
                  delay = { 0.35, 0.65 }, color = { 0.55, 0.03, 0.02 }, blend = "BLEND" },
})

add("champion", {
    group = "pvp", faction = "Horde", rank = 10,
    name = "Champion", tagline = "Horde, Rank 10: iron-edged numbers slam with embers; crits raise two crossed spears that lift the crest high.",
    font = F.skurri, size = 31, outline = "THICKOUTLINE",
    color = { 1, 0.3, 0.15 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } }, { x = 4, y = -4, color = { 0.05, 0, 0, 1 } } },
    motion = "drop", motionArgs = { height = 48, fall = 0.12, squash = 0.32, sinkAt = 0.35, sink = 12 },
    dur = 1.2, critDur = 1.65, critScale = 1.6, pop = 0, shake = 6,
    decor = emblem(HORDE_CREST, "spikes", 24, 27),
    critReplacesDecor = true,
    -- Two spears thrust up from below and cross; the crest rises on them.
    critPieces = {
        { tex = "spear", size = { 20, 124 }, y = 8, rot = 0.42, from = { 0, -120 }, move = 0.24, hold = true,
          color = { 0.86, 0.74, 0.58 }, blend = "BLEND" },
        { tex = "spear", size = { 20, 124 }, y = 8, rot = -0.42, from = { 0, -120 }, move = 0.24, delay = 0.04, hold = true,
          color = { 0.86, 0.74, 0.58 }, blend = "BLEND" },
        crestPiece(HORDE_CREST, "spikes", { size = 52, y = 46, from = { 0, 22 }, delay = 0.2, move = 0.22 }),
    },
    particles = { tex = "spark", count = 1, critCount = 10, size = { 3, 7 }, speed = { 30, 80 }, dir = { 60, 120 },
                  gravity = 70, life = { 0.5, 1.0 }, color = { 1, 0.45, 0.1 } },
})

add("warlord", {
    group = "pvp", faction = "Horde", rank = 13,
    name = "Warlord", tagline = "Horde, Rank 13: iron numbers under the crest; crits raise a wall of fire behind them, the crest dark in the flames, and roar WARLORD.",
    font = F.skurri, size = 31, outline = "THICKOUTLINE",
    color = { 0.95, 0.25, 0.15 }, physColor = { 0.93, 0.88, 0.84 }, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } }, { x = 4, y = -4, color = { 0.05, 0, 0, 1 } } },
    motion = "drop", motionArgs = { height = 46, fall = 0.12, squash = 0.32, sinkAt = 0.4, sink = 10 },
    dur = 1.3, critDur = 1.9, critScale = 1.7, pop = 0, shake = 7,
    decor = emblem(HORDE_CREST, "spikes", 24, 27, 0.9),
    critReplacesDecor = true,
    critPieces = {},   -- the wall of fire, filled in below
    critTitle = { text = "WARLORD", y = 58, size = 18, font = F.skurri, pop = 1.45,
                  colors = { { 1, 0.3, 0.15 }, { 1, 0.85, 0.5 }, { 0.85, 0.08, 0.05 } }, shadowColor = { 0.15, 0, 0 } },
    particles = { tex = "spark", count = 1, critCount = 14, size = { 3, 6 }, speed = { 40, 90 }, dir = { 80, 100 },
                  gravity = 30, sway = true, life = { 0.6, 1.1 }, origin = { 0, -16 }, spread = { 130, 8 },
                  delay = { 0.05, 0.5 }, color = { 1, 0.6, 0.2 }, altColor = { 1, 0.85, 0.4 } },
})
do
    -- Flame tongues climb up out of the ground, the middle ones first and
    -- tallest; hotter cores inside; the crest stands dark in front of them.
    local pieces = ns.Skins.warlord.critPieces
    for i = -3, 3 do
        local h = 62 - math.abs(i) * 9
        pieces[#pieces + 1] = { tex = "flame", size = { 30, h }, x = i * 21, y = -24 + h / 2, reveal = "up", move = 0.2,
                                delay = math.abs(i) * 0.03, life = 1.25, color = { 1, 0.4, 0.08 }, alpha = 0.9 }
    end
    for i = -1, 1 do
        local h = 40 - math.abs(i) * 8
        pieces[#pieces + 1] = { tex = "flame", size = { 18, h }, x = i * 26, y = -24 + h / 2, reveal = "up", move = 0.2,
                                delay = 0.06, life = 1.2, color = { 1, 0.85, 0.35 }, alpha = 0.85 }
    end
    pieces[#pieces + 1] = crestPiece(HORDE_CREST, "spikes", { size = 54, y = 34, delay = 0.1, snap = 1.4, snapTime = 0.12 })
end

add("highwarlord", {
    group = "pvp", faction = "Horde", rank = 14,
    name = "High Warlord", tagline = "Horde, Rank 14: every hit burns inside a spiked iron ring. Crits beat the war drum three times, split the ground, roar HIGH WARLORD, and erupt in fire and skulls.",
    font = F.skurri, size = 32, outline = "THICKOUTLINE",
    color = { 1, 0.2, 0.12 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = {
        { x = 2, y = -2, color = { 0.5, 0.05, 0.02, 1 } },
        { x = 4, y = -4, color = { 0.2, 0.02, 0, 1 } },
        { x = 6, y = -6, color = { 0.05, 0, 0, 1 } },
    },
    motion = "drop", motionArgs = { height = 55, fall = 0.12, squash = 0.35, sinkAt = 0.5, sink = 10 },
    dur = 1.4, critDur = 2.4, critScale = 1.8, pop = 0, shake = 9,
    drum = { count = 3, gap = 0.14, amp = 0.3 },
    decor = { tex = "spikes", size = 70, color = { 0.6, 0.06, 0.04 }, alpha = 0.35, blend = "BLEND", spin = -0.4 },
    critReplacesDecor = true,
    critDecor = { tex = "spikes", size = 120, color = { 0.8, 0.08, 0.05 }, alpha = 0.8, blend = "BLEND", spin = 0.6, snap = 0.3, snapTime = 0.1 },
    critDecor2 = crest(HORDE_CREST, "spikes", 90, 1),
    ring = { size = 110, color = { 1, 0.35, 0.15 }, grow = 1.8, alpha = 1 },
    critTitle = { text = "HIGH WARLORD", y = 54, size = 18, font = F.skurri, pop = 1.5,
                  colors = { { 1, 0.15, 0.1 }, { 1, 0.7, 0.2 }, { 1, 1, 1 } }, shadowColor = { 0.15, 0, 0 } },
    particles = { tex = "flame", count = 2, critCount = 18, size = { 10, 20 }, aspect = 0.5, speed = { 60, 170 },
                  dir = { 50, 130 }, gravity = 40, life = { 0.5, 1.0 }, orient = true,
                  color = { 1, 0.4, 0.08 }, altColor = { 1, 0.8, 0.25 } },
    particles2 = { tex = "skull", count = 0, critCount = 4, size = { 18, 26 }, speed = { 90, 160 }, dir = { 30, 150 },
                   gravity = -320, life = { 0.8, 1.3 }, color = { 0.95, 0.9, 0.8 }, blend = "BLEND", spin = 5 },
    world = { WorldTextScale = 1.3, WorldTextGravity = 2 },
})

---------------------------------------------------------------------------
-- Battlegrounds and duels
---------------------------------------------------------------------------
add("flagrunner", {
    group = "pvp", faction = "Warsong Gulch",
    name = "Flag Runner", tagline = "Warsong Gulch: numbers sprint in with a speed trail; crits plant the flag.",
    font = F.friz, size = 24, outline = "OUTLINE",
    color = { 0.55, 0.85, 0.35 }, physColor = { 0.94, 0.96, 0.86 }, spellColor = { 0.55, 0.85, 0.35 },
    layers = {
        { x = 8, y = 0, color = { 0.7, 0.9, 0.5, 0.3 }, trail = true },
        { x = 16, y = 0, color = { 0.7, 0.9, 0.5, 0.12 }, trail = true },
    },
    motion = "dash", motionArgs = { arrive = true, dist = 80, time = 0.22, rise = 18 },
    dur = 1.05, critDur = 1.35, critScale = 1.55, pop = 0,
    critDecor = { tex = "flag", size = 70, x = -4, y = 12, color = { 0.85, 0.25, 0.2 }, alpha = 1, blend = "BLEND", snap = 0.1, snapTime = 0.1 },
    particles = { tex = "slash", count = 1, critCount = 5, size = { 6, 10 }, aspect = 6, speed = { 100, 180 },
                  dir = { -10, 10 }, gravity = 0, life = { 0.2, 0.35 }, color = { 0.9, 0.95, 0.8 }, mirror = true },
    critDecor2 = { tex = "burst", size = 100, color = { 1, 0.35, 0.25 }, alpha = 0.4, spin = 0.5 },
})

add("fivebanners", {
    group = "pvp", faction = "Arathi Basin",
    name = "Five Banners", tagline = "Arathi Basin: numbers climb in stamped steps around the five nodes; crits light them all.",
    font = F.morpheus, size = 24, outline = "OUTLINE",
    color = { 1, 0.78, 0.3 }, physColor = { 0.95, 0.9, 0.75 }, spellColor = { 1, 0.75, 0.25 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.2, 0.02, 1 } } },
    motion = "march", motionArgs = { stepTime = 0.12, steps = 4, px = 8, pulse = 0.08, drift = 20 },
    dur = 1.25, critDur = 1.55, critScale = 1.5, pop = 0.2,
    decor = { tex = "nodes", size = 64, color = { 1, 0.8, 0.3 }, alpha = 0.35, spin = 0.5 },
    critReplacesDecor = true,
    critDecor = { tex = "nodes", size = 110, color = { 1, 0.85, 0.35 }, alpha = 0.95, spin = 1.0, snap = 0.4, snapTime = 0.12 },
    critDecor2 = { tex = "burst", size = 120, color = { 1, 0.8, 0.3 }, alpha = 0.5, spin = 0.4 },
    particles = { tex = "spark", count = 0, critCount = 5, size = { 3, 6 }, speed = { 30, 70 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.4, 0.8 }, color = { 1, 0.85, 0.4 } },
})

add("wintersiege", {
    group = "pvp", faction = "Alterac Valley",
    name = "Winter Siege", tagline = "Alterac Valley: frosty numbers slam in from big; crits blast horn shockwaves and snow.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 0.6, 0.85, 1 }, physColor = { 0.92, 0.96, 1 }, spellColor = { 0.45, 0.75, 1 },
    layers = { { x = 2, y = -2, color = { 0.08, 0.18, 0.35, 1 } } },
    motion = "slam", motionArgs = { from = 2.2, time = 0.14, drift = -26 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0, shake = 3,
    ring = { size = 70, color = { 0.85, 0.95, 1 }, grow = 2.2, alpha = 0.9 },
    critDecor = { tex = "ring", size = 50, color = { 0.6, 0.85, 1 }, alpha = 0.8, grow = 2.0, delay = 0.1 },
    particles = { tex = "snowflake", count = 2, critCount = 14, size = { 7, 13 }, speed = { 20, 90 }, dir = { 0, 360 },
                  gravity = -60, life = { 0.7, 1.3 }, color = { 0.92, 0.97, 1 }, spin = 3 },
    world = { WorldTextScale = 1.15 },
})

add("duelist", {
    group = "pvp", faction = "Duels",
    name = "Duelist", tagline = "Duels: gold numbers feint, then strike; crits flash crossed blades and kick up arena sand.",
    font = F.morpheus, size = 24, outline = "OUTLINE",
    color = { 1, 0.82, 0.3 }, physColor = { 1, 0.95, 0.82 }, spellColor = { 1, 0.72, 0.2 },
    layers = { { x = 2, y = -2, color = { 0.25, 0.15, 0, 1 } } },
    motion = "blink", motionArgs = { from = 12, at = 0.06, rise = 26 },
    dur = 1.1, critDur = 1.4, critScale = 1.5, pop = 0, shake = 3,
    critDecor = { tex = "blades", size = 90, color = { 0.92, 0.94, 1 }, alpha = 0.95, snap = 0.1, snapTime = 0.1 },
    particles = { tex = "puff", count = 0, critCount = 6, size = { 14, 24 }, speed = { 30, 70 }, dir = { 200, 340 },
                  gravity = 20, life = { 0.5, 0.9 }, color = { 0.75, 0.65, 0.45 }, blend = "BLEND" },
    critDecor2 = { tex = "burst", size = 110, color = { 1, 0.85, 0.5 }, alpha = 0.45, spin = 0.5 },
})

---------------------------------------------------------------------------
-- Honorable kills
---------------------------------------------------------------------------
add("tally", {
    group = "pvp", faction = "Honorable kills",
    name = "Tally Marks", tagline = "100 honorable kills: every hit scratches a tally above the number.",
    font = F.friz, size = 24, outline = "OUTLINE",
    color = { 0.85, 0.85, 0.75 }, physColor = { 0.95, 0.92, 0.85 }, spellColor = { 0.85, 0.3, 0.25 },
    layers = { { x = 2, y = -2, color = { 0.2, 0.15, 0.1, 1 } } },
    motion = "rise", motionArgs = { speed = 30 },
    dur = 1.15, critDur = 1.45, critScale = 1.5, pop = 0.2,
    decor = { tex = "tally", size = 26, y = 30, color = { 0.9, 0.88, 0.8 }, alpha = 0.55, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "tally", size = 44, y = 34, color = { 1, 0.95, 0.85 }, alpha = 0.95, blend = "BLEND", snap = 1.6, snapTime = 0.1 },
    -- A fresh line scored through the tally, chalk dust falling.
    critPieces = {
        { tex = "slash", size = { 70, 12 }, y = 34, reveal = "right", move = 0.12, delay = 0.12, life = 0.9, color = { 1, 0.9, 0.8 }, alpha = 0.9 },
    },
    particles2 = { tex = "puff", count = 0, critCount = 3, size = { 10, 16 }, speed = { 10, 25 }, dir = { 250, 290 },
                   gravity = -20, life = { 0.5, 0.8 }, origin = { 0, 30 }, spread = { 50, 4 }, delay = 0.14,
                   color = { 0.8, 0.78, 0.72 }, blend = "BLEND" },
    particles = { tex = "pixel", count = 0, critCount = 6, size = { 3, 5 }, speed = { 40, 100 }, dir = { 30, 150 },
                  gravity = -250, life = { 0.4, 0.7 }, color = { 0.9, 0.85, 0.7 }, blend = "BLEND" },
})

add("lionspride", {
    group = "pvp", faction = "Alliance",
    name = "Lion's Pride", tagline = "250 Alliance honorable kills: proud blue-and-gold numbers over the Alliance crest; crits make it roar, shaking as sound waves roll out to both sides.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.3, 0.55, 1 }, physColor = A_PHYS, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.05, 0.12, 0.35, 1 } }, { x = -1, y = 1, color = { 1, 0.85, 0.35, 0.45 } } },
    motion = "rise", motionArgs = { speed = 24 },
    dur = 1.3, critDur = 1.6, critScale = 1.55, pop = 0.3,
    decor = { file = ALLIANCE_CREST, tex = "shield", size = 30, y = 26, color = WHITE, alpha = 0.5, blend = "BLEND" },
    critReplacesDecor = true,
    critPieces = {},   -- the roar, filled in below
    particles = { tex = "spark", count = 0, critCount = 6, size = { 3, 6 }, speed = { 20, 60 }, dir = { 60, 120 },
                  gravity = 20, life = { 0.5, 1.0 }, origin = { 0, 30 }, color = GOLD },
})
do
    -- Three waves each way, a beat apart, rolling outward and widening;
    -- the crest shakes with the roar.
    local pieces = ns.Skins.lionspride.critPieces
    for j = 0, 2 do
        for _, side in ipairs({ -1, 1 }) do
            pieces[#pieces + 1] = { tex = "arc", size = 46, x = side * 104, y = 30, from = { side * 34, 30 },
                                    rot = side * -1.5708, move = 0.42, ease = "linear", grow = 0.9, delay = 0.08 + j * 0.13,
                                    life = 0.45, color = GOLD, alpha = 0.95 }
        end
    end
    pieces[#pieces + 1] = crestPiece(ALLIANCE_CREST, "shield", { size = 64, y = 30, jitter = { 2.5, 0.5 },
                                                                 snap = 1.3, snapTime = 0.1 })
end

add("bloodthunder", {
    group = "pvp", faction = "Horde",
    name = "Blood & Thunder", tagline = "250 Horde honorable kills: numbers pound like a war drum over the Horde crest; crits beat three times, each beat thundering out, and the last one strikes.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 0.9, 0.15, 0.12 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } }, { x = 4, y = -4, color = { 0.05, 0, 0, 1 } } },
    motion = "march", motionArgs = { stepTime = 0.14, steps = 2, px = 6, pulse = 0.14, drift = 14 },
    dur = 1.15, critDur = 1.6, critScale = 1.5, pop = 0, shake = 5, shakeAt = 0.56,
    drum = { count = 3, gap = 0.28, amp = 0.32 },
    decor = { file = HORDE_CREST, tex = "spikes", size = 30, y = 26, color = WHITE, alpha = 0.5, blend = "BLEND" },
    critReplacesDecor = true,
    critPieces = {},   -- the beats, filled in below
    particles = { tex = "pixel", count = 0, critCount = 9, size = { 3, 6 }, speed = { 60, 150 }, dir = { 20, 160 },
                  gravity = -400, life = { 0.4, 0.8 }, delay = { 0, 0.6 }, color = { 0.6, 0.1, 0.05 }, blend = "BLEND" },
})
do
    -- Each drum beat throws shock lines out to both sides; lightning answers
    -- the third.
    local pieces = ns.Skins.bloodthunder.critPieces
    for _, beat in ipairs({ 0, 0.28, 0.56 }) do
        for _, side in ipairs({ -1, 1 }) do
            pieces[#pieces + 1] = { tex = "speedlines", size = { 72, 40 }, x = side * 84, from = { side * 40, 0 },
                                    move = 0.26, delay = beat, life = 0.3, color = { 1, 0.8, 0.5 }, alpha = 0.85 }
        end
    end
    pieces[#pieces + 1] = crestPiece(HORDE_CREST, "spikes", { size = 56, y = 36, snap = 1.35, snapTime = 0.12 })
    pieces[#pieces + 1] = { tex = "bolt", size = { 24, 76 }, y = 40, delay = 0.56, life = 0.28, flicker = true,
                            color = { 1, 0.86, 0.55 } }
end

add("headhunter", {
    group = "pvp", faction = "Honorable kills",
    name = "Headhunter", tagline = "1,000 honorable kills: crits stamp a skull over a red ring and spill blood.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.85, 0.25, 0.2 }, physColor = { 0.95, 0.88, 0.8 }, spellColor = { 0.9, 0.25, 0.2 },
    layers = { { x = 2, y = -2, color = { 0.25, 0.03, 0.02, 1 } } },
    motion = "rise", motionArgs = { speed = 32 },
    dur = 1.2, critDur = 1.5, critScale = 1.55, pop = 0.2, shake = 4,
    critDecor = { tex = "skull", size = 44, y = 30, color = { 0.95, 0.9, 0.8 }, alpha = 0.95, blend = "BLEND", snap = 1.4, snapTime = 0.1 },
    -- A spatter of blood behind the skull as it lands.
    critPieces = {
        { tex = "splat", size = 82, y = 26, delay = 0.04, snap = 0.4, snapTime = 0.1, life = 0.9, color = { 0.55, 0.03, 0.02 }, alpha = 0.85, blend = "BLEND" },
    },
    particles = { tex = "glow", count = 0, critCount = 7, size = { 4, 7 }, speed = { 40, 110 }, dir = { 200, 340 },
                  gravity = -400, life = { 0.4, 0.8 }, color = { 0.7, 0.05, 0.05 }, blend = "BLEND" },
})

add("warmonger", {
    group = "pvp", faction = "Honorable kills",
    name = "Warmonger", tagline = "5,000 honorable kills: every hit smolders; crits blaze in a sunburst of war with skulls rising from the embers.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 1, 0.55, 0.15 }, physColor = { 1, 0.85, 0.6 }, spellColor = { 1, 0.4, 0.1 },
    layers = { { x = 2, y = -2, color = { 0.4, 0.08, 0, 1 } }, { x = 4, y = -4, color = { 0.1, 0, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 30, sway = 3, freq = 10 },
    dur = 1.3, critDur = 1.7, critScale = 1.6, pop = 0.2, shake = 7,
    decor = { tex = "burst", size = 60, color = { 1, 0.45, 0.1 }, alpha = 0.25, spin = 1 },
    critReplacesDecor = true,
    critDecor = { tex = "burst", size = 170, color = { 1, 0.45, 0.1 }, alpha = 0.7, spin = 0.7 },
    particles = { tex = "spark", count = 2, critCount = 16, size = { 3, 7 }, speed = { 40, 140 }, dir = { 50, 130 },
                  gravity = 60, life = { 0.5, 1.0 }, color = { 1, 0.5, 0.1 }, altColor = { 1, 0.85, 0.3 } },
    particles2 = { tex = "skull", count = 0, critCount = 3, size = { 18, 24 }, speed = { 30, 60 }, dir = { 70, 110 },
                   gravity = 0, life = { 0.8, 1.2 }, color = { 0.95, 0.9, 0.8 }, blend = "BLEND" },
})
