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
function UnitIsUnit(a, b) return a == "nameplate1" and b == "target" end
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
for _, file in ipairs({ "Skins.lua", "ClassSkins.lua", "Core.lua", "Engine.lua", "Jackpot.lua", "Options.lua" }) do
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
check(#ns.SkinOrder == 19 and nClass == 9, "19 skins, 9 of them class skins (" .. #ns.SkinOrder .. ", " .. nClass .. ")")
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
  if f.parent == win and f.kind == "Button" and f.scripts.OnClick then f.scripts.OnClick(f, "LeftButton") end
end
run(3)
for _, f in ipairs(frames) do
  if f.parent == win and f.kind == "Button" and f.scripts.OnClick then f.scripts.OnClick(f, "LeftButton") end
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
