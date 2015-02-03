--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpFrostLogic", 52)
if not mod then return end

mod:RegisterEnableBossPair("Hydroflux", "Mnemesis")
mod:RegisterRestrictZone("EpFrostLogic", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")

--------------------------------------------------------------------------------
-- Locals
--

local uPlayer = nil
local strMyName = ""

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	--Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 	"OnSpellCastStart", self)
	--Apollo.RegisterEventHandler("SPELL_CAST_END", 	"OnSpellCastEnd", self)
	--Apollo.RegisterEventHandler("CHAT_DATACHRON", 	"OnChatDC", self)
	--Apollo.RegisterEventHandler("BUFF_APPLIED", 		"OnBuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 		"OnDebuffApplied", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 			"OnReset", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnReset()
	core:StopBar("MIDPHASE")
	core:StopBar("GRAVE")
	core:StopBar("PRISON")
	core:StopBar("DEFRAG")
end

function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == "Mnemesis" and castName == "Circuit Breaker" then
		core:StopBar("MIDPHASE")
		core:AddBar("MIDPHASE", "Middle Phase", 100, true)
	elseif unitName == "Hydroflux" and castName == "Watery Grave" and self:Tank() then
		core:StopBar("GRAVE")
		core:AddBar("GRAVE", "Watery Grave", 10)
	elseif unitName == "Mnemesis" and castName == "Imprison" then
		core:StopBar("PRISON")
		core:AddBar("PRISON", "Imprison", 19)
	elseif unitName == "Mnemesis" and castName == "Defragment" then
		core:StopBar("DEFRAG")
		core:AddMsg("DEFRAG", "SPREAD", 5, "Beware")
		core:AddBar("DEFRAG", 40, true)
	end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	splName = GameLib.GetSpell(splId):GetName()
	if unitName == strMyName and splName == "Data Disruptor" then
		core:AddMsg("DISRUPTOR", "Stay away from boss with buff!", 5, "Beware")
	end
end

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == "Mnemesis" or sName == "Hydroflux" then
		core:AddUnit(unit)
		core:WatchUnit(unit)
		self:Start()
		self:StartScan()
	end
end
function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		local eventTime = GameLib.GetGameTime()

		if sName == "Hydroflux" then
			core:AddUnit(unit)
			core:WatchUnit(unit)
		elseif sName == "Mnemesis" then
			self:Start()
			uPlayer = GameLib.GetPlayerUnit()
			strMyName = uPlayer:GetName()
			core:UnitDebuff(uPlayer)
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			core:AddBar("MIDPHASE", "Middle Phase", 75, true)
			core:AddBar("PRISON", "Imprison", 16)
			core:AddBar("DEFRAG", "Defrag", 20, true)

			if self:Tank() then
				core:AddBar("GRAVE", "Watery Grave", 10)
			end

			Print(eventTime .. " " .. sName .. " FIGHT STARTED ")
		end
	end
end