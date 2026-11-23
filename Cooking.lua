-- Catch to cook to sell: is a fish worth more cooked than raw? Each Cooking recipe in the
-- collection, what it makes and what it takes, from Forever's game data (each recipe spell's
-- create-item effect and its SpellReagents, build 1.60.1.71037): [spell] = { product, makes,
-- { { reagent, count }, ... } }. Prices are the ones the stats window uses (Stats.ItemPrice: the
-- auction's, else a vendor's).

local _, ns = ...
local L = ns.L -- translations (Locale.lua)

local Cooking = {}
ns.Cooking = Cooking

Cooking.RECIPES = {
	[6500] = { 5527, 1, { { 5504, 1 }, { 2692, 1 } } }, -- Goblin Deviled Clams: 1 Goblin Deviled Clams from 1 Tangy Clam Meat, 1 Hot Spices
	[7751] = { 6290, 1, { { 6291, 1 } } }, -- Brilliant Smallfish: 1 Brilliant Smallfish from 1 Raw Brilliant Smallfish
	[7752] = { 787, 1, { { 6303, 1 } } }, -- Slitherskin Mackerel: 1 Slitherskin Mackerel from 1 Raw Slitherskin Mackerel
	[7753] = { 4592, 1, { { 6289, 1 } } }, -- Longjaw Mud Snapper: 1 Longjaw Mud Snapper from 1 Raw Longjaw Mud Snapper
	[7754] = { 6316, 1, { { 6317, 1 }, { 2678, 1 } } }, -- Loch Frenzy Delight: 1 Loch Frenzy Delight from 1 Raw Loch Frenzy, 1 Mild Spices
	[7755] = { 4593, 1, { { 6308, 1 } } }, -- Bristle Whisker Catfish: 1 Bristle Whisker Catfish from 1 Raw Bristle Whisker Catfish
	[7827] = { 5095, 1, { { 6361, 1 } } }, -- Rainbow Fin Albacore: 1 Rainbow Fin Albacore from 1 Raw Rainbow Fin Albacore
	[7828] = { 4594, 1, { { 6362, 1 } } }, -- Rockscale Cod: 1 Rockscale Cod from 1 Raw Rockscale Cod
	[8238] = { 6657, 1, { { 6522, 1 }, { 2678, 1 } } }, -- Savory Deviate Delight: 1 Savory Deviate Delight from 1 Deviate Fish, 1 Mild Spices
	[18238] = { 6887, 1, { { 4603, 1 } } }, -- Spotted Yellowtail: 1 Spotted Yellowtail from 1 Raw Spotted Yellowtail
	[18239] = { 13927, 1, { { 13754, 1 }, { 3713, 1 } } }, -- Cooked Glossy Mightfish: 1 Cooked Glossy Mightfish from 1 Raw Glossy Mightfish, 1 Soothing Spices
	[18240] = { 13928, 1, { { 13755, 1 }, { 3713, 1 } } }, -- Grilled Squid: 1 Grilled Squid from 1 Raw Winter Squid, 1 Soothing Spices
	[18241] = { 13930, 1, { { 13758, 1 } } }, -- Filet of Redgill: 1 Filet of Redgill from 1 Raw Redgill
	[18242] = { 13929, 1, { { 13756, 1 }, { 2692, 2 } } }, -- Hot Smoked Bass: 1 Hot Smoked Bass from 1 Raw Summer Bass, 2 Hot Spices
	[18243] = { 13931, 1, { { 13759, 1 }, { 159, 1 } } }, -- Nightfin Soup: 1 Nightfin Soup from 1 Raw Nightfin Snapper, 1 Refreshing Spring Water
	[18244] = { 13932, 1, { { 13760, 1 } } }, -- Poached Sunscale Salmon: 1 Poached Sunscale Salmon from 1 Raw Sunscale Salmon
	[18245] = { 13933, 1, { { 13888, 1 }, { 159, 1 } } }, -- Lobster Stew: 1 Lobster Stew from 1 Darkclaw Lobster, 1 Refreshing Spring Water
	[18246] = { 13934, 1, { { 13893, 1 }, { 2692, 1 }, { 3713, 1 } } }, -- Mightfish Steak: 1 Mightfish Steak from 1 Large Raw Mightfish, 1 Hot Spices, 1 Soothing Spices
	[18247] = { 13935, 1, { { 13889, 1 }, { 3713, 1 } } }, -- Baked Salmon: 1 Baked Salmon from 1 Raw Whitescale Salmon, 1 Soothing Spices
	[20626] = { 16766, 2, { { 7974, 2 }, { 2692, 1 }, { 1179, 1 } } }, -- Undermine Clam Chowder: 2 Undermine Clam Chowder from 2 Zesty Clam Meat, 1 Hot Spices, 1 Ice Cold Milk
	[20916] = { 8364, 1, { { 8365, 1 } } }, -- Mithril Headed Trout: 1 Mithril Head Trout from 1 Raw Mithril Head Trout
	[25704] = { 21072, 1, { { 21071, 1 }, { 2678, 1 } } }, -- Smoked Sagefish: 1 Smoked Sagefish from 1 Raw Sagefish, 1 Mild Spices
	[25954] = { 21217, 1, { { 21153, 1 }, { 2692, 1 } } }, -- Sagefish Delight: 1 Sagefish Delight from 1 Raw Greater Sagefish, 1 Hot Spices
	[470359] = { 232436, 1, { { 13888, 1 }, { 227813, 1 } } }, -- Darkclaw Bisque: 1 Darkclaw Bisque from 1 Darkclaw Lobster, 1 227813
	[470370] = { 232438, 1, { { 13758, 1 } } }, -- Smoked Redgill: 1 Smoked Redgill from 1 Raw Redgill
	[1225762] = { 238641, 1, { { 4603, 12 }, { 12184, 4 }, { 6362, 3 }, { 239017, 1 } } }, -- Specklefin Feast: 1 Specklefin Feast from 12 Raw Spotted Yellowtail, 4 Raptor Flesh, 3 Raw Rockscale Cod, 1 Exquisite Spices
	[1225763] = { 238642, 1, { { 13888, 12 }, { 3712, 4 }, { 3404, 3 }, { 239017, 1 } } }, -- Grand Lobster Banquet: 1 Grand Lobster Banquet from 12 Darkclaw Lobster, 4 Turtle Meat, 3 Buzzard Wing, 1 Exquisite Spices
	[1250158] = { 250081, 1, { { 7974, 3 }, { 3713, 4 } } }, -- Clam Linguine: 1 Clam Linguine from 3 Zesty Clam Meat, 4 Soothing Spices
	[1252566] = { 251525, 1, { { 251524, 1 }, { 2678, 1 } } }, -- Savory Whimsyfin Delight: 1 Savory Whimsyfin Delight from 1 Whimsyfin, 1 Mild Spices
	[1319313] = { 286152, 1, { { 13890, 1 }, { 3713, 1 } } }, -- Plated Armorfish: 1 Plated Armorfish from 1 Raw Plated Armorfish, 1 Soothing Spices
}

-- Fishing food: the cooked fish that raise Fishing (Food.lua), by item.
local function FoodBonus(itemID)
	for _, food in ipairs(ns.Food and ns.Food.LIST or {}) do
		if food[1] == itemID then
			return food[2]
		end
	end
end

-- Every Cooking use of a raw fish, most worth first: { spell, name, product, makes, need (raw fish
-- a cook takes), each (copper a raw fish turns into, after the other reagents' prices), extras
-- ({ itemID, count } the cook also takes), unpriced (an extra had no price, so `each` is too
-- high), known, food (its Fishing bonus, for fishing food) }; and the raw fish's own price.
function Cooking.Uses(fishID)
	local Price = ns.Stats and ns.Stats.ItemPrice
	local raw = Price and Price(fishID)
	local fish = ns.FISH_BY_ID and ns.FISH_BY_ID[fishID]
	local uses = {}
	for _, recipe in ipairs(fish and fish.recipes or {}) do
		local r = recipe[3] == "Cooking" and Cooking.RECIPES[recipe[1]]
		if r and Price then
			local product, makes, reagents = r[1], r[2], r[3]
			local need, cost, unpriced, extras = 0, 0, false, {}
			for _, reagent in ipairs(reagents) do
				if reagent[1] == fishID then
					need = reagent[2]
				else
					extras[#extras + 1] = reagent
					local p = Price(reagent[1])
					if p then
						cost = cost + p * reagent[2]
					else
						unpriced = true
					end
				end
			end
			local worth = Price(product)
			if need > 0 and worth then
				uses[#uses + 1] = { spell = recipe[1], name = recipe[2], product = product, makes = makes, need = need,
					each = math.max(0, (worth * makes - cost) / need), extras = extras, unpriced = unpriced,
					known = ns.KnowsSpell and ns.KnowsSpell(recipe[1]) or false, food = FoodBonus(product) }
			end
		end
	end
	table.sort(uses, function(a, b)
		return a.each > b.each
	end)
	return uses, raw
end

-- The best use you can cook now, if it beats selling raw: the use and the gain a fish (copper).
function Cooking.BestKnown(fishID)
	local uses, raw = Cooking.Uses(fishID)
	for _, use in ipairs(uses) do
		if use.known and use.each > (raw or 0) then
			return use, use.each - (raw or 0), raw
		end
	end
	return nil, 0, raw
end

-- How much more `items` ({ [itemID] = { count } }, a session's catch) are worth with each fish
-- cooked where a recipe you know pays more than selling it raw: copper, and how many fish.
function Cooking.Gain(items)
	local gain, fish = 0, 0
	for id, item in pairs(items or {}) do
		local count = type(item) == "table" and item.count or item
		local use, each = Cooking.BestKnown(id)
		if use and (count or 0) > 0 then
			gain = gain + each * count
			fish = fish + count
		end
	end
	return gain, fish
end

-- Money as plain words ("1g 20s", "45s", "8c"), for the book's parchment, where coloured coin
-- text is hard to read.
function Cooking.Money(copper)
	copper = math.floor((copper or 0) + 0.5)
	local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
	if g > 0 then
		return s > 0 and string.format(L["%dg %ds"], g, s) or string.format(L["%dg"], g)
	elseif s > 0 then
		return string.format(L["%ds"], s)
	end
	return string.format(L["%dc"], c)
end

-- The fish page's line under its recipes: its best use against raw, or nil without prices.
function Cooking.PageLine(fishID)
	local uses, raw = Cooking.Uses(fishID)
	local best = uses[1]
	if not (best and raw) then
		return nil
	end
	local M = Cooking.Money
	if best.each > raw then
		return string.format(L["Worth most cooked into %s: %s a fish, against %s raw%s."], best.name, M(best.each), M(raw),
			best.known and "" or L[" (you don't know the recipe yet)"])
	end
	return string.format(L["Worth more raw: %s a fish, against %s cooked into %s."], M(raw), M(best.each), best.name)
end

-- One line for a catch's tooltip: its best use cooked, against raw, or nil.
function Cooking.TipLine(fishID)
	local uses, raw = Cooking.Uses(fishID)
	local best = uses[1]
	if not best then
		return nil
	end
	local Short = ns.Stats.ShortGold
	local text = string.format(L["Cooked into %s: %s a fish%s"], best.name, Short(best.each),
		raw and string.format(L[" (raw %s)"], Short(raw)) or "")
	if not best.known then
		text = text .. L[", recipe not known"]
	end
	local better = not raw or best.each > raw
	return text, better
end
