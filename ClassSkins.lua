local _, ns = ...

-- One skin per class, each built around the class's signature move. Same
-- data format as Skins.lua (see its header); group = "class" lists them
-- under their own heading, and color is the class color used in the picker.
-- Each has a physical/spell pair (physical paler, spell stronger) so the
-- Colors setting works the same way here as on every other skin.

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

add("warrior", {
    group = "class", class = "WARRIOR",
    name = "Bloodrage", tagline = "Warrior: numbers slam down from above; crits crack the ground and throw debris.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 0.78, 0.61, 0.43 },
    physColor = { 0.95, 0.86, 0.72 }, spellColor = { 1, 0.38, 0.22 },   -- steel tan / rage red
    layers = { { x = 2, y = -2, color = { 0.45, 0.06, 0.04, 1 } } },
    motion = "drop", motionArgs = { height = 50, fall = 0.12, squash = 0.3, sinkAt = 0.35, sink = 14 },
    dur = 1.1, critDur = 1.4, critScale = 1.6, pop = 0, shake = 5,
    critDecor = { tex = "crack", size = 120, color = { 0.95, 0.3, 0.12 }, alpha = 0.9,
                  snap = 0.4, snapTime = 0.06, randomRot = true },
    particles = { tex = "pixel", count = 0, critCount = 9, size = { 3, 6 }, speed = { 60, 160 }, dir = { 20, 160 },
                  gravity = -500, life = { 0.4, 0.8 }, color = { 0.5, 0.35, 0.25 }, blend = "BLEND" },
    world = { WorldTextScale = 1.25, WorldTextGravity = 2 },
})

add("paladin", {
    group = "class", class = "PALADIN",
    name = "Lightbringer", tagline = "Paladin: radiant numbers rise in state; crits call down a column of light.",
    font = F.morpheus, size = 26, outline = "OUTLINE",
    color = { 0.96, 0.55, 0.73 },
    physColor = { 0.95, 0.95, 1 }, spellColor = { 1, 0.85, 0.42 },     -- silver / holy gold
    layers = glow({ 1, 0.85, 0.4 }, 0.35),
    motion = "rise", motionArgs = { speed = 38 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0.3,
    critDecor = { tex = "beam", size = { 60, 240 }, y = 50, color = { 1, 0.9, 0.55 }, alpha = 0.9,
                  snap = 0.2, snapTime = 0.12 },
    critDecor2 = { tex = "burst", size = 140, color = { 1, 0.82, 0.35 }, alpha = 0.7, spin = 0.6 },
    particles = { tex = "twinkle", count = 0, critCount = 6, size = { 6, 10 }, speed = { 10, 40 }, dir = { 60, 120 },
                  gravity = 20, life = { 0.6, 1.1 }, color = { 1, 0.95, 0.7 } },
    world = { WorldTextRampDuration = 1.3 },
})

add("hunter", {
    group = "class", class = "HUNTER",
    name = "Dead Eye", tagline = "Hunter: numbers fly in like arrows; crits snap a crosshair onto the target.",
    font = F.friz, size = 24, outline = "OUTLINE",
    color = { 0.67, 0.83, 0.45 },
    physColor = { 0.9, 0.96, 0.8 }, spellColor = { 0.58, 0.85, 0.32 },  -- pale green / hunter green
    layers = {
        { x = 8, y = 0, color = { 0.75, 0.9, 0.55, 0.3 }, trail = true },
        { x = 16, y = 0, color = { 0.75, 0.9, 0.55, 0.12 }, trail = true },
    },
    motion = "dash", motionArgs = { arrive = true, dist = 90, time = 0.22, rise = 18 },
    dur = 1.0, critDur = 1.3, critScale = 1.5, pop = 0,
    decor = { tex = "slash", size = { 70, 14 }, x = 40, trail = true, color = { 0.8, 0.95, 0.6 }, alpha = 0.5 },
    critDecor = { tex = "reticle", size = 80, color = { 1, 0.25, 0.2 }, alpha = 1,
                  snap = 2.2, snapTime = 0.15, unwind = 1.6 },
    world = { floatingCombatTextCombatDamageDirectionalScale = 1.5 },
})

add("rogue", {
    group = "class", class = "ROGUE",
    name = "Cutthroat", tagline = "Rogue: slanted numbers blink in and vanish; crits slash an X and spill poison.",
    font = F.slash, size = 28, outline = "OUTLINE",
    color = { 1, 0.96, 0.41 },
    physColor = { 1, 0.97, 0.65 }, spellColor = { 0.42, 1, 0.3 },     -- pale yellow / poison green
    layers = { { x = 2, y = -2, color = { 0.2, 0.15, 0, 1 } } },
    motion = "blink", motionArgs = { from = 16, at = 0.07, rise = 22 },
    dur = 0.85, critDur = 1.1, critScale = 1.5, pop = 0, shake = 2,
    critFormat = "%s!",
    critDecor = { tex = "slash", size = { 150, 36 }, rot = 0.65, color = { 1, 0.2, 0.2 }, alpha = 1,
                  snap = 0.1, snapTime = 0.08 },
    critDecor2 = { tex = "slash", size = { 150, 36 }, rot = -0.65, color = { 1, 0.2, 0.2 }, alpha = 1,
                   snap = 0.1, snapTime = 0.08 },
    particles = { tex = "glow", count = 0, critCount = 6, size = { 4, 7 }, speed = { 40, 110 }, dir = { 20, 160 },
                  gravity = -420, life = { 0.4, 0.8 }, color = { 0.4, 0.95, 0.25 }, blend = "BLEND" },
    world = { WorldTextRampDuration = 0.7 },
})

add("priest", {
    group = "class", class = "PRIEST",
    name = "Halo", tagline = "Priest: soft glowing numbers float under a halo; crits shed feathers.",
    font = F.arialn, size = 26, outline = "OUTLINE",
    color = { 1, 1, 1 },
    physColor = { 0.95, 0.95, 1 }, spellColor = { 0.8, 0.66, 1 },     -- white / lavender
    layers = glow({ 1, 1, 1 }, 0.3),
    motion = "rise", motionArgs = { speed = 32, sway = 6, freq = 2.5 },
    dur = 1.4, critDur = 1.7, critScale = 1.5, pop = 0.25,
    decor = { tex = "ring", size = { 44, 13 }, y = 22, color = { 1, 1, 0.85 }, alpha = 0.65 },
    critReplacesDecor = true,
    critDecor = { tex = "ring", size = { 72, 20 }, y = 30, color = { 1, 0.95, 0.6 }, alpha = 0.95,
                  snap = 0.4, snapTime = 0.15 },
    particles = { tex = "feather", count = 0, critCount = 5, size = { 12, 18 }, aspect = 0.5, speed = { 10, 30 },
                  dir = { 0, 360 }, gravity = -30, life = { 0.8, 1.3 }, spin = 2, color = { 1, 1, 1 }, blend = "BLEND" },
    world = { WorldTextRampDuration = 1.4 },
})

add("shaman", {
    group = "class", class = "SHAMAN",
    name = "Stormcall", tagline = "Shaman: crystal numbers crackle upward; crits fork chain lightning.",
    font = F.shard, size = 28, outline = "OUTLINE",
    color = { 0, 0.44, 0.87 },
    physColor = { 0.86, 0.93, 1 }, spellColor = { 0.3, 0.62, 1 },     -- ice white / storm blue
    layers = { { x = -1.5, y = 1.5, color = { 0.1, 0.3, 0.75, 0.85 } } },
    motion = "zap", motionArgs = { speed = 42, step = 0.06, jolt = 7 },
    dur = 1.0, critDur = 1.3, critScale = 1.5, pop = 0.2,
    decor = { tex = "bolt", size = { 14, 48 }, color = { 0.55, 0.8, 1 }, alpha = 0.8, flicker = true, randomRot = true },
    critDecor = { tex = "bolt", size = { 26, 100 }, color = { 0.45, 0.7, 1 }, alpha = 0.8, flicker = true, randomRot = true },
    ring = { size = 130, color = { 0.4, 0.7, 1 }, grow = 1.3, alpha = 0.9 },
    particles = { tex = "bolt", count = 0, critCount = 6, size = { 30, 44 }, aspect = 0.3, speed = { 140, 220 },
                  dir = { 0, 360 }, orient = true, life = { 0.18, 0.3 }, color = { 0.75, 0.9, 1 } },
    world = { floatingCombatTextCombatDamageDirectionalScale = 1.5 },
})

add("mage", {
    group = "class", class = "MAGE",
    name = "Spellweave", tagline = "Mage: sparks converge and the number bursts out; crits ripple fire, frost and arcane.",
    font = F.led, size = 28, outline = "OUTLINE",
    color = { 0.41, 0.8, 0.94 },
    physColor = { 0.86, 0.96, 1 }, spellColor = { 0.41, 0.8, 0.94 },  -- frost white / mage blue
    layers = {
        { x = 1, y = 1, color = { 0.2, 0.4, 0.85, 0.5 } },
        { x = -1, y = -1, color = { 0.2, 0.4, 0.85, 0.5 } },
    },
    motion = "implode", motionArgs = { time = 0.15, rise = 30 },
    dur = 1.15, critDur = 1.45, critScale = 1.5, pop = 0,
    ring = { size = 60, color = { 1, 0.5, 0.1 }, grow = 2.2, alpha = 1 },
    critDecor = { tex = "ring", size = 60, color = { 0.5, 0.9, 1 }, alpha = 1, grow = 2.2, delay = 0.08 },
    critDecor2 = { tex = "ring", size = 60, color = { 0.85, 0.45, 1 }, alpha = 1, grow = 2.2, delay = 0.16 },
    particles = { tex = "spark", inward = true, count = 6, critCount = 10, radius = { 50, 70 }, size = { 5, 7 },
                  life = { 0.15, 0.15 }, color = { 0.7, 0.9, 1 } },
    world = { WorldTextScale = 1.1 },
})

add("warlock", {
    group = "class", class = "WARLOCK",
    name = "Fel Pact", tagline = "Warlock: flickering numbers over a fel sigil; crits flare fel fire and a void ring.",
    font = F.morpheus, size = 28, outline = "OUTLINE",
    color = { 0.53, 0.53, 0.93 },
    physColor = { 0.8, 0.72, 0.96 }, spellColor = { 0.55, 1, 0.25 },  -- shadow violet / fel green
    flicker = true,
    layers = { { x = 2, y = -2, color = { 0.12, 0.02, 0.2, 1 } }, { x = -1, y = 1, color = { 0.75, 0.75, 1, 0.35 } } },
    motion = "rise", motionArgs = { speed = 45, sway = 4, freq = 9 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.3,
    decor = { tex = "rune", size = 72, color = { 0.4, 0.9, 0.18 }, alpha = 0.22, spin = 1.2 },
    critReplacesDecor = true,
    critDecor = { tex = "rune", size = 140, color = { 0.4, 0.95, 0.18 }, alpha = 0.55, spin = -2 },
    critDecor2 = { tex = "burst", size = 130, color = { 0.4, 1, 0.15 }, alpha = 0.6, spin = 1 },
    ring = { size = 100, color = { 0.6, 0.3, 0.95 }, grow = 1, alpha = 0.9 },
    particles = { tex = "glow", count = 2, critCount = 8, size = { 4, 8 }, speed = { 15, 40 }, dir = { 70, 110 },
                  gravity = 50, life = { 0.6, 1.1 }, color = { 0.5, 1, 0.3 }, sway = true },
    world = { WorldTextGravity = 0.3 },
})

add("druid", {
    group = "class", class = "DRUID",
    name = "Wild Bloom", tagline = "Druid: numbers sway up like falling leaves; crits bloom a flower.",
    font = F.friz, size = 25, outline = "OUTLINE",
    color = { 1, 0.49, 0.04 },
    physColor = { 1, 0.76, 0.48 }, spellColor = { 0.5, 0.95, 0.35 },  -- feral orange / nature green
    layers = { { x = 1.5, y = -1.5, color = { 0.2, 0.12, 0.02, 0.9 } } },
    motion = "rise", motionArgs = { speed = 42, sway = 16, freq = 3.5 },
    dur = 1.25, critDur = 1.55, critScale = 1.5, pop = 0.3,
    critDecor = { tex = "bloom", size = 110, color = { 0.4, 0.85, 0.3 }, alpha = 0.85, spin = 0.8, blend = "BLEND",
                  snap = 0.05, snapTime = 0.2 },
    particles = { tex = "leaf", count = 2, critCount = 8, size = { 10, 15 }, aspect = 0.5, speed = { 20, 60 },
                  dir = { 0, 360 }, gravity = -40, life = { 0.7, 1.2 }, spin = 4,
                  color = { 0.45, 0.8, 0.25 }, altColor = { 1, 0.6, 0.2 }, blend = "BLEND" },
    world = { floatingCombatTextCombatDamageDirectionalScale = 1.3 },
})
