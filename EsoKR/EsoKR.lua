local LMP = LibMediaProvider
EsoKR = EsoKR or {
  name = "EsoKR",
  firstInit = true,
  chat = { changed = true, privCursorPos = 0, editing = false },
  version = "10.09",
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

-- TODO: isKorean, Unused
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

function EsoKR:con2CNKR(text, encode)
  local temp = ""
  local scanleft = 0
  local result = ""
  local num = 0
  local hashan = false
  local byte
  local hex

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

-- TODO: E, Unused
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

-- TODO: removeIndex, Unused
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
  local styles = { "ZO_TOOLTIP_STYLES", "ZO_CRAFTING_TOOLTIP_STYLES", "ZO_GAMEPAD_DYEING_TOOLTIP_STYLES" }
  local path = EsoKR:getFontPath()
  local function f(x) return path .. x end
  local fontFaces = EsoKR.fontFaces
  for _, v in pairs(styles) do for k, fnt in pairs(fontFaces[v]) do _G[v][k]["fontFace"] = f(fnt) end end

  local fontString = "EsoKR/fonts/ftn47.otf"
  for _, fontStyle in pairs(styles) do
    local fontInformation = _G[fontStyle]
    for key, fontData in pairs(fontInformation) do
      fontData["fontFace"] = fontString
      -- if not fontData["fontSize"] then
      --   fontData["fontSize"] = 18
      -- end
    end
  end

  LMP:Register("font", "KR Futura Book", "$(ESOKR_FUTURA_CONDENSED_BOOK_FONT)")
  LMP:Register("font", "KR Futura Medium", "$(ESOKR_FUTURA_CONDENSED_MEDIUM_FONT)")
  LMP:Register("font", "KR Futura Bold", "$(ESOKR_FUTURA_CONDENSED_BOLD_FONT)")
  LMP:Register("font", "KR ProseAntique", "$(ESOKR_PROSE_ANTIQUE_FONT)")
  LMP:Register("font", "KR Univers Bold", "$(ESOKR_UNIVERS_BOLD_FONT)")
  LMP:Register("font", "KR Univers Medium", "$(ESOKR_UNIVERS_MEDIUM_FONT)")
  LMP:Register("font", "KR Univers Condensed", "$(ESOKR_UNIVERS_CONDENSED_FONT)")

  SetSCTKeyboardFont(f(fontFaces.UNI47) .. "|29|soft-shadow-thick")
  SetSCTGamepadFont(f(fontFaces.UNI47) .. "|35|soft-shadow-thick")
  SetNameplateKeyboardFont(f(fontFaces.UNI47), 4)
  SetNameplateGamepadFont(f(fontFaces.UNI47), 4)

  local function GetFontList()
    local fonts = {}
    for varName, value in zo_insecurePairs(_G) do
      if (type(value) == "userdata" and value.GetFontInfo) then
        fonts[#fonts + 1] = varName
      end
    end
    table.sort(fonts)
    EsoKR.fonts = fonts
    return fonts
  end

  local fontDescriptors = {}
  for fontName, fontObject in pairs(GetFontList()) do
    local gData = _G[fontObject]
    if gData and gData.GetFontInfo then
      local fileName, fontSize, fontEffect = gData:GetFontInfo()

      local index, location = nil, nil
      index, location = string.find(fileName:lower(), "univers67")
      if index then
        fileName = "EsoKR/fonts/univers47.otf"
      end

      local index, location = nil, nil
      index, location = string.find(fileName:lower(), "univers57")
      if index then
        fileName = "EsoKR/fonts/univers57.otf"
      end

      local index, location = nil, nil
      index, location = string.find(fileName:lower(), "proseantique")
      if index then
        fileName = "EsoKR/fonts/proseantiquepsmt.otf"
      end

      local fontDescriptor = fileName:lower() .. "|" .. fontSize
      if fontEffect then
        fontDescriptor = fontDescriptor .. "|" .. fontEffect:lower()
      end

      local index, location = nil, nil
      index, location = string.find(fileName:lower(), "esoui")

      if index then
        gData:SetFont(fontDescriptor)
        fontDescriptors[#fontDescriptors + 1] = fontDescriptor
      end
    end
  end
  EsoKR.fontDescriptors = fontDescriptors
  ZoFontTributeAntique40:SetFont("EsoKR/fonts/proseantiquepsmt.otf|40")
  ZoFontTributeAntique30:SetFont("EsoKR/fonts/proseantiquepsmt.otf|30")
  ZoFontTributeAntique20:SetFont("EsoKR/fonts/proseantiquepsmt.otf|20")
end

local function fontChangeWhenPlayerActivaited()
  local path = EsoKR:getFontPath()
  local function f(x) return path .. x end
  local fontFaces = EsoKR.fontFaces

  SetSCTKeyboardFont(f(fontFaces.UNI47) .. "|29|soft-shadow-thick")
  SetSCTGamepadFont(f(fontFaces.UNI47) .. "|35|soft-shadow-thick")
  SetNameplateKeyboardFont(f(fontFaces.UNI47), 4)
  SetNameplateGamepadFont(f(fontFaces.UNI47), 4)
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

function apply_byte_offset_to_hangul(input_filename)
    -- Note: This Lua function is a simplified demonstration and may not be suitable for all cases
    -- Note: Do not use this. It is for a new BETA update, also it won't work anyway because ESO doesn't allow disk access
    local output_filename = "output.txt"
    local target_start = 0xEAB080 -- Equivalent to U+6E00
    local hangul_start = 0xEAE080 -- Equivalent to U+AC00
    local hangul_end = 0xE12E83 -- Equivalent to U+D7A3
    local offset = 0xE13A80 - 0xEAE080 -- Equivalent for 0xE000 - 0xAC00

    -- local input_file = io.open(input_filename, "r")
    -- local input_text = input_file:read("*a")
    -- input_file:close()

    local converted_text = ""
    for char in input_text:gmatch(utf8.charpattern) do
        local char_code = string.byte(char)
        if char_code >= hangul_start and char_code <= hangul_end then
            local target_code = char_code + offset
            converted_text = converted_text .. utf8.char(target_code)
        else
            converted_text = converted_text .. char
        end
    end

    -- local output_file = io.open(output_filename, "w")
    -- output_file:write(converted_text)
    -- output_file:close()
end

