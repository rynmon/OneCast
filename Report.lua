-- OneCast report: this character's fishing data as plain text, to copy and share. It's shown
-- on the Feedback page, as its Data report (Feedback.lua).
--
-- Nobody has published Forever's real zone fishing levels or all of its fish, and the
-- game doesn't tell addons either. OneCast already sees every catch and getaway, and the skill
-- each happened at, so players can pass that on: OneCast's numbers can then become Forever's
-- own. The text holds fishing numbers only: no character name, realm or guild.

local _, ns = ...

local Report = {}
ns.Report = Report

local MAX_FISH = 15 -- items listed per camp buff, most caught first

-- The area ID for a zone name as the game gives it, in any client language.
local function AreaID(zone)
	local id = ns.ZONE_AREA_IDS and ns.ZONE_AREA_IDS[zone]
	if id then
		return id
	end
	for _, areaID in pairs(ns.ZONE_AREA_IDS or {}) do
		if C_Map.GetAreaInfo(areaID) == zone then
			return areaID
		end
	end
end

local function ByCount(items)
	local list = {}
	for id, item in pairs(items) do
		local count = type(item) == "table" and item.count or item
		local name = type(item) == "table" and item.name or C_Item.GetItemNameByID(id)
		list[#list + 1] = { id = id, count = count, name = name or ("item " .. id) }
	end
	table.sort(list, function(a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		return a.id < b.id
	end)
	return list
end

local function ItemLine(items)
	local parts = {}
	local list = ByCount(items)
	for i = 1, math.min(#list, MAX_FISH) do
		parts[i] = string.format("%s (%d) x%d", list[i].name, list[i].id, list[i].count)
	end
	if #list > MAX_FISH then
		parts[#parts + 1] = string.format("and %d more", #list - MAX_FISH)
	end
	return table.concat(parts, ", ")
end

-- "  skill 200-224: 40 caught, 3 got away" for each step with anything in it.
local function SkillLines(z, add)
	local steps, seen = {}, {}
	for _, key in ipairs({ "skillCatches", "skillGetaways" }) do
		for bucket in pairs(z[key] or {}) do
			if not seen[bucket] then
				seen[bucket] = true
				steps[#steps + 1] = bucket
			end
		end
	end
	table.sort(steps)
	local step = ns.Stats.SKILL_STEP
	for _, bucket in ipairs(steps) do
		local caught = z.skillCatches and z.skillCatches[bucket] or 0
		local away = z.skillGetaways and z.skillGetaways[bucket] or 0
		add(string.format("  skill %d-%d: %d caught%s", bucket, bucket + step - 1, caught,
			away > 0 and string.format(", %d got away", away) or ""))
	end
	return #steps > 0
end

-- Findings: what this character has seen that OneCast doesn't know ----------------------
-- Worth sharing: a badge on the Feedback tab until the report is copied.

local MIN_UNKNOWN_LEVEL = 10 -- catches in a zone with no known level
local MIN_BELOW_LEVEL = 20   -- catches without a getaway below a zone's listed level
local MIN_EXPECTED = 3       -- getaways those catches should have had, had the level been right
local MIN_CAMP = 5           -- catches under a camp buff

-- A collection fish the book can't say where to find: no zones at all, from any source. Only
-- these are worth a report when caught: a known fish in one more zone helps nobody find it.
local function Unplaced(fish)
	return not (fish.zones and fish.zones[1]) and not (fish.more and fish.more[1])
end

-- An item's name: as it was caught, the game's (if it's loaded yet), else the collection's.
local function ItemName(id, item)
	local fish = ns.FISH_BY_ID and ns.FISH_BY_ID[id]
	return (type(item) == "table" and item.name) or C_Item.GetItemNameByID(id) or (fish and fish.name) or ("item " .. id)
end

-- What Classic's fishing gives that the collection leaves out on purpose: junk, potions, herbs
-- and reagents (checked against CMaNGOS's fishing and pool loot, 13 November 2026), and the
-- Electropeller, a quest drop. Anything else fished up that the collection lacks is news.
local NOT_COLLECTED = {
	[6456] = true, [6297] = true, [6301] = true, [6455] = true, [6457] = true, -- junk
	[118] = true, [858] = true, [929] = true, [1710] = true, [3928] = true, [13446] = true, -- healing potions
	[2455] = true, [3385] = true, [3827] = true, [6149] = true, [13443] = true, -- mana potions
	[3820] = true, [2447] = true, [3857] = true, [7070] = true, [7079] = true, [7080] = true, -- herbs, reagents
	[6718] = true, -- Electropeller
}

-- Weapons and armour: a mob's drop looted right after a cast can be logged as a catch (a Flanged
-- Mace "fished up" in Elwynn Forest), and all the fishable gear known is in the collection already.
-- Quest items are left out too: they're fished up for a quest, not collected.
local function IsGear(id)
	local classID = select(6, C_Item.GetItemInfoInstant(id))
	return classID == 2 or classID == 4
		or classID == 12 -- and quest items, fished up for a quest (Darkshore's Gaffer Jacks)
end

-- A collection item OneCast only knows from Classic: no Forever zones, only `more` ones marked
-- "classic". The first Forever catch of one confirms it's still there.
local function ClassicOnly(fish)
	if fish.zones and fish.zones[1] then
		return false
	end
	for _, extra in ipairs(fish.more or {}) do
		if extra[2] ~= "classic" then
			return false
		end
	end
	return fish.more and fish.more[1] ~= nil
end

-- Every finding, as { key, text, zone }: the key stays the same while the finding does. The
-- tab's badge, stats window, book and this window can all ask in one redraw, so the list is
-- worked out once a frame. Callers may sort it, so each gets its own copy.
local cached, cachedAt
local Findings

function Report.Findings()
	local now = GetTime()
	if not cached or cachedAt ~= now then
		cached, cachedAt = Findings(), now
	end
	local copy = {}
	for i, f in ipairs(cached) do
		copy[i] = f
	end
	return copy
end

-- Nothing cached survives a catch, a getaway or sharing.
function Report.Forget()
	cached = nil
end

Findings = function()
	local found = {}
	-- text: the line in the report. title and detail: the window's, for the player: what was
	-- found, and why it's worth sending.
	local function add(key, text, zone, title, detail)
		found[#found + 1] = { key = key, text = text, zone = zone, title = title, detail = detail }
	end
	local step = ns.Stats.SKILL_STEP
	local zoneNames = {}
	for zone in pairs(OneCastCharDB and OneCastCharDB.zoneStats or {}) do
		zoneNames[#zoneNames + 1] = zone
	end
	table.sort(zoneNames)
	for _, zone in ipairs(zoneNames) do
		local z = OneCastCharDB.zoneStats[zone]
		local listed = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[zone]
		if not listed then
			if (z.catches or 0) >= MIN_UNKNOWN_LEVEL then
				add("level:" .. zone, string.format("%d catches in %s, which has no known fishing level", z.catches, zone), zone,
					zone, string.format("%d catches here. OneCast doesn't know the skill this zone needs: yours will tell.", z.catches))
			end
		else
			-- A getaway at or above the listed level says the real one is higher.
			local highestAway
			for bucket, n in pairs(z.skillGetaways or {}) do
				if n > 0 and (not highestAway or bucket > highestAway) then
					highestAway = bucket
				end
			end
			if highestAway and highestAway >= listed then
				add("above:" .. zone, string.format("A fish got away in %s at skill %d-%d, though OneCast lists %d",
					zone, highestAway, highestAway + step - 1, listed), zone,
					zone, string.format("A fish got away at skill %d, where OneCast says %d is plenty. It may need more.",
						highestAway, listed))
			end
			-- Plenty of catches below the listed level, none getting away there, says it's lower: but
			-- only where getaways were to be expected. Fish get away about (level - skill)% of the
			-- time below a zone's level, so catches just under it say little. Each step counts at its
			-- top skill, the least getaways it could expect; it takes MIN_EXPECTED in all.
			local below, lowest, expected = 0, nil, 0
			for bucket, n in pairs(z.skillCatches or {}) do
				if bucket + step <= listed and not (highestAway and bucket <= highestAway) then
					below = below + n
					lowest = math.min(lowest or bucket, bucket)
					expected = expected + n * (listed - (bucket + step - 1)) / 100
				end
			end
			if below >= MIN_BELOW_LEVEL and expected >= MIN_EXPECTED then
				add("below:" .. zone, string.format("%d catches in %s from skill %d with no getaways, though OneCast lists %d",
					below, zone, lowest, listed), zone,
					zone, string.format("%d catches from skill %d with none getting away, though OneCast says %d. It may need less.",
						below, lowest, listed))
			end
		end
	end
	for _, entry in ipairs(ns.Collection and ns.Collection.Discovered() or {}) do
		-- Where this character caught it, so the finding says everything on its own.
		local where = {}
		for _, zone in ipairs(zoneNames) do
			local item = OneCastCharDB.zoneStats[zone].items and OneCastCharDB.zoneStats[zone].items[entry.id]
			if item and (item.count or 0) > 0 then
				where[#where + 1] = string.format("%s x%d", zone, item.count)
			end
		end
		add("fish:" .. entry.id, string.format("%s (%d), which isn't in OneCast's collection%s", entry.name or ("item " .. entry.id),
			entry.id, #where > 0 and (" (caught in " .. table.concat(where, ", ") .. ")") or ""), nil,
			entry.name or ("Item " .. entry.id), "A fish OneCast's collection doesn't have yet"
				.. (#where > 0 and (", caught in " .. table.concat(where, ", ")) or "") .. ".")
	end
	-- Anything else fished up that the collection lacks (treasure, gear, junk new to Forever), and
	-- the first Forever catch of anything OneCast only knows from Classic. What came only while a
	-- camp buff was on is the buff's extra reward (ore, herbs, vials: Rare Fishing, 23 November
	-- 2026), not fishing loot: the report's camp section has it.
	local fromCamp = {}
	for _, craft in ipairs(ns.Camp and ns.Camp.CRAFTS or {}) do
		local r = craft.buff and ns.Camp.Record(craft.key)
		for id, n in pairs(r and r.items or {}) do
			fromCamp[id] = (fromCamp[id] or 0) + (type(n) == "table" and n.count or n)
		end
	end
	local caughtInAll = {}
	for _, zone in ipairs(zoneNames) do
		for id, item in pairs(OneCastCharDB.zoneStats[zone].items or {}) do
			caughtInAll[id] = (caughtInAll[id] or 0) + (item.count or 0)
		end
	end
	local other, confirmed = {}, {}
	for _, zone in ipairs(zoneNames) do
		for id, item in pairs(OneCastCharDB.zoneStats[zone].items or {}) do
			if (item.count or 0) > 0 then
				local fish = ns.FISH_BY_ID and ns.FISH_BY_ID[id]
				local list
				local campOnly = (fromCamp[id] or 0) >= (caughtInAll[id] or 0)
				if not fish and not campOnly and not NOT_COLLECTED[id] and not (ns.Collection and ns.Collection.IsFish(id)) and not IsGear(id) then
					list = other
				elseif fish and ClassicOnly(fish) then
					list = confirmed
				end
				if list then
					list[id] = list[id] or { name = ItemName(id, item), where = {}, places = {} }
					table.insert(list[id].where, string.format("%s x%d", zone, item.count))
					table.insert(list[id].places, item.count > 1 and string.format("%s (%d)", zone, item.count) or zone)
				end
			end
		end
	end
	for _, list in ipairs({ other, confirmed }) do
		local ids = {}
		for id in pairs(list) do
			ids[#ids + 1] = id
		end
		table.sort(ids)
		for _, id in ipairs(ids) do
			local e = list[id]
			if list == other then
				add("item:" .. id, string.format("%s (%d) fished up in %s, which isn't in OneCast's collection",
					e.name, id, table.concat(e.where, ", ")), nil,
					e.name, "Fished up in " .. table.concat(e.places, ", ") .. ". It isn't in OneCast's collection yet.")
			else
				add("confirm:" .. id, string.format("%s (%d) caught in %s: OneCast only had Classic's data for it",
					e.name, id, table.concat(e.where, ", ")), nil,
					e.name, "Caught in " .. table.concat(e.places, ", ") .. ". Proof it's in Forever: OneCast only knew it from Classic.")
			end
		end
	end
	-- For the Fisherman's journey: where ranks and fishing spells are learned, and fishing gear
	-- it doesn't list.
	for _, f in ipairs(ns.Journey and ns.Journey.Findings and ns.Journey.Findings() or {}) do
		add(f.key, f.text, nil, f.title, f.detail)
	end
	-- Where a Blueprint or Seasonal Fish Steaks dropped, unless it's the source already confirmed.
	local drops = OneCastCharDB.campDrops or {}
	local dropIDs = {}
	for id in pairs(drops) do
		dropIDs[#dropIDs + 1] = id
	end
	table.sort(dropIDs)
	for _, id in ipairs(dropIDs) do
		local known
		for _, craft in ipairs(ns.Camp and ns.Camp.CRAFTS or {}) do
			if craft.blueprint == id then
				known = craft.blueprintKnown
			end
		end
		local keys = {}
		for key in pairs(drops[id]) do
			keys[#keys + 1] = key
		end
		table.sort(keys)
		for _, key in ipairs(keys) do
			local d = drops[id][key]
			local isKnown = known and ((d.npc and d.npc == known.npc) or (d.name and d.name == known.name))
			if not isKnown then
				local from = d.name and (d.npc and string.format("%s [%d]", d.name, d.npc) or d.name)
					or (d.npc and string.format("creature %d", d.npc)) or (d.object and "a chest or object") or "somewhere"
				local name = ns.Camp.TRACKED_DROPS[id] or ItemName(id)
				add("drop:" .. id .. ":" .. key, string.format("%s (%d) dropped from %s in %s%s", name, id, from, d.zone,
					d.count > 1 and string.format(" (x%d)", d.count) or ""), nil,
					name, string.format("Dropped from %s in %s%s. OneCast doesn't know this source yet.",
						d.name or (d.object and "a chest or object") or "something", d.zone,
						d.count > 1 and string.format(", %d times", d.count) or ""))
			end
		end
	end
	for _, craft in ipairs(ns.Camp and ns.Camp.CRAFTS or {}) do
		local r = craft.buff and ns.Camp.Record(craft.key)
		if r and r.catches >= MIN_CAMP then
			add("camp:" .. craft.key, string.format("%d catches with %s on", r.catches, craft.buffName), nil,
				craft.buffName, string.format("%d catches with it on: enough to show what the buff really does.", r.catches))
		end
	end
	for _, zone in ipairs(zoneNames) do
		for id, item in pairs(OneCastCharDB.zoneStats[zone].items or {}) do
			local fish = ns.FISH_BY_ID and ns.FISH_BY_ID[id]
			if fish and Unplaced(fish) and (item.count or 0) > 0 then
				add("place:" .. id .. ":" .. zone, string.format("%s caught in %s: OneCast doesn't know where it's found yet",
					ItemName(id, item), zone), zone,
					ItemName(id, item), "Caught in " .. zone .. ". OneCast doesn't know where it's found yet.")
			end
		end
	end
	return found
end

local function Seen()
	local charDB = OneCastCharDB
	charDB.reportFindings = charDB.reportFindings or { shared = {} }
	charDB.reportFindings.said = nil -- the chat hints' record, before 1.0
	return charDB.reportFindings
end

-- Findings not yet shared (copied from the report).
function Report.Unshared()
	if not OneCastCharDB then
		return {}
	end
	local shared = Seen().shared
	local list = {}
	for _, f in ipairs(Report.Findings()) do
		if not shared[f.key] then
			list[#list + 1] = f
		end
	end
	return list
end

-- After a catch or getaway: what's new shows quietly, as the Feedback tab's badge.
function Report.Check()
	Report.Forget()
	if ns.Hub and ns.Hub.UpdateBadges then
		ns.Hub.UpdateBadges()
	end
	if Report.RefreshIfShown then
		Report.RefreshIfShown()
	end
end

-- Copying the report shares what's in it.
function Report.MarkShared()
	Report.Forget()
	if not OneCastCharDB then
		return
	end
	local seen = Seen()
	for _, f in ipairs(Report.Findings()) do
		seen.shared[f.key] = true
	end
	if ns.Hub and ns.Hub.UpdateBadges then
		ns.Hub.UpdateBadges()
	end
end

-- The report text ---------------------------------------------------------------------------
-- Only what OneCast can learn from: what's new, the evidence for zone levels, what camp buffs
-- bring in, and any fishing messages OneCast didn't recognise. Zones whose catches only agree
-- with the level OneCast already lists say nothing new, so they're left out.

-- Whether a zone's catches and getaways say anything about its fishing level.
local function Telling(zone, z)
	if (z.casts or 0) == 0 then
		return false
	end
	local listed = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[zone]
	if not listed then
		return (z.catches or 0) > 0 or (z.escapes or 0) > 0
	end
	for _, n in pairs(z.skillGetaways or {}) do
		if n > 0 then
			return true -- getaways bound the level, above or below the listed one
		end
	end
	local step = ns.Stats.SKILL_STEP
	for bucket, n in pairs(z.skillCatches or {}) do
		if n > 0 and bucket + step <= listed then
			return true -- caught below the listed level
		end
	end
	return (z.escapeSkill or 0) > 0 -- a getaway from before 0.7.0
end

-- The report code ---------------------------------------------------------------------------
-- The whole report as one line, for tools/atlas.py to read from a pasted CurseForge comment:
-- comments double-space lines and treat * _ ~ ` [ ] # > as formatting, so it uses only letters,
-- digits and . , ! @ + : -, numbers in base 36. Records are split by "!", fields by ",":
--   H,1,version,locale,id,rank,cap,yyyymmdd   the header; id is this character's, random, no name
--   Z,area,casts,catches,getaways             a zone (area ID, or @Name+With+Plus if it has none)
--   S,step,caught,away                        its catches and getaways at skill step*25 to +24
--   I,item,count                              items under the record above (zone, buff, container)
--   B,key,catches                             a camp buff ("rack", "hut") and what came with it on
--   O,item,opened                             a fished-up container and what it held
--   J,kind,id,how,npc,area,bonus              journey finds: r rank (by cap), s spell, g gear;
--                                             how is t trainer, v vendor, q quest, l loot, u unseen
--   D,item,npc,area,count,object              a camp item's drop
--   X,checksum                                over everything before it
Report.CODE_VERSION = 1
local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

local function B36(n)
	n = math.floor(tonumber(n) or 0)
	if n <= 0 then
		return "0"
	end
	local out = ""
	while n > 0 do
		local d = n % 36
		out = DIGITS:sub(d + 1, d + 1) .. out
		n = math.floor(n / 36)
	end
	return out
end
Report.B36 = B36

local function Checksum(s)
	local sum = 0
	for i = 1, #s do
		sum = (sum + i * s:byte(i)) % 1679616 -- 36^4
	end
	return B36(sum)
end
Report.Checksum = Checksum

-- This character's report ID: six random base-36 digits, made once. Lets the atlas keep only a
-- character's newest report (they hold all-time totals) without knowing whose it is.
local function ReportID()
	local charDB = OneCastCharDB
	if not charDB then
		return "0"
	end
	if not charDB.reportID then
		local id = ""
		for _ = 1, 6 do
			local d = math.random(0, 35)
			id = id .. DIGITS:sub(d + 1, d + 1)
		end
		charDB.reportID = id
	end
	return charDB.reportID
end

local function Place(zone)
	local id = zone and AreaID(zone)
	if id then
		return B36(id)
	end
	return "@" .. tostring(zone or "?"):gsub("[^%w' ]", ""):gsub(" ", "+")
end

local HOW = { trainer = "t", vendor = "v", quest = "q", loot = "l" }

function Report.Code()
	local charDB = OneCastCharDB or {}
	local rec = {}
	local function add(...)
		rec[#rec + 1] = table.concat({ ... }, ",")
	end
	local function items(list)
		local ids = {}
		for id in pairs(list or {}) do
			ids[#ids + 1] = id
		end
		table.sort(ids)
		for _, id in ipairs(ids) do
			local v = list[id]
			local n = type(v) == "table" and v.count or v
			if (tonumber(n) or 0) > 0 then
				add("I", B36(id), B36(n))
			end
		end
	end
	local rank, maxRank = ns.Stats.FishingSkill()
	local version = (ns.VERSION or ""):gsub("[^%w.]", "")
	add("H", Report.CODE_VERSION, version ~= "" and version or "0", GetLocale(), ReportID(), B36(rank), B36(maxRank),
		date("%Y%m%d"))
	local zones = {}
	for zone in pairs(charDB.zoneStats or {}) do
		zones[#zones + 1] = zone
	end
	table.sort(zones)
	local step = ns.Stats.SKILL_STEP
	for _, zone in ipairs(zones) do
		local z = charDB.zoneStats[zone]
		if (z.casts or 0) > 0 or (z.catches or 0) > 0 then
			add("Z", Place(zone), B36(z.casts), B36(z.catches), B36(z.escapes))
			local steps = {}
			for _, key in ipairs({ "skillCatches", "skillGetaways" }) do
				for bucket in pairs(z[key] or {}) do
					steps[bucket] = true
				end
			end
			local list = {}
			for bucket in pairs(steps) do
				list[#list + 1] = bucket
			end
			table.sort(list)
			for _, bucket in ipairs(list) do
				add("S", B36(bucket / step), B36(z.skillCatches and z.skillCatches[bucket]),
					B36(z.skillGetaways and z.skillGetaways[bucket]))
			end
			items(z.items)
		end
	end
	for _, craft in ipairs(ns.Camp and ns.Camp.CRAFTS or {}) do
		local r = craft.buff and ns.Camp.Record(craft.key)
		if r and r.catches > 0 then
			add("B", craft.key, B36(r.catches))
			items(r.items)
		end
	end
	local opened = {}
	for id in pairs(charDB.containerLoot or {}) do
		opened[#opened + 1] = id
	end
	table.sort(opened)
	for _, id in ipairs(opened) do
		local record = charDB.containerLoot[id]
		add("O", B36(id), B36(record.opened))
		items(record.items)
	end
	local finds = charDB.journeyFinds or {}
	for kind, key in pairs({ r = "ranks", s = "spells", g = "gear" }) do
		local ids = {}
		for id in pairs(finds[key] or {}) do
			ids[#ids + 1] = id
		end
		table.sort(ids)
		for _, id in ipairs(ids) do
			local f = finds[key][id]
			add("J", kind, B36(id), HOW[f.how] or "u", B36(f.npc), Place(f.zone), B36(f.bonus))
		end
	end
	for id, sources in pairs(charDB.campDrops or {}) do
		for _, d in pairs(sources) do
			add("D", B36(id), B36(d.npc), Place(d.zone), B36(d.count), d.object and "o" or "")
		end
	end
	local body = "OneCast:" .. table.concat(rec, "!")
	return body .. "!X," .. Checksum(body)
end

function Report.Text()
	local out = {}
	local function add(line)
		out[#out + 1] = line
	end
	local charDB = OneCastCharDB or {}
	local version, build = GetBuildInfo()
	add(string.format("OneCast %s data report", ns.VERSION or "?"))
	add(string.format("Game %s (build %s), %s, %s", version or "?", build or "?", GetLocale(), date("%Y-%m-%d")))
	local rank, maxRank, modifier = ns.Stats.FishingSkill()
	add(rank and string.format("Fishing %d/%d%s", rank, maxRank,
		modifier > 0 and string.format(" (+%d from gear, lure and food right now)", modifier) or "") or "Fishing skill not found")

	local findings = Report.Findings()
	add("")
	if #findings > 0 then
		add(string.format("New to OneCast (%d):", #findings))
		for _, f in ipairs(findings) do
			add("- " .. f.text)
		end
	else
		add("New to OneCast: nothing yet.")
	end

	local zones = {}
	for zone, z in pairs(charDB.zoneStats or {}) do
		if Telling(zone, z) then
			zones[#zones + 1] = { zone = zone, z = z }
		end
	end
	table.sort(zones, function(a, b)
		return a.zone < b.zone
	end)
	if #zones > 0 then
		add("")
		add("Zone levels: catches and getaways at each effective skill (gear, lure and food included).")
		for _, entry in ipairs(zones) do
			local zone, z = entry.zone, entry.z
			local id = AreaID(zone)
			local listed = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[zone]
			add(string.format("%s%s, %s", zone, id and (" [" .. id .. "]") or "",
				listed and ("OneCast lists " .. listed) or "no level known"))
			if not SkillLines(z, add) then
				-- Catches from before 0.7.0 weren't recorded by skill: their totals still say something.
				add(string.format("  %d caught, %d got away (skill not recorded: before 0.7.0)",
					z.catches or 0, z.escapes or 0))
				if z.escapeSkill then
					add(string.format("  a fish got away at %d", z.escapeSkill))
				end
			end
		end
	end

	local camp = {}
	for _, craft in ipairs(ns.Camp and ns.Camp.CRAFTS or {}) do
		local r = craft.buff and ns.Camp.Record(craft.key)
		if r and r.catches > 0 then
			camp[#camp + 1] = { craft = craft, r = r }
		end
	end
	if #camp > 0 then
		add("")
		add("Camp buffs: what was caught while each was on.")
		for _, entry in ipairs(camp) do
			local zonesHere = {}
			for zone, n in pairs(entry.r.zones) do
				zonesHere[#zonesHere + 1] = string.format("%s %d", zone, n)
			end
			table.sort(zonesHere)
			add(string.format("%s (%s): %d caught, in %s", entry.craft.buffName, entry.craft.name, entry.r.catches,
				table.concat(zonesHere, ", ")))
			add("  " .. ItemLine(entry.r.items))
		end
	end

	-- What fished-up trunks, crates, clams and bloated fish held when they were opened.
	local opened = {}
	for id, record in pairs(charDB.containerLoot or {}) do
		opened[#opened + 1] = { id = id, record = record }
	end
	table.sort(opened, function(a, b) return a.id < b.id end)
	if #opened > 0 then
		add("")
		add("What fished-up containers held:")
		for _, entry in ipairs(opened) do
			add(string.format("%s (%d), opened %d: %s", ItemName(entry.id), entry.id, entry.record.opened,
				ItemLine(entry.record.items)))
		end
	end

	-- Fishing messages OneCast didn't recognise: what to match if one is ever being missed.
	local messages = charDB.messagesWhileFishing
	if messages and #messages > 0 then
		add("")
		add("Unrecognised fishing messages:")
		for _, m in ipairs(messages) do
			add(string.format("- %q x%d (%s%s)", m.text, m.count, m.event, m.id and (", " .. m.id) or ""))
		end
	end
	-- The code last: one line that survives a CurseForge comment, for the atlas to read.
	add("")
	add("Report code (keep this line when you paste: it's what OneCast reads):")
	add(Report.Code())
	return table.concat(out, "\n")
end

-- The report lives on the Feedback page.
function Report.RefreshIfShown()
	if ns.Feedback and ns.Feedback.RefreshReport then
		ns.Feedback.RefreshReport()
	end
end

function Report.Show()
	ns.Feedback.ShowReport()
end

function Report.Toggle()
	ns.Feedback.ToggleReport()
end
