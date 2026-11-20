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
local A_PHYS, A_SPELL = { 0.95, 0.93, 0.85 }, { 0.35, 0.6, 1 }   -- Alliance: ivory / royal blue
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
    name = "Sergeant", tagline = "Alliance, Rank 3: blue numbers under a silver chevron; crits stamp three chevrons in a ring of light.",
    font = F.morpheus, size = 24, outline = "OUTLINE",
    color = { 0.45, 0.65, 1 }, physColor = A_PHYS, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.04, 0.1, 0.3, 1 } } },
    motion = "rise", motionArgs = { speed = 36 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.25,
    decor = emblem(ALLIANCE_CREST, "shield", 22, 26),
    critReplacesDecor = true,
    critDecor = crest(ALLIANCE_CREST, "shield", 70),
    critDecor2 = { tex = "burst", size = 110, color = { 0.86, 0.9, 1 }, alpha = 0.45, spin = 0.4 },
    ring = { size = 64, color = { 0.62, 0.76, 1 }, grow = 1.6, alpha = 0.85 },
    particles = { tex = "spark", count = 0, critCount = 8, size = { 3, 6 }, speed = { 40, 100 }, dir = { 30, 150 },
                  gravity = -120, life = { 0.5, 0.9 }, color = { 0.86, 0.9, 1 }, altColor = { 0.5, 0.66, 1 } },
})

add("knight", {
    group = "pvp", faction = "Alliance", rank = 7,
    name = "Knight-Lieutenant", tagline = "Alliance, Rank 7: stately blue-and-gold numbers; crits raise the crest.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.35, 0.6, 1 }, physColor = A_PHYS, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.05, 0.12, 0.35, 1 } } },
    motion = "rise", motionArgs = { speed = 36 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0.25,
    decor = emblem(ALLIANCE_CREST, "shield", 22, 26),
    critReplacesDecor = true,
    critDecor = crest(ALLIANCE_CREST, "shield", 72),
    critDecor2 = { tex = "burst", size = 120, color = GOLD, alpha = 0.5, spin = 0.4 },
    particles = { tex = "spark", count = 0, critCount = 6, size = { 3, 6 }, speed = { 20, 60 }, dir = { 60, 120 },
                  gravity = 20, life = { 0.5, 1.0 }, color = GOLD },
})

add("ltcommander", {
    group = "pvp", faction = "Alliance", rank = 10,
    name = "Lieutenant Commander", tagline = "Alliance, Rank 10: gilded numbers with rank chevrons; crits raise the crest in a ring of light.",
    font = F.morpheus, size = 26, outline = "OUTLINE",
    color = { 0.45, 0.68, 1 }, physColor = A_PHYS, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.05, 0.12, 0.35, 1 } }, { x = -1, y = 1, color = { 1, 0.88, 0.45, 0.6 } } },
    motion = "rise", motionArgs = { speed = 36 },
    dur = 1.35, critDur = 1.7, critScale = 1.55, pop = 0.3,
    decor = emblem(ALLIANCE_CREST, "shield", 24, 27),
    critReplacesDecor = true,
    critDecor = crest(ALLIANCE_CREST, "shield", 80),
    critDecor2 = { tex = "burst", size = 150, color = GOLD, alpha = 0.6, spin = 0.5 },
    ring = { size = 110, color = GOLD, grow = 1.0, alpha = 0.8 },
    particles = { tex = "twinkle", count = 1, critCount = 8, size = { 8, 14 }, speed = { 20, 60 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.1 }, color = GOLD },
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
    ring = { size = 90, color = { 0.86, 0.9, 1 }, grow = 1.8, alpha = 0.9 },
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
    name = "Sergeant", tagline = "Horde, Rank 3: red numbers under an iron chevron; crits hammer three chevrons down with sparks.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.95, 0.3, 0.2 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 36, fall = 0.1, squash = 0.3, sinkAt = 0.4, sink = 10 },
    dur = 1.15, critDur = 1.45, critScale = 1.5, pop = 0, shake = 3,
    decor = emblem(HORDE_CREST, "spikes", 22, 26),
    critReplacesDecor = true,
    critDecor = crest(HORDE_CREST, "spikes", 70),
    critDecor2 = { tex = "burst", size = 100, color = { 0.85, 0.12, 0.06 }, alpha = 0.55, spin = 0.4 },
    particles = { tex = "spark", count = 0, critCount = 10, size = { 3, 6 }, speed = { 60, 140 }, dir = { 20, 160 },
                  gravity = -300, life = { 0.4, 0.8 }, color = { 1, 0.6, 0.2 }, altColor = { 1, 0.35, 0.15 } },
})

add("stoneguard", {
    group = "pvp", faction = "Horde", rank = 7,
    name = "Blood Guard", tagline = "Horde, Rank 7: heavy numbers slam down; crits spike out in an iron ring.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 0.92, 0.2, 0.15 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 45, fall = 0.12, squash = 0.3, sinkAt = 0.35, sink = 12 },
    dur = 1.15, critDur = 1.45, critScale = 1.55, pop = 0, shake = 4,
    decor = emblem(HORDE_CREST, "spikes", 22, 26),
    critReplacesDecor = true,
    critDecor = crest(HORDE_CREST, "spikes", 74),
    critDecor2 = { tex = "spikes", size = 104, color = { 0.75, 0.08, 0.06 }, alpha = 0.75, blend = "BLEND", spin = 0.4, snap = 0.3, snapTime = 0.08 },
    particles = { tex = "pixel", count = 0, critCount = 7, size = { 3, 6 }, speed = { 60, 150 }, dir = { 20, 160 },
                  gravity = -400, life = { 0.4, 0.8 }, color = { 0.45, 0.3, 0.2 }, blend = "BLEND" },
})

add("champion", {
    group = "pvp", faction = "Horde", rank = 10,
    name = "Champion", tagline = "Horde, Rank 10: iron-edged numbers slam with embers; crits crack the ground under the spiked ring.",
    font = F.skurri, size = 31, outline = "THICKOUTLINE",
    color = { 1, 0.3, 0.15 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } }, { x = 4, y = -4, color = { 0.05, 0, 0, 1 } } },
    motion = "drop", motionArgs = { height = 48, fall = 0.12, squash = 0.32, sinkAt = 0.35, sink = 12 },
    dur = 1.2, critDur = 1.55, critScale = 1.6, pop = 0, shake = 6,
    critDecor = { tex = "spikes", size = 120, color = { 0.8, 0.08, 0.06 }, alpha = 0.9, blend = "BLEND", snap = 0.3, snapTime = 0.08, spin = 0.5 },
    decor = emblem(HORDE_CREST, "spikes", 24, 27),
    critReplacesDecor = true,
    critDecor2 = crest(HORDE_CREST, "spikes", 80),
    ring = { size = 100, color = { 1, 0.4, 0.2 }, grow = 1.0, alpha = 0.9 },
    particles = { tex = "spark", count = 1, critCount = 10, size = { 3, 7 }, speed = { 30, 80 }, dir = { 60, 120 },
                  gravity = 70, life = { 0.5, 1.0 }, color = { 1, 0.45, 0.1 } },
})

add("warlord", {
    group = "pvp", faction = "Horde", rank = 13,
    name = "Warlord", tagline = "Horde, Rank 13: iron numbers under a spiked crown; crits slam embers out of a blood-red ring and roar WARLORD.",
    font = F.skurri, size = 31, outline = "THICKOUTLINE",
    color = { 0.95, 0.25, 0.15 }, physColor = { 0.93, 0.88, 0.84 }, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } }, { x = 4, y = -4, color = { 0.05, 0, 0, 1 } } },
    motion = "drop", motionArgs = { height = 46, fall = 0.12, squash = 0.32, sinkAt = 0.4, sink = 10 },
    dur = 1.3, critDur = 1.9, critScale = 1.7, pop = 0, shake = 7,
    decor = emblem(HORDE_CREST, "spikes", 24, 27, 0.9),
    critReplacesDecor = true,
    critDecor = crest(HORDE_CREST, "spikes", 84),
    critDecor2 = { tex = "spikes", size = 100, color = { 0.8, 0.08, 0.05 }, alpha = 0.75, blend = "BLEND", spin = 0.5, snap = 0.3, snapTime = 0.1 },
    ring = { size = 96, color = { 1, 0.35, 0.15 }, grow = 1.8, alpha = 1 },
    critTitle = { text = "WARLORD", y = 52, size = 18, font = F.skurri, pop = 1.45,
                  colors = { { 1, 0.3, 0.15 }, { 1, 0.85, 0.5 }, { 0.85, 0.08, 0.05 } }, shadowColor = { 0.15, 0, 0 } },
    particles = { tex = "flame", count = 1, critCount = 14, size = { 10, 18 }, aspect = 0.5, speed = { 60, 150 }, dir = { 30, 150 },
                  gravity = -60, life = { 0.5, 1.0 }, color = { 1, 0.45, 0.12 }, altColor = { 1, 0.75, 0.3 } },
})

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
})

add("lionspride", {
    group = "pvp", faction = "Alliance",
    name = "Lion's Pride", tagline = "250 Alliance honorable kills: proud blue-and-gold numbers over the Alliance crest; crits raise it high in a golden shockwave.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.3, 0.55, 1 }, physColor = A_PHYS, spellColor = A_SPELL,
    layers = { { x = 2, y = -2, color = { 0.05, 0.12, 0.35, 1 } }, { x = -1, y = 1, color = { 1, 0.85, 0.35, 0.45 } } },
    motion = "rise", motionArgs = { speed = 34 },
    dur = 1.3, critDur = 1.6, critScale = 1.55, pop = 0.3,
    decor = { file = ALLIANCE_CREST, tex = "shield", size = 30, y = 26, color = WHITE, alpha = 0.5, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "burst", size = 120, color = GOLD, alpha = 0.55, spin = 0.5 },
    critDecor2 = { file = ALLIANCE_CREST, tex = "shield", size = 76, color = WHITE, alpha = 1, blend = "BLEND", snap = 1.6, snapTime = 0.12 },
    ring = { size = 70, color = GOLD, grow = 2.0, alpha = 0.9 },
    particles = { tex = "spark", count = 0, critCount = 6, size = { 3, 6 }, speed = { 20, 60 }, dir = { 60, 120 },
                  gravity = 20, life = { 0.5, 1.0 }, color = GOLD },
})

add("bloodthunder", {
    group = "pvp", faction = "Horde",
    name = "Blood & Thunder", tagline = "250 Horde honorable kills: numbers slam down like thunder over the Horde crest; crits stamp it down with a crack of lightning.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 0.9, 0.15, 0.12 }, physColor = H_PHYS, spellColor = H_SPELL,
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.02, 1 } }, { x = 4, y = -4, color = { 0.05, 0, 0, 1 } } },
    motion = "drop", motionArgs = { height = 40, fall = 0.12, squash = 0.3, sinkAt = 0.35, sink = 12 },
    dur = 1.15, critDur = 1.45, critScale = 1.55, pop = 0, shake = 6,
    decor = { file = HORDE_CREST, tex = "spikes", size = 30, y = 26, color = WHITE, alpha = 0.5, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { file = HORDE_CREST, tex = "spikes", size = 80, color = WHITE, alpha = 1, blend = "BLEND", snap = 0.3, snapTime = 0.08 },
    critDecor2 = { tex = "bolt", size = { 26, 100 }, color = { 1, 0.85, 0.5 }, alpha = 1, flicker = true, randomRot = true },
    particles = { tex = "pixel", count = 0, critCount = 8, size = { 3, 6 }, speed = { 60, 150 }, dir = { 20, 160 },
                  gravity = -400, life = { 0.4, 0.8 }, color = { 0.6, 0.1, 0.05 }, blend = "BLEND" },
})

add("headhunter", {
    group = "pvp", faction = "Honorable kills",
    name = "Headhunter", tagline = "1,000 honorable kills: crits stamp a skull over a red ring and spill blood.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.85, 0.25, 0.2 }, physColor = { 0.95, 0.88, 0.8 }, spellColor = { 0.9, 0.25, 0.2 },
    layers = { { x = 2, y = -2, color = { 0.25, 0.03, 0.02, 1 } } },
    motion = "rise", motionArgs = { speed = 32 },
    dur = 1.2, critDur = 1.5, critScale = 1.55, pop = 0.2, shake = 4,
    critDecor = { tex = "skull", size = 44, y = 30, color = { 0.95, 0.9, 0.8 }, alpha = 0.95, blend = "BLEND", snap = 1.4, snapTime = 0.1 },
    ring = { size = 60, color = { 0.9, 0.2, 0.15 }, grow = 1.6, alpha = 0.9 },
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
