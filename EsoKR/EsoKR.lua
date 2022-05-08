local LMP = LibMediaProvider
EsoKR = EsoKR or {
    name = "EsoKR",
    firstInit = true,
    chat = { changed = true, privCursorPos = 0, editing = false },
    version = "10.03",
    langVer = {
        ["stable"] = "kr",
        ["beta"] = "kb",
    },
}
EsoKR.Defaults = {
    Anchor = { BOTTOMRIGHT, BOTTOMRIGHT, 0, 7 },
    ignorePatcher = true,
    lang = "kr",
}
EsoKR.savedVars = EsoKR.Defaults

local flags = { EsoKR.langVer.stable, EsoKR.langVer.beta, "en", }
local korean = { EsoKR.langVer.stable, EsoKR.langVer.beta }
local isNeedToChangeAdditionalFontTable = { EsoKR.langVer.stable, EsoKR.langVer.beta, "en", }

-- 실시간 채팅창 폰트변환
function EsoKR:test()
    for _, v in pairs(CHAT_SYSTEM.control.container.tabPool.m_Active) do
        d(v:GetNamedChild("Text"):GetText())
        d(v.container.currentBuffer) --SetFont
        v.container.currentBuffer:AddMessage("Hello World!", 255, 255, 255, CHAT_CATEGORY_WHISPER_INCOMING)
    end
end

function EsoKR:setLanguage(lang)
    zo_callLater(function()
        SetCVar("language.2", lang)
        EsoKR.savedVars.lang = lang
        ReloadUI()
    end, 500)
end

function EsoKR:getLanguage() return GetCVar("language.2") end

function EsoKR:isKorean()
    local l = self:getLanguage()
    for _, v in pairs(korean) do if l == v then return true end end
    return false
end

function EsoKR:getFontPath()
    for _, x in pairs(isNeedToChangeAdditionalFontTable) do if self:getLanguage() == x then return "EsoKR/Fonts/" end end
    return "EsoUI/Common/Fonts/"
end

function EsoKR:getString(id)
    return self:con2CNKR(GetString(id), true)
end

--[[
local function chsize(char)
    if not char then return 0
    elseif char > 240 then return 4
    elseif char > 225 then return 3
    elseif char > 192 then return 2
    else return 1
    end
end

local function utf8sub(str, startChar, numChars)
    local startIndex = 1
    while startChar > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + chsize(char)
        startChar = startChar - 1
    end

    local currentIndex = startIndex

    while numChars > 0 and currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + chsize(char)
        numChars = numChars -1
    end
    return str:sub(startIndex, currentIndex - 1)
end
]]

function EsoKR:con2CNKR(text, encode)
    local temp = ""
    local scanleft = 0
    local result = ""
    local num = 0
    local hashan = false

    if (text == nil) then text = "" end
    for i in string.gmatch(text, ".") do
        --[[if(num >= 39) and hashan then
            temp = ""
            scanleft = 0
            result = utf8sub(result, 1, 40)
        else]]--
        local r = ""
        byte = string.byte(i)
        hex = string.format('%02X', byte)
        if scanleft > 0 then
            temp = temp .. hex
            scanleft = scanleft - 1
            if scanleft == 0 then
                temp = tonumber(temp, 16)
                if temp >= 0xE18480 and temp <= 0xE187BF then temp = temp + 0x43400
                elseif temp > 0xE384B0 and temp <= 0xE384BF then temp = temp + 0x237D0
                elseif temp > 0xE38580 and temp <= 0xE3868F then temp = temp + 0x23710
                elseif temp >= 0xEAB080 and temp <= 0xED9EAC then
                    if temp >= 0xEAB880 and temp <= 0xEABFBF then temp = temp - 0x33800
                    elseif temp >= 0xEBB880 and temp <= 0xEBBFBF then temp = temp - 0x33800
                    elseif temp >= 0xECB880 and temp <= 0xECBFBF then temp = temp - 0x33800
                    else temp = temp - 0x3F800
                    end
                elseif not encode and temp >= 0xE6B880 and temp <= 0xE9A6A3 then temp = temp + 0x3F800
                end
                temp = string.format('%02X', temp)
                r = (temp:gsub('..', function(cc) return string.char(tonumber(cc, 16)) end))
                temp = ""
                hashan = true
                num = num + 1
            end
        else
            if byte > 0xE0 and byte <= 0xEF then
                -- 3 bytes
                scanleft = 2
                temp = hex
            else
                r = i
                num = num + 1
            end
        end
        result = result .. r
        --end
    end
    return result
end

function EsoKR:E(t)
    local type = type(t)

    if type == "number" then return t
    elseif type == "string" then return self:con2CNKR(t, true)
    elseif type == "table" then
        for i, v in pairs(t) do t[i] = self:E(v) end
        return t
    else
        d(type)
        return t
    end
end
function EsoKR:removeIndex(text) return text:gsub("[%w][%w%d_%-,'()]+[_%-]+%d[_%-]%d+[_%-]?", "") end

local function utfstrlen(str, targetlen)
    local len = #str
    local left = len
    local cnt = 0
    local arr = { 0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
    while left ~= 0 do
        local tmp = string.byte(str, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function EsoKR:SaveAnchor()
    local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = EsoKRUI:GetAnchor()
    if isValidAnchor then
        EsoKR.savedVars.Anchor = { point, relativePoint, offsetX, offsetY }
    end
end

local function RefreshUI()
    local flagControl
    local count = 0
    local flagTexture
    for _, flagCode in pairs(flags) do
        flagTexture = "EsoKR/flags/" .. flagCode .. ".dds"
        flagControl = GetControl("EsoKR_FlagControl_" .. tostring(flagCode))
        if flagControl == nil then
            flagControl = CreateControlFromVirtual("EsoKR_FlagControl_", EsoKRUI, "EsoKR_FlagControl",
                tostring(flagCode))
            GetControl("EsoKR_FlagControl_" .. flagCode .. "Texture"):SetTexture(flagTexture)
            if EsoKR:getLanguage() ~= flagCode then
                flagControl:SetAlpha(0.3)
                if flagControl:GetHandler("OnMouseDown") == nil then
                    flagControl:SetHandler("OnMouseDown", function() EsoKR:setLanguage(flagCode) end)
                end
            end
        end
        flagControl:ClearAnchors()
        flagControl:SetAnchor(LEFT, EsoKRUI, LEFT, 14 + count * 34, 0)
        count = count + 1
    end
    EsoKRUI:SetDimensions(25 + count * 34, 50)
    EsoKRUI:SetMouseEnabled(true)
end

function EsoKR:fontChangeWhenInit()
    local path = EsoKR:getFontPath()
    local pair = { "ZO_TOOLTIP_STYLES", "ZO_CRAFTING_TOOLTIP_STYLES", "ZO_GAMEPAD_DYEING_TOOLTIP_STYLES" }
    local function f(x) return path .. x end
    local fontFaces = EsoKR.fontFaces

    for _, v in pairs(pair) do for k, fnt in pairs(fontFaces[v]) do _G[v][k]["fontFace"] = f(fnt) end end

    SetSCTKeyboardFont(f(fontFaces.UNI67) .. "|29|soft-shadow-thick")
    SetSCTGamepadFont(f(fontFaces.UNI67) .. "|35|soft-shadow-thick")
    SetNameplateKeyboardFont(f(fontFaces.UNI67), 4)
    SetNameplateGamepadFont(f(fontFaces.UNI67), 4)

    -- this is set up by EsoKR in fontFaces.lua
    -- ["Univers 55"] = UNI55,
    -- ["Univers 57"] = UNI57,
    -- ["Univers 67"] = UNI67,
    -- ["Skyrim Handwritten"] = HAND,
    -- ["ProseAntique"] = ANTIQUE,
    -- ["Trajan Pro"] = TRAJAN,
    -- ["Futura Condensed"] = FTN57,
    -- ["Futura Condensed Bold"] = FTN87,
    -- ["Futura Condensed Light"] = FTN47,
    for k, v in pairs(fontFaces.fonts) do
        LMP.MediaTable.font[k] = nil
        LMP:Register("font", k, f(v))
    end
    LMP:SetDefault("font", "Univers 57")

    -- Loop through list and make sure it is using ESORK Font
    local uni57 = f(fontFaces.UNI57)
    local uni47 = f(fontFaces.FTN47)
    local fontList = {
        "Arial Narrow",
        "Consolas",
        "ESO Cartographer",
        "Fontin Bold",
        "Fontin Italic",
        "Fontin Regular",
        "Fontin SmallCaps",
        "Futura Condensed",
    }
    for i = 1, #fontList do
        LMP.MediaTable.font[fontList[i]] = nil
        LMP:Register("font", fontList[i], uni57)
    end

    -- do single because it is different
    if LMP:Fetch("font", "Futura Light") ~= uni47 then
        LMP.MediaTable.font["Futura Light"] = nil
        LMP:Register("font", "Futura Light", uni47)
    end

    if LWF3 then
        LWF3.data.Fonts = {
            ["Arial Narrow"] = uni57,
            ["Consolas"] = uni57,
            ["ESO Cartographer"] = uni57,
            ["Fontin Bold"] = uni57,
            ["Fontin Italic"] = uni57,
            ["Fontin Regular"] = uni57,
            ["Fontin SmallCaps"] = uni57,
            ["Futura Condensed"] = uni57,
            ["Futura Light"] = path .. fontFaces.FTN47,
        }
        for k, v in pairs(fontFaces.fonts) do LWF3.data.Fonts[k] = f(v) end
    end

    if LWF4 then
        LWF4.data.Fonts = {
            ["Arial Narrow"] = uni57,
            ["Consolas"] = uni57,
            ["ESO Cartographer"] = uni57,
            ["Fontin Bold"] = uni57,
            ["Fontin Italic"] = uni57,
            ["Fontin Regular"] = uni57,
            ["Fontin SmallCaps"] = uni57,
            ["Futura Condensed"] = uni57,
            ["Futura Light"] = path .. fontFaces.FTN47,
        }
        for k, v in pairs(fontFaces.fonts) do LWF4.data.Fonts[k] = f(v) end
    end

    function ZO_TooltipStyledObject:GetFontString(...)
        local fontFace = self:GetProperty("fontFace", ...)
        local fontSize = self:GetProperty("fontSize", ...)

        if fontFace == "$(GAMEPAD_LIGHT_FONT)" then fontFace = f(fontFaces.FTN47) end
        if fontFace == "$(GAMEPAD_MEDIUM_FONT)" then fontFace = f(fontFaces.FTN57) end
        if fontFace == "$(GAMEPAD_BOLD_FONT)" then fontFace = f(fontFaces.FTN87) end

        if (fontFace and fontSize) then
            if type(fontSize) == "number" then
                fontSize = tostring(fontSize)
            end

            local fontStyle = self:GetProperty("fontStyle", ...)
            if (fontStyle) then
                return string.format("%s|%s|%s", fontFace, fontSize, fontStyle)
            else
                return string.format("%s|%s", fontFace, fontSize)
            end
        else
            return "ZoFontGame"
        end
    end
end

local function fontChangeWhenPlayerActivaited()
    local path = EsoKR:getFontPath()
    local function f(x) return path .. x end
    local fontFaces = EsoKR.fontFaces

    SetSCTKeyboardFont(f(fontFaces.UNI67) .. "|29|soft-shadow-thick")
    SetSCTGamepadFont(f(fontFaces.UNI67) .. "|35|soft-shadow-thick")
    SetNameplateKeyboardFont(f(fontFaces.UNI67), 4)
    SetNameplateGamepadFont(f(fontFaces.UNI67), 4)

end

local function EsoKRInit()
    for _, flagCode in pairs(flags) do
        ZO_CreateStringId("SI_BINDING_NAME_" .. string.upper(flagCode), string.upper(flagCode))
    end

    EsoKR:fontChangeWhenInit()
    RefreshUI()

    EsoKRUI:ClearAnchors()
    EsoKRUI:SetAnchor(EsoKR.savedVars.Anchor[1], GuiRoot, EsoKR.savedVars.Anchor[2], EsoKR.savedVars.Anchor[3], EsoKR.savedVars.Anchor[4])

    function ZO_GameMenu_OnShow(control)
        if control.OnShow then
            control.OnShow(control.gameMenu)
            EsoKRUI:SetHidden(hidden)
        end
    end

    function ZO_GameMenu_OnHide(control)
        if control.OnHide then
            control.OnHide(control.gameMenu)
            EsoKRUI:SetHidden(not hidden)
        end
    end

    ZO_PreHook("ZO_ChatTextEntry_Execute", function(control) control.system:CloseTextEntry(true) end)
    ZO_PreHook("ZO_ChatTextEntry_Escape", function(control) control.system:CloseTextEntry(true) end)
    ZO_PreHook("ZO_ChatTextEntry_TextChanged", function(control, newText) EsoKR:Convert(control.system.textEntry) end)
    ZO_PreHook("ZO_EditDefaultText_OnTextChanged", function(edit) EsoKR:Convert(edit) end)
end

function EsoKR:Convert(edit)
    if self.chat.editing then return end
    local cursorPos = edit:GetCursorPosition()
    if cursorPos ~= self.chat.privCursorPos and cursorPos ~= 0 then
        self.chat.editing = true
        local text = self:con2CNKR(edit:GetText(), true)
        edit:SetText(text)
        if (cursorPos < utfstrlen(text)) then edit:SetCursorPosition(cursorPos) end
        self.chat.editing = false
    end
    self.chat.privCursorPos = cursorPos
end

local function loadscreen(eventCode)
    fontChangeWhenPlayerActivaited()

    if EsoKR.firstInit then
        EsoKR.firstInit = false
        for _, v in pairs(isNeedToChangeAdditionalFontTable) do
            if EsoKR:getLanguage() ~= v and EsoKR.savedVars.lang == v then EsoKR:setLanguage(v) end
        end
    end

    zo_callLater(function() CALLBACK_MANAGER:FireCallbacks("loadscreen") end, 1000)
end

function EsoKR:closeMessageBox()
    ZO_Dialogs_ReleaseDialog("EsoKR:MessageBox", false)
end

function EsoKR:showMessageBox(title, msg, btnText, callback)
    local confirmDialog = {
        title = { text = title },
        mainText = { text = msg },
        buttons = { { text = btnText, callback = callback } }
    }

    ZO_Dialogs_RegisterCustomDialog("EsoKR:MessageBox", confirmDialog)
    self:closeMessageBox()
    ZO_Dialogs_ShowDialog("EsoKR:MessageBox")
end

function EsoKR:newInit()
    EsoKR.savedVars = ZO_SavedVars:NewAccountWide("EsoKR_Variables", 1, nil, { lang = EsoKR.langVer.stable })
    if EsoKR.savedVars.Anchor == nil then EsoKR.savedVars.Anchor = { BOTTOMRIGHT, BOTTOMRIGHT, 0, 7 } end

    if EsoKR:getLanguage() ~= "en" then
        SetCVar("IgnorePatcherLanguageSetting", 1)
        if GetCVar("IgnorePatcherLanguageSetting") == "1" then EsoKR.savedVars["ignorePatcher"] = true end
    else
        SetCVar("IgnorePatcherLanguageSetting", 0)
    end
end

local function LoadscreenLoaded()
    if EsoKR.savedVars["addonVer"] ~= EsoKR.version then
        EsoKR:showMessageBox(EsoKR:getString(EsoKR_NOTICE_TITLE), EsoKR:getString(EsoKR_NOTICE_BODY), SI_DIALOG_CONFIRM)
        EsoKR.savedVars["addonVer"] = EsoKR.version
    end
end

local function onAddonLoaded(eventCode, addonName)
    if (addonName ~= EsoKR.name) then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(EsoKR.name, EVENT_ADD_ON_LOADED)

    EsoKR:newInit()
    EsoKRInit()
end

EVENT_MANAGER:RegisterForEvent(EsoKR.name, EVENT_ADD_ON_LOADED, onAddonLoaded)
EVENT_MANAGER:RegisterForEvent("EsoKR_LoadScreen", EVENT_PLAYER_ACTIVATED, loadscreen)
CALLBACK_MANAGER:RegisterCallback("loadscreen", LoadscreenLoaded)
