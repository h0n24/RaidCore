------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--
-- EncounterPrototype contains all services useable by encounters itself.
--
------------------------------------------------------------------------------

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local EncounterPrototype = {}

------------------------------------------------------------------------------
-- Locals
------------------------------------------------------------------------------
local function RegisterLocale(tBoss, sLanguage, Locales)
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local sName = "RaidCore_" .. tBoss:GetName()
  local L = GeminiLocale:NewLocale(sName, sLanguage, sLanguage == "enUS", true)
  if L then
    for key, val in next, Locales do
      L[key] = val
    end
  end
end

local function DeepInit (obj, ...)
  if obj == nil then
    obj = {}
  end
  local root = obj
  for i = 1, select('#', ...) do
    local key = select(i, ...)
    if obj[key] == nil then
      obj[key] = {}
    end
    obj = obj[key]
  end
  return root
end

------------------------------------------------------------------------------
-- Encounter Prototype.
------------------------------------------------------------------------------
function EncounterPrototype:RegisterTrigMob(nTrigType, tTrigList)
  assert(type(tTrigList) == "table")
  assert(type(nTrigType) == "number")
  self.nTrigType = nTrigType
  self.EnableMob = tTrigList
end

-- Register a default config for bar manager.
-- @param tConfig Array of Timer Options indexed by the timer's key.
function EncounterPrototype:RegisterDefaultTimerBarConfigs(tConfig)
  assert(type(tConfig) == "table")
  self.tDefaultTimerBarsOptions = tConfig
end

-- Register a default setting which will be saved in user profile file.
-- @param sKey key to save/restore and use a setting.
-- @param bDefaultSetting default setting.
function EncounterPrototype:RegisterDefaultSetting(sKey, bDefaultSetting)
  assert(sKey)
  assert(self.tDefaultSettings[sKey] == nil)
  self.tDefaultSettings[sKey] = bDefaultSetting == nil or bDefaultSetting
end

-- Bind a message and sound settings to a message id to internally check
-- if they should be displayed or sound not played.
-- @param sKey key of the message.
-- @param sMatch Comparism type, "EQUAL", "MATCH", "FIND".
-- @param sMsgSetting Message setting id.
-- @param sSoundSetting Sound setting id.
function EncounterPrototype:RegisterMessageSetting(sKey, sMatch, sMsgSetting, sSoundSetting)
  assert(sKey)
  assert(sMatch == "MATCH" or sMatch == "FIND" or sMatch == "EQUAL")
  --Most of the matches will be EQUAL so use a faster hashtable to look up settings
  if sMatch == "EQUAL" then
    self.tSettingBindsEqual[sKey] = {
      sMsgSetting = sMsgSetting,
      sSoundSetting = sSoundSetting,
    }
  else
    table.insert(self.tSettingBinds, {
        sKey = sKey,
        sMatch = sMatch,
        sMsgSetting = sMsgSetting,
        sSoundSetting = sSoundSetting,
      }
    )
  end
end

function EncounterPrototype:GetSettingsForKey(sKey)
  if self.tSettingBindsEqual[sKey] then
    return self.tSettingBindsEqual[sKey]
  end

  local nCount = #self.tSettingBinds
  for i = 1, nCount do
    local tSettingBind = self.tSettingBinds[i]
    local sMatch = tSettingBind.sMatch
    local sMsgKey = tSettingBind.sKey
    local result = nil

    if sMatch == "EQUAL" then
      result = sMsgKey == sKey or nil
    elseif sMatch == "FIND" then
      result = sKey:find(sMsgKey)
    elseif sMatch == "MATCH" then
      result = sKey:match(sMsgKey)
    end
    if result ~= nil then
      return tSettingBind
    end
  end

  return {}
end

-- Register events to a single unit or a list of units
-- @param sUnitName String or table of Strings of unit names.
-- @param tEventsHandlers Table of Events/Handlers pairs
function EncounterPrototype:RegisterUnitEvents(tUnitNames, tEventsHandlers)
  assert(type(tUnitNames) == "string" or type(tUnitNames) == "table")
  assert(type(tEventsHandlers) == "table")
  if type(tUnitNames) == "string" then
    tUnitNames = {tUnitNames}
  end

  local nSize = #tUnitNames
  for i = 1, nSize do
    local sUnitName = tUnitNames[i]
    for sMethodName, fHandler in next, tEventsHandlers do
      if type(fHandler) == "table" then
        self:RegisterUnitSpellEvents(sUnitName, sMethodName, fHandler)
      else
        self:RegisterUnitEvent(sUnitName, sMethodName, fHandler)
      end
    end
  end
end

-- Register cast events to a single unit or a list of units
-- @param tUnitNames String or table of Strings of unit names.
-- @param primaryKey Parent key of the table OnCastStart or castName/buffId
-- @param tEventsHandlers Table of Events/Handlers pairs
local SPELL_EVENTS = {
  [RaidCore.E.CAST_START] = true,
  [RaidCore.E.CAST_END] = true,
  [RaidCore.E.BUFF_ADD] = true,
  [RaidCore.E.BUFF_UPDATE] = true,
  [RaidCore.E.BUFF_REMOVE] = true,
  [RaidCore.E.DEBUFF_ADD] = true,
  [RaidCore.E.DEBUFF_UPDATE] = true,
  [RaidCore.E.DEBUFF_REMOVE] = true,
  [RaidCore.E.NPC_SAY] = true, -- Not really spells but the format is the same:
  [RaidCore.E.NPC_YELL] = true, -- Bind by name and a second string
  [RaidCore.E.NPC_WHISPER] = true,
}
function EncounterPrototype:RegisterUnitSpellEvents(tUnitNames, primaryKey, tEventHandlers)
  assert(type(tUnitNames) == "string" or type(tUnitNames) == "table")
  assert(type(primaryKey) == "string" or type(primaryKey) == "number")
  assert(type(tEventHandlers) == "table")
  if type(tUnitNames) == "string" then
    tUnitNames = {tUnitNames}
  end
  local nSize = #tUnitNames
  for i = 1, nSize do
    local sUnitName = tUnitNames[i]
    local isEventFirst = SPELL_EVENTS[primaryKey] == true
    for secondaryKey, fHandler in next, tEventHandlers do
      local sMethodName = secondaryKey
      local sCastName = primaryKey
      if isEventFirst then
        sMethodName = primaryKey
        sCastName = secondaryKey
      end
      self:RegisterUnitSpellEvent(sUnitName, sMethodName, sCastName, fHandler)
    end
  end
end

-- Register cast events to a single unit or a list of units
-- @param sUnitName String or table of Strings of unit names.
-- @param sMethodName OnCastStart or OnCastEnd
-- @param sCastName Name of the cast or id of the buff
-- @param fHandler Function to handle the event
function EncounterPrototype:RegisterUnitSpellEvent(sUnitName, sMethodName, spellId, fHandler)
  assert(type(sUnitName) == "string")
  assert(type(sMethodName) == "string")
  assert(type(spellId) == "string" or type(spellId) == "number")
  assert(type(fHandler) == "function")
  sUnitName = self.L[sUnitName]
  if type(spellId) == "string" then
    spellId = self.L[spellId]
  end
  self.tUnitSpellEvents = DeepInit(self.tUnitSpellEvents, sMethodName, sUnitName, spellId)
  table.insert(self.tUnitSpellEvents[sMethodName][sUnitName][spellId], fHandler)
end

-- Register events to a datachron message
-- @param sSearchMessage The message or parts of it
-- @param compareType COMPARE_EQUAL, COMPARE_FIND or COMPARE_MATCH for comparing the sSearchMessage
-- @param fHandler Function to handle the event
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:RegisterDatachronEvent(sSearchMessage, compareType, fHandler)
  assert(type(sSearchMessage) == "string")
  assert(type(fHandler) == "function")
  assert(
    compareType == RaidCore.E.COMPARE_MATCH or
    compareType == RaidCore.E.COMPARE_FIND or
    compareType == RaidCore.E.COMPARE_EQUAL
  )
  sSearchMessage = self.L[sSearchMessage]
  self.tDatachronEvents = DeepInit(self.tDatachronEvents, sSearchMessage)
  table.insert(self.tDatachronEvents[sSearchMessage], {fHandler = fHandler, compareType = compareType })
end

-- Register events to a single unit
-- @param sUnitName Name of the unit
-- @param sMethodName Name of the event
-- @param fHandler Function to handle the event
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:RegisterUnitEvent(sUnitName, sMethodName, fHandler)
  assert(type(sUnitName) == "string")
  assert(type(sMethodName) == "string")
  assert(type(fHandler) == "function")
  sUnitName = self.L[sUnitName]
  self.tUnitEvents = DeepInit(self.tUnitEvents, sMethodName, sUnitName)
  table.insert(self.tUnitEvents[sMethodName][sUnitName], fHandler)
end

-- Add a message to screen.
-- @param sKey Index which will be used to match on AddMsg.
-- @param sEnglishText English text to search in language dictionnary.
-- @param nDuration Timer duration.
-- @param sSound The sound to be played back.
-- @param sColor The color of the message.
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:AddMsg(sKey, sEnglishText, nDuration, sSound, sColor)
  local bPlaySound = sSound and true
  local bShowMessage = sEnglishText and true
  local tSettings = self:GetSettingsForKey(sKey)
  if bPlaySound and type(tSettings.sSoundSetting) == "string" then
    bPlaySound = self:GetSetting(tSettings.sSoundSetting)
  end
  if bShowMessage and type(tSettings.sMsgSetting) == "string" then
    bShowMessage = self:GetSetting(tSettings.sMsgSetting)
  end

  if bShowMessage then
    sSound = bPlaySound == true and sSound
    RaidCore:AddMsg(sKey, self.L[sEnglishText], nDuration, sSound, sColor)
  elseif bPlaySound then
    RaidCore:PlaySound(sSound)
  end
end

-- Create a timer bar.
-- @param sKey Index which will be used to match on AddTimerBar.
-- @param sEnglishText English text to search in language dictionnary.
-- @param nDuration Timer duration.
-- @param bEmphasize Timer count down requested (nil take the default one).
-- @param sColor Color for the timer bar (nil take the default one)..
-- @param fHandler function to call on timeout
-- @param tClass Class used by callback action on timeout
-- @param tData Data forwarded by callback action on timeout
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:AddTimerBar(sKey, sEnglishText, nDuration, bEmphasize, sColor, fHandler, tClass, tData)
  local tOptions = {}
  local sLocalText = self.L[sEnglishText]
  if self.tDefaultTimerBarsOptions[sKey] then
    tOptions = self.tDefaultTimerBarsOptions[sKey]
  end
  if bEmphasize ~= nil then
    tOptions["bEmphasize"] = bEmphasize and true
  end
  if sColor ~= nil then
    assert(type(sColor) == "string")
    tOptions["sColor"] = sColor
  end
  local tCallback = nil
  if type(fHandler) == "function" then
    tCallback = {
      fHandler = fHandler,
      tClass = tClass,
      tData = tData,
    }
  end
  RaidCore:AddTimerBar(sKey, sLocalText, nDuration, tCallback, tOptions)
end

function EncounterPrototype:ExtendTimerBar(sKey, nDurationToAdd)
  RaidCore:ExtendTimerBar(sKey, nDurationToAdd)
end

-- Remove a timer bar if exist.
-- @param sKey Index to remove.
function EncounterPrototype:RemoveTimerBar(sKey)
  RaidCore:RemoveTimerBar(sKey)
end

-- Create a progress bar.
-- @param sKey Index which will be used to match on AddTimerBar.
-- @param sEnglishText English text to search in language dictionnary.
-- @param fHandler function to call to get progress
-- @param tClass Class used by update action on a timer
-- @param fHandler function to call to get progress
-- @param tClass Class used by update action on a timer
-- @param sColor Color of the bar
-- @param nPriority Order index of the bar compared to others 1-99
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:AddProgressBar(sKey, sEnglishText, fHandler, tClass, fHandler2, sColor, nPriority)
  local tOptions = {}
  local sLocalText = self.L[sEnglishText]
  if self.tDefaultTimerBarsOptions[sKey] then
    tOptions = self.tDefaultTimerBarsOptions[sKey]
  end
  tOptions.sColor = sColor or tOptions.sColor
  tOptions.nPriority = nPriority or tOptions.nPriority
  local tUpdate = nil
  if type(fHandler) == "function" then
    tUpdate = {
      fHandler = fHandler,
      tClass = tClass,
    }
  end
  local tCallback = nil
  if type(fHandler2) == "function" then
    tCallback = {
      fHandler = fHandler2,
      tClass = tClass,
    }
  end
  RaidCore:AddProgressBar(sKey, sLocalText, tUpdate, tOptions, tCallback)
end

-- Remove a progress bar if exist.
-- @param sKey Index to remove.
function EncounterPrototype:RemoveProgressBar(sKey)
  RaidCore:RemoveProgressBar(sKey)
end

function EncounterPrototype:PrepareEncounter()
  local tmp = {}
  -- Translate trigger names.
  if self.EnableMob then
    -- Replace english data by local data.
    for _, EnglishKey in next, self.EnableMob do
      table.insert(tmp, self.L[EnglishKey])
    end
  end
  self.EnableMob = tmp
end

function EncounterPrototype:OnEnable()
  -- Copy settings for fast and secure access.
  self.tSettings = {}
  local tSettings = RaidCore.db.profile.Encounters[self:GetName()]
  if tSettings then
    for k,v in next, tSettings do
      self.tSettings[k] = v
    end
  end
  -- TODO: Redefine this part.
  self.tDispelInfo = {}
  if self.SetupOptions then self:SetupOptions() end
  if type(self.OnBossEnable) == "function" then self:OnBossEnable() end
end

function EncounterPrototype:OnDisable()
  if type(self.OnBossDisable) == "function" then self:OnBossDisable() end
  self:CancelAllTimers()
  if type(self.OnWipe) == "function" then self:OnWipe() end
  self.tDispelInfo = nil
end

function EncounterPrototype:RegisterEnglishLocale(Locales)
  RegisterLocale(self, "enUS", Locales)
end

function EncounterPrototype:RegisterGermanLocale(Locales)
  RegisterLocale(self, "deDE", Locales)
end

function EncounterPrototype:RegisterFrenchLocale(Locales)
  RegisterLocale(self, "frFR", Locales)
end

-- Get setting value through the key.
-- @param sKey index in the array.
-- @return the key itself or false.
function EncounterPrototype:GetSetting(sKey)
  if self.tSettings[sKey] == nil then
    Print(("RaidCore warning: In '%s', setting \"%s\" don't exist."):format(self:GetName(), tostring(sKey)))
    self.tSettings[sKey] = false
  end
  return self.tSettings[sKey]
end

function EncounterPrototype:IsPlayerTank()
  local unit = GroupLib.GetGroupMember(1)
  if unit then return unit.bTank end
end

--- Compute the distance between 2 unit.
-- @param tUnitFrom userdata object from carbine.
-- @param tUnitTo userdata object from carbine.
-- @return The distance in meter.
function EncounterPrototype:GetDistanceBetweenUnits(tUnitFrom, tUnitTo)
  -- XXX If unit are unreachable, the distance should be nil.
  local r = 999
  if tUnitFrom and tUnitTo then
    local positionA = tUnitFrom:GetPosition()
    local positionB = tUnitTo:GetPosition()
    if positionA and positionB then
      local vectorA = Vector3.New(positionA)
      local vectorB = Vector3.New(positionB)
      r = (vectorB - vectorA):Length()
    end
  end
  return r
end

function EncounterPrototype:IsSpell2Dispel(nId)
  if self.tDispelInfo[nId] then
    return next(self.tDispelInfo[nId]) ~= nil
  end
  return false
end

function EncounterPrototype:AddSpell2Dispel(nId, nSpellId)
  if not self.tDispelInfo[nId] then
    self.tDispelInfo[nId] = {}
  end
  self.tDispelInfo[nId][nSpellId] = true
  RaidCore:AddPicture(("DISPEL%d"):format(nId), nId, "DispelWord", 30)
end

function EncounterPrototype:RemoveSpell2Dispel(nId, nSpellId)
  if self.tDispelInfo[nId] and self.tDispelInfo[nId][nSpellId] then
    self.tDispelInfo[nId][nSpellId] = nil
  end
  if not self:IsSpell2Dispel(nId) then
    RaidCore:RemovePicture(("DISPEL%d"):format(nId))
  end
end

function EncounterPrototype:SendIndMessage(sReason, tData)
  local msg = {
    action = RaidCore.E.COMM_ENCOUNTER_IND,
    reason = sReason,
    data = tData,
  }
  RaidCore:SendMessage(msg)
end

--- Default trigger function to start an encounter.
-- @param tNames Names of units without break space.
-- @return Any unit registered can start the encounter.
function EncounterPrototype:OnTrig(tNames)
  if not RaidCore.db.profile.bEnableTestEncounters and
  (self.displayName == "HousingTest" or self.displayName == "GalerasTest") then
    return false
  end
  if next(self.EnableMob) == nil then
    return false
  end
  if self.nTrigType == RaidCore.E.TRIGGER_ANY then
    for _, sMobName in next, self.EnableMob do
      if tNames[sMobName] then
        for _, tUnit in next, tNames[sMobName] do
          if tUnit:IsValid() and tUnit:IsInCombat() then
            return true
          end
        end
      end
    end
    return false
  elseif self.nTrigType == RaidCore.E.TRIGGER_ALL then
    for _, sMobName in next, self.EnableMob do
      if not tNames[sMobName] then
        return false
      else
        local bResult = false
        for _, tUnit in next, tNames[sMobName] do
          if tUnit:IsValid() and tUnit:IsInCombat() then
            bResult = true
          end
        end
        if not bResult then
          return false
        end
      end
    end
    return true
  end
  return false
end

-- Create a world marker.
-- @param sKey Index which will be used to match on SetMarker.
-- @param sText Text key to search in language dictionnary.
-- @param tPosition Position of the marker
--
-- Note: If the Text key is not found, the current string will be used like that.
function EncounterPrototype:SetWorldMarker(sKey, sText, tPosition)
  RaidCore:SetWorldMarker(sKey, self.L[sText], tPosition)
end

function EncounterPrototype:DropWorldMarker(sKey)
  RaidCore:DropWorldMarker(sKey)
end

function EncounterPrototype:ResetWorldMarkers()
  RaidCore:ResetWorldMarkers()
end

------------------------------------------------------------------------------
-- RaidCore interaction
------------------------------------------------------------------------------
do
  -- Sub modules are created when lua files are loaded by the WildStar.
  -- Default setting must be done before encounter loading so.
  RaidCore:SetDefaultModulePrototype(EncounterPrototype)
  RaidCore:SetDefaultModuleState(false)
  RaidCore:SetDefaultModulePackages("Gemini:Timer-1.0")
end

--- Registering a new encounter as a sub module of RaidCore.
--@param name Name of the encounter to create
--@param continentId Id list or id number
--@param parentMapId Id list or id number
--@param mapId Id list or id number
function RaidCore:NewEncounter(name, continentId, parentMapId, mapId)
  assert(name and continentId and parentMapId and mapId)
  -- Transform an unique key into a list with 1 entry, if needed.
  local continentIdList = type(continentId) == "table" and continentId or { continentId }
  local parentMapIdList = type(parentMapId) == "table" and parentMapId or { parentMapId }
  local mapIdList = type(mapId) == "table" and mapId or { mapId }

  -- Create the new encounter, and set zone identifiers.
  -- Library already manage unique name.
  local new = self:NewModule(name)
  new.continentIdList = continentIdList
  new.parentMapIdList = parentMapIdList
  new.mapIdList = mapIdList
  new.displayName = name
  new.tDefaultTimerBarsOptions = {}
  -- Register an empty locale table.
  new:RegisterEnglishLocale({})
  -- Retrieve Locale.
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  new.L = GeminiLocale:GetLocale("RaidCore_" .. name)
  -- Create a empty array for settings.
  new.tDefaultSettings = {}
  new.tUnitEvents = {}
  new.tDatachronEvents = {}
  new.tUnitSpellEvents = {}
  new.tSettingBinds = {}
  new.tSettingBindsEqual = {}
  return new
end
