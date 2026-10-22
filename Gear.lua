-- OneCast gear: equip a fishing pole from your bags on the cast key, and put your
-- weapons back afterwards.
--
-- Equipping is plain item use (EquipItemByName), allowed out of combat, so it runs from
-- the cast button's PreClick: a press with no pole equipped equips the best pole in your
-- bags instead of casting, and the next press casts. The weapons that were in the main and
-- off hand are saved per character and put back after a stretch without casting, when
-- combat starts, or on demand (key binding, stats window button, /onecast gear).

local _, ns = ...

local Gear = {}
ns.Gear = Gear

local MAIN = INVSLOT_MAINHAND or 16
local OFF = INVSLOT_OFFHAND or 17
local EQUIP_PENDING = 1.5 -- seconds a press waits for the pole to arrive before casting
local RETRY_LOOT = 5      -- idle restore postponed while the loot window is open

local Equip = (C_Item and C_Item.EquipItemByName) or EquipItemByName

local charDB
local pendingUntil = 0
local restoring = false
local restoreTimer

function Gear.IsPole(item)
	if not item then
		return false
	end
	local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(item)
	return classID == Enum.ItemClass.Weapon and subclassID == Enum.ItemWeaponSubclass.Fishingpole
end

local function MainHandIsPole()
	return Gear.IsPole(GetInventoryItemID("player", MAIN))
end

local function ItemLevel(link)
	local level = C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link)
	return level or 0
end

-- Best pole in the bags: the one used last time if it's there, else the highest item level.
local function FindPoleInBags()
	local best, bestScore
	for bag = 0, NUM_BAG_SLOTS or 4 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local link = C_Container.GetContainerItemLink(bag, slot)
			if link and Gear.IsPole(link) then
				local score = ItemLevel(link) + (link == charDB.lastPole and 10000 or 0)
				if not bestScore or score > bestScore then
					best, bestScore = link, score
				end
			end
		end
	end
	return best
end

local function UnequipToBags(slot)
	for bag = 0, NUM_BAG_SLOTS or 4 do
		if C_Container.GetContainerNumFreeSlots(bag) > 0 then
			PickupInventoryItem(slot)
			if bag == 0 then
				PutItemInBackpack()
			else
				PutItemInBag(C_Container.ContainerIDToInventoryID(bag))
			end
			return true
		end
	end
	return false
end

local function CancelRestoreTimer()
	if restoreTimer then
		restoreTimer:Cancel()
		restoreTimer = nil
	end
end

-- Called from the cast button's PreClick, out of combat. Returns true when this press
-- should not cast: a pole is being equipped instead.
function Gear.PreClick()
	if not ns.db.autoEquip or not charDB then
		return false
	end
	if GetTime() < pendingUntil then
		return not ns.HasFishingPole()
	end
	if ns.HasFishingPole() then
		return false
	end
	local pole = FindPoleInBags()
	if not pole then
		return false -- let the cast fail with the game's own "requires a fishing pole"
	end

	restoring = false
	CancelRestoreTimer()
	if not charDB.savedWeapons then
		charDB.savedWeapons = {
			main = GetInventoryItemLink("player", MAIN),
			off = GetInventoryItemLink("player", OFF),
		}
	end
	charDB.lastPole = pole
	Equip(pole, MAIN)
	pendingUntil = GetTime() + EQUIP_PENDING
	ns.Print("equipped " .. pole .. ". Press again to cast.")
	return true
end

-- One step of putting the saved weapons back; repeated as each swap lands.
local function RestoreStep()
	local saved = charDB.savedWeapons
	if not saved then
		restoring = false
		return
	end
	if InCombatLockdown() then
		return -- carried on from PLAYER_REGEN_ENABLED
	end
	if saved.main and GetInventoryItemLink("player", MAIN) ~= saved.main then
		Equip(saved.main, MAIN)
		return
	end
	if not saved.main and MainHandIsPole() then
		if not UnequipToBags(MAIN) then
			ns.Print("no bag space to take off the fishing pole.")
			restoring = false
		end
		return
	end
	if saved.off and GetInventoryItemLink("player", OFF) ~= saved.off then
		Equip(saved.off, OFF)
		return
	end
	charDB.savedWeapons = nil
	restoring = false
	ns.Print("weapons re-equipped.")
end

function Gear.Restore()
	CancelRestoreTimer()
	if not charDB or not charDB.savedWeapons then
		return false
	end
	restoring = true
	RestoreStep()
	return true
end

function Gear.HasSaved()
	return charDB and charDB.savedWeapons ~= nil
end

function Gear.OnCast()
	CancelRestoreTimer()
end

-- After the line comes in, put weapons back if nothing is cast for a while.
function Gear.OnFishingStopped()
	CancelRestoreTimer()
	local delay = ns.db.restoreDelay or 0
	if delay <= 0 or not Gear.HasSaved() then
		return
	end
	local function Fire()
		restoreTimer = nil
		if LootFrame and LootFrame:IsShown() then
			restoreTimer = C_Timer.NewTimer(RETRY_LOOT, Fire)
			return
		end
		Gear.Restore()
	end
	restoreTimer = C_Timer.NewTimer(delay, Fire)
end

function Gear.OnCombatStart()
	CancelRestoreTimer()
	if ns.db.restoreOnCombat and Gear.HasSaved() then
		-- Last moment before lockdown; anything left is finished when combat ends.
		restoring = true
		local saved = charDB.savedWeapons
		if saved.main and GetInventoryItemLink("player", MAIN) ~= saved.main then
			Equip(saved.main, MAIN)
		end
	end
end

-- Global for the "Re-equip weapons" key binding.
function OneCast_RestoreWeapons()
	if not Gear.Restore() then
		ns.Print("no saved weapons to re-equip.")
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, slot)
	if event == "PLAYER_LOGIN" then
		charDB = OneCastCharDB
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		if not charDB or not charDB.savedWeapons then
			return
		end
		if restoring then
			C_Timer.After(0.2, RestoreStep)
		elseif slot == MAIN and not MainHandIsPole() and GetTime() >= pendingUntil then
			-- The player changed weapons by hand; forget the saved ones.
			charDB.savedWeapons = nil
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if restoring then
			RestoreStep()
		end
	end
end)
