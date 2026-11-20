local _, ns = ...

-- Skin sharing between SkinDeep users: each copy tells the others which skin
-- it uses (addon messages to the group, the guild, and whispers on request).
-- Other players' skins show on their tooltip, can be previewed with
-- /skindeep peek, and in a duel the hits you take show in your opponent's
-- skin. Damage numbers can't be traced to who dealt them, so a duel (only
-- your opponent hits you) is the one place another player's skin can show.
--
-- Messages (prefix "SkinDeep"):
--   S1|skin|tier|pvpSkin|pvpTier   the sender's skin ("" pvpSkin: none)
--   Q1                             asks for the receiver's S1

local Share = {}
ns.Share = Share

local PREFIX = "SkinDeep"
local THROTTLE = 5         -- seconds between broadcasts on one channel
local ASK_AGAIN = 300      -- seconds before asking the same player again
local UNREACHABLE = 600    -- a player a request couldn't reach isn't asked again for this long
local peers = {}           -- full name -> { id, tier, pvp, pvpTier, at }
Share.peers = peers

local function global(name)
    local v = rawget(_G, name)
    return v
end
local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
end
local function now() return call(global("GetTime")) or 0 end

local function plain(v) return ns.Plain(v, "string") end

-- "Name-Realm" (or "Name-Surname" on Forever) to "Name".
local function short(name)
    name = plain(name)
    return name and name:match("^([^%-]+)") or nil
end

-- A unit's full name, the one whispers reach: on Forever the second part is
-- the character's surname ("Haze-Grimm"), and a first name alone isn't
-- unique, so a whisper to it can miss ("No player named ...").
local function fullName(unit)
    local first, second = call(global("UnitFullName"), unit)
    first, second = plain(first), plain(second)
    if not first then first = plain(call(global("UnitName"), unit)) end
    if not first then return nil end
    if second and second ~= "" then return first .. "-" .. second end
    return first
end
Share.FullName = fullName

-- Same character? Exact, or the same first name when one side has no
-- surname to compare.
local function sameName(a, b)
    a, b = plain(a), plain(b)
    if not a or not b then return false end
    if a == b then return true end
    return short(a) == short(b) and not (a:find("-", 1, true) and b:find("-", 1, true))
end
local function isMe(name) return sameName(name, fullName("player")) end

local function enabled() return ns.db and ns.db.shareSkins ~= false end

local function api()
    local c = global("C_ChatInfo")
    return c and c.SendAddonMessage, c and c.RegisterAddonMessagePrefix
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------
function Share.Payload()
    local F = ns.Feats
    local id = ns.ResolvedSkinID()
    local tier = F and F.SkinTier(id) or 0
    local pvp = ns.db.pvpSkin
    if not (pvp and ns.Skins[pvp] and (not F or F.IsUnlocked(pvp))) then pvp = nil end
    local pvpTier = pvp and F and F.SkinTier(pvp) or 0
    return ("S1|%s|%d|%s|%d"):format(id, tier or 0, pvp or "", pvpTier or 0)
end

-- Addon messages can be held back in combat inside instances: wait for the
-- fight to end instead.
local function blocked()
    if not call(global("InCombatLockdown")) then return false end
    local inInstance = call(global("IsInInstance"))
    return inInstance and true or false
end

local pending = {}        -- channel or "WHISPER:name" -> text, sent after combat
local lastSent = {}
local whispered = {}      -- full name -> when SkinDeep last whispered them
local function send(text, channel, target)
    if not enabled() then return end
    local sendFn = api()
    if not sendFn then return end
    local key = target and ("WHISPER:" .. target) or channel
    if blocked() then pending[key] = text; return end
    if target then whispered[target] = now() end
    pcall(sendFn, PREFIX, text, channel, target)
    lastSent[key] = now()
end
Share.Send = send

local function groupChannel()
    local inGroup = global("IsInGroup")
    local instanceCategory = global("LE_PARTY_CATEGORY_INSTANCE")
    if instanceCategory and call(inGroup, instanceCategory) then return "INSTANCE_CHAT" end
    if call(global("IsInRaid")) then return "RAID" end
    if call(inGroup) then return "PARTY" end
end

local lastPayload
-- Tells the group (and the guild) which skin you use.
function Share.Broadcast(force)
    if not enabled() or not ns.db then return end
    local text = Share.Payload()
    for _, channel in ipairs({ groupChannel() or false, call(global("IsInGuild")) and "GUILD" or false }) do
        if channel and (force or not lastSent[channel] or now() - lastSent[channel] >= THROTTLE or text ~= lastPayload) then
            send(text, channel)
        end
    end
    lastPayload = text
end

local soon
local function broadcastSoon(delay)
    if soon then return end
    soon = true
    local function go() soon = false; Share.Broadcast() end
    local after = global("C_Timer") and C_Timer.After
    if after then after(delay or 2, go) else go() end
end

---------------------------------------------------------------------------
-- Receiving
---------------------------------------------------------------------------
local asked, answered, unreachable = {}, {}, {}

-- Asks one player (by full name) for their skin, at most every few minutes,
-- and not at all for a while once a request couldn't reach them.
function Share.Ask(name)
    name = plain(name)
    if not name or isMe(name) or not enabled() then return false end
    if unreachable[name] and now() < unreachable[name] then return false end
    if asked[name] and now() - asked[name] < ASK_AGAIN then return false end
    asked[name] = now()
    send("Q1", "WHISPER", name)
    return true
end

-- "No player named 'X' is currently playing." for a whisper SkinDeep just
-- sent (offline, another faction, a first name that isn't unique): hidden
-- from chat, and that player isn't asked again for a while.
local notFoundPattern
local function notFoundName(msg)
    if not notFoundPattern then
        local fmt = global("ERR_CHAT_PLAYER_NOT_FOUND_S")
        if type(fmt) == "string" and fmt:find("%s", 1, true) then
            notFoundPattern = "^" .. fmt:gsub("([%(%)%.%[%]%*%+%-%?%^%$])", "%%%1"):gsub("%%s", "(.+)")
        else
            notFoundPattern = "^No player named '(.+)' is currently playing"
        end
    end
    return msg:match(notFoundPattern)
end
function Share.FilterSystemMessage(_, _, msg, ...)
    msg = plain(msg)
    local who = msg and notFoundName(msg)
    if not who then return false end
    for target, at in pairs(whispered) do
        if now() - at < 10 and sameName(target, who) then
            unreachable[target] = now() + UNREACHABLE
            whispered[target] = nil
            return true
        end
    end
    return false
end

local function onMessage(prefix, text, channel, sender)
    if ns.Plain(prefix, "string") ~= PREFIX or not enabled() then return end
    text, channel = ns.Plain(text, "string"), ns.Plain(channel, "string")
    local who = plain(sender)     -- the full name, as the game addresses them
    if not text or not who or isMe(who) then return end
    unreachable[who] = nil
    if text == "Q1" then
        if not answered[who] or now() - answered[who] >= THROTTLE then
            answered[who] = now()
            send(Share.Payload(), "WHISPER", who)
        end
        return
    end
    local id, tier, pvp, pvpTier = text:match("^S1|([%w_]+)|(%d+)|([%w_]*)|(%d+)")
    if not id then return end
    local known = peers[who]
    peers[who] = { id = id, tier = tonumber(tier), pvp = pvp ~= "" and pvp or nil, pvpTier = tonumber(pvpTier), at = now() }
    -- Someone new in the group: make sure they know yours too.
    if not known and (channel == "PARTY" or channel == "RAID" or channel == "INSTANCE_CHAT") then broadcastSoon(1) end
    if Share.OnPeer then Share.OnPeer(who) end
end
Share.OnMessage = onMessage

-- The record for a name: exact, or the one peer with that first name.
local function peerOf(name)
    name = plain(name)
    if not name then return nil end
    if peers[name] then return peers[name] end
    local found
    for key, p in pairs(peers) do
        if sameName(key, name) then
            if found then return nil end   -- two with that first name: can't tell
            found = p
        end
    end
    return found
end

-- A player's skin (one this copy has), as id, tier; nil if unknown. pvp:
-- the skin they use against players, when they set one.
function Share.SkinOf(name, pvp)
    local p = peerOf(name)
    if not p then return nil end
    if pvp and p.pvp and ns.Skins[p.pvp] then return p.pvp, p.pvpTier end
    if ns.Skins[p.id] then return p.id, p.tier end
end

-- "Grand Marshal", or "Anvilstrike · Artisan" for a tiered skin.
function Share.Describe(id, tier)
    local skin = ns.Skins[id]
    if not skin then return nil end
    local tiers = ns.Feats and ns.Feats.PROF_TIERS
    if skin.tiers and tiers and tiers[tier or 0] then return ("%s · %s"):format(skin.name, tiers[tier][2]) end
    return skin.name
end

---------------------------------------------------------------------------
-- Tooltips
---------------------------------------------------------------------------
local function addTooltipLine(tip)
    if not enabled() or not tip or not tip.GetUnit then return end
    local ok, _, unit = pcall(tip.GetUnit, tip)
    unit = ok and ns.Plain(unit, "string")
    if not unit or not ns.SafeBool(UnitIsPlayer, unit) then return end
    local name = fullName(unit)
    if not name then return end
    local id, tier
    if isMe(name) then
        id = ns.ResolvedSkinID()
        tier = ns.Feats and ns.Feats.SkinTier(id)
    else
        id, tier = Share.SkinOf(name)
        if not id then
            -- Ask quietly; the line appears next time (or right away if the
            -- answer arrives while this tooltip is still up).
            -- Whispers only reach your own faction.
            local theirs = plain(call(global("UnitFactionGroup"), unit))
            local mine = plain(call(global("UnitFactionGroup"), "player"))
            if theirs and theirs == mine and not call(global("InCombatLockdown")) then Share.Ask(name) end
            return
        end
    end
    local text = Share.Describe(id, tier)
    if text then
        local c = ns.Skins[id].color or { 1, 1, 1 }
        pcall(tip.AddLine, tip, "SkinDeep: " .. text, c[1], c[2], c[3])
        tip.skinDeepLine = name
    end
end
Share.AddTooltipLine = addTooltipLine

local function hookTooltips()
    local processor = global("TooltipDataProcessor")
    local enum = global("Enum")
    if processor and processor.AddTooltipPostCall and enum and enum.TooltipDataType and enum.TooltipDataType.Unit then
        pcall(processor.AddTooltipPostCall, enum.TooltipDataType.Unit, function(tip)
            if tip == GameTooltip then addTooltipLine(tip) end
        end)
    elseif GameTooltip and GameTooltip.HookScript then
        pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", addTooltipLine)
    end
end

-- An answer that arrives while that player's tooltip is up shows at once.
Share.OnPeer = function(name)
    local tip = GameTooltip
    if not (tip and tip.IsShown and tip:IsShown() and tip.GetUnit) then return end
    local ok, _, unit = pcall(tip.GetUnit, tip)
    unit = ok and ns.Plain(unit, "string")
    if unit and sameName(fullName(unit), name) and tip.skinDeepLine ~= name then
        addTooltipLine(tip)
        pcall(tip.Show, tip)
    end
end

---------------------------------------------------------------------------
-- Duels: the hits you take show in your opponent's skin
---------------------------------------------------------------------------
local duelWith, duelAt
local DUEL_EXPIRY = 300   -- a request nobody answered stops counting after this

local function setOpponent(name)
    name = plain(name)
    if not name or isMe(name) then return end
    -- The request may name them by first name: use your target's full name
    -- when it's them.
    if not name:find("-", 1, true) and sameName(fullName("target"), name) then name = fullName("target") end
    duelWith, duelAt = name, now()
    -- Swap skins now, before the fight starts.
    send(Share.Payload(), "WHISPER", name)
    asked[name] = nil
    Share.Ask(name)
end

-- The skin for hits you take: your duel opponent's, when they use SkinDeep.
function Share.IncomingSkin()
    if not (enabled() and duelWith) or now() - duelAt > DUEL_EXPIRY then return nil end
    return Share.SkinOf(duelWith, true)
end
function Share.DuelOpponent() return duelWith end

local function hookDuels()
    local hook = global("hooksecurefunc")
    if hook and global("StartDuel") then
        pcall(hook, "StartDuel", function(unit)
            setOpponent(fullName(unit or "target"))
        end)
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "CHAT_MSG_ADDON",
                     "PLAYER_REGEN_ENABLED", "DUEL_REQUESTED", "DUEL_FINISHED" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function(_, event, a, b, c, d)
    if event == "CHAT_MSG_ADDON" then
        onMessage(a, b, c, d)
    elseif event == "PLAYER_LOGIN" then
        local _, register = api()
        if register then pcall(register, PREFIX) end
        hookTooltips()
        hookDuels()
        local addFilter = global("ChatFrame_AddMessageEventFilter")
        if addFilter then pcall(addFilter, "CHAT_MSG_SYSTEM", Share.FilterSystemMessage) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        broadcastSoon(5)
    elseif event == "GROUP_ROSTER_UPDATE" then
        broadcastSoon(2)
    elseif event == "PLAYER_REGEN_ENABLED" then
        local sendFn = api()
        for key, text in pairs(pending) do
            pending[key] = nil
            local target = key:match("^WHISPER:(.+)")
            if target then whispered[target] = now() end
            if sendFn then pcall(sendFn, PREFIX, text, target and "WHISPER" or key, target) end
        end
    elseif event == "DUEL_REQUESTED" then
        setOpponent(a)
    elseif event == "DUEL_FINISHED" then
        -- Let the last hits finish in their skin.
        local after = global("C_Timer") and C_Timer.After
        local function done() duelWith = nil end
        if after then after(1.5, done) else done() end
    end
end)

-- Your skin changed: tell the others (debounced).
local prevChanged = ns.OnSettingsChanged
ns.OnSettingsChanged = function(...)
    if prevChanged then prevChanged(...) end
    if ns.db and enabled() and Share.Payload() ~= lastPayload then broadcastSoon(2) end
end
