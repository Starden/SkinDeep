local _, ns = ...

-- The config window (/skindeep): skin picker with a looping live preview,
-- toggles, size/speed, anchors. Built from plain frames and textures so it
-- doesn't lean on templates that differ between clients.

local floor = math.floor
local W, H = 660, 590
local window, previewBox
local previewClock = 0
local skinButtons, checks, modeButtons, colorButtons = {}, {}, {}, {}
local sizeLabel, speedLabel, nameText, tagText, noteText, unlockButton

local function refresh()
    if not window then return end
    local db = ns.db
    for _, b in ipairs(skinButtons) do
        local on = b.id == db.skin
        b.sel:SetShown(on)
        b.bg:SetColorTexture(on and 0.2 or 0.1, on and 0.15 or 0.1, on and 0.1 or 0.12, 0.9)
    end
    for _, c in ipairs(checks) do c:Refresh() end
    for _, m in ipairs(modeButtons) do
        if m.mode == db.mode then m:LockHighlight() else m:UnlockHighlight() end
    end
    for _, b in ipairs(colorButtons) do
        if b.scheme == db.colorScheme then b:LockHighlight() else b:UnlockHighlight() end
    end
    local skinNow = ns.CurrentSkin()
    for _, sw in ipairs(colorButtons.swatches or {}) do
        local c
        if db.colorScheme == "classic" then
            c = sw.physical and ns.CLASSIC_PHYSICAL or ns.CLASSIC_SPELL
        else
            c = sw.physical and (skinNow.physColor or skinNow.color) or (skinNow.spellColor or skinNow.color)
        end
        sw:SetTextColor(c[1], c[2], c[3])
        if db.colorScheme == "school" and not sw.physical then sw:SetText("Spells by school") else sw:SetText(sw.label) end
    end
    local skin = ns.CurrentSkin()
    if db.skin == ns.AUTO then
        nameText:SetText("Auto: " .. skin.name)
    else
        nameText:SetText(skin.name)
    end
    tagText:SetText(skin.tagline or "")
    sizeLabel:SetFormattedText("Size  %d%%", floor(db.scale * 100 + 0.5))
    speedLabel:SetFormattedText("Speed  %d%%", floor(db.speed * 100 + 0.5))
    unlockButton:SetText(ns.Engine.unlocked and "Lock anchors" or "Unlock anchors")

    local notes = {}
    if not db.enabled then
        notes[#notes + 1] = "|cffff6060SkinDeep is off.|r Tick Enabled to turn it back on."
    elseif db.groupFallback and IsInGroup() and db.mode ~= "font" then
        notes[#notes + 1] = "You're in a group: Blizzard's numbers are showing, since SkinDeep can't tell whose hit it is."
    end
    if ns.WorldFontPending() then
        notes[#notes + 1] = "|cffffd84aBlizzard's numbers get the new font after you log out and back in.|r"
    end
    noteText:SetText(table.concat(notes, "\n"))
end

function ns.OnSettingsChanged()
    ns.ApplyCVars()
    refresh()
end

local function playPreview()
    if not (window and window:IsShown()) then return end
    previewClock = 0
    ns.Test(previewBox, ns.db.skin, "TOOLTIP")
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
    title:SetText("|cffff8a2eSkin|r|cffffd84aDeep|r  |cff999999damage skins for floating combat numbers|r")

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- Skin list in two groups (styles, then classes), each name drawn in
    -- its own font and color.
    local ROW = 24
    local y = -40
    local function header(text)
        local h = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        h:SetPoint("TOPLEFT", 16, y - 4)
        h:SetText(text)
        y = y - 20
    end
    local ordered = {}
    for _, id in ipairs(ns.SkinOrder) do
        if ns.Skins[id].group ~= "class" then ordered[#ordered + 1] = id end
    end
    local firstClass = #ordered + 1
    for _, id in ipairs(ns.SkinOrder) do
        if ns.Skins[id].group == "class" then ordered[#ordered + 1] = id end
    end
    -- "Auto: my class" heads the list, drawn in the class skin's look.
    tinsert(ordered, 1, ns.AUTO)
    firstClass = firstClass + 1
    local mine = ns.Skins[ns.ClassSkinID() or ""]
    local autoEntry = {
        name = "Auto: my class",
        font = mine and mine.font or ns.Fonts.friz,
        outline = mine and mine.outline or "OUTLINE",
        color = mine and mine.color or { 1, 1, 1 },
        class = mine and mine.class,
    }
    header("STYLES")
    for i, id in ipairs(ordered) do
        if i == firstClass then y = y - 4; header("CLASSES") end
        local skin = id == ns.AUTO and autoEntry or ns.Skins[id]
        local b = CreateFrame("Button", nil, window)
        b.id = id
        b:SetSize(200, ROW - 2)
        b:SetPoint("TOPLEFT", 14, y)
        y = y - ROW
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.sel = b:CreateTexture(nil, "BORDER")
        b.sel:SetPoint("TOPLEFT")
        b.sel:SetPoint("BOTTOMLEFT")
        b.sel:SetWidth(3)
        b.sel:SetColorTexture(1, 0.7, 0.2, 1)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.06)
        local label = b:CreateFontString(nil, "OVERLAY")
        label:SetFont(skin.font, 14, skin.outline or "OUTLINE")
        if not label:GetFont() then label:SetFont(ns.Fonts.friz, 14, "OUTLINE") end
        label:SetPoint("LEFT", 12, 0)
        label:SetTextColor(skin.color[1], skin.color[2], skin.color[3])
        label:SetText(skin.name)
        if skin.class then
            -- The class it belongs to, small on the right.
            local cls = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            cls:SetPoint("RIGHT", -8, 0)
            local names = LOCALIZED_CLASS_NAMES_MALE
            cls:SetText((names and names[skin.class]) or (skin.class:sub(1, 1) .. skin.class:sub(2):lower()))
        end
        b:SetScript("OnClick", function()
            ns.SetSkin(id)
            playPreview()
        end)
        skinButtons[#skinButtons + 1] = b
    end

    local x0 = 232

    -- Preview stage.
    local stage = CreateFrame("Frame", nil, window)
    stage:SetPoint("TOPLEFT", x0, -44)
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

    nameText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -10)
    tagText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tagText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
    tagText:SetWidth(W - x0 - 16)
    tagText:SetJustifyH("LEFT")

    -- Mode.
    local modeLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -62)
    modeLabel:SetText("Numbers:")
    local modes = {
        { "skin", "Replace Blizzard's", "SkinDeep draws your floating numbers and Blizzard's damage numbers are switched off." },
        { "both", "Both", "SkinDeep's numbers on top of Blizzard's (restyled) ones." },
        { "font", "Restyle Blizzard's", "Only Blizzard's own numbers, with the skin's font and motion. Colors and effects need one of the other modes." },
    }
    local prev
    for _, m in ipairs(modes) do
        local b = button(window, m[2], m[1] == "both" and 70 or 128, 22, function()
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
    local colorLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colorLabel:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -92)
    colorLabel:SetText("Colors:")
    local schemes = {
        { "skin", "Skin palette", 100, "Each skin's own physical and spell colors. Physical is always the paler tone, spell the stronger one." },
        { "classic", "Classic", 70, "Blizzard's scheme on every skin: physical damage white, spell damage yellow." },
        { "school", "Spell schools", 100, "Physical in the skin's color; spells in their school's color (Fire orange, Frost blue, Shadow purple, Nature green, Holy pale gold, Arcane pink)." },
    }
    prev = nil
    for _, s in ipairs(schemes) do
        local b = button(window, s[2], s[3], 22, function()
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
    }
    for i, t in ipairs(toggles) do
        local c = checkbox(window, t[2], t[1], t[3])
        local col, row = (i - 1) % 2, floor((i - 1) / 2)
        c:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", col * 210, -124 - row * 24)
    end

    -- Size / speed.
    local sizeMinus
    sizeMinus, sizeLabel = stepper(window, "scale", 0.5, 2.5, 0.1)
    sizeMinus:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -254)
    local speedMinus
    speedMinus, speedLabel = stepper(window, "speed", 0.5, 2.0, 0.1)
    speedMinus:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 210, -254)

    -- Actions.
    local test = button(window, "Test in world", 120, 24, function() ns.Test() end)
    test:SetPoint("BOTTOMLEFT", x0, 40)
    tooltip(test, "Test in world", "Shows sample hits over your target's nameplate (or the no-nameplate anchor).")
    unlockButton = button(window, "Unlock anchors", 120, 24, function()
        ns.Engine.SetUnlocked(not ns.Engine.unlocked)
        refresh()
    end)
    unlockButton:SetPoint("LEFT", test, "RIGHT", 6, 0)
    tooltip(unlockButton, "Anchors", "Drag the orange boxes: where numbers go when the target has no nameplate, and where incoming numbers go.")
    local reset = button(window, "Reset anchors", 110, 24, function() ns.Engine.ResetAnchors(ns.DEFAULTS.anchors) end)
    reset:SetPoint("LEFT", unlockButton, "RIGHT", 6, 0)
    local restore = button(window, "Restore Blizzard", 120, 24, function()
        ns.db.enabled = false
        ns.RestoreCVars()
        ns.OnSettingsChanged()
        ns.Print("off. Blizzard's number settings are restored (the font fully resets at your next login).")
    end)
    restore:SetPoint("LEFT", reset, "RIGHT", 6, 0)
    tooltip(restore, "Restore Blizzard", "Turns SkinDeep off and puts back every number setting it changed. Use this before uninstalling.")

    noteText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteText:SetPoint("BOTTOMLEFT", x0, 12)
    noteText:SetWidth(W - x0 - 16)
    noteText:SetJustifyH("LEFT")

    window:SetScript("OnShow", function()
        refresh()
        playPreview()
    end)
    -- Replays the sample hits, giving each skin time to finish its show.
    window:SetScript("OnUpdate", function(_, elapsed)
        previewClock = previewClock + elapsed
        if previewClock >= (ns.CurrentSkin().previewLoop or 2.6) then playPreview() end
    end)
    window:SetScript("OnHide", function()
        if ns.Engine.unlocked then ns.Engine.SetUnlocked(false) end
    end)
end

function ns.ToggleWindow()
    if not window then build() end
    window:SetShown(not window:IsShown())
end

function ns.PreviewVisible(frame)
    return frame ~= previewBox or (window and window:IsShown())
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
        if not (window and window:IsShown()) then ns.ToggleWindow() end
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
    elseif cmd == "list" then
        ns.Print(("|cffffd84aauto|r  Auto: my class (%s)%s"):format(ns.Skins[ns.ResolvedSkinID()].name,
            ns.db.skin == ns.AUTO and "  (current)" or ""))
        for _, id in ipairs(ns.SkinOrder) do
            ns.Print(("|cffffd84a%s|r  %s%s"):format(id, ns.Skins[id].name, id == ns.db.skin and "  (current)" or ""))
        end
    elseif cmd == "skin" then
        local id = findSkin(rest)
        if id then
            ns.SetSkin(id)
            ns.Print("skin: " .. (id == ns.AUTO and ("Auto: my class (" .. ns.CurrentSkin().name .. ")") or ns.Skins[id].name))
            ns.Test()
        else
            ns.Print("no skin called '" .. rest .. "'. /skindeep list")
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
        ns.Print("/skindeep [test | list | skin <name> | on | off | restore | unlock | lock]")
    end
end
