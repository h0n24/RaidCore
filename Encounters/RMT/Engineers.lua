----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- TODO
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Engineers", 104, {548, 0}, {552, 548})
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, {
    "unit.warrior", "unit.engineer",
    "unit.fusion_core",
    "unit.cooling_turbine",
    "unit.spark_plug",
    "unit.lubricant_nozzle"
  }
)
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.fusion_core"] = "Fusion Core",
    ["unit.cooling_turbine"] = "Cooling Turbine",
    ["unit.spark_plug"] = "Spark Plug",
    ["unit.lubricant_nozzle"] = "Lubricant Nozzle",
    ["unit.engineer"] = "Head Engineer Orvulgh", -- Engineer
    ["unit.warrior"] = "Chief Engineer Wilbargh", -- Warrior
    ["unit.fire_orb"] = "Discharged Plasma", -- Fire Orb
    -- Cast names.
    ["cast.warrior.liquidate"] = "Liquidate",
    ["cast.engineer.electroshock"] = "Electroshock",
    ["cast.rocket_jump"] = "Rocket Jump",
    -- Messages.
    ["msg.warrior.liquidate.next"] = "Next Liquidate in",
    ["msg.warrior.liquidate.stack"] = "Stack",
    ["msg.engineer.electroshock.next"] = "Next Electroshock in",
    ["msg.engineer.electroshock.swap.other"] = "%s SWAP TO WARRIOR",
    ["msg.engineer.electroshock.swap.you"] = "YOU SWAP TO WARRIOR",
    ["msg.engineer.electroshock.swap.return"] = "SWAP TO ENGINEER",
    ["msg.fire_orb.next"] = "Next Fire Orb in",
    ["msg.fire_orb.you"] = "FIRE ORB ON YOU",
    ["msg.fire_orb.spawned"] = "Fire Orb",
    ["msg.fire_orb.pop.timer"] = "Fire Orb is safe to pop in",
    ["msg.fire_orb.pop.msg"] = "Pop the Orb",
    ["msg.core.health.high.warning"] = "%s HIGH HEALTH!",
    ["msg.core.health.low.warning"] = "%s LOW HEALTH!",
    ["msg.rocket_jump.moved"] = "%s MOVED",
    ["msg.heat.generation"] = "Core Health",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.fire_orb"] = "Plasmaentladung",
    -- Public Event Names.
    ["pub.fusion_core"] = "Fusionskern",
    ["pub.cooling_turbine"] = "Kühlturbine",
    ["pub.spark_plug"] = "Zündkerze",
    ["pub.lubricant_nozzle"] = "Schmiermitteldüse",
    -- Datachrons.
    ["chron.elektroshock"] = "([^%s]+%s[^%s]+) leidet unter „Electroshock“",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.fire_orb"] = "Plasma déchargé",
    -- Public Event Names.
    ["pub.fusion_core"] = "Noyau de fusion",
    ["pub.cooling_turbine"] = "Turbine de refroidissement",
    ["pub.spark_plug"] = "Bougie d'allumage",
    ["pub.lubricant_nozzle"] = "Embout de lubrification",
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_ELECTROSHOCK_VULNERABILITY = 83798
local DEBUFF_ATOMIC_ATTRACTION = 84053
local DEBUFF_ION_CLASH = 84051
local BUFF_INSULATION = 83987

-- Timers
local FIRST_ELECTROSHOCK_TIMER = 11
local ELECTROSHOCK_TIMER = 18
local JUMP_ELECTROSHOCK_TIMER = 12
local FIRST_FIRE_ORB_TIMER = 21
local NEXT_FIRE_ORB_TIMER = 24
local FIRE_ORB_SAFE_TIMER = 18

local FIRST_LIQUIDATE_TIMER = 12
local LIQUIDATE_TIMER = 22

local CORE_HEALTH_LOW_PERCENTAGE = 15
local CORE_HEALTH_LOW_WARN_PERCENTAGE = 20
local CORE_HEALTH_LOW_WARN_PERCENTAGE_REENABLE = 23
local CORE_HEALTH_HIGH_WARN_PERCENTAGE = 85
local CORE_HEALTH_HIGH_WARN_PERCENTAGE_REENABLE = 82

local FUSION_CORE = 1
local COOLING_TURBINE = 2
local SPARK_PLUG = 3
local LUBRICANT_NOZZLE = 4
local CORE_NAMES = {
  ["unit.fusion_core"] = FUSION_CORE,
  ["unit.cooling_turbine"] = COOLING_TURBINE,
  ["unit.spark_plug"] = SPARK_PLUG,
  ["unit.lubricant_nozzle"] = LUBRICANT_NOZZLE
}
local CORE_BAR_COLORS = {
  [FUSION_CORE] = "xkcdDarkRed",
  [COOLING_TURBINE] = "xkcdSkyBlue",
  [SPARK_PLUG] = "xkcdLightYellow",
  [LUBRICANT_NOZZLE] = "xkcdLightPurple",
}

local WARRIOR = 1
local ENGINEER = 2
local ENGINEER_NICK_NAMES = {
  [WARRIOR] = "unit.warrior",
  [ENGINEER] = "unit.engineer"
}
local ENGINEER_NAMES = {
  ["unit.warrior"] = WARRIOR,
  ["unit.engineer"] = ENGINEER,
}
local ENGINEER_START_LOCATION = {
  [WARRIOR] = SPARK_PLUG,
  [ENGINEER] = COOLING_TURBINE,
}
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local next, GetUnitById = next, GameLib.GetUnitById
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local coreUnits
local engineerUnits
local player
local coreMaxHealth

local fireOrbTargetTestTimer = ApolloTimer.Create(1, false, "RegisterOrbTarget", mod)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("BarsCoreHealth", false)
mod:RegisterDefaultSetting("MarkerCoreHealth")
mod:RegisterDefaultSetting("MarkerDebuff")
mod:RegisterDefaultSetting("LineElectroshock")
mod:RegisterDefaultSetting("VisualIonClashCircle")
-- Sounds.
mod:RegisterDefaultSetting("SoundBossMove", false)
mod:RegisterDefaultSetting("SoundLiquidate")
mod:RegisterDefaultSetting("SoundElectroshock")
mod:RegisterDefaultSetting("SoundElectroshockSwap")
mod:RegisterDefaultSetting("SoundElectroshockSwapYou")
mod:RegisterDefaultSetting("SoundElectroshockSwapReturn")
mod:RegisterDefaultSetting("SoundFireOrb")
mod:RegisterDefaultSetting("SoundFireOrbAlt")
mod:RegisterDefaultSetting("SoundFireOrbPop")
mod:RegisterDefaultSetting("SoundCoreHealthWarning")
-- Messages.
mod:RegisterDefaultSetting("MessageBossMove", false)
mod:RegisterDefaultSetting("MessageElectroshockSwap")
mod:RegisterDefaultSetting("MessageElectroshockSwapYou")
mod:RegisterDefaultSetting("MessageElectroshockSwapReturn")
mod:RegisterDefaultSetting("MessageLiquidate")
mod:RegisterDefaultSetting("MessageElectroshock")
mod:RegisterDefaultSetting("MessageFireOrb")
mod:RegisterDefaultSetting("MessageFireOrbAlt")
mod:RegisterDefaultSetting("MessageFireOrbPop")
mod:RegisterDefaultSetting("MessageCoreHealthWarning")
-- Binds.
mod:RegisterMessageSetting("BOSS_MOVED_PLATFORM", core.E.COMPARE_EQUAL, "MessageBossMove", "SoundBossMove")
mod:RegisterMessageSetting("ELECTROSHOCK_MSG_OVER", core.E.COMPARE_EQUAL, "MessageElectroshockSwapReturn", "SoundElectroshockSwapReturn")
mod:RegisterMessageSetting("ELECTROSHOCK_MSG_YOU", core.E.COMPARE_EQUAL, "MessageElectroshockSwapYou", "SoundElectroshockSwapYou")
mod:RegisterMessageSetting("ELECTROSHOCK_MSG_OTHER", core.E.COMPARE_FIND, "MessageElectroshockSwap", "SoundElectroshockSwap")
mod:RegisterMessageSetting("ELECTROSHOCK_CAST_MSG", core.E.COMPARE_EQUAL, "MessageElectroshock", "SoundElectroshock")
mod:RegisterMessageSetting("LIQUIDATE_MSG", core.E.COMPARE_EQUAL, "MessageLiquidate", "SoundLiquidate")
mod:RegisterMessageSetting("DISCHARGED_PLASMA_MSG", core.E.COMPARE_EQUAL, "MessageFireOrb", "SoundFireOrb")
mod:RegisterMessageSetting("DISCHARGED_PLASMA_MSG_SPAWN", core.E.COMPARE_EQUAL, "MessageFireOrbAlt", "SoundFireOrbAlt")
mod:RegisterMessageSetting("FIRE_ORB_POP_MSG", core.E.COMPARE_EQUAL, "MessageFireOrbPop", "SoundFireOrbPop")
mod:RegisterMessageSetting("CORE_HEALTH_%s+_WARN", core.E.COMPARE_MATCH, "MessageCoreHealthWarning", "SoundCoreHealthWarning")
-- Timer default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_ELEKTROSHOCK_TIMER"] = { sColor = "xkcdGreen" },
    ["NEXT_LIQUIDATE_TIMER"] = { sColor = "xkcdOrange" },
    ["NEXT_FIRE_ORB_TIMER"] = { sColor = "xkcdLightRed" },
  }
)
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  player = {}
  player.unit = GameLib.GetPlayerUnit()
  player.location = 0
  coreMaxHealth = 0
  engineerUnits = {}
  coreUnits = {}
  --locales
  for name, id in pairs(CORE_NAMES) do
    CORE_NAMES[self.L[name]] = id
  end
  for name, id in pairs(ENGINEER_NAMES) do
    ENGINEER_NAMES[self.L[name]] = id
  end

  if mod:GetSetting("BarsCoreHealth") then
    core:AddUnitSpacer("CORE_SPACER", nil, 2)
  end

  mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "msg.engineer.electroshock.next", FIRST_ELECTROSHOCK_TIMER)
  mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", "msg.warrior.liquidate.next", FIRST_LIQUIDATE_TIMER)
  mod:AddProgressBar("HEAT_GENERATIOn", "msg.heat.generation", mod.GetCoreTotalHealthPercentage, mod)
end

function mod:GetCoreTotalHealthPercentage(oldValue)
  if not coreMaxHealth then
    return oldValue
  end
  local coreCurrentHealth = 0
  local totalHealthPercent
  local barColor = "xkcdRed"
  for coreId, coreUnit in pairs(coreUnits) do
    coreCurrentHealth = coreCurrentHealth + coreUnit.unit:GetHealth()
  end
  totalHealthPercent = (coreCurrentHealth / coreMaxHealth) * 100
  if totalHealthPercent < 28.5 then
    barColor = "xkcdGreen"
  elseif totalHealthPercent < 30 then
    barColor = "xkcdOrange"
  end
  return totalHealthPercent, barColor
end

function mod:GetUnitPlatform(unit)
  local shortestDistance = 100000
  local currentDistance
  local location = 0
  for coreId, coreUnit in next, coreUnits do
    currentDistance = mod:GetDistanceBetweenUnits(unit, coreUnit.unit)
    if shortestDistance > currentDistance then
      shortestDistance = currentDistance
      location = coreId
    end
  end
  return location
end

function mod:OnEngiChangeLocation(engineerId, _, newLocation)
  if ENGINEER_NICK_NAMES[engineerId] ~= nil then
    local msg = self.L["msg.rocket_jump.moved"]:format(self.L[ENGINEER_NICK_NAMES[engineerId]])
    mod:AddMsg("BOSS_MOVED_PLATFORM", msg, 5, "Alarm", "xkcdWhite")
  end
  if newLocation == FUSION_CORE then
    mod:RemoveTimerBar("NEXT_FIRE_ORB_TIMER")
    mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", "msg.fire_orb.next", FIRST_FIRE_ORB_TIMER)
  end
end

function mod:UpdateCoreHealthMark(coreUnit)
  if not mod:GetSetting("MarkerCoreHealth") then
    return
  end
  local percent = coreUnit.percent
  local color = "White"
  if percent <= CORE_HEALTH_LOW_PERCENTAGE or percent >= CORE_HEALTH_HIGH_WARN_PERCENTAGE then
    color = "Red"
  elseif percent <= CORE_HEALTH_LOW_WARN_PERCENTAGE or percent >= CORE_HEALTH_HIGH_WARN_PERCENTAGE_REENABLE then
    color = "Yellow"
  end
  if not coreUnit.enabled then
    color = "DarkGray"
  end

  core:MarkUnit(coreUnit.unit, 0, percent, color)
end

mod:RegisterUnitEvents(core.E.ALL_UNITS, {
    [core.E.UNIT_DESTROYED] = function (self, id)
      core:DropMark(id)
    end,
    [DEBUFF_ELECTROSHOCK_VULNERABILITY] = {
      [core.E.DEBUFF_ADD] = function(self, id, spellId, stack, timeRemaining, targetName)
        local targetUnit
        if id == player.unit:GetId() then
          targetUnit = player.unit
          mod:AddMsg("ELECTROSHOCK_MSG_YOU", "msg.engineer.electroshock.swap.you", 5, "Burn", "Red")
        else
          targetUnit = GetUnitById(id)
          local messageId = string.format("ELECTROSHOCK_MSG_OTHER_%s", targetName)
          local electroshockOnX = self.L["msg.engineer.electroshock.swap.other"]:format(targetName)
          mod:AddMsg(messageId, electroshockOnX, 5, "Info", "xkcdBlue")
        end
        if mod:GetSetting("MarkerDebuff") then
          core:MarkUnit(targetUnit, core.E.LOCATION_STATIC_CHEST, "E", "xkcdOrange")
        end
      end,
      [core.E.DEBUFF_REMOVE] = function(self, id, spellId, targetName)
        if id == player.unit:GetId() then
          mod:AddMsg("ELECTROSHOCK_MSG_OVER", "msg.engineer.electroshock.swap.return", 5, "Burn", "xkcdGreen")
        end
        core:DropMark(id)
      end,
    },
    [DEBUFF_ION_CLASH] = {
      [core.E.DEBUFF_ADD] = function(_, id)
        if mod:GetSetting("VisualIonClashCircle") then
          core:AddPolygon("ION_CLASH", id, 9, 0, 10, "xkcdBlue", 64)
        end
      end,
      [core.E.DEBUFF_REMOVE] = function()
        core:RemovePolygon("ION_CLASH")
      end,
    },
    [core.E.DEBUFF_ADD] = {
      [DEBUFF_ATOMIC_ATTRACTION] = function(self, id, spellId, stack, timeRemaining, targetName)
        if id == player.unit:GetId() then
          mod:AddMsg("DISCHARGED_PLASMA_MSG", "msg.fire_orb.you", 5, "RunAway", "xkcdLightRed")
        elseif mod:IsPlayerOnPlatform(FUSION_CORE) then
          mod:AddMsg("DISCHARGED_PLASMA_MSG_SPAWN", "msg.fire_orb.spawned", 2, "Info", "xkcdWhite")
        end
      end,
    },
  }
)

function mod:IsPlayerOnPlatform(coreId)
  player.location = mod:GetUnitPlatform(player.unit)
  return player.location == coreId
end

function mod:OnEngineerCreated(id, unit, name)
  local engineerId = ENGINEER_NAMES[name]
  engineerUnits[engineerId] = {
    unit = unit,
    location = ENGINEER_START_LOCATION[engineerId],
  }
  core:WatchUnit(unit, core.E.TRACK_CASTS)
  mod:AddUnit(unit, nil, 1)
end

function mod:OnCoreCreated(id, unit, name)
  coreUnits[CORE_NAMES[name]] = {
    unit = unit,
    healthWarning = false,
    enabled = false,
    percent = 30,
  }
  coreMaxHealth = coreMaxHealth + unit:GetMaxHealth()
  core:WatchUnit(unit, core.E.TRACK_BUFFS + core.E.TRACK_HEALTH)
  mod:UpdateCoreHealthMark(coreUnits[CORE_NAMES[name]])
  if mod:GetSetting("BarsCoreHealth") then
    mod:AddUnit(unit, CORE_BAR_COLORS[CORE_NAMES[name]], 3)
  end
end

function mod:OnEngineerDestroyed(id, unit, name)
  engineerUnits[ENGINEER_NAMES[name]] = nil
end

mod:RegisterUnitEvents({"unit.engineer", "unit.warrior"}, {
    [core.E.UNIT_CREATED] = mod.OnEngineerCreated,
    [core.E.UNIT_DESTROYED] = mod.OnEngineerDestroyed,
  }
)

-- Cores
mod:RegisterUnitEvents({
    "unit.fusion_core",
    "unit.cooling_turbine",
    "unit.spark_plug",
    "unit.lubricant_nozzle"
    },{
    [core.E.UNIT_CREATED] = mod.OnCoreCreated,
    [core.E.HEALTH_CHANGED] = function(self, _, percent, name)
      local coreId = CORE_NAMES[name]
      local coreUnit = coreUnits[coreId]
      coreUnit.percent = percent
      mod:UpdateCoreHealthMark(coreUnit)

      if percent > CORE_HEALTH_LOW_WARN_PERCENTAGE_REENABLE and percent < CORE_HEALTH_HIGH_WARN_PERCENTAGE_REENABLE then
        coreUnit.healthWarning = false
      elseif percent >= CORE_HEALTH_HIGH_WARN_PERCENTAGE and not coreUnit.healthWarning then
        coreUnit.healthWarning = true
        mod:AddMsg("CORE_HEALTH_HIGH_WARN", self.L["msg.core.health.high.warning"]:format(name), 5, "Info", "xkcdRed")
      elseif percent <= CORE_HEALTH_LOW_WARN_PERCENTAGE and not coreUnit.healthWarning and mod:IsPlayerOnPlatform(coreId) then
        coreUnit.healthWarning = true
        mod:AddMsg("CORE_HEALTH_LOW_WARN", self.L["msg.core.health.low.warning"]:format(name), 5, "Inferno", "xkcdRed")
      end
    end,
    [BUFF_INSULATION] = {
      [core.E.BUFF_ADD] = function(_, id, spellId, stack, timeRemaining, name)
        local coreUnit = coreUnits[CORE_NAMES[name]]
        coreUnit.enabled = false
        mod:UpdateCoreHealthMark(coreUnit)
      end,
      [core.E.BUFF_REMOVE] = function(_, id, spellId, name)
        local coreUnit = coreUnits[CORE_NAMES[name]]
        coreUnit.enabled = true
        mod:UpdateCoreHealthMark(coreUnit)
        for engineerId, engineer in pairs(engineerUnits) do
          local oldLocation = engineerUnits[engineerId].location
          local newLocation = mod:GetUnitPlatform(engineer.unit)
          if newLocation ~= oldLocation then
            engineerUnits[engineerId].location = newLocation
            mod:OnEngiChangeLocation(engineerId, oldLocation, newLocation)
          end
        end
      end
    },
  }
)

-- Warrior
mod:RegisterUnitEvents("unit.warrior",{
    [core.E.CAST_START] = {
      ["cast.warrior.liquidate"] = function(self)
        if mod:IsPlayerOnPlatform(engineerUnits[WARRIOR].location) then
          mod:AddMsg("LIQUIDATE_MSG", "msg.warrior.liquidate.stack", 5, "Info", "xkcdOrange")
        end
      end,
      ["cast.rocket_jump"] = function()
        mod:ExtendTimerBar("NEXT_LIQUIDATE_TIMER", 4)
      end
    },
    [core.E.CAST_END] = {
      ["cast.warrior.liquidate"] = function(self)
        mod:RemoveTimerBar("NEXT_LIQUIDATE_TIMER")
        mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", "msg.warrior.liquidate.next", LIQUIDATE_TIMER)
      end
    },
  }
)

-- Engineer
mod:RegisterUnitEvents("unit.engineer",{
    [core.E.CAST_START] = {
      ["cast.engineer.electroshock"] = function(self)
        if mod:GetSetting("LineElectroshock") then
          core:AddPixie("ELECTROSHOCK_PIXIE", 2, engineerUnits[ENGINEER].unit, nil, "Red", 10, 80, 0)
        end
        if mod:IsPlayerOnPlatform(engineerUnits[ENGINEER].location) then
          mod:AddMsg("ELECTROSHOCK_CAST_MSG", "cast.engineer.electroshock", 5, "Beware", "xkcdOrange")
        end
      end
    },
    [core.E.CAST_END] = {
      ["cast.rocket_jump"] = function(self)
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "msg.engineer.electroshock.next", JUMP_ELECTROSHOCK_TIMER)
      end,
      ["cast.engineer.electroshock"] = function()
        if mod:GetSetting("LineElectroshock") then
          core:DropPixie("ELECTROSHOCK_PIXIE")
        end
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "msg.engineer.electroshock.next", ELECTROSHOCK_TIMER)
      end
    },
  }
)

function mod:PopFireOrb()
  if mod:IsPlayerOnPlatform(FUSION_CORE) then
    mod:AddMsg("FIRE_ORB_POP_MSG", "msg.fire_orb.pop.msg", 5, "Alarm", "xkcdGreen")
  end
end

mod:RegisterUnitEvents("unit.fire_orb",{
    [core.E.UNIT_CREATED] = function(self, id, unit)
      mod:RemoveTimerBar("NEXT_FIRE_ORB_TIMER")
      mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", "msg.fire_orb.next", NEXT_FIRE_ORB_TIMER)
      mod:AddTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", id), "msg.fire_orb.pop.timer", FIRE_ORB_SAFE_TIMER, false, "Red", mod.PopFireOrb, mod)
      fireOrbTargetTestTimer:Start()
    end,
    [core.E.UNIT_DESTROYED] = function(_, id)
      mod:RemoveTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", id))
    end,
  }
)
