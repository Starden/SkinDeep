local _, ns = ...

-- Jackpot: a slot machine for your damage.
--
-- Normal hits roll in a small reel window: random numbers blur past, slow
-- down, and the real amount lands with a bounce. A crit on your target opens
-- the full cabinet: one wide reel blurs through random numbers, clunks
-- through its last three faces, and lands on the real crit amount; then
-- JACKPOT!, the cabinet shakes and coins spray everywhere. Crits while a
-- jackpot is still running (or on other nameplates) get a bigger gold
-- mini-roll instead, so AoE crits don't stack cabinets.
--
-- The amount is secret in combat: Lua can show it but not read its digits,
-- so the reel can't spin digit by digit into it. The rolling numbers are
-- random filler (their length is a guess when the amount can't be read);
-- the real number is only ever written by Engine.WriteText when its reel
-- face comes up.

local Engine = ns.Engine
local TEX = "Interface\\AddOns\\SkinDeep\\Media\\Textures\\"
local FONT = ns.Fonts.block
local OUTLINE = "OUTLINE, MONOCHROME"

local random, floor, min, max, sin, cos, abs, pi =
    math.random, math.floor, math.min, math.max, math.sin, math.cos, math.abs, math.pi

local SMALL_ROLL, MINI_ROLL = 0.38, 0.5     -- seconds a small reel spins
local SMALL_LINE, BIG_LINE = 26, 60         -- reel line heights
local BIG_SPIN = 0.6                        -- the cabinet reel's fast spin...
local CLUNKS = { 0.68, 0.8, 0.92 }          -- ...then its last three faces, one at a time
local CLUNK_TIME = 0.07                     -- seconds each clunk takes
local JACKPOT_AT = 0.95                     -- the payout moment
local BIG_COOLDOWN = 1.6                    -- one cabinet at a time
local BULBS, COINS = 18, 16
local CAB_W, CAB_H = 260, 92
local REEL_W, REEL_H = 224, 64

local WHITE = { 1, 1, 1 }
local ROLL_COLOR = { 0.85, 0.85, 0.88 }
local FRAME_GOLD = { 0.9, 0.66, 0.18 }
local FRAME_MINI = { 1, 0.92, 0.47 }
local TITLE_CYCLE = { { 1, 0.82, 0.23 }, { 1, 0.29, 0.29 }, { 1, 1, 1 }, { 0.31, 0.85, 1 } }

local lastBig = -10
local lastSound = {}

-- Sound by SOUNDKIT name (numeric fallback); never in the options preview.
local function sound(p, key, fallback)
    if not ns.db.sounds or p.jpPreview then return end
    local now = GetTime()
    -- Stops stacked pops doubling a sound; shorter than the clunk beat (0.12s).
    if lastSound[key] and now - lastSound[key] < 0.05 then return end
    lastSound[key] = now
    local id = (SOUNDKIT and SOUNDKIT[key]) or fallback
    if id and PlaySound then pcall(PlaySound, id, "SFX") end
end

local function texture(parent, file, layer, sublevel)
    local t = parent:CreateTexture(nil, layer, nil, sublevel)
    t:SetTexture(TEX .. file .. ".tga")
    return t
end

---------------------------------------------------------------------------
-- Reels: two FontStrings sliding down through a clipping window. Faces
-- 0..n-1 come from reel.face(i) as (text, color); face n is the result,
-- written by reel.final(fs).
---------------------------------------------------------------------------
local function newReel(parent, w, h, size)
    local clip = CreateFrame("Frame", nil, parent)
    clip:SetSize(w, h)
    if clip.SetClipsChildren then clip:SetClipsChildren(true) end
    local reel = { clip = clip, a = clip:CreateFontString(nil, "OVERLAY"), b = clip:CreateFontString(nil, "OVERLAY") }
    Engine.SetFont(reel.a, FONT, size, OUTLINE)
    Engine.SetFont(reel.b, FONT, size, OUTLINE)
    return reel
end

local function resetReel(reel)
    reel.a.face, reel.b.face = nil, nil
    reel.heard = false
end

local function setFace(reel, fs, i)
    if fs.face == i then return end
    fs.face = i
    if i >= reel.n then
        reel.final(fs)
    else
        local text, c = reel.face(i)
        fs:SetText(text)
        fs:SetTextColor(c[1], c[2], c[3], 1)
    end
end

-- Places the reel for time t: reel.pos(reel, t) gives how far it has turned
-- (default: one ease-out spin), with a small bounce on the stop. Returns
-- true once it has stopped.
local function spinReel(reel, t)
    local line = reel.line
    local pos
    if reel.pos then
        pos = reel.pos(reel, t)
    else
        local k = min(1, max(0, t / reel.stop))
        pos = (1 - (1 - k) ^ 3) * reel.n * line
    end
    local i = floor(pos / line)
    local frac = pos - i * line
    if i >= reel.n then i, frac = reel.n, 0 end
    local since = t - reel.stop
    local bounce = 0
    if since > 0 and since < 0.16 then bounce = -line * 0.18 * sin(since / 0.16 * pi) end

    local a, b = reel.a, reel.b
    setFace(reel, a, i)
    a:ClearAllPoints()
    a:SetPoint("CENTER", reel.clip, "CENTER", 0, -frac + bounce)
    -- Fading by distance keeps the reel look even where clipping is missing.
    a:SetAlpha(1 - min(1, frac / line) * 0.7)
    if i < reel.n then
        setFace(reel, b, i + 1)
        b:ClearAllPoints()
        b:SetPoint("CENTER", reel.clip, "CENTER", 0, line - frac)
        b:SetAlpha(min(1, frac / line))
        b:Show()
    else
        b:Hide()
    end
    return since >= 0
end

---------------------------------------------------------------------------
-- Small roll (normal hits, and the gold mini-roll for extra crits)
---------------------------------------------------------------------------
local function smallKit(p)
    local c = Engine.Container(p, "jackpotSmall", true)
    if not c.panel then
        c.panel = texture(c, "panel", "BACKGROUND")
        c.panel:SetPoint("CENTER")
        c.panel:SetSize(112, 36)
        c.frame = texture(c, "frame", "BORDER")
        c.frame:SetPoint("CENTER")
        c.frame:SetSize(112, 36)
        c.reel = newReel(c, 108, 30, 24)
        c.reel.clip:SetPoint("CENTER")
        c.reel.line = SMALL_LINE
    end
    return c
end

local function digitCount(e)
    local n = ns.Plain(e.amount, "number")
    if n and n >= 1 then return min(6, #tostring(floor(n))) end
    return random(2, 4)
end

local function randomDigits(d)
    return tostring(random(floor(10 ^ (d - 1)), floor(10 ^ d) - 1))
end

local function spawnSmall(p, e, mini)
    local c = smallKit(p)
    p.jpKit, p.jpBig = c, false
    local roll = mini and MINI_ROLL or SMALL_ROLL
    p.landAt, p.riseSpeed = roll, 35
    if mini then
        p.base = p.base * 1.3
        p.dur = 1.6
    end
    local fc = mini and FRAME_MINI or FRAME_GOLD
    p.jpFrameColor = fc
    c.panel:SetVertexColor(0.09, 0.07, 0.12)
    c.panel:SetAlpha(0.9)
    c.frame:SetVertexColor(fc[1], fc[2], fc[3])
    c.frame:SetAlpha(1)
    c.reel.clip:SetScale(1)

    local reel = c.reel
    reel.n, reel.stop = mini and 10 or 6, roll
    local d, faces = digitCount(e), {}
    for i = 0, reel.n - 1 do faces[i] = randomDigits(d) end
    reel.face = function(i) return faces[i], ROLL_COLOR end
    local skin, color = p.skin, p.color
    reel.final = function(fs)
        Engine.WriteText(fs, e, skin)
        fs:SetTextColor(color[1], color[2], color[3], 1)
    end
    resetReel(reel)
end

local function updateSmall(p, t)
    local c = p.jpKit
    spinReel(c.reel, t)
    local since = t - p.landAt
    if since < 0 then return end
    -- Landing "ding": the number pops, the frame flashes white back to gold.
    if since < 0.15 then
        local k = 1 - since / 0.15
        c.reel.clip:SetScale(1 + 0.35 * k * k)
    else
        c.reel.clip:SetScale(1)
    end
    local f, fc = min(1, since / 0.25), p.jpFrameColor
    c.frame:SetVertexColor(1 + (fc[1] - 1) * f, 1 + (fc[2] - 1) * f, 1 + (fc[3] - 1) * f)
    -- The window fades away; the number floats on alone.
    local wa = since < 0.3 and 1 or max(0, 1 - (since - 0.3) / 0.3)
    c.panel:SetAlpha(0.9 * wa)
    c.frame:SetAlpha(wa)
end

---------------------------------------------------------------------------
-- The jackpot cabinet
---------------------------------------------------------------------------
-- A frame that can scale on its own around (x, y): an unscaled holder at the
-- offset, with the scaled frame centered on it (SetPoint offsets of a scaled
-- frame would scale too).
local function scalable(parent, x, y)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(1, 1)
    holder:SetPoint("CENTER", parent, "CENTER", x, y)
    local f = CreateFrame("Frame", nil, holder)
    f:SetSize(1, 1)
    f:SetPoint("CENTER")
    return f
end

local function label(parent, size, x, y, sublevel, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetDrawLayer("OVERLAY", sublevel)
    Engine.SetFont(fs, FONT, size, OUTLINE)
    fs:SetPoint("CENTER", parent, "CENTER", x, y)
    if color then fs:SetTextColor(color[1], color[2], color[3], 1) end
    return fs
end

-- The cabinet reel: a fast ease-out spin over all but the last three faces,
-- then each of those clunks into place on its own beat.
local function clunkPos(reel, t)
    local line, fast = reel.line, reel.n - #CLUNKS
    if t < BIG_SPIN then
        local k = t / BIG_SPIN
        return (1 - (1 - k) ^ 3) * fast * line
    end
    local pos = fast * line
    for _, at in ipairs(CLUNKS) do
        if t >= at then
            pos = pos + line
        elseif t > at - CLUNK_TIME then
            local k = (t - (at - CLUNK_TIME)) / CLUNK_TIME
            pos = pos + line * (1 - (1 - k) ^ 3)
        end
    end
    return pos
end

local function bigKit(p)
    local c = Engine.Container(p, "jackpotBig", true)
    if c.panel then return c end

    c.burst = texture(c, "burst", "BACKGROUND", -8)
    c.burst:SetPoint("CENTER")
    c.burst:SetSize(330, 330)
    c.burst:SetBlendMode("ADD")
    c.burst:SetVertexColor(1, 0.76, 0.23)
    c.flash = texture(c, "glow", "BACKGROUND", -7)
    c.flash:SetPoint("CENTER")
    c.flash:SetSize(350, 350)
    c.flash:SetBlendMode("ADD")
    c.flash:SetVertexColor(1, 0.96, 0.8)

    c.panel = texture(c, "panel", "BACKGROUND", 0)
    c.panel:SetPoint("CENTER")
    c.panel:SetSize(CAB_W, CAB_H)
    c.panel:SetVertexColor(0.09, 0.07, 0.12)
    c.frame = texture(c, "frame", "BORDER")
    c.frame:SetPoint("CENTER")
    c.frame:SetSize(CAB_W, CAB_H)

    local window = texture(c, "panel", "ARTWORK")
    window:SetPoint("CENTER")
    window:SetSize(REEL_W, REEL_H)
    window:SetVertexColor(0.04, 0.03, 0.06)
    c.reel = newReel(c, REEL_W - 4, REEL_H - 4, 36)
    c.reel.clip:SetPoint("CENTER")
    c.reel.line = BIG_LINE
    c.reel.pos = clunkPos
    -- Extrusion behind the landed number (it rides on the reel's front face).
    c.reelLayers = {
        label(c.reel.clip, 36, 4, -4, -2, { 0.35, 0.1, 0 }),
        label(c.reel.clip, 36, 2, -2, -1, { 0.76, 0.25, 0.05 }),
    }

    -- Marquee bulbs evenly around the cabinet's edge.
    c.bulbs = {}
    local perimeter = 2 * (CAB_W + CAB_H)
    for i = 1, BULBS do
        local s = (i - 1) / BULBS * perimeter
        local bx, by
        if s < CAB_W then
            bx, by = -CAB_W / 2 + s, CAB_H / 2
        elseif s < CAB_W + CAB_H then
            bx, by = CAB_W / 2, CAB_H / 2 - (s - CAB_W)
        elseif s < 2 * CAB_W + CAB_H then
            bx, by = CAB_W / 2 - (s - CAB_W - CAB_H), -CAB_H / 2
        else
            bx, by = -CAB_W / 2, -CAB_H / 2 + (s - 2 * CAB_W - CAB_H)
        end
        local bulb = texture(c, "glow", "OVERLAY")
        bulb:SetBlendMode("ADD")
        bulb:SetPoint("CENTER", c, "CENTER", bx, by)
        bulb:SetSize(14, 14)
        c.bulbs[i] = bulb
    end

    c.title = scalable(c, 0, 72)
    label(c.title, 30, 3, -3, 1, { 0.35, 0.04, 0.04 }):SetText("JACKPOT!")
    c.titleText = label(c.title, 30, 0, 0, 2)
    c.titleText:SetText("JACKPOT!")

    return c
end

local function coinKit(p)
    local c = Engine.Container(p, "jackpotCoins", false)
    if not c.coins then
        c.coins = {}
        for i = 1, COINS do c.coins[i] = { tex = texture(c, "coin", "OVERLAY") } end
    end
    for _, coin in ipairs(c.coins) do
        coin.alive = false
        coin.tex:Hide()
    end
    return c
end

-- Crits are big hits: guess a little longer than a normal hit's filler.
local function critDigitCount(e)
    local n = ns.Plain(e.amount, "number")
    if n and n >= 1 then return min(6, #tostring(floor(n))) end
    return random(3, 5)
end

local function spawnBig(p, e)
    local c = bigKit(p)
    p.jpKit, p.jpBig = c, true
    p.landAt, p.riseSpeed = JACKPOT_AT, 6
    p.jpPaid, p.jpSettled = false, false
    p.jpClunks, p.jpClunkAt = 0, -1
    p.ox, p.oy = 0, 0

    local fx = ns.db.effects and true or false
    c.burst:SetShown(fx)
    c.flash:SetShown(fx)
    c.burst:SetAlpha(0)
    c.flash:SetAlpha(0)
    for _, bulb in ipairs(c.bulbs) do bulb:SetShown(fx) end
    c.frame:SetVertexColor(FRAME_GOLD[1], FRAME_GOLD[2], FRAME_GOLD[3])
    c.title:SetAlpha(0)
    c.title:SetScale(1)
    c.reel.clip:SetScale(1)
    c:ClearAllPoints()
    c:SetPoint("CENTER")

    local reel = c.reel
    reel.n, reel.stop = 16, CLUNKS[#CLUNKS]
    local d, faces = critDigitCount(e), {}
    for i = 0, reel.n - 1 do faces[i] = randomDigits(d) end
    reel.face = function(i) return faces[i], ROLL_COLOR end
    local skin, color = p.skin, p.color
    reel.final = function(fs)
        Engine.WriteText(fs, e, skin)
        fs:SetTextColor(color[1], color[2], color[3], 1)
    end
    resetReel(reel)
    for _, layer in ipairs(c.reelLayers) do
        Engine.WriteText(layer, e, skin)
        layer:Hide()
    end

    p.jpCoins = fx and coinKit(p) or nil
end

local function launchCoins(p)
    local scale = ns.db.scale or 1
    for _, coin in ipairs(p.jpCoins.coins) do
        coin.alive, coin.t = true, 0
        coin.life = 1.2 + random() * 0.5
        coin.x, coin.y = 0, 0
        coin.vx = (random() - 0.5) * 2 * (60 + random() * 130)
        coin.vy = 200 + random() * 160
        coin.spin = 8 + random() * 8
        coin.phase = random() * 6.28
        coin.size = (14 + random() * 6) * scale
        coin.tex:Show()
    end
end

local function updateCoins(p, dt)
    for _, coin in ipairs(p.jpCoins.coins) do
        if coin.alive then
            coin.t = coin.t + dt
            if coin.t >= coin.life then
                coin.alive = false
                coin.tex:Hide()
            else
                coin.vy = coin.vy - 700 * dt
                coin.x = coin.x + coin.vx * dt
                coin.y = coin.y + coin.vy * dt
                -- Flip: squash the width with the spin, darker on the back.
                local cs = cos(coin.phase + coin.spin * coin.t)
                coin.tex:SetSize(coin.size * max(0.15, abs(cs)), coin.size)
                local shade = cs > 0 and 1 or 0.72
                coin.tex:SetVertexColor(shade, 0.8 * shade, 0.25 * shade)
                local k = coin.t / coin.life
                coin.tex:SetAlpha(k > 0.7 and (1 - k) / 0.3 or 1)
                coin.tex:ClearAllPoints()
                coin.tex:SetPoint("CENTER", p.anchor, p.anchorPoint, p.ax + p.ox + coin.x, p.ay + p.oy + coin.y)
            end
        end
    end
end

local function updateBig(p, t, dt)
    local c, reel = p.jpKit, p.jpKit.reel
    local landed = spinReel(reel, t)

    -- Each clunk: a click, the frame flashes white, every bulb lights.
    for i, at in ipairs(CLUNKS) do
        if t >= at and p.jpClunks < i then
            p.jpClunks, p.jpClunkAt = i, t
            sound(p, "IG_MAINMENU_OPTION_CHECKBOX_ON", 856)
        end
    end
    local flash = p.jpClunkAt >= 0 and max(0, 1 - (t - p.jpClunkAt) / 0.12) or 0
    c.frame:SetVertexColor(FRAME_GOLD[1] + (1 - FRAME_GOLD[1]) * flash, FRAME_GOLD[2] + (1 - FRAME_GOLD[2]) * flash,
        FRAME_GOLD[3] + (1 - FRAME_GOLD[3]) * flash)

    local k = t - JACKPOT_AT
    if ns.db.effects then
        -- Chasing lights, faster once it pays out.
        local rate = k > 0 and 22 or 10
        for i, bulb in ipairs(c.bulbs) do
            if flash > 0.5 or (floor(t * rate) + i) % 3 == 0 then
                bulb:SetVertexColor(1, 0.95, 0.63)
                bulb:SetAlpha(1)
                bulb:SetSize(16, 16)
            else
                bulb:SetVertexColor(1, 0.35, 0.12)
                bulb:SetAlpha(0.45)
                bulb:SetSize(11, 11)
            end
        end
    end

    -- The landed number: extrusion on, a pulse, then gold/white flashes
    -- through the payout.
    for _, layer in ipairs(c.reelLayers) do
        if landed then
            if not layer:IsShown() then
                layer:ClearAllPoints()
                layer:SetPoint("CENTER", reel.a, "CENTER", layer == c.reelLayers[1] and 4 or 2, layer == c.reelLayers[1] and -4 or -2)
                layer:Show()
            end
        else
            layer:Hide()
        end
    end
    if landed then
        local since = t - reel.stop
        local pulse = max(0, 1 - since / 0.18)
        c.reel.clip:SetScale(1 + 0.3 * pulse * pulse)
        local col = p.color
        if k > 0 and k < 0.6 and floor(k / 0.1) % 2 == 1 then col = WHITE end
        reel.a:SetTextColor(col[1], col[2], col[3], 1)
    end
    if k < 0 then return end

    if not p.jpPaid then
        p.jpPaid = true
        sound(p, "LOOT_WINDOW_COIN_SOUND", 120)
        if p.jpCoins then launchCoins(p) end
    end

    if k < 0.35 then
        local m = 6 * (1 - k / 0.35)
        c:ClearAllPoints()
        c:SetPoint("CENTER", (random() - 0.5) * 2 * m, (random() - 0.5) * 2 * m)
    elseif not p.jpSettled then
        p.jpSettled = true
        c:ClearAllPoints()
        c:SetPoint("CENTER")
    end

    local pop = max(0, 1 - k / 0.2)
    c.title:SetScale(1 + 1.4 * pop * pop)
    c.title:SetAlpha(min(1, k / 0.05))
    local tc = TITLE_CYCLE[floor(k / 0.08) % #TITLE_CYCLE + 1]
    c.titleText:SetTextColor(tc[1], tc[2], tc[3], 1)

    if ns.db.effects then
        c.burst:SetAlpha(0.5 * min(1, k / 0.25))
        if c.burst.SetRotation then c.burst:SetRotation(k * 0.8) end
        c.flash:SetAlpha(max(0, 1 - k / 0.4) * 0.8)
    end
    if p.jpCoins then updateCoins(p, dt) end
end

---------------------------------------------------------------------------
-- Skin
---------------------------------------------------------------------------
-- Holds still while the reels spin, then floats up.
Engine.MOTIONS.slot = {
    update = function(p, t)
        local land = p.landAt or SMALL_ROLL
        p.mx = 0
        p.my = t > land and (t - land) * (p.riseSpeed or 35) or 0
    end,
}

local function onSpawn(p, e, crit)
    p.jpPreview = e.preview
    local big = crit and e.kind == "dmg" and e.side ~= "inc"
        and (e.unit == nil or e.unit == "target")
        and GetTime() - lastBig >= BIG_COOLDOWN
    if big then
        lastBig = GetTime()
        spawnBig(p, e)
    else
        spawnSmall(p, e, crit)
    end
end

local function onUpdate(p, t, dt)
    if p.jpBig then updateBig(p, t, dt) else updateSmall(p, t) end
end

ns.AddSkin("jackpot", {
    name = "Jackpot", tagline = "Every hit is a little slot roll. Crits on your target hit the JACKPOT.",
    font = FONT, size = 24, outline = OUTLINE,
    color = { 1, 0.8, 0.2 }, critColor = { 1, 0.9, 0.45 },
    physColor = { 0.92, 0.92, 0.96 }, spellColor = { 1, 0.8, 0.2 },   -- silver / gold
    ownText = true,
    motion = "slot",
    dur = 1.25, critDur = 2.9, critScale = 1, pop = 0.25, fade = 0.3,
    laneStep = 38,
    previewLoop = 3.6,
    world = { WorldTextScale = 1.2 },
    onSpawn = onSpawn,
    onUpdate = onUpdate,
})
