local _, ns = ...

-- The floating numbers: a pool of "pops" (one per hit), each a holder frame
-- placed against an anchor (a nameplate, a screen anchor or the preview box),
-- with a scaled inner frame carrying the text layers and decor textures.
-- Particles are loose textures anchored to the same spot. One OnUpdate
-- drives everything that's alive; only positions, scales, alphas and colors
-- are animated, so secret amounts are never touched after SetFormattedText.

local Engine = {}
ns.Engine = Engine

local TEX = "Interface\\AddOns\\SkinDeep\\Media\\Textures\\"
local MAX_POPS, MAX_LAYERS, MAX_PARTS = 40, 5, 24
local FADE_IN = 0.05
local POP_TIME = 0.12

local random, sin, cos, floor, min, max, rad = math.random, math.sin, math.cos, math.floor, math.min, math.max, math.rad
local pi, atan2 = math.pi, math.atan2 or math.atan
local tremove, tinsert = table.remove, table.insert

local WHITE = { 1, 1, 1 }
local EMPTY = {}
local HEAL = { 0.35, 1, 0.4 }
local WORD = { 0.9, 0.9, 0.9 }
local INCOMING = { 1, 0.35, 0.3 }

-- Spell school colors (UNIT_COMBAT's school bitmask, single schools).
local SCHOOL = {
    [2]  = { 1, 0.9, 0.5 },   -- Holy
    [4]  = { 1, 0.5, 0 },     -- Fire
    [8]  = { 0.3, 1, 0.3 },   -- Nature
    [16] = { 0.5, 1, 1 },     -- Frost
    [32] = { 0.6, 0.55, 1 },  -- Shadow
    [64] = { 1, 0.5, 1 },     -- Arcane
}

local function rr(v)
    if type(v) == "table" then return v[1] + random() * (v[2] - v[1]) end
    return v or 0
end

local function lighten(c, k)
    return { c[1] + (1 - c[1]) * k, c[2] + (1 - c[2]) * k, c[3] + (1 - c[3]) * k }
end

local function sizeOf(s)
    if type(s) == "table" then return s[1], s[2] end
    return s, s
end

local function setFont(fs, path, size, flags)
    fs:SetFont(path, size, flags or "")
    if not fs:GetFont() then fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE") end
end

---------------------------------------------------------------------------
-- Motions: set p.mx, p.my (offset from the pop's origin) and p.ms (extra
-- scale). init runs once at spawn.
---------------------------------------------------------------------------
local MOTIONS = {}

MOTIONS.rise = {
    update = function(p, t, dt, a)
        p.mx = (a.sway or 0) * sin(t * (a.freq or 5) + p.phase)
        p.my = (a.speed or 60) * t
    end,
}

MOTIONS.toss = {
    init = function(p, a) p.vx = p.dir * rr(a.vx or { 50, 100 }); p.vy = rr(a.vy or 150) end,
    update = function(p, t, dt, a)
        p.mx = p.vx * t
        p.my = p.vy * t - 0.5 * (a.gravity or 380) * t * t
    end,
}

MOTIONS.bounce = {
    init = function(p, a) p.vx = p.dir * rr(a.vx or { 40, 80 }); p.vy = rr(a.vy or 170) end,
    update = function(p, t, dt, a)
        p.vy = p.vy - (a.gravity or 520) * dt
        p.mx = p.mx + p.vx * dt
        p.my = p.my + p.vy * dt
        local floorY = a.floor or -30
        if p.my < floorY and p.vy < 0 then
            p.my = floorY
            p.vy = -p.vy * (a.damp or 0.45)
            p.vx = p.vx * 0.7
        end
    end,
}

MOTIONS.slam = {
    update = function(p, t, dt, a)
        local time = a.time or 0.14
        if t < time then
            local k = 1 - t / time
            p.ms = 1 + ((a.from or 2) - 1) * k * k * k
            p.my = 0
        else
            p.ms = 1
            p.my = -(a.drift or 18) * (t - time)
        end
    end,
}

MOTIONS.spiral = {
    update = function(p, t, dt, a)
        local ang = p.phase + p.dir * (a.spin or 4) * t
        local r = (a.r0 or 8) + (a.grow or 35) * t
        p.mx = r * cos(ang)
        p.my = r * sin(ang) + (a.rise or 30) * t
    end,
}

MOTIONS.drip = {
    update = function(p, t, dt, a)
        local hold = a.hold or 0.3
        if t <= hold then p.my = 0; return end
        local d = t - hold
        p.my = -(a.speed or 6) * d - 0.5 * (a.accel or 70) * d * d
    end,
}

MOTIONS.hop = {
    update = function(p, t, dt, a)
        p.my = floor(t / (a.step or 0.06)) * (a.px or 7)
    end,
}

MOTIONS.dash = {
    update = function(p, t, dt, a)
        local k = min(1, t / (a.time or 0.25))
        local e = 1 - (1 - k) * (1 - k) * (1 - k)
        -- arrive: fly in from the side and stop in place (an arrow);
        -- otherwise dash out from the spot.
        p.mx = a.arrive and -p.dir * (a.dist or 70) * (1 - e) or p.dir * (a.dist or 70) * e
        p.my = (a.rise or 20) * t
    end,
}

-- Falls in from above, squashes on impact, then slowly sinks.
MOTIONS.drop = {
    update = function(p, t, dt, a)
        local fall, height, sinkAt = a.fall or 0.12, a.height or 50, a.sinkAt or 0.35
        if t < fall then
            local k = t / fall
            p.my, p.ms = height * (1 - k * k), 1
        else
            p.ms = 1 + (a.squash or 0.3) * max(0, 1 - (t - fall) / 0.1)
            p.my = t > sinkAt and -(t - sinkAt) * (a.sink or 14) or 0
        end
    end,
}

-- Rises in jittery sideways snaps, like crackling lightning.
MOTIONS.zap = {
    update = function(p, t, dt, a)
        p.my = (a.speed or 42) * t
        p.mx = sin(floor(t / (a.step or 0.06)) * 12.99 + p.phase) * (a.jolt or 7)
    end,
}

-- Shows offset for an instant, then snaps into place and rises.
MOTIONS.blink = {
    update = function(p, t, dt, a)
        if t < (a.at or 0.07) then
            p.mx, p.my, p.ms = p.dir * (a.from or 16), 6, 0.85
        else
            p.mx, p.my, p.ms = 0, (a.rise or 22) * t, 1
        end
    end,
}

-- Grows out of a point with an overshoot, then rises.
MOTIONS.implode = {
    update = function(p, t, dt, a)
        local grow = a.time or 0.15
        if t < grow then
            p.ms = 0.15 + 1.1 * (t / grow) ^ 0.6
        elseif t < grow + 0.1 then
            p.ms = 1.25 - 0.25 * (t - grow) / 0.1
        else
            p.ms = 1
        end
        p.my = t > grow and (t - grow) * (a.rise or 30) or 0
    end,
}

-- Rises in a few measured steps, each one stamped with a little pulse.
MOTIONS.march = {
    update = function(p, t, dt, a)
        local stepTime, steps = a.stepTime or 0.22, a.steps or 3
        local step = min(steps, floor(t / stepTime))
        p.my = step * (a.px or 14) + (step >= steps and (t - steps * stepTime) * (a.drift or 10) or 0)
        local k = (t % stepTime) / stepTime
        p.ms = step < steps and 1 + (a.pulse or 0.12) * max(0, 1 - k * 4) or 1
    end,
}

-- Rises with a lurching side-to-side stagger.
MOTIONS.lurch = {
    update = function(p, t, dt, a)
        local side = floor(t / (a.period or 0.16)) % 2 == 0 and -1 or 1
        p.mx = side * (a.amp or 6) * p.dir
        p.my = (a.speed or 22) * t
    end,
}

-- Pops up from below, then rises.
MOTIONS.sneak = {
    update = function(p, t, dt, a)
        local rise = a.rise or 0.1
        p.my = t < rise and -(a.from or 16) * (1 - t / rise) or (a.speed or 28) * (t - rise)
    end,
}

Engine.MOTIONS = MOTIONS

---------------------------------------------------------------------------
-- Pool
---------------------------------------------------------------------------
local active, free = {}, {}
local driver = CreateFrame("Frame")
driver:Hide()

local function newPop()
    local p = CreateFrame("Frame", nil, UIParent)
    p:SetSize(1, 1)
    p:Hide()
    local inner = CreateFrame("Frame", nil, p)
    inner:SetSize(1, 1)
    inner:SetPoint("CENTER")
    p.inner = inner
    p.decor = inner:CreateTexture(nil, "BACKGROUND")
    p.burst = inner:CreateTexture(nil, "BORDER")
    p.burst2 = inner:CreateTexture(nil, "BORDER", nil, 1)
    p.ring = inner:CreateTexture(nil, "ARTWORK")
    p.layers = {}
    for i = 1, MAX_LAYERS do
        local fs = inner:CreateFontString(nil, "OVERLAY")
        fs:SetDrawLayer("OVERLAY", -i) -- the first layer sits right behind the text
        p.layers[i] = fs
    end
    p.text = inner:CreateFontString(nil, "OVERLAY")
    p.text:SetDrawLayer("OVERLAY", 7)
    p.parts = {}
    p.containers = {}
    return p
end

local function hideTextures(p)
    p.decor:Hide(); p.burst:Hide(); p.burst2:Hide(); p.ring:Hide()
    for _, part in ipairs(p.parts) do part.tex:Hide(); part.alive = false end
    for _, c in pairs(p.containers) do c:Hide() end
end

-- The crit title's widgets: an unscaled holder at the title's offset, and a
-- frame centered on it that scales on its own (an offset on a scaled frame
-- would scale too).
function Engine.TitleKit(p)
    local c = Engine.Container(p, "critTitle", true)
    if not c.frame then
        c.holder = CreateFrame("Frame", nil, c)
        c.holder:SetSize(1, 1)
        c.frame = CreateFrame("Frame", nil, c.holder)
        c.frame:SetSize(1, 1)
        c.frame:SetPoint("CENTER")
        c.shadow = c.frame:CreateFontString(nil, "OVERLAY")
        c.shadow:SetDrawLayer("OVERLAY", 1)
        c.shadow:SetPoint("CENTER", c.frame, "CENTER", 2, -2)
        c.text = c.frame:CreateFontString(nil, "OVERLAY")
        c.text:SetDrawLayer("OVERLAY", 2)
        c.text:SetPoint("CENTER", c.frame, "CENTER", 0, 0)
    end
    return c
end

-- A frame a skin can build its own widgets in, kept with the pop and
-- reused. scaled: inside the scaled inner frame (moves and scales with the
-- number); otherwise unscaled on the holder (for loose particles).
function Engine.Container(p, key, scaled)
    local c = p.containers[key]
    if not c then
        c = CreateFrame("Frame", nil, scaled and p.inner or p)
        c:SetSize(1, 1)
        c:SetPoint("CENTER")
        p.containers[key] = c
    end
    c:Show()
    return c
end

local function release(i)
    local p = tremove(active, i)
    p:Hide()
    p:ClearAllPoints()
    hideTextures(p)
    p.anchor = nil
    free[#free + 1] = p
end

---------------------------------------------------------------------------
-- Spawn
---------------------------------------------------------------------------
-- Writes the hit's text into one FontString.
local function writeText(fs, e, skin)
    if e.kind == "word" then
        if e.amount ~= nil and C_StringUtil and C_StringUtil.TruncateWhenZero then
            -- "Absorb 12": the word, then whatever got through (nothing for a zero).
            local ok, rest = pcall(C_StringUtil.TruncateWhenZero, e.amount)
            if ok and pcall(fs.SetFormattedText, fs, "%s %s", e.word, rest) then return end
        end
        fs:SetText(e.word)
    elseif e.side == "inc" then
        ns.FormatAmount(fs, e.kind == "heal" and "+%s" or "-%s", e.amount)
    else
        ns.FormatAmount(fs, e.crit and (skin.critFormat or "%s") or (skin.format or "%s"), e.amount)
    end
end

-- dir: the pop's motion direction (-1/1); d.trail puts the texture's x
-- offset behind the motion (an arrow streak).
local function setupTexture(tex, d, rotation, dir)
    tex:SetTexture(TEX .. d.tex .. ".tga")
    tex:SetBlendMode(d.blend or "ADD")
    local c = d.color or WHITE
    tex:SetVertexColor(c[1], c[2], c[3])
    local w, h = sizeOf(d.size or 64)
    tex:SetSize(w, h)
    tex:ClearAllPoints()
    local x = d.x or 0
    if d.trail then x = -(dir or 1) * x end
    tex:SetPoint("CENTER", tex:GetParent(), "CENTER", x, d.y or 0)
    if tex.SetRotation then tex:SetRotation(rotation or 0) end
    tex:SetAlpha(0)
    tex:Show()
end

local function chooseColor(e, skin, db)
    if e.kind == "heal" then return skin.healColor or HEAL end
    if e.kind == "word" then return skin.wordColor or WORD end
    if e.side == "inc" then return skin.incColor or INCOMING end
    -- School 1 is Physical; anything else (including mixed schools) is a spell.
    local physical = (e.school or 1) == 1
    local phys = skin.physColor or skin.color
    local spell = skin.spellColor or skin.color
    local scheme = db.colorScheme or "skin"
    local c
    if scheme == "classic" then
        c = physical and ns.CLASSIC_PHYSICAL or ns.CLASSIC_SPELL
    elseif scheme == "school" then
        c = physical and phys or SCHOOL[e.school] or spell
    else
        c = physical and phys or spell
    end
    -- Crits: the same color, brighter.
    if e.crit then c = lighten(c, 0.3) end
    return c
end

-- Numbers landing on the same spot in quick succession stack upward.
local lanes = setmetatable({}, { __mode = "k" })

local function laneOffset(anchor, step)
    local now = GetTime()
    local lane = lanes[anchor]
    if not lane or now - lane.at > 0.35 then
        lane = { at = now, n = 0 }
        lanes[anchor] = lane
    end
    lane.at = now
    lane.n = lane.n + 1
    return ((lane.n - 1) % 4) * (step or 16)
end

-- Fills particle slots from `first` on; returns the next free slot, so a
-- second system (skin.particles2) can follow the first. Unused slots were
-- already hidden by hideTextures.
local function spawnParticles(p, pd, crit, color, first)
    first = first or 1
    local count = crit and (pd.critCount or pd.count or 0) or (pd.count or 0)
    count = min(count, MAX_PARTS - first + 1)
    for i = first, first + count - 1 do
        local part = p.parts[i]
        if not part then
            part = { tex = p:CreateTexture(nil, "OVERLAY") }
            p.parts[i] = part
        end
        local tex = part.tex
        tex:SetTexture(TEX .. pd.tex .. ".tga")
        tex:SetBlendMode(pd.blend or "ADD")
        local c = pd.color or color
        if pd.randomColor then c = { 0.4 + random() * 0.6, 0.4 + random() * 0.6, 0.4 + random() * 0.6 } end
        if pd.altColor and random() < 0.4 then c = pd.altColor end
        tex:SetVertexColor(c[1], c[2], c[3])
        local size = rr(pd.size or { 4, 8 })
        local aspect = pd.aspect or (pd.tex == "shard" and 0.5) or 1
        tex:SetSize(size * aspect, size)
        local angle = rad(rr(pd.dir or { 0, 360 }))
        part.t, part.life = 0, rr(pd.life or { 0.4, 0.8 })
        if pd.inward then
            -- Converge: start out on a ring, arrive at the center at end of life.
            local r = rr(pd.radius or { 50, 70 })
            part.x, part.y = cos(angle) * r, sin(angle) * r
            part.vx, part.vy = -part.x / part.life, -part.y / part.life
        else
            local speed = rr(pd.speed or { 30, 80 })
            part.vx, part.vy = cos(angle) * speed, sin(angle) * speed
            part.x, part.y = 0, 0
        end
        if pd.mirror then part.vx = part.vx * -p.dir end
        part.gravity = pd.gravity or 0
        part.spin = pd.spin and (random() - 0.5) * 2 * pd.spin or 0
        part.rot = random() * 6.28
        part.orient = pd.orient   -- point along the flight (bolts)
        part.sway = pd.sway       -- drift side to side (wisps)
        part.alive = true
        tex:Show()
    end
    return first + count
end

function Engine.Spawn(e)
    local db = ns.db
    if not db then return end
    local skin = (e.skin and ns.Skins[e.skin]) or ns.CurrentSkin()
    if #active >= MAX_POPS then release(1) end
    local p = tremove(free) or newPop()

    local crit = e.crit and true or false
    local inc = e.side == "inc"
    p.skin, p.crit = skin, crit
    p.args = skin.motionArgs or EMPTY
    p.motion = MOTIONS[skin.motion] or MOTIONS.rise
    p.dur = (crit and skin.critDur or skin.dur) or 1.1
    p.fade = skin.fade or 0.35
    p.pop = skin.pop or 0.3
    p.base = (db.scale or 1) * (inc and 0.8 or 1) * (crit and (skin.critScale or 1.5) or 1)
    p.shake = crit and skin.shake or nil
    p.drum = crit and skin.drum or nil
    p.t, p.mx, p.my, p.ms = 0, 0, 0, 1
    p.dir = e.dir or (random() < 0.5 and -1 or 1)
    p.phase = random() * 6.28
    p.flicker = skin.flicker
    p.blink = skin.blink
    -- Crit color flashing is part of a skin's own palette only.
    p.cycle = crit and (db.colorScheme or "skin") == "skin" and skin.critCycle or nil
    p.cyclePeriod = skin.cyclePeriod or 0.08

    -- Where: anchor + origin. Origins jitter a little and stack per anchor.
    p.anchor = e.anchor or UIParent
    p.anchorPoint = e.point or "CENTER"
    p.ax, p.ay = e.ax or 0, e.ay or 0
    p.ox = (random() - 0.5) * 30
    p.oy = laneOffset(p.anchor, skin.laneStep)
    p:SetFrameStrata(e.strata or "LOW")

    -- Text and its layers (skins with ownText draw their own).
    local color = chooseColor(e, skin, db)
    p.color = color
    local size = skin.size or 24
    if skin.ownText then
        p.text:Hide()
        for i = 1, MAX_LAYERS do p.layers[i]:Hide() end
    else
        p.text:Show()
        setFont(p.text, skin.font, size, skin.outline)
        p.text:SetTextColor(color[1], color[2], color[3], 1)
        if skin.shadow then
            p.text:SetShadowColor(0, 0, 0, 1)
            p.text:SetShadowOffset(skin.shadow[1], skin.shadow[2])
        else
            p.text:SetShadowOffset(0, 0)
        end
        p.text:ClearAllPoints()
        p.text:SetPoint("CENTER", p.inner, "CENTER", 0, 0)
        writeText(p.text, e, skin)
        local layers = skin.layers or EMPTY
        for i = 1, MAX_LAYERS do
            local fs, L = p.layers[i], layers[i]
            if L then
                setFont(fs, skin.font, size, skin.outline)
                local c = L.color or WHITE
                fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
                fs:SetShadowOffset(0, 0)
                fs:ClearAllPoints()
                fs:SetPoint("CENTER", p.inner, "CENTER", L.trail and (-p.dir * L.x) or L.x, L.y)
                writeText(fs, e, skin)
                fs:Show()
            else
                fs:Hide()
            end
        end
    end

    -- Decor, bursts, rings, particles.
    hideTextures(p)
    p.decorDef, p.burstDef, p.burst2Def, p.ringDef = nil, nil, nil, nil
    if db.effects and e.kind ~= "word" then
        -- critReplacesDecor: a crit swaps the everyday decor for its own.
        if skin.decor and not (crit and skin.critReplacesDecor) then
            p.decorDef = skin.decor
            p.decorRot = skin.decor.randomRot and random() * 6.28 or (skin.decor.rot or 0)
            setupTexture(p.decor, skin.decor, p.decorRot, p.dir)
        end
        if crit and skin.critDecor then
            p.burstDef = skin.critDecor
            p.burstRot = skin.critDecor.randomRot and random() * 6.28 or (skin.critDecor.rot or 0) * p.dir
            setupTexture(p.burst, skin.critDecor, p.burstRot, p.dir)
        end
        if crit and skin.critDecor2 then
            p.burst2Def = skin.critDecor2
            p.burst2Rot = skin.critDecor2.randomRot and random() * 6.28 or (skin.critDecor2.rot or 0) * p.dir
            setupTexture(p.burst2, skin.critDecor2, p.burst2Rot, p.dir)
        end
        if crit and skin.ring then
            p.ringDef = { tex = "ring", size = skin.ring.size, color = skin.ring.color, alpha = skin.ring.alpha,
                          grow = skin.ring.grow, blend = "ADD" }
            setupTexture(p.ring, p.ringDef, 0)
        end
        local slot = 1
        if skin.particles then slot = spawnParticles(p, skin.particles, crit, color, slot) end
        if skin.particles2 then spawnParticles(p, skin.particles2, crit, color, slot) end
    end

    -- Crit title: a banner word above the number ("GRAND MARSHAL").
    p.titleDef = nil
    if crit and skin.critTitle and e.kind == "dmg" then
        local d, c = skin.critTitle, Engine.TitleKit(p)
        c.holder:ClearAllPoints()
        c.holder:SetPoint("CENTER", c, "CENTER", d.x or 0, d.y or 44)
        for _, fs in ipairs({ c.shadow, c.text }) do
            setFont(fs, d.font or ns.Fonts.friz, d.size or 18, "THICKOUTLINE")
            fs:SetText(d.text)
        end
        local sc = d.shadowColor or { 0, 0, 0 }
        c.shadow:SetTextColor(sc[1], sc[2], sc[3], 1)
        local c1 = d.colors[1]
        c.text:SetTextColor(c1[1], c1[2], c1[3], 1)
        c.frame:SetScale(1)
        c.frame:SetAlpha(0)
        p.titleDef, p.titleKit = d, c
    end

    -- Skins with their own machinery (Jackpot.lua) build it here; they may
    -- also adjust p.dur, p.base, p.landAt and friends.
    if skin.onSpawn then skin.onSpawn(p, e, crit) end

    if p.motion.init then p.motion.init(p, p.args) end
    tinsert(active, p)
    Engine.Step(p, 0)
    p:Show()
    driver:Show()
end

---------------------------------------------------------------------------
-- Animation
---------------------------------------------------------------------------
-- Texture options: alpha, grow (size gain over its life), spin (rad/s),
-- delay (seconds before it appears), snap (starting size factor that eases
-- to 1 over snapTime: >1 slams in, <1 springs open), unwind (extra rotation
-- that eases away with the snap), flicker (random alpha and jitter, like
-- crackling lightning).
local function animateTexture(tex, d, t, life, rotation)
    if not d then return end
    local delay = d.delay or 0
    if t < delay then tex:SetAlpha(0); return end
    t, life = t - delay, max(0.05, life - delay)
    local k = min(1, t / life)
    local a = (d.alpha or 1) * min(1, t / FADE_IN) * (1 - k)
    local rot = rotation + (d.spin or 0) * t
    if d.flicker then
        a = a * (0.2 + 0.8 * random())
        rot = rot + (random() - 0.5) * 0.8
    end
    tex:SetAlpha(max(0, a))
    local w, h = sizeOf(d.size or 64)
    local g = 1 + (d.grow or 0) * k
    if d.snap then
        local snapTime = d.snapTime or 0.15
        if t < snapTime then
            local q = 1 - t / snapTime
            g = g * (1 + (d.snap - 1) * q * q)
            rot = rot + (d.unwind or 0) * q * q
        end
    end
    tex:SetSize(max(0.1, w * g), max(0.1, h * g))
    if tex.SetRotation then tex:SetRotation(rot) end
end

-- Advances one pop by dt seconds; false once it's done.
function Engine.Step(p, dt)
    local t = p.t + dt
    p.t = t
    if t >= p.dur then return false end

    p.motion.update(p, t, dt, p.args)

    -- Scale: settle from the "pop" size during the first moments.
    local s = p.base * (p.ms or 1)
    if p.pop > 0 and t < POP_TIME then
        local k = 1 - t / POP_TIME
        s = s * (1 + p.pop * k * k)
    end
    -- War drum: a few hard pulses in a row on crits.
    if p.drum then
        local gap = p.drum.gap or 0.13
        for i = 0, (p.drum.count or 3) - 1 do
            local d = t - i * gap
            if d >= 0 and d < gap then
                local q = 1 - d / gap
                s = s * (1 + (p.drum.amp or 0.25) * q * q)
            end
        end
    end
    p.inner:SetScale(max(0.01, s))

    -- Crit title: pops in big, flashes through its colors, then settles.
    if p.titleDef then
        local d, c = p.titleDef, p.titleKit
        local k = t - (d.delay or 0.05)
        if k < 0 then
            c.frame:SetAlpha(0)
        else
            local pop = max(0, 1 - k / 0.2)
            c.frame:SetScale(1 + (d.pop or 1.2) * pop * pop)
            c.frame:SetAlpha(min(1, k / 0.05))
            local cols = d.colors
            local col = k > (d.cycleFor or 0.8) and cols[1] or cols[floor(k / (d.period or 0.08)) % #cols + 1]
            c.text:SetTextColor(col[1], col[2], col[3], 1)
        end
    end

    -- Alpha: quick fade in, fade out over the last part.
    local fadeStart = p.dur * (1 - p.fade)
    local alpha = min(1, t / FADE_IN)
    if t > fadeStart then alpha = alpha * (1 - (t - fadeStart) / (p.dur - fadeStart)) end
    if p.flicker then alpha = alpha * (0.78 + 0.22 * sin(t * 37 + p.phase) * sin(t * 13)) end
    if p.blink and t > p.dur * 0.65 and floor(t * 18) % 2 == 0 then alpha = alpha * 0.25 end
    p:SetAlpha(max(0, alpha))

    if p.cycle then
        local c = p.cycle[floor(t / p.cyclePeriod) % #p.cycle + 1]
        p.text:SetTextColor(c[1], c[2], c[3], 1)
    end

    -- Position (+ crit shake).
    local x, y = p.ox + p.mx, p.oy + p.my
    if p.shake and t < 0.25 then
        local k = p.shake * (1 - t / 0.25)
        x, y = x + (random() - 0.5) * 2 * k, y + (random() - 0.5) * 2 * k
    end
    p:ClearAllPoints()
    p:SetPoint("CENTER", p.anchor, p.anchorPoint, p.ax + x, p.ay + y)

    -- Decor follows the number; bursts and rings live for half its time.
    animateTexture(p.decor, p.decorDef, t, p.dur, p.decorRot or 0)
    animateTexture(p.burst, p.burstDef, t, p.dur * 0.55, p.burstRot or 0)
    animateTexture(p.burst2, p.burst2Def, t, p.dur * 0.55, p.burst2Rot or 0)
    animateTexture(p.ring, p.ringDef, t, p.dur * 0.45, 0)

    -- Particles fly from where the number spawned, not with it.
    for _, part in ipairs(p.parts) do
        if part.alive then
            part.t = part.t + dt
            if part.t >= part.life then
                part.alive = false
                part.tex:Hide()
            else
                part.vy = part.vy + part.gravity * dt
                part.x = part.x + part.vx * dt
                part.y = part.y + part.vy * dt
                local k = part.t / part.life
                part.tex:SetAlpha((1 - k) * min(1, part.t / 0.04))
                if part.tex.SetRotation then
                    if part.orient then
                        part.tex:SetRotation(atan2(part.vy, part.vx) - pi / 2)
                    elseif part.spin ~= 0 then
                        part.tex:SetRotation(part.rot + part.spin * part.t)
                    end
                end
                local sx = part.sway and sin(part.t * 6 + part.rot) * 6 or 0
                part.tex:ClearAllPoints()
                part.tex:SetPoint("CENTER", p.anchor, p.anchorPoint, p.ax + p.ox + part.x + sx, p.ay + p.oy + part.y)
            end
        end
    end

    if p.skin.onUpdate then p.skin.onUpdate(p, t, dt) end
    return true
end

-- For skins that draw their own text (see Jackpot.lua).
Engine.WriteText = writeText
Engine.SetFont = setFont
Engine.Rand = rr

driver:SetScript("OnUpdate", function(_, elapsed)
    local speed = (ns.db and ns.db.speed) or 1
    local dt = min(elapsed, 0.1) * speed
    for i = #active, 1, -1 do
        if not Engine.Step(active[i], dt) then release(i) end
    end
    if #active == 0 then driver:Hide() end
end)

function Engine.Clear()
    for i = #active, 1, -1 do release(i) end
end

---------------------------------------------------------------------------
-- Anchors
---------------------------------------------------------------------------
local function plateFor(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if not ok or not plate or ns.IsSecret(plate) or type(plate) ~= "table" then return nil end
    if plate.IsForbidden and ns.SafeBool(plate.IsForbidden, plate) ~= false then return nil end
    if ns.SafeBool(plate.IsShown, plate) == false then return nil end
    return plate
end

-- anchor frame, point, x, y for a hit on unit.
function Engine.AnchorFor(unit, side)
    if side == "out" and unit then
        local plate = plateFor(unit)
        if plate then return plate, "CENTER", 0, ns.db.plateOffset or 30 end
    end
    local a = Engine.anchors and Engine.anchors[side]
    if a then return a, "CENTER", 0, 0 end
    return UIParent, "CENTER", 0, side == "inc" and -40 or 140
end

-- A plate going away (mob died, out of range) may soon carry another unit:
-- numbers on it stay where they are, or fade out if that can't be read.
function Engine.PlateRemoved(unit)
    local plate
    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        local ok, r = pcall(C_NamePlate.GetNamePlateForUnit, unit)
        if ok then plate = r end
    end
    if not plate then return end
    for _, p in ipairs(active) do
        if p.anchor == plate then
            local ok, cx, cy = pcall(p.GetCenter, p)
            cx, cy = ok and ns.Plain(cx, "number"), ok and ns.Plain(cy, "number")
            if cx and cy then
                local x, y = p.ox + p.mx, p.oy + p.my
                p.anchor, p.anchorPoint = UIParent, "BOTTOMLEFT"
                p.ax, p.ay = cx - x, cy - y
            else
                p.t = max(p.t, p.dur - 0.15)
            end
        end
    end
end

local function makeAnchor(key, label)
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(140, 28)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)
    f:RegisterForDrag("LeftButton")
    local pos = ns.db.anchors[key]
    f:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(1, 0.55, 0.15, 0.35)
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.label:SetPoint("CENTER")
    f.label:SetText(label)
    f.bg:Hide(); f.label:Hide()
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local ux, uy = UIParent:GetCenter()
        local s = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
        local nx, ny = floor(x * s - ux + 0.5), floor(y * s - uy + 0.5)
        ns.db.anchors[key] = { x = nx, y = ny }
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", nx, ny)
    end)
    return f
end

function Engine.Init()
    if Engine.anchors then return end
    Engine.anchors = {
        out = makeAnchor("out", "SkinDeep: no nameplate"),
        inc = makeAnchor("inc", "SkinDeep: incoming"),
    }
end

function Engine.SetUnlocked(on)
    Engine.unlocked = on
    for _, f in pairs(Engine.anchors or EMPTY) do
        f:EnableMouse(on)
        f.bg:SetShown(on)
        f.label:SetShown(on)
    end
end

function Engine.ResetAnchors(defaults)
    for key, f in pairs(Engine.anchors or EMPTY) do
        local pos = defaults[key]
        ns.db.anchors[key] = { x = pos.x, y = pos.y }
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
    end
end
