local _, ns = ...

-- Spell effects layered onto the skins: each skin keeps its own look and
-- gains the magic of its theme (a warrior's thunder clap, a priest's holy
-- nova, a warlock's shadow bolt...). Loaded after every skin file. The art
-- is SkinDeep's own (tools/make_textures.js).
--   upgrade(id, { critUnder, critOver, hitUnder, hitOver, particles3 })
-- Under: drawn beneath the skin's own pieces (ground effects); over: on top.

local function upgrade(id, u)
    local s = ns.Skins[id]
    if not s then return end
    local function merge(part, under, over)
        if not under and not over then return end
        local out = {}
        for _, d in ipairs(under or {}) do out[#out + 1] = d end
        for _, d in ipairs(s[part] or {}) do out[#out + 1] = d end
        for _, d in ipairs(over or {}) do out[#out + 1] = d end
        s[part] = out
    end
    merge("critPieces", u.critUnder, u.critOver)
    merge("hitPieces", u.hitUnder, u.hitOver)
    -- Trade skins: tiers that bring their own pieces get the same layers.
    for _, t in pairs(s.tiers or {}) do
        for _, part in ipairs({ "critPieces", "hitPieces" }) do
            local under, over = part == "critPieces" and u.critUnder or u.hitUnder, part == "critPieces" and u.critOver or u.hitOver
            if t[part] and (under or over) then
                local out = {}
                for _, d in ipairs(under or {}) do out[#out + 1] = d end
                for _, d in ipairs(t[part]) do out[#out + 1] = d end
                for _, d in ipairs(over or {}) do out[#out + 1] = d end
                t[part] = out
            end
        end
    end
    if u.particles3 then s.particles3 = u.particles3 end
end
ns.Upgrade = upgrade

-- Effect builders. Colors are { r, g, b }; times in seconds.
local E = {}
ns.Effect = E
local WHITE = { 1, 1, 1 }

-- A radiant star flash (a spell landing).
function E.star(x, y, size, color, delay, life, alpha)
    return { tex = "holystar", size = size, x = x, y = y, delay = delay or 0, snap = 0.3, snapTime = 0.08, life = life or 0.3,
             color = color, alpha = alpha or 1 }
end
-- A dust or energy shockwave across the ground.
function E.ground(y, w, color, delay, life, alpha)
    return { tex = "groundring", size = { w, w * 0.37 }, y = y, delay = delay or 0, snap = 0.3, snapTime = 0.25, grow = 0.5,
             life = life or 0.6, color = color, alpha = alpha or 0.85 }
end
-- Consecrated ground: a rune circle that lingers.
function E.consecrate(y, w, color, delay, life, alpha)
    return { tex = "consecrate", size = { w, w * 0.4 }, y = y, delay = delay or 0, snap = 0.3, snapTime = 0.25,
             life = life or 1.2, color = color, alpha = alpha or 0.8 }
end
-- A nova: a ring of shards bursting outward.
function E.nova(x, y, size, color, delay, life, alpha)
    return { tex = "novaring", size = size, x = x, y = y, delay = delay or 0, snap = 0.4, snapTime = 0.1, grow = 0.8,
             life = life or 0.45, color = color, alpha = alpha or 0.85 }
end
-- Real fire (full color), two shapes to alternate.
function E.fire(x, y, w, h, delay, life, alt, rot)
    return { tex = alt and "flamecolor2" or "flamecolor", size = { w, h }, x = x, y = y, rot = rot, delay = delay or 0,
             snap = 0.2, snapTime = 0.16, life = life or 0.7, color = WHITE, alpha = 1 }
end
-- A tinted flame (fel fire, frostfire, holy flame).
function E.flame(x, y, w, h, color, delay, life, rot)
    return { tex = "flame", size = { w, h }, x = x, y = y, rot = rot, delay = delay or 0, snap = 0.2, snapTime = 0.16,
             life = life or 0.7, color = color, alpha = 0.9 }
end
-- Smoke, soft or dark (blend "BLEND" darkens).
function E.smoke(x, y, size, color, delay, life, alpha, blend)
    return { tex = "smoke", size = size, x = x, y = y, delay = delay or 0, snap = 0.4, snapTime = 0.3, spin = 0.6,
             life = life or 0.9, color = color, alpha = alpha or 0.5, blend = blend }
end
-- Forked lightning from one point to another.
function E.fork(x1, y1, x2, y2, delay, color, width)
    local dx, dy = x2 - x1, y2 - y1
    return { tex = "forkbolt", size = { (width or 12) * 2, math.sqrt(dx * dx + dy * dy) * 1.05 }, x = (x1 + x2) / 2, y = (y1 + y2) / 2,
             rot = (math.atan2 or math.atan)(dy, dx) - math.pi / 2, delay = delay or 0, life = 0.3, flicker = true, front = true,
             color = color, alpha = 1 }
end
-- A missile: a glowing head on a streak, flashing where it lands.
function E.missile(fromX, fromY, toX, toY, delay, color, head)
    local dx, dy = toX - fromX, toY - fromY
    local rot = (math.atan2 or math.atan)(dy, dx)
    return {
        { tex = "streak", size = { 44, 9 }, x = toX - dx * 0.25, y = toY - dy * 0.25, from = { fromX, fromY }, rot = rot, ease = "in",
          move = 0.16, delay = delay, life = 0.2, color = color, alpha = 1 },
        head == "arrow"
            and { tex = "arrow", size = { 46, 11 }, x = toX - dx * 0.12, y = toY - dy * 0.12, from = { fromX, fromY }, rot = rot, ease = "in", move = 0.16,
                  delay = delay, life = 0.5, color = { 0.95, 0.88, 0.7 }, alpha = 1, blend = "BLEND" }
            or { tex = head or "arcorb", size = head and 22 or 16, x = toX, y = toY, from = { fromX, fromY }, ease = "in", move = 0.16, delay = delay,
                 life = 0.2, spin = head and 6 or nil, color = head and color or WHITE, alpha = 1, blend = head and "BLEND" or nil },
        E.star(toX, toY, 36, color, delay + 0.16, 0.28),
    }
end
-- A rising spiral of light (heals, resurrection).
function E.spiral(x, y, w, h, color, delay, life, alpha)
    return { tex = "rezspiral", size = { w, h }, x = x, y = y, delay = delay or 0, snap = 0.6, snapTime = 0.2, life = life or 0.9,
             color = color, alpha = alpha or 0.7 }
end
-- A churning shadow orb.
function E.orb(x, y, size, color, delay, life, alpha)
    return { tex = "shadoworb", size = size, x = x, y = y, delay = delay or 0, spin = 2, snap = 0.3, snapTime = 0.2,
             life = life or 0.9, color = color, alpha = alpha or 0.75, blend = "BLEND" }
end
-- A splash of blood or venom.
function E.splat(x, y, size, color, delay, life, rot)
    return { tex = "splat", size = size, x = x, y = y, rot = rot or 0, delay = delay or 0, snap = 0.3, snapTime = 0.1,
             life = life or 0.8, color = color, alpha = 0.9, blend = "BLEND" }
end
-- Particle systems: rocks thrown up, leaves, embers.
function E.rocks(y, color, delay, count)
    return { tex = "rock", count = 0, critCount = count or 8, size = { 5, 10 }, speed = { 80, 160 }, dir = { 50, 130 },
             origin = { 0, y }, spread = { 50, 4 }, delay = delay or 0, gravity = -460, life = { 0.45, 0.75 },
             color = color or { 0.5, 0.42, 0.34 }, blend = "BLEND", spin = 7 }
end
function E.motes(color, delay, count, alt)
    return { tex = "twinkle", count = 0, critCount = count or 10, size = { 6, 11 }, speed = { 30, 80 }, dir = { 60, 120 },
             spread = { 90, 20 }, delay = delay or 0, gravity = 30, life = { 0.6, 1.0 }, color = color, altColor = alt or WHITE }
end
function E.embers(y, color, delay, count)
    return { tex = "spark", count = 1, critCount = count or 12, size = { 3, 6 }, speed = { 40, 110 }, dir = { 70, 110 },
             origin = { 0, y }, spread = { 70, 6 }, delay = delay or 0, gravity = 50, life = { 0.5, 0.9 }, color = color,
             altColor = { 1, 0.9, 0.5 } }
end
function E.leaves(color, delay, count)
    return { tex = "leaf", count = 0, critCount = count or 8, size = { 8, 13 }, speed = { 40, 110 }, dir = { 0, 360 },
             delay = delay or 0, gravity = -60, life = { 0.7, 1.1 }, color = color, blend = "BLEND", spin = 4, sway = true }
end
local function concat(...)
    local out = {}
    for _, t in ipairs({ ... }) do for _, d in ipairs(t) do out[#out + 1] = d end end
    return out
end
E.concat = concat

-- Tidewater is a water healer: it drops the chain lightning it inherited.
if ns.Skins.shaman_resto and ns.Skins.shaman and ns.Skins.shaman_resto.critPieces == ns.Skins.shaman.critPieces then
    ns.Skins.shaman_resto.critPieces = nil
end
---------------------------------------------------------------------------
-- Class skins
---------------------------------------------------------------------------
local BLOOD, HOLY, FEL, ARCANE, FROST, NATURE, SHADOW, STORM =
    { 0.95, 0.25, 0.12 }, { 1, 0.86, 0.45 }, { 0.45, 1, 0.2 }, { 0.75, 0.5, 1 }, { 0.6, 0.85, 1 }, { 0.45, 0.9, 0.35 },
    { 0.55, 0.3, 0.85 }, { 0.55, 0.8, 1 }
local DUST = { 0.8, 0.62, 0.42 }

-- Bloodrage: the slam is a thunder clap, rocks flying.
upgrade("warrior", {
    critUnder = { E.ground(-34, 170, DUST, 0.12, 0.55) },
    critOver = { E.star(0, -24, 100, { 1, 0.55, 0.3 }, 0.12, 0.24) },
    hitUnder = { E.ground(-22, 70, DUST, 0.12, 0.35, 0.6) },
    particles3 = E.rocks(-30, { 0.55, 0.4, 0.3 }, 0.12),
})
-- Lightbringer: the light consecrates the ground beneath.
upgrade("paladin", {
    critUnder = { E.consecrate(-42, 160, HOLY, 0.05, 1.2) },
    critOver = { E.star(0, 14, 110, { 1, 0.95, 0.7 }, 0.05, 0.35), E.spiral(0, 30, 70, 130, HOLY, 0.1, 0.8, 0.5) },
    hitOver = { E.star(30, 12, 22, HOLY, 0.04, 0.24) },
    particles3 = E.motes(HOLY, 0.1, 10),
})
-- Dead Eye: a volley of arrows thuds into the crosshair.
upgrade("hunter", {
    critOver = concat(E.missile(-110, 40, -12, 6, 0.06, { 0.85, 1, 0.6 }, "arrow"), E.missile(-110, 10, 8, -6, 0.12, { 0.85, 1, 0.6 }, "arrow"),
        E.missile(-110, -20, 2, 10, 0.18, { 0.85, 1, 0.6 }, "arrow")),
    hitOver = { E.star(0, 0, 26, { 0.85, 1, 0.6 }, 0.2, 0.2, 0.8) },
})
-- Cutthroat: a smoke bomb under the X, and poison drips.
upgrade("rogue", {
    critUnder = { E.smoke(0, 0, 120, { 0.5, 0.5, 0.52 }, 0, 0.8, 0.55, "BLEND") },
    critOver = { E.star(0, 0, 80, { 1, 0.4, 0.4 }, 0.05, 0.22) },
    hitUnder = { E.smoke(-16, 0, 36, { 0.55, 0.55, 0.58 }, 0, 0.35, 0.45, "BLEND") },
    particles3 = { tex = "drop", count = 0, critCount = 6, size = { 4, 7 }, aspect = 0.6, speed = { 10, 30 }, dir = { 250, 290 },
                   spread = { 70, 10 }, delay = 0.1, gravity = -240, life = { 0.5, 0.8 }, color = { 0.35, 0.9, 0.2 }, blend = "BLEND" },
})
-- Halo: a holy nova of golden light.
upgrade("priest", {
    critUnder = { E.nova(0, 0, 70, HOLY, 0.05, 0.5, 0.7) },
    critOver = { E.star(0, 10, 110, { 1, 0.97, 0.8 }, 0.05, 0.35) },
    hitOver = { E.star(-30, 14, 20, HOLY, 0.06, 0.25) },
    particles3 = E.motes({ 1, 0.95, 0.75 }, 0.08, 12),
})
-- Stormcall: real forked lightning out to both sides, flashing at the ends.
upgrade("shaman", {
    critUnder = { E.ground(-40, 160, STORM, 0.05, 0.5, 0.7) },
    critOver = { E.fork(0, 0, -80, 30, 0.06, STORM, 14), E.fork(0, 0, 80, 26, 0.1, STORM, 14),
                 E.star(-80, 30, 46, WHITE, 0.08, 0.25), E.star(80, 26, 46, WHITE, 0.12, 0.25) },
    hitOver = { E.fork(20, 4, 46, 20, 0.04, STORM, 7) },
})
-- Spellweave: fire, frost and arcane, one after another.
upgrade("mage", {
    critOver = { E.fire(-46, 4, 26, 56, 0.06, 0.6), E.nova(46, 4, 54, FROST, 0.14, 0.45), E.star(0, 34, 70, ARCANE, 0.22, 0.3) },
    hitOver = { E.star(0, 18, 22, ARCANE, 0.12, 0.24) },
})
-- Fel Pact: a shadow bolt slams in, fel fire licks up beside it.
upgrade("warlock", {
    critUnder = { E.smoke(0, -6, 120, { 0.25, 0.6, 0.15 }, 0, 0.9, 0.4) },
    critOver = concat(E.missile(-110, 30, -6, 0, 0, SHADOW, "shadoworb"),
        { E.flame(-46, -6, 26, 60, FEL, 0.16, 0.7), E.flame(46, -4, 28, 64, FEL, 0.2, 0.7) }),
    hitOver = { E.orb(-32, 4, 22, SHADOW, 0, 0.4, 0.7) },
})
-- Wild Bloom: regrowth spirals up and leaves scatter.
upgrade("druid", {
    critUnder = { E.ground(-40, 150, NATURE, 0.05, 0.6, 0.6) },
    critOver = { E.spiral(0, 20, 70, 130, NATURE, 0.08, 0.9, 0.6), E.star(0, 10, 80, { 0.75, 1, 0.6 }, 0.06, 0.3) },
    particles3 = E.leaves(NATURE, 0.05, 9),
})

---------------------------------------------------------------------------
-- Spec skins
---------------------------------------------------------------------------
upgrade("warrior_arms", {   -- Mortal Strike: the wound opens and bleeds
    critOver = { E.splat(-10, -6, 40, { 0.6, 0.03, 0.03 }, 0.12, 0.9, 0.6), E.star(0, 0, 90, { 1, 0.35, 0.25 }, 0.1, 0.22) },
    critUnder = { E.ground(-34, 160, DUST, 0.1, 0.5) },
    particles3 = { tex = "drop", count = 0, critCount = 8, size = { 4, 8 }, aspect = 0.6, speed = { 40, 110 }, dir = { 20, 160 },
                   delay = 0.12, gravity = -300, life = { 0.4, 0.7 }, color = { 0.65, 0.04, 0.04 }, blend = "BLEND" },
})
upgrade("warrior_fury", {   -- Rampage: each strike flashes, the ground scorched
    critOver = { E.star(-18, 4, 70, { 1, 0.5, 0.2 }, 0.18, 0.2), E.star(18, -4, 76, { 1, 0.6, 0.25 }, 0.28, 0.2) },
    critUnder = { E.ground(-32, 160, { 1, 0.4, 0.15 }, 0.2, 0.55) },
    hitOver = { E.star(10, 0, 26, { 1, 0.55, 0.25 }, 0.2, 0.16, 0.8) },
})
upgrade("warrior_prot", {   -- Shield Wall: the shield rings out and the ground shakes
    critUnder = { E.ground(-36, 170, { 0.8, 0.85, 0.95 }, 0.05, 0.55) },
    critOver = { E.star(0, 4, 110, { 0.9, 0.95, 1 }, 0.05, 0.25), E.nova(0, 0, 70, { 0.85, 0.9, 1 }, 0.08, 0.45, 0.6) },
    particles3 = E.rocks(-34, nil, 0.05, 6),
})
upgrade("paladin_holy", {   -- Radiance: a holy light rises in a spiral
    critUnder = { E.consecrate(-44, 150, HOLY, 0.05, 1.1, 0.6) },
    critOver = { E.spiral(0, 30, 80, 150, HOLY, 0.06, 1.0, 0.6), E.star(0, 10, 110, { 1, 0.95, 0.75 }, 0.05, 0.35) },
    hitOver = { E.star(26, 16, 20, HOLY, 0.05, 0.25) },
})
upgrade("paladin_prot", {   -- Bulwark: consecration and a shield flash
    critUnder = { E.consecrate(-40, 170, HOLY, 0.05, 1.3) },
    critOver = { E.star(0, 18, 100, { 1, 0.92, 0.6 }, 0.08, 0.3), E.nova(0, 6, 64, HOLY, 0.1, 0.45, 0.6) },
    particles3 = E.motes(HOLY, 0.1, 10),
})
upgrade("paladin_ret", {    -- Judgment: the hammer of light lands with a blast
    critUnder = { E.ground(-38, 180, HOLY, 0.12, 0.55), E.consecrate(-40, 150, HOLY, 0.12, 1.0, 0.6) },
    critOver = { E.star(0, -10, 130, { 1, 0.9, 0.55 }, 0.12, 0.3), E.nova(0, -4, 70, HOLY, 0.14, 0.45, 0.7) },
})
upgrade("hunter_bm", {      -- Pack Leader: the beast's rake draws blood; a roar shakes the dust
    critOver = { E.splat(-6, 0, 36, { 0.6, 0.04, 0.04 }, 0.15, 0.8, 1.1), E.star(0, 0, 80, { 1, 0.7, 0.35 }, 0.12, 0.22) },
    critUnder = { E.ground(-34, 160, DUST, 0.1, 0.55) },
})
upgrade("hunter_mm", {      -- Bullseye: the aimed shot lands in a flash
    critOver = concat(E.missile(-120, 0, 0, 0, 0.32, { 0.9, 1, 0.7 }, "arrow"), { E.star(0, 0, 100, WHITE, 0.48, 0.28) }),
})
upgrade("hunter_sv", {      -- Trapper: the trap spews a venom cloud
    critUnder = { E.smoke(0, -10, 140, { 0.35, 0.8, 0.2 }, 0.1, 1.1, 0.45), E.ground(-36, 150, { 0.5, 0.9, 0.3 }, 0.1, 0.5) },
    critOver = { E.star(0, -14, 80, { 0.7, 1, 0.5 }, 0.12, 0.25) },
    particles3 = { tex = "bubble", count = 0, critCount = 8, size = { 5, 10 }, speed = { 20, 50 }, dir = { 70, 110 },
                   spread = { 90, 10 }, delay = 0.15, gravity = 20, life = { 0.6, 1.0 }, color = { 0.5, 1, 0.35 } },
})
upgrade("rogue_assa", {     -- Venom: a toxic cloud boils over the pool
    critUnder = { E.smoke(0, -16, 130, { 0.35, 0.85, 0.2 }, 0.05, 1.1, 0.4) },
    critOver = { E.star(0, -20, 70, { 0.6, 1, 0.4 }, 0.06, 0.22) },
    particles3 = { tex = "bubble", count = 0, critCount = 9, size = { 5, 10 }, speed = { 20, 50 }, dir = { 70, 110 },
                   origin = { 0, -20 }, spread = { 90, 10 }, delay = 0.1, gravity = 20, life = { 0.6, 1.0 }, color = { 0.5, 1, 0.35 } },
})
upgrade("rogue_combat", {   -- Blade Flurry: each blade strike sparks
    critOver = { E.splat(-16, 6, 30, { 0.6, 0.05, 0.04 }, 0.1, 0.7, 0.8), E.splat(18, -8, 26, { 0.6, 0.05, 0.04 }, 0.18, 0.7, 2.4),
                 { tex = "impact", size = 60, x = 0, y = 2, delay = 0.24, snap = 0.4, snapTime = 0.08, life = 0.22, color = { 1, 0.9, 0.6 }, alpha = 0.9 } },
    particles3 = { tex = "spark", count = 0, critCount = 12, size = { 3, 6 }, aspect = 0.4, speed = { 90, 180 }, dir = { 0, 360 },
                   delay = 0.08, gravity = -150, life = { 0.25, 0.45 }, color = { 1, 0.9, 0.6 }, orient = true },
})
upgrade("rogue_sub", {      -- Shadowstep: out of a shadow and a smoke bomb
    critUnder = { E.orb(0, 4, 110, SHADOW, 0, 0.8, 0.6), E.smoke(0, 0, 130, { 0.45, 0.42, 0.5 }, 0.05, 0.8, 0.5, "BLEND") },
    hitUnder = { E.smoke(0, 0, 44, { 0.45, 0.42, 0.5 }, 0, 0.35, 0.4, "BLEND") },
})
upgrade("priest_disc", {    -- Bastion: the ward seals over sanctified ground
    critUnder = { E.consecrate(-40, 150, HOLY, 0.12, 1.1, 0.6) },
    critOver = { { tex = "bubble", size = 96, delay = 0.15, snap = 0.6, snapTime = 0.15, life = 0.6, color = { 1, 0.92, 0.6 }, alpha = 0.6 } },
    particles3 = E.motes(HOLY, 0.15, 10),
})
upgrade("priest_holy", {    -- Seraph: a holy spiral rises between the wings
    critOver = { E.spiral(0, 30, 80, 150, { 1, 0.95, 0.75 }, 0.08, 1.0, 0.6), E.star(0, 16, 100, WHITE, 0.08, 0.3) },
    particles3 = E.motes({ 1, 0.97, 0.85 }, 0.1, 10),
})
upgrade("priest_shadow", {  -- Mind Flay: a beam of shadow pours into the number
    critUnder = { E.orb(0, 4, 120, SHADOW, 0, 1.0, 0.7) },
    critOver = { E.fork(0, 100, 0, 8, 0.05, { 0.7, 0.45, 1 }, 16), E.fork(0, 100, 0, 8, 0.25, { 0.7, 0.45, 1 }, 14),
                 E.star(0, 6, 80, ARCANE, 0.08, 0.3) },
})
upgrade("shaman_ele", {     -- Thunderhead: the bolt strikes down and the ground jolts
    critUnder = { E.ground(-38, 170, STORM, 0.12, 0.5) },
    critOver = { E.fork(0, 100, 0, 6, 0.1, STORM, 18), E.star(0, 6, 110, WHITE, 0.12, 0.28) },
})
upgrade("shaman_enh", {     -- Stormstrike: sparks where the charged blades cross
    critOver = { E.star(0, 0, 90, STORM, 0.1, 0.25), E.fork(-40, 26, 0, 0, 0.1, STORM, 8), E.fork(40, 26, 0, 0, 0.14, STORM, 8) },
})
upgrade("shaman_resto", {   -- Tidewater: a healing wave spirals up
    critOver = { E.spiral(0, 26, 80, 140, { 0.45, 0.85, 1 }, 0.08, 0.9, 0.6), E.star(0, 10, 90, { 0.7, 0.95, 1 }, 0.06, 0.3) },
    particles3 = { tex = "bubble", count = 0, critCount = 10, size = { 5, 10 }, speed = { 20, 60 }, dir = { 60, 120 },
                   spread = { 80, 10 }, delay = 0.1, gravity = 30, life = { 0.6, 1.0 }, color = { 0.6, 0.9, 1 } },
})
upgrade("mage_arcane", {    -- Arcane Surge: arcane missiles, then an arcane explosion
    critOver = concat(E.missile(-90, 50, -20, 6, 0.05, ARCANE), E.missile(90, 50, 20, 6, 0.12, ARCANE), E.missile(0, 100, 0, 14, 0.19, ARCANE),
        { E.nova(0, 0, 70, ARCANE, 0.36, 0.45, 0.75) }),
})
upgrade("mage_fire", {      -- Pyroclasm: columns of real fire and rolling smoke
    critUnder = { E.ground(-34, 170, { 1, 0.5, 0.15 }, 0.05, 0.55) },
    critOver = { E.fire(-50, -6, 30, 70, 0.06, 0.75), E.fire(50, -4, 32, 76, 0.1, 0.75, true), E.fire(0, 30, 26, 58, 0.14, 0.6),
                 E.smoke(0, 60, 70, { 0.4, 0.36, 0.34 }, 0.3, 1.0, 0.4, "BLEND") },
    hitOver = { E.fire(-30, -2, 12, 28, 0, 0.45) },
    particles3 = E.embers(-20, { 1, 0.55, 0.15 }, 0.05),
})
upgrade("mage_frost", {     -- Glacial Spike: a frost nova where it shatters
    critUnder = { E.ground(-34, 160, FROST, 0.1, 0.5) },
    critOver = { E.nova(0, 0, 80, FROST, 0.08, 0.5), E.star(0, 0, 100, { 0.9, 0.97, 1 }, 0.08, 0.25) },
})
upgrade("warlock_aff", {    -- Withering: a cloud of decay and a drifting shadow
    critUnder = { E.smoke(0, 0, 130, { 0.45, 0.75, 0.2 }, 0, 1.0, 0.35), E.orb(0, 30, 70, SHADOW, 0.1, 0.9, 0.5) },
})
upgrade("warlock_demo", {   -- Demonic Pact: fel fire burns round the ring
    critUnder = { E.ground(-36, 160, FEL, 0.05, 0.55) },
    critOver = { E.flame(-52, -4, 26, 62, FEL, 0.1, 0.7), E.flame(52, -4, 26, 62, FEL, 0.14, 0.7), E.star(0, 6, 90, { 0.7, 1, 0.5 }, 0.08, 0.25) },
})
upgrade("warlock_destro", { -- Chaos Fire: fel fire erupts and stones fly
    critOver = { E.flame(-54, -10, 30, 76, FEL, 0.08, 0.75), E.flame(0, 24, 34, 82, FEL, 0.12, 0.7), E.flame(54, -8, 30, 76, FEL, 0.1, 0.75),
                 E.smoke(0, 60, 70, { 0.3, 0.45, 0.2 }, 0.3, 1.0, 0.4, "BLEND") },
    particles3 = E.rocks(-30, { 0.35, 0.45, 0.28 }, 0.1),
})
upgrade("druid_balance", {  -- Starsurge: stars fall into the number
    critOver = concat(E.missile(-80, 110, -16, 10, 0.04, { 0.8, 0.85, 1 }), E.missile(80, 110, 16, 10, 0.1, { 0.8, 0.85, 1 }),
        { E.star(0, 6, 110, { 0.85, 0.9, 1 }, 0.26, 0.35) }),
})
upgrade("druid_feral", {    -- Shred: claws draw blood
    critOver = { E.splat(0, 0, 36, { 0.6, 0.04, 0.04 }, 0.12, 0.8), E.star(0, 0, 80, { 1, 0.75, 0.35 }, 0.1, 0.22) },
    critUnder = { E.ground(-34, 150, DUST, 0.08, 0.5) },
})
upgrade("druid_guardian", { -- Ironbark: the blow rings off bark; splinters fly
    critUnder = { E.ground(-36, 160, { 0.7, 0.5, 0.3 }, 0.05, 0.55) },
    critOver = { E.star(0, 0, 90, { 0.95, 0.8, 0.5 }, 0.05, 0.25) },
    particles3 = E.rocks(-10, { 0.5, 0.34, 0.18 }, 0.05, 8),
})
upgrade("druid_resto", {    -- Lifebloom: a rejuvenating spiral, leaves on the wind
    critOver = { E.spiral(0, 24, 80, 140, NATURE, 0.1, 1.0, 0.6), E.star(0, 10, 90, { 0.75, 1, 0.6 }, 0.08, 0.3) },
    particles3 = E.leaves(NATURE, 0.1, 9),
})

upgrade("shaman_resto", { critUnder = { E.nova(0, 0, 70, { 0.5, 0.85, 1 }, 0.05, 0.5, 0.6) } })

---------------------------------------------------------------------------
-- Faction skins
---------------------------------------------------------------------------
local GOLDEN, EMBER, SAND = { 1, 0.82, 0.4 }, { 1, 0.55, 0.15 }, { 0.85, 0.72, 0.48 }
upgrade("scarlet", {    -- Crimson Oath: holy fire on consecrated ground
    critUnder = { E.consecrate(-42, 160, { 1, 0.5, 0.3 }, 0.05, 1.1, 0.65) },
    critOver = { E.flame(-48, -2, 26, 62, { 1, 0.7, 0.3 }, 0.08, 0.7), E.flame(48, -2, 26, 62, { 1, 0.7, 0.3 }, 0.12, 0.7),
                 E.star(0, 8, 100, { 1, 0.85, 0.6 }, 0.06, 0.3) },
    particles3 = E.embers(-20, { 1, 0.6, 0.25 }, 0.08, 10),
})
upgrade("scourge", {    -- Plague Tide: plague mist and a frost nova
    critUnder = { E.smoke(0, -4, 140, { 0.4, 0.75, 0.3 }, 0, 1.1, 0.4) },
    critOver = { E.nova(0, 0, 80, { 0.65, 0.9, 1 }, 0.1, 0.5, 0.7), E.star(0, 0, 80, { 0.8, 1, 0.85 }, 0.1, 0.25) },
    particles3 = E.motes({ 0.55, 0.95, 0.5 }, 0.1, 10),
})
upgrade("defias", {     -- Red Kerchief: a gunpowder flash, smoke and splinters
    critOver = { E.star(0, 0, 110, { 1, 0.7, 0.3 }, 0, 0.22), E.smoke(10, 20, 110, { 0.4, 0.38, 0.36 }, 0.05, 0.9, 0.5, "BLEND") },
    particles3 = E.rocks(0, { 0.45, 0.3, 0.18 }, 0, 8),
})
upgrade("darkiron", {   -- Molten Anvil: the forge blow throws fire and slag
    critUnder = { E.ground(-34, 170, EMBER, 0.1, 0.55) },
    critOver = { E.fire(-44, -6, 26, 58, 0.12, 0.6), E.fire(44, -6, 26, 58, 0.16, 0.6, true), E.star(0, -12, 100, { 1, 0.75, 0.35 }, 0.1, 0.22) },
    particles3 = E.rocks(-30, { 0.3, 0.2, 0.15 }, 0.1, 8),
})
upgrade("brood", {      -- Broodmother: real dragonfire rolls out, smoke behind
    critOver = { E.fire(-30, 10, 34, 80, 0.06, 0.75, false, 0.5), E.fire(0, 22, 38, 90, 0.1, 0.75, true, 0), E.fire(30, 10, 34, 80, 0.14, 0.75, false, -0.5),
                 E.smoke(0, 64, 90, { 0.35, 0.28, 0.38 }, 0.3, 1.0, 0.45, "BLEND") },
    particles3 = E.embers(0, { 0.85, 0.45, 1 }, 0.08, 12),
})
upgrade("argent", {     -- Silver Dawn: holy light breaks over sanctified ground
    critUnder = { E.consecrate(-42, 160, { 0.85, 0.9, 1 }, 0.05, 1.1, 0.6) },
    critOver = { E.star(0, 10, 120, { 1, 0.97, 0.85 }, 0.05, 0.35), E.spiral(0, 30, 70, 130, { 0.9, 0.95, 1 }, 0.1, 0.8, 0.5) },
    particles3 = E.motes({ 0.95, 0.97, 1 }, 0.1, 10),
})
upgrade("broadside", {  -- Broadside: cannon smoke rolls, splinters fly
    critOver = { E.star(0, 0, 110, { 1, 0.75, 0.35 }, 0, 0.2), E.smoke(-20, 10, 130, { 0.42, 0.4, 0.38 }, 0.04, 1.0, 0.55, "BLEND") },
    particles3 = E.rocks(0, { 0.5, 0.34, 0.2 }, 0, 8),
})
upgrade("hexbound", {   -- Hexbound: voodoo mojo churns round the mask
    critUnder = { E.orb(0, 6, 120, { 0.5, 0.9, 0.4 }, 0, 0.9, 0.55), E.smoke(0, 0, 130, { 0.6, 0.3, 0.7 }, 0.05, 1.0, 0.35) },
    particles3 = E.motes({ 0.6, 1, 0.45 }, 0.05, 12, { 0.85, 0.5, 1 }),
})
upgrade("oldgod", {     -- Old God Whispers: the void reaches up for the number
    critUnder = { E.orb(0, 4, 130, SHADOW, 0, 1.1, 0.7) },
    critOver = { E.fork(-50, -60, -8, 0, 0.1, { 0.7, 0.4, 1 }, 12), E.fork(50, -60, 8, 0, 0.16, { 0.7, 0.4, 1 }, 12),
                 E.star(0, 0, 80, ARCANE, 0.12, 0.3) },
})
upgrade("swarm", {      -- Silithid Swarm: the sand churns and spits
    critUnder = { E.ground(-34, 160, SAND, 0, 0.6), E.smoke(0, -20, 130, { 0.75, 0.62, 0.4 }, 0, 0.9, 0.4, "BLEND") },
    particles3 = E.rocks(-30, { 0.72, 0.58, 0.36 }, 0, 10),
})
upgrade("tidecaller", { -- Tidecaller: a splash ring, a rising swell, bubbles
    critOver = { E.nova(0, 0, 80, { 0.5, 0.85, 1 }, 0.05, 0.5, 0.7), E.spiral(0, 26, 70, 130, { 0.5, 0.85, 1 }, 0.1, 0.8, 0.5) },
    particles3 = { tex = "bubble", count = 1, critCount = 10, size = { 5, 10 }, speed = { 20, 60 }, dir = { 60, 120 },
                   spread = { 80, 10 }, delay = 0.08, gravity = 30, life = { 0.6, 1.0 }, color = { 0.6, 0.9, 1 } },
})

---------------------------------------------------------------------------
-- PvP skins
---------------------------------------------------------------------------
local ALLY, HORDE = { 0.55, 0.75, 1 }, { 1, 0.4, 0.25 }
upgrade("sergeant_a", { critUnder = { E.ground(-32, 150, DUST, 0.1, 0.5) }, critOver = { E.star(0, 10, 80, ALLY, 0.1, 0.25) } })
upgrade("knight", { critOver = { E.star(0, 12, 90, GOLDEN, 0.1, 0.3) }, particles3 = E.motes(GOLDEN, 0.1, 8, ALLY) })
upgrade("ltcommander", {
    critOver = { E.star(0, 18, 90, WHITE, 0.2, 0.25) },
    particles3 = { tex = "spark", count = 0, critCount = 12, size = { 3, 6 }, aspect = 0.4, speed = { 80, 170 }, dir = { 0, 360 },
                   origin = { 0, 18 }, delay = 0.2, gravity = -180, life = { 0.3, 0.5 }, color = { 1, 0.9, 0.6 }, orient = true },
})
upgrade("fieldmarshal", { critOver = { E.star(0, 10, 120, { 0.9, 0.95, 1 }, 0.15, 0.35), E.nova(0, 4, 80, { 0.8, 0.88, 1 }, 0.18, 0.5, 0.6) } })
upgrade("grandmarshal", {
    critUnder = { E.consecrate(-44, 180, GOLDEN, 0.1, 1.3, 0.7) },
    critOver = { E.spiral(0, 40, 80, 160, GOLDEN, 0.15, 1.0, 0.55), E.star(0, 20, 140, { 1, 0.95, 0.7 }, 0.15, 0.4) },
})
upgrade("sergeant_h", { critUnder = { E.ground(-32, 150, DUST, 0.08, 0.5) }, particles3 = E.rocks(-10, { 0.5, 0.45, 0.4 }, 0.1, 8) })
upgrade("stoneguard", { critOver = { E.splat(-14, 6, 40, { 0.6, 0.06, 0.04 }, 0.15, 0.8, 0.4) }, critUnder = { E.ground(-32, 150, DUST, 0.05, 0.5) } })
upgrade("champion", { critOver = { E.star(0, 16, 90, EMBER, 0.15, 0.25) }, particles3 = E.embers(-20, EMBER, 0.1, 12) })
upgrade("warlord", {
    critOver = { E.fire(-56, 0, 30, 76, 0.1, 0.8), E.fire(56, 0, 30, 76, 0.14, 0.8, true), E.smoke(0, 70, 100, { 0.3, 0.26, 0.24 }, 0.3, 1.1, 0.45, "BLEND") },
    particles3 = E.embers(-20, EMBER, 0.1, 14),
})
upgrade("highwarlord", {
    critUnder = { E.ground(-36, 170, EMBER, 0.05, 0.4), E.ground(-36, 190, EMBER, 0.2, 0.4), E.ground(-36, 210, EMBER, 0.35, 0.45) },
    critOver = { E.fire(-60, -4, 32, 80, 0.4, 0.8), E.fire(60, -4, 32, 80, 0.44, 0.8, true), E.star(0, 0, 130, { 1, 0.6, 0.3 }, 0.36, 0.3) },
    particles3 = E.rocks(-32, { 0.35, 0.25, 0.2 }, 0.36, 10),
})
upgrade("flagrunner", { critUnder = { E.ground(-34, 160, DUST, 0.1, 0.5) }, critOver = { E.star(0, 20, 80, WHITE, 0.15, 0.25) } })
upgrade("fivebanners", { critOver = { E.star(0, 10, 100, GOLDEN, 0.2, 0.3) }, particles3 = E.motes(GOLDEN, 0.2, 10) })
upgrade("wintersiege", {
    critUnder = { E.ground(-34, 170, { 0.85, 0.95, 1 }, 0.05, 0.55) },
    critOver = { E.nova(0, 0, 80, FROST, 0.05, 0.5, 0.7) },
    particles3 = { tex = "glow", count = 0, critCount = 14, size = { 3, 6 }, speed = { 10, 40 }, dir = { 250, 290 },
                   origin = { 0, 70 }, spread = { 160, 20 }, gravity = -30, life = { 0.8, 1.3 }, color = WHITE, sway = true, drag = 0, shrink = 0 },
})
upgrade("duelist", { critUnder = { E.ground(-34, 150, SAND, 0.1, 0.5) }, critOver = { E.star(0, 4, 90, WHITE, 0.12, 0.22) } })
upgrade("tally", { critOver = { E.star(0, 30, 50, { 1, 0.9, 0.7 }, 0.1, 0.25) } })
upgrade("lionspride", { critUnder = { E.ground(-34, 170, GOLDEN, 0.1, 0.6, 0.6) }, critOver = { E.star(0, 20, 100, GOLDEN, 0.1, 0.3) } })
upgrade("bloodthunder", {
    critUnder = { E.ground(-34, 160, HORDE, 0.05, 0.4), E.ground(-34, 180, HORDE, 0.2, 0.4), E.ground(-34, 200, HORDE, 0.35, 0.45) },
    critOver = { E.fork(-40, 70, -10, 10, 0.35, STORM, 10), E.fork(40, 70, 10, 10, 0.38, STORM, 10) },
})
upgrade("headhunter", { critOver = { E.splat(16, -10, 44, { 0.6, 0.04, 0.04 }, 0.1, 0.9, 2), E.star(0, 4, 90, { 1, 0.4, 0.3 }, 0.08, 0.22) } })
upgrade("warmonger", {
    critOver = { E.fire(-50, -6, 30, 70, 0.05, 0.75), E.fire(50, -6, 30, 70, 0.09, 0.75, true), E.smoke(0, 66, 100, { 0.3, 0.26, 0.24 }, 0.3, 1.1, 0.45, "BLEND") },
    particles3 = E.embers(-20, EMBER, 0.05, 14),
})

---------------------------------------------------------------------------
-- Style skins
---------------------------------------------------------------------------
local PINK, MAGENTA = { 1, 0.5, 0.75 }, { 1, 0.35, 0.9 }
upgrade("classic", { critOver = { E.star(0, 0, 70, { 1, 0.95, 0.8 }, 0, 0.18, 0.6) } })   -- Classic+ stays classic
upgrade("ember", {
    critOver = { E.fire(-40, -4, 26, 62, 0.04, 0.7), E.fire(40, -4, 26, 62, 0.08, 0.7, true), E.fire(0, 26, 22, 52, 0.12, 0.6) },
    hitOver = { E.fire(-28, -4, 11, 26, 0, 0.45, true) },
    particles3 = E.embers(-10, { 1, 0.55, 0.15 }, 0.05, 12),
})
upgrade("frost", {
    critUnder = { E.ground(-34, 160, FROST, 0.05, 0.5) },
    critOver = { E.nova(0, 0, 86, FROST, 0.05, 0.5, 0.75), E.star(0, 0, 100, { 0.92, 0.98, 1 }, 0.05, 0.25) },
    hitOver = { E.star(0, 0, 26, FROST, 0.05, 0.2, 0.8) },
})
upgrade("arcane", {
    critOver = E.concat(E.missile(-90, 60, -18, 6, 0.04, ARCANE), E.missile(90, 60, 18, 6, 0.1, ARCANE),
        { E.nova(0, 0, 76, ARCANE, 0.28, 0.45, 0.7) }),
    hitOver = { E.star(0, 18, 22, ARCANE, 0.1, 0.24) },
})
upgrade("comic", {
    critUnder = { E.smoke(0, 0, 150, { 1, 1, 1 }, 0, 0.6, 0.35) },
    critOver = { E.star(0, 0, 110, { 1, 0.95, 0.6 }, 0, 0.22) },
    particles3 = { tex = "spark", count = 0, critCount = 10, size = { 4, 8 }, aspect = 0.4, speed = { 120, 220 }, dir = { 0, 360 },
                   gravity = 0, life = { 0.2, 0.4 }, color = { 1, 0.95, 0.5 }, orient = true },
})
upgrade("blood", {
    critOver = { E.splat(-30, 14, 40, { 0.5, 0, 0.02 }, 0.1, 1.0, 1.2), E.splat(34, -10, 34, { 0.5, 0, 0.02 }, 0.16, 1.0, 2.6),
                 E.star(0, 0, 90, { 1, 0.3, 0.25 }, 0.04, 0.22) },
})
upgrade("arcade", {
    critOver = { E.star(0, 0, 100, WHITE, 0, 0.18) },
    particles3 = { tex = "pixel", count = 0, critCount = 18, size = { 4, 7 }, speed = { 100, 200 }, dir = { 0, 360 },
                   gravity = -160, life = { 0.4, 0.8 }, randomColor = true, blend = "BLEND" },
})
upgrade("gilded", {
    critOver = { E.spiral(0, 24, 70, 130, GOLDEN, 0.05, 0.8, 0.6), E.star(0, 6, 100, { 1, 0.92, 0.55 }, 0.04, 0.3) },
    hitOver = { E.star(18, 10, 22, GOLDEN, 0.08, 0.24) },
    particles3 = E.motes(GOLDEN, 0.05, 12),
})
upgrade("blade", {
    critOver = { E.star(-10, 4, 80, WHITE, 0.03, 0.2), E.star(12, -6, 70, { 0.75, 0.88, 1 }, 0.09, 0.2) },
    particles3 = { tex = "spark", count = 0, critCount = 12, size = { 3, 6 }, aspect = 0.4, speed = { 100, 200 }, dir = { -30, 30 },
                   gravity = -120, life = { 0.25, 0.45 }, color = { 0.85, 0.92, 1 }, orient = true, mirror = true },
})
upgrade("starfall", {
    critOver = E.concat(E.missile(-70, 120, -18, 8, 0.02, { 0.85, 0.9, 1 }), E.missile(20, 130, 6, 12, 0.08, { 0.85, 0.9, 1 }),
        E.missile(80, 110, 20, 4, 0.14, { 0.85, 0.9, 1 }), { E.star(0, 6, 110, { 0.9, 0.93, 1 }, 0.3, 0.3) }),
})
upgrade("gearworks", {
    critOver = { E.smoke(-30, 30, 90, { 0.95, 0.95, 0.95 }, 0.05, 0.9, 0.4), E.smoke(34, 26, 80, { 0.95, 0.95, 0.95 }, 0.1, 0.9, 0.35),
                 E.star(0, 0, 90, { 1, 0.8, 0.45 }, 0, 0.2) },
    particles3 = { tex = "spark", count = 0, critCount = 12, size = { 3, 6 }, aspect = 0.4, speed = { 90, 180 }, dir = { 30, 150 },
                   gravity = -250, life = { 0.3, 0.6 }, color = { 1, 0.75, 0.3 }, orient = true },
})
upgrade("murloc", {
    critOver = { E.nova(0, -4, 80, { 0.5, 0.85, 1 }, 0.05, 0.5, 0.7), E.star(0, 0, 80, { 0.7, 0.95, 1 }, 0.05, 0.22) },
    particles3 = { tex = "bubble", count = 0, critCount = 10, size = { 5, 10 }, speed = { 30, 80 }, dir = { 50, 130 },
                   gravity = 30, life = { 0.6, 1.0 }, color = { 0.6, 0.9, 1 } },
})
upgrade("hallows", {
    critUnder = { E.orb(0, 4, 120, { 1, 0.55, 0.15 }, 0, 0.9, 0.5), E.smoke(0, -10, 140, { 0.45, 0.3, 0.55 }, 0.05, 1.0, 0.4) },
    particles3 = E.motes({ 1, 0.6, 0.2 }, 0.05, 10, { 0.7, 1, 0.4 }),
})
upgrade("winterveil", {
    critOver = { E.star(0, 10, 100, WHITE, 0.04, 0.3), E.nova(0, 0, 76, { 0.85, 0.95, 1 }, 0.06, 0.45, 0.6) },
    particles3 = { tex = "glow", count = 1, critCount = 14, size = { 3, 6 }, speed = { 10, 40 }, dir = { 250, 290 },
                   origin = { 0, 60 }, spread = { 150, 20 }, gravity = -30, life = { 0.8, 1.3 }, color = WHITE, sway = true, drag = 0, shrink = 0 },
})
upgrade("heartthrob", {
    critOver = { E.star(0, 4, 100, PINK, 0.04, 0.3), E.spiral(0, 24, 70, 130, PINK, 0.06, 0.8, 0.5) },
    particles3 = { tex = "heart", count = 0, critCount = 9, size = { 8, 13 }, speed = { 30, 80 }, dir = { 60, 120 },
                   spread = { 60, 10 }, delay = 0.06, gravity = 30, life = { 0.7, 1.1 }, color = PINK, altColor = { 1, 0.8, 0.9 }, sway = true },
})

---------------------------------------------------------------------------
-- Loot skins
---------------------------------------------------------------------------
upgrade("freshfind", { critOver = { E.star(0, 6, 90, { 0.4, 1, 0.4 }, 0.05, 0.3) }, particles3 = E.motes({ 0.5, 1, 0.5 }, 0.05, 10) })
upgrade("rarefind", {
    critOver = { E.star(0, 6, 100, { 0.4, 0.65, 1 }, 0.05, 0.3), E.nova(0, 0, 70, { 0.4, 0.65, 1 }, 0.08, 0.45, 0.6) },
    particles3 = E.motes({ 0.5, 0.7, 1 }, 0.05, 10),
})
upgrade("epichaul", {
    critOver = { E.spiral(0, 26, 76, 140, { 0.75, 0.45, 1 }, 0.05, 0.9, 0.55), E.star(0, 6, 110, { 0.8, 0.55, 1 }, 0.05, 0.3) },
    particles3 = E.motes({ 0.8, 0.55, 1 }, 0.05, 12),
})
upgrade("legendary", {
    critUnder = { E.consecrate(-44, 180, { 1, 0.55, 0.1 }, 0.05, 1.3, 0.7) },
    critOver = { E.spiral(0, 34, 84, 160, { 1, 0.6, 0.15 }, 0.06, 1.0, 0.55) },
})
upgrade("fullset", { critOver = { E.star(0, 8, 100, GOLDEN, 0.1, 0.3), E.nova(0, 0, 70, GOLDEN, 0.12, 0.45, 0.55) } })

---------------------------------------------------------------------------
-- Trade skins (each tier keeps these too)
---------------------------------------------------------------------------
upgrade("philter", { critOver = { E.smoke(-20, 20, 90, { 0.4, 1, 0.4 }, 0.05, 0.9, 0.45), E.smoke(24, 16, 80, { 0.75, 0.4, 1 }, 0.1, 0.9, 0.45) } })
upgrade("anvilstrike", { critUnder = { E.ground(-34, 160, EMBER, 0.05, 0.5) }, critOver = { E.star(0, -8, 100, { 1, 0.75, 0.4 }, 0.05, 0.22) } })
upgrade("runethread", { critOver = { E.spiral(0, 24, 70, 130, ARCANE, 0.08, 0.8, 0.5), E.star(0, 6, 90, ARCANE, 0.06, 0.28) } })
upgrade("blastcap", { critOver = { E.fire(-30, 6, 28, 60, 0.04, 0.55), E.fire(30, 6, 28, 60, 0.08, 0.55, true), E.star(0, 0, 120, { 1, 0.8, 0.4 }, 0, 0.22) } })
upgrade("wildroot", { critOver = { E.star(0, 6, 80, { 0.75, 1, 0.5 }, 0.06, 0.25) }, particles3 = E.leaves(NATURE, 0.05, 8) })
upgrade("stitchwork", { critOver = { E.star(0, 4, 80, { 1, 0.85, 0.6 }, 0.1, 0.25) } })
upgrade("motherlode", { critUnder = { E.ground(-34, 150, { 0.75, 0.7, 0.6 }, 0.05, 0.5) }, particles3 = E.rocks(-20, { 0.55, 0.52, 0.5 }, 0.05, 10) })
upgrade("keenedge", { critOver = { E.star(0, 0, 80, WHITE, 0.08, 0.2) } })
upgrade("boltofcloth", { critOver = { E.star(0, 8, 80, { 1, 0.85, 0.95 }, 0.1, 0.25) } })
upgrade("sizzle", { critOver = { E.smoke(-16, 34, 70, { 0.95, 0.95, 0.95 }, 0.1, 1.0, 0.35), E.smoke(20, 40, 60, { 0.95, 0.95, 0.95 }, 0.2, 1.0, 0.3), E.fire(0, -30, 30, 40, 0, 0.5) } })
upgrade("luckybobber", { critOver = { E.nova(0, -24, 70, { 0.55, 0.85, 1 }, 0.1, 0.5, 0.7) } })
upgrade("fielddressing", { critOver = { E.spiral(0, 24, 70, 130, { 1, 0.95, 0.95 }, 0.08, 0.8, 0.45), E.star(0, 8, 80, WHITE, 0.06, 0.25) } })

---------------------------------------------------------------------------
-- Fun skins
---------------------------------------------------------------------------
upgrade("natural20", { critOver = { E.star(0, 6, 110, GOLDEN, 0.1, 0.3) }, particles3 = E.motes(GOLDEN, 0.1, 10) })
upgrade("synthwave", { critUnder = { E.ground(-34, 170, MAGENTA, 0.05, 0.6) }, critOver = { E.star(0, 4, 100, { 1, 0.5, 0.9 }, 0.04, 0.28) } })
upgrade("glitch", {
    critOver = { E.star(0, 0, 80, { 0.4, 1, 1 }, 0, 0.15) },
    particles3 = { tex = "pixel", count = 2, critCount = 16, size = { 3, 8 }, speed = { 60, 180 }, dir = { -10, 10 },
                   spread = { 20, 60 }, gravity = 0, life = { 0.1, 0.3 }, randomColor = true, blend = "BLEND", mirror = true },
})
upgrade("discofever", { critOver = { E.star(0, 10, 100, WHITE, 0.05, 0.3) }, particles3 = E.motes({ 1, 0.5, 0.9 }, 0.05, 14, { 0.5, 0.9, 1 }) })
upgrade("bunnyhop", { critUnder = { E.ground(-30, 120, DUST, 0.05, 0.4) }, critOver = { E.star(0, 0, 60, { 1, 0.9, 0.95 }, 0.05, 0.2) } })
upgrade("graveyard", {
    critUnder = { E.smoke(0, -10, 150, { 0.55, 0.65, 0.55 }, 0, 1.2, 0.4), E.orb(0, 10, 100, { 0.6, 0.9, 0.6 }, 0.05, 1.0, 0.45) },
    particles3 = E.motes({ 0.7, 1, 0.75 }, 0.1, 10),
})
upgrade("hogger", { critUnder = { E.ground(-34, 170, DUST, 0.05, 0.55) }, critOver = { E.star(0, -10, 100, { 1, 0.7, 0.4 }, 0.05, 0.22) },
                    particles3 = E.rocks(-30, nil, 0.05, 8) })
upgrade("powersurge", {
    critOver = { E.fork(-50, -30, -6, 0, 0.1, { 1, 0.95, 0.4 }, 10), E.fork(50, -30, 6, 0, 0.14, { 1, 0.95, 0.4 }, 10), E.star(0, 0, 120, { 1, 0.95, 0.5 }, 0.1, 0.3) },
    critUnder = { E.ground(-34, 170, { 1, 0.9, 0.3 }, 0.1, 0.55) },
})
upgrade("finalmove", { critOver = { E.nova(0, 0, 90, { 1, 0.6, 0.9 }, 0.1, 0.5, 0.7), E.star(0, 0, 120, WHITE, 0.08, 0.3) } })
upgrade("sakura", { critOver = { E.spiral(0, 24, 70, 130, PINK, 0.05, 0.9, 0.5), E.star(0, 6, 90, { 1, 0.8, 0.9 }, 0.05, 0.28) } })
upgrade("mechastrike", { critOver = { E.smoke(0, 20, 110, { 0.6, 0.6, 0.62 }, 0.1, 0.9, 0.45, "BLEND"), E.star(0, 0, 110, { 0.6, 0.9, 1 }, 0.05, 0.25) },
                         particles3 = E.embers(0, { 1, 0.75, 0.3 }, 0.05, 12) })
upgrade("bassdrop", {
    critUnder = { E.ground(-34, 150, MAGENTA, 0.1, 0.35), E.ground(-34, 170, { 0.4, 0.8, 1 }, 0.3, 0.35), E.ground(-34, 190, MAGENTA, 0.5, 0.4) },
})
upgrade("lofi", { critOver = { E.smoke(10, 34, 70, { 0.9, 0.85, 1 }, 0.1, 1.1, 0.3) }, particles3 = E.motes({ 0.85, 0.75, 1 }, 0.1, 8) })
upgrade("karaoke", { critOver = { E.star(0, 10, 100, { 1, 0.85, 1 }, 0.05, 0.3) }, particles3 = E.motes({ 1, 0.6, 0.9 }, 0.05, 10, { 0.6, 0.9, 1 }) })
upgrade("powerballad", { critOver = { E.fire(-50, -20, 12, 28, 0.1, 0.9), E.fire(50, -20, 12, 28, 0.16, 0.9, true) }, particles3 = E.motes(GOLDEN, 0.1, 10) })

---------------------------------------------------------------------------
-- Race skins
---------------------------------------------------------------------------
upgrade("royalseal", { critOver = { E.star(0, 4, 100, GOLDEN, 0.12, 0.28) }, particles3 = E.motes(GOLDEN, 0.12, 8) })
upgrade("hearthale", { critOver = { E.star(0, 18, 80, { 1, 0.95, 0.8 }, 0.18, 0.25) } })
upgrade("moonwell", { critOver = { E.spiral(0, 24, 70, 130, { 0.75, 0.85, 1 }, 0.08, 0.9, 0.55), E.star(0, 30, 80, { 0.85, 0.9, 1 }, 0.1, 0.3) } })
upgrade("pocketrocket", { critOver = { E.smoke(0, -40, 90, { 0.85, 0.85, 0.85 }, 0, 0.9, 0.4), E.star(0, 30, 100, { 1, 0.8, 0.4 }, 0.3, 0.25) },
                          particles3 = E.embers(-30, { 1, 0.6, 0.2 }, 0, 12) })
upgrade("axefury", { critUnder = { E.ground(-34, 150, DUST, 0.12, 0.5) }, particles3 = E.rocks(-30, nil, 0.12, 8) })
upgrade("bansheewail", { critUnder = { E.smoke(0, 0, 140, { 0.6, 0.75, 0.9 }, 0, 1.0, 0.35) }, critOver = { E.nova(0, 0, 80, { 0.7, 0.85, 1 }, 0.1, 0.5, 0.5) } })
upgrade("totemstomp", { critUnder = { E.ground(-34, 170, DUST, 0.2, 0.55), E.ground(-34, 190, DUST, 0.4, 0.5) }, particles3 = E.rocks(-30, nil, 0.2, 10) })
upgrade("berserk", { critOver = { E.star(0, 0, 100, { 1, 0.4, 0.3 }, 0.1, 0.22) }, critUnder = { E.ground(-34, 150, { 1, 0.45, 0.3 }, 0.1, 0.5) } })

-- Skins whose number shrinks away (critScaleKeys) keep their effects full
-- size while it's gone.
local function steady(list)
    for _, d in ipairs(list) do d.steady = true end
    return list
end
local CYAN, VIOLET, RED = { 0.45, 0.9, 1 }, { 0.78, 0.55, 1 }, { 1, 0.25, 0.25 }

---------------------------------------------------------------------------
-- Pop skins
---------------------------------------------------------------------------
upgrade("wishingstar", {
    critOver = { E.star(62, 56, 60, { 1, 0.7, 0.9 }, 0.58, 0.3), E.star(-54, 50, 54, { 0.6, 0.9, 1 }, 0.72, 0.3), E.star(6, 82, 60, GOLDEN, 0.86, 0.3) },
    particles3 = E.motes({ 1, 0.92, 0.7 }, 0.1, 10, { 0.85, 0.8, 1 }),
})
upgrade("midnightchime", {
    critOver = { E.spiral(0, 20, 80, 150, { 0.75, 0.9, 1 }, 0.56, 0.9, 0.55), E.star(82, -40, 50, WHITE, 0.78, 0.3) },
})
upgrade("snowqueen", {
    critUnder = { E.ground(-40, 160, { 0.8, 0.92, 1 }, 0.05, 0.6) },
    critOver = { E.nova(0, 0, 84, { 0.75, 0.9, 1 }, 0.3, 0.5, 0.6), E.star(0, 0, 100, WHITE, 0.3, 0.3) },
})
upgrade("savannasunrise", {
    critUnder = { E.ground(-44, 170, { 1, 0.7, 0.4 }, 0.1, 0.7, 0.7) },
    critOver = { E.star(0, 60, 90, { 1, 0.85, 0.5 }, 0.6, 0.4) },
    particles3 = E.motes({ 1, 0.8, 0.45 }, 0.3, 10),
})
upgrade("rubberhose", {
    critOver = { E.smoke(0, -18, 110, { 0.95, 0.94, 0.9 }, 0, 0.6, 0.5), E.star(0, 0, 80, { 0.96, 0.95, 0.9 }, 0, 0.2) },
})
upgrade("toybox", {
    critUnder = { E.ground(-46, 140, { 0.8, 0.65, 0.45 }, 0.16, 0.45), E.ground(-46, 150, { 0.8, 0.65, 0.45 }, 1.3, 0.45) },
    critOver = { E.star(0, 10, 70, WHITE, 0.3, 0.25) },
    particles3 = { tex = "pixel", count = 0, critCount = 14, size = { 3, 6 }, speed = { 60, 140 }, dir = { 30, 150 },
                   delay = 1.1, gravity = -200, life = { 0.5, 0.8 }, randomColor = true, blend = "BLEND", spin = 8 },
})
upgrade("islandalert", { critOver = { E.star(-56, 0, 40, { 0.4, 1, 0.6 }, 0.62, 0.3) } })
upgrade("frostedglass", { critOver = { E.star(-50, 20, 40, WHITE, 0.65, 0.3), E.star(52, -18, 30, WHITE, 0.75, 0.25) }, particles3 = E.motes(WHITE, 0.3, 6) })
upgrade("edgeglow", { critOver = { E.star(0, 0, 70, { 0.75, 0.88, 1 }, 0.82, 0.3) } })
upgrade("fastcharge", {
    critOver = { E.fork(-46, -32, -26, -10, 0.52, { 1, 1, 0.6 }, 6), E.fork(36, -32, 20, -8, 0.56, { 1, 1, 0.6 }, 6),
                 E.star(-5, -32, 60, { 0.5, 1, 0.6 }, 0.52, 0.3) },
})
upgrade("readreceipt", { critOver = steady({ E.star(40, 10, 50, { 0.55, 0.8, 1 }, 0.42, 0.25) }) })
upgrade("ringcloser", { critOver = { E.star(0, 0, 110, WHITE, 0.66, 0.3) }, particles3 = E.motes({ 0.6, 1, 0.4 }, 0.66, 8, { 0.3, 0.9, 1 }) })

---------------------------------------------------------------------------
-- Anime skins
---------------------------------------------------------------------------
upgrade("mostwanted", { critOver = { E.smoke(0, -40, 100, { 0.9, 0.8, 0.6 }, 0.12, 0.6, 0.35), E.star(0, 0, 80, GOLDEN, 0.12, 0.22) } })
upgrade("blackcrescent", {
    critUnder = { E.orb(0, 0, 130, { 1, 0.15, 0.2 }, 0, 1.0, 0.6), E.smoke(0, 0, 130, { 0.25, 0.02, 0.05 }, 0.05, 1.0, 0.5, "BLEND") },
    critOver = { E.star(0, 0, 90, RED, 0.3, 0.25) },
})
upgrade("shinobi", {
    critUnder = { E.ground(-40, 160, CYAN, 0.2, 0.55) },
    critOver = { E.nova(0, 0, 90, CYAN, 0.2, 0.5, 0.7), E.smoke(0, 0, 120, { 0.9, 0.9, 0.92 }, 0.95, 0.5, 0.45) },
})
upgrade("menacing", { critUnder = { E.orb(0, 0, 130, VIOLET, 0, 1.1, 0.5), E.ground(-40, 170, VIOLET, 0.05, 0.7, 0.6) } })
upgrade("flowingform", {
    critOver = { E.nova(0, 0, 90, { 0.5, 0.8, 1 }, 0.2, 0.5, 0.6) },
    particles3 = { tex = "bubble", count = 0, critCount = 10, size = { 5, 10 }, speed = { 30, 80 }, dir = { 40, 140 },
                   origin = { 0, 20 }, delay = 0.2, gravity = 20, life = { 0.6, 1.0 }, color = { 0.6, 0.9, 1 } },
})
upgrade("gotcha", { critOver = steady({ E.star(0, -8, 100, { 1, 0.95, 0.7 }, 1.0, 0.3), E.nova(0, -8, 70, { 0.5, 0.95, 0.9 }, 1.02, 0.45, 0.6) }) })
upgrade("sootsprites", { critUnder = { E.smoke(0, 0, 130, { 0.15, 0.13, 0.12 }, 0, 0.9, 0.55, "BLEND") } })
upgrade("transmute", {
    critUnder = { E.ground(-34, 170, { 0.5, 0.85, 1 }, 0.3, 0.55) },
    critOver = { E.fork(-70, -20, -20, -26, 0.2, { 0.5, 0.85, 1 }, 8), E.fork(70, -24, 20, -26, 0.26, { 0.5, 0.85, 1 }, 8),
                 E.star(0, -24, 100, { 0.7, 0.92, 1 }, 0.32, 0.25) },
    particles3 = E.rocks(-30, { 0.6, 0.62, 0.68 }, 0.32, 8),
})
upgrade("finalpage", { critUnder = { E.smoke(0, 0, 140, { 0.25, 0.02, 0.05 }, 0.2, 1.1, 0.4, "BLEND") }, critOver = { E.star(56, -6, 50, RED, 0.55, 0.3) } })
upgrade("steamblades", {
    critOver = { E.star(0, 0, 110, WHITE, 0.08, 0.22), E.smoke(-30, 20, 100, { 0.95, 0.95, 0.97 }, 0.1, 0.9, 0.45), E.smoke(30, -10, 90, { 0.95, 0.95, 0.97 }, 0.15, 0.9, 0.4) },
})
upgrade("sevenstars", {
    critUnder = { E.ground(-36, 170, GOLDEN, 0.55, 0.6) },
    critOver = { E.spiral(0, 40, 70, 150, { 1, 0.85, 0.45 }, 0.55, 0.8, 0.55), E.star(0, 30, 110, { 1, 0.92, 0.6 }, 0.55, 0.35) },
})
upgrade("smash", {
    critUnder = { E.ground(-36, 200, { 0.9, 0.9, 1 }, 0.16, 0.55), E.smoke(0, -30, 160, { 0.8, 0.75, 0.68 }, 0.18, 0.8, 0.4, "BLEND") },
    particles3 = E.rocks(-30, nil, 0.16, 12),
})
upgrade("moonlitcharm", {
    critOver = { E.spiral(0, 20, 80, 150, { 1, 0.6, 0.85 }, 0.1, 0.9, 0.55), E.star(0, 44, 80, { 1, 0.95, 0.75 }, 0.1, 0.35) },
})
upgrade("hexbarrier", { critUnder = { E.ground(-40, 170, { 1, 0.6, 0.2 }, 0.45, 0.55) }, critOver = { E.star(0, 0, 100, { 1, 0.75, 0.35 }, 0.45, 0.25) } })
upgrade("chainrev", {
    critOver = { E.splat(-30, -10, 40, { 0.55, 0.02, 0.03 }, 0.15, 0.9, 1), E.splat(34, 12, 32, { 0.55, 0.02, 0.03 }, 0.25, 0.9, 2.5),
                 E.star(0, 0, 80, { 1, 0.7, 0.35 }, 0.1, 0.2) },
})
upgrade("pressurepoint", {
    critUnder = { E.ground(-36, 190, { 1, 0.85, 0.5 }, 0.7, 0.55) },
    critOver = { E.nova(0, 0, 90, { 1, 0.9, 0.5 }, 0.7, 0.45, 0.6), E.star(0, 0, 130, WHITE, 0.7, 0.25) },
})
upgrade("spiraldrill", { critUnder = { E.ground(-40, 170, { 0.9, 0.6, 0.4 }, 0.3, 0.55) }, critOver = { E.star(0, 40, 100, { 0.6, 0.95, 1 }, 0.35, 0.3) },
                         particles3 = E.rocks(-36, { 0.55, 0.42, 0.32 }, 0.3, 10) })
upgrade("linkstart", { critOver = { E.star(0, 0, 100, CYAN, 0.35, 0.3), E.nova(0, 0, 80, CYAN, 0.36, 0.45, 0.6) } })
upgrade("neonslide", {
    critUnder = { E.ground(-30, 180, { 1, 0.25, 0.3 }, 0.05, 0.6), E.smoke(-50, -20, 110, { 0.55, 0.55, 0.58 }, 0.05, 0.9, 0.4, "BLEND") },
})
upgrade("oneanddone", {
    critUnder = { E.ground(-36, 220, WHITE, 0.25, 0.6), E.smoke(0, -30, 180, { 0.85, 0.8, 0.72 }, 0.27, 0.9, 0.4, "BLEND") },
    particles3 = E.rocks(-30, nil, 0.25, 14),
})
upgrade("powerlevel", {
    critUnder = { E.ground(-40, 170, { 1, 0.9, 0.3 }, 0.05, 0.9, 0.6) },
    critOver = { E.fork(-40, -50, -20, -10, 0.3, { 1, 0.95, 0.5 }, 8), E.fork(40, -50, 20, -10, 0.45, { 1, 0.95, 0.5 }, 8),
                 E.star(14, 4, 110, WHITE, 0.62, 0.25) },
})
upgrade("curseddomain", { critUnder = { E.smoke(0, 0, 150, { 0.35, 0.02, 0.06 }, 0.2, 1.2, 0.45, "BLEND") }, critOver = { E.star(0, 0, 110, RED, 0.35, 0.22) } })
upgrade("bountyjazz", { critOver = { E.star(-60, 20, 50, GOLDEN, 0.3, 0.3) }, particles3 = E.motes(GOLDEN, 0.3, 8) })
upgrade("overflow", {
    critUnder = { E.ground(-40, 190, VIOLET, 0.45, 0.6) },
    critOver = { E.star(0, 0, 130, { 1, 0.9, 1 }, 0.45, 0.3), E.spiral(0, 30, 80, 160, { 0.8, 0.6, 1 }, 0.45, 0.8, 0.5) },
})
upgrade("facedowncard", { critOver = steady({ E.star(0, 30, 120, GOLDEN, 0.52, 0.3), E.spiral(0, 40, 90, 170, GOLDEN, 0.52, 0.8, 0.45) }) })
upgrade("isekaid", {
    critOver = steady({ E.star(0, 0, 160, WHITE, 0.32, 0.25), E.spiral(0, 20, 90, 170, CYAN, 0.45, 0.8, 0.5), E.star(0, 0, 100, CYAN, 0.92, 0.3) }),
    critUnder = steady({ E.ground(-40, 180, CYAN, 0.42, 0.7, 0.6) }),
})
upgrade("angervein", { critOver = { E.smoke(0, 30, 90, { 0.95, 0.95, 0.95 }, 0.1, 0.9, 0.4), E.star(54, 28, 60, RED, 0.05, 0.22) } })
upgrade("iaido", {
    critUnder = { E.ground(-30, 200, WHITE, 0.62, 0.5, 0.7) },
    critOver = { E.star(0, -36, 70, WHITE, 0.54, 0.25), E.star(0, 0, 130, { 1, 0.95, 0.85 }, 0.62, 0.22) },
})
