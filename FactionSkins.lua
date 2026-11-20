local _, ns = ...

-- Faction skins. Same data format as Skins.lua (see its header); group =
-- "faction" lists them under their own heading, and each id matches its
-- feat in Feats.lua (in Collector mode that feat unlocks it). Every sigil,
-- flame and skull is SkinDeep's own art (tools/make_textures.js).

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

add("scarlet", {
    group = "faction", faction = "Scarlet Crusade",
    name = "Crimson Oath", tagline = "Scarlet Crusade: numbers march up in stamped steps over the crusade's sigil; crits burn with holy fire.",
    font = F.morpheus, size = 26, outline = "OUTLINE",
    color = { 0.92, 0.14, 0.14 },
    physColor = { 0.97, 0.94, 0.86 }, spellColor = { 0.92, 0.14, 0.14 },   -- bone white / crusade crimson
    layers = { { x = 2, y = -2, color = { 0.4, 0.03, 0.03, 1 } } },
    motion = "march", motionArgs = { stepTime = 0.22, steps = 3, px = 14, pulse = 0.12, drift = 10 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0.2,
    decor = { tex = "sigil", size = 56, color = { 0.8, 0.1, 0.1 }, alpha = 0.32, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "sigil", size = 86, color = { 0.85, 0.12, 0.1 }, alpha = 0.7, blend = "BLEND", snap = 1.6, snapTime = 0.12 },
    critDecor2 = { tex = "burst", size = 140, color = { 1, 0.75, 0.25 }, alpha = 0.6, spin = 0.5 },
    particles = { tex = "flame", count = 1, critCount = 7, size = { 8, 14 }, aspect = 0.5, speed = { 15, 45 }, dir = { 70, 110 },
                  gravity = 30, life = { 0.5, 1.0 }, color = { 1, 0.45, 0.1 }, altColor = { 1, 0.85, 0.3 } },
    world = { WorldTextScale = 1.1 },
})

add("scourge", {
    group = "faction", faction = "Scourge",
    name = "Plague Tide", tagline = "Scourge: sickly numbers lurch through plague mist; crits raise an icy rune and a grinning skull.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 0.55, 1, 0.35 },
    physColor = { 0.9, 0.9, 0.8 }, spellColor = { 0.55, 1, 0.35 },         -- bone / plague green
    layers = { { x = 2, y = -2, color = { 0.1, 0.25, 0.05, 1 } } },
    motion = "lurch", motionArgs = { period = 0.16, amp = 6, speed = 22 },
    dur = 1.35, critDur = 1.7, critScale = 1.5, pop = 0.25,
    critDecor = { tex = "rune", size = 120, color = { 0.55, 0.85, 1 }, alpha = 0.8, spin = -1.5 },
    critDecor2 = { tex = "skull", size = 60, color = { 0.85, 1, 0.75 }, alpha = 0.8, blend = "BLEND", snap = 0.2, snapTime = 0.12 },
    particles = { tex = "puff", count = 2, critCount = 7, size = { 16, 26 }, speed = { 5, 22 }, dir = { 60, 120 },
                  gravity = 8, life = { 0.8, 1.4 }, color = { 0.45, 0.85, 0.25 }, blend = "BLEND" },
    world = { WorldTextGravity = 0.4 },
})

add("defias", {
    group = "faction", faction = "Defias Brotherhood",
    name = "Red Kerchief", tagline = "Defias Brotherhood: numbers pop up from below; crits go off in a gunpowder flash and smoke.",
    font = F.friz, size = 24, outline = "THICKOUTLINE",
    color = { 0.88, 0.25, 0.18 },
    physColor = { 0.95, 0.9, 0.78 }, spellColor = { 0.88, 0.18, 0.12 },    -- parchment / kerchief red
    layers = { { x = 1.5, y = -1.5, color = { 0.25, 0.05, 0.02, 1 } } },
    motion = "sneak", motionArgs = { rise = 0.1, from = 16, speed = 28 },
    dur = 1.1, critDur = 1.4, critScale = 1.55, pop = 0.3, shake = 3,
    critFormat = "%s!",
    critDecor = { tex = "burst", size = 110, color = { 1, 0.6, 0.15 }, alpha = 0.9, grow = 0.3 },
    critDecor2 = { tex = "glow", size = 120, color = { 1, 0.45, 0.1 }, alpha = 0.7 },
    particles = { tex = "puff", count = 0, critCount = 6, size = { 24, 40 }, speed = { 40, 80 }, dir = { 0, 360 },
                  gravity = 10, life = { 0.6, 1.1 }, color = { 0.5, 0.48, 0.46 }, blend = "BLEND" },
    world = { WorldTextRampDuration = 0.8 },
})

add("darkiron", {
    group = "faction", faction = "Dark Iron",
    name = "Molten Anvil", tagline = "Dark Iron: molten numbers slam down like a forge hammer and throw sparks; crits ring the anvil.",
    font = F.friz, size = 28, outline = "THICKOUTLINE",
    color = { 1, 0.55, 0.2 },
    physColor = { 0.85, 0.8, 0.75 }, spellColor = { 1, 0.5, 0.1 },         -- cold iron / molten
    layers = {
        { x = -1, y = 1, color = { 1, 0.85, 0.4, 0.8 } },
        { x = 2, y = -2, color = { 0.6, 0.15, 0, 1 } },
        { x = 4, y = -4, color = { 0.25, 0.05, 0, 1 } },
    },
    motion = "drop", motionArgs = { height = 40, fall = 0.1, squash = 0.35, sinkAt = 0.35, sink = 10 },
    dur = 1.15, critDur = 1.45, critScale = 1.55, pop = 0, shake = 4,
    critDecor = { tex = "glow", size = 110, color = { 1, 0.5, 0.1 }, alpha = 0.8 },
    ring = { size = 110, color = { 1, 0.85, 0.6 }, grow = 1.0, alpha = 0.9 },
    particles = { tex = "spark", count = 2, critCount = 12, size = { 3, 6 }, speed = { 80, 200 }, dir = { 30, 150 },
                  gravity = -420, life = { 0.35, 0.7 }, color = { 1, 0.6, 0.15 } },
    world = { WorldTextScale = 1.2, WorldTextGravity = 2 },
})

add("brood", {
    group = "faction", faction = "Black Dragonflight",
    name = "Broodmother", tagline = "Black Dragonflight: smoldering violet numbers rise; crits breathe a cone of dragonfire.",
    font = F.morpheus, size = 28, outline = "OUTLINE",
    color = { 0.7, 0.45, 1 },
    physColor = { 0.85, 0.78, 0.95 }, spellColor = { 1, 0.45, 0.15 },      -- pale violet / dragonfire
    layers = { { x = 2, y = -2, color = { 0.15, 0.02, 0.2, 1 } } },
    motion = "rise", motionArgs = { speed = 40, sway = 6, freq = 4 },
    dur = 1.2, critDur = 1.5, critScale = 1.55, pop = 0.3,
    critDecor = { tex = "burst", size = 130, color = { 0.55, 0.2, 0.9 }, alpha = 0.7, spin = -0.8 },
    particles = { tex = "flame", count = 1, critCount = 12, size = { 10, 18 }, aspect = 0.5, speed = { 90, 170 },
                  dir = { 65, 115 }, gravity = -40, life = { 0.35, 0.7 }, orient = true,
                  color = { 1, 0.45, 0.1 }, altColor = { 0.7, 0.3, 1 } },
    world = { WorldTextScale = 1.15 },
})

add("argent", {
    group = "faction", faction = "Argent Dawn",
    name = "Silver Dawn", tagline = "Argent Dawn: silver numbers rise over the first light of dawn; crits break into rays.",
    font = F.friz, size = 26, outline = "OUTLINE",
    color = { 0.62, 0.88, 1 },
    physColor = { 0.92, 0.95, 1 }, spellColor = { 0.45, 0.85, 0.95 },     -- silver / dawn teal
    layers = glow({ 0.7, 0.9, 1 }, 0.3),
    motion = "rise", motionArgs = { speed = 34 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0.25,
    decor = { tex = "ring", size = { 70, 22 }, y = -12, color = { 0.55, 0.88, 1 }, alpha = 0.5 },
    critReplacesDecor = true,
    critDecor = { tex = "ring", size = { 110, 34 }, y = -14, color = { 0.75, 0.95, 1 }, alpha = 0.9, snap = 0.3, snapTime = 0.15 },
    critDecor2 = { tex = "burst", size = 150, y = -10, color = { 0.6, 0.9, 1 }, alpha = 0.6, spin = 0.3 },
    particles = { tex = "twinkle", count = 1, critCount = 7, size = { 8, 14 }, speed = { 15, 45 }, dir = { 30, 150 },
                  gravity = 10, life = { 0.6, 1.1 }, color = { 0.85, 0.97, 1 } },
    world = { WorldTextRampDuration = 1.3 },
})

add("broadside", {
    group = "faction", faction = "Bloodsail Buccaneers",
    name = "Broadside", tagline = "Bloodsail Buccaneers: numbers fire in like cannonballs; crits burst in smoke and spill gold.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.85, 0.2, 0.2 },
    physColor = { 0.95, 0.9, 0.78 }, spellColor = { 0.85, 0.2, 0.18 },     -- sailcloth / bloodsail red
    layers = { { x = 2, y = -2, color = { 0.2, 0.05, 0.02, 1 } } },
    motion = "dash", motionArgs = { arrive = true, dist = 30, time = 0.1, rise = 26 },
    dur = 1.15, critDur = 1.45, critScale = 1.55, pop = 0, shake = 5,
    critDecor = { tex = "burst", size = 90, color = { 1, 0.6, 0.15 }, alpha = 0.85 },
    particles = { tex = "puff", count = 0, critCount = 5, size = { 24, 40 }, speed = { 30, 70 }, dir = { 0, 360 },
                  gravity = 10, life = { 0.6, 1.0 }, color = { 0.6, 0.58, 0.55 }, blend = "BLEND" },
    particles2 = { tex = "coin", count = 0, critCount = 7, size = { 8, 11 }, speed = { 80, 160 }, dir = { 40, 140 },
                   gravity = -380, life = { 0.6, 1.0 }, color = { 1, 0.82, 0.25 }, blend = "BLEND" },
})

add("hexbound", {
    group = "faction", faction = "Gurubashi",
    name = "Hexbound", tagline = "Gurubashi: swaying voodoo numbers; crits flash a hex mask and a ring of mojo.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.55, 0.9, 0.4 },
    physColor = { 0.9, 0.95, 0.8 }, spellColor = { 0.75, 0.35, 1 },        -- bone / hex purple
    layers = { { x = 2, y = -2, color = { 0.1, 0.25, 0.08, 1 } } },
    motion = "rise", motionArgs = { speed = 30, sway = 8, freq = 6 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0.25,
    critDecor = { tex = "mask", size = 64, color = { 0.35, 0.6, 0.25 }, alpha = 0.9, blend = "BLEND", snap = 0.2, snapTime = 0.12 },
    ring = { size = 50, color = { 0.75, 0.35, 1 }, grow = 1.8, alpha = 0.9 },
    particles = { tex = "glow", count = 2, critCount = 8, size = { 3, 6 }, speed = { 15, 45 }, dir = { 60, 120 },
                  gravity = 40, life = { 0.6, 1.1 }, color = { 0.6, 1, 0.4 }, altColor = { 0.8, 0.45, 1 } },
})

add("oldgod", {
    group = "faction", faction = "Twilight's Hammer",
    name = "Old God Whispers", tagline = "Twilight's Hammer: numbers drift under a watching eye; crits ripple out in void rings.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.6, 0.4, 0.95 },
    physColor = { 0.85, 0.8, 0.95 }, spellColor = { 0.6, 0.35, 0.95 },     -- pale violet / void
    layers = glow({ 0.5, 0.2, 0.8 }, 0.35),
    motion = "rise", motionArgs = { speed = 22, sway = 10, freq = 3 },
    dur = 1.35, critDur = 1.7, critScale = 1.5, pop = 0.2,
    decor = { tex = "eye", size = { 40, 20 }, color = { 0.55, 0.25, 0.85 }, alpha = 0.25, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "eye", size = { 90, 45 }, color = { 0.55, 0.25, 0.85 }, alpha = 0.65, blend = "BLEND", snap = 0.2, snapTime = 0.15 },
    ring = { size = 60, color = { 0.45, 0.2, 0.75 }, grow = 2, alpha = 0.8 },
    critDecor2 = { tex = "ring", size = 40, color = { 0.7, 0.45, 1 }, alpha = 0.7, grow = 1.8, delay = 0.1 },
    particles = { tex = "eye", count = 0, critCount = 5, size = { 6, 9 }, aspect = 2, speed = { 20, 60 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.1 }, color = { 0.7, 0.45, 1 }, blend = "BLEND" },
})

add("swarm", {
    group = "faction", faction = "Qiraji",
    name = "Silithid Swarm", tagline = "Qiraji: twitching numbers crawl upward in a cloud of beetles.",
    font = F.friz, size = 24, outline = "OUTLINE",
    color = { 0.9, 0.75, 0.35 },
    physColor = { 0.95, 0.9, 0.75 }, spellColor = { 0.9, 0.7, 0.25 },      -- sand / amber
    layers = { { x = 2, y = -2, color = { 0.3, 0.2, 0.05, 1 } } },
    motion = "zap", motionArgs = { speed = 34, step = 0.05, jolt = 3 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.2,
    critDecor = { tex = "puff", size = 110, color = { 0.62, 0.48, 0.22 }, alpha = 0.6, blend = "BLEND", grow = 0.8, spin = 0.4 },
    ring = { size = 70, color = { 0.95, 0.8, 0.45 }, grow = 1.6, alpha = 0.7 },
    particles = { tex = "bug", count = 3, critCount = 16, size = { 9, 15 }, speed = { 50, 130 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.2 }, color = { 0.55, 0.42, 0.18 }, altColor = { 0.3, 0.24, 0.12 },
                  blend = "BLEND", orient = true, drag = 0.3, shrink = 0 },
})

add("tidecaller", {
    group = "faction", faction = "Hydraxian Waterlords",
    name = "Tidecaller", tagline = "Hydraxian Waterlords: numbers sway like the tide; crits splash out in rings and droplets.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.35, 0.7, 1 },
    physColor = { 0.88, 0.95, 1 }, spellColor = { 0.3, 0.65, 1 },          -- spray / deep water
    layers = { { x = 1.5, y = -1.5, color = { 0.05, 0.2, 0.4, 1 } } },
    motion = "rise", motionArgs = { speed = 30, sway = 8, freq = 5 },
    dur = 1.25, critDur = 1.55, critScale = 1.5, pop = 0.25,
    ring = { size = 60, color = { 0.5, 0.8, 1 }, grow = 2, alpha = 0.9 },
    critDecor = { tex = "ring", size = 40, color = { 0.7, 0.9, 1 }, alpha = 0.8, grow = 2, delay = 0.1 },
    particles = { tex = "drop", count = 1, critCount = 10, size = { 8, 12 }, aspect = 0.5, speed = { 70, 150 }, dir = { 50, 130 },
                  gravity = -380, life = { 0.5, 0.9 }, color = { 0.55, 0.82, 1 } },
})
