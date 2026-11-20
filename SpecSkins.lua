local _, ns = ...

-- Spec variants of the class skins. Each starts as a copy of its class skin
-- (ClassSkins.lua) and overrides what makes the spec its own; false clears an
-- inherited field. tree is the talent tree it belongs to, 1 to 3 from left
-- to right as the talent frame draws them (Forever has one spec per class,
-- with the three classic trees side by side in one talent tree). Unlocked by spending 20 talent points
-- in that tree (Feats.lua); Auto: my class switches to the active spec's
-- variant once it's earned.

local F = ns.Fonts
local add = ns.AddSkin

local function glow(c, a, d)
    d = d or 1.5
    return {
        { x = d, y = d, color = { c[1], c[2], c[3], a } },
        { x = -d, y = -d, color = { c[1], c[2], c[3], a } },
        { x = d, y = -d, color = { c[1], c[2], c[3], a } },
        { x = -d, y = d, color = { c[1], c[2], c[3], a } },
    }
end

local function variant(id, baseId, spec, tree, over)
    local base = ns.Skins[baseId]
    local s = {}
    for k, v in pairs(base) do s[k] = v end
    for k, v in pairs(over) do
        if v == false then s[k] = nil else s[k] = v end
    end
    s.spec, s.tree, s.base = spec, tree, baseId
    s.group, s.class = "class", base.class
    add(id, s)
end

---------------------------------------------------------------------------
-- Warrior (Bloodrage)
---------------------------------------------------------------------------
variant("warrior_arms", "warrior", "Arms", 1, {
    name = "Mortal Strike", tagline = "Arms: heavy numbers slam down; crits carve a deep red wound that bleeds.",
    spellColor = { 0.85, 0.15, 0.1 }, shake = 6,
    critDecor = { tex = "slash", size = { 130, 30 }, rot = -0.5, color = { 0.9, 0.15, 0.1 }, alpha = 1, snap = 0.1, snapTime = 0.08 },
    critDecor2 = { tex = "crack", size = 100, y = -8, color = { 0.5, 0.04, 0.03 }, alpha = 0.85, blend = "BLEND", randomRot = true },
    particles = { tex = "glow", count = 0, critCount = 7, size = { 4, 7 }, speed = { 20, 60 }, dir = { 200, 340 },
                  gravity = -300, life = { 0.5, 0.9 }, color = { 0.7, 0.05, 0.05 }, blend = "BLEND" },
})
variant("warrior_fury", "warrior", "Fury", 2, {
    name = "Rampage", tagline = "Fury: every hit lands twice in a frenzy; crits blow out in a red-orange burst.",
    physColor = { 1, 0.82, 0.55 }, spellColor = { 1, 0.4, 0.15 },
    layers = { { x = 2, y = -2, color = { 0.5, 0.1, 0.02, 1 } } },
    motion = "zap", motionArgs = { speed = 60, step = 0.03, jolt = 2 },
    echo = { delay = 0.07 }, shake = 8, dur = 0.95,
    critDecor = { tex = "burst", size = 120, color = { 1, 0.3, 0.1 }, alpha = 0.75, spin = 2 },
    particles = { tex = "flame", count = 0, critCount = 6, size = { 8, 12 }, aspect = 0.5, speed = { 50, 120 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.3, 0.5 }, color = { 1, 0.35, 0.1 }, orient = true },
    ring = { size = 64, color = { 1, 0.4, 0.15 }, grow = 1.8, alpha = 0.85 },
})
variant("warrior_prot", "warrior", "Protection", 3, {
    name = "Shield Wall", tagline = "Protection: numbers bounce off a steel shield; crits ring out in a shockwave.",
    physColor = { 0.85, 0.9, 1 }, spellColor = { 0.45, 0.7, 1 }, size = 28,
    layers = { { x = 2, y = -2, color = { 0.1, 0.15, 0.35, 1 } } },
    motion = "bounce", motionArgs = { vx = { -10, 10 }, vy = 150, gravity = 520, floor = -8, damp = 0.4 }, shake = 3,
    decor = { tex = "shield", size = 38, y = 22, color = { 0.35, 0.45, 0.6 }, alpha = 0.6, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "shield", size = 58, y = 22, color = { 0.4, 0.5, 0.68 }, alpha = 0.95, blend = "BLEND", snap = 1.4, snapTime = 0.1 },
    ring = { size = 60, color = { 0.75, 0.85, 1 }, grow = 1.6, alpha = 0.9 },
    particles = { tex = "spark", count = 0, critCount = 6, size = { 3, 5 }, speed = { 80, 160 }, dir = { 20, 160 },
                  gravity = -200, life = { 0.3, 0.5 }, color = { 0.9, 0.95, 1 } },
})

---------------------------------------------------------------------------
-- Paladin (Lightbringer)
---------------------------------------------------------------------------
variant("paladin_holy", "paladin", "Holy", 1, {
    name = "Radiance", tagline = "Holy: soft golden numbers among rising motes of light; crits bloom in halos.",
    physColor = { 1, 0.98, 0.9 }, spellColor = { 1, 0.9, 0.55 },
    layers = glow({ 1, 0.95, 0.6 }, 0.35),
    motion = "rise", motionArgs = { speed = 30, sway = 4, freq = 2 },
    decor = { tex = "glow", size = 50, color = { 1, 0.95, 0.6 }, alpha = 0.15 },
    critReplacesDecor = true,
    critDecor = { tex = "burst", size = 110, color = { 1, 0.95, 0.7 }, alpha = 0.5, spin = 0.3 },
    critDecor2 = false,
    ring = { size = 40, color = { 1, 0.95, 0.6 }, grow = 3, alpha = 0.9 },
    particles = { tex = "glow", count = 2, critCount = 8, size = { 3, 5 }, speed = { 10, 30 }, dir = { 70, 110 },
                  gravity = 20, life = { 0.6, 1.1 }, color = { 1, 0.95, 0.7 } },
})
variant("paladin_prot", "paladin", "Protection", 2, {
    name = "Bulwark", tagline = "Protection: a gold crest guards every hit; crits consecrate the ground.",
    physColor = { 0.92, 0.94, 1 }, spellColor = { 0.6, 0.8, 1 },
    layers = { { x = 2, y = -2, color = { 0.1, 0.18, 0.4, 1 } } },
    motion = "bounce", motionArgs = { vx = { -8, 8 }, vy = 140, gravity = 520, floor = -8, damp = 0.4 },
    decor = { tex = "shield", size = 34, color = { 0.75, 0.6, 0.2 }, alpha = 0.35, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "shield", size = 64, color = { 0.85, 0.68, 0.2 }, alpha = 0.95, blend = "BLEND", snap = 1.5, snapTime = 0.1 },
    critDecor2 = { tex = "ring", size = { 80, 24 }, y = -22, color = { 1, 0.85, 0.4 }, alpha = 0.9, grow = 1.5 },
    particles = false,
})
variant("paladin_ret", "paladin", "Retribution", 3, {
    name = "Judgment", tagline = "Retribution: numbers hammer down under a column of light and a golden blast.",
    physColor = { 1, 0.95, 0.8 }, spellColor = { 1, 0.75, 0.2 },
    layers = { { x = 2, y = -2, color = { 0.4, 0.25, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 45, fall = 0.12, squash = 0.3, sinkAt = 0.35, sink = 12 }, pop = 0, shake = 5,
    critDecor = { tex = "beam", size = { 60, 240 }, y = 40, color = { 1, 0.85, 0.4 }, alpha = 0.9, snap = 0.2, snapTime = 0.08 },
    critDecor2 = { tex = "burst", size = 130, color = { 1, 0.75, 0.2 }, alpha = 0.7, spin = 1 },
    particles = { tex = "spark", count = 0, critCount = 8, size = { 3, 6 }, speed = { 60, 140 }, dir = { 20, 160 },
                  gravity = -300, life = { 0.4, 0.8 }, color = { 1, 0.85, 0.4 } },
})

---------------------------------------------------------------------------
-- Hunter (Dead Eye)
---------------------------------------------------------------------------
variant("hunter_bm", "hunter", "Beast Mastery", 1, {
    name = "Pack Leader", tagline = "Beast Mastery: savage numbers rush in; crits rake three claw marks.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    physColor = { 0.95, 0.88, 0.75 }, spellColor = { 0.85, 0.55, 0.25 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.15, 0.05, 1 } } },
    motionArgs = { arrive = true, dist = 60, time = 0.22, rise = 18 }, shake = 3,
    decor = false,
    critDecor = { tex = "claws", size = 118, color = { 1, 0.62, 0.25 }, alpha = 1, snap = 0.1, snapTime = 0.08 },
    particles = { tex = "glow", count = 0, critCount = 6, size = { 3, 6 }, speed = { 40, 100 }, dir = { 200, 340 },
                  gravity = -200, life = { 0.4, 0.8 }, color = { 0.6, 0.4, 0.2 }, blend = "BLEND" },
})
variant("hunter_mm", "hunter", "Marksmanship", 2, {
    name = "Bullseye", tagline = "Marksmanship: every shot is sighted; crits land dead center in a red bullseye.",
    physColor = { 0.95, 0.98, 0.9 }, spellColor = { 0.75, 0.9, 0.5 },
    motionArgs = { arrive = true, dist = 110, time = 0.22, rise = 18 },
    decor = { tex = "reticle", size = 36, color = { 0.9, 0.95, 0.8 }, alpha = 0.35 },
    critReplacesDecor = true,
    critDecor = { tex = "reticle", size = 90, color = { 1, 0.2, 0.2 }, alpha = 1, snap = 2.4, snapTime = 0.12 },
    ring = { size = 30, color = { 1, 0.3, 0.3 }, grow = 2, alpha = 0.9 },
})
variant("hunter_sv", "hunter", "Survival", 3, {
    name = "Trapper", tagline = "Survival: numbers spring the trap; crits snap its jaws shut in a venom cloud.",
    physColor = { 0.9, 0.95, 0.8 }, spellColor = { 0.5, 0.9, 0.3 },
    layers = { { x = 1.5, y = -1.5, color = { 0.15, 0.25, 0.05, 1 } } },
    motion = "slam", motionArgs = { from = 2, time = 0.14, drift = 18 },
    decor = false,
    critDecor = { tex = "spikes", size = 96, color = { 0.36, 0.34, 0.32 }, alpha = 0.95, blend = "BLEND", snap = 2, snapTime = 0.08 },
    particles = { tex = "puff", count = 0, critCount = 5, size = { 14, 22 }, speed = { 20, 50 }, dir = { 0, 360 },
                  gravity = 5, life = { 0.6, 1.0 }, color = { 0.45, 0.85, 0.25 }, blend = "BLEND" },
    particles2 = { tex = "drop", count = 0, critCount = 6, size = { 5, 8 }, aspect = 0.6, speed = { 40, 90 }, dir = { 30, 150 },
                   gravity = -250, life = { 0.5, 0.8 }, color = { 0.45, 0.85, 0.25 }, blend = "BLEND" },
})

---------------------------------------------------------------------------
-- Rogue (Cutthroat)
---------------------------------------------------------------------------
variant("rogue_assa", "rogue", "Assassination", 1, {
    name = "Venom", tagline = "Assassination: numbers drip poison; crits slash a green X through a toxic cloud.",
    physColor = { 0.9, 1, 0.75 }, spellColor = { 0.35, 1, 0.25 },
    layers = { { x = 2, y = -2, color = { 0.05, 0.25, 0.02, 1 } } },
    critDecor = { tex = "slash", size = { 150, 36 }, rot = 0.65, color = { 0.4, 1, 0.3 }, alpha = 1, snap = 0.1, snapTime = 0.08 },
    critDecor2 = { tex = "slash", size = { 150, 36 }, rot = -0.65, color = { 0.4, 1, 0.3 }, alpha = 1, snap = 0.1, snapTime = 0.08 },
    particles = { tex = "drop", count = 1, critCount = 7, size = { 6, 9 }, aspect = 0.5, speed = { 20, 60 }, dir = { 200, 340 },
                  gravity = -300, life = { 0.5, 0.9 }, color = { 0.35, 0.95, 0.25 } },
    particles2 = { tex = "puff", count = 0, critCount = 3, size = { 30, 44 }, speed = { 10, 30 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.6, 1.0 }, color = { 0.3, 0.75, 0.2 }, blend = "BLEND" },
})
variant("rogue_combat", "rogue", "Combat", 2, {
    name = "Blade Flurry", tagline = "Combat: numbers dash in with a blur of steel; crits flash a flurry of slashes.",
    physColor = { 1, 0.95, 0.7 }, spellColor = { 1, 0.75, 0.3 },
    layers = {
        { x = 2, y = -2, color = { 0.3, 0.2, 0, 1 } },
        { x = 8, y = 0, color = { 1, 0.9, 0.6, 0.3 }, trail = true },
    },
    motion = "dash", motionArgs = { arrive = true, dist = 80, time = 0.22, rise = 18 },
    critDecor = { tex = "slash", size = { 140, 30 }, y = 12, rot = 0.15, color = { 1, 0.9, 0.6 }, alpha = 1, snap = 0.1, snapTime = 0.06 },
    critDecor2 = { tex = "slash", size = { 140, 30 }, y = -12, rot = 0.15, color = { 1, 0.9, 0.6 }, alpha = 1, snap = 0.1, snapTime = 0.06, delay = 0.06 },
    particles = { tex = "slash", count = 0, critCount = 4, size = { 6, 9 }, aspect = 6, speed = { 120, 200 }, dir = { -10, 10 },
                  gravity = 0, life = { 0.2, 0.35 }, color = { 1, 0.95, 0.8 }, mirror = true },
})
variant("rogue_sub", "rogue", "Subtlety", 3, {
    name = "Shadowstep", tagline = "Subtlety: numbers fade out of the shadows; crits strike from a cloud of smoke.",
    physColor = { 0.85, 0.8, 0.95 }, spellColor = { 0.6, 0.45, 0.95 },
    layers = { { x = 2, y = -2, color = { 0.1, 0.05, 0.2, 1 } } },
    motion = "rise", motionArgs = { speed = 24 }, fadeIn = 0.25,
    critDecor = { tex = "puff", size = 70, color = { 0.15, 0.08, 0.22 }, alpha = 0.85, blend = "BLEND" },
    critDecor2 = { tex = "slash", size = { 150, 36 }, rot = 0.65, color = { 0.75, 0.55, 1 }, alpha = 1, snap = 0.1, snapTime = 0.08 },
    particles = { tex = "puff", count = 1, critCount = 5, size = { 14, 22 }, speed = { 10, 40 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.0 }, color = { 0.2, 0.12, 0.3 }, blend = "BLEND" },
})

---------------------------------------------------------------------------
-- Priest (Halo)
---------------------------------------------------------------------------
variant("priest_disc", "priest", "Discipline", 1, {
    name = "Bastion", tagline = "Discipline: numbers sit inside a golden ward; crits seal it with a shield.",
    physColor = { 1, 0.97, 0.9 }, spellColor = { 1, 0.88, 0.55 },
    layers = glow({ 1, 0.9, 0.6 }, 0.3),
    decor = { tex = "ring", size = 52, color = { 1, 0.9, 0.55 }, alpha = 0.4 },
    critDecor = { tex = "ring", size = 90, color = { 1, 0.9, 0.55 }, alpha = 0.9, snap = 0.6, snapTime = 0.12 },
    critDecor2 = { tex = "shield", size = 50, color = { 1, 0.88, 0.5 }, alpha = 0.5, blend = "BLEND" },
    particles = false,
})
variant("priest_holy", "priest", "Holy", 2, {
    name = "Seraph", tagline = "Holy: haloed numbers float on feathers; crits call down a beam of light.",
    physColor = { 1, 1, 1 }, spellColor = { 1, 0.95, 0.7 },
    critDecor2 = { tex = "beam", size = { 60, 240 }, y = 40, color = { 1, 1, 0.85 }, alpha = 0.8 },
    particles = { tex = "feather", count = 0, critCount = 6, size = { 12, 18 }, aspect = 0.5, speed = { 10, 30 },
                  dir = { 0, 360 }, gravity = -30, life = { 0.8, 1.3 }, spin = 2, color = { 1, 1, 1 }, blend = "BLEND" },
})
variant("priest_shadow", "priest", "Shadow", 3, {
    name = "Mind Flay", tagline = "Shadow: flickering numbers drift under a void eye; crits ripple into darkness.",
    physColor = { 0.85, 0.8, 0.95 }, spellColor = { 0.6, 0.3, 0.95 },
    layers = glow({ 0.45, 0.15, 0.75 }, 0.4), flicker = true,
    motion = "rise", motionArgs = { speed = 24, sway = 8, freq = 3 },
    decor = { tex = "eye", size = { 40, 20 }, color = { 0.5, 0.2, 0.85 }, alpha = 0.25, blend = "BLEND", y = 0 },
    critDecor = { tex = "eye", size = { 90, 45 }, color = { 0.5, 0.2, 0.85 }, alpha = 0.65, blend = "BLEND", y = 0, snap = 0.3, snapTime = 0.12 },
    ring = { size = 40, color = { 0.45, 0.15, 0.75 }, grow = 3, alpha = 0.85 },
    particles = { tex = "puff", count = 1, critCount = 5, size = { 12, 20 }, speed = { 10, 30 }, dir = { 60, 120 },
                  gravity = 10, life = { 0.6, 1.1 }, color = { 0.25, 0.08, 0.35 }, blend = "BLEND" },
})

---------------------------------------------------------------------------
-- Shaman (Stormcall)
---------------------------------------------------------------------------
variant("shaman_ele", "shaman", "Elemental", 1, {
    name = "Thunderhead", tagline = "Elemental: storm clouds and forking lightning; crits split the sky.",
    physColor = { 0.9, 0.95, 1 }, spellColor = { 0.55, 0.75, 1 },
    decor = { tex = "bolt", size = { 16, 56 }, color = { 0.8, 0.9, 1 }, alpha = 0.9, flicker = true, randomRot = true },
    critDecor = { tex = "bolt", size = { 30, 120 }, color = { 0.55, 0.75, 1 }, alpha = 0.85, flicker = true, randomRot = true },
    ring = { size = 150, color = { 0.6, 0.8, 1 }, grow = 1.4, alpha = 0.9 },
    particles2 = { tex = "puff", count = 0, critCount = 3, size = { 30, 40 }, speed = { 10, 25 }, dir = { 60, 120 },
                   gravity = 0, life = { 0.8, 1.2 }, color = { 0.35, 0.38, 0.45 }, blend = "BLEND" },
})
variant("shaman_enh", "shaman", "Enhancement", 2, {
    name = "Stormstrike", tagline = "Enhancement: twin electrified strikes; crits cross two charged slashes.",
    physColor = { 0.85, 0.92, 1 }, spellColor = { 0.35, 0.75, 1 },
    motion = "dash", motionArgs = { arrive = true, dist = 70, time = 0.2, rise = 18 }, echo = { delay = 0.07 }, shake = 4,
    decor = false, ring = false,
    critDecor = { tex = "slash", size = { 140, 30 }, y = -6, rot = 0.35, color = { 0.6, 0.85, 1 }, alpha = 1, snap = 0.1, snapTime = 0.06 },
    critDecor2 = { tex = "slash", size = { 140, 30 }, y = 6, rot = 0.35, color = { 0.6, 0.85, 1 }, alpha = 1, snap = 0.1, snapTime = 0.06, delay = 0.05 },
    particles = { tex = "bolt", count = 0, critCount = 4, size = { 30, 40 }, aspect = 0.3, speed = { 140, 220 },
                  dir = { 0, 360 }, orient = true, life = { 0.18, 0.3 }, color = { 0.75, 0.9, 1 } },
})
variant("shaman_resto", "shaman", "Restoration", 3, {
    name = "Tidewater", tagline = "Restoration: numbers rise on a gentle tide of bubbles; crits wash out in rings.",
    physColor = { 0.85, 1, 0.95 }, spellColor = { 0.3, 0.9, 0.8 },
    layers = { { x = -1.5, y = 1.5, color = { 0.05, 0.35, 0.35, 0.85 } } },
    motion = "rise", motionArgs = { speed = 30, sway = 7, freq = 4 },
    decor = false,
    critDecor = { tex = "ring", size = 40, color = { 0.4, 0.95, 0.85 }, alpha = 0.9, grow = 2.5 },
    ring = { size = 30, color = { 0.7, 1, 0.95 }, grow = 2.3, alpha = 0.8 },
    particles = { tex = "bubble", count = 2, critCount = 8, size = { 6, 12 }, speed = { 15, 40 }, dir = { 70, 110 },
                  gravity = 25, life = { 0.6, 1.1 }, color = { 0.6, 1, 0.9 } },
})

---------------------------------------------------------------------------
-- Mage (Spellweave)
---------------------------------------------------------------------------
variant("mage_arcane", "mage", "Arcane", 1, {
    name = "Arcane Surge", tagline = "Arcane: numbers burst from a spinning rune among stars; crits flare the rune wide.",
    physColor = { 0.95, 0.88, 1 }, spellColor = { 0.85, 0.45, 1 },
    layers = { { x = 1, y = 1, color = { 0.45, 0.15, 0.75, 0.5 } }, { x = -1, y = -1, color = { 0.45, 0.15, 0.75, 0.5 } } },
    decor = { tex = "rune", size = 56, color = { 0.8, 0.45, 1 }, alpha = 0.22, spin = 1.2 },
    critReplacesDecor = true,
    critDecor = { tex = "rune", size = 132, color = { 0.8, 0.45, 1 }, alpha = 0.55, spin = -2 },
    critDecor2 = false, ring = false,
    particles2 = { tex = "star", count = 1, critCount = 7, size = { 6, 10 }, speed = { 15, 45 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.6, 1.1 }, color = { 1, 0.7, 1 } },
})
variant("mage_fire", "mage", "Fire", 2, {
    name = "Pyroclasm", tagline = "Fire: numbers ignite from gathering embers; crits erupt in flame.",
    physColor = { 1, 0.9, 0.75 }, spellColor = { 1, 0.5, 0.1 },
    layers = { { x = 1, y = 1, color = { 0.6, 0.15, 0, 0.6 } }, { x = -1, y = -1, color = { 0.6, 0.15, 0, 0.6 } } },
    critDecor = { tex = "burst", size = 130, color = { 1, 0.5, 0.1 }, alpha = 0.8, spin = 1 },
    critDecor2 = false,
    ring = { size = 60, color = { 1, 0.6, 0.2 }, grow = 1.6, alpha = 0.9 },
    particles = { tex = "spark", inward = true, count = 6, critCount = 10, radius = { 50, 70 }, size = { 5, 7 },
                  life = { 0.15, 0.15 }, color = { 1, 0.6, 0.2 } },
    particles2 = { tex = "flame", count = 2, critCount = 12, size = { 8, 14 }, aspect = 0.5, speed = { 40, 120 }, dir = { 50, 130 },
                   gravity = 40, life = { 0.4, 0.8 }, color = { 1, 0.5, 0.1 }, orient = true },
})
variant("mage_frost", "mage", "Frost", 3, {
    name = "Glacial Spike", tagline = "Frost: numbers slam in like spikes of ice; crits shatter into shards.",
    physColor = { 0.9, 0.98, 1 }, spellColor = { 0.45, 0.8, 1 },
    layers = { { x = 1, y = 1, color = { 0.15, 0.35, 0.7, 0.6 } }, { x = -1, y = -1, color = { 0.15, 0.35, 0.7, 0.6 } } },
    motion = "slam", motionArgs = { from = 2.2, time = 0.14, drift = 18 }, shake = 3,
    -- The spike itself: a tall ice shard striking from above.
    critDecor = { tex = "shard", size = { 26, 72 }, y = 50, color = { 0.72, 0.93, 1 }, alpha = 0.95, snap = 1.8, snapTime = 0.1 },
    critDecor2 = { tex = "snowflake", size = 70, color = { 0.8, 0.95, 1 }, alpha = 0.55, spin = 1.2 },
    ring = { size = 60, color = { 0.7, 0.92, 1 }, grow = 2, alpha = 0.9 },
    particles = { tex = "shard", count = 0, critCount = 9, size = { 10, 16 }, speed = { 90, 160 }, dir = { 0, 360 },
                  gravity = -220, life = { 0.4, 0.8 }, color = { 0.75, 0.95, 1 }, spin = 6 },
})

---------------------------------------------------------------------------
-- Warlock (Fel Pact)
---------------------------------------------------------------------------
variant("warlock_aff", "warlock", "Affliction", 1, {
    name = "Withering", tagline = "Affliction: numbers rot and drip away; crits raise a grinning skull.",
    physColor = { 0.8, 0.75, 0.9 }, spellColor = { 0.55, 0.3, 0.85 },
    layers = { { x = 2, y = -2, color = { 0.15, 0.02, 0.25, 1 } } },
    motion = "drip", motionArgs = { hold = 0.25, speed = 20, accel = 60 }, flicker = false,
    decor = false,
    critDecor2 = { tex = "puff", size = 92, y = 8, color = { 0.45, 0.75, 0.3 }, alpha = 0.55, blend = "BLEND", grow = 0.8, spin = 0.3 },
    ring = { size = 56, color = { 0.6, 0.9, 0.4 }, grow = 1.5, alpha = 0.7 },
    critDecor = { tex = "skull", size = 44, y = 28, color = { 0.75, 0.65, 0.95 }, alpha = 0.9, blend = "BLEND", snap = 1.4, snapTime = 0.1 },
    particles = { tex = "puff", count = 1, critCount = 5, size = { 12, 20 }, speed = { 5, 20 }, dir = { 60, 120 },
                  gravity = 15, life = { 0.7, 1.2 }, color = { 0.3, 0.12, 0.4 }, blend = "BLEND" },
})
variant("warlock_demo", "warlock", "Demonology", 2, {
    name = "Demonic Pact", tagline = "Demonology: numbers rise under a demon's gaze; crits open its eye in a spiked fel ring.",
    physColor = { 0.85, 0.78, 0.95 }, spellColor = { 0.75, 0.3, 1 },
    decor = false, ring = false,
    critDecor = { tex = "eye", size = { 84, 40 }, color = { 0.5, 1, 0.25 }, alpha = 0.7, blend = "BLEND", snap = 0.3, snapTime = 0.12 },
    critDecor2 = { tex = "spikes", size = 110, color = { 0.5, 0.15, 0.75 }, alpha = 0.8, blend = "BLEND", spin = 1 },
})
variant("warlock_destro", "warlock", "Destruction", 3, {
    name = "Chaos Fire", tagline = "Destruction: numbers crash down in fel fire; crits crack the ground in a green blast.",
    physColor = { 0.9, 0.85, 0.7 }, spellColor = { 0.5, 1, 0.15 },
    layers = { { x = 2, y = -2, color = { 0.15, 0.3, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 45, fall = 0.12, squash = 0.3, sinkAt = 0.35, sink = 12 }, pop = 0, shake = 5,
    flicker = false, decor = false, ring = false,
    critDecor = { tex = "burst", size = 140, color = { 0.45, 1, 0.15 }, alpha = 0.75, spin = 1 },
    critDecor2 = { tex = "crack", size = 100, y = -10, color = { 0.2, 0.5, 0.05 }, alpha = 0.85, blend = "BLEND", randomRot = true },
    particles = { tex = "flame", count = 2, critCount = 12, size = { 8, 14 }, aspect = 0.5, speed = { 40, 130 }, dir = { 50, 130 },
                  gravity = 40, life = { 0.4, 0.8 }, color = { 0.5, 1, 0.2 }, orient = true },
})

---------------------------------------------------------------------------
-- Druid (Wild Bloom)
---------------------------------------------------------------------------
variant("druid_balance", "druid", "Balance", 1, {
    name = "Starsurge", tagline = "Balance: starlit numbers under a crescent moon; crits burst into starlight.",
    physColor = { 0.9, 0.9, 1 }, spellColor = { 0.6, 0.55, 1 },
    layers = glow({ 0.6, 0.6, 1 }, 0.3),
    motion = "rise", motionArgs = { speed = 32, sway = 6, freq = 2 },
    decor = { tex = "moon", size = 24, y = 26, color = { 0.85, 0.85, 1 }, alpha = 0.45, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "moon", size = 40, y = 26, color = { 0.9, 0.9, 1 }, alpha = 0.9, blend = "BLEND", snap = 1.5, snapTime = 0.1 },
    critDecor2 = { tex = "burst", size = 120, color = { 0.7, 0.65, 1 }, alpha = 0.6, spin = 0.4 },
    particles = { tex = "star", count = 1, critCount = 8, size = { 6, 11 }, speed = { 20, 70 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 1.0 }, color = { 1, 0.95, 0.75 } },
})
variant("druid_feral", "druid", "Feral", 2, {
    treeName = "Feral Combat",
    name = "Shred", tagline = "Feral: numbers pounce and slam; crits tear three claw marks.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    physColor = { 1, 0.82, 0.55 }, spellColor = { 1, 0.55, 0.15 },
    layers = { { x = 2, y = -2, color = { 0.35, 0.15, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 40, fall = 0.1, squash = 0.3, sinkAt = 0.35, sink = 12 }, pop = 0, shake = 5,
    critDecor = { tex = "claws", size = 100, color = { 1, 0.6, 0.2 }, alpha = 1, snap = 0.1, snapTime = 0.07 },
    particles = { tex = "glow", count = 0, critCount = 6, size = { 4, 7 }, speed = { 30, 80 }, dir = { 200, 340 },
                  gravity = -300, life = { 0.5, 0.9 }, color = { 0.7, 0.1, 0.05 }, blend = "BLEND" },
})
variant("druid_guardian", "druid", "Guardian", 2, {
    form = "bear", treeName = "Feral Combat",
    name = "Ironbark", tagline = "Guardian (Bear Form): numbers bounce off thick bark armor; crits ring out from it.",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    physColor = { 0.9, 0.82, 0.7 }, spellColor = { 0.6, 0.85, 0.4 },
    layers = { { x = 2, y = -2, color = { 0.25, 0.15, 0.05, 1 } } },
    motion = "bounce", motionArgs = { vx = { -8, 8 }, vy = 140, gravity = 520, floor = -8, damp = 0.4 },
    decor = { tex = "bark", size = 36, y = 20, color = { 0.55, 0.38, 0.2 }, alpha = 0.6, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "bark", size = 56, y = 20, color = { 0.6, 0.42, 0.22 }, alpha = 0.95, blend = "BLEND", snap = 1.4, snapTime = 0.1 },
    ring = { size = 60, color = { 0.75, 0.6, 0.35 }, grow = 1.6, alpha = 0.9 },
    particles = false,
})
variant("druid_resto", "druid", "Restoration", 3, {
    name = "Lifebloom", tagline = "Restoration: numbers drift up among opening flowers; crits bloom in full.",
    physColor = { 0.95, 1, 0.9 }, spellColor = { 0.45, 1, 0.55 },
    layers = glow({ 0.5, 1, 0.5 }, 0.3),
    motion = "rise", motionArgs = { speed = 28, sway = 10, freq = 2.5 },
    decor = { tex = "bloom", size = 40, color = { 0.5, 0.95, 0.5 }, alpha = 0.3, spin = 1, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "bloom", size = 110, color = { 0.55, 1, 0.5 }, alpha = 0.85, spin = 0.6, blend = "BLEND", snap = 0.05, snapTime = 0.25 },
    ring = { size = 40, color = { 0.6, 1, 0.6 }, grow = 2.5, alpha = 0.7 },
    particles = { tex = "leaf", count = 2, critCount = 9, size = { 8, 12 }, aspect = 0.5, speed = { 15, 50 }, dir = { 0, 360 },
                  gravity = -30, life = { 0.7, 1.2 }, spin = 4, color = { 0.5, 0.95, 0.4 }, blend = "BLEND" },
})
