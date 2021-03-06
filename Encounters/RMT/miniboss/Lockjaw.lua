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
local mod = core:NewEncounter("Lockjaw", 104, 548, 550)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.lockjaw" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.lockjaw"] = "Chief Warden Lockjaw",
    ["unit.shackle"] = "Blaze Shackle",
    -- Cast names.
    ["cast.lockjaw.shackle"] = "Blaze Shackles",
    -- Messages.
    ["msg.lockjaw.shackle.dodge"] = "INTERRUPT",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.lockjaw"] = "Hauptwärter Maulsperr",
    ["unit.shackle"] = "Glutfessel",
    -- Cast names.
    ["cast.lockjaw.shackle"] = "Glutfesseln",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.lockjaw"] = "Gardien en chef Tétanos",
    ["unit.shackle"] = "Fer enflammé",
    -- Cast names.
    ["cast.lockjaw.shackle"] = "Fers enflammés",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("CrosshairTethers")
mod:RegisterDefaultSetting("MessageShackles")
mod:RegisterDefaultSetting("SoundShackles")

mod:RegisterMessageSetting("CIRCLES", core.E.COMPARE_EQUAL, "MessageShackles", "SoundShackles")
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.lockjaw",{
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_CASTS)
    end,
    [core.E.CAST_END] = {
      ["cast.lockjaw.shackle"] = function(self)
        mod:AddMsg("CIRCLES", "msg.lockjaw.shackle.dodge", 5, "Inferno", "xkcdOrange")
      end
    },
  }
)

mod:RegisterUnitEvents("unit.shackle",{
    [core.E.UNIT_CREATED] = function (_, id)
      if mod:GetSetting("CrosshairTethers") then
        core:AddPicture(id, id, "Crosshair", 25)
      end
    end,
    [core.E.UNIT_DESTROYED] = function (_, id)
      core:RemovePicture(id)
    end,
  }
)
