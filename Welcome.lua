local _, ns = ...

-- The first-run window (pick Collector or Everything unlocked) and the
-- toast that pops when a feat completes.

local TEX = "Interface\\AddOns\\SkinDeep\\Media\\Textures\\"
local GOLD = { 1, 0.82, 0.29 }

local function backdrop(f, edge, fill)
    local e = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    e:SetAllPoints()
    e:SetColorTexture(edge[1], edge[2], edge[3], edge[4] or 1)
    local b = f:CreateTexture(nil, "BACKGROUND", nil, -7)
    b:SetPoint("TOPLEFT", 1, -1)
    b:SetPoint("BOTTOMRIGHT", -1, 1)
    b:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
    return e, b
end

---------------------------------------------------------------------------
-- Toasts
---------------------------------------------------------------------------
local toast
local queue = {}
local IN, HOLD, OUT = 0.25, 4.5, 0.6

local function fanfare()
    if not ns.db.toastSound then return end
    -- The achievement fanfare; sound kits as a fallback.
    if PlaySoundFile then
        local ok, willPlay = pcall(PlaySoundFile, "Sound\\Spells\\AchievmentSound1.ogg", "Master")
        if ok and willPlay ~= false then return end
    end
    for _, key in ipairs({ "LFG_REWARDS", "IG_QUEST_LIST_COMPLETE" }) do
        local id = SOUNDKIT and SOUNDKIT[key]
        if id and PlaySound and pcall(PlaySound, id, "Master") then return end
    end
end

local function buildToast()
    toast = CreateFrame("Button", "SkinDeepToast", UIParent)
    toast:SetSize(360, 72)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -150)
    toast:SetFrameStrata("HIGH")
    toast:Hide()
    backdrop(toast, { 0.85, 0.64, 0.15 }, { 0.07, 0.06, 0.09, 0.95 })

    toast.glow = toast:CreateTexture(nil, "ARTWORK")
    toast.glow:SetTexture(TEX .. "burst.tga")
    toast.glow:SetBlendMode("ADD")
    toast.glow:SetSize(64, 64)
    toast.glow:SetPoint("LEFT", 6, 0)
    toast.icon = toast:CreateTexture(nil, "OVERLAY")
    toast.icon:SetTexture(TEX .. "ring.tga")
    toast.icon:SetBlendMode("ADD")
    toast.icon:SetSize(44, 44)
    toast.icon:SetPoint("CENTER", toast.glow)

    toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toast.title:SetPoint("TOPLEFT", 74, -10)
    toast.title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    toast.name = toast:CreateFontString(nil, "OVERLAY")
    toast.name:SetPoint("TOPLEFT", toast.title, "BOTTOMLEFT", 0, -3)
    toast.note = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toast.note:SetPoint("TOPLEFT", toast.name, "BOTTOMLEFT", 0, -3)
    toast.note:SetWidth(272)
    toast.note:SetJustifyH("LEFT")
    toast.note:SetTextColor(0.68, 0.65, 0.58)

    toast:SetScript("OnClick", function(self)
        self.t = HOLD + IN -- fade out now
        if ns.OpenWindow then ns.OpenWindow() end
    end)
    toast:SetScript("OnUpdate", function(self, elapsed)
        self.t = self.t + elapsed
        local t = self.t
        local alpha, dy = 1, 0
        if t < IN then
            alpha, dy = t / IN, 20 * (1 - t / IN)
        elseif t > IN + HOLD then
            alpha = 1 - (t - IN - HOLD) / OUT
        end
        if self.glow.SetRotation then self.glow:SetRotation(t * 0.8) end
        self:SetAlpha(math.max(0, math.min(1, alpha)))
        self:ClearAllPoints()
        self:SetPoint("TOP", UIParent, "TOP", 0, -150 + dy)
        if t >= IN + HOLD + OUT then
            self:Hide()
            ns.NextToast()
        end
    end)
end

function ns.NextToast()
    local item = table.remove(queue, 1)
    if not item then return end
    if not toast then buildToast() end
    local c = item.color or GOLD
    toast.title:SetText(item.title)
    local font = item.skin and item.skin.font or ns.Fonts.friz
    toast.name:SetFont(font, 18, (item.skin and item.skin.outline) or "OUTLINE")
    if not toast.name:GetFont() then toast.name:SetFont(ns.Fonts.friz, 18, "OUTLINE") end
    toast.name:SetTextColor(c[1], c[2], c[3])
    toast.name:SetText(item.name)
    toast.note:SetText(item.note or "")
    toast.glow:SetVertexColor(c[1], c[2], c[3])
    toast.icon:SetVertexColor(c[1], c[2], c[3])
    toast.t = 0
    toast:SetAlpha(0)
    toast:Show()
    fanfare()
end

function ns.ShowToast(title, name, note, skin, color)
    if not (ns.db and ns.db.toasts) then return end
    queue[#queue + 1] = { title = title, name = name, note = note, skin = skin, color = color or (skin and skin.color) }
    if not (toast and toast:IsShown()) then ns.NextToast() end
end

-- Chain onto whatever else listens (the window refreshes itself there).
local prevOnComplete = ns.Feats.OnComplete
ns.Feats.OnComplete = function(f, title, name, note, skin)
    if prevOnComplete then prevOnComplete(f, title, name, note, skin) end
    ns.ShowToast(title, name, note, skin, f.color)
end

---------------------------------------------------------------------------
-- First run: Collector or Everything unlocked
---------------------------------------------------------------------------
local welcome, choice
local cards = {}

local function selectCard(mode)
    choice = mode
    for _, c in ipairs(cards) do
        local on = c.mode == mode
        c.edge:SetColorTexture(on and 1 or 0.3, on and 0.72 or 0.25, on and 0.23 or 0.18, 1)
    end
end

local function card(parent, mode, title, body, foot)
    local c = CreateFrame("Button", nil, parent)
    c.mode = mode
    c:SetSize(258, 150)
    c.edge = backdrop(c, { 0.3, 0.25, 0.18 }, { 0.11, 0.1, 0.14 })
    local hl = c:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.04)
    local t = c:CreateFontString(nil, "OVERLAY")
    t:SetFont(ns.Fonts.friz, 15, "OUTLINE")
    t:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    t:SetPoint("TOPLEFT", 12, -12)
    t:SetText(title)
    local b = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    b:SetWidth(234)
    b:SetJustifyH("LEFT")
    b:SetSpacing(2)
    b:SetText(body)
    local f = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f:SetPoint("BOTTOMLEFT", 12, 10)
    f:SetWidth(234)
    f:SetJustifyH("LEFT")
    f:SetText(foot)
    c:SetScript("OnClick", function() selectCard(mode) end)
    cards[#cards + 1] = c
    return c
end

local function buildWelcome()
    welcome = CreateFrame("Frame", "SkinDeepWelcome", UIParent)
    welcome:SetSize(560, 290)
    welcome:SetPoint("CENTER", 0, 60)
    welcome:SetFrameStrata("DIALOG")
    welcome:SetToplevel(true)
    welcome:SetClampedToScreen(true)
    welcome:SetMovable(true)
    welcome:EnableMouse(true)
    welcome:RegisterForDrag("LeftButton")
    welcome:SetScript("OnDragStart", welcome.StartMoving)
    welcome:SetScript("OnDragStop", welcome.StopMovingOrSizing)
    welcome:Hide()
    tinsert(UISpecialFrames, "SkinDeepWelcome")  -- Escape closes it (same as Not now)
    backdrop(welcome, { 0.55, 0.42, 0.25 }, { 0.05, 0.05, 0.07, 0.97 })

    local title = welcome:CreateFontString(nil, "OVERLAY")
    title:SetFont(ns.Fonts.friz, 20, "OUTLINE")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("Welcome to |cffff8a2eSkin|r|cffffd84aDeep|r")
    local sub = welcome:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetTextColor(0.68, 0.65, 0.58)
    sub:SetText("How do you want your damage skins? You can change this any time in /skindeep.")

    local total = #ns.SkinOrder
    local a = card(welcome, "collector", "Collector",
        "Start with Classic+, Auto: my class and your class's own skin. Earn the rest through SkinDeep feats: "
        .. "land 777 crits for Jackpot, earn gold for Gilded Hoard, level other classes for their skins, and more.",
        "Unlocks are shared by all your characters.")
    a:SetPoint("TOPLEFT", 16, -64)
    local b = card(welcome, "all", "Everything unlocked",
        ("All %d skins are yours right now. Feats still track and pop up for fun."):format(total),
        "Switch to Collector any time: earned feats are kept.")
    b:SetPoint("TOPRIGHT", -16, -64)

    local go = CreateFrame("Button", nil, welcome, "UIPanelButtonTemplate")
    go:SetSize(120, 26)
    go:SetPoint("BOTTOMRIGHT", -16, 16)
    go:SetText("Continue")
    go:SetScript("OnClick", function()
        ns.Feats.SetMode(choice or "collector")
        welcome:Hide()
        if choice == "all" then
            ns.Print("everything's unlocked. Pick a skin in the window, and feats will pop up as you play.")
        else
            ns.Print("Collector mode: earn skins through feats. The Feats tab in /skindeep shows your progress.")
        end
        if ns.OpenWindow then ns.OpenWindow() end
    end)
    local later = CreateFrame("Button", nil, welcome, "UIPanelButtonTemplate")
    later:SetSize(90, 26)
    later:SetPoint("RIGHT", go, "LEFT", -6, 0)
    later:SetText("Not now")
    later:SetScript("OnClick", function()
        welcome:Hide()
        ns.Print("no problem: every skin stays open until you choose. |cffffd84a/skindeep welcome|r brings this back.")
    end)
    local hint = welcome:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 18, 22)
    hint:SetText("Next: pick your skin with a live preview.")
    selectCard("collector")
end

function ns.ShowWelcome()
    if not welcome then buildWelcome() end
    selectCard(ns.db.unlockMode or "collector")
    welcome:Show()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    if ns.db and ns.db.unlockMode == nil then
        C_Timer.After(3, function()
            if ns.db.unlockMode == nil then ns.ShowWelcome() end
        end)
    end
end)
