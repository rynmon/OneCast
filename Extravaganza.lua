-- OneCast: the Stranglethorn Fishing Extravaganza. A countdown to the next contest, a race view
-- while it runs (Tastyfish, pace, and whether 40 comes in time), a checklist before it starts,
-- the rare fish and prizes, where Tastyfish have bitten for you, and each contest's result kept
-- as records. It has a page of its own in the window.
--
-- Every Sunday, 14:00 to 16:00 realm time, Speckled Tastyfish and the contest's rare fish bite
-- in Stranglethorn Vale: Classic's schedule, which Forever kept (warcraft.wiki.gg's Forever
-- pages, 14 November 2026).
--
-- The prizes are Forever's (its client data, Wowhead and warcraft.wiki.gg, 16 November 2026):
-- the first 250 players on each ruleset to hand 40 Tastyfish to Riggle Bassbait in Booty Bay get
-- the Arcanite Fishing Pole, an Extravagant Extravaganza Coin and the Master Angler! title for a
-- week. It was 50 at launch; the 13 November hotfix raised it, and Riggle's quest text says 250
-- (seen in game, 22 November 2026). Tastyfish bite from schools along Stranglethorn's coasts.
-- Jang trades one coin for any one of her prizes.
-- Fishbot 5000 trades each rare fish for a piece of fishing gear.
--
-- A win is seen three ways, any one enough: Riggle's quest (Master Angler, 8193 in Classic)
-- turned in, or a coin or an Arcanite Fishing Pole arriving in the bags during the contest or
-- the hour after. Riggle's yells are counted as winners only if they say "winner": Classic's
-- words, which Forever may not keep.

local _, ns = ...

local X = {}
ns.Extravaganza = X

X.ZONE = "Stranglethorn Vale"
X.TASTYFISH = 19807
X.GOAL = 40
X.SCHEDULE = "Sundays 14:00-16:00 realm time"
X.WINNERS = 250
X.COIN = 274026
X.POLE = 19970 -- Arcanite Fishing Pole
X.QUEST = 8193 -- Master Angler, Riggle's
X.RIGGLE_NAME = "Riggle Bassbait"
-- Jang's prizes, a coin each: the swim-form trinket, water-walking shoes, the cosmetic hat and
-- bucket, and a pet. { item, its name until the game has it }.
X.JANG = { { 19979, "Hook of the Master Angler" }, { 276274, "Surfer Shoes" }, { 276272, "Master Angler's Fishing Hat" },
	{ 276273, "Empty Fish Bucket" }, { 276275, "Bitter Baitling" } }
-- Fishbot 5000's trades: rare fish -> { item, its name until the game has it }.
X.RARE = {
	[19805] = { 19972, "Lucky Fishing Hat" },
	[19806] = { 19971, "High Test Eternium Fishing Line" },
	[19803] = { 19969, "Nat Pagle's Extreme Anglin' Boots" },
}
-- The rare fish in the order shown, with their names until the game has them.
X.RARE_ORDER = { { 19805, "Keefer's Angelfish" }, { 19806, "Dezian Queenfish" }, { 19803, "Brownell's Blue Striped Racer" } }

local WEEKDAY = 1          -- calendar weekday: 1 is Sunday
local START_HOUR = 14
local LENGTH = 2 * 3600
local WEEK = 7 * 86400
local REMIND_BEFORE = 15 * 60
local READY_BEFORE = 60 * 60 -- the checklist in chat, an hour before
local LAST_CALL = 10 * 60    -- holding 40 with this little left: say hurry, once
local GRACE = 3600           -- after the end, wins still count and the result waits
local HISTORY = 12           -- contests kept
local BAG_ROOM = 4           -- free slots worth having: 40 Tastyfish and the rest of the catch

X.LENGTH = LENGTH

-- Realm time as seconds since Sunday 00:00 of this week, or nil if the calendar isn't ready.
local function WeekSeconds()
	local t = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime and C_DateAndTime.GetCurrentCalendarTime()
	if not (t and t.weekday and t.hour) then
		return nil
	end
	return (t.weekday - 1) * 86400 + t.hour * 3600 + (t.minute or 0) * 60 + GetServerTime() % 60
end

-- running, seconds: while the contest runs, true and the seconds left; otherwise false and
-- the seconds until it starts. nil if realm time isn't known.
function X.Status()
	local now = WeekSeconds()
	if not now then
		return nil
	end
	local start = (WEEKDAY - 1) * 86400 + START_HOUR * 3600
	if now >= start and now < start + LENGTH then
		return true, start + LENGTH - now
	end
	return false, (start - now) % WEEK
end

-- The server time the latest contest started (the one running, or the last one), to the
-- minute, so every check names it the same; and the seconds since it ended (0 while it runs).
local function LatestStart()
	local running, seconds = X.Status()
	if running == nil then
		return nil
	end
	local now = GetServerTime()
	local start = running and (now + seconds - LENGTH) or (now + seconds - WEEK)
	start = math.floor((start + 30) / 60) * 60
	return start, running and 0 or math.max(0, now - start - LENGTH), running
end

-- "2d 4h", "3h 12m" or "12m".
function X.FormatWait(seconds)
	seconds = math.max(0, math.floor(seconds))
	local d, h, m = math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600), math.floor(seconds % 3600 / 60)
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%dm", math.max(m, 1))
end

function X.TastyfishInBags()
	return ns.ItemCount(X.TASTYFISH)
end

local function Reminders()
	return ns.db and ns.db.extravaganza
end

-- Speckled Tastyfish as a chat link, or its name until the game has the item.
local function Tastyfish()
	return ns.ItemLink(X.TASTYFISH, "Speckled Tastyfish")
end

local function ItemName(itemID, fallback)
	return C_Item.GetItemNameByID(itemID) or fallback
end
X.ItemName = ItemName

-- What OneCast keeps: { current = this contest's, history = { newest first } }. A contest is
-- { start, caught (Tastyfish), catches, first (first catch), firstFish, goalAt, won, winners,
-- over, rares = { [id] = n }, coins, poles }.
local function Store()
	local charDB = OneCastCharDB
	if not charDB then
		return nil
	end
	charDB.extravaganza = charDB.extravaganza or {}
	local s = charDB.extravaganza
	s.history = s.history or {}
	return s
end

-- The contest running now, or the one that just ended (for the hour Riggle still takes fish);
-- nil otherwise, or if nothing has been kept for it.
function X.Current()
	local s = Store()
	local start, since = LatestStart()
	local c = s and s.current
	if c and start and c.start == start and since < GRACE then
		return c
	end
end

function X.History()
	local s = Store()
	return s and s.history or {}
end

-- Personal records over every contest kept: { contests, best (Tastyfish), fastest (seconds from
-- the first catch to 40), wins }.
function X.Records()
	local r = { contests = 0, best = 0, wins = 0 }
	for _, c in ipairs(X.History()) do
		r.contests = r.contests + 1
		r.best = math.max(r.best, c.caught or 0)
		if c.goalTime and (not r.fastest or c.goalTime < r.fastest) then
			r.fastest = c.goalTime
		end
		if c.won then
			r.wins = r.wins + 1
		end
	end
	return r
end

local RefreshPage -- set by the page below

-- The contest's result: what came in, how fast 40 came, and any record broken. Nil if you
-- didn't fish it.
function X.SummaryText(c)
	if not (c and (c.catches or 0) > 0) then
		return nil
	end
	local parts = { string.format("%d Tastyfish", c.caught or 0) }
	for _, rare in ipairs(X.RARE_ORDER) do
		local n = c.rares and c.rares[rare[1]]
		if n and n > 0 then
			parts[#parts + 1] = ItemName(rare[1], rare[2])
		end
	end
	local text = table.concat(parts, ", ")
	if c.goalTime then
		text = text .. string.format("; 40 in %s", X.FormatWait(c.goalTime))
	end
	if c.won then
		text = text .. "; you won"
	end
	local r = X.Records()
	local news = {}
	if (c.caught or 0) > r.best then
		news[#news + 1] = "best haul"
	end
	if c.goalTime and r.fastest and c.goalTime < r.fastest then
		news[#news + 1] = "fastest 40"
	end
	if #news > 0 then
		text = text .. ". New record: " .. table.concat(news, " and ")
	end
	return text .. "."
end

-- Into the history, newest first, if there's anything to keep.
local function Finish(c)
	local s = Store()
	if not s then
		return
	end
	if c and ((c.catches or 0) > 0 or c.won) then
		table.insert(s.history, 1, { start = c.start, caught = c.caught or 0, catches = c.catches or 0,
			goalTime = c.goalTime, won = c.won and true or nil, rares = c.rares })
		while #s.history > HISTORY do
			table.remove(s.history)
		end
	end
	if s.current == c then
		s.current = nil
	end
end

-- This contest's record, started the first time it's needed while the contest runs. The bags'
-- coins and poles are counted at the start, so one arriving later is a win.
local function EnsureCurrent()
	local s = Store()
	local start, _, running = LatestStart()
	if not (s and start and running) then
		return nil
	end
	local c = s.current
	if c and c.start ~= start then
		Finish(c)
		c = nil
	end
	if not c then
		c = { start = start, caught = 0, catches = 0, rares = {}, winners = 0,
			coins = ns.ItemCount(X.COIN), poles = ns.ItemCount(X.POLE) }
		s.current = c
	end
	return c
end

-- Tastyfish an hour this contest, from the first one to now, once there are a few to go by.
function X.Pace()
	local c = X.Current()
	if not (c and c.firstFish and (c.caught or 0) >= 3) then
		return nil
	end
	local span = GetServerTime() - c.firstFish
	if span < 300 then
		return nil
	end
	return (c.caught - 1) / span * 3600
end

-- Whether 40 comes in time: "ready" (you hold 40), "ahead" with the seconds 40 will take at your
-- pace, or "behind" with the pace 40 would need. Nil while it isn't running or there's no pace.
function X.Forecast()
	local running, left = X.Status()
	if not running then
		return nil
	end
	local c = X.Current()
	if c and c.won then
		return "won"
	end
	local need = X.GOAL - X.TastyfishInBags()
	if need <= 0 then
		return "ready"
	end
	local rate = X.Pace()
	if not rate or rate <= 0 then
		return nil
	end
	local eta = need / rate * 3600
	if eta <= left then
		return "ahead", eta
	end
	return "behind", need / left * 3600
end

-- The forecast in words, for the mini bar and the stats window.
function X.PaceLine()
	local kind, value = X.Forecast()
	if kind == "won" then
		return "|cff20ff20won this week|r"
	elseif kind == "ready" then
		return "|cff20ff20hand them to Riggle in Booty Bay|r"
	elseif kind == "ahead" then
		return string.format("|cff20ff20ahead|r, 40 in about %s", X.FormatWait(value))
	elseif kind == "behind" then
		return string.format("|cffff8040behind|r, 40 needs %.0f/hr", value)
	end
end

-- One line for the mini bar and the minimap tooltip, or nil when the contest isn't worth
-- mentioning: shown while it runs, in Stranglethorn Vale, or in the last few hours before it.
function X.StatusLine(zone)
	local running, seconds = X.Status()
	if running == nil then
		return nil
	end
	if running then
		return string.format("Tastyfish %d/%d  ·  |cff9d9d9d%s left|r", X.TastyfishInBags(), X.GOAL, X.FormatWait(seconds))
	end
	if zone == X.ZONE or seconds <= 3 * 3600 then
		return "starts in " .. X.FormatWait(seconds)
	end
end

-- The stats window's rows, one fact each: { label, value }.
function X.StatusRows(zone)
	local running, seconds = X.Status()
	if running == nil then
		return {}
	end
	if not running then
		local line = X.StatusLine(zone)
		return line and { { "Extravaganza", line } } or {}
	end
	local rows = { { "Tastyfish", string.format("%d/%d", X.TastyfishInBags(), X.GOAL) } }
	local pace = X.PaceLine()
	if pace then
		rows[#rows + 1] = { "Race", pace }
	end
	rows[#rows + 1] = { "Contest ends", "in " .. X.FormatWait(seconds) }
	return rows
end

-- A sentence for the fish's page in the book: when it bites, and what it's handed in for.
function X.Describe(fishID)
	local running, seconds = X.Status()
	local text = "Bites only during the Stranglethorn Fishing Extravaganza, " .. X.SCHEDULE .. "."
	local rare = fishID and X.RARE[fishID]
	if rare then
		text = text .. " Fishbot 5000 in Booty Bay trades it for " .. ItemName(rare[1], rare[2]) .. "."
	elseif fishID == X.TASTYFISH then
		text = text .. string.format(" The first %d on your ruleset to bring Riggle Bassbait %d win the Arcanite Fishing Pole and a coin for one of Jang's prizes; Jang buys any you have left in fives.", X.WINNERS, X.GOAL)
	end
	if running then
		return text .. " It's on now: " .. X.FormatWait(seconds) .. " left."
	elseif running == false then
		return text .. " Next contest in " .. X.FormatWait(seconds) .. "."
	end
	return text
end

-- A waypoint to the Booty Bay dock, where Riggle Bassbait takes the Tastyfish (Fishbot 5000 and
-- Jang stand with him), without opening the map: the arrow points the way. Classic's spot.
X.RIGGLE = { x = 0.276, y = 0.776 }
function X.Waypoint()
	if InCombatLockdown() or not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then
		return false
	end
	local mapID = ns.Book and ns.Book.ZoneMapID and ns.Book.ZoneMapID(X.ZONE)
	if not mapID or (C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(mapID)) then
		return false
	end
	local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(mapID, X.RIGGLE.x, X.RIGGLE.y))
	if ok and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
		pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
	end
	if ok then
		ns.Print("waypoint set: Riggle Bassbait, Booty Bay.")
	end
	return ok
end

-- Whether you have an item: in the bags or bank, worn, or learned (a toy, a pet, an appearance).
function X.Owned(itemID)
	local count = C_Item.GetItemCount and C_Item.GetItemCount(itemID, true) or 0
	if (tonumber(count) or 0) > 0 then
		return true
	end
	if C_Item.IsEquippedItem and C_Item.IsEquippedItem(itemID) == true then
		return true
	end
	if PlayerHasToy and PlayerHasToy(itemID) == true then
		return true
	end
	local pets = C_PetJournal
	if pets and pets.GetPetInfoByItemID and pets.GetNumCollectedInfo then
		local species = select(13, pets.GetPetInfoByItemID(itemID))
		local owned = species and pets.GetNumCollectedInfo(species)
		if (tonumber(owned) or 0) > 0 then
			return true
		end
	end
	local looks = C_TransmogCollection
	if looks and looks.PlayerHasTransmog and looks.PlayerHasTransmog(itemID) == true then
		return true
	end
	return false
end

local function FreeBagSlots()
	local free = 0
	for bag = 0, NUM_BAG_SLOTS or 4 do
		local slots, family = C_Container.GetContainerNumFreeSlots(bag)
		if (family or 0) == 0 then
			free = free + (slots or 0)
		end
	end
	return free
end

-- The best lure in the bags you can use, whatever the tackle box is set to.
local function BestLure()
	local best
	for _, lure in ipairs(ns.Lure and ns.Lure.LIST or {}) do
		if ns.Lure.Count(lure) > 0 and ns.Lure.SkillOK(lure) and (not best or lure.bonus > best.bonus) then
			best = lure
		end
	end
	return best
end

-- Before the contest: { label, value, ok, tip } a row. `ok` is true (ready), false (a problem)
-- or nil (worth having, not needed).
function X.Checklist()
	local rows = {}
	local G, R, GREY = "|cff20ff20", "|cffff4040", "|cff9d9d9d"
	-- Fishing for Stranglethorn, with what you wear and any lure or food already on.
	local rank, _, modifier = ns.Stats.FishingSkill()
	local needed = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[X.ZONE]
	if not rank then
		rows[#rows + 1] = { "Fishing", GREY .. "not learned|r", false, "Learn Fishing from a trainer first." }
	elseif needed then
		local effective = rank + (modifier or 0)
		local ok = effective >= needed
		rows[#rows + 1] = { "Fishing", string.format("%s%d|r of %d", ok and G or R, effective, needed), ok,
			string.format("Stranglethorn's waters need %d Fishing to keep every catch. Yours is %d, with your gear and anything on you now.", needed, effective) }
	else
		rows[#rows + 1] = { "Fishing", tostring(rank + (modifier or 0)), nil, "Your Fishing, with your gear and anything on you now." }
	end
	-- A pole.
	local poles = ns.Gear and ns.Gear.Poles and ns.Gear.Poles() or {}
	local worn = poles[1] and poles[1].worn
	rows[#rows + 1] = { "Fishing pole", #poles == 0 and (R .. "none|r") or (G .. (worn and "in hand" or "in your bags") .. "|r"),
		#poles > 0, "A fishing pole, worn or in your bags: OneCast puts it on when you cast." }
	-- Lures: they last 10 minutes, so a contest takes about a dozen.
	local left = ns.Lure and ns.Lure.Left() or 0
	local best = BestLure()
	local count = best and ns.Lure.Count(best) or 0
	if best then
		rows[#rows + 1] = { "Lures", string.format("%s%d|r %s", count >= 12 and G or "|cffffd100", count, ns.Lure.Name(best)), count >= 12 or nil,
			"Lures last about 10 minutes: the two hours take about 12." }
	else
		rows[#rows + 1] = { "Lures", left > 0 and (G .. "one on now|r") or (R .. "none in your bags|r"), left > 0 and nil or false,
			"Lures last about 10 minutes: the two hours take about 12. A lure raises your Fishing and catches come quicker." }
	end
	-- Fishing food.
	local food = ns.Food and ns.Food.Best()
	local active = ns.Food and ns.Food.Active()
	if active then
		rows[#rows + 1] = { "Fishing food", G .. "Well Fed now|r", true, "Fishing food's bonus lasts 15 minutes." }
	elseif food then
		rows[#rows + 1] = { "Fishing food", string.format("%s%d|r %s", G, ns.Food.Count(food), ns.Food.Name(food)), true,
			string.format("+%d Fishing for 15 minutes. Eat it when the contest starts.", food[2]) }
	else
		rows[#rows + 1] = { "Fishing food", GREY .. "none|r", nil, "Fishing food raises your Fishing for 15 minutes. Not needed, but it helps." }
	end
	-- Room for the catch.
	local free = FreeBagSlots()
	rows[#rows + 1] = { "Bag space", string.format("%s%d|r free", free >= BAG_ROOM and G or R, free), free >= BAG_ROOM,
		string.format("40 Tastyfish and the rest of the catch: keep at least %d slots free.", BAG_ROOM) }
	return rows
end

-- Where Tastyfish have bitten for this character in Stranglethorn: { name, count, rate, spot }
-- a spot, best per hour first.
function X.Spots()
	local charDB = OneCastCharDB
	local z = charDB and charDB.zoneStats and charDB.zoneStats[X.ZONE]
	local list = {}
	for name, t in pairs(z and z.spots or {}) do
		local item = t.items and t.items[X.TASTYFISH]
		if item and item.count > 0 then
			local rate = (t.activeTime or 0) >= 300 and item.count / t.activeTime * 3600 or nil
			list[#list + 1] = { name = name, count = item.count, rate = rate, spot = t }
		end
	end
	table.sort(list, function(a, b)
		if (a.rate or -1) ~= (b.rate or -1) then
			return (a.rate or -1) > (b.rate or -1)
		end
		return a.count > b.count
	end)
	return list
end

-- Won: say so once, and stop the race's alerts.
local announcedGoal, lastCall = false, false
local bagWatch = CreateFrame("Frame")
local function Won()
	local c = X.Current()
	if not c or c.won then
		return
	end
	c.won = GetServerTime()
	announcedGoal = true
	bagWatch:UnregisterEvent("BAG_UPDATE_DELAYED")
	ns.Print("you're a Master Angler! Take your Extravagant Extravaganza Coin to Jang in Booty Bay for one of her prizes.")
	if RefreshPage then
		RefreshPage()
	end
end

-- A coin or the pole arriving since the contest started.
local function CheckWin()
	local c = X.Current()
	if c and not c.won and ((c.coins and ns.ItemCount(X.COIN) > c.coins) or (c.poles and ns.ItemCount(X.POLE) > c.poles)) then
		Won()
	end
end

-- The moment you hold 40 Tastyfish during the contest, say where to go. Checked when the bags
-- change rather than at the catch, since the fish isn't in the bags until it's looted.
local function CheckGoal()
	CheckWin()
	local c = X.Current()
	if c and not c.goalAt and X.Status() and X.TastyfishInBags() >= X.GOAL then
		c.goalAt = GetServerTime()
		c.goalTime = c.first and math.max(0, c.goalAt - c.first) or nil
	end
	if announcedGoal or not Reminders() or not X.Status() or X.TastyfishInBags() < X.GOAL or (c and c.won) then
		return
	end
	announcedGoal = true
	ns.Print(string.format("%d %s! Hand them to Riggle Bassbait in Booty Bay: the first %d win the Arcanite Fishing Pole and a coin for one of Jang's prizes.", X.GOAL, Tastyfish(), X.WINNERS))
	ns.RaidWarning(X.GOAL .. " Tastyfish: hurry to Booty Bay!")
	PlaySound(SOUNDKIT.RAID_WARNING)
	X.Waypoint()
end
bagWatch:SetScript("OnEvent", function()
	CheckGoal()
	if RefreshPage then
		RefreshPage()
	end
end)

-- Called by Stats.lua after a catch: this contest's tally, and the bags watched once a
-- Tastyfish bites.
function X.OnCatch(loot)
	if not X.Status() then
		return
	end
	local c = EnsureCurrent()
	if not c then
		return
	end
	local now = GetServerTime()
	c.catches = c.catches + 1
	c.first = c.first or now
	for _, l in ipairs(loot) do
		local n = l.quantity or 1
		if l.id == X.TASTYFISH then
			c.caught = c.caught + n
			c.firstFish = c.firstFish or now
			if Reminders() and not announcedGoal and not c.won then
				bagWatch:RegisterEvent("BAG_UPDATE_DELAYED")
			end
		elseif X.RARE[l.id] then
			c.rares[l.id] = (c.rares[l.id] or 0) + n
			if Reminders() then
				local prize = X.RARE[l.id]
				ns.Print(string.format("%s! Fishbot 5000 in Booty Bay trades it for %s, today only.",
					ns.ItemLink(l.id, "a rare fish"), ns.ItemLink(prize[1], prize[2])))
			end
		end
	end
	if RefreshPage then
		RefreshPage()
	end
end

-- What's missing before the contest, in a few words each, or nil if nothing is.
function X.Missing()
	local missing = {}
	for _, row in ipairs(X.Checklist()) do
		if row[3] == false then
			missing[#missing + 1] = row[1]:lower() .. " (" .. row[2]:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") .. ")"
		end
	end
	return #missing > 0 and table.concat(missing, ", ") or nil
end

-- Chat reminders: the checklist an hour before, shortly before the start, at the start, once at
-- login while it runs, and with 40 in the bags near the end. The result when it ends.
local wasRunning, remindedSoon, remindedReady
local function Tick()
	local running, seconds = X.Status()
	if running == nil then
		return
	end
	local s = Store()
	if running then
		EnsureCurrent()
		CheckGoal()
	else
		CheckWin()
	end
	local c = X.Current()
	-- The contest has ended: its result now, into the history after the hour for wins.
	if not running and s and s.current and s.current ~= c then
		Finish(s.current)
	end
	if not running then
		announcedGoal, lastCall = false, false
		bagWatch:UnregisterEvent("BAG_UPDATE_DELAYED")
	end
	if not Reminders() then
		wasRunning = running
		return
	end
	if running and not wasRunning and not (c and c.won) then
		ns.Print(string.format("the Stranglethorn Fishing Extravaganza is on%s! Catch %d %s in Stranglethorn Vale and hand them to Riggle Bassbait in Booty Bay.",
			wasRunning == nil and (" (" .. X.FormatWait(seconds) .. " left)") or "", X.GOAL, Tastyfish()))
	elseif not running and wasRunning and c and not c.summarized then
		c.summarized = true
		local summary = X.SummaryText(c)
		if summary then
			ns.Print("the Extravaganza is over: " .. summary)
		end
	elseif running and seconds <= LAST_CALL and not lastCall and not (c and c.won) and X.TastyfishInBags() >= X.GOAL then
		lastCall = true
		ns.Print(string.format("%s left: hand your %d Tastyfish to Riggle Bassbait before it ends.", X.FormatWait(seconds), X.GOAL))
	elseif not running and seconds <= READY_BEFORE and seconds > REMIND_BEFORE and not remindedReady then
		remindedReady = true
		local missing = X.Missing()
		ns.Print("the Stranglethorn Fishing Extravaganza starts in " .. X.FormatWait(seconds)
			.. (missing and (". Before you go: " .. missing .. ".") or ": you're ready."))
	elseif not running and seconds <= REMIND_BEFORE and not remindedSoon then
		remindedSoon = true
		ns.Print("the Stranglethorn Fishing Extravaganza starts in " .. X.FormatWait(seconds) .. ".")
	end
	if not running and seconds > READY_BEFORE then
		remindedSoon, remindedReady = false, false
	end
	wasRunning = running
	if RefreshPage then
		RefreshPage()
	end
end
X.Tick = Tick

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
ns.RegisterAnyEvent(events, { "QUEST_TURNED_IN" })
ns.RegisterAnyEvent(events, { "CHAT_MSG_MONSTER_YELL" })
events:SetScript("OnEvent", function(_, event, a, b)
	if event == "PLAYER_LOGIN" then
		-- Give the login chat a moment, then check every 30 seconds.
		C_Timer.After(6, function()
			Tick()
			C_Timer.NewTicker(30, Tick)
		end)
	elseif event == "QUEST_TURNED_IN" then
		if a == X.QUEST then
			Won()
		else
			CheckWin()
		end
	elseif event == "CHAT_MSG_MONSTER_YELL" then
		-- Riggle naming a winner, in Classic's words.
		local c = X.Current()
		if c and b == X.RIGGLE_NAME and type(a) == "string" and a:lower():find("winner", 1, true) then
			c.winners = (c.winners or 0) + 1
			if RefreshPage then
				RefreshPage()
			end
		end
	end
end)

---------------------------------------------------------------------------------------------
-- The Extravaganza page: this week's contest, the race, getting ready and where they bite on
-- the left; the rare fish, Jang's prizes and your contests on the right.

local PAGE_WIDTH, EDGE, GAP, PAD = 660, 10, 8, 10
local HEADER = 24
local ROW = 20
local GREY, GOOD, BAD, GOLD = "|cff9d9d9d", "|cff20ff20", "|cffff4040", "|cffffd100"
local page

local function Text(parent, font)
	local fs = parent:CreateFontString(nil, "OVERLAY", font or "OneCastFontHighlightSmall")
	fs:SetJustifyH("LEFT")
	page.strings[#page.strings + 1] = fs
	return fs
end

local function Icon(parent, size)
	local icon = parent:CreateTexture(nil, "ARTWORK")
	icon:SetSize(size, size)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	return icon
end

local function ItemIcon(itemID)
	return C_Item.GetItemIconByID(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function Place(region, parent, y, height)
	region:ClearAllPoints()
	region:SetPoint("TOPLEFT", parent, "TOPLEFT", EDGE, -y)
	region:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -EDGE, -y)
	if height then
		region:SetHeight(height)
	end
end

local function PlaceHeader(header, y)
	Place(header, header:GetParent(), y)
	return y + HEADER + 4
end

-- A shaded line: a label at the left, its value at the right, a tooltip, and a click if given.
local function LineRow(parent, index, onClick)
	local row = CreateFrame(onClick and "Button" or "Frame", nil, parent)
	row:SetHeight(ROW)
	ns.UI.RowBackground(row, index)
	row.icon = Icon(row, 16)
	row.icon:SetPoint("LEFT", 4, 0)
	row.label = Text(row)
	row.label:SetPoint("LEFT", PAD, 0)
	row.value = Text(row)
	row.value:SetPoint("RIGHT", -PAD, 0)
	row.value:SetJustifyH("RIGHT")
	row.icon:Hide()
	if onClick then
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row:SetScript("OnClick", onClick)
	end
	row:EnableMouse(true)
	row:SetScript("OnEnter", function(self)
		if not (self.tip or self.item) then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.item then
			GameTooltip:SetItemByID(self.item)
			if self.tip then
				GameTooltip:AddLine(" ")
			end
		else
			GameTooltip:SetText(self.label:GetText() or "", 1, 0.82, 0)
		end
		if self.tip then
			GameTooltip:AddLine(self.tip, 1, 1, 1, true)
		end
		if self.click then
			GameTooltip:AddLine(self.click, 0.6, 0.8, 1, true)
		end
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", GameTooltip_Hide)
	page.hovers[#page.hovers + 1] = row
	return row
end

-- Sets a row's words, with an icon pushing the label right when there is one.
local function SetRow(row, label, value, icon)
	row.label:SetText(label)
	row.value:SetText(value or "")
	row.label:ClearAllPoints()
	if icon then
		row.icon:SetTexture(icon)
		row.icon:Show()
		row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	else
		row.icon:Hide()
		row.label:SetPoint("LEFT", PAD, 0)
	end
end

local function Rows(list, parent, n, onClick)
	for i = 1, n do
		list[i] = LineRow(parent, i, onClick)
	end
	return list
end

local function BoothWaypoint()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	if not X.Waypoint() then
		ns.Print("couldn't set a waypoint here.")
	end
end

local function Paint()
	local f = page
	if not (f and f:IsShown()) then
		return
	end
	local width = f.left:GetWidth()
	width = (width and width > 0 and width or (PAGE_WIDTH - 10) / 2) - 2 * EDGE
	local running, seconds = X.Status()
	local c = X.Current()
	local bags = X.TastyfishInBags()

	-- Left: this week's contest.
	local L = f.left
	local y = PlaceHeader(f.weekHeader, GAP)
	f.weekHeader.waypoint:SetLabel(nil, "Waypoint: Booty Bay")
	local card = f.week
	local title, sub, color
	if running == nil then
		title, sub, color = "Sundays, 14:00 to 16:00", "Realm time isn't known yet.", { 0.5, 0.5, 0.5 }
	elseif c and c.won then
		title, sub, color = GOOD .. "You won this week|r",
			"You're a Master Angler. Trade your Extravagant Extravaganza Coin with Jang in Booty Bay.", { 0.12, 1, 0 }
	elseif running then
		title, sub, color = GOOD .. "On now|r  " .. GREY .. "·|r  " .. X.FormatWait(seconds) .. " left",
			string.format("Catch %d Speckled Tastyfish in Stranglethorn Vale and bring them to Riggle Bassbait in Booty Bay. The first %d win.", X.GOAL, X.WINNERS),
			{ 0.12, 1, 0 }
	else
		title, sub = "Starts in " .. X.FormatWait(seconds), "Sundays, 14:00 to 16:00 realm time, in Stranglethorn Vale."
		color = seconds <= 3 * 3600 and { 1, 0.82, 0 } or { 0.5, 0.5, 0.5 }
	end
	card:SetColor(color[1], color[2], color[3], running and 0.16 or 0.1)
	card.icon:SetTexture(ItemIcon(X.TASTYFISH))
	card.title:SetText(title)
	card.sub:SetText(sub)
	card.sub:SetWidth(width - 12 - 34 - 10 - PAD)
	local h = 8 + math.max(34, (card.title:GetStringHeight() or 13) + 4 + (card.sub:GetStringHeight() or 12)) + 8
	Place(card, L, y, h)
	y = y + h + GAP

	-- The race: Tastyfish in the bags against 40, then this contest's numbers. Between contests,
	-- the last one's.
	local last = not c and X.History()[1]
	f.raceHeader.text:SetText((running or not (c or last)) and "The race" or (c and "This contest") or "Last contest")
	y = PlaceHeader(f.raceHeader, y)
	local bar = f.bar
	local inBags = running or not (c or last)
	local shown = inBags and bags or (c and c.caught) or (last and last.caught) or 0
	bar:SetValue(math.min(shown, X.GOAL) / X.GOAL)
	local done = shown >= X.GOAL
	bar:SetStatusBarColor(done and 0.12 or 1, done and 0.8 or 0.7, done and 0.1 or 0)
	bar.text:SetText(string.format("%d/%d %s", math.min(shown, 999), X.GOAL,
		inBags and "Tastyfish in your bags" or "Tastyfish caught"))
	Place(bar.holder, L, y, 22)
	y = y + 22 + 4
	local lines = {}
	if running or c then
		lines[#lines + 1] = { "Caught this contest", tostring(c and c.caught or 0),
			"Speckled Tastyfish you've caught since it started." }
		local pace = X.Pace()
		if running then
			lines[#lines + 1] = { "Pace", pace and string.format("%.0f an hour", pace) or (GREY .. "after a few Tastyfish|r"),
				"Tastyfish an hour, from your first this contest." }
			lines[#lines + 1] = { "Forecast", X.PaceLine() or (GREY .. "after a few Tastyfish|r"),
				"Whether 40 comes before the end, at your pace." }
		end
		if c and c.goalTime then
			lines[#lines + 1] = { "40 reached in", X.FormatWait(c.goalTime), "From your first catch this contest." }
		end
		if c and (c.winners or 0) > 0 then
			lines[#lines + 1] = { "Winners heard", tostring(c.winners), "Winners Riggle Bassbait has announced where you could hear him." }
		end
	elseif last then
		lines[#lines + 1] = { "When", date("%d %b", last.start), "The day of your last contest." }
		lines[#lines + 1] = { "40 reached in", last.goalTime and X.FormatWait(last.goalTime) or (GREY .. "not reached|r"),
			"From your first catch that contest." }
		lines[#lines + 1] = { "Result", last.won and (GOOD .. "won|r") or (GREY .. "no prize|r"), "Whether you won the Arcanite Fishing Pole." }
	end
	for i, row in ipairs(f.race) do
		local line = lines[i]
		row:SetShown(line ~= nil)
		if line then
			SetRow(row, line[1], line[2])
			row.tip = line[3]
			Place(row, L, y, ROW)
			y = y + ROW
		end
	end
	f.raceNote:SetShown(#lines == 0)
	if #lines == 0 then
		f.raceNote:SetText("Your Tastyfish, pace and result show here when you fish a contest.")
		f.raceNote:SetWidth(width - 8)
		f.raceNote:ClearAllPoints()
		f.raceNote:SetPoint("TOPLEFT", L, "TOPLEFT", EDGE + 4, -y - 2)
		y = y + (f.raceNote:GetStringHeight() or 12) + 6
	end
	y = y + GAP

	-- Getting ready, or where they bite once it's on.
	y = PlaceHeader(f.readyHeader, y)
	for i, line in ipairs(X.Checklist()) do
		local row = f.ready[i]
		if row then
			local mark = line[3] == true and "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t "
				or line[3] == false and "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14|t "
				or "|TInterface\\RaidFrame\\ReadyCheck-Waiting:14:14|t "
			SetRow(row, mark .. line[1], line[2])
			row.tip = line[4]
			Place(row, L, y, ROW)
			y = y + ROW
		end
	end
	y = y + GAP

	y = PlaceHeader(f.spotsHeader, y)
	local spots = X.Spots()
	for i, row in ipairs(f.spots) do
		local spot = spots[i]
		row:SetShown(spot ~= nil)
		if spot then
			SetRow(row, spot.name, spot.rate and string.format("%.0f/hr", spot.rate) or (spot.count .. " caught"))
			row.tip = string.format("%d Tastyfish caught here.", spot.count)
			row.where = spot.spot.mapID and spot.spot.x and spot.spot
			row.click = row.where and "Click: show it on the map."
			Place(row, L, y, ROW)
			y = y + ROW
		end
	end
	f.spotsNote:SetShown(#spots == 0)
	if #spots == 0 then
		f.spotsNote:SetText("None caught yet. They bite from schools along Stranglethorn's coasts during the contest: your best spots show here, from your own catches.")
		f.spotsNote:SetWidth(width - 8)
		f.spotsNote:ClearAllPoints()
		f.spotsNote:SetPoint("TOPLEFT", L, "TOPLEFT", EDGE + 4, -y - 2)
	end

	-- Right: the rare fish, Fishbot 5000's trades.
	local R = f.right
	y = PlaceHeader(f.rareHeader, GAP)
	for i, rare in ipairs(X.RARE_ORDER) do
		local row = f.rares[i]
		local id = rare[1]
		local prize = X.RARE[id]
		local caught = ns.Collection and ns.Collection.Get(id).total or 0
		local today = c and c.rares and c.rares[id] or 0
		local have = X.Owned(prize[1])
		row:SetColor(have and 0.12 or 1, have and 1 or 0.82, have and 0 or 0, have and 0.08 or (today > 0 and 0.16 or 0.06))
		row.icon:SetTexture(ItemIcon(id))
		row.name:SetText(ItemName(id, rare[2]))
		row.caught:SetText(today > 0 and (GOOD .. today .. " today|r") or caught > 0 and (GREY .. "caught " .. caught .. "|r") or (GREY .. "not caught|r"))
		row.prize:SetText(GREY .. "For|r " .. ItemName(prize[1], prize[2])
			.. (have and " |TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t" or ""))
		row.item = id
		row.tip = string.format("Fishbot 5000 in Booty Bay trades it for %s, during the contest.%s", ItemName(prize[1], prize[2]),
			have and " You have it." or "")
		row:SetIndex(i)
		Place(row, R, y, 40)
		y = y + 40
	end
	y = y + GAP

	-- Jang's prizes, a coin each.
	local coins = ns.ItemCount(X.COIN)
	f.jangHeader.text:SetText("Jang's prizes  " .. GREY .. "(a coin each)|r")
	y = PlaceHeader(f.jangHeader, y)
	SetRow(f.coin, ItemName(X.COIN, "Extravagant Extravaganza Coin"), coins > 0 and (GOLD .. coins .. "|r") or (GREY .. "none|r"), ItemIcon(X.COIN))
	f.coin.item = X.COIN
	f.coin.tip = "Winners get one. Jang in Booty Bay trades it for any one of her prizes."
	Place(f.coin, R, y, ROW)
	y = y + ROW
	for i, prize in ipairs(X.JANG) do
		local row = f.jang[i]
		local have = X.Owned(prize[1])
		SetRow(row, ItemName(prize[1], prize[2]), have and (GOOD .. "have it|r") or "", ItemIcon(prize[1]))
		row.item = prize[1]
		row.tip = nil
		Place(row, R, y, ROW)
		y = y + ROW
	end
	y = y + GAP

	-- Your contests.
	local r = X.Records()
	y = PlaceHeader(f.recordsHeader, y)
	local facts = {
		{ "Contests fished", tostring(r.contests), "Contests you caught something in, of the last " .. HISTORY .. "." },
		{ "Best haul", r.best > 0 and (r.best .. " Tastyfish") or (GREY .. "-|r"), "The most Tastyfish you've caught in one contest." },
		{ "Fastest 40", r.fastest and X.FormatWait(r.fastest) or (GREY .. "-|r"), "Your quickest 40 Tastyfish, from your first catch." },
		{ "Wins", tostring(r.wins), "Contests you've won the Arcanite Fishing Pole in." },
	}
	for i, row in ipairs(f.records) do
		local fact = facts[i]
		SetRow(row, fact[1], fact[2])
		row.tip = fact[3]
		Place(row, R, y, ROW)
		y = y + ROW
	end
end
X.PaintPage = Paint

-- Repaints at most twice a second: catches, bags and the clock all ask.
local pending = false
RefreshPage = function()
	if not (page and page:IsShown()) or pending then
		return
	end
	pending = true
	C_Timer.After(0.5, function()
		pending = false
		Paint()
	end)
end

local function CreatePage()
	local UI = ns.UI
	local f, inset = UI.CreateShell("OneCastContestFrame", "Fishing Extravaganza", ItemIcon(X.TASTYFISH))
	page = f
	f.strings, f.hovers = {}, {}
	f:SetSize(PAGE_WIDTH, UI.PAGE_HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	UI.RememberPosition(f, "contest")

	f.left = CreateFrame("Frame", nil, inset)
	f.left:SetPoint("TOPLEFT")
	f.left:SetPoint("BOTTOMRIGHT", inset, "BOTTOM", 0, 0)
	f.right = CreateFrame("Frame", nil, inset)
	f.right:SetPoint("TOPLEFT", inset, "TOP", 0, 0)
	f.right:SetPoint("BOTTOMRIGHT")
	local L, R = f.left, f.right

	f.weekHeader = UI.SectionHeader(L, -GAP)
	f.weekHeader.text:SetText("This week")
	local waypoint = UI.HeaderButton(f.weekHeader)
	waypoint:SetPoint("RIGHT", -4, 0)
	waypoint:SetScript("OnClick", BoothWaypoint)
	waypoint:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Waypoint: Booty Bay", 1, 0.82, 0)
		GameTooltip:AddLine("Riggle Bassbait takes the Tastyfish on the dock; Fishbot 5000 and Jang are with him.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	waypoint:SetScript("OnLeave", GameTooltip_Hide)
	f.weekHeader.waypoint = waypoint
	local week = UI.Card(L)
	week.icon = Icon(week, 34)
	week.icon:SetPoint("TOPLEFT", 12, -8)
	week.title = Text(week, "GameFontHighlight")
	week.title:SetPoint("TOPLEFT", week.icon, "TOPRIGHT", 10, -1)
	week.sub = Text(week)
	week.sub:SetTextColor(0.78, 0.78, 0.78)
	week.sub:SetPoint("TOPLEFT", week.title, "BOTTOMLEFT", 0, -4)
	week.sub:SetWordWrap(true)
	f.week = week

	f.raceHeader = UI.SectionHeader(L, -GAP)
	local holder = CreateFrame("Frame", nil, L, "BackdropTemplate")
	if holder.SetBackdrop then
		holder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		holder:SetBackdropColor(0.02, 0.02, 0.03, 0.9)
		holder:SetBackdropBorderColor(0.55, 0.55, 0.58, 1)
	end
	local bar = CreateFrame("StatusBar", nil, holder)
	bar:SetPoint("TOPLEFT", 2, -2)
	bar:SetPoint("BOTTOMRIGHT", -2, 2)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar.text = Text(bar, "GameFontHighlightSmall")
	bar.text:SetPoint("CENTER", 0, 0)
	bar.text:SetJustifyH("CENTER")
	bar.holder = holder
	f.bar = bar
	f.race = Rows({}, L, 5)
	f.raceNote = Text(L)
	f.raceNote:SetTextColor(0.66, 0.66, 0.66)
	f.raceNote:SetWordWrap(true)

	f.readyHeader = UI.SectionHeader(L, -GAP)
	f.readyHeader.text:SetText("Get ready")
	f.ready = Rows({}, L, 5)

	f.spotsHeader = UI.SectionHeader(L, -GAP)
	f.spotsHeader.text:SetText("Where they bite for you")
	f.spots = Rows({}, L, 4, function(self)
		local w = self.where
		if w then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			ns.UI.ShowOnMap(w.mapID, w.x, w.y, self.label:GetText())
		end
	end)
	f.spotsNote = Text(L)
	f.spotsNote:SetTextColor(0.66, 0.66, 0.66)
	f.spotsNote:SetWordWrap(true)

	f.rareHeader = UI.SectionHeader(R, -GAP)
	f.rareHeader.text:SetText("Rare fish  " .. GREY .. "(Fishbot 5000)|r")
	f.rares = {}
	for i = 1, #X.RARE_ORDER do
		local row = UI.Card(R, "Button")
		row.icon = Icon(row, 28)
		row.icon:SetPoint("LEFT", 10, 0)
		row.name = Text(row)
		row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0)
		row.caught = Text(row)
		row.caught:SetPoint("TOPRIGHT", -PAD, -6)
		row.caught:SetJustifyH("RIGHT")
		row.prize = Text(row)
		row.prize:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 0)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row:SetScript("OnClick", BoothWaypoint)
		row:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetItemByID(self.item)
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(self.tip, 1, 1, 1, true)
			GameTooltip:AddLine("Click: a waypoint to Booty Bay.", 0.6, 0.8, 1)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", GameTooltip_Hide)
		page.hovers[#page.hovers + 1] = row
		f.rares[i] = row
	end

	f.jangHeader = UI.SectionHeader(R, -GAP)
	f.coin = LineRow(R, 1)
	f.jang = {}
	for i = 1, #X.JANG do
		f.jang[i] = LineRow(R, i + 1)
	end

	f.recordsHeader = UI.SectionHeader(R, -GAP)
	f.recordsHeader.text:SetText("Your contests")
	f.records = Rows({}, R, 4)

	-- The clock and the bags change while it's open.
	local since = 0
	f:SetScript("OnUpdate", function(_, elapsed)
		since = since + elapsed
		if since >= 5 then
			since = 0
			Paint()
		end
	end)
	f:SetScript("OnShow", Paint)
	f:Hide()
	ns.Hub.Attach("contest", f)
	return f
end

-- The Extravaganza page, from the window's tab or /onecast contest.
function X.ShowPage()
	page = page or CreatePage()
	page:Show()
	Paint()
end

function X.Page()
	return page
end
