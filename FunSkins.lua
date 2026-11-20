local _, ns = ...

-- Fun skins: original takes on pop culture (tabletop dice, 80s neon, VHS
-- glitches, disco, a classic Azeroth menace), each earned by a secret feat
-- (Feats.lua): the Feats tab shows only a riddle until it's done.

local F = ns.Fonts
local add = ns.AddSkin

local GOLD = { 1, 0.82, 0.3 }

add("natural20", {
    group = "fun", listNote = "Secret",
    name = "Natural 20", tagline = "Hits tumble out on a spinning d20; crits land the die on 20 with a gold flash and NAT 20!",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 0.78, 0.7, 1 }, physColor = { 0.88, 0.84, 1 }, spellColor = { 0.66, 0.5, 1 },
    layers = { { x = 2, y = -2, color = { 0.1, 0.05, 0.28, 1 } } },
    motion = "rise", motionArgs = { speed = 32 },
    dur = 1.2, critDur = 1.7, critScale = 1.55, pop = 0.25,
    decor = { tex = "d20", size = 18, x = 26, y = 8, color = { 0.5, 0.36, 0.9 }, alpha = 0.95, blend = "BLEND", spin = 7 },
    critReplacesDecor = true,
    critDecor = { tex = "d20", size = 44, y = 46, color = GOLD, alpha = 1, blend = "BLEND", snap = 1.8, snapTime = 0.35, unwind = 9 },
    critTitle = { text = "NAT 20!", y = 78, size = 17, font = F.morpheus, pop = 1.5, delay = 0.35,
                  colors = { GOLD, { 1, 1, 1 }, { 0.75, 0.6, 1 } }, shadowColor = { 0.25, 0.15, 0 } },
    particles = { tex = "twinkle", count = 0, critCount = 12, size = { 9, 15 }, speed = { 40, 110 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.6, 1.1 }, color = GOLD, altColor = { 0.85, 0.75, 1 } },
})

add("synthwave", {
    group = "fun", listNote = "Secret",
    name = "Synthwave", tagline = "Chrome pink numbers with a cyan edge; crits rise over a neon sun and a glowing grid.",
    font = F.block, size = 24, outline = "OUTLINE",
    color = { 1, 0.42, 0.84 }, physColor = { 1, 0.62, 0.92 }, spellColor = { 0.35, 0.9, 1 },
    layers = { { x = 0, y = -2, color = { 0.15, 0.85, 0.95, 0.9 } }, { x = 2, y = -4, color = { 0.18, 0.02, 0.25, 1 } } },
    motion = "rise", motionArgs = { speed = 30 },
    dur = 1.3, critDur = 1.7, critScale = 1.55, pop = 0.25,
    critDecor = { tex = "synthsun", size = 72, y = 16, color = { 1, 0.45, 0.62 }, alpha = 0.95, blend = "BLEND", snap = 0.3, snapTime = 0.2 },
    critDecor2 = { tex = "synthgrid", size = { 160, 70 }, y = -22, color = { 0.2, 0.85, 1 }, alpha = 0.85, snap = 0.5, snapTime = 0.25 },
    particles = { tex = "twinkle", count = 0, critCount = 8, size = { 8, 13 }, speed = { 20, 70 }, dir = { 20, 160 },
                  gravity = 0, life = { 0.6, 1.1 }, color = { 1, 0.5, 0.9 }, altColor = { 0.3, 0.9, 1 } },
})

add("glitch", {
    group = "fun", listNote = "Secret",
    name = "Glitch", tagline = "Numbers jitter with a split red and cyan echo; crits stutter through colors and shed broken pixels.",
    font = F.block, size = 23, outline = "OUTLINE",
    color = { 1, 1, 1 }, physColor = { 1, 1, 1 }, spellColor = { 0.75, 1, 1 },
    layers = { { x = -2, y = 0, color = { 1, 0.15, 0.3, 0.85 } }, { x = 2, y = 0, color = { 0.15, 0.9, 1, 0.85 } },
               { x = 1, y = -2, color = { 0, 0, 0, 1 } } },
    motion = "zap", motionArgs = { speed = 30, step = 0.04, jolt = 4 },
    flicker = true,
    dur = 1.1, critDur = 1.4, critScale = 1.5, pop = 0.2,
    critCycle = { { 1, 1, 1 }, { 1, 0.2, 0.35 }, { 0.2, 0.95, 1 }, { 1, 1, 1 }, { 0.6, 1, 0.3 } }, cyclePeriod = 0.05,
    -- Tear bars: flickering beams laid sideways across the number.
    critDecor = { tex = "beam", size = { 10, 150 }, y = 5, rot = 1.5708, color = { 0.2, 0.95, 1 }, alpha = 0.7, flicker = true },
    critDecor2 = { tex = "beam", size = { 8, 130 }, y = -7, rot = 1.5708, color = { 1, 0.2, 0.4 }, alpha = 0.7, flicker = true },
    particles = { tex = "pixel", count = 1, critCount = 14, size = { 3, 7 }, speed = { 20, 110 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.25, 0.6 }, color = { 1, 0.2, 0.35 }, altColor = { 0.2, 0.95, 1 }, drag = 2, shrink = 0 },
})

add("discofever", {
    group = "fun", listNote = "Secret",
    name = "Disco Fever", tagline = "Numbers bounce to the beat; crits drop a spinning disco ball and flash every color of the floor.",
    font = F.block, size = 24, outline = "OUTLINE",
    color = { 1, 0.4, 0.85 }, physColor = { 1, 0.6, 0.92 }, spellColor = { 0.5, 0.75, 1 },
    layers = { { x = 2, y = -2, color = { 0.2, 0.02, 0.25, 1 } } },
    motion = "bounce", motionArgs = { vx = { -8, 8 }, vy = 120, gravity = 520, floor = -4, damp = 0.6 },
    dur = 1.25, critDur = 1.7, critScale = 1.55, pop = 0.2,
    critCycle = { { 1, 0.3, 0.5 }, { 1, 0.75, 0.2 }, { 0.4, 1, 0.4 }, { 0.3, 0.8, 1 }, { 0.75, 0.4, 1 } }, cyclePeriod = 0.09,
    critDecor = { tex = "discoball", size = 36, y = 52, color = { 0.92, 0.94, 1 }, alpha = 1, blend = "BLEND", spin = 2, snap = 0.3, snapTime = 0.15 },
    critDecor2 = { tex = "burst", size = 150, y = 30, color = { 1, 0.45, 0.85 }, alpha = 0.55, spin = 1.6 },
    particles = { tex = "twinkle", count = 1, critCount = 14, size = { 8, 14 }, speed = { 30, 110 }, dir = { 0, 360 },
                  gravity = 0, life = { 0.5, 1.0 }, randomColor = true },
})

add("bunnyhop", {
    group = "fun", listNote = "Secret",
    name = "Bunny Hop", tagline = "Numbers spring along in hops; crits bounce off a coiled spring with a BOING!",
    font = F.block, size = 23, outline = "THICKOUTLINE",
    color = { 0.6, 0.85, 1 }, physColor = { 0.88, 0.95, 1 }, spellColor = { 0.45, 0.75, 1 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.12, 0.25, 1 } } },
    motion = "bounce", motionArgs = { vx = { 30, 45 }, vy = 170, gravity = 720, floor = -6, damp = 0.6 },
    dur = 1.2, critDur = 1.6, critScale = 1.5, pop = 0.15,
    critDecor = { tex = "spring", size = { 22, 46 }, y = -30, color = { 0.8, 0.84, 0.9 }, alpha = 1, blend = "BLEND", snap = 0.4, snapTime = 0.18 },
    critTitle = { text = "BOING!", y = 46, size = 17, font = F.block, pop = 1.6,
                  colors = { { 1, 0.9, 0.4 }, { 1, 1, 1 }, { 0.6, 0.85, 1 } }, shadowColor = { 0.25, 0.18, 0 } },
    particles = { tex = "puff", count = 0, critCount = 5, size = { 8, 14 }, speed = { 20, 60 }, dir = { 160, 380 },
                  gravity = 0, life = { 0.4, 0.8 }, color = { 0.85, 0.85, 0.85 }, blend = "BLEND" },
})

add("graveyard", {
    group = "fun", listNote = "Secret",
    name = "Graveyard Shift", tagline = "Pale, flickering numbers rise from a tombstone; crits set loose a wailing wisp.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 0.7, 1, 0.88 }, physColor = { 0.85, 1, 0.94 }, spellColor = { 0.55, 1, 0.8 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.15, 0.1, 1 } } },
    motion = "rise", motionArgs = { speed = 30, sway = 3, freq = 3 },
    fadeIn = 0.2, flicker = true,
    dur = 1.3, critDur = 1.7, critScale = 1.5, pop = 0.2,
    decor = { tex = "tombstone", size = { 22, 30 }, y = -26, color = { 0.45, 0.48, 0.55 }, alpha = 0.8, blend = "BLEND" },
    particles = { tex = "puff", count = 0, critCount = 8, size = { 12, 20 }, speed = { 20, 50 }, dir = { 70, 110 },
                  gravity = 10, life = { 0.8, 1.3 }, color = { 0.6, 1, 0.82 }, sway = true },
    critReplacesDecor = true,
    critDecor = { tex = "tombstone", size = { 40, 54 }, y = -24, color = { 0.55, 0.6, 0.68 }, alpha = 0.95, blend = "BLEND", snap = 0.4, snapTime = 0.15 },
    particles2 = { tex = "skull", count = 0, critCount = 1, size = { 16, 20 }, speed = { 30, 40 }, dir = { 85, 95 },
                   gravity = 0, life = { 0.9, 1.1 }, color = { 0.65, 1, 0.85 }, drag = 0, shrink = 0 },
})

add("hogger", {
    group = "fun", listNote = "Secret",
    name = "Hogger!", tagline = "Rough, gnoll-scrawled numbers; crits shake the screen with a roaring HOGGER! and flying claw marks.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 0.95, 0.75, 0.45 }, physColor = { 0.98, 0.86, 0.66 }, spellColor = { 1, 0.6, 0.25 },
    layers = { { x = 2, y = -2, color = { 0.25, 0.1, 0.02, 1 } } },
    motion = "drop", motionArgs = { height = 40, fall = 0.11, squash = 0.35, sinkAt = 0.4, sink = 10 },
    dur = 1.15, critDur = 1.6, critScale = 1.6, pop = 0, shake = 9,
    critDecor = { tex = "claws", size = 110, color = { 0.85, 0.55, 0.25 }, alpha = 1, snap = 0.1, snapTime = 0.08 },
    critTitle = { text = "HOGGER!", y = 50, size = 21, font = F.skurri, pop = 1.6,
                  colors = { { 1, 0.6, 0.2 }, { 1, 0.9, 0.5 }, { 0.9, 0.2, 0.1 } }, shadowColor = { 0.25, 0.08, 0 } },
    particles = { tex = "pixel", count = 0, critCount = 10, size = { 4, 7 }, speed = { 60, 140 }, dir = { 20, 160 },
                  gravity = -300, life = { 0.4, 0.8 }, color = { 0.55, 0.36, 0.18 }, altColor = { 0.8, 0.55, 0.3 }, blend = "BLEND", spin = 6 },
})

---------------------------------------------------------------------------
-- Anime-inspired (original takes on the genre)
---------------------------------------------------------------------------
add("powersurge", {
    group = "fun", listNote = "Secret",
    name = "Power Surge", tagline = "Numbers burn in a rising golden aura; crits flare it wide, crackle with energy and shake the screen.",
    font = F.skurri, size = 28, outline = "THICKOUTLINE",
    color = { 1, 0.86, 0.35 }, physColor = { 1, 0.97, 0.85 }, spellColor = { 1, 0.8, 0.25 },
    layers = { { x = 2, y = -2, color = { 0.35, 0.18, 0, 1 } } },
    motion = "rise", motionArgs = { speed = 24 },
    dur = 1.25, critDur = 1.7, critScale = 1.6, pop = 0, shake = 6,
    drum = { count = 2, gap = 0.12, amp = 0.18 },
    decor = { tex = "aura", size = { 56, 76 }, y = 16, color = { 1, 0.82, 0.25 }, alpha = 0.55, flicker = true },
    critReplacesDecor = true,
    critDecor = { tex = "aura", size = { 86, 118 }, y = 22, color = { 1, 0.85, 0.3 }, alpha = 0.9, flicker = true, snap = 0.4, snapTime = 0.12 },
    critDecor2 = { tex = "bolt", size = { 22, 80 }, color = { 1, 0.97, 0.75 }, alpha = 1, flicker = true, randomRot = true },
    particles = { tex = "glow", count = 2, critCount = 14, size = { 3, 6 }, speed = { 40, 110 }, dir = { 70, 110 },
                  gravity = 20, life = { 0.4, 0.8 }, color = { 1, 0.9, 0.4 }, altColor = { 1, 1, 0.85 } },
})

add("finalmove", {
    group = "fun", listNote = "Secret",
    name = "Final Move", tagline = "Sharp numbers dash in on speed lines; crits slash a diagonal cut-in banner that calls CRITICAL!",
    font = F.skurri, size = 27, outline = "THICKOUTLINE",
    color = { 0.95, 0.96, 1 }, physColor = { 0.97, 0.98, 1 }, spellColor = { 1, 0.45, 0.55 },
    layers = { { x = 2, y = -2, color = { 0.08, 0.02, 0.05, 1 } } },
    motion = "dash", motionArgs = { arrive = true, dist = 60, time = 0.12, rise = 16 },
    dur = 1.15, critDur = 1.55, critScale = 1.55, pop = 0.15,
    decor = { tex = "speedlines", size = { 90, 40 }, x = 46, trail = true, color = { 0.85, 0.9, 1 }, alpha = 0.55 },
    critReplacesDecor = true,
    critDecor = { tex = "band", size = { 230, 34 }, y = 34, rot = 0.18, color = { 0.85, 0.08, 0.25 }, alpha = 0.95, blend = "BLEND", snap = 0.2, snapTime = 0.1 },
    critDecor2 = { tex = "speedlines", size = { 150, 70 }, x = 50, trail = true, color = { 1, 1, 1 }, alpha = 0.7 },
    critTitle = { text = "CRITICAL!", y = 34, size = 16, font = F.skurri, pop = 1.3,
                  colors = { { 1, 1, 1 }, { 1, 0.85, 0.3 }, { 1, 1, 1 } }, shadowColor = { 0.1, 0, 0.03 } },
    particles = { tex = "shard", count = 0, critCount = 8, size = { 6, 10 }, speed = { 80, 180 }, dir = { -20, 20 },
                  gravity = 0, life = { 0.2, 0.4 }, color = { 1, 1, 1 }, mirror = true },
})

add("sakura", {
    group = "fun", listNote = "Secret",
    name = "Sakura Drift", tagline = "Soft pink numbers drift on a breeze of cherry petals; crits burst a whirl of blossoms.",
    font = F.morpheus, size = 23, outline = "OUTLINE",
    color = { 1, 0.72, 0.85 }, physColor = { 1, 0.86, 0.92 }, spellColor = { 0.98, 0.55, 0.75 },
    layers = { { x = 2, y = -2, color = { 0.3, 0.05, 0.15, 1 } } },
    motion = "rise", motionArgs = { speed = 26, sway = 5, freq = 3 },
    dur = 1.35, critDur = 1.8, critScale = 1.5, pop = 0.2,
    particles = { tex = "petal", count = 4, critCount = 20, size = { 9, 14 }, speed = { 15, 70 }, dir = { 0, 360 },
                  gravity = -18, life = { 0.9, 1.6 }, color = { 1, 0.72, 0.85 }, altColor = { 1, 0.9, 0.95 },
                  blend = "BLEND", spin = 4, sway = true, drag = 1.4, shrink = 0.15 },
    critDecor = { tex = "bloom", size = 90, color = { 1, 0.72, 0.85 }, alpha = 0.7, spin = 0.6, blend = "BLEND", snap = 0.4, snapTime = 0.2 },
})

add("mechastrike", {
    group = "fun", listNote = "Secret",
    name = "Mecha Strike", tagline = "Steel numbers locked in HUD brackets; crits turn the brackets red, fire a salvo and read TARGET LOCKED.",
    font = F.led, size = 23, outline = "OUTLINE",
    color = { 0.85, 0.93, 1 }, physColor = { 0.9, 0.95, 1 }, spellColor = { 0.4, 0.9, 1 },
    layers = { { x = 2, y = -2, color = { 0.03, 0.1, 0.15, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.2, critDur = 1.6, critScale = 1.5, pop = 0.2,
    decor = { tex = "brackets", size = { 76, 40 }, color = { 0.37, 0.88, 1 }, alpha = 0.8, snap = 1.4, snapTime = 0.12 },
    critReplacesDecor = true,
    critDecor = { tex = "brackets", size = { 96, 50 }, color = { 1, 0.35, 0.2 }, alpha = 1, snap = 1.6, snapTime = 0.1 },
    critTitle = { text = "TARGET LOCKED", y = 44, size = 13, font = F.led, pop = 1.2,
                  colors = { { 1, 0.5, 0.35 }, { 1, 1, 1 }, { 1, 0.3, 0.2 } }, shadowColor = { 0.15, 0.02, 0 } },
    particles = { tex = "spark", count = 0, critCount = 6, size = { 8, 12 }, aspect = 0.4, speed = { 160, 220 }, dir = { 15, 40 },
                  gravity = 0, life = { 0.25, 0.4 }, color = { 1, 0.85, 0.5 }, orient = true, drag = 0, mirror = true },
})

---------------------------------------------------------------------------
-- Music-inspired
---------------------------------------------------------------------------
add("bassdrop", {
    group = "fun", listNote = "Secret",
    name = "Bass Drop", tagline = "Numbers pulse over equalizer bars; crits beat four times, drop a heavy shockwave and call DROP!",
    font = F.block, size = 24, outline = "THICKOUTLINE",
    color = { 0.85, 0.65, 1 }, physColor = { 0.94, 0.9, 1 }, spellColor = { 0.35, 0.85, 1 },
    layers = { { x = 2, y = -2, color = { 0.1, 0.02, 0.2, 1 } } },
    motion = "rise", motionArgs = { speed = 18 },
    dur = 1.25, critDur = 1.75, critScale = 1.55, pop = 0.2, shake = 4,
    drum = { count = 4, gap = 0.12, amp = 0.16 },
    decor = { tex = "eqbars", size = { 64, 30 }, y = -22, color = { 0.4, 0.8, 1 }, alpha = 0.7, flicker = true },
    critReplacesDecor = true,
    critDecor = { tex = "eqbars", size = { 110, 52 }, y = -30, color = { 0.65, 0.45, 1 }, alpha = 0.95, flicker = true, snap = 0.3, snapTime = 0.1 },
    ring = { size = 70, color = { 0.66, 0.33, 0.97 }, grow = 2.4, alpha = 1 },
    critTitle = { text = "DROP!", y = 46, size = 18, font = F.block, pop = 1.6, delay = 0.36,
                  colors = { { 0.9, 0.8, 1 }, { 0.35, 0.85, 1 }, { 1, 0.45, 0.85 } }, shadowColor = { 0.1, 0.02, 0.2 } },
})

add("lofi", {
    group = "fun", listNote = "Secret",
    name = "Lo-Fi", tagline = "Mellow, muted numbers beside a slowly spinning record; crits patter soft rain and drifting notes.",
    font = F.morpheus, size = 22, outline = "OUTLINE",
    color = { 0.9, 0.84, 0.76 }, physColor = { 0.92, 0.88, 0.82 }, spellColor = { 0.9, 0.65, 0.78 },
    layers = { { x = 2, y = -2, color = { 0.15, 0.12, 0.1, 1 } } },
    motion = "rise", motionArgs = { speed = 16 },
    fadeIn = 0.15,
    dur = 1.5, critDur = 1.9, critScale = 1.3, pop = 0.1,
    decor = { tex = "vinyl", size = 32, x = 42, color = { 0.95, 0.65, 0.78 }, alpha = 0.9, blend = "BLEND", spin = 2.2 },
    critReplacesDecor = true,
    critDecor = { tex = "vinyl", size = 54, x = 50, color = { 0.95, 0.65, 0.78 }, alpha = 0.95, blend = "BLEND", spin = 2.6, snap = 0.5, snapTime = 0.25 },
    particles = { tex = "drop", count = 0, critCount = 10, size = { 3, 5 }, aspect = 0.4, speed = { 90, 130 }, dir = { 260, 280 },
                  gravity = -60, life = { 0.5, 0.8 }, color = { 0.62, 0.7, 0.8 }, drag = 0, shrink = 0 },
    particles2 = { tex = "note", count = 0, critCount = 5, size = { 10, 14 }, aspect = 0.67, speed = { 15, 30 }, dir = { 60, 120 },
                   gravity = 0, life = { 1.0, 1.4 }, color = { 0.95, 0.65, 0.78 }, altColor = { 0.79, 0.84, 0.91 }, sway = true },
})

add("karaoke", {
    group = "fun", listNote = "Secret",
    name = "Karaoke", tagline = "Numbers shine in a spotlight beside the mic; crits light up in every color and send notes flying.",
    font = F.morpheus, size = 24, outline = "THICKOUTLINE",
    color = { 1, 1, 1 }, physColor = { 1, 1, 1 }, spellColor = { 0.37, 0.88, 1 },
    layers = { { x = 2, y = -2, color = { 0.1, 0.06, 0.2, 1 } } },
    motion = "rise", motionArgs = { speed = 20 },
    dur = 1.3, critDur = 1.7, critScale = 1.5, pop = 0.2,
    decor = { tex = "mic", size = { 14, 28 }, x = -40, y = -2, color = { 0.78, 0.8, 0.86 }, alpha = 1, blend = "BLEND" },
    critCycle = { { 1, 1, 1 }, { 0.37, 0.88, 1 }, { 1, 0.42, 0.84 }, { 1, 0.9, 0.42 } }, cyclePeriod = 0.12,
    critDecor = { tex = "beam", size = { 70, 150 }, y = 50, color = { 1, 0.96, 0.75 }, alpha = 0.4, snap = 0.3, snapTime = 0.2 },
    particles = { tex = "note", count = 0, critCount = 7, size = { 12, 16 }, aspect = 0.67, speed = { 30, 80 }, dir = { 40, 140 },
                  gravity = -10, life = { 0.8, 1.2 }, color = { 0.37, 0.88, 1 }, altColor = { 1, 0.42, 0.84 } },
})

add("powerballad", {
    group = "fun", listNote = "Secret",
    name = "Power Ballad", tagline = "Big chrome numbers in the stage lights; crits swing two spotlights and raise a sea of lighter flames.",
    font = F.skurri, size = 29, outline = "THICKOUTLINE",
    color = { 0.95, 0.96, 1 }, physColor = { 0.97, 0.97, 1 }, spellColor = { 1, 0.42, 0.84 },
    layers = { { x = 0, y = -2, color = { 1, 0.42, 0.84, 0.8 } }, { x = 2, y = -4, color = { 0.15, 0.05, 0.2, 1 } } },
    motion = "rise", motionArgs = { speed = 22 },
    dur = 1.3, critDur = 1.8, critScale = 1.55, pop = 0.25,
    critDecor = { tex = "beam", size = { 40, 170 }, x = -30, y = 50, rot = -0.35, color = { 1, 0.42, 0.84 }, alpha = 0.55 },
    critDecor2 = { tex = "beam", size = { 40, 170 }, x = 30, y = 50, rot = 0.35, color = { 0.37, 0.88, 1 }, alpha = 0.55 },
    particles = { tex = "flame", count = 0, critCount = 12, size = { 8, 12 }, aspect = 0.5, speed = { 15, 35 }, dir = { 80, 100 },
                  gravity = 0, life = { 0.8, 1.3 }, color = { 1, 0.7, 0.3 }, altColor = { 1, 0.9, 0.45 }, sway = true, drag = 0.5 },
})
