local _, ns = ...

-- Skin rotation: your numbers can change skin by themselves.
--   rotate          "off", "fight" (a new random skin each fight) or "cycle"
--                   (the next skin every rotateMinutes, between fights)
--   rotatePicks     skins you picked to rotate through (Ctrl-click in the
--                   list); none picked: every skin you've unlocked
--   zoneRules       a skin per kind of place (zoneSkins: dungeon, raid,
--                   city, world)
--   enemyRules      a skin per creature type you're hitting (enemySkins,
--                   keyed by the game's English type: Undead, Demon...)
-- Priority for a hit: the PvP skin, then the enemy's skin, then the zone's,
-- then the rotation, then the skin you chose. Only SkinDeep's own numbers
-- rotate; Blizzard's keep your chosen skin's font.

local R = {}
ns.Rotation = R

R.ZONES = { { "dungeon", "Dungeons" }, { "raid", "Raids" }, { "city", "Cities and inns" }, { "world", "Open world" } }
R.ENEMIES = { "Beast", "Demon", "Dragonkin", "Elemental", "Giant", "Humanoid", "Mechanical", "Undead" }
-- A fitting skin per creature type, filled in (if unlocked) the first time
-- enemy skins are turned on.
R.SUGGEST = { Beast = "hunter", Demon = "chainrev", Dragonkin = "brood", Elemental = "tidecaller",
              Giant = "steamblades", Mechanical = "gearworks", Undead = "scourge" }

local current, switchedAt

local function usable(id)
    return id and ns.Skins[id] ~= nil and (not ns.Feats or ns.Feats.IsUnlocked(id))
end
R.Usable = usable

-- The skins the rotation draws from, in list order.
function R.Pool()
    local db, picked, all = ns.db, {}, {}
    for _, id in ipairs(ns.SkinOrder) do
        if usable(id) then
            all[#all + 1] = id
            if db.rotatePicks[id] then picked[#picked + 1] = id end
        end
    end
    return #picked > 0 and picked or all, #picked > 0
end

function R.IsPicked(id) return ns.db.rotatePicks[id] == true end

function R.TogglePick(id)
    if not ns.Skins[id] then return end
    ns.db.rotatePicks[id] = not ns.db.rotatePicks[id] or nil
end

local function now() return (GetTime and GetTime()) or 0 end

-- Moves the rotation on: a random other skin ("fight") or the next one.
function R.Advance()
    local pool = R.Pool()
    if #pool == 0 then current = nil; return end
    local at
    for i, id in ipairs(pool) do if id == current then at = i end end
    if ns.db.rotate == "cycle" then
        current = pool[at and (at % #pool + 1) or 1]
    elseif #pool == 1 then
        current = pool[1]
    else
        local pick = math.random(#pool - (at and 1 or 0))
        if at and pick >= at then pick = pick + 1 end
        current = pool[pick]
    end
    switchedAt = now()
end

-- A fight starts: time for a new skin?
function R.OnCombatStart()
    local mode = ns.db and ns.db.rotate
    if mode == "fight" then
        R.Advance()
    elseif mode == "cycle" and (not current or now() - (switchedAt or 0) >= (ns.db.rotateMinutes or 10) * 60) then
        R.Advance()
    end
end

-- The rotation's skin right now, or nil when it's off.
function R.Current()
    local mode = ns.db and ns.db.rotate
    if mode ~= "fight" and mode ~= "cycle" then return nil end
    if not usable(current) then R.Advance() end
    return current
end

-- Where you are: "dungeon", "raid", "city" (resting) or "world"; nil in
-- battlegrounds and arenas, where the PvP skin rules.
function R.ZoneKind()
    local ok, inside, kind = pcall(IsInInstance)
    kind = ok and ns.Plain(kind, "string")
    if kind == "party" then return "dungeon" end
    if kind == "raid" then return "raid" end
    if kind == "pvp" or kind == "arena" then return nil end
    if ns.SafeBool(rawget(_G, "IsResting")) then return "city" end
    return "world"
end

function R.ZoneSkin()
    if not ns.db.zoneRules then return nil end
    local kind = R.ZoneKind()
    local id = kind and ns.db.zoneSkins[kind]
    return usable(id) and id or nil
end

function R.EnemySkin(unit)
    if not (ns.db.enemyRules and unit) then return nil end
    local ok, t = pcall(UnitCreatureType, unit)
    t = ok and ns.Plain(t, "string")
    local id = t and ns.db.enemySkins[t]
    return usable(id) and id or nil
end

-- The skin for a hit, or nil for your chosen skin. side: "out" (your hits)
-- or "inc" (hits you take, which have no known source: no enemy rule).
function R.SkinFor(unit, side)
    if not ns.db then return nil end
    return (side == "out" and R.EnemySkin(unit)) or R.ZoneSkin() or R.Current()
end

-- Turning enemy skins on the first time fills in the suggestions you own.
function R.SetEnemyRules(on)
    ns.db.enemyRules = on and true or false
    if on and not ns.db.enemySuggested then
        ns.db.enemySuggested = true
        for t, id in pairs(R.SUGGEST) do
            if not ns.db.enemySkins[t] and usable(id) then ns.db.enemySkins[t] = id end
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent", function() R.OnCombatStart() end)
