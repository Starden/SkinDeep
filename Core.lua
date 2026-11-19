local ADDON_NAME, ns = ...

-- SkinDeep: damage skins for the floating combat numbers.
--
-- Two layers work together:
--   1. Blizzard's own floating numbers (the engine draws them in the world).
--      Addons can only restyle them two ways: the font (DAMAGE_TEXT_FONT, read
--      once at login) and the engine's motion CVars (WorldText*). Their colors
--      are fixed.
--   2. SkinDeep's own numbers (Engine.lua), drawn over the target's nameplate
--      from UNIT_COMBAT. They can do what the engine can't: colors, layered
--      text, bursts, particles and custom motion. While they're on, Blizzard's
--      damage numbers are switched off so nothing is shown twice.
--
-- In WoW: Forever, UNIT_COMBAT amounts are "secret" in combat: Lua may hand
-- them to a FontString but never read, compare or split them. So skins are
-- built from fonts, text layers, textures and motion, never from per-digit
-- sprites, and amounts only ever pass through SetFormattedText.

-- Stamped into the TOC by the release packager from the git tag.
do
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local v = get and get(ADDON_NAME, "Version")
    ns.VERSION = (v and not v:find("@", 1, true)) and v or "dev"
end

local DEFAULTS = {
    enabled = true,
    skin = "auto",          -- "auto": the class skin of whichever character is logged in
    mode = "skin",          -- "skin": SkinDeep numbers replace Blizzard's
                            -- "both": SkinDeep numbers on top of Blizzard's
                            -- "font": only restyle Blizzard's numbers (font + motion)
    groupFallback = false,  -- true: in a group, hand back to Blizzard's numbers
                            -- (UNIT_COMBAT can't tell whose hit it was, so in
                            -- groups SkinDeep shows everyone's hits on your target)
    nameplates = true,      -- also enemy nameplates other than the target (AoE)
    incoming = false,       -- damage you take, at the "incoming" anchor
    incomingHeals = true,
    colorScheme = "skin",   -- "skin": each skin's physical/spell pair
                            -- "classic": physical white, spell yellow (Blizzard)
                            -- "school": Fire, Frost, Shadow... colors for spells
    abbreviate = true,
    effects = true,         -- bursts, rings, decor and particles
    sounds = true,          -- skin sound effects (Jackpot's reels and payout)
    toasts = true,          -- popup when a feat completes / a skin unlocks
    toastSound = true,      -- its fanfare
    -- unlockMode: nil until the first-run window is answered, then
    -- "collector" (earn skins through feats) or "all"
    worldFont = true,       -- give Blizzard's numbers the skin's font (next login)
    worldMotion = true,     -- give Blizzard's numbers the skin's motion preset
    scale = 1.0,
    speed = 1.0,
    plateOffset = 30,
    anchors = {
        out = { x = 0, y = 140 },
        inc = { x = -260, y = -40 },
    },
}

ns.DEFAULTS = DEFAULTS

-- Copies missing defaults into t (tables recursively).
local function fill(t, defaults)
    for k, v in pairs(defaults) do
        if t[k] == nil then
            if type(v) == "table" then t[k] = {}; fill(t[k], v) else t[k] = v end
        elseif type(v) == "table" and type(t[k]) == "table" then
            fill(t[k], v)
        end
    end
end

---------------------------------------------------------------------------
-- Secret values
---------------------------------------------------------------------------
local issecret = issecretvalue

function ns.IsSecret(v)
    if not issecret then return false end
    local ok, r = pcall(issecret, v)
    return ok and r == true
end

-- v when it is a readable value of the given Lua type, else nil.
function ns.Plain(v, kind)
    if ns.IsSecret(v) or type(v) ~= kind then return nil end
    return v
end

-- A plain boolean from fn(...), or nil when it errors or comes back secret.
function ns.SafeBool(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(fn, ...)
    if not ok or ns.IsSecret(r) then return nil end
    return r and true or false
end

local function shortNumber(n)
    if not ns.db.abbreviate then return ("%d"):format(n) end
    if n >= 1e9 then return ("%.1fB"):format(n / 1e9) end
    if n >= 1e6 then return ("%.1fM"):format(n / 1e6) end
    if n >= 1e4 then return ("%.1fK"):format(n / 1e3) end
    return ("%d"):format(n)
end

-- Puts an amount into a FontString through fmt ("%s" = the number). Secret
-- amounts go through the client's own formatter untouched.
function ns.FormatAmount(fs, fmt, amount)
    local n = ns.Plain(amount, "number")
    if n then
        fs:SetFormattedText(fmt, shortNumber(n))
        return
    end
    local v = amount
    if ns.db.abbreviate and AbbreviateLargeNumbers then
        local ok, r = pcall(AbbreviateLargeNumbers, amount)
        if ok and r ~= nil then v = r end
    end
    if not pcall(fs.SetFormattedText, fs, fmt, v) then
        pcall(fs.SetText, fs, v)
    end
end

---------------------------------------------------------------------------
-- Skins
---------------------------------------------------------------------------
ns.AUTO = "auto"
local AUTO_FALLBACK = "ember"   -- if the class can't be read or has no skin

-- The class skin for the logged-in character (nil if unknown).
function ns.ClassSkinID()
    local ok, _, token = pcall(UnitClass, "player")
    token = ok and ns.Plain(token, "string")
    if not token then return nil end
    for _, id in ipairs(ns.SkinOrder) do
        if ns.Skins[id].class == token then return id end
    end
end

-- The skin id that's really in use ("auto" resolved).
function ns.ResolvedSkinID()
    local id = ns.db and ns.db.skin
    -- Locked for this character (Collector mode): use the class skin instead.
    if id ~= ns.AUTO and ns.Feats and ns.db and not ns.Feats.IsUnlocked(id) then id = ns.AUTO end
    if id == ns.AUTO then return ns.ClassSkinID() or AUTO_FALLBACK end
    return id
end

function ns.CurrentSkin()
    return ns.Skins[ns.ResolvedSkinID()] or ns.Skins.classic
end

function ns.IsValidSkin(id)
    return id == ns.AUTO or ns.Skins[id] ~= nil
end

function ns.WorldFontFor(skin)
    return skin.worldFont or skin.font
end

-- false, "locked" for a skin Collector mode hasn't unlocked yet.
function ns.SetSkin(id)
    if not ns.IsValidSkin(id) then return false end
    if ns.Feats and not ns.Feats.IsUnlocked(id) then return false, "locked" end
    ns.db.skin = id
    ns.ApplyCVars()
    if ns.OnSettingsChanged then ns.OnSettingsChanged() end
    return true
end

-- True while SkinDeep draws outgoing numbers itself.
function ns.OverlayActive()
    local db = ns.db
    if not db or not db.enabled or db.mode == "font" then return false end
    if db.groupFallback and IsInGroup and IsInGroup() then return false end
    return true
end

-- Needs a relog for the world font? (DAMAGE_TEXT_FONT is only read at login.)
function ns.WorldFontPending()
    local db = ns.db
    local want = (db.enabled and db.worldFont) and ns.WorldFontFor(ns.CurrentSkin()) or ns.loginDefaultFont
    return want ~= ns.loginWorldFont
end

---------------------------------------------------------------------------
-- CVars: borrowed while needed, handed back when not (and at logout, so
-- removing the addon never leaves Blizzard's numbers switched off).
---------------------------------------------------------------------------
local function getCVar(name)
    if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
    if GetCVar then return GetCVar(name) end
end

local function setCVar(name, value)
    local f = (C_CVar and C_CVar.SetCVar) or SetCVar
    if not f then return false end
    return (pcall(f, name, tostring(value)))
end

local HIDE_BLIZZARD = {
    floatingCombatTextCombatDamage = "0",
    floatingCombatTextCombatLogPeriodicSpells = "0",
    floatingCombatTextPetMeleeDamage = "0",
    floatingCombatTextPetSpellDamage = "0",
}

-- The client's real name for a CVar. Modern clients (WoW: Forever included)
-- renamed the combat text CVars with a "_v2" suffix and the old names are
-- gone, so the suffixed name wins when it exists. nil: neither exists.
local function resolveCVar(name)
    local v2 = name .. "_v2"
    if getCVar(v2) ~= nil then return v2 end
    if getCVar(name) ~= nil then return name end
end
ns.ResolveCVar = resolveCVar

-- Wanted values keyed by the client's real CVar names.
function ns.DesiredCVars()
    local want, db = {}, ns.db
    if not db.enabled then return want end
    local source
    if db.mode == "skin" and ns.OverlayActive() then
        source = HIDE_BLIZZARD
    elseif db.worldMotion then
        source = ns.CurrentSkin().world or {}
    end
    for k, v in pairs(source or {}) do
        local real = resolveCVar(k)
        if real then want[real] = tostring(v) end
    end
    return want
end

local pendingCVars = false

local function releaseCVars(want)
    local db = ns.db
    for name, original in pairs(db.borrowed) do
        if not want or want[name] == nil then
            -- Only put it back if it still holds our value: a change the
            -- player made by hand meanwhile wins.
            if getCVar(name) == db.wrote[name] then setCVar(name, original) end
            db.borrowed[name], db.wrote[name] = nil, nil
        end
    end
end

function ns.ApplyCVars()
    local db = ns.db
    if not db then return end
    if InCombatLockdown and InCombatLockdown() then pendingCVars = true; return end
    pendingCVars = false
    local want = ns.DesiredCVars()
    releaseCVars(want)
    for name, value in pairs(want) do
        local current = getCVar(name)
        if current ~= nil and not ns.IsSecret(current) then
            if db.borrowed[name] == nil then db.borrowed[name] = current end
            if current ~= value and not setCVar(name, value) then
                ns.Print(("couldn't change the setting %s; Blizzard's numbers may still show."):format(name))
            end
            db.wrote[name] = value
        end
    end
end

-- Gives every borrowed CVar back now (slash "restore", logout).
function ns.RestoreCVars()
    if ns.db then releaseCVars(nil) end
end

---------------------------------------------------------------------------
-- UNIT_COMBAT -> floating numbers
---------------------------------------------------------------------------
local CRIT = { CRITICAL = true, CRUSHING = true }
local ZERO_FLAGS = { ABSORB = true, BLOCK = true, RESIST = true }
local WORDS = {
    MISS = true, DODGE = true, PARRY = true, IMMUNE = true, RESIST = true, BLOCK = true,
    ABSORB = true, EVADE = true, DEFLECT = true, REFLECT = true,
}

local function wordFor(key)
    local s = _G[key]
    if type(s) == "string" and s ~= "" then return s end
    return key:sub(1, 1) .. key:sub(2):lower()
end
ns.WordFor = wordFor

function ns.HandleCombat(unit, action, flags, amount, school)
    local db = ns.db
    if not db or not db.enabled then return end
    local u, kind = ns.Plain(unit, "string"), ns.Plain(action, "string")
    if not u or not kind then return end
    local flag = ns.Plain(flags, "string") or ""

    local side
    if u == "player" then
        if not db.incoming then return end
        side = "inc"
    else
        if not ns.OverlayActive() then return end
        if u == "target" then
            if ns.SafeBool(UnitCanAttack, "player", "target") == false then return end
        elseif db.nameplates and u:find("^nameplate%d") then
            -- The target's own plate fires too; it's already shown as "target".
            if ns.SafeBool(UnitIsUnit, u, "target") then return end
            if ns.SafeBool(UnitCanAttack, "player", u) == false then return end
        else
            return
        end
        side = "out"
    end

    local e = { side = side, unit = u, school = ns.Plain(school, "number") or 1 }
    if kind == "WOUND" then
        local n = ns.Plain(amount, "number")
        if ZERO_FLAGS[flag] then
            e.kind, e.word = "word", wordFor(flag)
            if n == nil or n > 0 then e.amount = amount end
        elseif n == 0 then
            e.kind, e.word = "word", wordFor("MISS")
        else
            e.kind, e.amount, e.crit = "dmg", amount, CRIT[flag] or false
        end
    elseif kind == "HEAL" then
        if side ~= "inc" or not db.incomingHeals then return end
        e.kind, e.amount, e.crit = "heal", amount, flag == "CRITICAL"
    elseif WORDS[kind] then
        e.kind, e.word = "word", wordFor(kind)
    else
        return
    end
    e.anchor, e.point, e.ax, e.ay = ns.Engine.AnchorFor(u, side)
    e.skin = ns.PvPSkinFor(u, side)
    ns.Engine.Spawn(e)
end

---------------------------------------------------------------------------
-- Test hits (plain numbers, so the preview can run any time)
---------------------------------------------------------------------------
local TEST = {
    { kind = "dmg", amount = 142 },
    { kind = "dmg", amount = 87, school = 4 },
    { kind = "dmg", amount = 1234, crit = true },
    { kind = "word", word = "MISS" },
    { kind = "dmg", amount = 36, school = 16 },
    { kind = "dmg", amount = 28750, crit = true, school = 64 },
    { kind = "dmg", amount = 512, school = 32 },
}

-- anchorFrame: where to show them (nil = the target's plate or the out anchor).
function ns.Test(anchorFrame, skinID, strata)
    for i, hit in ipairs(TEST) do
        C_Timer.After((i - 1) * 0.22, function()
            if anchorFrame and not ns.PreviewVisible(anchorFrame) then return end
            local e ={ side = "out", kind = hit.kind, amount = hit.amount, crit = hit.crit,
                        school = hit.school or 1, skin = skinID, strata = strata,
                        preview = anchorFrame ~= nil }
            if hit.word then e.word = wordFor(hit.word) end
            if anchorFrame then
                e.anchor, e.point, e.ax, e.ay = anchorFrame, "CENTER", 0, 0
            else
                e.anchor, e.point, e.ax, e.ay = ns.Engine.AnchorFor("target", "out")
            end
            ns.Engine.Spawn(e)
        end)
    end
    if not anchorFrame and ns.db.incoming then
        C_Timer.After(0.5, function()
            local a, p, x, y = ns.Engine.AnchorFor("player", "inc")
            ns.Engine.Spawn({ side = "inc", kind = "dmg", amount = 214, anchor = a, point = p, ax = x, ay = y, skin = skinID })
            C_Timer.After(0.4, function()
                ns.Engine.Spawn({ side = "inc", kind = "heal", amount = 380, anchor = a, point = p, ax = x, ay = y, skin = skinID })
            end)
        end)
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local function chat(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8a2eSkin|r|cffffd84aDeep|r: " .. msg)
end
ns.Print = chat

-- Says so in chat when joining or leaving a group flips SkinDeep over to
-- Blizzard's numbers and back, so the switch never looks like a breakdown.
local wasGrouped
local function announceGroup()
    local grouped = IsInGroup() and true or false
    if grouped == wasGrouped then return end
    local first = wasGrouped == nil
    wasGrouped = grouped
    local db = ns.db
    if not (db.enabled and db.mode ~= "font") then return end
    if not db.groupFallback then
        -- Staying on: say once per session what that means.
        if grouped and not ns.groupNoted then
            ns.groupNoted = true
            chat("in a group: your skin also shows your party's hits on your target (addons can't tell them apart).")
        end
        return
    end
    if grouped then
        chat("you're in a group, so Blizzard's numbers are back (addons can't tell whose hit it was). "
            .. "To keep SkinDeep on in groups, untick |cffffd84aBlizzard's numbers in groups|r in /skindeep.")
    elseif not first then
        chat("left the group: SkinDeep's numbers are back.")
    end
end

---------------------------------------------------------------------------
-- PvP skin: a second skin for battlegrounds and fights with players
---------------------------------------------------------------------------
local inBattleground = false

function ns.UpdateInstance()
    local ok, _, kind = pcall(IsInInstance)
    inBattleground = ok and ns.Plain(kind, "string") == "pvp" or false
end

function ns.InBattleground() return inBattleground end

-- The PvP skin for a hit, or nil for the usual one. Hits you take have no
-- known source, so for those only battlegrounds count.
function ns.PvPSkinFor(unit, side)
    local id = ns.db and ns.db.pvpSkin
    if not id or not ns.Skins[id] then return nil end
    if ns.Feats and not ns.Feats.IsUnlocked(id) then return nil end
    if inBattleground then return id end
    if side == "out" and unit and ns.SafeBool(UnitIsPlayer, unit) then return id end
    return nil
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("UNIT_COMBAT")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")

events:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_COMBAT" then
        ns.HandleCombat(...)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        ns.UpdateInstance()
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        ns.Engine.PlateRemoved(...)
    elseif event == "ADDON_LOADED" then
        if ... ~= ADDON_NAME then return end
        SkinDeepDB = SkinDeepDB or {}
        ns.db = SkinDeepDB
        -- Saves from before 1.1 have the old "Blizzard's numbers in groups"
        -- default stored; 1.1 keeps SkinDeep on in groups.
        if (ns.db.dbVersion or 1) < 2 and ns.db.skin then ns.db.groupFallback = false end
        ns.db.dbVersion = 2
        fill(ns.db, DEFAULTS)
        ns.db.borrowed = ns.db.borrowed or {}
        ns.db.wrote = ns.db.wrote or {}
        if ns.Feats then ns.Feats.InitDB(ns.db) end
        if not ns.IsValidSkin(ns.db.skin) then ns.db.skin = DEFAULTS.skin end
        -- Blizzard's world numbers read this once, as the world loads.
        ns.loginDefaultFont = DAMAGE_TEXT_FONT
        if ns.db.enabled and ns.db.worldFont then
            DAMAGE_TEXT_FONT = ns.WorldFontFor(ns.CurrentSkin())
        end
        ns.loginWorldFont = DAMAGE_TEXT_FONT
    elseif event == "PLAYER_LOGIN" then
        ns.Engine.Init()
        ns.ApplyCVars()
        if not ns.db.welcomed then
            ns.db.welcomed = true
            chat("loaded. Type |cffffd84a/skindeep|r to pick a damage skin.")
        end
        announceGroup()
    elseif event == "PLAYER_LOGOUT" then
        ns.RestoreCVars()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingCVars then ns.ApplyCVars() end
    elseif event == "GROUP_ROSTER_UPDATE" then
        ns.ApplyCVars()
        announceGroup()
        if ns.OnSettingsChanged then ns.OnSettingsChanged() end
    end
end)
