-- OneCast's Fisherman's Journey: the four Fishing ranks, where you stand, and what's next.
-- Each rank's cap, whether you have it, how and where to learn it (with a waypoint), what it
-- needs, and where to fish while you're at it.
--
-- From Forever's game data (wago.tools, 13 November 2026): the ranks are Classic's
-- (Apprentice 75, Journeyman 150, Expert 225, Artisan 300); Expert is learned from "Expert
-- Fishing - The Bass and You" (level 20, Fishing 125, 1 gold), sold in Stranglethorn Vale by Old
-- Man Heming <Fisherman> (Wowhead's Forever data); Artisan is Nat Pagle's quest "Nat Pagle,
-- Angler Extreme" in Dustwallow Marsh, for one each of four special fish. What Forever's data
-- doesn't hold (trainers and quests are the server's) is Classic's, from CMaNGOS's world
-- database: trainers teach Apprentice at level 5 for 1 silver and Journeyman at Fishing 50 for
-- 5 silver, with no level; Nat's quest needs level 35 and Fishing 225. The waypoints are
-- Classic's spots for Heming and Nat.

local _, ns = ...

local Journey = {}
ns.Journey = Journey

local WIDTH = 660
local EDGE, GAP = 10, 8
local CARD_HEIGHT = 98
local GOOD, GREY, GOLD = "|cff1eff00", "|cff9d9d9d", "|cffffd100"

-- Nat Pagle's four fish, for Artisan.
local NAT_FISH = { 16970, 16968, 16967, 16969 }

Journey.RANKS = {
	{ key = "apprentice", name = "Apprentice", cap = 75, from = 1, icon = "Interface\\Icons\\Trade_Fishing",
		how = "Any Fishing trainer teaches it, for 1 silver: in every capital city and many towns.",
		needs = { level = 5 }, fishFrom = 1, fishTo = 74 },
	{ key = "journeyman", name = "Journeyman", cap = 150, from = 75, icon = "Interface\\Icons\\Trade_Fishing",
		how = "Any Fishing trainer teaches it, for 5 silver, once you've reached Fishing 50.",
		needs = { skill = 50 }, fishFrom = 75, fishTo = 149 },
	{ key = "expert", name = "Expert", cap = 225, from = 150, item = 16083, icon = "Interface\\Icons\\INV_Misc_Book_09",
		how = "Read Expert Fishing - The Bass and You: 1 gold from Old Man Heming <Fisherman> in Booty Bay, Stranglethorn Vale.",
		needs = { level = 20, skill = 125 }, fishFrom = 150, fishTo = 224,
		where = { zone = "Stranglethorn Vale", x = 0.276, y = 0.774, label = "Old Man Heming, Booty Bay" } },
	{ key = "artisan", name = "Artisan", cap = 300, from = 225, icon = "Interface\\Icons\\INV_Misc_Fish_14",
		how = "Nat Pagle's quest, Nat Pagle, Angler Extreme, on his island off Dustwallow Marsh: bring him one of each fish below.",
		needs = { level = 35, skill = 225 }, fishFrom = 225, fishTo = 425, natFish = true,
		where = { zone = "Dustwallow Marsh", x = 0.586, y = 0.602, label = "Nat Pagle, Dustwallow Marsh" } },
}

-- A zone's name in the client's language.
local function LocalZone(english)
	local id = ns.ZONE_AREA_IDS and ns.ZONE_AREA_IDS[english]
	local name = id and C_Map.GetAreaInfo and C_Map.GetAreaInfo(id)
	return (name and name ~= "") and name or english
end

-- Your rank: the index into RANKS for your cap, 0 before you've learned Fishing.
function Journey.Current()
	if not ns.Stats then
		return 0, nil, nil
	end
	local rank, maxRank = ns.Stats.FishingSkill()
	if not (rank and maxRank) then
		return 0, rank, maxRank
	end
	local index = 0
	for i, r in ipairs(Journey.RANKS) do
		if maxRank >= r.cap then
			index = i
		end
	end
	return index, rank, maxRank
end

-- Where to fish at a rank: zones whose level falls in its range, easiest first.
local function ZonesFor(r)
	local list = {}
	for zone, needed in pairs(ns.ZONE_FISHING_SKILL or {}) do
		if needed >= r.fishFrom and needed <= r.fishTo then
			list[#list + 1] = { zone = zone, needed = needed }
		end
	end
	table.sort(list, function(a, b)
		if a.needed ~= b.needed then
			return a.needed < b.needed
		end
		return a.zone < b.zone
	end)
	return list
end

local function ZoneText(r)
	local list = ZonesFor(r)
	local names = {}
	for i, z in ipairs(list) do
		if i > 4 then
			names[#names + 1] = string.format("and %d more", #list - 4)
			break
		end
		names[#names + 1] = z.zone .. " " .. GREY .. z.needed .. "|r"
	end
	return #names > 0 and table.concat(names, ", ") or (GREY .. "none listed|r")
end

-- What a rank needs that you don't have yet, as text, or nil when you're ready.
local function Missing(r, rank)
	local parts = {}
	local level = UnitLevel("player") or 0
	if r.needs.level and level < r.needs.level then
		parts[#parts + 1] = string.format("level %d (you're %d)", r.needs.level, level)
	end
	if r.needs.skill and (rank or 0) < r.needs.skill then
		parts[#parts + 1] = string.format("Fishing %d (you have %d)", r.needs.skill, rank or 0)
	end
	return #parts > 0 and table.concat(parts, " and ") or nil
end

local function NeedsText(r)
	local parts = {}
	if r.needs.level then
		parts[#parts + 1] = "level " .. r.needs.level
	end
	if r.needs.skill then
		parts[#parts + 1] = "Fishing " .. r.needs.skill
	end
	return #parts > 0 and table.concat(parts, ", ") or "nothing"
end

local function Card(parent, r, y)
	local c = CreateFrame("Frame", nil, parent)
	c:SetPoint("TOPLEFT", EDGE, y)
	c:SetPoint("TOPRIGHT", -EDGE, y)
	c:SetHeight(CARD_HEIGHT - 6)
	c.bg = c:CreateTexture(nil, "BACKGROUND")
	c.bg:SetAllPoints()
	c.bg:SetColorTexture(1, 1, 1, 0.04)
	c.edge = c:CreateTexture(nil, "BORDER")
	c.edge:SetPoint("TOPLEFT")
	c.edge:SetPoint("BOTTOMLEFT")
	c.edge:SetWidth(3)
	c.icon = c:CreateTexture(nil, "ARTWORK")
	c.icon:SetSize(40, 40)
	c.icon:SetPoint("TOPLEFT", 12, -8)
	c.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	c.icon:SetTexture(r.item and C_Item.GetItemIconByID(r.item) or r.icon)
	c.check = c:CreateTexture(nil, "OVERLAY")
	c.check:SetSize(18, 18)
	c.check:SetPoint("BOTTOMRIGHT", c.icon, "BOTTOMRIGHT", 4, -4)
	if ns.UI.HasAtlas("UI-LFG-ReadyMark") then
		c.check:SetAtlas("UI-LFG-ReadyMark")
	else
		c.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
	end
	c.title = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	c.title:SetPoint("TOPLEFT", c.icon, "TOPRIGHT", 12, 0)
	c.status = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	c.status:SetPoint("TOPRIGHT", -12, -10)
	c.status:SetJustifyH("RIGHT")
	c.how = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	c.how:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -6)
	c.how:SetPoint("RIGHT", -130, 0)
	c.how:SetJustifyH("LEFT")
	c.how:SetWordWrap(true)
	c.zones = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	c.zones:SetPoint("TOPLEFT", c.how, "BOTTOMLEFT", 0, -4)
	c.zones:SetPoint("RIGHT", -12, 0)
	c.zones:SetJustifyH("LEFT")
	c.zones:SetWordWrap(false)
	c.extra = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	c.extra:SetPoint("TOPLEFT", c.zones, "BOTTOMLEFT", 0, -4)
	c.extra:SetPoint("RIGHT", -12, 0)
	c.extra:SetJustifyH("LEFT")
	c.extra:SetWordWrap(false)
	if r.where then
		c.map = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
		ns.Theme.Register(c.map, "button")
		c.map:SetSize(112, 22)
		c.map:SetPoint("TOPRIGHT", c.status, "BOTTOMRIGHT", 2, -6)
		c.map:SetText("Show on map")
		c.map:SetScript("OnClick", function()
			local zone = LocalZone(r.where.zone)
			local mapID = ns.Book and ns.Book.ZoneMapID and ns.Book.ZoneMapID(zone)
			ns.UI.ShowOnMap(mapID, r.where.x, r.where.y, r.where.label)
		end)
		c.map:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(r.where.label)
			GameTooltip:AddLine("Opens the map there with a waypoint. Classic's spot: Forever may differ a little.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		c.map:SetScript("OnLeave", GameTooltip_Hide)
	end
	-- Expert's book, and Nat's fish: hover for the item.
	c:EnableMouse(true)
	c:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if r.item then
			GameTooltip:SetItemByID(r.item)
			GameTooltip:AddLine(" ")
		else
			GameTooltip:SetText(r.name .. " Fishing")
		end
		-- Every zone to fish at this rank, with the Fishing each needs.
		GameTooltip:AddLine("Fish in", 1, 0.82, 0)
		for _, z in ipairs(ZonesFor(r)) do
			GameTooltip:AddDoubleLine(z.zone, tostring(z.needed), 1, 1, 1, 0.7, 0.7, 0.7)
		end
		GameTooltip:Show()
	end)
	c:SetScript("OnLeave", GameTooltip_Hide)
	c.rank = r
	return c
end

local function Paint(c, index, current, rank)
	local r = c.rank
	local learned = index <= current
	local nextUp = index == current + 1
	c.title:SetText(r.name .. "  " .. GREY .. "Fishing up to " .. r.cap .. "|r")
	c.check:SetShown(learned)
	c.icon:SetDesaturated(not learned and not nextUp)
	local color
	if learned then
		c.status:SetText(GOOD .. "Learned|r")
		color = { 0.12, 1, 0 }
	elseif nextUp then
		local missing = Missing(r, rank)
		c.status:SetText(missing and (GOLD .. "Next: needs " .. missing .. "|r") or (GOOD .. "Next: ready to learn!|r"))
		color = { 1, 0.82, 0 }
	else
		c.status:SetText(GREY .. "Later|r")
		color = { 0.5, 0.5, 0.5 }
	end
	c.edge:SetColorTexture(color[1], color[2], color[3], 0.9)
	c.bg:SetColorTexture(color[1], color[2], color[3], nextUp and 0.1 or 0.04)
	c.how:SetText((learned and GREY or "|cffffffff") .. r.how .. "|r")
	c.zones:SetText(GOLD .. "Fish in:|r " .. ZoneText(r))
	if r.natFish then
		local parts = {}
		for _, id in ipairs(NAT_FISH) do
			local fish = ns.FISH_BY_ID and ns.FISH_BY_ID[id]
			local caught = ns.Collection and ns.Collection.Get(id).total > 0
			local icon = C_Item.GetItemIconByID(id)
			parts[#parts + 1] = (icon and ("|T" .. icon .. ":14:14:0:0:64:64:5:59:5:59|t ") or "")
				.. (caught and GOOD or GREY) .. (C_Item.GetItemNameByID(id) or (fish and fish.name) or "?") .. "|r"
		end
		c.extra:SetText(GOLD .. "Nat's fish:|r " .. table.concat(parts, "  "))
	else
		c.extra:SetText(GOLD .. "Needs:|r " .. NeedsText(r))
	end
end

-- Fishing gear: poles first, then what you wear. `from` is where it comes from: Forever's own
-- where Wowhead's Forever data has it (marked forever), else Classic's from CMaNGOS's world
-- database (vendors, quest rewards and loot). The bonus is read from the game's own tooltip, so
-- it's Forever's.
Journey.GEAR = {
	{ id = 6256, kind = "Pole", from = "Sold by fishing vendors all over Azeroth.", forever = true },
	{ id = 6365, kind = "Pole", from = "Sold by some fishing vendors, among them Old Man Heming in Booty Bay.", forever = true },
	{ id = 12225, kind = "Pole", from = "Reward from The Family and the Fishing Pole, an Alliance quest in Darkshore (level 10)." },
	{ id = 6367, kind = "Pole", from = "Found in Shellfish Traps under the water, now and then." },
	{ id = 19022, kind = "Pole", from = "Reward from Snapjaws, Mon!, a Horde quest in The Hinterlands (level 44)." },
	{ id = 19970, kind = "Pole", from = "The Fishing Extravaganza's top prize: be first to bring 40 Tastyfish." },
	{ id = 285094, kind = "Pole", from = "New in Forever: where it comes from isn't known yet.", forever = true },
	{ id = 276203, kind = "Pole", from = "New in Forever: sold in Riverglades.", forever = true, ifBonus = true },
	{ id = 276272, kind = "Head", from = "New in Forever: sold in Stranglethorn Vale.", forever = true },
	{ id = 259846, kind = "Head", from = "New in Forever: where it comes from isn't known yet.", forever = true, ifBonus = true },
	{ id = 244229, kind = "Shoulder", from = "New in Forever: where it comes from isn't known yet.", forever = true, ifBonus = true },
	{ id = 19972, kind = "Head", from = "Fishing Extravaganza: hand in a Keefer's Angelfish." },
	{ id = 19969, kind = "Feet", from = "Fishing Extravaganza: hand in a Brownell's Blue Striped Racer." },
	{ id = 273495, kind = "Hands", from = "New in Forever: the Fishing enchant for your gloves.", forever = true },
}
local GEAR_ROW = 29
-- ifBonus: Forever's new items whose Fishing bonus its data doesn't say. They show once the
-- game's tooltip for them has one, so a cosmetic hat or mantle never joins the list.

local frame

local function CreateWindow()
	local UI = ns.UI
	local f, inset = UI.CreateShell("OneCastJourneyFrame", "Fisherman's journey",
		C_Item.GetItemIconByID(16083) or "Interface\\Icons\\INV_Misc_Book_09")
	f:SetSize(WIDTH, ns.UI.PAGE_HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	UI.RememberPosition(f, "journey")
	tinsert(UISpecialFrames, f:GetName())
	UI.KeepOpenThroughOptions(f:GetName())


	-- Where you stand: your rank, your skill along it, and what it takes to the cap.
	f.headline = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.headline:SetPoint("TOPLEFT", EDGE + 4, -GAP - 2)
	-- The stats page's own bar: Forever's Fishing bar, its water in the theme's colours.
	f.progress = UI.RankBar(inset, ns.GetFishingName and ns.GetFishingName() or "Fishing")
	f.progress:ClearAllPoints()
	f.progress:SetPoint("TOPLEFT", EDGE, -GAP - 26)
	f.progress:SetPoint("TOPRIGHT", -EDGE, -GAP - 26)
	f.togo = inset:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.togo:SetPoint("TOPRIGHT", -EDGE - 4, -GAP - 4)
	f.togo:SetJustifyH("RIGHT")

	f.cards = {}
	local y = -GAP - 66
	f.ranksView = CreateFrame("Frame", nil, inset)
	f.ranksView:SetAllPoints()
	for i, r in ipairs(Journey.RANKS) do
		f.cards[i] = Card(f.ranksView, r, y)
		y = y - CARD_HEIGHT
	end

	-- Gear: every fishing pole and piece of fishing gear, its bonus, whether you have it, and
	-- where it comes from.
	f.gearView = CreateFrame("Frame", nil, inset)
	f.gearView:SetAllPoints()
	f.gearView:Hide()
	f.gearRows = {}
	for i, g in ipairs(Journey.GEAR) do
		local row = CreateFrame("Button", nil, f.gearView)
		-- Placed in PaintGear, which closes up around the rows it hides.
		row:SetHeight(GEAR_ROW - 2)
		ns.UI.RowBackground(row, i)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(26, 26)
		row.icon:SetPoint("LEFT", 6, 0)
		row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		row.check = row:CreateTexture(nil, "OVERLAY")
		row.check:SetSize(14, 14)
		row.check:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 4, -3)
		if ns.UI.HasAtlas("UI-LFG-ReadyMark") then
			row.check:SetAtlas("UI-LFG-ReadyMark")
		else
			row.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
		end
		row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 1)
		row.name:SetWidth(250)
		row.name:SetJustifyH("LEFT")
		row.name:SetWordWrap(false)
		row.bonus = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		row.bonus:SetPoint("LEFT", row.name, "RIGHT", 4, 0)
		row.from = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.from:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
		row.from:SetPoint("RIGHT", -8, 0)
		row.from:SetJustifyH("LEFT")
		row.from:SetWordWrap(false)
		row.kind = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.kind:SetPoint("TOPRIGHT", -8, -3)
		row.gear = g
		row:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetItemByID(self.gear.id)
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(self.gear.from, 1, 1, 1, true)
			GameTooltip:AddLine(self.gear.forever and "From Forever's own data." or "Classic's source: Forever may differ.",
				0.6, 0.6, 0.6, true)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", GameTooltip_Hide)
		row:SetScript("OnClick", function(self)
			local _, link = C_Item.GetItemInfo(self.gear.id)
			if link and IsModifiedClick and IsModifiedClick("CHATLINK") and ns.InsertChatLink then
				ns.InsertChatLink(link)
			end
		end)
		f.gearRows[i] = row
	end

	-- Ranks and Gear as tabs on top of the panel, right of the portrait, as on the stats window.
	f.views, f.Tabs = {}, {}
	for i, view in ipairs({ { "ranks", "Ranks" }, { "gear", "Gear" } }) do
		local tab = UI.TryCreate("Button", "OneCastJourneyFrameTab" .. i, f, "PanelTopTabButtonTemplate")
			or CreateFrame("Button", "OneCastJourneyFrameTab" .. i, f, "UIPanelButtonTemplate")
		ns.Theme.Register(tab, "button")
		tab:SetID(i)
		tab:SetText(view[2])
		tab:SetWidth(96)
		if i == 1 then
			tab:SetPoint("BOTTOMLEFT", inset, "TOPLEFT", 62, 0)
		else
			tab:SetPoint("LEFT", f.Tabs[i - 1], "RIGHT", 2, 0)
		end
		tab:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
			f.view = view[1]
			Journey.Refresh()
		end)
		f.Tabs[i], f.views[view[1]] = tab, tab
	end
	if PanelTemplates_SetNumTabs then
		PanelTemplates_SetNumTabs(f, #f.Tabs)
	end
	f.view = "ranks"

	f:SetScript("OnShow", Journey.Refresh)
	local events = CreateFrame("Frame", nil, f)
	events:RegisterEvent("SKILL_LINES_CHANGED")
	events:RegisterEvent("PLAYER_LEVEL_UP")
	events:RegisterEvent("BAG_UPDATE_DELAYED")
	events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	-- A swap or a loot fires these in bursts: one refresh for the lot, a moment later.
	local pending = false
	events:SetScript("OnEvent", function()
		if f:IsShown() and not pending then
			pending = true
			C_Timer.After(0.1, function()
				pending = false
				Journey.Refresh()
			end)
		end
	end)
	f:Hide()
	ns.Hub.Attach("journey", f)
	return f
end

function Journey.Refresh()
	if not (frame and frame:IsShown()) then
		return
	end
	local current, rank, maxRank = Journey.Current()
	if not (rank and maxRank) then
		frame.headline:SetText("You haven't learned Fishing yet")
		frame.progress:SetRank(0, "0/0")
		frame.togo:SetText("")
		frame.togo:SetText(GREY .. "Learn Apprentice Fishing from any Fishing trainer to start.|r")
	else
		local r = Journey.RANKS[current]
		frame.headline:SetText((r and r.name or "") .. " Fishing")
		frame.progress:SetRank(maxRank > 0 and rank / maxRank or 0, string.format("%d/%d", rank, maxRank))
		local nextRank = Journey.RANKS[current + 1]
		if rank >= maxRank and nextRank then
			frame.togo:SetText(GOLD .. "At your cap: learn " .. nextRank.name .. " to keep going.|r")
		elseif rank < maxRank then
			local catches = ns.Stats.CatchesToGo and ns.Stats.CatchesToGo(rank, maxRank - rank)
			frame.togo:SetText(string.format("%s%d to your cap%s|r", GREY, maxRank - rank,
				catches and string.format(", about %d catches", catches) or ""))
		else
			frame.togo:SetText(GOOD .. "Every rank learned.|r")
		end
	end
	-- The view: ranks or gear, its tab selected.
	local gear = frame.view == "gear"
	frame.ranksView:SetShown(not gear)
	frame.gearView:SetShown(gear)
	if PanelTemplates_SetTab then
		PanelTemplates_SetTab(frame, gear and 2 or 1)
	end
	if gear then
		Journey.PaintGear()
	end
	for i, c in ipairs(frame.cards) do
		Paint(c, i, current, rank)
	end
end

-- Each piece of gear: its name in its quality's colour, its Fishing bonus, whether you have it.
function Journey.PaintGear()
	local have, shown = 0, 0
	for _, row in ipairs(frame.gearRows) do
		local g = row.gear
		local bonus = ns.Gear and ns.Gear.ItemBonus and ns.Gear.ItemBonus(g.id)
		local show = not g.ifBonus or (bonus and bonus > 0)
		row:SetShown(show and true or false)
		if show then
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", EDGE, -GAP - 66 - shown * GEAR_ROW)
			row:SetPoint("TOPRIGHT", -EDGE, -GAP - 66 - shown * GEAR_ROW)
			shown = shown + 1
		end
		local name, _, quality = C_Item.GetItemInfo(g.id)
		local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
		row.icon:SetTexture(C_Item.GetItemIconByID(g.id))
		row.name:SetText((color and color.hex or "|cffffffff") .. (name or "...") .. "|r")
		row.bonus:SetText(bonus and bonus > 0 and (GOOD .. "+" .. bonus .. " Fishing|r") or "")
		local owned = (C_Item.GetItemCount and C_Item.GetItemCount(g.id, true) or 0) > 0
			or (C_Item.IsEquippedItem and C_Item.IsEquippedItem(g.id)) or false
		row.check:SetShown(owned)
		row.icon:SetDesaturated(not owned)
		row.kind:SetText(g.kind .. (owned and (GOOD .. "  You have it|r") or ""))
		row.from:SetText((owned and GREY or "|cffd0d0d0") .. g.from .. "|r")
		have = have + (show and owned and 1 or 0)
	end
	frame.togo:SetText(string.format("%sYou have %d of %d. Hover one for its tooltip.|r", GREY, have, shown))
end

function Journey.Show()
	frame = frame or CreateWindow()
	frame:Show()
end

-- Finds for the data report -----------------------------------------------------------------
-- What Forever's data can't tell, found as you play: where a Fishing rank is learned (the
-- trainer, or the quest), fishing gear the Gear view doesn't list, and how Find Fish and Bait
-- and Tackle are learned. Each with where it came from: the trainer or vendor you had open, the
-- quest you'd just handed in, or loot.
-- OneCastCharDB.journeyFinds = { ranks = { [cap] = find }, gear = { [itemID] = find },
--   spells = { [spellID] = find } }; find = { zone, how, name, npc, quest, bonus }

local TRACKED_SPELLS = { [43308] = "Find Fish", [1278067] = "Bait and Tackle" }
local RECENT = 10        -- seconds a quest hand-in or loot still explains what turns up
local TRAINER_RECENT = 120
local context = {}       -- what you were last doing: trainer, vendor, quest, loot
local checked = {}       -- items already looked at this session, for new gear
local lastCap

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

local function NpcHere()
	local guid = UnitGUID and UnitGUID("npc")
	local name = UnitName and UnitName("npc")
	if Secret(guid) or Secret(name) then
		return nil
	end
	local id = type(guid) == "string" and tonumber(guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)") or "")
	return { name = name, npc = id, at = GetTime() }
end

local function Finds()
	if not OneCastCharDB then
		return nil
	end
	OneCastCharDB.journeyFinds = OneCastCharDB.journeyFinds or { ranks = {}, gear = {}, spells = {} }
	return OneCastCharDB.journeyFinds
end

-- Where something you just got came from: whichever of the trainer you had open, a vendor, a
-- quest you handed in or loot happened last, within its window.
local function Source(trainerToo)
	local now = GetTime()
	local find = { zone = GetRealZoneText() or "?", how = "unknown" }
	local c = context
	local best
	local function Consider(how, entry, window)
		if entry and now - entry.at <= window and (not best or entry.at >= best.entry.at) then
			best = { how = how, entry = entry }
		end
	end
	if trainerToo then
		Consider("trainer", c.trainer, TRAINER_RECENT)
	end
	Consider("quest", c.quest, RECENT)
	if c.vendor then
		Consider("vendor", c.vendor, c.vendorOpen and math.huge or RECENT)
	end
	Consider("loot", c.loot, RECENT)
	if best then
		local e = best.entry
		find.how, find.name, find.npc, find.quest = best.how, e.name or e.title, e.npc, e.id
	end
	return find
end
Journey.Source = Source

local function Changed()
	if ns.Report and ns.Report.Check then
		ns.Report.Check()
	end
end

-- A rank learned: your cap went up. Expert's book is confirmed from Forever's data; the others
-- aren't, so where they're learned is worth knowing.
local function CheckRank()
	local stats = ns.Stats
	if not (stats and stats.FishingSkill) then
		return
	end
	local _, cap = stats.FishingSkill()
	if not cap then
		return
	end
	if lastCap and cap > lastCap and cap ~= 225 then
		local finds = Finds()
		if finds and not finds.ranks[cap] then
			finds.ranks[cap] = Source(true)
			Changed()
		end
	end
	lastCap = cap
end

-- Fishing gear the Gear view doesn't list: a pole, or anything with a Fishing bonus.
local LISTED
local function Listed(id)
	if not LISTED then
		LISTED = {}
		for _, g in ipairs(Journey.GEAR) do
			LISTED[g.id] = true
		end
	end
	return LISTED[id]
end

local function CheckItem(id, link)
	if checked[id] or Listed(id) then
		return
	end
	local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(id)
	if classID ~= 2 and classID ~= 4 then
		checked[id] = true
		return
	end
	local bonus = ns.Gear and ns.Gear.ItemBonus and ns.Gear.ItemBonus(id)
	if bonus == nil then
		return -- still loading: looked at again on the next bag change
	end
	checked[id] = true
	local pole = classID == 2 and subclassID == 20
	if bonus > 0 or pole then
		local finds = Finds()
		if finds and not finds.gear[id] then
			local find = Source(false)
			find.bonus, find.item = bonus, C_Item.GetItemNameByID(id) or (link and link:match("%[(.-)%]"))
			finds.gear[id] = find
			Changed()
		end
	end
end

local function ScanGear()
	for bag = 0, NUM_BAG_SLOTS or 4 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local info = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot)
			if info and info.itemID then
				CheckItem(info.itemID, info.hyperlink)
			end
		end
	end
	for _, slot in ipairs({ 1, 2, 3, 5, 6, 7, 8, 9, 10, 15, 16 }) do
		local id = GetInventoryItemID("player", slot)
		if id then
			CheckItem(id)
		end
	end
end
Journey.ScanGear = ScanGear

local tracker = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "SKILL_LINES_CHANGED", "TRAINER_SHOW", "MERCHANT_SHOW", "MERCHANT_CLOSED",
	"QUEST_TURNED_IN", "LOOT_READY", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED" }) do
	tracker:RegisterEvent(event)
end
if ns.RegisterAnyEvent then
	ns.RegisterAnyEvent(tracker, { "LEARNED_SPELL_IN_SKILL_LINE", "LEARNED_SPELL_IN_TAB" })
end
tracker:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		local stats = ns.Stats
		if stats and stats.FishingSkill then
			local _, cap = stats.FishingSkill()
			lastCap = cap
		end
		C_Timer.After(5, ScanGear)
	elseif event == "SKILL_LINES_CHANGED" then
		CheckRank()
	elseif event == "TRAINER_SHOW" then
		context.trainer = NpcHere()
	elseif event == "MERCHANT_SHOW" then
		context.vendor, context.vendorOpen = NpcHere(), true
	elseif event == "MERCHANT_CLOSED" then
		context.vendorOpen = false
		if context.vendor then
			context.vendor.at = GetTime()
		end
	elseif event == "QUEST_TURNED_IN" then
		local questID = ...
		if type(questID) == "number" and not Secret(questID) then
			local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
			context.quest = { id = questID, title = not Secret(title) and title or nil, at = GetTime() }
		end
	elseif event == "LOOT_READY" then
		local guid = GetLootSourceInfo and GetLootSourceInfo(1)
		local npc = not Secret(guid) and type(guid) == "string" and guid:match("^Creature") and
			tonumber(guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)") or "")
		context.loot = { npc = npc or nil, at = GetTime() }
	elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
		ScanGear()
	else
		-- A spell learned: Find Fish or Bait and Tackle.
		local spellID = ...
		if type(spellID) == "number" and not Secret(spellID) and TRACKED_SPELLS[spellID] then
			local finds = Finds()
			if finds and not finds.spells[spellID] then
				finds.spells[spellID] = Source(true)
				Changed()
			end
		end
	end
end)

-- Report lines for what's been found: { key, text } each.
local function FromText(f)
	local who = f.name and (f.npc and string.format("%s [%d]", f.name, f.npc) or f.name) or (f.npc and ("creature " .. f.npc))
	if f.how == "trainer" then
		return "from the trainer " .. (who or "?")
	elseif f.how == "vendor" then
		return "bought from " .. (who or "a vendor")
	elseif f.how == "quest" then
		return string.format("from the quest %s[%s]", f.name and (f.name .. " ") or "", tostring(f.quest))
	elseif f.how == "loot" then
		return who and ("looted from " .. who) or "from loot"
	end
	return "source not seen"
end

function Journey.Findings()
	local out = {}
	local finds = OneCastCharDB and OneCastCharDB.journeyFinds
	if not finds then
		return out
	end
	local caps = {}
	for cap in pairs(finds.ranks or {}) do
		caps[#caps + 1] = cap
	end
	table.sort(caps)
	for _, cap in ipairs(caps) do
		local f = finds.ranks[cap]
		local rankName = "Fishing"
		for _, r in ipairs(Journey.RANKS) do
			if r.cap == cap then
				rankName = r.name .. " Fishing"
			end
		end
		out[#out + 1] = { key = "journey:rank:" .. cap, text = string.format("Learned %s (up to %d) %s in %s",
			rankName, cap, FromText(f), f.zone or "?") }
	end
	local ids = {}
	for id in pairs(finds.gear or {}) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local f = finds.gear[id]
		out[#out + 1] = { key = "journey:gear:" .. id, id = id, text = string.format("Fishing gear OneCast doesn't list: %s (%d)%s, %s in %s",
			f.item or ("item " .. id), id, (f.bonus or 0) > 0 and string.format(", +%d Fishing", f.bonus) or "",
			FromText(f), f.zone or "?") }
	end
	for spellID, f in pairs(finds.spells or {}) do
		out[#out + 1] = { key = "journey:spell:" .. spellID, text = string.format("Learned %s (%d) %s in %s",
			TRACKED_SPELLS[spellID] or "a fishing spell", spellID, FromText(f), f.zone or "?") }
	end
	return out
end

-- Global for the "Fisherman's journey" key binding.
function OneCast_ToggleJourney()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		Journey.Show()
	end
end
