-- OneCast's fishing food. In Forever, some cooked fish are "Nutritious Food": eat one for 10
-- seconds and you're Well Fed (spell 1249521) with more Fishing skill for 15 minutes. The game
-- counts that bonus in your skill already; this knows the foods, what you have, the buff's time
-- left, and says when it's worn off while you fish (foodReminder). The tackle box has its row.

local _, ns = ...
local L = ns.L -- translations (Locale.lua)

local Food = {}
ns.Food = Food

Food.WELL_FED = 1249521 -- "Well Fed": Fishing skill raised
Food.MINUTES = 15

-- Best first: { itemID, Fishing bonus, its name until the game has the item }. From Forever's
-- game data (each food's Nutritious Food spell, build 1.60.1.70938, 21 November 2026).
Food.LIST = {
	{ 13930, 18, "Filet of Redgill" },
	{ 8957, 18, "Spinefin Halibut" },
	{ 4594, 12, "Rockscale Cod" },
	{ 4593, 8, "Bristle Whisker Catfish" },
	{ 5476, 5, "Fillet of Frenzy" },
	{ 6316, 3, "Loch Frenzy Delight" },
}

function Food.Name(food)
	return C_Item.GetItemNameByID(food[1]) or food[3]
end

function Food.Count(food)
	return C_Item.GetItemCount and C_Item.GetItemCount(food[1]) or 0
end

-- The best fishing food in your bags, or nil.
function Food.Best()
	for _, food in ipairs(Food.LIST) do
		if Food.Count(food) > 0 then
			return food
		end
	end
end

-- The fishing food buff on you now: its bonus and seconds left, or nil.
function Food.Active()
	local aura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(Food.WELL_FED)
	if type(aura) ~= "table" then
		return nil
	end
	local bonus = type(aura.points) == "table" and tonumber(aura.points[1]) or nil
	local expires = tonumber(aura.expirationTime)
	return bonus or 0, expires and expires > 0 and math.max(0, expires - GetTime()) or nil
end

-- A food in your bags that would close a zone's gap of `short` skill: the smallest that does.
function Food.CoverHint(short)
	if Food.Active() then
		return nil
	end
	local pick
	for _, food in ipairs(Food.LIST) do
		if food[2] >= short and Food.Count(food) > 0 and (not pick or food[2] < pick[2]) then
			pick = food
		end
	end
	return pick and string.format(L["Eating a %s (+%d) would cover it."], Food.Name(pick), pick[2])
end

-- Worn off while you fish, with more in your bags: chat says which to eat.
local wasActive = false
local events = CreateFrame("Frame")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:SetScript("OnEvent", function()
	local active = Food.Active() ~= nil
	if wasActive and not active and ns.db and ns.db.foodReminder ~= false
		and ns.HasFishingPole and ns.HasFishingPole() then
		local best = Food.Best()
		if best then
			ns.Print(string.format(L["your fishing food has worn off. Eat a %s for +%d Fishing (the tackle box has it)."],
				Food.Name(best), best[2]))
		end
	end
	wasActive = active
	if ns.TackleBox and ns.TackleBox.RefreshFood then
		ns.TackleBox.RefreshFood()
	end
end)
