-- OneCast camp: Forever's fishing crafts for its wilderness camps, and the buffs they give.
--
-- Forever lets players build a campfire and place camp features by it. Fishing has three:
-- the Fish Bowl, the Fishing Rack and the Fishing Hut. Sitting by the fire for a minute gives
-- each feature's benefit for an hour; the Rack and the Hut give "Uncommon Fishing" and "Rare
-- Fishing", extra rewards while fishing. What those rewards are is decided by the server and
-- not published anywhere, so catches made under each buff are recorded here, to be shown in
-- the window's Camp page and in /onecast report.
--
-- Everything below is from Forever's game data on wago.tools (build 1.60.1.70862): recipe and
-- item IDs, reagents, the Fishing each needs (the craft's skill-up level and the item's own
-- requirement), the 15-minute features, the hour-long buffs and the shared hour cooldown.
-- Where the Blueprints, the Fish Bowl recipe and Seasonal Fish Steaks come from isn't in it:
-- `blueprintFrom` is from player reports (10 November 2026). The Rack's Blueprint dropping from
-- Gelihast is reported by several guides, which disagree only on the drop rate. The Hut's
-- dropping from Jammal'an the Prophet is one player's report, via a Wowhead comment (13 November 2026).

local _, ns = ...

local Camp = {}
ns.Camp = Camp

Camp.CRAFTS = {
	{ key = "bowl", name = "Fish Bowl", recipe = 1229745, item = 279967, skill = 20,
		reagents = { { 6291, 1, "Raw Brilliant Smallfish" }, { 3371, 1, "Empty Vial" } },
		effect = "+8% to all stats for you and anyone sitting nearby, for an hour.",
		does = "Placed by a campfire, it gives you and everyone sitting nearby +8% to all stats for an hour. It doesn't stack with Blessing of Kings." },
	{ key = "rack", name = "Fishing Rack", recipe = 1262990, item = 279965, skill = 140,
		blueprint = 273141, blueprintName = "Blueprint: Fishing Rack", buff = 1280341, buffName = "Uncommon Fishing",
		blueprintFrom = "drops from Gelihast in Blackfathom Deeps, not on every kill. Other players can trade it to you.",
		blueprintKnown = { name = "Gelihast", npc = 6243 }, -- confirmed: a drop from it isn't news
		blueprintShort = "Gelihast, Blackfathom Deeps",
		blueprintWhere = { zone = "Ashenvale", x = 0.145, y = 0.142, label = "Blackfathom Deeps, for Gelihast's Blueprint" },
		effect = "Uncommon Fishing for an hour: extra rewards while you fish, and the Fish Bowl's stats.",
		reagents = { { 4470, 2, "Simple Wood" }, { 8925, 1, "Crystal Vial" }, { 8365, 2, "Raw Mithril Head Trout" } },
		does = "Placed by a campfire, it gives Uncommon Fishing for an hour: extra rewards while you fish. It also provides lures and the Fish Bowl's +8% stats, and can replace a Fish Bowl." },
	{ key = "hut", name = "Fishing Hut", recipe = 1262998, item = 279966, skill = 300,
		blueprint = 273119, blueprintName = "Blueprint: Fishing Hut", buff = 1280342, buffName = "Rare Fishing",
		blueprintFrom = "reported to drop from Jammal'an the Prophet in the Sunken Temple (one player's report, not yet confirmed). Other players can trade it to you.",
		blueprintShort = "Jammal'an the Prophet, Sunken Temple (unconfirmed)",
		blueprintWhere = { zone = "Swamp of Sorrows", x = 0.695, y = 0.536, label = "The Sunken Temple, for Jammal'an's Blueprint" },
		effect = "Rare Fishing for an hour: greater extra rewards while you fish, and the Fish Bowl's stats.",
		reagents = { { 4470, 5, "Simple Wood" }, { 14048, 2, "Bolt of Runecloth" }, { 273295, 1, "Seasonal Fish Steaks" } },
		does = "Placed by a campfire, it gives Rare Fishing for an hour: greater extra rewards while you fish. It also provides lures and the Fish Bowl's +8% stats, and can replace a Fish Bowl." },
}

-- Cooking recipes: a campfire holds this many features. Basic comes with Cooking; the others are
-- learned from blueprints that drop (Forever's client data and Wowhead, 16 November 2026).
Camp.CAMPFIRES = {
	{ name = "Basic Campfire", recipe = 1229737, holds = 3, from = "Learned with Cooking." },
	{ name = "Journeyman Campfire", recipe = 1283400, holds = 5, blueprint = 273087,
		from = "Learned from Blueprint: Journeyman Campfire (Cooking 90), dropped by Lord Serpentis in Wailing Caverns, about 1 kill in 17. Made with Star Wood." },
	{ name = "Expert Campfire", recipe = 1291341, holds = 10, blueprint = 273101,
		from = "Learned from Blueprint: Expert Campfire (Cooking 200), dropped by Slavecrusher Grox, about 1 kill in 23. Made with Thick Logs." },
}
Camp.FEATURE_MINUTES = 15  -- a placed feature stands this long
Camp.SIT_SECONDS = 60      -- time by the fire before its benefits arrive
Camp.COOLDOWN_MINUTES = 60 -- shared by every camp feature

local byBuff = {}
for _, craft in ipairs(Camp.CRAFTS) do
	if craft.buff then
		byBuff[craft.buff] = craft
	end
end

Camp.Count = ns.ItemCount

function Camp.ItemName(itemID, fallback)
	return C_Item.GetItemNameByID(itemID) or fallback
end

-- True if the recipe is learned, false if not, nil if the game can't say.
function Camp.Known(craft)
	return ns.KnowsSpell(craft.recipe)
end

-- The camp fishing buff on you now, if any: the craft that gives it and seconds left. The
-- Hut's is the stronger, so it wins if both are somehow on.
function Camp.ActiveBuff()
	if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
		return nil
	end
	local found, left
	for _, craft in ipairs(Camp.CRAFTS) do
		if craft.buff then
			local aura = C_UnitAuras.GetPlayerAuraBySpellID(craft.buff)
			local expires = aura and aura.expirationTime
			if expires and not (issecretvalue and issecretvalue(expires)) then
				found, left = craft, expires > 0 and math.max(0, expires - GetTime()) or nil
			end
		end
	end
	return found, left
end

-- Catches made under each buff: { [buff key] = { catches, items = { [id] = count }, zones } }.
local function Records()
	local charDB = OneCastCharDB
	if not charDB then
		return nil
	end
	charDB.camp = charDB.camp or {}
	return charDB.camp
end

function Camp.Record(key)
	local records = Records()
	return records and records[key]
end

-- From the stats window's catch handling, with the zone and what came out of the water.
function Camp.OnCatch(zone, loot)
	local craft = Camp.ActiveBuff()
	local records = craft and Records()
	if not records then
		return
	end
	local r = records[craft.key]
	if not r then
		r = { catches = 0, items = {}, zones = {} }
		records[craft.key] = r
	end
	r.catches = r.catches + 1
	r.zones[zone] = (r.zones[zone] or 0) + 1
	for _, l in ipairs(loot) do
		r.items[l.id] = (r.items[l.id] or 0) + l.quantity
	end
end

-- Where the camp items whose source is unconfirmed drop: any loot window holding a Blueprint or
-- Seasonal Fish Steaks is recorded, with the creature it came from, for the data report.
-- OneCastCharDB.campDrops[itemID][sourceKey] = { zone, name, npc, count }.
Camp.TRACKED_DROPS = { [273295] = "Seasonal Fish Steaks" }
for _, craft in ipairs(Camp.CRAFTS) do
	if craft.blueprint then
		Camp.TRACKED_DROPS[craft.blueprint] = craft.blueprintName
	end
end

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

function Camp.OnLootReady()
	if not OneCastCharDB or not GetNumLootItems then
		return
	end
	for slot = 1, GetNumLootItems() do
		local link = GetLootSlotLink(slot)
		local id = link and not Secret(link) and tonumber(link:match("item:(%d+)"))
		if id and Camp.TRACKED_DROPS[id] then
			local guid = GetLootSourceInfo and GetLootSourceInfo(slot)
			if Secret(guid) then
				guid = nil
			end
			local kind, npc = nil, nil
			if guid then
				kind = guid:match("^(%a+)")
				-- Creature-0-[server]-[instance]-[zone]-[npc ID]-[spawn]
				npc = tonumber(guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)") or "")
			end
			local name
			local targetGUID = UnitGUID("target")
			if guid and targetGUID and not Secret(targetGUID) and targetGUID == guid then
				name = UnitName("target")
			end
			local zone = GetRealZoneText() or "?"
			local key = (kind == "Creature" and npc) and ("npc" .. npc) or ((kind or "unknown") .. ":" .. zone)
			local drops = OneCastCharDB.campDrops or {}
			OneCastCharDB.campDrops = drops
			drops[id] = drops[id] or {}
			local d = drops[id][key] or { zone = zone, count = 0 }
			drops[id][key] = d
			d.count = d.count + 1
			d.name = d.name or (not Secret(name) and name) or nil
			d.npc = d.npc or (kind == "Creature" and npc) or nil
			d.object = kind == "GameObject" or nil
			if ns.Report and ns.Report.Check then
				ns.Report.Check()
			end
		end
	end
end

-- "Rare Fishing  ·  42m", for the stats window and minimap tooltip, or nil with no buff on.
function Camp.StatusText()
	local craft, left = Camp.ActiveBuff()
	if not craft then
		return nil
	end
	if left then
		return string.format("%s  ·  %dm", craft.buffName, math.ceil(left / 60))
	end
	return craft.buffName
end

local function RefreshViews()
	if ns.Stats and ns.Stats.RefreshIfShown then
		ns.Stats.RefreshIfShown()
	end
	Camp.PaintPage()
end

-- Auras change all the time, in combat above all: only a buff starting or ending matters.
-- When one runs out, say so once: the next hour needs another sit by the fire.
local had -- the buff's craft key, false for none, nil before login
local function CheckBuff()
	local craft = Camp.ActiveBuff()
	local now = craft and craft.key or false
	if now == had then
		return
	end
	if had and not now and ns.db and ns.db.campReminder then
		for _, gone in ipairs(Camp.CRAFTS) do
			if gone.key == had then
				local buff = C_Spell and C_Spell.GetSpellLink and C_Spell.GetSpellLink(gone.buff) or gone.buffName
				local item = ns.ItemLink(gone.item, gone.name)
				ns.Print(buff .. " has worn off. Sit by a campfire with a " .. item .. " to get it again.")
			end
		end
	end
	had = now
	RefreshViews()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("LOOT_READY")
-- A recipe learned: Forever calls it LEARNED_SPELL_IN_SKILL_LINE, older clients LEARNED_SPELL_IN_TAB.
ns.RegisterAnyEvent(events, { "LEARNED_SPELL_IN_SKILL_LINE", "LEARNED_SPELL_IN_TAB" })
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		local craft = Camp.ActiveBuff()
		had = craft and craft.key or false
	elseif event == "UNIT_AURA" then
		if had ~= nil then
			CheckBuff()
		end
	elseif event == "LOOT_READY" then
		Camp.OnLootReady()
	else
		-- Reagents or a recipe changed: only the Camp page shows those.
		Camp.PaintPage()
	end
end)

-- The Camp page --------------------------------------------------------------------------------
-- One of the window's pages, built from the same parts as the stats and the journey: on the left
-- each fishing craft as a card (what it does, what it's made from against your bags, where its
-- Blueprint comes from), on the right the buff on you now, how camps work, the campfires, and
-- what the buffs have brought in. Every string grows to fit: nothing is cut short.

local PAGE_WIDTH, EDGE, GAP, PAD = 660, 10, 8, 10
local HEADER = 24
local GREY, GOOD, BAD, GOLD = "|cff9d9d9d", "|cff20ff20", "|cffff4040", "|cffffd100"
local page

-- Every string on the page, for its tests; and its hover areas.
local function Text(parent, font)
	local fs = parent:CreateFontString(nil, "OVERLAY", font or "OneCastFontHighlightSmall")
	fs:SetJustifyH("LEFT")
	page.strings[#page.strings + 1] = fs
	return fs
end

-- A link in chat on Shift-click, the item's own tooltip on hover with `extra` lines after it.
local function ItemHover(region, itemID, extra)
	region:EnableMouse(true)
	region:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetItemByID(itemID)
		if extra then
			extra(GameTooltip)
		end
		GameTooltip:Show()
	end)
	region:SetScript("OnLeave", GameTooltip_Hide)
	region:SetScript("OnMouseUp", function()
		if IsModifiedClick and IsModifiedClick("CHATLINK") then
			local link = select(2, C_Item.GetItemInfo(itemID))
			if link and ChatEdit_InsertLink then
				ChatEdit_InsertLink(link)
			end
		end
	end)
	page.hovers[#page.hovers + 1] = region
end

local function Icon(parent, size)
	local icon = parent:CreateTexture(nil, "ARTWORK")
	icon:SetSize(size, size)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	return icon
end

-- A craft's card: built once, filled and sized by PaintCraft.
local function CraftCard(parent, craft)
	local c = ns.UI.Card(parent)
	c.craft = craft
	c.icon = Icon(c, 34)
	c.icon:SetPoint("TOPLEFT", 12, -8)
	c.made = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline")
	c.made:SetPoint("BOTTOMRIGHT", c.icon, "BOTTOMRIGHT", 1, 1)
	c.status = Text(c)
	c.status:SetPoint("TOPRIGHT", -PAD, -10)
	c.status:SetJustifyH("RIGHT")
	c.name = Text(c, "GameFontNormal")
	c.name:SetPoint("TOPLEFT", c.icon, "TOPRIGHT", 10, -1)
	c.effect = Text(c)
	c.effect:SetTextColor(0.78, 0.78, 0.78)
	c.effect:SetPoint("TOPLEFT", c.name, "BOTTOMLEFT", 0, -4)
	c.effect:SetPoint("RIGHT", -PAD, 0)
	c.effect:SetWordWrap(true)
	ItemHover(c, craft.item, function(tip)
		tip:AddLine(" ")
		tip:AddLine(craft.does, 1, 1, 1, true)
		local known = Camp.Known(craft)
		if known then
			tip:AddLine("You've learned to make it.", 0.12, 1, 0)
		elseif known == false then
			tip:AddLine("You haven't learned to make it yet.", 1, 0.3, 0.3)
		end
	end)
	-- What it's made from: a shaded row each, have/need at the right.
	c.reagents = {}
	for j, r in ipairs(craft.reagents) do
		local row = CreateFrame("Frame", nil, c)
		row:SetHeight(20)
		ns.UI.RowBackground(row, j)
		row.icon = Icon(row, 16)
		row.icon:SetPoint("LEFT", 4, 0)
		row.name = Text(row)
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
		row.need = Text(row)
		row.need:SetPoint("RIGHT", -6, 0)
		row.need:SetJustifyH("RIGHT")
		row.reagent = r
		ItemHover(row, r[1], function(tip)
			tip:AddLine(string.format("You have %d, and it takes %d.", Camp.Count(r[1]), r[2]), 1, 1, 1)
		end)
		c.reagents[j] = row
	end
	-- Where the Blueprint comes from: its tooltip, and a click for the dungeon's entrance.
	if craft.blueprint then
		local bp = CreateFrame("Button", nil, c)
		bp.text = Text(bp)
		bp.text:SetPoint("TOPLEFT", 4, -3)
		bp.text:SetPoint("RIGHT", -4, 0)
		bp.text:SetWordWrap(true)
		bp:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		local where = craft.blueprintWhere
		ItemHover(bp, craft.blueprint, function(tip)
			tip:AddLine(" ")
			tip:AddLine("It " .. craft.blueprintFrom, 1, 1, 1, true)
			if where then
				tip:AddLine("Click: a waypoint at the dungeon's entrance in " .. where.zone, 0.6, 0.8, 1)
			end
		end)
		bp:SetScript("OnClick", function()
			if IsModifiedClick and IsModifiedClick("CHATLINK") then
				return
			end
			local mapID = where and ns.Book and ns.Book.ZoneMapID and ns.Book.ZoneMapID(where.zone)
			if mapID then
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				ns.UI.ShowOnMap(mapID, where.x, where.y, where.label)
			elseif where then
				ns.Print("the game has no map for " .. where.zone .. ".")
			end
		end)
		c.blueprint = bp
	end
	return c
end

-- Fills a craft's card and returns its height.
local function PaintCraft(c, width)
	local craft = c.craft
	local rank = ns.Stats.FishingSkill()
	local known = Camp.Known(craft)
	local hasBlueprint = craft.blueprint and Camp.Count(craft.blueprint) > 0
	local status, color
	if known then
		status, color = GOOD .. "Learned|r", { 0.12, 1, 0 }
	elseif hasBlueprint then
		status, color = GOLD .. "Blueprint in your bags|r", { 1, 0.82, 0 }
	elseif rank and rank < craft.skill then
		status, color = BAD .. "Needs " .. craft.skill .. " Fishing|r", { 1, 0.25, 0.25 }
	else
		status, color = GREY .. "Not learned yet|r", { 0.5, 0.5, 0.5 }
	end
	c:SetColor(color[1], color[2], color[3], known and 0.1 or 0.16)
	c.icon:SetTexture(C_Item.GetItemIconByID(craft.item) or "Interface\\Icons\\INV_Misc_QuestionMark")
	local made = Camp.Count(craft.item)
	c.made:SetText(made > 0 and made or "")
	c.name:SetText(craft.name)
	c.status:SetText(status)
	c.effect:SetText(craft.effect or craft.does)
	c.effect:SetWidth(width - 12 - 34 - 10 - PAD)
	local y = 8 + math.max(34, (c.name:GetStringHeight() or 13) + 4 + (c.effect:GetStringHeight() or 12)) + 8
	for _, row in ipairs(c.reagents) do
		local r = row.reagent
		local have = Camp.Count(r[1])
		row.icon:SetTexture(C_Item.GetItemIconByID(r[1]) or "Interface\\Icons\\INV_Misc_QuestionMark")
		row.name:SetText(Camp.ItemName(r[1], r[3]))
		row.need:SetText((have >= r[2] and GOOD or BAD) .. math.min(have, r[2]) .. "/" .. r[2] .. "|r")
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 56, -y)
		row:SetPoint("TOPRIGHT", -PAD, -y)
		y = y + 20
	end
	local bp = c.blueprint
	if bp then
		local show = craft.blueprintFrom and not known and not hasBlueprint
		bp:SetShown(show)
		if show then
			bp.text:SetWidth(width - 56 - PAD - 8)
			bp.text:SetText(GOLD .. "Blueprint:|r " .. (craft.blueprintShort or craft.blueprintFrom))
			local h = (bp.text:GetStringHeight() or 12) + 6
			bp:ClearAllPoints()
			bp:SetPoint("TOPLEFT", 56, -y - 4)
			bp:SetPoint("TOPRIGHT", -PAD, -y - 4)
			bp:SetHeight(h)
			y = y + 4 + h
		end
	end
	return y + 8
end

-- A line of the right column: a shaded row with its text, as tall as the text needs.
local function InfoRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	ns.UI.RowBackground(row, index)
	row.text = Text(row)
	row.text:SetPoint("TOPLEFT", PAD, -4)
	row.text:SetPoint("RIGHT", -PAD, 0)
	row.text:SetWordWrap(true)
	return row
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
	header:ClearAllPoints()
	header:SetPoint("TOPLEFT", header:GetParent(), "TOPLEFT", EDGE, -y)
	header:SetPoint("TOPRIGHT", header:GetParent(), "TOPRIGHT", -EDGE, -y)
	return y + HEADER + 4
end

function Camp.PaintPage()
	local f = page
	if not (f and f:IsShown()) then
		return
	end
	local width = f.left:GetWidth()
	width = (width and width > 0 and width or (PAGE_WIDTH - 10) / 2) - 2 * EDGE

	-- Left: the crafts.
	local learned = 0
	for _, craft in ipairs(Camp.CRAFTS) do
		learned = learned + (Camp.Known(craft) and 1 or 0)
	end
	f.craftsHeader.text:SetText(string.format("Camp features  %s(%d of %d learned)|r", GREY, learned, #Camp.CRAFTS))
	local y = PlaceHeader(f.craftsHeader, GAP)
	for _, c in ipairs(f.crafts) do
		local h = PaintCraft(c, width)
		Place(c, f.left, y, h)
		y = y + h + 6
	end

	-- Right: the buff on you now.
	local Rt = f.right
	y = PlaceHeader(f.nowHeader, GAP)
	local craft, timeLeft = Camp.ActiveBuff()
	local now = f.now
	if craft then
		now.icon:SetTexture((C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(craft.buff))
			or C_Item.GetItemIconByID(craft.item))
		now.icon:SetDesaturated(false)
		now.title:SetText(GOOD .. craft.buffName .. "|r")
		now.sub:SetText((timeLeft and string.format("%d more minutes, ", math.ceil(timeLeft / 60)) or "")
			.. "from a " .. craft.name .. ".")
		now:SetColor(0.12, 1, 0)
	else
		now.icon:SetTexture(C_Item.GetItemIconByID(Camp.CRAFTS[#Camp.CRAFTS].item))
		now.icon:SetDesaturated(true)
		now.title:SetText("No camp buff on")
		now.sub:SetText("Sit by a campfire with a Fishing Rack or Fishing Hut to get one.")
		now:SetColor(0.5, 0.5, 0.5, 0.08)
	end
	now.buff = craft and craft.buff
	now.sub:SetWidth(width - 12 - 34 - 10 - PAD)
	local h = 8 + math.max(34, (now.title:GetStringHeight() or 13) + 4 + (now.sub:GetStringHeight() or 12)) + 8
	Place(now, Rt, y, h)
	y = y + h + 8

	-- How camps work: a fact a row.
	y = PlaceHeader(f.howHeader, y)
	local facts = {
		"Build a campfire with Cooking, then place features beside it.",
		string.format("Sit nearby for %d seconds: each feature's buff lasts an hour.", Camp.SIT_SECONDS),
		string.format("Features stand %d minutes and share a %d-minute cooldown.", Camp.FEATURE_MINUTES, Camp.COOLDOWN_MINUTES),
	}
	for i, row in ipairs(f.how) do
		row.text:SetText(facts[i])
		row.text:SetWidth(width - 2 * PAD)
		local rh = math.max(20, (row.text:GetStringHeight() or 12) + 8)
		Place(row, Rt, y, rh)
		y = y + rh
	end
	y = y + 8

	-- The campfires.
	y = PlaceHeader(f.firesHeader, y)
	for _, row in ipairs(f.fires) do
		local fire = row.fire
		row.icon:SetTexture((C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(fire.recipe))
			or "Interface\\Icons\\Spell_Fire_Fire")
		row.name:SetText(fire.name)
		row.holds:SetText(GREY .. "holds|r " .. fire.holds)
		Place(row, Rt, y, 22)
		y = y + 22
	end
	y = y + 8

	-- What the buffs have brought in.
	y = PlaceHeader(f.caughtHeader, y)
	for _, chip in ipairs(f.chips) do
		chip:Hide()
	end
	local used, any = 0, false
	for i, c in ipairs(Camp.CRAFTS) do
		local row = f.records[i]
		local r = c.buff and Camp.Record(c.key)
		local show = r and r.catches > 0
		if row then
			row:SetShown(show or false)
		end
		if show then
			any = true
			row.label:SetText(GOLD .. c.buffName .. "|r")
			row.value:SetText(string.format("%d catch%s", r.catches, r.catches == 1 and "" or "es"))
			Place(row, Rt, y, 20)
			y = y + 22
			local items = {}
			for id, n in pairs(r.items) do
				items[#items + 1] = { id = id, n = n }
			end
			table.sort(items, function(a, b)
				return a.n > b.n
			end)
			local x = EDGE + 4
			for _, item in ipairs(items) do
				used = used + 1
				local chip = f.chips[used]
				if not chip then
					chip = CreateFrame("Frame", nil, Rt)
					chip:SetSize(26, 26)
					chip.icon = Icon(chip, 26)
					chip.icon:SetAllPoints()
					chip.count = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline")
					chip.count:SetPoint("BOTTOMRIGHT", 1, 1)
					chip:EnableMouse(true)
					chip:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetItemByID(self.id)
						GameTooltip:AddLine(string.format("%d caught with %s on.", self.n, self.buffName), 1, 1, 1)
						GameTooltip:Show()
					end)
					chip:SetScript("OnLeave", GameTooltip_Hide)
					page.hovers[#page.hovers + 1] = chip
					f.chips[used] = chip
				end
				if x + 26 > EDGE + width then
					x, y = EDGE + 4, y + 30
				end
				chip.icon:SetTexture(C_Item.GetItemIconByID(item.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
				chip.count:SetText(item.n)
				chip:ClearAllPoints()
				chip:SetPoint("TOPLEFT", Rt, "TOPLEFT", x, -y)
				chip:Show()
				chip.id, chip.n, chip.buffName = item.id, item.n, c.buffName
				x = x + 30
			end
			y = y + 34
		end
	end
	f.nothing:SetShown(not any)
	if not any then
		f.nothing:SetWidth(width - 8)
		f.nothing:ClearAllPoints()
		f.nothing:SetPoint("TOPLEFT", Rt, "TOPLEFT", EDGE + 4, -y)
	end
end

local function CreatePage()
	local UI = ns.UI
	local f, inset = UI.CreateShell("OneCastCampFrame", "Camp",
		C_Item.GetItemIconByID(279966) or "Interface\\Icons\\INV_Misc_Bag_EnchantedRunecloth")
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
	UI.RememberPosition(f, "camp")

	-- Two columns, each with its own headers.
	f.left = CreateFrame("Frame", nil, inset)
	f.left:SetPoint("TOPLEFT")
	f.left:SetPoint("BOTTOMRIGHT", inset, "BOTTOM", 0, 0)
	f.right = CreateFrame("Frame", nil, inset)
	f.right:SetPoint("TOPLEFT", inset, "TOP", 0, 0)
	f.right:SetPoint("BOTTOMRIGHT")

	f.craftsHeader = UI.SectionHeader(f.left, -GAP)
	f.crafts = {}
	for i, craft in ipairs(Camp.CRAFTS) do
		f.crafts[i] = CraftCard(f.left, craft)
	end

	f.nowHeader = UI.SectionHeader(f.right, -GAP)
	f.nowHeader.text:SetText("Right now")
	local now = UI.Card(f.right)
	now.icon = Icon(now, 34)
	now.icon:SetPoint("TOPLEFT", 12, -8)
	now.title = Text(now, "GameFontHighlight")
	now.title:SetPoint("TOPLEFT", now.icon, "TOPRIGHT", 10, -1)
	now.sub = Text(now)
	now.sub:SetTextColor(0.78, 0.78, 0.78)
	now.sub:SetPoint("TOPLEFT", now.title, "BOTTOMLEFT", 0, -4)
	now.sub:SetWordWrap(true)
	now:EnableMouse(true)
	now:SetScript("OnEnter", function(self)
		if self.buff then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(self.buff)
			GameTooltip:Show()
		end
	end)
	now:SetScript("OnLeave", GameTooltip_Hide)
	f.now = now

	f.howHeader = UI.SectionHeader(f.right, -GAP)
	f.howHeader.text:SetText("How camps work")
	f.how = {}
	for i = 1, 3 do
		f.how[i] = InfoRow(f.right, i)
	end

	f.firesHeader = UI.SectionHeader(f.right, -GAP)
	f.firesHeader.text:SetText("Campfires")
	f.fires = {}
	for i, fire in ipairs(Camp.CAMPFIRES) do
		local row = CreateFrame("Frame", nil, f.right)
		UI.RowBackground(row, i)
		row.fire = fire
		row.icon = Icon(row, 18)
		row.icon:SetPoint("LEFT", 4, 0)
		row.name = Text(row)
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
		row.holds = Text(row)
		row.holds:SetPoint("RIGHT", -PAD, 0)
		row.holds:SetJustifyH("RIGHT")
		row:EnableMouse(true)
		row:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(fire.recipe)
			GameTooltip:AddLine(string.format("A Cooking recipe. Holds up to %d camp features.", fire.holds), 1, 1, 1, true)
			GameTooltip:AddLine(fire.from, 1, 0.82, 0, true)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", GameTooltip_Hide)
		page.hovers[#page.hovers + 1] = row
		f.fires[i] = row
	end

	f.caughtHeader = UI.SectionHeader(f.right, -GAP)
	f.caughtHeader.text:SetText("Caught with the buffs")
	f.records, f.chips = {}, {}
	for i, craft in ipairs(Camp.CRAFTS) do
		if craft.buff then
			local row = CreateFrame("Frame", nil, f.right)
			UI.RowBackground(row, 1)
			row.label = Text(row)
			row.label:SetPoint("LEFT", PAD, 0)
			row.value = Text(row)
			row.value:SetPoint("RIGHT", -PAD, 0)
			row.value:SetJustifyH("RIGHT")
			row:Hide()
			f.records[i] = row
		end
	end
	f.nothing = Text(f.right)
	f.nothing:SetTextColor(0.66, 0.66, 0.66)
	f.nothing:SetWordWrap(true)
	f.nothing:SetText("Nothing yet. What you catch with Uncommon or Rare Fishing on shows here, to see what "
		.. "their extra rewards really are.")

	f:SetScript("OnShow", Camp.PaintPage)
	f:Hide()
	ns.Hub.Attach("camp", f)
	return f
end

-- The Camp page, from the window's Camp tab or /onecast camp.
function Camp.ShowPage()
	page = page or CreatePage()
	page:Show()
	Camp.PaintPage()
end

function Camp.Page()
	return page
end
