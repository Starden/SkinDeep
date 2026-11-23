-- Appended to the test harness's mock (tests/harness.lua, up to its first
-- test) by tools/gallery.js: records every visible texture and text of each
-- skin's hit and crit, 20 times a second, for the skin gallery.

local LAYER = { BACKGROUND = 0, BORDER = 1, ARTWORK = 2, OVERLAY = 3, HIGHLIGHT = 4 }
local base = {}
for _, k in ipairs({ "CreateTexture", "CreateFontString", "SetDrawLayer", "SetSize", "SetWidth", "SetHeight",
                     "SetVertexColor", "SetRotation", "SetTexCoord", "SetBlendMode", "SetFont", "SetTextColor", "SetShadowOffset" }) do
  base[k] = Widget[k]
end
function Widget:CreateTexture(name, layer, tmpl, sub)
  local t = base.CreateTexture(self, name, layer, tmpl, sub)
  t.layer, t.sub = LAYER[layer or "ARTWORK"] or 2, sub or 0
  return t
end
function Widget:CreateFontString(name, layer, tmpl)
  local t = base.CreateFontString(self, name, layer, tmpl)
  t.layer, t.sub = LAYER[layer or "ARTWORK"] or 3, 0
  return t
end
function Widget:SetDrawLayer(l, s) base.SetDrawLayer(self, l, s); self.layer = LAYER[l] or self.layer; self.sub = s or 0 end
function Widget:SetSize(w, h) base.SetSize(self, w, h); self.w, self.h = w, h end
function Widget:SetWidth(w) base.SetWidth(self, w); self.w = w end
function Widget:SetHeight(h) base.SetHeight(self, h); self.h = h end
function Widget:SetVertexColor(r, g, b, a) base.SetVertexColor(self, r, g, b, a); self.vc = { r, g, b, a or 1 } end
function Widget:SetRotation(r) base.SetRotation(self, r); self.rot = r end
function Widget:SetTexCoord(l, r, t, b) base.SetTexCoord(self, l, r, t, b); self.tc = { l, r, t, b } end
function Widget:SetBlendMode(m) base.SetBlendMode(self, m); self.blend = m end
function Widget:SetFont(path, size, flags) local ok = base.SetFont(self, path, size, flags); self.fontSize, self.flags = size, flags or ""; return ok end
function Widget:SetTextColor(r, g, b, a) base.SetTextColor(self, r, g, b, a); self.color = { r, g, b, a or 1 } end
function Widget:SetShadowOffset(x, y) base.SetShadowOffset(self, x, y); self.shadow = { x, y } end
-- Clipping frames (a slot reel's window, a cut in two): recorded, so the
-- gallery clips what they hold.
function Widget:SetClipsChildren(v) self.clips = v and true or nil end
-- Real frames start shown (the mock starts them hidden): track explicit hides.
local baseShow, baseHide = Widget.Show, Widget.Hide
function Widget:Show() baseShow(self); self.hidden = false end
function Widget:Hide() baseHide(self); self.hidden = true end

local function isRegion(w) return w.kind == "Texture" or w.kind == "FontString" end
local function effScale(w)
  local s, f = 1, w
  while f do
    if not isRegion(f) then s = s * (f.scale or 1) end
    f = f.parent
  end
  return s
end
local function center(w)
  if w == UIParent or not w then return 0, 0 end
  local pt = w._pt
  if not pt then return center(w.parent) end
  local rel = pt[2] or w.parent
  local rx, ry = center(rel)
  local s = effScale(w)
  return rx + (pt[4] or 0) * s, ry + (pt[5] or 0) * s
end
local function visible(w)
  local a, f = 1, w
  while f do
    if f.hidden or (f.hidden == nil and not f.shown and f ~= UIParent and (f.kind == "Texture" or f.kind == "FontString")) then return 0 end
    a = a * (f.alpha or 1)
    f = f.parent
  end
  return a
end
local function depth(w)
  local d, f = 0, w.parent
  while f do d = d + 1; f = f.parent end
  return d
end

local function r2(v) return math.floor(v * 100 + 0.5) / 100 end
-- The nearest clipping frame around w, as { x, y, w, h }, or 0.
local function clipOf(w)
  local f = w.parent
  while f do
    if f.clips then
      local x, y = center(f)
      local s = effScale(f)
      return { r2(x), r2(y), r2((f.w or 0) * s), r2((f.h or 0) * s) }
    end
    f = f.parent
  end
  return 0
end

local fonts, fontIndex = {}, {}
local texs, texIndex = {}, {}
local function intern(list, index, v)
  if not index[v] then list[#list + 1] = v; index[v] = #list - 1 end
  return index[v]
end
local function snapshot()
  local out = {}
  for _, w in ipairs(frames) do
    if isRegion(w) then
      local a = visible(w)
      if a > 0.004 then
        local x, y = center(w)
        local s = effScale(w)
        local z = depth(w) * 100 + (w.layer or 2) * 10 + (w.sub or 0)
        if w.kind == "Texture" and w.tex and w.w then
          local c = w.vc or { 1, 1, 1 }
          out[#out + 1] = { 0, r2(x), r2(y), r2(w.w * s), r2((w.h or w.w) * s), r2(a), r2(w.rot or 0),
                            r2(c[1]), r2(c[2]), r2(c[3]), intern(texs, texIndex, w.tex), w.blend == "BLEND" and 1 or 0, 0, 0, z,
                            w.tc and { r2(w.tc[1]), r2(w.tc[2]), r2(w.tc[3]), r2(w.tc[4]) } or 0, clipOf(w) }
        elseif w.kind == "FontString" and w.text and w.text ~= "" and w.fontSize then
          local c = w.color or { 1, 1, 1, 1 }
          local flags = (w.flags or ""):find("THICK") and 2 or ((w.flags or ""):find("OUTLINE") and 1 or 0)
          out[#out + 1] = { 1, r2(x), r2(y), 0, 0, r2(a * (c[4] or 1)), 0, r2(c[1]), r2(c[2]), r2(c[3]), w.text,
                            intern(fonts, fontIndex, w.font or ""), r2(w.fontSize * s), flags, z, 0, clipOf(w) }
        end
      end
    end
  end
  table.sort(out, function(p, q) return p[15] < q[15] end)
  return out
end

-- JSON for nested arrays of numbers and strings.
local function json(v)
  local t = type(v)
  if t == "number" then
    if v == math.floor(v) and math.abs(v) < 1e15 then return string.format("%d", v) end
    return tostring(v)
  elseif t == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"'
  elseif t == "table" then
    local parts = {}
    if #v > 0 or next(v) == nil then
      for i = 1, #v do parts[i] = json(v[i]) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    for k, x in pairs(v) do parts[#parts + 1] = json(tostring(k)) .. ":" .. json(x) end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "null"
end

-- Set up an Everything-unlocked player and record each skin.
SkinDeepDB = { unlockMode = "all" }
fire("ADDON_LOADED", "SkinDeep")
fire("PLAYER_LOGIN")
run(4)

local only = CAPTURE_ONLY
local result = { skins = {} }
for _, id in ipairs(ns.SkinOrder) do
  if not only or only[id] then
    local skin = ns.Skins[id]
    local CLASS = { WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
                    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid" }
    local note = skin.spec and (skin.spec .. " " .. (CLASS[skin.class] or ""))
      or (skin.prof and (skin.prof .. " · Artisan")) or skin.listNote
      or (skin.class and CLASS[skin.class]) or (skin.rank and ("%s · Rank %d"):format(skin.faction, skin.rank))
      or skin.faction or ""
    local rec = { id = id, name = skin.name, group = skin.group or "style", tagline = skin.tagline or "", note = note,
                  font = skin.font or "", color = skin.color or { 1, 1, 1 } }
    for _, crit in ipairs({ false, true }) do
      run(3)   -- let everything finish
      math.randomseed(7)
      ns.Engine.Spawn({ kind = "dmg", side = "out", amount = crit and 2391 or 847, crit = crit, school = 1,
                        skin = id, dir = 1 })
      local frames20 = {}
      local dt = 1 / 60
      for i = 1, 150 do
        clock = clock + dt
        for k = #timers, 1, -1 do local t = timers[k]; if t.at <= clock then table.remove(timers, k); t.f() end end
        for _, f in ipairs(frames) do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f, dt) end end
        if i % 3 == 0 then frames20[#frames20 + 1] = snapshot() end
      end
      rec[crit and "crit" or "hit"] = frames20
    end
    result.skins[#result.skins + 1] = rec
  end
end
result.fonts, result.textures = fonts, texs
CAPTURE_JSON = json(result)
