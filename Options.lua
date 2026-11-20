local _, ns = ...

-- The config window (/skindeep), in two tabs:
--   Skins: skin picker with a looping live preview, settings, anchors.
--          In Collector mode locked skins show what earns them and can
--          still be previewed.
--   Feats: unlock mode, popup settings, and every feat with its progress.
-- Built from plain frames and textures so it doesn't lean on templates that
-- differ between clients.

local floor = math.floor
local W, H = 660, 620
local window, previewBox, skinsPage, featsPage
local previewClock = 0
local previewId        -- a locked skin being previewed (not equipped)
local previewTier, previewWho   -- /skindeep peek: their tier and name
local skinButtons, checks, modeButtons, colorButtons, unlockButtons, featRows, tabs = {}, {}, {}, {}, {}, {}, {}
local sizeLabel, speedLabel, nameText, tagText, noteText, unlockButton, countText

local Feats = ns.Feats

-- Skins and feats are shown one group at a time. The Feats tab adds a Specs
-- group (spec variants live inside Classes on the Skins tab).
-- Tab widths fit seven tabs beside the preview stage.
local GROUPS = { { "style", "Styles", 33 }, { "class", "Class", 30 }, { "faction", "Faction", 37 }, { "pvp", "PvP", 24 },
                 { "prof", "Trades", 34 }, { "loot", "Loot", 26 }, { "fun", "Fun", 24 } }
local FEAT_GROUPS = { { "style", "Styles" }, { "class", "Classes" }, { "spec", "Specs" }, { "faction", "Factions" }, { "pvp", "PvP" },
                      { "prof", "Trades" }, { "loot", "Loot" }, { "fun", "Secrets" } }
local CLASS_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local LIST_ROW, LIST_TOP = 24, -70
local listGroup, featGroup = "style", "style"
local expandedClass        -- the class whose spec variants are folded open
local featSpecClass        -- the class shown in the Feats tab's Specs group
local featProfTier = 1     -- the tier shown in the Feats tab's Trades group
local skinGroupTabs, featGroupTabs = {}, {}
local specCycler

local function groupOf(id)
    local skin = ns.Skins[id]
    return (skin and skin.group) or "style"
end

local function myClass()
    local mine = ns.Skins[ns.ClassSkinID() or ""]
    return mine and mine.class or "WARRIOR"
end

-- A small flat tab button.
local function groupTab(parent, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(49, 20)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetPoint("CENTER")
    b.label:SetText(text)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
    function b.SetOn(on)
        b.bg:SetColorTexture(on and 0.45 or 0.14, on and 0.3 or 0.12, on and 0.08 or 0.16, 1)
        b.label:SetTextColor(on and 1 or 0.7, on and 0.85 or 0.68, on and 0.4 or 0.62)
    end
    b:SetScript("OnClick", onClick)
    b.SetOn(false)
    return b
end

local function layoutSkins()
    local y = LIST_TOP
    local function place(b, indent, row)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 14 + indent, y)
        b:Show()
        y = y - row
    end
    for _, b in ipairs(skinButtons) do b:Hide() end
    if listGroup == "class" then
        -- Each class skin, with its spec variants folded open beneath the
        -- expanded class.
        for _, b in ipairs(skinButtons) do
            if b.group == "class" and not b.isVariant then
                place(b, 0, LIST_ROW)
                if b.class == expandedClass then
                    for _, v in ipairs(skinButtons) do
                        if v.isVariant and v.class == b.class then place(v, 14, LIST_ROW - 2) end
                    end
                end
            end
        end
    else
        for _, b in ipairs(skinButtons) do
            if b.group == listGroup then place(b, 0, LIST_ROW) end
        end
    end
    for _, t in ipairs(skinGroupTabs) do t.SetOn(t.group == listGroup) end
end

local function layoutFeats()
    local shown = {}
    for _, r in ipairs(featRows) do
        local on = r.group == featGroup and Feats.Available(r.feat)
            and (featGroup ~= "spec" or r.feat.class == featSpecClass)
            and (featGroup ~= "prof" or r.feat.tier == featProfTier)
        r:SetShown(on)
        if on then shown[#shown + 1] = r end
    end
    if specCycler then
        specCycler:SetShown(featGroup == "spec" or featGroup == "prof")
        if featGroup == "prof" then
            local t = Feats.PROF_TIERS[featProfTier]
            specCycler.label:SetText(("%s (%d)"):format(t[2], t[1]))
        else
            specCycler.label:SetText(Feats.ClassName(featSpecClass or "WARRIOR"))
        end
    end
    local perCol = math.ceil(#shown / 2)
    for i, r in ipairs(shown) do
        local col, row = floor((i - 1) / perCol), (i - 1) % perCol
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 16 + col * (r.colW + 16), -132 - row * 34)
    end
    for _, t in ipairs(featGroupTabs) do t.SetOn(t.group == featGroup) end
end

local function isLocked(id)
    return id ~= ns.AUTO and not Feats.IsUnlocked(id)
end

local function lockLine(id)
    local f = Feats.FeatForSkin(id)
    if not f then return "" end
    return ("|cffffd84aLocked.|r Earn it: %s  |cff999999(%s)|r"):format(Feats.DisplayText(f), Feats.ProgressText(f))
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
local function refreshSkins()
    local db = ns.db
    for _, b in ipairs(skinButtons) do
        local on = b.id == db.skin
        local locked = isLocked(b.id)
        local looking = b.id == previewId
        b.sel:SetShown(on or looking)
        if looking and not on then b.sel:SetColorTexture(0.6, 0.6, 0.6, 1) else b.sel:SetColorTexture(1, 0.7, 0.2, 1) end
        b.bg:SetColorTexture(on and 0.2 or 0.1, on and 0.15 or 0.1, on and 0.1 or 0.12, 0.9)
        b.label:SetAlpha(locked and 0.45 or 1)
        if b.right then
            if locked then
                b.right:SetText("|cff8c8577Locked|r")
            elseif b.id == db.pvpSkin then
                b.right:SetText("|cffffd84aPvP skin|r")
            else
                b.right:SetText(b.rightText or "")
            end
        end
    end
    for _, c in ipairs(checks) do c:Refresh() end
    for _, m in ipairs(modeButtons) do
        if m.mode == db.mode then m:LockHighlight() else m:UnlockHighlight() end
    end
    for _, b in ipairs(colorButtons) do
        if b.scheme == db.colorScheme then b:LockHighlight() else b:UnlockHighlight() end
    end
    local shown = (previewId and ns.Skins[previewId]) or ns.CurrentSkin()
    for _, sw in ipairs(colorButtons.swatches or {}) do
        local c
        if db.colorScheme == "classic" then
            c = sw.physical and ns.CLASSIC_PHYSICAL or ns.CLASSIC_SPELL
        else
            c = sw.physical and (shown.physColor or shown.color) or (shown.spellColor or shown.color)
        end
        sw:SetTextColor(c[1], c[2], c[3])
        if db.colorScheme == "school" and not sw.physical then sw:SetText("Spells by school") else sw:SetText(sw.label) end
    end
    if previewId then
        if previewWho then
            nameText:SetText(("%s's skin: %s"):format(previewWho, ns.Share.Describe(previewId, previewTier) or shown.name))
            tagText:SetText(shown.tagline or "")
        else
            nameText:SetText(shown.name .. "  |cff8c8577(preview)|r")
            tagText:SetText(Feats.TierLine(previewId) or lockLine(previewId))
        end
    else
        nameText:SetText(db.skin == ns.AUTO and ("Auto: " .. shown.name) or shown.name)
        local tier = Feats.TierLine(shown.id)
        tagText:SetText((shown.tagline or "") .. (tier and ("\n" .. tier) or ""))
    end
    sizeLabel:SetFormattedText("Size  %d%%", floor(db.scale * 100 + 0.5))
    speedLabel:SetFormattedText("Speed  %d%%", floor(db.speed * 100 + 0.5))
    unlockButton:SetText(ns.Engine.unlocked and "Lock anchors" or "Unlock anchors")

    local notes = {}
    if not db.enabled then
        notes[#notes + 1] = "|cffff6060SkinDeep is off.|r Tick Enabled to turn it back on."
    elseif db.groupFallback and IsInGroup() and db.mode ~= "font" then
        notes[#notes + 1] = "You're in a group: Blizzard's numbers are showing, since SkinDeep can't tell whose hit it is."
    end
    if db.unlockMode == "collector" then
        local have, total = Feats.UnlockedCount()
        notes[#notes + 1] = ("Collector: %d / %d skins unlocked. The Feats tab shows how to earn the rest."):format(have, total)
    end
    if db.pvpSkin and ns.Skins[db.pvpSkin] then
        notes[#notes + 1] = ("PvP skin: %s, in battlegrounds and against players. Shift-click a skin to change it.")
            :format(ns.Skins[db.pvpSkin].name)
    end
    if ns.WorldFontPending() then
        notes[#notes + 1] = "|cffffd84aBlizzard's numbers get the new font after you log out and back in.|r"
    end
    noteText:SetText(table.concat(notes, "\n"))
end

local function refreshFeats()
    local db = ns.db
    for _, b in ipairs(unlockButtons) do
        if b.mode == db.unlockMode then b:LockHighlight() else b:UnlockHighlight() end
    end
    local have, total = Feats.UnlockedCount()
    local visible = Feats.Visible()
    local done = 0
    for _, f in ipairs(visible) do if Feats.IsDone(f) then done = done + 1 end end
    if db.unlockMode == "collector" then
        countText:SetFormattedText("%d / %d feats complete  ·  %d / %d skins unlocked", done, #visible, have, total)
    elseif db.unlockMode == "all" then
        countText:SetFormattedText("%d / %d feats complete  ·  every skin unlocked", done, #visible)
    else
        countText:SetFormattedText("%d / %d feats complete  ·  choose how skins unlock below", done, #visible)
    end
    for _, row in ipairs(featRows) do
        local f = row.feat
        local isDone = Feats.IsDone(f)
        local cur, goal = Feats.Progress(f)
        if isDone then cur, goal = 1, 1 end
        if f.secret and not isDone then cur = 0 end   -- no hints from the bar
        row.text:SetText(Feats.DisplayText(f))
        row.status:SetText(isDone and "|cff7fe07fComplete|r" or ("|cffaaa59a" .. Feats.ProgressText(f, true) .. "|r"))
        row.fill:SetWidth(math.max(0.01, row.barWidth * (goal > 0 and cur / goal or 0)))
        row.fill:SetColorTexture(isDone and 0.45 or 0.85, isDone and 0.85 or 0.64, isDone and 0.4 or 0.15, 1)
        row.name:SetAlpha(isDone and 1 or 0.75)
    end
    for _, c in ipairs(checks) do c:Refresh() end
end

local function refresh()
    if not window then return end
    refreshSkins()
    refreshFeats()
end

function ns.OnSettingsChanged()
    ns.ApplyCVars()
    refresh()
end

-- Feats completing while the window is open update it.
local prevOnComplete = Feats.OnComplete
Feats.OnComplete = function(...)
    if prevOnComplete then prevOnComplete(...) end
    refresh()
end

local function playPreview()
    if not (window and window:IsShown() and skinsPage:IsShown()) then return end
    previewClock = 0
    ns.Test(previewBox, previewId or ns.db.skin, "TOOLTIP", previewId and previewTier or nil)
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------
local function tooltip(owner, title, text)
    owner:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        GameTooltip:AddLine(text, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    owner:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function checkbox(parent, label, key, help)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(190, 20)
    b.border = b:CreateTexture(nil, "BORDER")
    b.border:SetSize(16, 16)
    b.border:SetPoint("LEFT")
    b.border:SetColorTexture(0.55, 0.45, 0.3, 1)
    b.box = b:CreateTexture(nil, "ARTWORK")
    b.box:SetSize(14, 14)
    b.box:SetPoint("CENTER", b.border)
    b.box:SetColorTexture(0.12, 0.12, 0.15, 1)
    b.check = b:CreateTexture(nil, "OVERLAY")
    b.check:SetSize(8, 8)
    b.check:SetPoint("CENTER", b.border)
    b.check:SetColorTexture(1, 0.72, 0.2, 1)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b.border, "RIGHT", 6, 0)
    b.text:SetText(label)
    function b.Refresh() b.check:SetShown(ns.db[key] and true or false) end
    b:SetScript("OnClick", function()
        ns.db[key] = not ns.db[key]
        ns.OnSettingsChanged()
    end)
    tooltip(b, label, help)
    checks[#checks + 1] = b
    return b
end

local function button(parent, text, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function stepper(parent, key, lo, hi, step)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetWidth(100)
    label:SetJustifyH("CENTER")
    local minus = button(parent, "-", 24, 20, function()
        ns.db[key] = math.max(lo, floor((ns.db[key] - step) * 10 + 0.5) / 10)
        refresh(); playPreview()
    end)
    local plus = button(parent, "+", 24, 20, function()
        ns.db[key] = math.min(hi, floor((ns.db[key] + step) * 10 + 0.5) / 10)
        refresh(); playPreview()
    end)
    label:SetPoint("LEFT", minus, "RIGHT", 2, 0)
    plus:SetPoint("LEFT", label, "RIGHT", 2, 0)
    return minus, label
end

local function selectTab(name)
    skinsPage:SetShown(name == "skins")
    featsPage:SetShown(name == "feats")
    for _, t in ipairs(tabs) do
        if t.tab == name then t:LockHighlight() else t:UnlockHighlight() end
    end
    if name == "skins" then playPreview() else ns.Engine.Clear() end
    refresh()
end

---------------------------------------------------------------------------
-- Skins page
---------------------------------------------------------------------------
local function buildSkins(page)
    -- Skin list, one group at a time (Styles · Classes · Factions · PvP),
    -- each name drawn in its own font and color. "Auto: my class" heads the
    -- styles.
    local ordered = { ns.AUTO }
    for _, id in ipairs(ns.SkinOrder) do ordered[#ordered + 1] = id end
    local x = 14
    for _, g in ipairs(GROUPS) do
        local t = groupTab(page, g[2], function()
            listGroup = g[1]
            layoutSkins()
        end)
        t.group = g[1]
        t:SetSize(g[3], 20)
        t:SetPoint("TOPLEFT", x, -44)
        x = x + g[3] + 1
        skinGroupTabs[#skinGroupTabs + 1] = t
    end
    local mine = ns.Skins[ns.ClassSkinID() or ""]
    -- Plain font in the class color: some class skins' fonts (crystal, dots)
    -- are hard to read at list size.
    local autoEntry = {
        name = "Auto: my class",
        font = ns.Fonts.friz,
        outline = "OUTLINE",
        color = mine and mine.color or { 1, 1, 1 },
        class = mine and mine.class,
        tagline = "Uses the class skin of whichever character you're playing.",
    }
    for _, id in ipairs(ordered) do
        local skin = id == ns.AUTO and autoEntry or ns.Skins[id]
        local b = CreateFrame("Button", nil, page)
        b.id = id
        b.group = groupOf(id)
        b.class = id ~= ns.AUTO and skin.class or nil
        b.isVariant = skin.spec ~= nil
        -- Spec variants sit indented under their class, a touch smaller.
        b:SetSize(b.isVariant and 186 or 200, LIST_ROW - (b.isVariant and 4 or 2))
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.sel = b:CreateTexture(nil, "BORDER")
        b.sel:SetPoint("TOPLEFT")
        b.sel:SetPoint("BOTTOMLEFT")
        b.sel:SetWidth(3)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.06)
        local label = b:CreateFontString(nil, "OVERLAY")
        local fontSize = b.isVariant and 13 or 14
        label:SetFont(skin.font, fontSize, skin.outline or "OUTLINE")
        if not label:GetFont() then label:SetFont(ns.Fonts.friz, fontSize, "OUTLINE") end
        label:SetPoint("LEFT", 12, 0)
        label:SetTextColor(skin.color[1], skin.color[2], skin.color[3])
        label:SetText(skin.name)
        b.label = label
        -- Right side: the class it belongs to, or "Locked".
        b.right = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        b.right:SetPoint("RIGHT", -8, 0)
        b.rightText = skin.spec or skin.prof or skin.listNote or (skin.class and Feats.ClassName(skin.class))
            or (skin.rank and ("%s · R%d"):format(skin.faction, skin.rank)) or skin.faction
        b:SetScript("OnClick", function()
            -- A class skin folds open its spec variants.
            if b.class and not b.isVariant and b.group == "class" and expandedClass ~= b.class then
                expandedClass = b.class
                layoutSkins()
            end
            if IsShiftKeyDown and IsShiftKeyDown() and id ~= ns.AUTO then
                -- Shift-click: the skin used in battlegrounds and against players.
                if isLocked(id) then
                    ns.Print("that skin is locked. Earn it first: " .. Feats.DisplayText(Feats.FeatForSkin(id)) .. ".")
                elseif ns.db.pvpSkin == id then
                    ns.db.pvpSkin = nil
                    ns.Print("PvP skin off: your usual skin shows everywhere.")
                else
                    ns.db.pvpSkin = id
                    ns.Print(("PvP skin: %s, in battlegrounds and against players."):format(skin.name))
                end
                refresh()
                return
            end
            previewTier, previewWho = nil, nil
            if isLocked(id) then
                previewId = id      -- look, but don't equip
            else
                previewId = nil
                ns.SetSkin(id)
            end
            refresh()
            playPreview()
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(skin.name, skin.color[1], skin.color[2], skin.color[3])
            if skin.tagline then GameTooltip:AddLine(skin.tagline, 0.85, 0.85, 0.85, true) end
            if isLocked(id) then
                local f = Feats.FeatForSkin(id)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Locked. Earn it: " .. Feats.DisplayText(f), 1, 0.82, 0.29, true)
                GameTooltip:AddLine(Feats.ProgressText(f), 0.7, 0.7, 0.7)
                GameTooltip:AddLine("Click to preview it.", 0.6, 0.6, 0.6)
            elseif id ~= ns.AUTO then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(ns.db.pvpSkin == id and "Your PvP skin. Shift-click to turn that off."
                    or "Shift-click: use it in battlegrounds and against players.", 0.6, 0.6, 0.6, true)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        skinButtons[#skinButtons + 1] = b
    end

    local x0 = 232

    -- Preview stage.
    local stage = CreateFrame("Frame", nil, page)
    stage:SetPoint("TOPLEFT", x0, -48)
    stage:SetSize(W - x0 - 16, 160)
    local sbg = stage:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints()
    sbg:SetColorTexture(0.11, 0.1, 0.09, 1)
    local floorLine = stage:CreateTexture(nil, "BORDER")
    floorLine:SetPoint("BOTTOMLEFT", 0, 0)
    floorLine:SetPoint("BOTTOMRIGHT", 0, 0)
    floorLine:SetHeight(2)
    floorLine:SetColorTexture(0.55, 0.42, 0.25, 0.6)
    local stageTag = stage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    stageTag:SetPoint("BOTTOMRIGHT", -6, 6)
    stageTag:SetText("live preview")
    previewBox = CreateFrame("Frame", nil, stage)
    previewBox:SetSize(1, 1)
    previewBox:SetPoint("CENTER", stage, "CENTER", 0, -15)

    nameText = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -10)
    tagText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tagText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
    tagText:SetWidth(W - x0 - 16)
    tagText:SetJustifyH("LEFT")

    -- Numbers mode.
    local modeLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -62)
    modeLabel:SetText("Numbers:")
    local modes = {
        { "skin", "Replace Blizzard's", "SkinDeep draws your floating numbers and Blizzard's damage numbers are switched off." },
        { "both", "Both", "SkinDeep's numbers on top of Blizzard's (restyled) ones." },
        { "font", "Restyle Blizzard's", "Only Blizzard's own numbers, with the skin's font and motion. Colors and effects need one of the other modes." },
    }
    local prev
    for _, m in ipairs(modes) do
        local b = button(page, m[2], m[1] == "both" and 70 or 128, 22, function()
            ns.db.mode = m[1]
            ns.OnSettingsChanged()
            playPreview()
        end)
        b.mode = m[1]
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("LEFT", modeLabel, "RIGHT", 8, 0) end
        tooltip(b, m[2], m[3])
        modeButtons[#modeButtons + 1] = b
        prev = b
    end

    -- Colors: physical vs spell damage.
    local colorLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colorLabel:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -92)
    colorLabel:SetText("Colors:")
    local schemes = {
        { "skin", "Skin palette", 100, "Each skin's own physical and spell colors. Physical is always the paler tone, spell the stronger one." },
        { "classic", "Classic", 70, "Blizzard's scheme on every skin: physical damage white, spell damage yellow." },
        { "school", "Spell schools", 100, "Physical in the skin's color; spells in their school's color (Fire orange, Frost blue, Shadow purple, Nature green, Holy pale gold, Arcane pink)." },
    }
    prev = nil
    for _, s in ipairs(schemes) do
        local b = button(page, s[2], s[3], 22, function()
            ns.db.colorScheme = s[1]
            ns.OnSettingsChanged()
            playPreview()
        end)
        b.scheme = s[1]
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("LEFT", colorLabel, "RIGHT", 14, 0) end
        tooltip(b, s[2], s[4])
        colorButtons[#colorButtons + 1] = b
        prev = b
    end
    -- Live legend of the current pair, in the preview's corner.
    local spellSw = stage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    spellSw:SetPoint("TOPRIGHT", stage, "TOPRIGHT", -8, -6)
    spellSw.physical, spellSw.label = false, "Spell"
    local physSw = stage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    physSw:SetPoint("RIGHT", spellSw, "LEFT", -10, 0)
    physSw.physical, physSw.label = true, "Physical"
    colorButtons.swatches = { physSw, spellSw }

    -- Toggles, two columns.
    local toggles = {
        { "enabled", "Enabled", "Master switch. Off hands every setting back to Blizzard." },
        { "nameplates", "Enemy nameplates (AoE)", "Also show numbers over other enemy nameplates, not only your target's." },
        { "incoming", "Damage you take", "Numbers for hits on you, at the incoming anchor (Unlock anchors to move it)." },
        { "incomingHeals", "Heals you receive", "With Damage you take: heals on you too." },
        { "groupFallback", "Blizzard's numbers in groups", "In a group, other players' hits look the same as yours to addons. With this on, Blizzard's numbers (which only show yours) take over while you're grouped." },
        { "effects", "Bursts and particles", "Crit bursts, rings, decor and particles." },
        { "abbreviate", "Abbreviate big numbers", "28.8K instead of 28750." },
        { "worldFont", "Skin font on Blizzard's numbers", "Gives Blizzard's own floating numbers the skin's font. Takes effect at your next login." },
        { "worldMotion", "Skin motion on Blizzard's numbers", "Tunes the engine's number motion (size, gravity, spread) to the skin while Blizzard's numbers are showing." },
        { "sounds", "Skin sounds", "Sound effects for skins that have them: Jackpot's reel clicks and coin payout. The preview stays silent." },
        { "shareSkins", "Share skins with players", "Tells other SkinDeep users which skin you use, and shows theirs: on their tooltip, with /skindeep peek, and on the hits you take in a duel with them." },
    }
    for i, t in ipairs(toggles) do
        local c = checkbox(page, t[2], t[1], t[3])
        local col, row = (i - 1) % 2, floor((i - 1) / 2)
        c:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", col * 210, -124 - row * 24)
    end

    -- Size / speed.
    local sizeMinus
    sizeMinus, sizeLabel = stepper(page, "scale", 0.5, 2.5, 0.1)
    sizeMinus:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -278)
    local speedMinus
    speedMinus, speedLabel = stepper(page, "speed", 0.5, 2.0, 0.1)
    speedMinus:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 210, -278)

    -- Actions.
    local test = button(page, "Test in world", 120, 24, function() ns.Test() end)
    test:SetPoint("BOTTOMLEFT", x0, 48)
    tooltip(test, "Test in world", "Shows sample hits over your target's nameplate (or the no-nameplate anchor).")
    unlockButton = button(page, "Unlock anchors", 120, 24, function()
        ns.Engine.SetUnlocked(not ns.Engine.unlocked)
        refresh()
    end)
    unlockButton:SetPoint("LEFT", test, "RIGHT", 6, 0)
    tooltip(unlockButton, "Anchors", "Drag the orange boxes: where numbers go when the target has no nameplate, and where incoming numbers go.")
    local reset = button(page, "Reset anchors", 110, 24, function() ns.Engine.ResetAnchors(ns.DEFAULTS.anchors) end)
    reset:SetPoint("LEFT", unlockButton, "RIGHT", 6, 0)
    local restore = button(page, "Restore Blizzard", 120, 24, function()
        ns.db.enabled = false
        ns.RestoreCVars()
        ns.OnSettingsChanged()
        ns.Print("off. Blizzard's number settings are restored (the font fully resets at your next login).")
    end)
    restore:SetPoint("LEFT", reset, "RIGHT", 6, 0)
    tooltip(restore, "Restore Blizzard", "Turns SkinDeep off and puts back every number setting it changed. Use this before uninstalling.")

    noteText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteText:SetPoint("BOTTOMLEFT", x0, 10)
    noteText:SetWidth(W - x0 - 16)
    noteText:SetJustifyH("LEFT")
end

---------------------------------------------------------------------------
-- Feats page
---------------------------------------------------------------------------
local function buildFeats(page)
    local head = page:CreateFontString(nil, "OVERLAY")
    head:SetFont(ns.Fonts.friz, 15, "OUTLINE")
    head:SetTextColor(1, 0.82, 0.29)
    head:SetPoint("TOPLEFT", 16, -48)
    head:SetText("Feats")
    countText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countText:SetPoint("LEFT", head, "RIGHT", 12, -1)
    countText:SetTextColor(0.68, 0.65, 0.58)

    -- Unlock mode.
    local modeLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("TOPLEFT", 16, -78)
    modeLabel:SetText("Skins:")
    local modes = {
        { "collector", "Collector", 100, "Start with Classic+, Auto and your class's skin; earn the rest through these feats." },
        { "all", "Everything unlocked", 150, "Every skin is open. Feats still track and pop up for fun." },
    }
    local prev
    for _, m in ipairs(modes) do
        local b = button(page, m[2], m[3], 22, function()
            Feats.SetMode(m[1])
            refresh()
        end)
        b.mode = m[1]
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("LEFT", modeLabel, "RIGHT", 8, 0) end
        tooltip(b, m[2], m[4])
        unlockButtons[#unlockButtons + 1] = b
        prev = b
    end
    local pop = checkbox(page, "Unlock popups", "toasts", "A popup when a feat completes or a skin unlocks.")
    pop:SetPoint("TOPLEFT", 380, -79)
    local fan = checkbox(page, "Popup fanfare", "toastSound", "The popup plays the achievement fanfare.")
    fan:SetPoint("TOPLEFT", 510, -79)

    -- Feat groups, like the skin list, plus Specs.
    local x = 16
    for _, g in ipairs(FEAT_GROUPS) do
        local t = groupTab(page, g[2], function()
            featGroup = g[1]
            layoutFeats()
        end)
        t.group = g[1]
        t:SetPoint("TOPLEFT", x, -106)
        x = x + 51
        featGroupTabs[#featGroupTabs + 1] = t
    end

    -- Specs: ‹ Class › steps through the classes; Trades: through the tiers.
    specCycler = CreateFrame("Frame", nil, page)
    specCycler:SetSize(170, 20)
    specCycler:SetPoint("TOPLEFT", x + 12, -106)
    local function step(dir)
        if featGroup == "prof" then
            featProfTier = (featProfTier - 1 + dir) % #Feats.PROF_TIERS + 1
            layoutFeats()
            return
        end
        local i = 1
        for k, c in ipairs(CLASS_ORDER) do if c == featSpecClass then i = k end end
        featSpecClass = CLASS_ORDER[(i - 1 + dir) % #CLASS_ORDER + 1]
        layoutFeats()
    end
    local prevBtn = groupTab(specCycler, "<", function() step(-1) end)
    prevBtn:SetSize(22, 20)
    prevBtn:SetPoint("LEFT")
    local nextBtn = groupTab(specCycler, ">", function() step(1) end)
    nextBtn:SetSize(22, 20)
    nextBtn:SetPoint("RIGHT")
    specCycler.label = specCycler:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    specCycler.label:SetPoint("CENTER")
    specCycler:Hide()

    -- The feats of the chosen group, two columns (laid out by layoutFeats).
    local COLS, ROWH = 2, 34
    local colW = (W - 32 - 16) / COLS
    for _, f in ipairs(Feats.Visible()) do
        local r = CreateFrame("Frame", nil, page)
        r:SetSize(colW, ROWH - 4)
        r.colW = colW
        r.feat = f
        r.group = f.spec and "spec" or groupOf(f.skin)
        local skin = ns.Skins[f.skin]
        local color = skin.color
        r.name = r:CreateFontString(nil, "OVERLAY")
        r.name:SetFont(skin.font, 13, skin.outline or "OUTLINE")
        if not r.name:GetFont() then r.name:SetFont(ns.Fonts.friz, 13, "OUTLINE") end
        -- One line each, in fixed lanes: name on the left, progress on the
        -- right, requirement below. Nothing wraps or runs into its neighbor.
        local STATUS_W = 96
        r.name:SetPoint("TOPLEFT", 0, 0)
        r.name:SetWidth(colW - STATUS_W - 6)
        r.name:SetJustifyH("LEFT")
        if r.name.SetWordWrap then r.name:SetWordWrap(false) end
        r.name:SetTextColor(color[1], color[2], color[3])
        r.name:SetText(skin.name)
        r.status = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.status:SetPoint("TOPRIGHT", 0, -1)
        r.status:SetWidth(STATUS_W)
        r.status:SetJustifyH("RIGHT")
        if r.status.SetWordWrap then r.status:SetWordWrap(false) end
        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        r.text:SetPoint("TOPLEFT", 0, -16)
        r.text:SetWidth(colW)
        r.text:SetJustifyH("LEFT")
        if r.text.SetWordWrap then r.text:SetWordWrap(false) end
        r.text:SetText(Feats.DisplayText(f))
        r.barWidth = colW
        local track = r:CreateTexture(nil, "BACKGROUND")
        track:SetPoint("BOTTOMLEFT", 0, 0)
        track:SetSize(colW, 3)
        track:SetColorTexture(0.17, 0.15, 0.2, 1)
        r.fill = r:CreateTexture(nil, "ARTWORK")
        r.fill:SetPoint("BOTTOMLEFT", 0, 0)
        r.fill:SetHeight(3)
        featRows[#featRows + 1] = r
    end

    local foot = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    foot:SetPoint("BOTTOMLEFT", 16, 12)
    foot:SetWidth(W - 32)
    foot:SetJustifyH("LEFT")
    foot:SetText("Progress is shared by all your characters. Hits and crits count on your target and enemy nameplates; in a party they include your party's hits on your target, as the numbers do.")
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function build()
    window = CreateFrame("Frame", "SkinDeepConfig", UIParent)
    window:SetSize(W, H)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    tinsert(UISpecialFrames, "SkinDeepConfig")

    local edge = window:CreateTexture(nil, "BACKGROUND", nil, -8)
    edge:SetAllPoints()
    edge:SetColorTexture(0.55, 0.42, 0.25, 1)
    local bg = window:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetColorTexture(0.05, 0.05, 0.07, 0.97)

    local title = window:CreateFontString(nil, "OVERLAY")
    title:SetFont(ns.Fonts.friz, 18, "OUTLINE")
    title:SetPoint("TOPLEFT", 16, -12)
    title:SetText("|cffff8a2eSkin|r|cffffd84aDeep|r")

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- Tabs.
    local prev
    for _, t in ipairs({ { "skins", "Skins" }, { "feats", "Feats" } }) do
        local b = button(window, t[2], 80, 22, function() selectTab(t[1]) end)
        b.tab = t[1]
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("LEFT", title, "RIGHT", 18, 0) end
        tabs[#tabs + 1] = b
        prev = b
    end

    skinsPage = CreateFrame("Frame", nil, window)
    skinsPage:SetAllPoints()
    featsPage = CreateFrame("Frame", nil, window)
    featsPage:SetAllPoints()
    buildSkins(skinsPage)
    buildFeats(featsPage)
    featsPage:Hide()
    -- Open on the group of the skin in use, with your class folded open.
    listGroup = groupOf(ns.db.skin)
    expandedClass = (ns.Skins[ns.db.skin] and ns.Skins[ns.db.skin].class) or myClass()
    featSpecClass = myClass()
    layoutSkins()
    layoutFeats()

    window:SetScript("OnShow", function()
        refresh()
        playPreview()
    end)
    -- Replays the sample hits, giving each skin time to finish its show.
    window:SetScript("OnUpdate", function(_, elapsed)
        previewClock = previewClock + elapsed
        local shown = (previewId and ns.Skins[previewId]) or ns.CurrentSkin()
        if previewClock >= (shown.previewLoop or 2.6) then playPreview() end
    end)
    window:SetScript("OnHide", function()
        previewId, previewTier, previewWho = nil, nil, nil
        if ns.Engine.unlocked then ns.Engine.SetUnlocked(false) end
    end)
    selectTab("skins")
end

function ns.ToggleWindow()
    if not window then build() end
    window:SetShown(not window:IsShown())
end

-- Opens the window (on a tab: "skins" or "feats").
function ns.OpenWindow(tab)
    if not window then build() end
    window:Show()
    selectTab(tab or "skins")
end

-- Plays another player's skin in the preview (at their tier).
function ns.PreviewSkin(id, tier, who)
    ns.OpenWindow("skins")
    previewId, previewTier, previewWho = id, tier, who
    refresh()
    playPreview()
end

function ns.PreviewVisible(frame)
    return frame ~= previewBox or (window and window:IsShown() and skinsPage:IsShown())
end

---------------------------------------------------------------------------
-- Settings panel entry, compartment, slash commands
---------------------------------------------------------------------------
local function registerSettings()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    local panel = CreateFrame("Frame")
    local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText("SkinDeep")
    local d = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    d:SetText("Damage skins for the floating combat numbers. Everything lives in its own window.")
    local open = button(panel, "Open SkinDeep", 160, 26, function()
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        ns.OpenWindow()
    end)
    open:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12)
    pcall(function()
        local category = Settings.RegisterCanvasLayoutCategory(panel, "SkinDeep")
        Settings.RegisterAddOnCategory(category)
    end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", registerSettings)

function SkinDeep_OnCompartmentClick()
    ns.ToggleWindow()
end

local function findSkin(query)
    query = query:lower()
    if query == "" then return nil end
    if query == ns.AUTO or query == "my class" or query == "class" then return ns.AUTO end
    if ns.Skins[query] then return query end
    for _, id in ipairs(ns.SkinOrder) do
        if ns.Skins[id].name:lower():find(query, 1, true) then return id end
    end
end

SLASH_SKINDEEP1 = "/skindeep"
SLASH_SKINDEEP2 = "/dmgskin"
SlashCmdList.SKINDEEP = function(msg)
    local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" then
        ns.ToggleWindow()
    elseif cmd == "test" then
        ns.Test()
    elseif cmd == "feats" then
        ns.OpenWindow("feats")
    elseif cmd == "welcome" then
        ns.ShowWelcome()
    elseif cmd == "talents" or cmd == "spec" then
        -- What SkinDeep reads for the spec skins.
        local trees, cls, source = Feats.TalentReport()
        local names = {}
        for _, id in ipairs(ns.SkinOrder) do
            local sk = ns.Skins[id]
            if sk.spec and sk.class == cls and not sk.form then names[sk.tree] = sk.treeName or sk.spec end
        end
        if not trees then
            ns.Print("couldn't read your talents from the game yet. Open your talent frame once and try again.")
        else
            local parts = {}
            for i = 1, 3 do parts[i] = ("%s %d"):format(names[i] or ("Tree " .. i), trees[i] or 0) end
            ns.Print(("talent points: %s (read from %s). Spec skins unlock at 20 in a tree.")
                :format(table.concat(parts, ", "), source == "traits" and "the talent tree" or "your specs"))
            local sp = ns.db.specPoints
            local best = {}
            for i = 1, 3 do best[i] = ("%d"):format(sp[cls .. ":" .. i] or 0) end
            ns.Print(("best ever on a %s: %s."):format(Feats.ClassName(cls) or cls, table.concat(best, " / ")))
        end
        local variant = ns.SpecVariantID()
        ns.Print(("skin in use: %s."):format(ns.Skins[ns.ResolvedSkinID()].name)
            .. (variant and not Feats.IsUnlocked(variant) and (" (" .. ns.Skins[variant].name .. " once you earn it)") or ""))
    elseif cmd == "peek" then
        -- Another SkinDeep user's skin: /skindeep peek [name] (default: target).
        local name = rest ~= "" and rest or (UnitExists("target") and ns.SafeBool(UnitIsPlayer, "target") and ns.Share.FullName("target"))
        if not name then
            ns.Print("peek: target a player, or type /skindeep peek Name.")
        elseif not ns.db.shareSkins then
            ns.Print("skin sharing is off. Tick Share skins with players to see theirs.")
        else
            local id, tier = ns.Share.SkinOf(name)
            if id then
                ns.PreviewSkin(id, tier, name)
            else
                ns.Share.Ask(name)
                ns.Print(("asked %s for their skin. If they use SkinDeep, peek again in a moment."):format(name))
            end
        end
    elseif cmd == "loot" or cmd == "sets" then
        -- What SkinDeep reads for the loot and set skins.
        local NAMES = { [0] = "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }
        local best = ns.db.counters.lootBest
        ns.Print(("best loot so far: %s."):format(best and NAMES[best] or "nothing tracked yet (loot something)"))
        local any = false
        for name, info in pairs(Feats.WornSets()) do
            any = true
            ns.Print(("wearing %s: %d / %d pieces%s"):format(name, info.have, info.total,
                info.have >= info.total and " (complete)." or "."))
        end
        if not any then ns.Print("no item set pieces equipped.") end
        local worn = {}
        for name in pairs(ns.db.setsWorn) do worn[#worn + 1] = name end
        table.sort(worn)
        if #worn > 0 then ns.Print("complete sets worn so far: " .. table.concat(worn, ", ") .. ".") end
    elseif cmd == "rank" or cmd == "honor" then
        -- What SkinDeep reads for the PvP rank skins, raw values included.
        local rank, info = Feats.PvPRank()
        local faction = Feats.PlayerFaction() or "?"
        local names = Feats.RANK_NAMES[faction]
        local title = rank and (rank == 0 and "Civilian" or (names and names[rank])) or nil
        local c = ns.db.counters
        if rank then
            ns.Print(("PvP rank %d (%s, %s). Best so far: Alliance %d, Horde %d. Rank skins unlock at 3, 7, 10, 13 and 14.")
                :format(rank, title or "?", faction, c.rankAlliance or 0, c.rankHorde or 0))
        else
            ns.Print("couldn't read a PvP rank from the game on this client.")
        end
        if type(info) == "table" then
            ns.Print(("rank currency: %s, quantity %s, max %s, earned %s.")
                :format(tostring(info.name), tostring(info.quantity), tostring(info.maxQuantity), tostring(info.totalEarned)))
        end
        ns.Print(("battlegrounds won: Warsong %d, Arathi %d, Alterac %d. Duels won: %d.")
            :format(c.winWSG or 0, c.winAB or 0, c.winAV or 0, c.duels or 0))
    elseif cmd == "pvp" then
        if rest == "" or rest:lower() == "off" then
            ns.db.pvpSkin = nil
            ns.Print("PvP skin off: your usual skin shows everywhere.")
        else
            local id = findSkin(rest)
            if not id or id == ns.AUTO then
                ns.Print("no skin called '" .. rest .. "'. /skindeep list")
            elseif isLocked(id) then
                ns.Print(("%s is locked. Earn it: %s."):format(ns.Skins[id].name, Feats.DisplayText(Feats.FeatForSkin(id))))
            else
                ns.db.pvpSkin = id
                ns.Print(("PvP skin: %s, in battlegrounds and against players."):format(ns.Skins[id].name))
            end
        end
        refresh()
    elseif cmd == "list" then
        ns.Print(("|cffffd84aauto|r  Auto: my class (%s)%s"):format(ns.Skins[ns.ResolvedSkinID()].name,
            ns.db.skin == ns.AUTO and "  (current)" or ""))
        for _, id in ipairs(ns.SkinOrder) do
            ns.Print(("|cffffd84a%s|r  %s%s%s"):format(id, ns.Skins[id].name, id == ns.db.skin and "  (current)" or "",
                isLocked(id) and "  |cff8c8577(locked)|r" or ""))
        end
    elseif cmd == "skin" then
        local id = findSkin(rest)
        if not id then
            ns.Print("no skin called '" .. rest .. "'. /skindeep list")
        elseif isLocked(id) then
            local f = Feats.FeatForSkin(id)
            ns.Print(("%s is locked. Earn it: %s (%s)."):format(ns.Skins[id].name, Feats.DisplayText(f), Feats.ProgressText(f)))
        else
            ns.SetSkin(id)
            ns.Print("skin: " .. (id == ns.AUTO and ("Auto: my class (" .. ns.CurrentSkin().name .. ")") or ns.Skins[id].name))
            ns.Test()
        end
    elseif cmd == "on" or cmd == "off" then
        ns.db.enabled = cmd == "on"
        ns.OnSettingsChanged()
        ns.Print(cmd == "on" and "on." or "off. Blizzard's number settings are back.")
    elseif cmd == "restore" then
        ns.db.enabled = false
        ns.RestoreCVars()
        ns.OnSettingsChanged()
        ns.Print("off. Blizzard's number settings are restored (the font fully resets at your next login).")
    elseif cmd == "unlock" or cmd == "lock" then
        ns.Engine.SetUnlocked(cmd == "unlock")
        refresh()
    else
        ns.Print("/skindeep [test | feats | list | skin <name> | pvp <name|off> | rank | welcome | on | off | restore | unlock | lock]")
    end
end
