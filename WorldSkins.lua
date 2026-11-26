local _, ns = ...

-- World skins: Azeroth itself. The four legendary weapons are drawn from the
-- game's own models (Media/Textures, made by tools/make_textures.js), and
-- their crits show each weapon's real item icon, loaded from the game. Each
-- skin is earned by a feat (Feats.lua) and has its own World tab.

local F = ns.Fonts
local add = ns.AddSkin

local WHITE = { 1, 1, 1 }
local GOLD = { 1, 0.85, 0.4 }
local LEGENDARY = { 1, 0.5, 0 }   -- the game's legendary item color

-- A legendary crit's loot line: the item's own icon in an orange frame,
-- beside the weapon's name in legendary orange.
local function lootIcon(icon, fallback, x, y, delay)
    return {
        { tex = "legendframe", size = 32, x = x, y = y, delay = delay, snap = 1.6, snapTime = 0.14, hold = true, color = LEGENDARY, alpha = 1 },
        { file = "Interface\\Icons\\" .. icon, tex = fallback, size = 25, x = x, y = y, delay = delay, snap = 1.6, snapTime = 0.14,
          hold = true, color = WHITE, alpha = 1, blend = "BLEND" },
    }
end
local function lootTitle(text, x, y, delay)
    return { text = text, x = x, y = y, size = 13, font = F.friz, pop = 0.8, delay = delay,
             colors = { LEGENDARY, { 1, 0.75, 0.3 }, LEGENDARY }, shadowColor = { 0.15, 0.06, 0 } }
end
local function append(list, more)
    for _, d in ipairs(more) do list[#list + 1] = d end
    return list
end
-- Forked lightning from (x1, y1) to (x2, y2): the texture runs bottom to
-- top, so it is turned to the line and set at its middle.
local function arc(x1, y1, x2, y2, delay, color, width)
    local dx, dy = x2 - x1, y2 - y1
    return { tex = "forkbolt", size = { (width or 12) * 2, math.sqrt(dx * dx + dy * dy) * 1.05 }, x = (x1 + x2) / 2, y = (y1 + y2) / 2,
             rot = (math.atan2 or math.atan)(dy, dx) - math.pi / 2, delay = delay, life = 0.32, flicker = true, front = true, color = color, alpha = 1 }
end

---------------------------------------------------------------------------
-- Windseeker: Thunderfury flicks behind each hit; a crit swings the blade
-- up in a whirlwind and its lightning chains from point to point.
---------------------------------------------------------------------------
local STORM = { 0.6, 0.82, 1 }
local windCrit = {
    { tex = "glow", size = { 200, 110 }, life = 1.1, color = { 0.3, 0.5, 1 }, alpha = 0.45 },
    { tex = "whirlwind", size = { 80, 120 }, x = 4, y = 10, snap = 0.3, snapTime = 0.25, flap = { 0.06, 22 }, life = 1.2, color = { 0.75, 0.88, 1 }, alpha = 0.5 },
    { tex = "thunderfury", size = { 184, 46 }, x = -78, y = -40, pivot = { -50, 0 }, rot = 0.26, fromRot = -0.8, move = 0.2, hold = true,
      color = WHITE, alpha = 1, blend = "BLEND" },
    arc(-6, 8, -62, 36, 0.24, STORM), arc(-62, 36, 64, 44, 0.32, STORM, 14), arc(64, 44, 58, -36, 0.4, STORM),
}
for i, pt in ipairs({ { -62, 36 }, { 64, 44 }, { 58, -36 } }) do
    windCrit[#windCrit + 1] = { tex = "twinkle", size = 22, x = pt[1], y = pt[2], delay = 0.24 + i * 0.08, snap = 2, snapTime = 0.1,
                                life = 0.35, front = true, color = WHITE, alpha = 1 }
end
append(windCrit, lootIcon("INV_Sword_39", "icon_thunderfury", -52, 54, 0.3))
add("windseeker", {
    group = "world", listNote = "Legendary",
    name = "Windseeker", tagline = "Thunderfury flicks behind every hit; crits swing the blade up in a whirlwind as its lightning chains from foe to foe.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 0.84, 0.93, 1 }, physColor = { 0.93, 0.97, 1 }, spellColor = { 0.5, 0.78, 1 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.1, 0.32, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.2, critDur = 1.95, critScale = 1.5, pop = 0.15, shake = 4, shakeAt = 0.2,
    hitPieces = {
        { tex = "thunderfury", size = { 104, 26 }, x = -44, y = -16, pivot = { -28, 0 }, rot = 0.3, fromRot = -0.45, move = 0.12,
          life = 0.5, color = WHITE, alpha = 1, blend = "BLEND" },
        arc(38, 14, 56, -6, 0.08, STORM, 8),
    },
    critPieces = windCrit,
    critTitle = lootTitle("Thunderfury", 14, 54, 0.3),
    glowColor = { 0.4, 0.6, 1 },
    particles = { tex = "spark", count = 1, critCount = 14, size = { 4, 8 }, aspect = 0.4, speed = { 60, 150 }, dir = { 0, 360 },
                  delay = 0.24, gravity = 0, life = { 0.25, 0.5 }, color = STORM, orient = true },
    particles2 = { tex = "speedlines", count = 0, critCount = 4, size = { 26, 34 }, speed = { 60, 100 }, dir = { 160, 200 },
                   spread = { 40, 60 }, gravity = 0, life = { 0.4, 0.6 }, color = { 0.8, 0.9, 1 }, drag = 0, shrink = 0 },
})

---------------------------------------------------------------------------
-- Hand of Ragnaros: embers on every hit; a crit brings Sulfuras down and
-- the ground splits in fire.
---------------------------------------------------------------------------
local MAGMA = { 1, 0.45, 0.08 }
local ragCrit = {
    { tex = "sulfuras", size = { 152, 76 }, y = 6, rot = -math.pi / 2, fromRot = -1.05, from = { 26, 150 }, ease = "in", move = 0.2,
      hold = true, color = WHITE, alpha = 1, blend = "BLEND" },
    { tex = "glow", size = { 210, 110 }, y = -40, delay = 0.2, life = 0.8, color = { 1, 0.35, 0.05 }, alpha = 0.45 },
    { tex = "crack", size = 140, y = -58, delay = 0.2, snap = 0.3, snapTime = 0.1, life = 1.3, color = MAGMA, alpha = 1 },
    { tex = "ring", size = 80, y = -58, grow = 1.8, delay = 0.2, life = 0.5, color = { 1, 0.7, 0.3 }, alpha = 0.9 },
    { tex = "flame", size = { 34, 76 }, x = -56, y = -28, rot = 0.3, delay = 0.24, snap = 0.2, snapTime = 0.15, life = 0.7, color = MAGMA, alpha = 0.95 },
    { tex = "flame", size = { 38, 84 }, x = 58, y = -26, rot = -0.3, delay = 0.27, snap = 0.2, snapTime = 0.15, life = 0.7, color = MAGMA, alpha = 0.95 },
}
append(ragCrit, lootIcon("INV_Hammer_Unique_Sulfuras", "icon_sulfuras", -46, 56, 0.34))
add("handofragnaros", {
    group = "world", listNote = "Legendary",
    name = "Hand of Ragnaros", tagline = "Embers rise off every hit; crits bring Sulfuras crashing down and the ground splits in fire.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.74, 0.3 }, physColor = { 1, 0.86, 0.6 }, spellColor = { 1, 0.5, 0.12 },
    layers = { { x = 2, y = -2, color = { 0.42, 0.05, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 18 },
    dur = 1.2, critDur = 1.95, critScale = 1.5, pop = 0.1, shake = 9, shakeAt = 0.2,
    hitPieces = {
        { tex = "crack", size = 36, y = -18, snap = 0.5, snapTime = 0.1, life = 0.5, color = MAGMA, alpha = 0.9 },
    },
    critPieces = ragCrit,
    critTitle = lootTitle("Sulfuras", 10, 56, 0.34),
    glowColor = MAGMA,
    particles = { tex = "spark", count = 3, critCount = 18, size = { 4, 8 }, speed = { 50, 160 }, dir = { 40, 140 },
                  origin = { 0, -50 }, delay = { 0.2, 0.3 }, gravity = -260, life = { 0.4, 0.8 }, color = { 1, 0.62, 0.15 }, altColor = { 1, 0.9, 0.4 } },
    particles2 = { tex = "puff", count = 0, critCount = 8, size = { 16, 26 }, speed = { 20, 50 }, dir = { 60, 120 },
                   origin = { 0, -56 }, spread = { 80, 8 }, delay = 0.25, gravity = 10, life = { 0.7, 1.1 }, color = { 0.22, 0.12, 0.08 }, blend = "BLEND", drag = 1 },
})

---------------------------------------------------------------------------
-- Ashbringer: ash drifts down every hit; a crit drives the blade down in a
-- column of light and spreads wings of radiance.
---------------------------------------------------------------------------
local HOLY = { 1, 0.86, 0.45 }
local ashCrit = {
    { tex = "beam", size = { 56, 230 }, y = 40, snap = 0.3, snapTime = 0.2, life = 1.1, color = HOLY, alpha = 0.55 },
    { tex = "wingleft", size = { 90, 90 }, x = -50, y = 30, delay = 0.2, snap = 0.2, snapTime = 0.3, life = 1.25, color = HOLY, alpha = 0.5 },
    { tex = "wingright", size = { 90, 90 }, x = 50, y = 30, delay = 0.2, snap = 0.2, snapTime = 0.3, life = 1.25, color = HOLY, alpha = 0.5 },
    { tex = "ashbringer", size = { 152, 38 }, y = 12, rot = -math.pi / 2, from = { 0, 170 }, ease = "in", move = 0.2, hold = true,
      color = WHITE, alpha = 1, blend = "BLEND" },
    { tex = "radial", size = 150, y = -40, delay = 0.2, snap = 0.5, snapTime = 0.12, life = 0.45, color = HOLY, alpha = 0.45 },
}
append(ashCrit, lootIcon("INV_Sword_48", "icon_ashbringer", -54, 58, 0.32))
add("ashbringer", {
    group = "world", listNote = "Legendary",
    name = "Ashbringer", tagline = "Ash drifts down past every hit; crits drive the Ashbringer down in a column of light and spread wings of radiance.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.95, 0.8 }, physColor = { 1, 0.98, 0.92 }, spellColor = { 1, 0.82, 0.38 },
    layers = { { x = 2, y = -2, color = { 0.4, 0.24, 0.02, 1 } } },
    motion = "rise", motionArgs = { speed = 18 },
    dur = 1.25, critDur = 1.95, critScale = 1.5, pop = 0.15, shake = 5, shakeAt = 0.2,
    hitPieces = {
        { tex = "twinkle", size = 16, x = 34, y = 12, delay = 0.05, snap = 2, snapTime = 0.1, life = 0.3, color = HOLY, alpha = 1 },
    },
    critPieces = ashCrit,
    critTitle = lootTitle("Ashbringer", 16, 58, 0.32),
    glowColor = HOLY,
    -- Ash: grey flakes drifting down.
    particles = { tex = "glow", count = 3, critCount = 18, size = { 3, 6 }, speed = { 5, 20 }, dir = { 250, 290 },
                  origin = { 0, 60 }, spread = { 140, 20 }, gravity = -20, life = { 0.8, 1.4 }, color = { 0.62, 0.6, 0.58 }, blend = "BLEND", sway = true, drag = 0, shrink = 0 },
    particles2 = { tex = "twinkle", count = 0, critCount = 10, size = { 7, 12 }, speed = { 40, 100 }, dir = { 20, 160 },
                   delay = 0.2, gravity = 0, life = { 0.4, 0.8 }, color = HOLY },
})

---------------------------------------------------------------------------
-- Atiesh: arcane motes and a raven feather on every hit; a crit raises the
-- greatstaff, a portal opens at its head and a raven bursts out.
---------------------------------------------------------------------------
local ARCANE = { 0.72, 0.5, 1 }
local RAVEN = { 0.12, 0.08, 0.16 }
-- The staff sweeps up about its grip; its head ends up near (62, 35).
local atieshCrit = {
    { tex = "puff", size = { 160, 70 }, x = 0, y = -4, rot = 0.55, life = 1.2, color = { 0.85, 0.82, 0.95 }, alpha = 0.25, blend = "BLEND" },
    { tex = "atiesh", size = { 176, 88 }, x = -56, y = -38, pivot = { -52, 25 }, rot = 0.5, fromRot = -0.25, move = 0.25, hold = true,
      color = WHITE, alpha = 1, blend = "BLEND" },
    { tex = "rune", size = 70, x = 54, y = 28, delay = 0.28, snap = 0.1, snapTime = 0.3, spin = 2, life = 1.2, color = ARCANE, alpha = 0.9 },
    { tex = "ring", size = 50, x = 54, y = 28, delay = 0.3, grow = 1.4, life = 0.5, color = { 0.85, 0.7, 1 }, alpha = 0.8 },
    { tex = "raven", size = { 70, 35 }, x = 112, y = 84, from = { 54, 28 }, ease = "linear", move = 1.0, delay = 0.42, flap = { 0.2, 16 },
      life = 1.1, color = RAVEN, alpha = 1, blend = "BLEND" },
}
append(atieshCrit, lootIcon("INV_Staff_Medivh", "icon_atiesh", -66, 60, 0.36))
add("atiesh", {
    group = "world", listNote = "Legendary",
    name = "Atiesh", tagline = "Arcane motes and a raven's feather drift off every hit; crits raise the greatstaff, open a portal at its head and loose a raven.",
    font = F.morpheus, size = 26, outline = "THICKOUTLINE",
    color = { 0.9, 0.82, 1 }, physColor = { 0.96, 0.93, 1 }, spellColor = { 0.72, 0.5, 1 },
    layers = { { x = 2, y = -2, color = { 0.18, 0.05, 0.35, 1 } } },
    motion = "rise", motionArgs = { speed = 18, sway = 3, freq = 3 },
    dur = 1.25, critDur = 1.95, critScale = 1.5, pop = 0.15,
    hitPieces = {
        { tex = "feather", size = { 10, 22 }, x = 40, y = 20, from = { 30, 4 }, rot = 0.6, move = 0.6, flap = { 0.4, 6 }, life = 0.85,
          color = RAVEN, alpha = 1, blend = "BLEND" },
    },
    critPieces = atieshCrit,
    critTitle = lootTitle("Atiesh", -16, 60, 0.36),
    glowColor = ARCANE,
    particles = { tex = "twinkle", count = 2, critCount = 12, size = { 6, 11 }, speed = { 20, 70 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 1.0 }, color = ARCANE, altColor = { 0.9, 0.85, 1 } },
    particles2 = { tex = "feather", count = 0, critCount = 6, size = { 9, 16 }, speed = { 20, 50 }, dir = { 200, 340 },
                   origin = { 60, 34 }, delay = 0.5, gravity = -40, life = { 0.8, 1.2 }, color = RAVEN, blend = "BLEND", sway = true, spin = 2, drag = 0, shrink = 0 },
})

---------------------------------------------------------------------------
-- Corrupted Blood: a tainted drop falls from every hit; a crit spreads the
-- plague: drops leap to everything nearby and take hold.
---------------------------------------------------------------------------
local BLOOD, TAINT = { 0.7, 0.03, 0.06 }, { 0.45, 0.95, 0.25 }
local bloodCycle = {}
for i = 1, 24 do bloodCycle[i] = (i % 4 == 0) and { 0.6, 1, 0.35 } or { 1, 0.16, 0.2 } end
local bloodCrit = { { tex = "glow", size = { 150, 90 }, pulse = { 0.15, 9 }, life = 1.3, color = { 0.4, 0.9, 0.2 }, alpha = 0.3 } }
for i, pt in ipairs({ { -58, 30 }, { 60, 34 }, { -54, -30 }, { 58, -28 } }) do
    local d = 0.12 + i * 0.07
    bloodCrit[#bloodCrit + 1] = { tex = "drop", size = { 9, 13 }, x = pt[1], y = pt[2], from = { 0, 4 }, move = 0.3, delay = d, life = 0.34,
                                  color = BLOOD, alpha = 1, blend = "BLEND" }
    bloodCrit[#bloodCrit + 1] = { tex = "splat", size = 36, x = pt[1], y = pt[2], rot = i * 1.7, delay = d + 0.3, snap = 0.3, snapTime = 0.1,
                                  hold = true, color = BLOOD, alpha = 0.95, blend = "BLEND" }
    bloodCrit[#bloodCrit + 1] = { tex = "glow", size = 44, x = pt[1], y = pt[2], delay = d + 0.3, pulse = { 0.3, 10 }, hold = true,
                                  color = TAINT, alpha = 0.6 }
end
add("corruptedblood", {
    group = "world", listNote = "Zul'Gurub",
    name = "Corrupted Blood", tagline = "A tainted drop falls from every hit; crits spread the plague, leaping to everything nearby and taking hold.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.2, 0.24 }, physColor = { 1, 0.6, 0.6 }, spellColor = { 0.6, 1, 0.38 },
    layers = { { x = 2, y = -2, color = { 0.18, 0, 0.02, 1 } } },
    motion = "rise", motionArgs = { speed = 18 },
    dur = 1.2, critDur = 1.85, critScale = 1.5, pop = 0.15,
    critCycle = bloodCycle, cyclePeriod = 0.12,
    hitPieces = {
        { tex = "drop", size = { 8, 12 }, x = 30, y = -10, from = { 30, 4 }, ease = "in", move = 0.45, life = 0.6, color = BLOOD, alpha = 1, blend = "BLEND" },
        { tex = "twinkle", size = 10, x = 30, y = -6, delay = 0.2, life = 0.3, color = TAINT, alpha = 1 },
    },
    critPieces = bloodCrit,
    glowColor = { 1, 0.1, 0.12 }, glowAlpha = 0.35,
    particles = { tex = "drop", count = 0, critCount = 10, size = { 4, 7 }, aspect = 0.6, speed = { 40, 110 }, dir = { 20, 160 },
                  gravity = -260, life = { 0.4, 0.8 }, color = BLOOD, blend = "BLEND" },
})

---------------------------------------------------------------------------
-- Chromatic: numbers shimmer through the five flights; crits fan out five
-- tongues of dragonfire, one of each.
---------------------------------------------------------------------------
local FLIGHTS = { { 1, 0.28, 0.16 }, { 0.62, 0.32, 0.85 }, { 0.32, 1, 0.42 }, { 0.32, 0.62, 1 }, { 1, 0.78, 0.25 } }
local chromaCrit = { { tex = "glow", size = { 190, 110 }, y = 10, life = 0.9, color = { 1, 0.6, 0.4 }, alpha = 0.35 } }
for i, c in ipairs(FLIGHTS) do
    chromaCrit[#chromaCrit + 1] = { tex = "flame", size = { 36, 96 }, y = -12, pivot = { 0, -44 }, rot = (3 - i) * 0.45, fromRot = 0,
                                    move = 0.18, delay = (i - 1) * 0.04, snap = 0.2, snapTime = 0.18, life = 0.85, color = c, alpha = 0.95 }
end
add("chromatic", {
    group = "world", listNote = "Blackwing Lair",
    name = "Chromatic", tagline = "Numbers shimmer through the five dragonflights; crits fan out five tongues of dragonfire, one of each.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.82, 0.62 }, physColor = { 1, 0.92, 0.82 }, spellColor = { 0.72, 0.5, 1 },
    layers = { { x = 2, y = -2, color = { 0.12, 0.04, 0.12, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.15, critDur = 1.75, critScale = 1.5, pop = 0.2, shake = 4,
    critCycle = FLIGHTS, cyclePeriod = 0.1,
    hitPieces = {
        { tex = "flame", size = { 14, 34 }, x = -40, y = -6, pivot = { 0, -15 }, rot = 0.4, life = 0.5, snap = 0.3, snapTime = 0.1, color = FLIGHTS[1], alpha = 0.9 },
        { tex = "flame", size = { 14, 36 }, x = -40, y = -6, pivot = { 0, -15 }, rot = 0, delay = 0.04, life = 0.5, snap = 0.3, snapTime = 0.1, color = FLIGHTS[3], alpha = 0.9 },
        { tex = "flame", size = { 14, 34 }, x = -40, y = -6, pivot = { 0, -15 }, rot = -0.4, delay = 0.08, life = 0.5, snap = 0.3, snapTime = 0.1, color = FLIGHTS[4], alpha = 0.9 },
    },
    critPieces = chromaCrit,
    particles = { tex = "dragonscale", count = 2, critCount = 16, size = { 7, 12 }, speed = { 40, 130 }, dir = { 0, 360 },
                  gravity = -120, life = { 0.5, 0.9 }, randomColor = true, spin = 4 },
})

---------------------------------------------------------------------------
-- Emerald Dream: drowsy Z's drift off every hit; on a crit the dreaming
-- dragon's great eye opens in the mist.
---------------------------------------------------------------------------
local DREAM = { 0.5, 1, 0.62 }
add("emeralddream", {
    group = "world", listNote = "The Dream",
    name = "Emerald Dream", tagline = "Sleepy Z's drift off every hit; on crits a dreaming dragon's great eye opens in the emerald mist.",
    font = F.morpheus, size = 26, outline = "THICKOUTLINE",
    color = { 0.78, 1, 0.84 }, physColor = { 0.9, 1, 0.92 }, spellColor = { 0.45, 0.95, 0.6 },
    layers = { { x = 2, y = -2, color = { 0.02, 0.22, 0.08, 1 } } },
    motion = "rise", motionArgs = { speed = 14, sway = 4, freq = 2.5 },
    dur = 1.3, critDur = 1.95, critScale = 1.5, pop = 0.1,
    hitPieces = {
        { tex = "zee", size = 12, x = 46, y = 26, from = { 30, 4 }, move = 0.7, ease = "linear", life = 0.9, color = DREAM, alpha = 0.9 },
        { tex = "zee", size = 9, x = 56, y = 40, from = { 40, 14 }, move = 0.7, ease = "linear", delay = 0.2, life = 0.8, color = DREAM, alpha = 0.8 },
    },
    critPieces = {
        { tex = "glow", size = { 220, 130 }, y = 24, life = 1.5, color = { 0.2, 0.8, 0.4 }, alpha = 0.45 },
        { tex = "dragoneye", size = { 120, 60 }, y = 48, fromSize = { 120, 1 }, move = 0.35, delay = 0.25, hold = true,
          after = { at = 1.4, move = 0.2, size = { 120, 1 } }, color = WHITE, alpha = 1, blend = "BLEND" },
        { tex = "zee", size = 16, x = 58, y = 18, from = { 36, -6 }, move = 0.9, ease = "linear", delay = 0.1, life = 1.0, color = DREAM, alpha = 0.9 },
        { tex = "zee", size = 12, x = 72, y = 34, from = { 50, 6 }, move = 0.9, ease = "linear", delay = 0.3, life = 0.9, color = DREAM, alpha = 0.8 },
    },
    glowColor = DREAM,
    particles = { tex = "glow", count = 1, critCount = 10, size = { 40, 70 }, speed = { 10, 30 }, dir = { 0, 360 },
                  spread = { 140, 40 }, gravity = 0, life = { 0.9, 1.4 }, color = { 0.3, 0.85, 0.45 }, drag = 1, shrink = 0 },
})

---------------------------------------------------------------------------
-- Titan Disc: a carved disc turns behind each hit; a crit lights its ring
-- of glyphs one by one and sends a beam of light up.
---------------------------------------------------------------------------
local STONE, RUNE = { 0.68, 0.7, 0.76 }, { 0.45, 0.85, 1 }
local discCrit = {
    { tex = "titandisc", size = 122, snap = 0.4, snapTime = 0.18, hold = true, color = STONE, alpha = 0.9, blend = "BLEND" },
}
for i = 0, 11 do
    discCrit[#discCrit + 1] = { tex = "glyphseg", size = 122, rot = -i * math.pi / 6, delay = 0.15 + i * 0.04, hold = true, color = RUNE, alpha = 1 }
end
discCrit[#discCrit + 1] = { tex = "beam", size = { 40, 200 }, y = 90, delay = 0.65, snap = 0.3, snapTime = 0.12, life = 0.7, color = RUNE, alpha = 0.7 }
discCrit[#discCrit + 1] = { tex = "ring", size = 122, grow = 0.4, delay = 0.65, life = 0.4, color = RUNE, alpha = 0.9 }
add("titandisc", {
    group = "world", listNote = "Uldaman",
    name = "Titan Disc", tagline = "A carved titan disc turns behind each hit; crits light its ring of glyphs one by one and send a beam of light up.",
    font = F.friz, size = 25, outline = "THICKOUTLINE",
    color = { 0.86, 0.95, 1 }, physColor = { 0.93, 0.97, 1 }, spellColor = { 0.5, 0.85, 1 },
    layers = { { x = 2, y = -2, color = { 0.05, 0.12, 0.26, 1 } } },
    motion = "rise", motionArgs = { speed = 14 },
    dur = 1.2, critDur = 1.8, critScale = 1.5, pop = 0.1,
    hitPieces = {
        { tex = "titandisc", size = 44, x = -46, spin = 2, snap = 0.5, snapTime = 0.12, life = 0.7, color = STONE, alpha = 1, blend = "BLEND" },
    },
    critPieces = discCrit,
    glowColor = RUNE, glowAlpha = 0.25,
    particles = { tex = "twinkle", count = 0, critCount = 10, size = { 6, 10 }, speed = { 30, 80 }, dir = { 60, 120 },
                  delay = 0.65, gravity = 0, life = { 0.5, 0.9 }, color = RUNE },
})

---------------------------------------------------------------------------
-- Bonecraft: a bony hand claws at each hit; a crit raises a skeletal hand
-- out of the ground round the number, in necromantic green fire.
---------------------------------------------------------------------------
local BONE, NECRO = { 0.92, 0.88, 0.76 }, { 0.4, 1, 0.45 }
add("bonecraft", {
    group = "world", listNote = "Scholomance",
    name = "Bonecraft", tagline = "A bony hand claws at each hit; crits raise a great skeletal hand round the number in necromantic green fire.",
    font = F.morpheus, size = 26, outline = "THICKOUTLINE",
    color = { 0.94, 0.92, 0.82 }, physColor = { 0.97, 0.96, 0.9 }, spellColor = { 0.55, 1, 0.55 },
    layers = { { x = 2, y = -2, color = { 0.08, 0.12, 0.04, 1 } } },
    motion = "rise", motionArgs = { speed = 16 },
    dur = 1.2, critDur = 1.85, critScale = 1.5, pop = 0.1,
    hitPieces = {
        { tex = "bonehand", size = { 18, 36 }, x = 40, y = -10, reveal = "up", move = 0.2, life = 0.6, color = BONE, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "flame", size = { 40, 80 }, x = -40, y = -24, delay = 0.2, life = 0.9, flicker = true, color = NECRO, alpha = 0.7 },
        { tex = "flame", size = { 44, 90 }, x = 42, y = -22, delay = 0.25, life = 0.9, flicker = true, color = NECRO, alpha = 0.7 },
        { tex = "bonehand", size = { 76, 152 }, y = -14, reveal = "up", move = 0.3, hold = true, after = { at = 1.25, move = 0.4, y = -120, ease = "in" },
          color = BONE, alpha = 1, blend = "BLEND" },
        { tex = "glow", size = { 120, 70 }, y = -56, life = 0.8, color = NECRO, alpha = 0.45 },
    },
    glowColor = NECRO, glowAlpha = 0.25,
    particles = { tex = "shard", count = 0, critCount = 10, size = { 5, 9 }, speed = { 60, 120 }, dir = { 30, 150 },
                  origin = { 0, -50 }, gravity = -200, life = { 0.4, 0.7 }, color = BONE, blend = "BLEND", spin = 6 },
    particles2 = { tex = "glow", count = 0, critCount = 10, size = { 6, 10 }, speed = { 20, 50 }, dir = { 70, 110 },
                   spread = { 80, 10 }, origin = { 0, -40 }, delay = 0.25, gravity = 30, life = { 0.6, 1.0 }, color = NECRO },
})

---------------------------------------------------------------------------
-- Kodo Stampede: hoofprints thud in under each hit; a crit sends a kodo
-- thundering across, leaving a trail of prints and dust.
---------------------------------------------------------------------------
local DUST, HIDE = { 0.78, 0.62, 0.42 }, { 0.5, 0.36, 0.22 }
local kodoCrit = {
    { tex = "kodo", size = { 124, 62 }, x = 210, y = -6, from = { -210, -6 }, ease = "linear", move = 0.75, life = 0.8, color = HIDE, alpha = 1, blend = "BLEND" },
}
for i = 0, 8 do
    kodoCrit[#kodoCrit + 1] = { tex = "hoofprint", size = 11, x = -88 + i * 22, y = -42 + (i % 2) * 7, rot = -math.pi / 2, delay = 0.12 + i * 0.07,
                                hold = true, color = { 0.66, 0.5, 0.32 }, alpha = 0.95, blend = "BLEND" }
end
add("kodostampede", {
    group = "world", listNote = "Desolace",
    name = "Kodo Stampede", tagline = "Hoofprints thud in under each hit; crits send a kodo thundering across in a trail of prints and dust.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.86, 0.62 }, physColor = { 1, 0.93, 0.8 }, spellColor = { 1, 0.66, 0.32 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.15, 0.02, 1 } } },
    motion = "rise", motionArgs = { speed = 16 },
    dur = 1.15, critDur = 1.8, critScale = 1.5, pop = 0.15,
    drum = { count = 6, gap = 0.11, amp = 0.06 },
    hitPieces = {
        { tex = "hoofprint", size = 10, x = -12, y = -22, rot = -math.pi / 2, life = 0.7, color = { 0.66, 0.5, 0.32 }, alpha = 0.9, blend = "BLEND" },
        { tex = "hoofprint", size = 10, x = 10, y = -16, rot = -math.pi / 2, delay = 0.1, life = 0.6, color = { 0.66, 0.5, 0.32 }, alpha = 0.9, blend = "BLEND" },
    },
    critPieces = kodoCrit,
    glowColor = DUST, glowAlpha = 0.2,
    particles = { tex = "puff", count = 1, critCount = 14, size = { 14, 26 }, speed = { 15, 40 }, dir = { 60, 120 },
                  origin = { 0, -40 }, spread = { 170, 6 }, delay = { 0.1, 0.7 }, gravity = 10, life = { 0.6, 1.0 }, color = DUST, blend = "BLEND", drag = 1 },
})

---------------------------------------------------------------------------
-- No Take Candle: a kobold's candle bobs by each hit; crits plant one on
-- the number's head and its flame flares up.
---------------------------------------------------------------------------
local WAX, CANDLELIGHT = { 1, 1, 1 }, { 1, 0.78, 0.3 }
add("notakecandle", {
    group = "world", listNote = "Kobolds",
    name = "No Take Candle", tagline = "A kobold's candle bobs by each hit; crits plant one on the number's head and its flame flares up.",
    font = F.block, size = 23, outline = "OUTLINE",
    color = { 1, 0.88, 0.55 }, physColor = { 1, 0.94, 0.78 }, spellColor = { 1, 0.66, 0.28 },
    layers = { { x = 2, y = -2, color = { 0.32, 0.16, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 16 },
    dur = 1.15, critDur = 1.8, critScale = 1.5, pop = 0.1,
    hitPieces = {
        { tex = "candle", size = { 11, 22 }, x = 40, y = 6, from = { 40, -6 }, move = 0.2, wobble = { 0.2, 26, 6 }, life = 0.7, color = WAX, alpha = 1, blend = "BLEND" },
        { tex = "flame", size = { 8, 14 }, x = 40, y = 23, from = { 40, 11 }, move = 0.2, flicker = true, life = 0.7, color = CANDLELIGHT, alpha = 1 },
    },
    critPieces = {
        { tex = "candle", size = { 20, 40 }, y = 30, from = { 0, 70 }, ease = "in", move = 0.15, wobble = { 0.18, 30, 5 }, hold = true,
          color = WAX, alpha = 1, blend = "BLEND" },
        { tex = "flame", size = { 14, 24 }, y = 61, from = { 0, 101 }, ease = "in", move = 0.15, grow = 1.4, pulse = { 0.12, 30 }, hold = true,
          color = CANDLELIGHT, alpha = 1 },
        { tex = "glow", size = 70, y = 60, delay = 0.25, grow = 1.2, life = 1.2, color = CANDLELIGHT, alpha = 0.7 },
    },
    critTitle = { text = "YOU NO TAKE CANDLE!", y = -32, size = 11, font = F.block, pop = 1.2, delay = 0.3,
                  colors = { CANDLELIGHT, WHITE, { 1, 0.5, 0.2 } }, shadowColor = { 0.25, 0.1, 0 } },
    glowColor = CANDLELIGHT,
    particles = { tex = "drop", count = 0, critCount = 4, size = { 4, 6 }, aspect = 0.6, speed = { 5, 20 }, dir = { 250, 290 },
                  origin = { 0, 34 }, spread = { 16, 4 }, delay = 0.3, gravity = -120, life = { 0.5, 0.8 }, color = { 1, 0.96, 0.8 }, blend = "BLEND", drag = 0, shrink = 0 },
})

---------------------------------------------------------------------------
-- Polymorph: hits sparkle pink; a crit turns into a sheep for a moment,
-- then pops back.
---------------------------------------------------------------------------
local POLY = { 1, 0.55, 0.9 }
add("polymorph", {
    group = "world", listNote = "Critters",
    name = "Polymorph", tagline = "Hits sparkle with arcane pink; crits turn into a bleating sheep for a moment, then pop back.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.82, 1 }, physColor = { 1, 0.92, 1 }, spellColor = { 0.95, 0.6, 1 },
    layers = { { x = 2, y = -2, color = { 0.32, 0.04, 0.36, 1 } } },
    motion = "rise", motionArgs = { speed = 14 },
    dur = 1.15, critDur = 2.0, critScale = 1.5, pop = 0, noSpring = true,
    critScaleKeys = { { 0, 1 }, { 0.22, 1 }, { 0.28, 0.02 }, { 1.2, 0.02 }, { 1.3, 1.25 }, { 1.42, 1 } },
    hitPieces = {
        { tex = "twinkle", size = 14, x = 34, y = 12, delay = 0.04, snap = 2, snapTime = 0.1, life = 0.3, color = POLY, alpha = 1 },
    },
    critPieces = {
        { tex = "ring", size = 50, steady = true, delay = 0.22, grow = 1.6, life = 0.4, color = POLY, alpha = 0.9 },
        { tex = "glow", size = 90, steady = true, delay = 0.22, life = 0.35, color = POLY, alpha = 0.8 },
        { tex = "sheep", size = 66, steady = true, delay = 0.27, snap = 0.3, snapTime = 0.1, life = 0.98,
          rock = { at = 0.1, n = 4, gap = 0.2, amp = 0.18 }, pulse = { 0.06, 31 }, color = WHITE, alpha = 1, blend = "BLEND" },
        { tex = "ring", size = 50, steady = true, delay = 1.2, grow = 1.6, life = 0.4, color = POLY, alpha = 0.9 },
    },
    critTitle = { text = "Baa!", x = 36, y = 34, size = 12, font = F.friz, pop = 1.2, delay = 0.5,
                  colors = { WHITE, POLY }, shadowColor = { 0.2, 0, 0.2 } },
    glowColor = POLY, noGlow = true,
    particles = { tex = "twinkle", count = 1, critCount = 14, size = { 6, 11 }, speed = { 40, 100 }, dir = { 0, 360 },
                  delay = { 0.22, 1.2 }, gravity = 0, life = { 0.3, 0.6 }, color = POLY, altColor = WHITE },
})

---------------------------------------------------------------------------
-- Raptor Pack: claws rake every hit; a crit sends a raptor leaping through
-- as three rakes tear across.
---------------------------------------------------------------------------
local CLAW = { 1, 0.9, 0.78 }
add("raptorpack", {
    group = "world", listNote = "Stranglethorn",
    name = "Raptor Pack", tagline = "Claws rake every hit; crits send a raptor leaping through as three rakes tear across.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.86, 0.64 }, physColor = { 1, 0.93, 0.8 }, spellColor = { 1, 0.55, 0.32 },
    layers = { { x = 2, y = -2, color = { 0.32, 0.06, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 18 },
    dur = 1.1, critDur = 1.7, critScale = 1.5, pop = 0.15, shake = 5, shakeAt = 0.2,
    hitPieces = {
        { tex = "claws", size = 50, x = 8, rot = -0.3, snap = 0.5, snapTime = 0.08, life = 0.34, front = true, color = CLAW, alpha = 1 },
    },
    critPieces = {
        { tex = "raptor", size = { 112, 56 }, x = 170, y = 50, from = { -170, -40 }, ease = "linear", move = 0.42, life = 0.48,
          color = { 0.2, 0.12, 0.08 }, alpha = 1, blend = "BLEND" },
        { tex = "claws", size = 76, x = -14, rot = -0.4, delay = 0.16, snap = 0.5, snapTime = 0.08, life = 0.4, front = true, color = CLAW, alpha = 1 },
        { tex = "claws", size = 76, x = 12, y = 6, rot = 0.5, delay = 0.26, snap = 0.5, snapTime = 0.08, life = 0.4, front = true, color = CLAW, alpha = 1 },
        { tex = "claws", size = 84, x = 0, y = -4, rot = -0.1, delay = 0.36, snap = 0.5, snapTime = 0.08, life = 0.45, front = true, color = { 1, 0.6, 0.4 }, alpha = 1 },
    },
    glowColor = { 1, 0.5, 0.2 }, glowAlpha = 0.25,
    particles = { tex = "feather", count = 0, critCount = 8, size = { 8, 14 }, speed = { 40, 100 }, dir = { 0, 360 },
                  delay = 0.2, gravity = -60, life = { 0.6, 1.0 }, color = { 1, 0.5, 0.2 }, altColor = { 0.3, 0.6, 0.9 }, blend = "BLEND", spin = 3, sway = true },
})

---------------------------------------------------------------------------
-- Wisp: little wisps circle each hit; a crit gathers a ring of them, then
-- they detonate in white light.
---------------------------------------------------------------------------
local WISP = { 0.78, 0.92, 1 }
local function orbit(n, r, size, life, spin, list, delay)
    for i = 1, n do
        list[#list + 1] = { tex = "wisp", size = size, pivot = { 0, -r }, rot = (i - 1) * math.pi * 2 / n, spin = spin, delay = delay or 0,
                            life = life, color = WISP, alpha = 1 }
    end
    return list
end
local wispCrit = orbit(6, 40, 34, 0.7, 4, {}, 0)
wispCrit[#wispCrit + 1] = { tex = "glow", size = 160, delay = 0.62, life = 0.35, color = WHITE, alpha = 0.9 }
wispCrit[#wispCrit + 1] = { tex = "ring", size = 60, delay = 0.62, grow = 2.2, life = 0.5, color = WISP, alpha = 1 }
add("wisp", {
    group = "world", listNote = "Night Elf",
    name = "Wisp", tagline = "Little wisps circle each hit; crits gather a ring of them, then they detonate in white light.",
    font = F.morpheus, size = 26, outline = "THICKOUTLINE",
    color = { 0.86, 0.95, 1 }, physColor = { 0.94, 0.98, 1 }, spellColor = { 0.6, 0.85, 1 },
    layers = { { x = 2, y = -2, color = { 0.05, 0.14, 0.3, 1 } } },
    motion = "rise", motionArgs = { speed = 16 },
    dur = 1.2, critDur = 1.75, critScale = 1.5, pop = 0.1, shake = 4, shakeAt = 0.62,
    hitPieces = orbit(2, 28, 24, 0.75, 5, {}, 0),
    critPieces = wispCrit,
    glowColor = WISP, glowAlpha = 0.25,
    particles = { tex = "twinkle", count = 0, critCount = 16, size = { 6, 11 }, speed = { 70, 150 }, dir = { 0, 360 },
                  delay = 0.62, gravity = 0, life = { 0.4, 0.8 }, color = WHITE, altColor = WISP },
})

---------------------------------------------------------------------------
-- Green Hills: a page flutters off each hit; a crit throws open the old
-- adventure book and its pages scatter.
---------------------------------------------------------------------------
local PAPER = { 1, 1, 1 }
add("greenhills", {
    group = "world", listNote = "Stranglethorn",
    name = "Green Hills", tagline = "A torn page flutters off each hit; crits throw open an old adventure book and its pages scatter.",
    font = F.morpheus, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.95, 0.8 }, physColor = { 1, 0.97, 0.9 }, spellColor = { 0.62, 0.92, 0.52 },
    layers = { { x = 2, y = -2, color = { 0.25, 0.15, 0.04, 1 } } },
    motion = "rise", motionArgs = { speed = 16 },
    dur = 1.2, critDur = 1.85, critScale = 1.5, pop = 0.1,
    hitPieces = {
        { tex = "page", size = { 12, 24 }, x = 46, y = 22, from = { 20, 0 }, move = 0.6, spin = 3, life = 0.8, color = PAPER, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "glow", size = { 170, 90 }, y = -20, life = 1.0, color = { 1, 0.85, 0.5 }, alpha = 0.35 },
        { tex = "openbook", size = { 116, 58 }, y = -34, fromSize = { 30, 58 }, move = 0.2, hold = true, color = PAPER, alpha = 1, blend = "BLEND" },
    },
    glowColor = { 1, 0.88, 0.6 }, glowAlpha = 0.2,
    particles = { tex = "page", count = 0, critCount = 12, size = { 24, 36 }, aspect = 0.5, speed = { 80, 150 }, dir = { 40, 140 },
                  origin = { 0, -26 }, delay = 0.18, gravity = -110, life = { 0.8, 1.2 }, color = PAPER, blend = "BLEND", spin = 4, sway = true, shrink = 0 },
})

---------------------------------------------------------------------------
-- Midsummer Blaze: flames lick each hit; a crit lights a bonfire under it
-- and three torches cartwheel overhead.
---------------------------------------------------------------------------
local FIRE = { 1, 0.55, 0.12 }
local function torch(x0, x1, peakY, delay)
    return { tex = "torch", size = { 16, 32 }, x = (x0 + x1) / 2, y = peakY, from = { x0, -24 }, move = 0.3, delay = delay, spin = 12,
             life = 0.8, after = { at = 0.3, move = 0.3, x = x1, y = -24, ease = "in" }, color = WHITE, alpha = 1, blend = "BLEND" }
end
add("midsummerblaze", {
    group = "world", listNote = "Midsummer",
    name = "Midsummer Blaze", tagline = "Flames lick every hit; crits light a bonfire beneath it and three torches cartwheel overhead.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.82, 0.42 }, physColor = { 1, 0.9, 0.66 }, spellColor = { 1, 0.56, 0.16 },
    layers = { { x = 2, y = -2, color = { 0.42, 0.08, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 16 },
    dur = 1.2, critDur = 1.85, critScale = 1.5, pop = 0.15,
    hitPieces = {
        { tex = "flame", size = { 20, 40 }, x = -38, y = -2, pulse = { 0.12, 26 }, snap = 0.3, snapTime = 0.1, life = 0.6, color = FIRE, alpha = 1 },
        { tex = "flame", size = { 12, 26 }, x = -38, y = -6, pulse = { 0.15, 33 }, life = 0.55, color = { 1, 0.9, 0.5 }, alpha = 1 },
    },
    critPieces = {
        { tex = "glow", size = { 170, 100 }, y = -36, life = 1.4, color = { 1, 0.45, 0.1 }, alpha = 0.55 },
        { tex = "flame", size = { 44, 78 }, x = -16, y = -12, flicker = true, life = 1.3, color = FIRE, alpha = 0.85 },
        { tex = "flame", size = { 52, 92 }, x = 10, y = -8, flicker = true, life = 1.3, color = { 1, 0.75, 0.25 }, alpha = 0.85 },
        { tex = "bonfire", size = { 112, 56 }, y = -44, snap = 0.6, snapTime = 0.12, hold = true, color = WHITE, alpha = 1, blend = "BLEND" },
        torch(-58, 58, 66, 0.1), torch(58, -58, 74, 0.25), torch(-40, 46, 58, 0.4),
    },
    glowColor = FIRE,
    particles = { tex = "spark", count = 2, critCount = 14, size = { 3, 6 }, speed = { 40, 110 }, dir = { 70, 110 },
                  origin = { 0, -30 }, spread = { 50, 6 }, gravity = 40, life = { 0.5, 0.9 }, color = FIRE, altColor = { 1, 0.9, 0.4 } },
    particles2 = { tex = "petal", count = 0, critCount = 8, size = { 7, 11 }, speed = { 30, 80 }, dir = { 30, 150 },
                   delay = 0.2, gravity = -60, life = { 0.7, 1.1 }, color = { 1, 0.6, 0.2 }, altColor = { 1, 0.85, 0.3 }, spin = 4, sway = true },
})

---------------------------------------------------------------------------
-- Lunar Lanterns: a red lantern rises past each hit; crits send lanterns
-- up and rockets burst in red and gold.
---------------------------------------------------------------------------
local LUNAR_RED, LUNAR_GOLD = { 1, 0.25, 0.2 }, { 1, 0.85, 0.3 }
add("lunarlanterns", {
    group = "world", listNote = "Lunar Festival",
    name = "Lunar Lanterns", tagline = "A red lantern rises past each hit; crits float lanterns up as rockets burst in red and gold.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.88, 0.5 }, physColor = { 1, 0.94, 0.74 }, spellColor = { 1, 0.42, 0.32 },
    layers = { { x = 2, y = -2, color = { 0.45, 0.03, 0.03, 1 } } },
    motion = "rise", motionArgs = { speed = 18 },
    dur = 1.25, critDur = 1.9, critScale = 1.5, pop = 0.15,
    hitPieces = {
        { tex = "lantern", size = { 16, 32 }, x = 40, y = 30, from = { 40, -16 }, ease = "linear", move = 0.9, life = 0.9, color = WHITE, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "streak", size = { 70, 8 }, x = -46, y = 56, rot = math.pi / 2, from = { -46, -30 }, move = 0.3, life = 0.35, color = LUNAR_GOLD, alpha = 1 },
        { tex = "streak", size = { 70, 8 }, x = 48, y = 64, rot = math.pi / 2, from = { 48, -30 }, move = 0.3, delay = 0.1, life = 0.35, color = LUNAR_RED, alpha = 1 },
        { tex = "firework", size = 76, x = -46, y = 62, delay = 0.3, snap = 0.3, snapTime = 0.2, grow = 0.3, life = 0.7, color = LUNAR_RED, alpha = 1 },
        { tex = "firework", size = 84, x = 48, y = 70, delay = 0.4, snap = 0.3, snapTime = 0.2, grow = 0.3, life = 0.7, color = LUNAR_GOLD, alpha = 1 },
        { tex = "firework", size = 100, x = 0, y = 44, delay = 0.55, snap = 0.3, snapTime = 0.2, grow = 0.3, life = 0.8, color = { 1, 0.55, 0.3 }, alpha = 1 },
    },
    glowColor = LUNAR_RED, glowAlpha = 0.3,
    particles = { tex = "lantern", count = 0, critCount = 6, size = { 28, 40 }, aspect = 0.5, speed = { 30, 50 }, dir = { 80, 100 },
                  spread = { 160, 20 }, origin = { 0, -30 }, delay = { 0, 0.3 }, gravity = 10, life = { 1.2, 1.6 }, color = WHITE, blend = "BLEND", sway = true, drag = 0, shrink = 0 },
    particles2 = { tex = "spark", count = 0, critCount = 12, size = { 3, 6 }, speed = { 40, 90 }, dir = { 200, 340 },
                   origin = { 0, 60 }, spread = { 100, 20 }, delay = 0.4, gravity = -80, life = { 0.5, 0.9 }, color = LUNAR_GOLD, altColor = LUNAR_RED },
})

---------------------------------------------------------------------------
-- High Striker: the Darkmoon Faire's test of strength. Hits thump the pad;
-- a crit sends the puck all the way up to ring the bell.
---------------------------------------------------------------------------
local FAIRE = { 0.8, 0.5, 1 }
add("highstriker", {
    group = "world", listNote = "Darkmoon Faire",
    name = "High Striker", tagline = "The Darkmoon Faire's strength test: hits thump the pad; crits send the puck all the way up to ring the bell.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 1, 0.9, 0.6 }, physColor = { 1, 0.95, 0.8 }, spellColor = { 0.86, 0.62, 1 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.05, 0.4, 1 } } },
    motion = "rise", motionArgs = { speed = 10 },
    dur = 1.15, critDur = 1.85, critScale = 1.45, pop = 0.1,
    hitPieces = {
        { tex = "impact", size = 30, x = 0, y = -22, snap = 0.5, snapTime = 0.08, life = 0.25, color = GOLD, alpha = 0.8 },
    },
    critPieces = {
        { tex = "highstriker", size = { 24, 96 }, x = 58, y = 8, hold = true, color = WHITE, alpha = 1, blend = "BLEND" },
        { tex = "impact", size = 40, x = 58, y = -42, snap = 0.5, snapTime = 0.08, life = 0.3, color = GOLD, alpha = 0.9 },
        { tex = "pixel", size = { 13, 6 }, x = 58, y = 45, from = { 58, -34 }, move = 0.38, delay = 0.04, hold = true,
          after = { at = 0.75, move = 0.4, y = -34, ease = "in" }, color = { 1, 0.25, 0.2 }, alpha = 1, blend = "BLEND" },
        { tex = "glow", size = 50, x = 58, y = 53, delay = 0.42, pulse = { 0.3, 30 }, life = 0.6, color = GOLD, alpha = 1 },
        { tex = "ring", size = 30, x = 58, y = 53, delay = 0.42, grow = 1.8, life = 0.4, color = GOLD, alpha = 0.9 },
    },
    critTitle = { text = "DING!", x = 58, y = 74, size = 13, font = F.skurri, pop = 1.4, delay = 0.42,
                  colors = { GOLD, WHITE, FAIRE }, shadowColor = { 0.25, 0.05, 0.3 } },
    glowColor = FAIRE, glowAlpha = 0.2,
    particles = { tex = "star", count = 0, critCount = 9, size = { 6, 10 }, speed = { 50, 110 }, dir = { 20, 160 },
                  origin = { 58, 53 }, delay = 0.42, gravity = -150, life = { 0.5, 0.8 }, color = GOLD, altColor = FAIRE, spin = 5 },
})

---------------------------------------------------------------------------
-- Egg Hunt: a painted egg rolls by each hit; a crit is hidden in an egg
-- that wobbles, cracks open and lets out a chick.
---------------------------------------------------------------------------
add("egghunt", {
    group = "world", listNote = "Noblegarden",
    name = "Egg Hunt", tagline = "A painted egg rolls by each hit; crits hide in an egg that wobbles, cracks open and lets out a chick.",
    font = F.block, size = 23, outline = "OUTLINE",
    color = { 1, 0.86, 0.95 }, physColor = { 1, 0.94, 0.98 }, spellColor = { 0.62, 0.88, 1 },
    layers = { { x = 2, y = -2, color = { 0.4, 0.1, 0.3, 1 } } },
    motion = "rise", motionArgs = { speed = 14 },
    dur = 1.15, critDur = 1.9, critScale = 1.45, pop = 0, noSpring = true, noFlash = true,
    critScaleKeys = { { 0, 0.02 }, { 0.62, 0.02 }, { 0.72, 1.2 }, { 0.82, 1 } },
    hitPieces = {
        { tex = "egg", size = 20, x = 40, y = -8, from = { 56, -8 }, move = 0.3, spin = -6, life = 0.7, color = WHITE, alpha = 1, blend = "BLEND" },
    },
    critPieces = {
        { tex = "eggbottom", size = 64, y = -10, steady = true, snap = 0.6, snapTime = 0.12, rock = { at = 0.12, n = 3, gap = 0.14, amp = 0.25 },
          pivot = { 0, -28 }, hold = true, color = WHITE, alpha = 1, blend = "BLEND" },
        { tex = "eggtop", size = 64, y = -10, steady = true, snap = 0.6, snapTime = 0.12, rock = { at = 0.12, n = 3, gap = 0.14, amp = 0.25 },
          pivot = { 0, -28 }, hold = true, after = { at = 0.6, move = 0.35, x = 34, y = 40, rot = -1.6 }, color = WHITE, alpha = 1, blend = "BLEND" },
        { tex = "chick", size = 30, x = 0, y = -12, steady = true, from = { 0, -24 }, move = 0.18, delay = 0.62, hold = true, color = WHITE, alpha = 1, blend = "BLEND" },
    },
    critTitle = { text = "peep!", x = 34, y = 14, size = 11, font = F.block, pop = 1, delay = 0.7,
                  colors = { { 1, 0.9, 0.35 }, WHITE }, shadowColor = { 0.4, 0.25, 0 } },
    glowColor = { 1, 0.7, 0.9 }, noGlow = true,
    particles = { tex = "star", count = 0, critCount = 10, size = { 6, 10 }, speed = { 50, 110 }, dir = { 30, 150 },
                  delay = 0.62, gravity = -160, life = { 0.5, 0.9 }, randomColor = true, spin = 4 },
})

---------------------------------------------------------------------------
-- Spirit Healer: hits leave a ghostly trail; a crit starts grey as a ghost,
-- then a winged spirit rises and raises it in golden light.
---------------------------------------------------------------------------
local GHOST, REZ = { 0.72, 0.8, 0.92 }, { 1, 0.92, 0.6 }
local spiritCycle = {}
for i = 1, 24 do spiritCycle[i] = i <= 5 and GHOST or REZ end
add("spirithealer", {
    group = "world", listNote = "Graveyards",
    name = "Spirit Healer", tagline = "Hits leave a ghostly trail; crits start grey as a ghost, then a winged spirit rises and raises them in golden light.",
    font = F.morpheus, size = 26, outline = "THICKOUTLINE",
    color = { 0.82, 0.9, 1 }, physColor = { 0.92, 0.95, 1 }, spellColor = { 0.62, 0.78, 1 },
    layers = { { x = 2, y = -2, color = { 0.1, 0.14, 0.3, 1 } } },
    motion = "rise", motionArgs = { speed = 16, sway = 3, freq = 3 },
    fadeIn = 0.2,
    dur = 1.25, critDur = 1.95, critScale = 1.5, pop = 0, noSpring = true,
    critCycle = spiritCycle, cyclePeriod = 0.1,
    critScaleKeys = { { 0, 0.9 }, { 0.48, 0.9 }, { 0.56, 1.25 }, { 0.7, 1 } },
    hitPieces = {
        { tex = "wisp", size = 22, x = -34, y = -8, rot = 2.4, life = 0.7, color = GHOST, alpha = 0.6 },
    },
    critPieces = {
        { tex = "angel", size = 140, y = 30, from = { 0, 0 }, move = 0.5, snap = 0.9, snapTime = 0.3, life = 1.5, color = GHOST, alpha = 0.55 },
        { tex = "beam", size = { 56, 230 }, y = 50, delay = 0.48, snap = 0.3, snapTime = 0.15, life = 0.9, color = REZ, alpha = 0.4 },
        { tex = "angel", size = 140, y = 30, delay = 0.48, life = 1.0, color = REZ, alpha = 0.4 },
        { tex = "radial", size = 150, delay = 0.48, snap = 0.5, snapTime = 0.12, life = 0.45, color = REZ, alpha = 0.35 },
    },
    glowColor = REZ, glowAlpha = 0.3,
    particles = { tex = "twinkle", count = 1, critCount = 14, size = { 6, 11 }, speed = { 30, 80 }, dir = { 60, 120 },
                  delay = 0.48, gravity = 20, life = { 0.5, 1.0 }, color = REZ, altColor = WHITE },
})

---------------------------------------------------------------------------
-- Spell effects: each skin's own magic, layered in. under = drawn beneath
-- the skin's pieces (ground effects), over = on top of them.
---------------------------------------------------------------------------
local function spells(id, part, under, over)
    local s = ns.Skins[id]
    local list = s[part] or {}
    local out = {}
    for _, d in ipairs(under or {}) do out[#out + 1] = d end
    for _, d in ipairs(list) do out[#out + 1] = d end
    for _, d in ipairs(over or {}) do out[#out + 1] = d end
    s[part] = out
end
local function missile(fromX, fromY, toX, toY, delay, color)
    local dx, dy = toX - fromX, toY - fromY
    local rot = (math.atan2 or math.atan)(dy, dx)
    return {
        { tex = "streak", size = { 40, 8 }, x = toX - dx * 0.25, y = toY - dy * 0.25, from = { fromX, fromY }, rot = rot, ease = "in", move = 0.16,
          delay = delay, life = 0.2, color = color, alpha = 1 },
        { tex = "arcorb", size = 16, x = toX, y = toY, from = { fromX, fromY }, ease = "in", move = 0.16, delay = delay, life = 0.2, color = WHITE, alpha = 1 },
        { tex = "holystar", size = 34, x = toX, y = toY, delay = delay + 0.16, snap = 0.3, snapTime = 0.08, life = 0.28, color = color, alpha = 1 },
    }
end
local function concat(...)
    local out = {}
    for _, t in ipairs({ ... }) do for _, d in ipairs(t) do out[#out + 1] = d end end
    return out
end

-- Thunderfury's proc: the struck foe frozen in a ring of frost, wind
-- tearing across the ground.
spells("windseeker", "critPieces", {
    { tex = "groundring", size = { 190, 70 }, y = -52, delay = 0.18, snap = 0.3, snapTime = 0.3, grow = 0.5, life = 0.7, color = { 0.7, 0.85, 1 }, alpha = 0.7 },
}, {
    { tex = "novaring", size = 56, x = 58, y = -36, delay = 0.42, snap = 0.3, snapTime = 0.12, life = 0.7, color = { 0.65, 0.85, 1 }, alpha = 0.9 },
    { tex = "holystar", size = 60, x = 58, y = -36, delay = 0.42, snap = 0.3, snapTime = 0.1, life = 0.3, color = WHITE, alpha = 1 },
    { tex = "holystar", size = 44, x = -62, y = 36, delay = 0.26, snap = 0.3, snapTime = 0.1, life = 0.25, color = STORM, alpha = 1 },
    { tex = "holystar", size = 44, x = 64, y = 44, delay = 0.34, snap = 0.3, snapTime = 0.1, life = 0.25, color = STORM, alpha = 1 },
})
spells("windseeker", "hitPieces", nil, {
    { tex = "holystar", size = 22, x = 48, y = 2, delay = 0.1, snap = 0.3, snapTime = 0.08, life = 0.22, color = STORM, alpha = 1 },
})

-- Sulfuras: fire erupts round the impact, rocks fly, smoke rolls.
spells("handofragnaros", "critPieces", {
    { tex = "groundring", size = { 200, 74 }, y = -60, delay = 0.2, snap = 0.3, snapTime = 0.25, grow = 0.6, life = 0.8, color = { 1, 0.55, 0.15 }, alpha = 0.9 },
}, {
    { tex = "flamecolor", size = { 34, 80 }, x = -64, y = -30, rot = 0.25, delay = 0.22, snap = 0.15, snapTime = 0.18, life = 0.75, color = WHITE, alpha = 1 },
    { tex = "flamecolor2", size = { 30, 70 }, x = -30, y = -36, rot = 0.1, delay = 0.26, snap = 0.15, snapTime = 0.18, life = 0.7, color = WHITE, alpha = 1 },
    { tex = "flamecolor", size = { 30, 72 }, x = 32, y = -36, rot = -0.1, delay = 0.24, snap = 0.15, snapTime = 0.18, life = 0.7, color = WHITE, alpha = 1 },
    { tex = "flamecolor2", size = { 36, 84 }, x = 66, y = -30, rot = -0.25, delay = 0.21, snap = 0.15, snapTime = 0.18, life = 0.78, color = WHITE, alpha = 1 },
    { tex = "holystar", size = 100, y = -56, delay = 0.2, snap = 0.4, snapTime = 0.08, life = 0.22, color = { 1, 0.75, 0.35 }, alpha = 0.75 },
})
ns.Skins.handofragnaros.particles2 = { tex = "rock", count = 0, critCount = 10, size = { 6, 11 }, speed = { 90, 170 }, dir = { 50, 130 },
    origin = { 0, -56 }, delay = 0.2, gravity = -480, life = { 0.5, 0.8 }, color = { 0.45, 0.22, 0.12 }, blend = "BLEND", spin = 7 }
spells("handofragnaros", "hitPieces", nil, {
    { tex = "flamecolor", size = { 12, 28 }, x = 30, y = -12, snap = 0.3, snapTime = 0.1, life = 0.4, color = WHITE, alpha = 1 },
})

-- The Ashbringer: consecrated ground, a holy star where the blade bites.
spells("ashbringer", "critPieces", {
    { tex = "consecrate", size = { 180, 72 }, y = -60, delay = 0.2, snap = 0.3, snapTime = 0.25, life = 1.5, color = HOLY, alpha = 0.85 },
}, {
    { tex = "holystar", size = 130, y = -60, delay = 0.2, snap = 0.3, snapTime = 0.1, life = 0.4, color = { 1, 0.95, 0.75 }, alpha = 1 },
    { tex = "holystar", size = 60, y = 60, delay = 0.35, snap = 0.3, snapTime = 0.1, life = 0.35, color = HOLY, alpha = 0.9 },
})
spells("ashbringer", "hitPieces", nil, {
    { tex = "holystar", size = 26, x = 34, y = 12, delay = 0.05, snap = 0.3, snapTime = 0.08, life = 0.28, color = HOLY, alpha = 1 },
})

-- Atiesh: arcane missiles from the portal, then an arcane explosion.
spells("atiesh", "critPieces", nil, concat(
    missile(54, 28, -30, 8, 0.48, ARCANE), missile(54, 28, 4, -14, 0.58, ARCANE), missile(54, 28, 30, 6, 0.68, ARCANE),
    { { tex = "novaring", size = 60, delay = 0.86, grow = 1, life = 0.4, color = ARCANE, alpha = 0.7 },
      { tex = "holystar", size = 90, delay = 0.86, snap = 0.3, snapTime = 0.1, life = 0.3, color = { 0.85, 0.75, 1 }, alpha = 1 } }))
spells("atiesh", "hitPieces", nil, {
    { tex = "arcorb", size = 12, x = -30, y = 10, from = { -50, 26 }, move = 0.3, life = 0.45, color = ARCANE, alpha = 1 },
})

-- Corrupted Blood: a poison cloud hangs round each infection.
local bloodCloud = {}
for i, pt in ipairs({ { -58, 30 }, { 60, 34 }, { -54, -30 }, { 58, -28 } }) do
    bloodCloud[#bloodCloud + 1] = { tex = "smoke", size = 58, x = pt[1], y = pt[2], delay = 0.4 + i * 0.07, snap = 0.4, snapTime = 0.3, spin = 0.6,
                                    life = 1.1, color = { 0.35, 0.75, 0.2 }, alpha = 0.55 }
end
spells("corruptedblood", "critPieces", { { tex = "smoke", size = 120, spin = -0.4, life = 1.4, color = { 0.3, 0.6, 0.15 }, alpha = 0.4 } }, bloodCloud)

-- Chromatic: sparks of each flight's breath fly out.
local breath = {}
for i, c in ipairs(FLIGHTS) do
    local a = math.pi / 2 + (3 - i) * 0.45
    breath[#breath + 1] = { tex = "arcorb", size = 14, x = math.cos(a) * 92, y = -12 + math.sin(a) * 92, from = { 0, -12 }, move = 0.35,
                            delay = 0.12 + i * 0.04, life = 0.5, color = c, alpha = 1 }
end
spells("chromatic", "critPieces", {
    { tex = "smoke", size = 130, y = 20, delay = 0.15, spin = 0.5, life = 1.0, color = { 0.4, 0.35, 0.4 }, alpha = 0.35, blend = "BLEND" },
}, breath)

-- Emerald Dream: a dream mist rolls through, leaves drift, the eye glints.
spells("emeralddream", "critPieces", {
    { tex = "smoke", size = { 220, 90 }, x = -30, y = -10, from = { -80, -10 }, move = 1.4, ease = "linear", life = 1.6, color = { 0.3, 0.8, 0.45 }, alpha = 0.4 },
    { tex = "smoke", size = { 200, 80 }, x = 40, y = 10, from = { 90, 10 }, move = 1.4, ease = "linear", delay = 0.1, life = 1.5, color = { 0.25, 0.7, 0.4 }, alpha = 0.35 },
}, {
    { tex = "holystar", size = 34, x = 20, y = 58, delay = 0.62, snap = 0.3, snapTime = 0.1, life = 0.35, color = WHITE, alpha = 1 },
})
ns.Skins.emeralddream.particles2 = { tex = "leaf", count = 0, critCount = 8, size = { 8, 13 }, speed = { 20, 60 }, dir = { 160, 200 },
    origin = { 90, 20 }, spread = { 20, 80 }, delay = { 0.1, 0.6 }, gravity = -20, life = { 1.0, 1.4 }, color = { 0.4, 0.9, 0.45 }, blend = "BLEND", spin = 3, sway = true, drag = 0, shrink = 0 }

-- Titan Disc: lightning crackles between the glyphs; debris falls.
local discArcs = {}
for i, a in ipairs({ 0.3, 2.4, 4.4 }) do
    local x1, y1 = math.cos(a) * 44, math.sin(a) * 44
    local x2, y2 = math.cos(a + 0.9) * 44, math.sin(a + 0.9) * 44
    discArcs[#discArcs + 1] = arc(x1, y1, x2, y2, 0.35 + i * 0.1, RUNE, 18)
end
spells("titandisc", "critPieces", {
    { tex = "groundring", size = { 190, 70 }, y = -64, delay = 0.65, snap = 0.3, snapTime = 0.2, grow = 0.4, life = 0.6, color = RUNE, alpha = 0.7 },
}, discArcs)
ns.Skins.titandisc.particles2 = { tex = "rock", count = 0, critCount = 8, size = { 5, 9 }, speed = { 30, 80 }, dir = { 230, 310 },
    origin = { 0, 60 }, spread = { 120, 10 }, delay = { 0.1, 0.6 }, gravity = -300, life = { 0.5, 0.9 }, color = STONE, blend = "BLEND", spin = 5 }

-- Bonecraft: a shadow orb churns behind the hand; souls rise.
spells("bonecraft", "critPieces", {
    { tex = "shadoworb", size = 104, y = 10, spin = 1.6, snap = 0.2, snapTime = 0.25, life = 1.3, color = { 0.45, 0.85, 0.5 }, alpha = 0.7, blend = "BLEND" },
}, {
    { tex = "wisp", size = 30, x = -30, y = 40, from = { -20, -20 }, rot = 2.4, move = 0.9, delay = 0.35, life = 0.9, color = NECRO, alpha = 0.9 },
    { tex = "wisp", size = 26, x = 36, y = 46, from = { 24, -16 }, rot = 2.4, move = 0.9, delay = 0.5, life = 0.9, color = NECRO, alpha = 0.9 },
})

-- Kodo Stampede: the ground shakes in rings; rocks bounce.
spells("kodostampede", "critPieces", {
    { tex = "groundring", size = { 170, 60 }, y = -46, delay = 0.15, grow = 0.6, life = 0.5, color = DUST, alpha = 0.9 },
    { tex = "groundring", size = { 170, 60 }, y = -46, delay = 0.45, grow = 0.6, life = 0.5, color = DUST, alpha = 0.8 },
})
ns.Skins.kodostampede.particles2 = { tex = "rock", count = 0, critCount = 8, size = { 5, 9 }, speed = { 60, 120 }, dir = { 60, 120 },
    origin = { 0, -44 }, spread = { 160, 6 }, delay = { 0.15, 0.7 }, gravity = -420, life = { 0.4, 0.6 }, color = { 0.55, 0.42, 0.3 }, blend = "BLEND", spin = 6 }

-- No Take Candle: a real flame, and a curl of smoke off it.
spells("notakecandle", "critPieces", nil, {
    { tex = "flamecolor", size = { 18, 34 }, y = 64, from = { 0, 104 }, ease = "in", move = 0.15, pulse = { 0.1, 26 }, hold = true, color = WHITE, alpha = 1 },
    { tex = "smoke", size = 26, x = 4, y = 96, from = { 0, 70 }, move = 1.2, ease = "linear", delay = 0.4, spin = 1, life = 1.2, color = { 0.6, 0.6, 0.62 }, alpha = 0.5, blend = "BLEND" },
})

-- Polymorph: a burst of arcane sparkle each way.
spells("polymorph", "critPieces", nil, {
    { tex = "holystar", size = 80, steady = true, delay = 0.22, snap = 0.3, snapTime = 0.08, life = 0.3, color = POLY, alpha = 1 },
    { tex = "rezspiral", size = { 60, 110 }, steady = true, y = 10, delay = 0.2, life = 0.5, color = POLY, alpha = 0.8 },
    { tex = "holystar", size = 80, steady = true, delay = 1.2, snap = 0.3, snapTime = 0.08, life = 0.3, color = POLY, alpha = 1 },
})

-- Raptor Pack: the rakes draw blood; the raptor lands in a cloud of dust.
spells("raptorpack", "critPieces", nil, {
    { tex = "splat", size = 30, x = -20, y = 4, rot = 0.6, delay = 0.2, snap = 0.3, snapTime = 0.1, life = 0.8, color = { 0.6, 0.04, 0.04 }, alpha = 0.85, blend = "BLEND" },
    { tex = "splat", size = 24, x = 22, y = -6, rot = 2.1, delay = 0.3, snap = 0.3, snapTime = 0.1, life = 0.8, color = { 0.6, 0.04, 0.04 }, alpha = 0.85, blend = "BLEND" },
    { tex = "groundring", size = { 130, 48 }, x = 120, y = 20, delay = 0.42, grow = 0.5, life = 0.45, color = { 0.8, 0.65, 0.45 }, alpha = 0.8 },
})

-- Wisp: the detonation flashes white, frost-bright.
spells("wisp", "critPieces", nil, {
    { tex = "holystar", size = 140, delay = 0.62, snap = 0.3, snapTime = 0.08, life = 0.35, color = WHITE, alpha = 1 },
    { tex = "novaring", size = 80, delay = 0.64, grow = 1.4, life = 0.45, color = WISP, alpha = 0.9 },
})

-- Green Hills: the book glows; jungle leaves swirl out with the pages.
spells("greenhills", "critPieces", nil, {
    { tex = "holystar", size = 70, y = -30, delay = 0.18, snap = 0.3, snapTime = 0.1, life = 0.4, color = { 1, 0.9, 0.6 }, alpha = 1 },
})
ns.Skins.greenhills.particles2 = { tex = "leaf", count = 0, critCount = 8, size = { 9, 14 }, speed = { 50, 120 }, dir = { 30, 150 },
    origin = { 0, -26 }, delay = 0.2, gravity = -90, life = { 0.8, 1.2 }, color = { 0.35, 0.8, 0.3 }, blend = "BLEND", spin = 4, sway = true }

-- Midsummer: real fire in the bonfire, and a fire nova as it catches.
spells("midsummerblaze", "critPieces", {
    { tex = "groundring", size = { 180, 66 }, y = -44, delay = 0.05, grow = 0.6, life = 0.6, color = { 1, 0.5, 0.1 }, alpha = 0.9 },
}, {
    { tex = "flamecolor", size = { 40, 84 }, x = -14, y = -10, pulse = { 0.08, 22 }, life = 1.35, color = WHITE, alpha = 1 },
    { tex = "flamecolor2", size = { 48, 96 }, x = 12, y = -6, pulse = { 0.08, 27 }, life = 1.35, color = WHITE, alpha = 1 },
    { tex = "smoke", size = 50, x = 4, y = 70, from = { 0, 40 }, move = 1.2, ease = "linear", delay = 0.3, spin = 0.8, life = 1.2, color = { 0.4, 0.38, 0.38 }, alpha = 0.4, blend = "BLEND" },
})

-- Lunar Lanterns: each burst has a bright heart.
spells("lunarlanterns", "critPieces", nil, {
    { tex = "holystar", size = 60, x = -46, y = 62, delay = 0.3, snap = 0.3, snapTime = 0.08, life = 0.3, color = LUNAR_RED, alpha = 1 },
    { tex = "holystar", size = 66, x = 48, y = 70, delay = 0.4, snap = 0.3, snapTime = 0.08, life = 0.3, color = LUNAR_GOLD, alpha = 1 },
    { tex = "holystar", size = 80, x = 0, y = 44, delay = 0.55, snap = 0.3, snapTime = 0.08, life = 0.35, color = { 1, 0.75, 0.5 }, alpha = 1 },
})

-- High Striker: the bell flashes and the Faire throws confetti.
spells("highstriker", "critPieces", nil, {
    { tex = "holystar", size = 70, x = 58, y = 53, delay = 0.42, snap = 0.3, snapTime = 0.08, life = 0.35, color = GOLD, alpha = 1 },
})
ns.Skins.highstriker.particles2 = { tex = "pixel", count = 0, critCount = 16, size = { 3, 5 }, speed = { 60, 140 }, dir = { 30, 150 },
    origin = { 58, 53 }, delay = 0.42, gravity = -200, life = { 0.6, 1.0 }, randomColor = true, blend = "BLEND", spin = 8, sway = true }

-- Egg Hunt: a sparkle as it cracks, and shell bits fly.
spells("egghunt", "critPieces", nil, {
    { tex = "holystar", size = 70, y = 0, steady = true, delay = 0.6, snap = 0.3, snapTime = 0.08, life = 0.3, color = { 1, 0.85, 0.95 }, alpha = 1 },
})
ns.Skins.egghunt.particles2 = { tex = "shard", count = 0, critCount = 8, size = { 5, 8 }, speed = { 60, 120 }, dir = { 30, 150 },
    delay = 0.6, gravity = -260, life = { 0.4, 0.7 }, color = { 0.98, 0.72, 0.86 }, altColor = { 0.6, 0.85, 1 }, blend = "BLEND", spin = 7 }

-- Spirit Healer: the resurrection spirals up in gold.
spells("spirithealer", "critPieces", nil, {
    { tex = "rezspiral", size = { 90, 170 }, y = 20, delay = 0.46, snap = 0.6, snapTime = 0.2, life = 1.0, color = REZ, alpha = 0.6 },
    { tex = "holystar", size = 100, delay = 0.48, snap = 0.3, snapTime = 0.1, life = 0.35, color = REZ, alpha = 0.6 },
})
