local _, ns = ...

-- Feats: SkinDeep's own achievements, and the unlocks they give.
--
-- At first login the player picks how skins are had (Onboarding.lua):
--   "collector": start with Classic+, Auto and your class's skin; earn the
--                rest through feats.
--   "all":       everything unlocked; feats still track and pop for fun.
-- Until a choice is made everything stays unlocked, so nobody loses a skin
-- to a window they closed. Unlocks and progress are account-wide (one
-- SkinDeepDB for every character).
--
-- What the client lets addons see shapes every feat: hits and crits on your
-- target and enemy nameplates (UNIT_COMBAT; amounts are secret, so no feat
-- depends on how big a hit was), kills of mobs you hit (by name or creature
-- type), boss kills (ENCOUNTER_END / BOSS_KILL), levels and gold. In a party
-- your target's hits include your party's, as with the numbers themselves.
-- Names and creature types are matched in English.

local Feats = {}
ns.Feats = Feats

local min, floor, tinsert = math.min, math.floor, table.insert
local GOLD = 10000 -- copper
local STARTER = { classic = true, [ns.AUTO or "auto"] = true }

local CLASS_NAMES = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid",
}
local function className(token)
    local names = LOCALIZED_CLASS_NAMES_MALE
    return (names and names[token]) or CLASS_NAMES[token] or token
end
Feats.ClassName = className

---------------------------------------------------------------------------
-- The feats. counter + goal: a running count; classLevel: a level reached
-- on a character of that class; boss: any of these kills completes it too.
-- skin: what it unlocks (flavor feats' skins arrive in a later update and
-- are counted already, so progress isn't lost).
---------------------------------------------------------------------------
local LIST = {
    { id = "ember",   skin = "ember",   text = "Deal Fire damage 500 times",   counter = "fire",   goal = 500 },
    { id = "frost",   skin = "frost",   text = "Deal Frost damage 500 times",  counter = "frost",  goal = 500 },
    { id = "arcane",  skin = "arcane",  text = "Deal Arcane damage 500 times", counter = "arcane", goal = 500 },
    { id = "comic",   skin = "comic",   text = "Land 250 critical hits",       counter = "crits",  goal = 250 },
    { id = "arcade",  skin = "arcade",  text = "Land 1,000 hits",              counter = "hits",   goal = 1000 },
    { id = "blade",   skin = "blade",   text = "Land 2,500 hits",              counter = "hits",   goal = 2500 },
    { id = "gilded",  skin = "gilded",  text = "Earn 100 gold",                counter = "gold",   goal = 100 * GOLD, money = true },
    { id = "blood",   skin = "blood",   text = "Reach level 20 on any character", counter = "maxLevel", goal = 20 },
    { id = "jackpot", skin = "jackpot", text = "Land 777 critical hits",       counter = "crits",  goal = 777 },
}

for _, token in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
    local skinId = token:lower()
    LIST[#LIST + 1] = { id = "class_" .. skinId, skin = skinId, classLevel = token, goal = 10,
                        text = "Reach level 10 on a " .. className(token) }
end

-- Faction flavor skins (coming in the next update; counted from now on).
local FLAVOR = {
    { id = "scarlet",  title = "Crimson Oath", faction = "Scarlet Crusade", color = { 0.92, 0.14, 0.14 },
      text = "Slay 100 Scarlet Crusade or defeat Whitemane",
      counter = "scarlet", goal = 100, boss = { "High Inquisitor Whitemane" } },
    { id = "scourge",  title = "Plague Tide", faction = "Scourge", color = { 0.55, 1, 0.35 },
      text = "Slay 250 Undead or defeat Baron Rivendare",
      counter = "undead", goal = 250, boss = { "Baron Rivendare" } },
    { id = "defias",   title = "Red Kerchief", faction = "Defias Brotherhood", color = { 0.88, 0.25, 0.18 },
      text = "Defeat Edwin VanCleef", boss = { "Edwin VanCleef" } },
    { id = "darkiron", title = "Molten Anvil", faction = "Dark Iron", color = { 1, 0.55, 0.2 },
      text = "Slay 100 Dark Iron or defeat Emperor Thaurissan",
      counter = "darkiron", goal = 100, boss = { "Emperor Dagran Thaurissan" } },
    { id = "brood",    title = "Broodmother", faction = "Black Dragonflight", color = { 0.7, 0.45, 1 },
      text = "Defeat Onyxia", boss = { "Onyxia" } },
    { id = "argent",   title = "Silver Dawn", faction = "Argent Dawn", color = { 0.62, 0.88, 1 },
      text = "Defeat Darkmaster Gandling", boss = { "Darkmaster Gandling" } },
}
for _, f in ipairs(FLAVOR) do
    f.flavor = true
    f.skin = f.skin or f.id   -- unlocks once the skin with this id exists
    LIST[#LIST + 1] = f
end

Feats.LIST = LIST
local BY_ID, BY_SKIN, BY_COUNTER, BY_BOSS = {}, {}, {}, {}
for _, f in ipairs(LIST) do
    BY_ID[f.id] = f
    BY_SKIN[f.skin] = f
    if f.counter then
        BY_COUNTER[f.counter] = BY_COUNTER[f.counter] or {}
        tinsert(BY_COUNTER[f.counter], f)
    end
    for _, b in ipairs(f.boss or {}) do BY_BOSS[b] = BY_BOSS[b] or {}; tinsert(BY_BOSS[b], f) end
end
Feats.ByID, Feats.BySkin = BY_ID, BY_SKIN

-- Kills counted toward counters, matched on the mob's English name/type.
local NAME_PREFIX = { ["Scarlet "] = "scarlet", ["Dark Iron "] = "darkiron", ["Defias "] = "defias" }
local CREATURE_TYPE = { Undead = "undead", Dragonkin = "dragonkin" }

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local function db() return ns.db end

function Feats.InitDB(d)
    d.counters = d.counters or {}
    d.classLevels = d.classLevels or {}
    d.bosses = d.bosses or {}
    d.specCrits = d.specCrits or {}
    d.feats = d.feats or {}
end

function Feats.Mode()
    return db() and db().unlockMode   -- nil until chosen
end

-- Progress toward a feat: current, goal.
function Feats.Progress(f)
    local d = db()
    if f.classLevel then
        return min(f.goal, d.classLevels[f.classLevel] or 0), f.goal
    end
    if f.counter then
        return min(f.goal, d.counters[f.counter] or 0), f.goal
    end
    return 0, 1
end

-- short: the compact form for the Feats tab's right-hand column.
function Feats.ProgressText(f, short)
    if Feats.IsDone(f) then return "Complete" end
    if not f.counter and not f.classLevel then return "Not yet" end
    local cur, goal = Feats.Progress(f)
    if f.money then return ("%d / %d gold"):format(floor(cur / GOLD), floor(goal / GOLD)) end
    if f.classLevel then
        if short then return ("Level %d / %d"):format(cur, goal) end
        return ("Best %s: level %d / %d"):format(className(f.classLevel), cur, goal)
    end
    return ("%d / %d"):format(cur, goal)
end

local function bossDone(f)
    for _, b in ipairs(f.boss or {}) do
        if db().bosses[b] then return true end
    end
    return false
end

local function liveDone(f)
    if bossDone(f) then return true end
    if not f.counter and not f.classLevel then return false end
    local cur, goal = Feats.Progress(f)
    return cur >= goal
end

function Feats.IsDone(f)
    return db().feats[f.id] ~= nil
end

-- The skin's own lock state; any skin with no feat is free.
function Feats.IsUnlocked(skinId)
    local d = db()
    if not d or d.unlockMode ~= "collector" then return true end
    if STARTER[skinId] or skinId == ns.ClassSkinID() then return true end
    local f = BY_SKIN[skinId]
    return not f or Feats.IsDone(f)
end

function Feats.FeatForSkin(skinId)
    return BY_SKIN[skinId]
end

-- Counts of skins the player could use right now / all there are.
function Feats.UnlockedCount()
    local have, total = 0, 0
    for _, id in ipairs(ns.SkinOrder) do
        total = total + 1
        if Feats.IsUnlocked(id) then have = have + 1 end
    end
    return have, total
end

---------------------------------------------------------------------------
-- Completing feats
---------------------------------------------------------------------------
local function complete(f, quiet)
    db().feats[f.id] = { at = time() }
    if quiet then return end
    local skin = ns.Skins[f.skin]
    local collector = db().unlockMode == "collector"
    local title = (skin and collector) and "Skin unlocked" or "Feat complete"
    local name = skin and skin.name or f.title or f.id
    local note = f.text
    if f.flavor and not skin then note = f.text .. ". Its skin arrives in the next update." end
    if Feats.OnComplete then Feats.OnComplete(f, title, name, note, skin) end
    if skin and collector then
        ns.Print(("|cffffd84aSkin unlocked:|r %s (%s). /skindeep to equip it."):format(name, f.text))
    else
        ns.Print(("|cffffd84aFeat complete:|r %s (%s)."):format(name, f.text))
    end
end

-- Checks a set of feats (default: all) and completes any that are done.
function Feats.Check(list, quiet)
    for _, f in ipairs(list or LIST) do
        if not Feats.IsDone(f) and liveDone(f) then complete(f, quiet) end
    end
end

local function bump(counter, by)
    local c = db().counters
    c[counter] = (c[counter] or 0) + (by or 1)
    local list = BY_COUNTER[counter]
    if list then Feats.Check(list) end
end
Feats.Bump = bump

function Feats.BossKilled(name)
    name = ns.Plain(name, "string")
    if not name or not BY_BOSS[name] then return end
    db().bosses[name] = db().bosses[name] or time()
    Feats.Check(BY_BOSS[name])
end

-- A mob you fought died.
function Feats.Killed(name, creatureType)
    if name then
        for prefix, counter in pairs(NAME_PREFIX) do
            if name:sub(1, #prefix) == prefix then bump(counter) end
        end
        if BY_BOSS[name] then Feats.BossKilled(name) end
    end
    local counter = creatureType and CREATURE_TYPE[creatureType]
    if counter then bump(counter) end
end

---------------------------------------------------------------------------
-- Mode
---------------------------------------------------------------------------
function Feats.SetMode(mode)
    local d = db()
    d.unlockMode = mode
    -- A skin that's locked in Collector falls back to Auto.
    if mode == "collector" and not Feats.IsUnlocked(d.skin) then
        ns.Print(("%s is locked in Collector mode, so you're on Auto: my class until you earn it.")
            :format(ns.Skins[d.skin] and ns.Skins[d.skin].name or d.skin))
        d.skin = ns.AUTO
        ns.ApplyCVars()
    end
    if ns.OnSettingsChanged then ns.OnSettingsChanged() end
end

---------------------------------------------------------------------------
-- Tracking
---------------------------------------------------------------------------
local CRIT = { CRITICAL = true, CRUSHING = true }
local SCHOOL_COUNTER = { [4] = "fire", [16] = "frost", [64] = "arcane" }

-- Enemy units we hit, by unit token, until they die or the token moves on.
local engaged = {}

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(fn, ...)
    if ok then return r end
end

-- Refreshed on every hit: a token can come to carry a different mob (a
-- plate reused, a target swapped) without an event in between.
local function engage(u)
    if ns.SafeBool(UnitIsPlayer, u) then engaged[u] = nil; return end
    local rec = engaged[u] or {}
    rec.name = ns.Plain(call(UnitName, u), "string")
    rec.ctype = ns.Plain(call(UnitCreatureType, u), "string")
    engaged[u] = rec
end

local function checkDead(u)
    local rec = engaged[u]
    if not rec or not ns.SafeBool(UnitIsDead, u) then return end
    engaged[u] = nil
    -- The same mob may be engaged under its other token (target + plate).
    for other in pairs(engaged) do
        if ns.SafeBool(UnitIsUnit, u, other) then engaged[other] = nil end
    end
    Feats.Killed(rec.name, rec.ctype)
end
Feats.CheckDead = checkDead

local function specKey()
    local spec = C_SpecializationInfo
    local idx = spec and ns.Plain(call(spec.GetSpecialization), "number")
    local ok, _, cls = pcall(UnitClass, "player")
    cls = ok and ns.Plain(cls, "string")
    if not (idx and cls) then return nil end
    return cls .. ":" .. idx
end

function Feats.OnCombat(unit, action, flags, amount, school)
    if not db() then return end
    local u = ns.Plain(unit, "string")
    if not u or (u ~= "target" and not u:find("^nameplate%d")) then return end
    if ns.SafeBool(UnitCanAttack, "player", u) == false then return end
    if ns.Plain(action, "string") ~= "WOUND" then return end
    if ns.Plain(amount, "number") == 0 then return end -- a miss in disguise
    engage(u)
    -- The target's own plate fires too: count each hit once.
    if u ~= "target" and ns.SafeBool(UnitIsUnit, u, "target") then return end
    bump("hits")
    if CRIT[ns.Plain(flags, "string") or ""] then
        bump("crits")
        local key = specKey()
        if key then db().specCrits[key] = (db().specCrits[key] or 0) + 1 end
    end
    local sc = SCHOOL_COUNTER[ns.Plain(school, "number") or 1]
    if sc then bump(sc) end
end

local lastMoney
local function money()
    local m = ns.Plain(call(GetMoney), "number")
    if not m then return end
    if lastMoney and m > lastMoney then bump("gold", m - lastMoney) end
    lastMoney = m
end

local function level(newLevel)
    local lvl = ns.Plain(newLevel, "number") or ns.Plain(call(UnitLevel, "player"), "number")
    local ok, _, cls = pcall(UnitClass, "player")
    cls = ok and ns.Plain(cls, "string")
    if not lvl then return end
    local d = db()
    if cls and (d.classLevels[cls] or 0) < lvl then d.classLevels[cls] = lvl end
    if (d.counters.maxLevel or 0) < lvl then d.counters.maxLevel = lvl end
    Feats.Check()
end

local events = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UNIT_COMBAT", "UNIT_HEALTH", "PLAYER_TARGET_CHANGED",
                     "NAME_PLATE_UNIT_REMOVED", "ENCOUNTER_END", "BOSS_KILL", "PLAYER_MONEY", "PLAYER_LEVEL_UP" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function(_, event, a, b, c, d, e)
    if not db() then return end
    if event == "UNIT_COMBAT" then
        Feats.OnCombat(a, b, c, d, e)
    elseif event == "UNIT_HEALTH" then
        local u = ns.Plain(a, "string")
        if u and engaged[u] then checkDead(u) end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local u = ns.Plain(a, "string")
        if u and engaged[u] then
            checkDead(u)
            engaged[u] = nil  -- the token will carry another unit next
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        engaged.target = nil  -- "target" is someone else now
    elseif event == "ENCOUNTER_END" then
        if e == 1 or e == true then Feats.BossKilled(b) end
    elseif event == "BOSS_KILL" then
        Feats.BossKilled(b)
    elseif event == "PLAYER_MONEY" then
        money()
    elseif event == "PLAYER_LEVEL_UP" then
        level(a)
    elseif event == "PLAYER_LOGIN" then
        -- Records this character's level (and checks every feat: anything
        -- already reached, like a level 60's class feat, pops now).
        level()
    elseif event == "PLAYER_ENTERING_WORLD" then
        lastMoney = nil
        money()
    end
end)
