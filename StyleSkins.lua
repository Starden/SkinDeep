local _, ns = ...

-- More style skins (same data format as Skins.lua; see its header), three of
-- them seasonal. Each id matches its feat in Feats.lua. All art is SkinDeep's
-- own (tools/make_textures.js).

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

add("starfall", {
    name = "Starfall", tagline = "Starlit numbers drift among twinkling stars; crits loose shooting stars.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.6, 0.7, 1 }, physColor = { 0.9, 0.92, 1 }, spellColor = { 0.65, 0.55, 1 },  -- starlight / nebula
    layers = glow({ 0.7, 0.7, 1 }, 0.3),
    motion = "rise", motionArgs = { speed = 30, sway = 5, freq = 2 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0.25,
    ring = { size = 90, color = { 0.7, 0.75, 1 }, grow = 0.8, alpha = 0.5 },
    particles = { tex = "star", count = 2, critCount = 6, size = { 6, 12 }, speed = { 10, 40 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.4, 0.8 }, color = { 1, 1, 0.85 }, spin = 3 },
    particles2 = { tex = "star", count = 0, critCount = 4, size = { 8, 12 }, speed = { 120, 200 }, dir = { 200, 250 },
                   gravity = -60, life = { 0.5, 0.9 }, color = { 1, 0.95, 0.7 } },
})

add("gearworks", {
    name = "Gearworks", tagline = "Numbers tick upward over turning gears; crits spin up the works in a puff of steam.",
    font = F.friz, size = 24, outline = "OUTLINE",
    color = { 0.75, 0.68, 0.5 }, physColor = { 0.85, 0.82, 0.72 }, spellColor = { 0.4, 0.85, 0.95 },  -- brass / arc
    layers = { { x = 2, y = -2, color = { 0.25, 0.2, 0.1, 1 } } },
    motion = "hop", motionArgs = { step = 0.08, px = 5 },
    dur = 1.1, critDur = 1.4, critScale = 1.5, pop = 0.2,
    decor = { tex = "gear", size = 44, color = { 0.6, 0.52, 0.35 }, alpha = 0.35, spin = 2, blend = "BLEND" },
    critReplacesDecor = true,
    critDecor = { tex = "gear", size = 74, color = { 0.7, 0.6, 0.38 }, alpha = 0.85, spin = 4, blend = "BLEND" },
    critDecor2 = { tex = "gear", size = 36, x = 30, y = 18, color = { 0.78, 0.65, 0.38 }, alpha = 0.85, spin = -6, blend = "BLEND" },
    particles = { tex = "puff", count = 0, critCount = 4, size = { 16, 24 }, speed = { 20, 50 }, dir = { 60, 120 },
                  gravity = 10, life = { 0.5, 0.9 }, color = { 0.85, 0.85, 0.85 }, blend = "BLEND" },
})

add("murloc", {
    name = "Murloc Mayhem", tagline = "Wobbly numbers bubble up from the shallows; crits shout MRGLGL!",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 0.35, 0.75, 0.95 }, physColor = { 0.85, 0.95, 1 }, spellColor = { 0.3, 0.85, 0.75 },  -- foam / sea green
    layers = { { x = 2, y = -2, color = { 0.05, 0.2, 0.3, 1 } } },
    motion = "zap", motionArgs = { speed = 40, step = 0.07, jolt = 3 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.3,
    critTitle = { text = "MRGLGL!", y = 40, size = 16, font = F.skurri, pop = 1.3,
                  colors = { { 0.5, 1, 0.8 }, { 1, 1, 1 }, { 0.35, 0.75, 0.95 } }, shadowColor = { 0.02, 0.15, 0.2 } },
    particles = { tex = "bubble", count = 2, critCount = 9, size = { 6, 14 }, speed = { 15, 45 }, dir = { 70, 110 },
                  gravity = 30, life = { 0.6, 1.2 }, color = { 0.75, 0.95, 1 } },
})

add("hallows", {
    name = "Hallow's End", tagline = "Seasonal (October): flickering numbers with bats on the wing; crits light a jack-o'-lantern.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 1, 0.55, 0.1 }, physColor = { 0.95, 0.88, 0.7 }, spellColor = { 1, 0.55, 0.1 },  -- candlelight / pumpkin
    flicker = true,
    layers = { { x = 2, y = -2, color = { 0.2, 0.05, 0.25, 1 } } },
    motion = "rise", motionArgs = { speed = 34, sway = 4, freq = 8 },
    dur = 1.25, critDur = 1.55, critScale = 1.5, pop = 0.3,
    critDecor = { tex = "pumpkin", size = 70, color = { 1, 0.55, 0.08 }, alpha = 0.95, blend = "BLEND", snap = 0.2, snapTime = 0.12 },
    particles = { tex = "bat", count = 1, critCount = 6, size = { 9, 13 }, aspect = 2, speed = { 50, 110 }, dir = { 30, 150 },
                  gravity = 0, life = { 0.6, 1.1 }, color = { 0.25, 0.1, 0.3 }, blend = "BLEND" },
})

add("winterveil", {
    name = "Winter Veil", tagline = "Seasonal (December): numbers drift through falling snow; crits pop a wrapped gift.",
    font = F.morpheus, size = 25, outline = "OUTLINE",
    color = { 0.9, 0.2, 0.2 }, physColor = { 0.95, 0.97, 1 }, spellColor = { 0.92, 0.2, 0.22 },  -- snow / holly red
    layers = { { x = 2, y = -2, color = { 0.05, 0.25, 0.1, 1 } } },
    motion = "rise", motionArgs = { speed = 30, sway = 6, freq = 3 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0.3,
    critDecor = { tex = "gift", size = 58, color = { 0.2, 0.6, 0.25 }, alpha = 0.95, blend = "BLEND", snap = 0.2, snapTime = 0.12 },
    particles = { tex = "snowflake", count = 2, critCount = 10, size = { 6, 11 }, speed = { 10, 50 }, dir = { 0, 360 },
                  gravity = -30, life = { 0.8, 1.4 }, color = { 0.95, 0.98, 1 }, spin = 2 },
})

add("heartthrob", {
    name = "Heartthrob", tagline = "Seasonal (February): rosy numbers float up; crits beat like a heart and shower hearts.",
    font = F.friz, size = 24, outline = "OUTLINE",
    color = { 1, 0.45, 0.65 }, physColor = { 1, 0.88, 0.92 }, spellColor = { 1, 0.35, 0.6 },  -- blush / rose
    layers = glow({ 1, 0.5, 0.7 }, 0.3),
    motion = "rise", motionArgs = { speed = 32 },
    dur = 1.25, critDur = 1.55, critScale = 1.5, pop = 0.25,
    drum = { count = 2, gap = 0.18, amp = 0.2 },
    critDecor = { tex = "heart", size = 66, color = { 1, 0.3, 0.5 }, alpha = 0.9, blend = "BLEND", snap = 0.3, snapTime = 0.12 },
    particles = { tex = "heart", count = 1, critCount = 8, size = { 7, 12 }, speed = { 20, 60 }, dir = { 60, 120 },
                  gravity = 20, life = { 0.6, 1.1 }, color = { 1, 0.55, 0.75 }, blend = "BLEND" },
})
