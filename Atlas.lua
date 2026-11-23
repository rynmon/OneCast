-- The Forever fishing atlas in game: what players' data reports (AtlasData.lua, made by
-- tools/atlas.py from pasted CurseForge comments) say about each zone. Where Forever's catches
-- and getaways overrule the listed level, its level is used; everywhere, the zone's tooltips say
-- how many players' reports back it up, and a fish's page gives Forever's own catch rate once
-- reports with a code have counted enough catches.

local _, ns = ...

local Atlas = {}
ns.Atlas = Atlas

local data = ns.ATLAS or { players = 0, zones = {} }
local byName = {}
local MIN_RATE_CATCHES = 30 -- a zone's catches before a fish's share of them is worth saying

-- Each zone by its name in this client's language, and by its English one.
local englishClient = GetLocale() == "enUS" or GetLocale() == "enGB"
local english = {}
for name, id in pairs(ns.ZONE_AREA_IDS or {}) do
	english[id] = english[id] or name
end
for key, z in pairs(data.zones or {}) do
	local names = {}
	if type(key) == "number" then
		-- The client's own name, where it isn't English (an English client needs no lookup).
		local here = not englishClient and C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(key)
		if type(here) == "string" and here ~= "" then
			names[#names + 1] = here
		end
		if english[key] then
			names[#names + 1] = english[key]
		end
	else
		names[#names + 1] = key
	end
	for _, name in ipairs(names) do
		byName[name] = z
	end
	z.name = names[1]
	-- Forever's own level, where the reports overrule the listed one (or there was none).
	if z.level and z.name and ns.ZONE_FISHING_SKILL then
		ns.ZONE_FISHING_SKILL[z.name] = z.level
		local unknown = ns.ZONE_FISHING_UNKNOWN or {}
		for i = #unknown, 1, -1 do
			for _, name in ipairs(names) do
				if unknown[i] == name then
					table.remove(unknown, i)
					break
				end
			end
		end
	end
end

function Atlas.Players()
	return data.players or 0
end

function Atlas.Zone(zone)
	return zone and byName[zone] or nil
end

local function Who(n)
	return n == 1 and "1 player's report" or string.format("%d players' reports", n)
end

-- One sentence on what Forever's players have seen in a zone, or nil with nothing to say.
function Atlas.ZoneLine(zone)
	local z = Atlas.Zone(zone)
	if not z then
		return nil
	end
	local listed = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[zone]
	local who = Who(z.reports or 1)
	if z.level and listed == z.level then
		return string.format("Forever's own level, from %s: fish got away up to %d skill.", who, z.low - 1)
	elseif z.low and listed and z.low == listed then
		return string.format("Confirmed in Forever by %s.", who)
	elseif z.low and listed and z.low < listed then
		return string.format("In Forever, fish got away up to %d skill (%s).", z.low - 1, who)
	elseif z.low then
		return string.format("In Forever, fish got away up to %d skill (%s).", z.low - 1, who)
	elseif (z.catches or 0) > 0 then
		return string.format("In Forever, none got away in %d catches (%s).", z.catches, who)
	end
end

-- A fish's share of the catches in a zone, from reports with a code: share (0 to 1), the zone's
-- catches and the reports behind it; nil until there are enough catches to say.
function Atlas.ItemShare(itemID, zone)
	local z = Atlas.Zone(zone)
	if not (z and z.items and z.items[itemID]) then
		return nil
	end
	local total = 0
	for _, n in pairs(z.items) do
		total = total + n
	end
	if total < MIN_RATE_CATCHES then
		return nil
	end
	return z.items[itemID] / total, total, z.reports or 1
end
