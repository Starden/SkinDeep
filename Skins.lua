local _, ns = ...

-- Skin definitions. Every skin is pure data; Engine.lua turns it into
-- moving numbers. Fields:
--   name, tagline        shown in the picker
--   font, size, outline  the number's font (also Blizzard's world numbers, see worldFont)
--   shadow               { x, y } drop shadow offset, or nil
--   color, critColor     main text color; crits use critColor
--   critCycle            palette crits flash through ({ r, g, b } list), cyclePeriod seconds per color
--   flicker              text alpha flickers like a flame
--   layers               copies of the text drawn behind it: { x, y, color = { r, g, b, a }, trail }
--                        (trail = the x offset points away from the motion direction)
--   motion, motionArgs   path the number takes (see Engine.lua MOTIONS)
--   dur, critDur         seconds on screen; fade = share of that spent fading out
--   critScale, pop       crit size multiplier; pop = how much bigger it starts before settling
--   shake                crit screen-shake in pixels
--   decor, critDecor     textures behind the number: { tex, size, color, alpha, spin, grow, blend, rot }
--   ring                 crit shockwave ring: { size, color, grow, alpha }
--   particles            { tex, count, critCount, size = {min,max}, speed = {min,max}, dir = {deg,deg},
--                          gravity (px/s^2, + is up), life = {min,max}, color, blend, spin }
--   format, critFormat   text around the number ("%s" is the number)
--   world                engine CVars for Blizzard's own floating numbers (used when they are visible)

local FONTS = "Interface\\AddOns\\SkinDeep\\Media\\Fonts\\"
local F = {
    block = FONTS .. "SkinDeepBlock.ttf",
    led   = FONTS .. "SkinDeepLED.ttf",
    shard = FONTS .. "SkinDeepShard.ttf",
    slash = FONTS .. "SkinDeepSlash.ttf",
    friz     = "Fonts\\FRIZQT__.TTF",
    morpheus = "Fonts\\MORPHEUS.TTF",
    skurri   = "Fonts\\SKURRI.TTF",
    arialn   = "Fonts\\ARIALN.TTF",
}
ns.Fonts = F

ns.Skins = {}
ns.SkinOrder = {}

local function add(id, skin)
    skin.id = id
    ns.Skins[id] = skin
    ns.SkinOrder[#ns.SkinOrder + 1] = id
end
-- Skins with their own machinery register from their own files (Jackpot.lua).
ns.AddSkin = add

add("classic", {
    name = "Classic+", tagline = "Blizzard's look, with a cleaner pop on crits.",
    font = F.friz, size = 24, outline = "OUTLINE",
    color = { 1, 0.82, 0 }, critColor = { 1, 1, 1 },
    motion = "rise", motionArgs = { speed = 55 },
    dur = 1.0, critDur = 1.3, critScale = 1.6, pop = 0.35,
    world = {},
    ring = { size = 56, color = { 1, 1, 1 }, grow = 1.4, alpha = 0.5 },
    particles = { tex = "spark", count = 0, critCount = 6, size = { 3, 5 }, speed = { 40, 100 }, dir = { 30, 150 },
                  gravity = -200, life = { 0.3, 0.6 }, color = { 1, 1, 0.9 } },
})

add("ember", {
    name = "Ember Tide", tagline = "Flickering fire numbers that drift up on a trail of embers.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.55, 0.12 }, critColor = { 1, 0.9, 0.35 },
    flicker = true,
    layers = { { x = 1.5, y = -1.5, color = { 0.5, 0.05, 0, 0.9 } } },
    motion = "rise", motionArgs = { speed = 70, sway = 10, freq = 7 },
    dur = 1.1, critDur = 1.4, critScale = 1.6, pop = 0.5,
    critDecor = { tex = "burst", size = 120, color = { 1, 0.45, 0.05 }, alpha = 0.85, spin = 1.5, grow = 0.5 },
    particles = { tex = "spark", count = 3, critCount = 10, size = { 4, 9 }, speed = { 20, 70 }, dir = { 60, 120 },
                  gravity = 60, life = { 0.5, 1.1 }, color = { 1, 0.5, 0.1 } },
    world = { WorldTextScale = 1.15, WorldTextRampDuration = 1.2, floatingCombatTextCombatDamageDirectionalScale = 0 },
    critDecor2 = { tex = "flame", size = { 44, 74 }, y = 16, color = { 1, 0.55, 0.12 }, alpha = 0.85, snap = 0.3, snapTime = 0.12 },
    ring = { size = 64, color = { 1, 0.6, 0.2 }, grow = 1.6, alpha = 0.8 },
})

add("frost", {
    name = "Frostbite", tagline = "Crystal numbers slam in, crack, and shed ice shards.",
    font = F.shard, size = 30, outline = "OUTLINE",
    color = { 0.6, 0.9, 1 }, critColor = { 0.92, 1, 1 },
    layers = {
        { x = -1.5, y = 1.5, color = { 0.1, 0.3, 0.75, 0.85 } },
        { x = 1.5, y = -1.5, color = { 0.05, 0.15, 0.45, 0.85 } },
    },
    motion = "slam", motionArgs = { from = 2.2, time = 0.14, drift = 18 },
    dur = 1.0, critDur = 1.35, critScale = 1.5, pop = 0, shake = 4,
    ring = { size = 140, color = { 0.6, 0.9, 1 }, grow = 1.2, alpha = 0.9 },
    particles = { tex = "shard", count = 0, critCount = 8, size = { 8, 14 }, speed = { 90, 160 }, dir = { 0, 360 },
                  gravity = -220, life = { 0.4, 0.8 }, color = { 0.7, 0.95, 1 }, spin = 6 },
    world = { WorldTextScale = 1.0, WorldTextRampDuration = 0.6, WorldTextGravity = 1.2 },
    critDecor = { tex = "snowflake", size = 100, color = { 0.5, 0.78, 1 }, alpha = 0.5, spin = 1.2, snap = 0.3, snapTime = 0.12 },
    critDecor2 = { tex = "burst", size = 130, color = { 0.55, 0.85, 1 }, alpha = 0.4, spin = 0.5 },
})

add("arcane", {
    name = "Arcane Sigil", tagline = "Dotted runic digits spiral out of a turning sigil.",
    font = F.led, size = 30, outline = "OUTLINE",
    color = { 0.85, 0.5, 1 }, critColor = { 1, 0.78, 1 },
    layers = {
        { x = 1, y = 1, color = { 0.45, 0.1, 0.85, 0.5 } },
        { x = -1, y = -1, color = { 0.45, 0.1, 0.85, 0.5 } },
        { x = 1, y = -1, color = { 0.45, 0.1, 0.85, 0.5 } },
        { x = -1, y = 1, color = { 0.45, 0.1, 0.85, 0.5 } },
        { x = 2, y = -2, color = { 0.1, 0.02, 0.22, 1 } },
    },
    motion = "spiral", motionArgs = { r0 = 8, grow = 35, spin = 4, rise = 30 },
    dur = 1.2, critDur = 1.5, critScale = 1.5, pop = 0.3,
    decor = { tex = "rune", size = 76, color = { 0.6, 0.3, 0.95 }, alpha = 0.28, spin = 1.2 },
    critDecor = { tex = "rune", size = 150, color = { 0.9, 0.45, 1 }, alpha = 0.6, spin = -2, grow = 0.4 },
    particles = { tex = "twinkle", count = 2, critCount = 7, size = { 8, 16 }, speed = { 15, 45 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.2 }, color = { 1, 0.6, 1 } },
    world = { floatingCombatTextCombatDamageDirectionalScale = 2 },
    ring = { size = 70, color = { 0.8, 0.5, 1 }, grow = 1.6, alpha = 0.8 },
    particles2 = { tex = "twinkle", count = 0, critCount = 6, size = { 10, 16 }, speed = { 60, 120 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.4, 0.7 }, color = { 1, 0.8, 1 } },
})

add("comic", {
    name = "Kaboom!", tagline = "Chunky 3D comic numbers that bounce, with POW bursts on crits.",
    font = F.skurri, size = 30, outline = "THICKOUTLINE",
    color = { 1, 0.92, 0.2 }, critColor = { 1, 1, 1 },
    layers = {
        { x = 2, y = -2, color = { 0.9, 0.3, 0.05, 1 } },
        { x = 4, y = -4, color = { 0.6, 0.1, 0, 1 } },
        { x = 6, y = -6, color = { 0.2, 0, 0, 1 } },
    },
    motion = "bounce", motionArgs = { vx = { 40, 80 }, vy = 170, gravity = 520, floor = -30, damp = 0.45 },
    dur = 1.2, critDur = 1.5, critScale = 1.6, pop = 0.6, shake = 3,
    critFormat = "%s!",
    critDecor = { tex = "burst", size = 150, color = { 1, 0.25, 0.1 }, alpha = 1, spin = 0.6, blend = "BLEND" },
    ring = { size = 120, color = { 1, 1, 1 }, grow = 0.8, alpha = 0.8 },
    world = { WorldTextScale = 1.3 },
    critTitle = { text = "POW!", y = 46, size = 18, font = F.skurri, pop = 1.6,
                  colors = { { 1, 0.9, 0.2 }, { 1, 1, 1 }, { 1, 0.3, 0.1 } }, shadowColor = { 0.4, 0.05, 0 } },
    particles = { tex = "star", count = 0, critCount = 8, size = { 8, 14 }, speed = { 80, 160 }, dir = { 0, 360 },
                  gravity = -100, life = { 0.4, 0.8 }, color = { 1, 0.9, 0.2 }, altColor = { 1, 0.35, 0.1 } },
})

add("blood", {
    name = "Bloodmoon Ink", tagline = "Gothic numbers splash onto ink blots and slowly drip away.",
    font = F.morpheus, size = 30, outline = "OUTLINE",
    color = { 0.92, 0.1, 0.12 }, critColor = { 1, 0.3, 0.25 },
    layers = { { x = 1, y = -2, color = { 0.15, 0, 0, 1 } } },
    motion = "drip", motionArgs = { hold = 0.3, speed = 6, accel = 70 },
    dur = 1.3, critDur = 1.6, critScale = 1.5, pop = 0.5,
    decor = { tex = "splat", size = 70, color = { 0.4, 0, 0.02 }, alpha = 0.75, blend = "BLEND", randomRot = true },
    critDecor = { tex = "splat", size = 125, color = { 0.55, 0, 0.03 }, alpha = 0.9, blend = "BLEND", randomRot = true, grow = 0.15 },
    particles = { tex = "glow", count = 1, critCount = 6, size = { 5, 9 }, speed = { 40, 110 }, dir = { 200, 340 },
                  gravity = -400, life = { 0.5, 0.9 }, color = { 0.6, 0, 0.02 }, blend = "BLEND" },
    world = { WorldTextScale = 1.1, WorldTextGravity = 2 },
    critDecor2 = { tex = "splat", size = 70, x = 26, y = -16, color = { 0.4, 0, 0.02 }, alpha = 0.8, blend = "BLEND", randomRot = true, delay = 0.08 },
    particles2 = { tex = "drop", count = 0, critCount = 6, size = { 5, 8 }, aspect = 0.6, speed = { 20, 60 }, dir = { 250, 290 },
                   gravity = -260, life = { 0.5, 0.9 }, color = { 0.5, 0, 0.03 }, blend = "BLEND", drag = 0, shrink = 0 },
})

add("arcade", {
    name = "Retro Arcade", tagline = "Pixel numbers hop up in steps; crits flash every color.",
    font = F.block, size = 28, outline = "OUTLINE, MONOCHROME",
    color = { 0.3, 1, 0.5 }, critColor = { 1, 1, 0.3 },
    critCycle = { { 1, 0.2, 0.6 }, { 0.2, 1, 1 }, { 1, 1, 0.2 }, { 0.4, 1, 0.3 } }, cyclePeriod = 0.07,
    layers = { { x = 3, y = -3, color = { 0, 0, 0, 1 } } },
    motion = "hop", motionArgs = { step = 0.06, px = 7 }, blink = true,
    dur = 1.0, critDur = 1.4, critScale = 1.5, pop = 0,
    critFormat = "%s!",
    particles = { tex = "pixel", count = 2, critCount = 12, size = { 4, 6 }, speed = { 60, 140 }, dir = { 0, 360 },
                  gravity = -200, life = { 0.4, 0.8 }, color = { 1, 1, 0.3 }, blend = "BLEND", randomColor = true },
    world = { WorldTextScale = 0.9 },
    critTitle = { text = "HIGH SCORE!", y = 44, size = 13, font = F.block, pop = 1.3, cycleFor = 9, period = 0.07,
                  colors = { { 1, 0.2, 0.6 }, { 0.2, 1, 1 }, { 1, 1, 0.2 }, { 0.4, 1, 0.3 } }, shadowColor = { 0, 0, 0 } },
    ring = { size = 60, color = { 0.2, 1, 1 }, grow = 1.4, alpha = 0.7 },
})

add("gilded", {
    name = "Gilded Hoard", tagline = "Beveled gold numbers tossed like coins, glinting as they fall.",
    font = F.friz, size = 26, outline = "THICKOUTLINE",
    color = { 1, 0.8, 0.25 }, critColor = { 1, 0.95, 0.6 },
    layers = {
        { x = -1, y = 1, color = { 1, 0.97, 0.75, 1 } },
        { x = 1.5, y = -1.5, color = { 0.45, 0.28, 0.02, 1 } },
        { x = 3, y = -3, color = { 0.2, 0.12, 0, 1 } },
    },
    motion = "toss", motionArgs = { vx = { 50, 110 }, vy = 150, gravity = 380 },
    dur = 1.1, critDur = 1.4, critScale = 1.55, pop = 0.4,
    critDecor = { tex = "glow", size = 110, color = { 1, 0.8, 0.2 }, alpha = 0.8, grow = 0.3 },
    ring = { size = 110, color = { 1, 0.85, 0.3 }, grow = 0.9, alpha = 0.7 },
    particles = { tex = "twinkle", count = 1, critCount = 6, size = { 8, 14 }, speed = { 20, 60 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 1.0 }, color = { 1, 0.9, 0.4 } },
    world = { WorldTextGravity = 1.5, floatingCombatTextCombatDamageDirectionalScale = 1.5 },
})

add("blade", {
    name = "Swiftblade", tagline = "Slanted steel numbers dash sideways with a motion trail.",
    font = F.slash, size = 28, outline = "OUTLINE",
    color = { 0.92, 0.95, 1 }, critColor = { 1, 1, 1 },
    layers = {
        { x = 6, y = 0, color = { 0.6, 0.75, 1, 0.35 }, trail = true },
        { x = 12, y = 0, color = { 0.6, 0.75, 1, 0.15 }, trail = true },
    },
    motion = "dash", motionArgs = { dist = 70, time = 0.25, rise = 20 },
    dur = 0.9, critDur = 1.2, critScale = 1.5, pop = 0.2, shake = 2,
    critDecor = { tex = "slash", size = { 180, 45 }, color = { 0.7, 0.85, 1 }, alpha = 0.9, rot = 0.35, grow = 0.4 },
    particles = { tex = "spark", count = 0, critCount = 5, size = { 3, 6 }, speed = { 80, 160 }, dir = { -15, 15 },
                  gravity = 0, life = { 0.2, 0.45 }, color = { 0.8, 0.9, 1 }, mirror = true },
    world = { floatingCombatTextCombatDamageDirectionalScale = 2, WorldTextRampDuration = 0.7 },
    critDecor2 = { tex = "slash", size = { 160, 40 }, color = { 1, 1, 1 }, alpha = 0.8, rot = -0.45, grow = 0.3, delay = 0.06 },
    ring = { size = 50, color = { 0.7, 0.85, 1 }, grow = 1.8, alpha = 0.6 },
})

-- Damage-type palettes for the "Skin palette" color scheme: { physical, spell }.
-- Like Blizzard's white/yellow, physical is the paler tone and spell the
-- stronger one, so the two read apart the same way in every skin.
ns.CLASSIC_PHYSICAL = { 1, 1, 1 }
ns.CLASSIC_SPELL = { 1, 0.82, 0 }
local PALETTES = {
    classic = { ns.CLASSIC_PHYSICAL, ns.CLASSIC_SPELL },
    ember   = { { 1, 0.78, 0.55 },   { 1, 0.55, 0.1 } },     -- warm ash / flame
    frost   = { { 0.88, 0.96, 1 },   { 0.35, 0.78, 1 } },    -- frost white / ice blue
    arcane  = { { 0.93, 0.86, 1 },   { 0.82, 0.4, 1 } },     -- lilac / violet
    comic   = { { 1, 1, 1 },         { 1, 0.9, 0.15 } },     -- white / comic yellow
    blood   = { { 0.93, 0.86, 0.78 }, { 0.95, 0.1, 0.12 } }, -- bone / blood
    arcade  = { { 0.55, 1, 0.6 },    { 1, 0.3, 0.85 } },     -- green / magenta
    gilded  = { { 0.9, 0.9, 0.95 },  { 1, 0.78, 0.2 } },     -- silver / gold
    blade   = { { 0.95, 0.97, 1 },   { 0.5, 0.75, 1 } },     -- steel / blue steel
}
for id, pal in pairs(PALETTES) do
    ns.Skins[id].physColor, ns.Skins[id].spellColor = pal[1], pal[2]
end
