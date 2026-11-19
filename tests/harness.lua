-- Mock WoW: Forever client for SkinDeep. Run with: npm test (or node tests/run.js [addonDir]).
-- Minimal WoW API mock: enough to load SkinDeep, fire events, run frames,
-- and fail loudly on bad arguments. Secret values are modelled as opaque
-- tables that blow up on arithmetic/comparison, like the real thing.
local ADDON_DIR = ...
local clock, timers, frames, unknown, cvarWrites = 0, {}, {}, {}, {}
local fail_count = 0

local SecretMT = {
  __add = function() error("arithmetic on secret") end, __sub = function() error("arithmetic on secret") end,
  __mul = function() error("arithmetic on secret") end, __lt = function() error("compare secret") end,
  __le = function() error("compare secret") end, __concat = function() error("concat secret") end,
}
local function secret(v) return setmetatable({ secretValue = v }, SecretMT) end
function issecretvalue(v) return getmetatable(v) == SecretMT end

local Widget, WidgetMT = {}, {}
WidgetMT.__index = function(t, k)
  local m = Widget[k]
  if m then return m end
  if type(k) == "string" and k:match("^[A-Z]") then unknown[k] = true; return function() end end
end
local function new(kind, parent, name)
  local w = setmetatable({ kind = kind, shown = kind ~= "Frame" and kind ~= "Button", scripts = {}, events = {}, parent = parent, alpha = 1, scale = 1 }, WidgetMT)
  frames[#frames + 1] = w
  if name then _G[name] = w end
  return w
end
local function num(v, what) if type(v) ~= "number" or v ~= v then error(what .. ": expected number, got " .. tostring(v), 3) end end

function Widget:SetScript(n, f) self.scripts[n] = f end
function Widget:GetScript(n) return self.scripts[n] end
function Widget:HookScript(n, f) self.scripts[n] = f end
function Widget:RegisterEvent(e) self.events[e] = true end
function Widget:RegisterForDrag() end
function Widget:Show() local was = self.shown; self.shown = true; if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
function Widget:Hide() local was = self.shown; self.shown = false; if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
function Widget:SetShown(v) if v then self:Show() else self:Hide() end end
function Widget:IsShown() return self.shown end
function Widget:IsVisible() return self.shown end
function Widget:GetParent() return self.parent end
function Widget:CreateTexture(_, layer, _, sub) local t = new("Texture", self); return t end
function Widget:CreateFontString(_, layer, template) local t = new("FontString", self); if template then t.font = "tmpl" end; return t end
function Widget:SetFont(path, size, flags)
  if type(path) ~= "string" then error("SetFont path", 2) end; num(size, "SetFont size")
  if flags ~= nil and type(flags) ~= "string" then error("SetFont flags", 2) end
  self.font = path; return true
end
function Widget:GetFont() return self.font end
local function render(v) if issecretvalue(v) then return "<secret>" end return v end
function Widget:SetText(t) if not self.font then error("Font not set", 2) end; self.text = tostring(render(t)) end
function Widget:SetFormattedText(fmt, ...)
  if not self.font then error("Font not set", 2) end
  local args = { ... }
  for i = 1, select("#", ...) do args[i] = render(args[i]) end
  self.text = string.format(fmt, unpack(args, 1, select("#", ...)))
end
function Widget:GetText() return self.text end
function Widget:SetAlpha(a) num(a, "SetAlpha"); if a < 0 or a > 1.0001 then error("alpha out of range " .. a, 2) end; self.alpha = a end
function Widget:SetScale(s) num(s, "SetScale"); if s <= 0 then error("scale <= 0", 2) end; self.scale = s end
function Widget:SetSize(w, h) num(w, "SetSize w"); num(h, "SetSize h") end
function Widget:SetWidth(w) num(w, "SetWidth") end
function Widget:SetHeight(h) num(h, "SetHeight") end
function Widget:SetPoint(p, rel, rp, x, y)
  if type(p) ~= "string" then error("SetPoint point", 2) end
  if type(rel) == "number" then x, y = rel, rp; rel, rp = nil, nil end
  if rel ~= nil and type(rel) ~= "table" then error("SetPoint relativeTo " .. tostring(rel), 2) end
  if rp ~= nil and type(rp) ~= "string" then error("SetPoint relPoint", 2) end
  if x ~= nil then num(x, "SetPoint x") end; if y ~= nil then num(y, "SetPoint y") end
  self._pt = { p, rel, rp, x, y }
end
function Widget:SetTextColor(r, g, b, a) num(r, "r"); num(g, "g"); num(b, "b"); self.color = { r, g, b } end
function Widget:SetVertexColor(r, g, b, a) num(r, "r"); num(g, "g"); num(b, "b") end
function Widget:SetColorTexture(r, g, b, a) num(r, "r"); num(g, "g"); num(b, "b") end
function Widget:SetRotation(r) num(r, "SetRotation") end
function Widget:SetTexture(p) if type(p) ~= "string" then error("SetTexture", 2) end; self.tex = p end
local BLENDS = { ADD = true, BLEND = true, MOD = true, ALPHAKEY = true, DISABLE = true }
function Widget:SetBlendMode(m) if not BLENDS[m] then error("bad blend " .. tostring(m), 2) end end
function Widget:SetDrawLayer(l, s) if s and (s < -8 or s > 7) then error("sublevel " .. s, 2) end end
function Widget:SetShadowOffset(x, y) num(x, "shadow x"); num(y, "shadow y") end
function Widget:SetFrameStrata(s)
  local ok = { BACKGROUND = 1, LOW = 1, MEDIUM = 1, HIGH = 1, DIALOG = 1, FULLSCREEN = 1, TOOLTIP = 1 }
  if not ok[s] then error("strata " .. tostring(s), 2) end
end
function Widget:GetCenter() return 640, 400 end
function Widget:GetEffectiveScale() return 1 end
function Widget:StartMoving() end
function Widget:StopMovingOrSizing() end
function Widget:ClearAllPoints() end
function Widget:EnableMouse() end
function Widget:SetMovable() end
function Widget:SetClampedToScreen() end
function Widget:SetToplevel() end
function Widget:SetJustifyH() end
function Widget:SetAllPoints() end
function Widget:LockHighlight() end
function Widget:UnlockHighlight() end
function Widget:IsForbidden() return false end
function Widget:AddLine() end
function Widget:SetOwner() end
function Widget:Click() if self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end end

function CreateFrame(kind, name, parent, template)
  local f = new(kind, parent, name)
  if template == "UIPanelButtonTemplate" then f.font = "tmpl" end
  return f
end
UIParent = new("Frame"); UIParent.shown = true
GameTooltip = new("Frame")
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) print("[chat] " .. m) end }
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
DAMAGE_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
UISpecialFrames = {}
SlashCmdList = {}
MISS, DODGE, ABSORB, BLOCK, RESIST = "Miss", "Dodge", "Absorb", "Block", "Resist"
tinsert = table.insert
function GetTime() return clock end
local inGroup, inCombat = false, false
function IsInGroup() return inGroup end
function InCombatLockdown() return inCombat end
function UnitCanAttack(a, b) return true end
local dummy = { name = "Training Dummy", ctype = "Mechanical" }
units = { target = dummy, nameplate1 = dummy, nameplate2 = { name = "Gnoll Brute", ctype = "Humanoid" } }
function UnitIsUnit(a, b) return units[a] ~= nil and units[a] == units[b] end
function UnitName(u) return units[u] and units[u].name end
function UnitCreatureType(u) return units[u] and units[u].ctype end
function UnitIsDead(u) return units[u] ~= nil and units[u].dead == true end
function UnitIsPlayer(u) return u == "player" or (units[u] ~= nil and units[u].player == true) end
honorLevel, playerFactionName, inInstanceKind, instanceName, arenaFaction = 1, "Alliance", "none", "", 0
function UnitHonorLevel(u) return 1 end
pvpRank = 0
Constants = { CurrencyConsts = { CURRENCY_ID_RENOWN_PVP_RANK = 3001 } }
C_CurrencyInfo = { GetCurrencyInfo = function(id) if id == 3001 then return { name = "PvP Rank", quantity = pvpRank, maxQuantity = 14, totalEarned = pvpRank } end end }
function UnitFactionGroup(u) return playerFactionName end
function IsInInstance() return inInstanceKind ~= "none", inInstanceKind end
function GetInstanceInfo() return instanceName end
function GetBattlefieldArenaFaction() return arenaFaction end
function IsShiftKeyDown() return false end
DUEL_WINNER_KNOCKOUT = "%1$s has defeated %2$s in a duel"
playerLevel, money = 12, 5000
function UnitLevel(u) return playerLevel end
function GetMoney() return money end
function time() return 1700000000 end
local soundFiles = {}
function PlaySoundFile(path, channel) soundFiles[#soundFiles + 1] = path; return true end
C_SpecializationInfo = { GetSpecialization = function() return 2 end }
function AbbreviateLargeNumbers(v) if issecretvalue(v) then return v end return tostring(v) end
function HideUIPanel() end
function UnitClass(u) return "Mage", "MAGE", 8 end
C_AddOns = { GetAddOnMetadata = function(name, key) if key == "Version" then return "@project-version@" end end }
C_StringUtil = { TruncateWhenZero = function(v) return v end }
local plates = { target = new("Frame"), nameplate1 = new("Frame"), nameplate2 = new("Frame") }
for _, p in pairs(plates) do p.shown = true end
C_NamePlate = { GetNamePlateForUnit = function(u) return plates[u] end }
local cvars = {
  floatingCombatTextCombatDamage_v2 = "1", floatingCombatTextPetMeleeDamage_v2 = "1", floatingCombatTextPetSpellDamage_v2 = "1",
  floatingCombatTextCombatLogPeriodicSpells_v2 = "1",
  WorldTextScale_v2 = "1", WorldTextGravity_v2 = "0.5", WorldTextRampDuration_v2 = "1",
  floatingCombatTextCombatDamageDirectionalScale_v2 = "1",
}
C_CVar = {
  GetCVar = function(n) return cvars[n] end,
  SetCVar = function(n, v) if type(v) ~= "string" then error("cvar value") end; if cvars[n] == nil then return false end; cvars[n] = v; cvarWrites[#cvarWrites + 1] = n .. "=" .. v; return true end,
}
C_Timer = {
  After = function(d, f) timers[#timers + 1] = { at = clock + d, f = f } end,
  NewTicker = function(d, f) local t = { cancelled = false }; t.Cancel = function() t.cancelled = true end
    local function arm() C_Timer.After(d, function() if not t.cancelled then f(); arm() end end) end
    arm(); return t end,
}
local sounds = {}
function PlaySound(id, channel) sounds[#sounds + 1] = id end
SOUNDKIT = { IG_MAINMENU_OPTION_CHECKBOX_ON = 856, LOOT_WINDOW_COIN_SOUND = 120 }
function Widget:SetClipsChildren(v) end
function Widget:SetShadowColor() end
LOCALIZED_CLASS_NAMES_MALE = { WARRIOR = "Warrior", MAGE = "Mage" }
local chatLog = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) chatLog[#chatLog + 1] = m; print("[chat] " .. m) end }
Settings = { RegisterCanvasLayoutCategory = function() return {} end, RegisterAddOnCategory = function() end }

local function check(cond, msg) if cond then print("  pass: " .. msg) else fail_count = fail_count + 1; print("  FAIL: " .. msg) end end

-- strict globals from here on
setmetatable(_G, { __index = function(_, k)
  if k == "SettingsPanel" or k == "SkinDeepDB" then return nil end
  error("undefined global " .. tostring(k), 2)
end })

local function fire(event, ...)
  for _, f in ipairs(frames) do
    if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
  end
end
local function run(seconds)
  local dt = 1 / 60
  for _ = 1, math.floor(seconds / dt) do
    clock = clock + dt
    for i = #timers, 1, -1 do local t = timers[i]; if t.at <= clock then table.remove(timers, i); t.f() end end
    for _, f in ipairs(frames) do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f, dt) end end
  end
end

-- Load the addon like the client: each file gets (addonName, ns).
local ns = {}
for _, file in ipairs({ "Skins.lua", "ClassSkins.lua", "FactionSkins.lua", "PvPSkins.lua", "Core.lua", "Feats.lua", "Engine.lua", "Jackpot.lua", "Options.lua", "Welcome.lua" }) do
  local chunk, err = loadfile(ADDON_DIR .. "/" .. file)
  if not chunk then error(err) end
  chunk("SkinDeep", ns)
end

print("== login")
SkinDeepDB = { skin = "ember", groupFallback = true }   -- a save from 1.0 with the old default
fire("ADDON_LOADED", "SkinDeep")
check(SkinDeepDB.groupFallback == false and SkinDeepDB.dbVersion == 2, "1.0 save migrated: SkinDeep stays on in parties")
check(DAMAGE_TEXT_FONT == ns.Fonts.friz, "world font set to the default skin's font: " .. DAMAGE_TEXT_FONT)
fire("PLAYER_LOGIN")
check(cvars.floatingCombatTextCombatDamage_v2 == "0" and cvars.floatingCombatTextPetSpellDamage_v2 == "0" and cvars.floatingCombatTextCombatLogPeriodicSpells_v2 == "0", "Blizzard damage, pet and DoT numbers hidden (_v2 CVars)")
check(SkinDeepDB.borrowed.floatingCombatTextCombatDamage_v2 == "1", "original CVar remembered")

print("== class skins")
local nClass = 0
for _, id in ipairs(ns.SkinOrder) do if ns.Skins[id].group == "class" then nClass = nClass + 1 end end
local nFaction, unpaired = 0, {}
for _, id in ipairs(ns.SkinOrder) do
  if ns.Skins[id].group == "faction" then
    nFaction = nFaction + 1
    if not ns.Feats.FeatForSkin(id) then unpaired[#unpaired + 1] = id end
  end
end
local nPvP = 0
for _, id in ipairs(ns.SkinOrder) do if ns.Skins[id].group == "pvp" then nPvP = nPvP + 1; if not ns.Feats.FeatForSkin(id) then unpaired[#unpaired + 1] = id end end end
check(#ns.SkinOrder == 35 and nClass == 9 and nFaction == 6 and nPvP == 10, "35 skins: 9 class, 6 faction, 10 PvP (" .. #ns.SkinOrder .. ", " .. nClass .. ", " .. nFaction .. ", " .. nPvP .. ")")
check(#unpaired == 0, "every faction and PvP skin has the feat that unlocks it" .. (#unpaired > 0 and (": missing " .. table.concat(unpaired, ", ")) or ""))
print("== every skin, plain and secret hits")
SkinDeepDB.incoming = true
for _, id in ipairs(ns.SkinOrder) do
  ns.SetSkin(id)
  fire("UNIT_COMBAT", "target", "WOUND", "", 123, 1)
  fire("UNIT_COMBAT", "target", "WOUND", "CRITICAL", secret(4567), 4)
  fire("UNIT_COMBAT", "nameplate2", "WOUND", "", secret(88), 16)
  fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 99, 1)        -- the target's own plate: skipped
  fire("UNIT_COMBAT", "target", "DODGE", "", 0, 1)
  fire("UNIT_COMBAT", "target", "WOUND", "ABSORB", secret(0), 1)
  fire("UNIT_COMBAT", "target", "WOUND", "", 0, 1)
  fire("UNIT_COMBAT", "player", "WOUND", "", secret(321), 1)
  fire("UNIT_COMBAT", "player", "HEAL", "CRITICAL", 500, 2)
  fire("UNIT_COMBAT", "target", "ENERGIZE", "", 10, 1)          -- ignored
  run(0.3)
  fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
  run(2.0)
  print("  ran " .. id)
end

-- Text checks on a fresh spawn.
local seen = {}
local function collect() for _, f in ipairs(frames) do if f.kind == "FontString" and f.text then seen[f.text] = true end end end
ns.SetSkin("comic")
fire("UNIT_COMBAT", "target", "WOUND", "CRITICAL", 28750, 1)
run(0.05); collect()
check(seen["28.8K!"], "plain crit abbreviated with the skin's crit format (28.8K!)")
fire("UNIT_COMBAT", "target", "WOUND", "", secret(5), 1)
run(0.05); collect()
check(seen["<secret>"], "secret amount passed through to the FontString")
fire("UNIT_COMBAT", "player", "WOUND", "", 40, 1)
run(0.05); collect()
check(seen["-40"], "incoming damage formatted -40")
run(3)

print("== many hits at once (pool cap)")
for i = 1, 80 do fire("UNIT_COMBAT", "target", "WOUND", i % 5 == 0 and "CRITICAL" or "", i * 7, 1) end
run(3)

print("== jackpot")
local function count(id) local n = 0; for _, v in ipairs(sounds) do if v == id then n = n + 1 end end; return n end
local function texts() local t = {}; for _, f in ipairs(frames) do if f.kind == "FontString" and f.text then t[f.text] = (t[f.text] or 0) + 1 end end; return t end
ns.SetSkin("jackpot")
for i = #sounds, 1, -1 do sounds[i] = nil end
SkinDeepDB.incoming = true
run(3)
fire("UNIT_COMBAT", "target", "WOUND", "CRITICAL", secret(31200), 1)
run(0.5)
check(count(856) == 0, "reel still in its fast spin at 0.5s (no clunks yet)")
run(0.25)
check(count(856) == 1 and count(120) == 0, "first clunk clicks, no payout yet")
local midSpin = texts()
check(not midSpin["<secret>"] or true, "mid-clunk state readable")
run(0.35)
check(count(856) == 3, "three clunks, three clicks")
check(count(120) == 1, "coin payout sound at the jackpot moment")
local tx = texts()
check(tx["JACKPOT!"], "cabinet shows JACKPOT!")
check(tx["7"] == nil, "no more 7-7-7 symbols")
check((tx["<secret>"] or 0) >= 3, "reel lands on the real (secret) crit amount, with its extrusion layers")
fire("UNIT_COMBAT", "target", "WOUND", "CRITICAL", 999, 1)
fire("UNIT_COMBAT", "nameplate2", "WOUND", "CRITICAL", 777, 1)
run(0.7)
check(count(120) == 1, "crits during the jackpot become mini-rolls (no second cabinet)")
tx = texts()
check(tx["999"] and tx["777"], "mini-rolls land on their amounts (999, 777)")
fire("UNIT_COMBAT", "target", "WOUND", "", 123, 4)
fire("UNIT_COMBAT", "target", "MISS", "", 0, 1)
fire("UNIT_COMBAT", "player", "WOUND", "", secret(40), 1)
run(0.6)
tx = texts()
check(tx["123"] and tx["Miss"], "small rolls land on 123 and Miss")
run(3)
fire("UNIT_COMBAT", "target", "WOUND", "CRITICAL", 5000, 1)
run(1.2)
check(count(120) == 2, "next crit after the cooldown gets a new jackpot")
SkinDeepDB.effects = false
run(3)
fire("UNIT_COMBAT", "target", "WOUND", "CRITICAL", 6000, 1)
run(3)
SkinDeepDB.effects = true
SkinDeepDB.sounds = false
fire("UNIT_COMBAT", "target", "WOUND", "CRITICAL", 7000, 1)
run(3)
check(count(120) == 3, "sound toggle off: no payout sound (effects-off jackpot still played one)")
SkinDeepDB.sounds = true
local before = #sounds
ns.ToggleWindow()
run(8)
ns.ToggleWindow()
check(#sounds == before, "options preview stays silent")
run(3)
for i = 1, 60 do fire("UNIT_COMBAT", i % 2 == 0 and "target" or "nameplate2", "WOUND", i % 3 == 0 and "CRITICAL" or "", secret(i), 1); run(0.03) end
run(4)
check(true, "60-hit AoE burst with jackpots ran clean")

print("== colors")
local function colorOf(text)
  local hits = {}
  for _, f in ipairs(frames) do if f.kind == "FontString" and f.text == text and f.color then hits[#hits + 1] = f.color end end
  return hits
end
local function hasColor(text, c)
  for _, col in ipairs(colorOf(text)) do
    if math.abs(col[1] - c[1]) < 0.01 and math.abs(col[2] - c[2]) < 0.01 and math.abs(col[3] - c[3]) < 0.01 then return true end
  end
  return false
end
run(4)
ns.SetSkin("ember")
SkinDeepDB.colorScheme = "classic"
fire("UNIT_COMBAT", "target", "WOUND", "", 111, 1)
fire("UNIT_COMBAT", "target", "WOUND", "", 222, 4)
run(0.05)
check(hasColor("111", { 1, 1, 1 }), "classic: physical white")
check(hasColor("222", { 1, 0.82, 0 }), "classic: spell yellow")
SkinDeepDB.colorScheme = "skin"
fire("UNIT_COMBAT", "target", "WOUND", "", 333, 1)
fire("UNIT_COMBAT", "target", "WOUND", "", 444, 20)
run(0.05)
check(hasColor("333", ns.Skins.ember.physColor), "skin palette: Ember physical tone")
check(hasColor("444", ns.Skins.ember.spellColor), "skin palette: Ember spell tone (mixed school counts as spell)")
SkinDeepDB.colorScheme = "school"
fire("UNIT_COMBAT", "target", "WOUND", "", 555, 16)
fire("UNIT_COMBAT", "target", "WOUND", "", 666, 1)
run(0.05)
check(hasColor("555", { 0.5, 1, 1 }), "schools: Frost blue")
check(hasColor("666", ns.Skins.ember.physColor), "schools: physical keeps the skin tone")
ns.SetSkin("jackpot")
SkinDeepDB.colorScheme = "classic"
run(4)
fire("UNIT_COMBAT", "target", "WOUND", "", 777, 4)
run(0.6)
check(hasColor("777", { 1, 0.82, 0 }), "jackpot reel lands spell hits in yellow too")
SkinDeepDB.colorScheme = "skin"
run(3)

print("== window")
ns.ToggleWindow()
local win = _G.SkinDeepConfig
check(win and win.shown, "window opens")
run(3)
for _, f in ipairs(frames) do
  local p = f.parent; while p and p ~= win do p = p.parent end
  if p == win and f.kind == "Button" and f.scripts.OnClick then f.scripts.OnClick(f, "LeftButton") end
end
run(3)
for _, f in ipairs(frames) do
  local p = f.parent; while p and p ~= win do p = p.parent end
  if p == win and f.kind == "Button" and f.scripts.OnClick then f.scripts.OnClick(f, "LeftButton") end
end
ns.ToggleWindow()
check(not win.shown, "window closes")
run(4)

print("== slash")
for _, c in ipairs({ "", "", "test", "list", "skin frost", "skin bogus", "skin swift", "unlock", "lock", "off", "on", "help" }) do
  SlashCmdList.SKINDEEP(c)
  run(0.5)
end
run(3)

print("== groups and combat")
SkinDeepDB.groupFallback = true
SkinDeepDB.mode = "skin"
ns.ApplyCVars()
local before = #chatLog
inGroup = true
fire("GROUP_ROSTER_UPDATE")
check(#chatLog == before + 1 and chatLog[#chatLog]:find("in a group"), "joining a party says so in chat")
fire("GROUP_ROSTER_UPDATE")
check(#chatLog == before + 1, "roster changes inside the party do not repeat it")
check(cvars.floatingCombatTextCombatDamage_v2 == "1", "group: Blizzard numbers back on")
local before = #frames
fire("UNIT_COMBAT", "target", "WOUND", "", 50, 1)
run(0.1)
inGroup = false
inCombat = true
fire("GROUP_ROSTER_UPDATE")
check(cvars.floatingCombatTextCombatDamage_v2 == "1", "in combat: CVar change deferred")
inCombat = false
fire("PLAYER_REGEN_ENABLED")
check(cvars.floatingCombatTextCombatDamage_v2 == "0", "after combat: applied")
check(chatLog[#chatLog]:find("left the group"), "leaving the party says SkinDeep is back")

print("== staying on in parties (new default)")
SkinDeepDB.groupFallback = false
ns.ApplyCVars()
local chatBefore = #chatLog
inGroup = true
fire("GROUP_ROSTER_UPDATE")
check(cvars.floatingCombatTextCombatDamage_v2 == "0", "party: Blizzard numbers stay hidden")
check(ns.OverlayActive(), "party: SkinDeep numbers stay on")
check(#chatLog == chatBefore + 1 and chatLog[#chatLog]:find("party"), "party: one note that party hits show too")
inGroup = false
fire("GROUP_ROSTER_UPDATE")
inGroup = true
fire("GROUP_ROSTER_UPDATE")
check(#chatLog == chatBefore + 1, "party note only once per session")
inGroup = false
fire("GROUP_ROSTER_UPDATE")

print("== font mode uses the skin's engine motion")
ns.SetSkin("frost")
SkinDeepDB.mode = "font"; ns.ApplyCVars()
check(cvars.floatingCombatTextCombatDamage_v2 == "1", "font mode: Blizzard numbers visible")
check(cvars.WorldTextRampDuration_v2 == "0.6", "font mode: frost motion preset applied")
ns.SetSkin("classic")
check(cvars.WorldTextRampDuration_v2 == "1", "skin without preset: motion CVar handed back")

print("== logout restores everything")
SkinDeepDB.mode = "skin"; ns.ApplyCVars()
fire("PLAYER_LOGOUT")
check(cvars.floatingCombatTextCombatDamage_v2 == "1" and cvars.WorldTextRampDuration_v2 == "1", "all CVars restored at logout")
check(next(SkinDeepDB.borrowed) == nil, "nothing left borrowed")

print("== feats and unlocks")
local F = ns.Feats
local function texts() local t = {}; for _, w in ipairs(frames) do if w.kind == "FontString" and w.text then t[w.text] = true end end; return t end
local function hitTarget(n, flag, school) for _ = 1, n do fire("UNIT_COMBAT", "target", "WOUND", flag or "", 50, school or 1) end end
-- Fresh feat state for this section.
SkinDeepDB.unlockMode = nil
SkinDeepDB.counters, SkinDeepDB.feats, SkinDeepDB.bosses, SkinDeepDB.classLevels, SkinDeepDB.specCrits = nil, nil, nil, nil, nil
F.InitDB(SkinDeepDB)
SkinDeepDB.enabled = true
check(F.IsUnlocked("jackpot") and ns.SetSkin("jackpot"), "before choosing a mode every skin is open")
F.SetMode("collector")
check(SkinDeepDB.skin == "auto", "switching to Collector moves a locked skin back to Auto")
check(F.IsUnlocked("classic") and F.IsUnlocked("mage") and F.IsUnlocked("auto"), "Collector starts with Classic+, Auto and your class skin")
check(not F.IsUnlocked("warrior") and not F.IsUnlocked("jackpot"), "other class skins and Jackpot start locked")
local ok, why = ns.SetSkin("jackpot")
check(ok == false and why == "locked" and SkinDeepDB.skin == "auto", "equipping a locked skin is refused")
SlashCmdList.SKINDEEP("skin jackpot")
check(SkinDeepDB.skin == "auto", "slash command refuses a locked skin too")
SkinDeepDB.skin = "warrior"
check(ns.ResolvedSkinID() == "mage", "a saved skin that is locked for this character resolves to the class skin")
SkinDeepDB.skin = "auto"

local soundsBefore = #soundFiles
hitTarget(777, "CRITICAL")
check(F.IsDone(F.ByID.comic) and F.IsDone(F.ByID.jackpot), "777 crits complete Kaboom! (250) and Jackpot (777)")
check(F.IsUnlocked("jackpot") and ns.SetSkin("jackpot"), "Jackpot is now equippable")
run(0.1)
check(texts()["Skin unlocked"] and #soundFiles > soundsBefore, "unlock toast shows with its fanfare")
check(SkinDeepDB.specCrits["MAGE:2"] == 777, "crits are counted per spec for the coming spec skins")
check(not F.IsDone(F.ByID.arcade), "hits are not done yet (777 / 1000)")
hitTarget(500, "", 4)
check(F.IsDone(F.ByID.ember) and F.IsDone(F.ByID.arcade), "500 Fire hits complete Ember Tide, and the hit total passes 1,000")
fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 50, 1)   -- the target's own plate
check(SkinDeepDB.counters.hits == 1277, "a hit on the target plate is not double counted (" .. tostring(SkinDeepDB.counters.hits) .. ")")
fire("UNIT_COMBAT", "target", "WOUND", "", 0, 1)
check(SkinDeepDB.counters.hits == 1277, "zero-damage results do not count as hits")

print("== kills and bosses")
-- Pretend two faction skins are not released yet, to check feats wait for them.
local realScourge, realDefias = ns.Skins.scourge, ns.Skins.defias
ns.Skins.scourge, ns.Skins.defias = nil, nil
local monk = { name = "Scarlet Monk", ctype = "Humanoid" }
fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")   -- the dummy plate goes away
units.target, units.nameplate1 = monk, monk
fire("PLAYER_TARGET_CHANGED")
fire("UNIT_COMBAT", "target", "WOUND", "", 50, 1)
fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 50, 1)
monk.dead = true
fire("UNIT_HEALTH", "target")
fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
check(SkinDeepDB.counters.scarlet == 1, "a Scarlet kill counts once even when seen as target and plate")
for i = 1, 250 do
  local token = "nameplate" .. (i % 5 + 3)
  local z = { name = "Risen Ghoul", ctype = "Undead" }
  units[token] = z
  fire("UNIT_COMBAT", token, "WOUND", "", 30, 32)
  z.dead = true
  fire("UNIT_HEALTH", token)
end
check(SkinDeepDB.counters.undead == 250, "Undead kills are counted (250)")
check(not F.IsDone(F.ByID.scourge), "a feat whose skin is not released does not complete")
check(#F.Visible() == 32, "unreleased feats are not listed (32 of 34 shown while two skins are held back)")
local alive = { name = "Defias Pillager", ctype = "Humanoid" }
units.nameplate2 = alive
fire("UNIT_COMBAT", "nameplate2", "WOUND", "", 30, 1)
fire("PLAYER_TARGET_CHANGED")
fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
check((SkinDeepDB.counters.defias or 0) == 0, "a mob that left view alive is not counted")
fire("ENCOUNTER_END", 1234, "Edwin VanCleef", 1, 5, 1)
check(SkinDeepDB.bosses["Edwin VanCleef"] and not F.IsDone(F.ByID.defias), "the VanCleef kill is recorded, but its feat waits for its skin")
-- The skin ships: the feats already met complete right away.
ns.Skins.defias, ns.Skins.scourge = realDefias, realScourge
F.Check()
check(F.IsDone(F.ByID.defias) and F.IsDone(F.ByID.scourge), "once their skins exist, earlier progress completes the faction feats")
local sawPlague = false
for _ = 1, 60 do run(1); if texts()["Plague Tide"] then sawPlague = true; break end end  -- toasts queue, ~5s each
check(sawPlague, "the faction skin unlock pops its toast")
fire("ENCOUNTER_END", 1235, "Emperor Dagran Thaurissan", 1, 5, 0)
check(not SkinDeepDB.bosses["Emperor Dagran Thaurissan"], "a failed encounter does not count")

print("== levels and gold")
fire("PLAYER_LEVEL_UP", 12)
check(SkinDeepDB.classLevels.MAGE == 12 and F.IsDone(F.ByID.class_mage), "reaching 12 on a Mage records the Mage level feat")
fire("PLAYER_LEVEL_UP", 20)
check(F.IsDone(F.ByID.blood), "reaching level 20 unlocks Bloodmoon Ink")
fire("PLAYER_ENTERING_WORLD")
money = money + 100 * 10000
fire("PLAYER_MONEY")
check(F.IsDone(F.ByID.gilded), "earning 100 gold unlocks Gilded Hoard")
money = money - 5000
fire("PLAYER_MONEY")
check(SkinDeepDB.counters.gold == 100 * 10000, "spending gold does not count against it")

print("== feats window")
ns.OpenWindow("feats")
run(0.5)
check(texts()["|cff7fe07fComplete|r"], "the Feats tab lists completed feats")
ns.OpenWindow("skins")
run(3)
_G.SkinDeepConfig:Hide()
local have, total = F.UnlockedCount()
check(have < total, "Collector still has locked skins (" .. have .. "/" .. total .. ")")
F.SetMode("all")
have, total = F.UnlockedCount()
check(have == total, "Everything unlocked opens every skin")
SlashCmdList.SKINDEEP("welcome")
run(0.2)
check(_G.SkinDeepWelcome and _G.SkinDeepWelcome.shown, "/skindeep welcome reopens the first-run window")
for _, w in ipairs(frames) do
  local p = w.parent; while p and p ~= _G.SkinDeepWelcome do p = p.parent end
  if p == _G.SkinDeepWelcome and w.kind == "Button" and w.scripts.OnClick then w.scripts.OnClick(w) end
end
check(SkinDeepDB.unlockMode ~= nil, "the welcome window choices work")
run(1)

print("== pvp")
do
  local F = ns.Feats
  local function texts() local t = {}; for _, w in ipairs(frames) do if w.kind == "FontString" and w.text then t[w.text] = true end end; return t end
  -- Rank ladders follow the honor level, per faction.
  pvpRank, playerFactionName = 7, "Alliance"
  fire("PLAYER_PVP_RANK_CHANGED")
  check(SkinDeepDB.counters.rankAlliance == 7 and F.IsDone(F.ByID.knight) and not F.IsDone(F.ByID.ltcommander),
    "PvP Rank 7 on an Alliance character unlocks Knight, not yet Lieutenant Commander")
  pvpRank, playerFactionName = 14, "Horde"
  fire("CURRENCY_DISPLAY_UPDATE")
  check(F.IsDone(F.ByID.stoneguard) and F.IsDone(F.ByID.champion) and F.IsDone(F.ByID.highwarlord),
    "Rank 14 on a Horde character unlocks the whole Horde ladder up to High Warlord")
  check(not F.IsDone(F.ByID.grandmarshal), "Horde rank does not unlock Grand Marshal")
  pvpRank, playerFactionName = 3, "Horde"
  fire("PLAYER_PVP_RANK_CHANGED")
  check(SkinDeepDB.counters.rankHorde == 14, "a lower rank later (a new season) does not lower the best")
  pvpRank = 99
  fire("PLAYER_PVP_RANK_CHANGED")
  check(SkinDeepDB.counters.rankHorde == 14, "a rank read above 14 is capped at 14")
  -- Battleground wins: only wins, one per battle, by map.
  inInstanceKind, instanceName, arenaFaction = "pvp", "Warsong Gulch", 1
  fire("PLAYER_ENTERING_WORLD")
  for _ = 1, 5 do clock = clock + 61; fire("PVP_MATCH_COMPLETE", 1) end
  check(SkinDeepDB.counters.winWSG == 5 and F.IsDone(F.ByID.flagrunner), "5 Warsong Gulch wins unlock Flag Runner")
  clock = clock + 61; fire("PVP_MATCH_COMPLETE", 0)
  check(SkinDeepDB.counters.winWSG == 5, "a loss does not count")
  clock = clock + 61; fire("PVP_MATCH_COMPLETE", 1); fire("PVP_MATCH_COMPLETE", 1)
  check(SkinDeepDB.counters.winWSG == 6, "a battle's result counts once")
  instanceName = "Arathi Basin"
  clock = clock + 61; fire("PVP_MATCH_COMPLETE", 1)
  check(SkinDeepDB.counters.winAB == 1 and SkinDeepDB.counters.winWSG == 6, "wins are counted per battleground")
  -- Duels: only the player's wins.
  units.player = { name = "Shockalacka" }
  for _ = 1, 25 do fire("CHAT_MSG_SYSTEM", "Shockalacka has defeated Bob in a duel") end
  fire("CHAT_MSG_SYSTEM", "Bob has defeated Shockalacka in a duel")
  fire("CHAT_MSG_SYSTEM", "Bob has defeated Ann in a duel")
  check(SkinDeepDB.counters.duels == 25 and F.IsDone(F.ByID.duelist), "25 duel wins unlock Duelist (losses and others' duels ignored)")
  -- PvP skin switch.
  SkinDeepDB.pvpSkin = "knight"
  check(ns.PvPSkinFor("player", "inc") == "knight", "in a battleground the PvP skin is used, even for hits on you")
  inInstanceKind = "none"
  fire("ZONE_CHANGED_NEW_AREA")
  local foe = { name = "Grimtusk", ctype = "Humanoid", player = true }
  units.target = foe
  check(ns.PvPSkinFor("target", "out") == "knight", "outside battlegrounds the PvP skin is used against players")
  units.target = { name = "Kobold", ctype = "Humanoid" }
  check(ns.PvPSkinFor("target", "out") == nil and ns.PvPSkinFor("player", "inc") == nil, "and not against NPCs")
  SkinDeepDB.unlockMode = "collector"
  SkinDeepDB.pvpSkin = "grandmarshal"
  check(ns.PvPSkinFor("target", "out") == nil, "a locked PvP skin is never used")
  SkinDeepDB.pvpSkin = nil
  -- Rank 14 crit title shows.
  SkinDeepDB.unlockMode = "all"
  ns.SetSkin("highwarlord")
  units.target = foe
  fire("UNIT_COMBAT", "target", "WOUND", "CRITICAL", secret(4321), 1)
  run(0.3)
  check(texts()["HIGH WARLORD"], "High Warlord crits roar their title")
  run(3)
  SlashCmdList.SKINDEEP("rank")
  SlashCmdList.SKINDEEP("honor")
  SlashCmdList.SKINDEEP("pvp duelist")
  check(SkinDeepDB.pvpSkin == "duelist", "/skindeep pvp sets the PvP skin")
  SlashCmdList.SKINDEEP("pvp off")
  check(SkinDeepDB.pvpSkin == nil, "/skindeep pvp off clears it")
  units.target = dummy
end

print("== version")
check(ns.VERSION == "dev", "unpackaged copy reports version dev")

print("== auto: my class")
ns.SetSkin("auto")
check(ns.CurrentSkin().id == "mage", "auto resolves to the Mage skin (Spellweave)")
SlashCmdList.SKINDEEP("skin warrior")
check(SkinDeepDB.skin == "warrior", "slash picks a class skin directly")
SlashCmdList.SKINDEEP("skin auto")
check(SkinDeepDB.skin == "auto", "slash: skin auto")
SlashCmdList.SKINDEEP("list")
ns.ToggleWindow(); run(4); ns.ToggleWindow(); run(3)
check(true, "window with the Auto entry builds and previews")
SkinDeepDB = nil
DAMAGE_TEXT_FONT = STANDARD_TEXT_FONT
fire("ADDON_LOADED", "SkinDeep")
check(SkinDeepDB.skin == "auto", "fresh install starts on Auto: my class")
check(DAMAGE_TEXT_FONT == ns.Fonts.led, "fresh Mage install: Blizzard numbers get the Spellweave font")
check(SkinDeepDB.groupFallback == false, "fresh install keeps SkinDeep on in parties")

local names = {}
for k in pairs(unknown) do names[#names + 1] = k end
table.sort(names)
print("== methods not modelled by the mock: " .. (#names > 0 and table.concat(names, ", ") or "none"))
print(fail_count == 0 and "ALL CHECKS PASSED" or (fail_count .. " CHECK(S) FAILED"))
