-- OneCast collection book: every fish (FishData.lua) on two parchment pages, caught ones in
-- colour with a tick and your count, missing ones greyed out. Click a fish for its own
-- spread: the game's flavour text, a summary, your catches by character, where to catch
-- it with a map of the zone, and the recipes it's used in. Catch data comes from
-- Collection.lua and is shared by all your characters.

local ADDON, ns = ...

local Book = {}
ns.Book = Book

local WIDTH, HEIGHT = 840, 580
local COLS, ROWS = 4, 3
local PER_PAGE = COLS * ROWS
local CELL_W, CELL_H = 86, 108
local MAX_ZONES, MAX_RECIPES, MAX_CHARS = 6, 4, 4
local MAP_W, MAP_H = 300, 128

local CATEGORIES = {
	{ key = "all", label = "All" },
	{ key = "fish", label = "Fish" },
	{ key = "special", label = "Special" },
	{ key = "trophy", label = "Trophies" },
	{ key = "bloated", label = "Bloated" },
}
local CAT_ORDER = { fish = 1, special = 2, trophy = 3, bloated = 4 }
local CAT_NAME = { fish = "Fish", special = "Special catch", trophy = "Trophy fish", bloated = "Bloated fish" }
local CAT_LEAD = {
	fish = "A fish",
	special = "An unusual catch",
	trophy = "A trophy fish, kept for its size rather than eaten",
	bloated = "A bloated fish that can hold a pearl or other treasure when opened",
}
local SHOW = { "all", "caught", "missing" }
local SHOW_LABEL = { all = "Showing: all", caught = "Showing: caught", missing = "Showing: missing" }

-- Parchment ink, as in the What's new window.
local INK = { 0.18, 0.10, 0.02 }
local INK_SOFT = { 0.36, 0.25, 0.14 }
local LEAD = "|cff7a2a00"
local SOFT = "|cff6b5233"

local frame
local state = { cat = "all", show = "all", spread = 1 }

local function TryCreate(frameType, name, parent, template)
	local ok, f = pcall(CreateFrame, frameType, name, parent, template)
	if ok then
		return f
	end
end

local function HasAtlas(atlas)
	return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) ~= nil
end

local function SizedFont(fs, fontObject, size)
	fs:SetFontObject(fontObject)
	local path, _, flags = fs:GetFont()
	if path then
		fs:SetFont(path, size, flags)
	end
end

-- Fish data ------------------------------------------------------------------------------

local function FishName(fish)
	return C_Item.GetItemNameByID(fish.id) or fish.name or ("item " .. fish.id)
end

local function FishIcon(fish)
	return C_Item.GetItemIconByID(fish.id) or fish.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function FishQuality(fish)
	return C_Item.GetItemQualityByID(fish.id) or fish.quality or 1
end

-- Lowest zone fishing level among the fish's zones: its easiest waters.
local function EasiestSkill(fish)
	local best
	for _, zone in ipairs(fish.zones or {}) do
		local skill = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[zone]
		if skill and skill > 1 and (not best or skill < best) then
			best = skill
		end
	end
	return best
end

local function AllFish()
	local list = {}
	for _, fish in ipairs(ns.FISH) do
		list[#list + 1] = fish
	end
	for _, found in ipairs(ns.Collection.Discovered()) do
		found.cat, found.zones = "fish", {}
		list[#list + 1] = found
	end
	return list
end

local function Progress()
	local caught, total = 0, 0
	for _, fish in ipairs(AllFish()) do
		total = total + 1
		if ns.Collection.Get(fish.id).total > 0 then
			caught = caught + 1
		end
	end
	return caught, total
end

-- The fish on show: chosen category and caught/missing filter, easiest waters first.
local function Filtered()
	local out = {}
	for _, fish in ipairs(AllFish()) do
		if state.cat == "all" or fish.cat == state.cat then
			local info = ns.Collection.Get(fish.id)
			local caught = info.total > 0
			if state.show == "all" or (state.show == "caught") == caught then
				out[#out + 1] = { fish = fish, info = info, skill = EasiestSkill(fish) }
			end
		end
	end
	table.sort(out, function(a, b)
		local ca, cb = CAT_ORDER[a.fish.cat] or 9, CAT_ORDER[b.fish.cat] or 9
		if ca ~= cb then
			return ca < cb
		end
		local sa, sb = a.skill or 999, b.skill or 999
		if sa ~= sb then
			return sa < sb
		end
		return FishName(a.fish) < FishName(b.fish)
	end)
	return out
end

-- The game's own flavour text for the item, if it has any.
local function FlavorText(itemID)
	if not (C_TooltipInfo and C_TooltipInfo.GetItemByID) then
		return nil
	end
	local data = C_TooltipInfo.GetItemByID(itemID)
	for _, line in ipairs(data and data.lines or {}) do
		local text = line.leftText
		if text and text:match('^".+"$') then
			return text
		end
	end
end

local function Summary(fish)
	local zones = #(fish.zones or {}) + #(fish.more or {})
	local first = (fish.zones and fish.zones[1]) or (fish.more and fish.more[1] and fish.more[1][1])
	local text = CAT_LEAD[fish.cat] or "A catch"
	if zones > 0 then
		text = text .. string.format(" found in %d zone%s, most often in %s", zones, zones == 1 and "" or "s", first)
	end
	text = text .. "."
	local skill = EasiestSkill(fish)
	if skill then
		text = text .. string.format(" Its easiest waters need %d Fishing so none get away.", skill)
	end
	if fish.recipes and #fish.recipes > 0 then
		local byProf, order = {}, {}
		for _, recipe in ipairs(fish.recipes) do
			if not byProf[recipe[3]] then
				order[#order + 1] = recipe[3]
			end
			byProf[recipe[3]] = (byProf[recipe[3]] or 0) + 1
		end
		local parts = {}
		for _, prof in ipairs(order) do
			parts[#parts + 1] = string.format("%d %s recipe%s", byProf[prof], prof, byProf[prof] == 1 and "" or "s")
		end
		text = text .. " Used in " .. table.concat(parts, " and ") .. "."
	end
	if fish.discovered then
		text = text .. " Not in OneCast's records yet: you found this one yourself."
	end
	return text
end

-- Zone maps ------------------------------------------------------------------------------

local zoneMaps
local function ZoneMapID(zone)
	if not zoneMaps then
		zoneMaps = {}
		for mapID = 1, 3000 do
			local info = C_Map.GetMapInfo(mapID)
			if info and info.name and info.mapType == (Enum.UIMapType and Enum.UIMapType.Zone or 3) then
				zoneMaps[info.name] = zoneMaps[info.name] or mapID
			end
		end
	end
	return zoneMaps[zone]
end

-- Draw a zone's map art, scaled to fit the box. Returns the map ID, or nil if none.
local function DrawMap(box, zone)
	for _, tile in ipairs(box.tiles) do
		tile:Hide()
	end
	local mapID = zone and ZoneMapID(zone)
	local layers = mapID and C_Map.GetMapArtLayers(mapID)
	local layer = layers and layers[1]
	local files = layer and C_Map.GetMapArtLayerTextures(mapID, 1)
	if not (files and #files > 0) then
		box.empty:Show()
		return nil
	end
	box.empty:Hide()
	local cols = math.ceil(layer.layerWidth / layer.tileWidth)
	local scale = math.min(MAP_W / layer.layerWidth, MAP_H / layer.layerHeight)
	local offX = (MAP_W - layer.layerWidth * scale) / 2
	local offY = (MAP_H - layer.layerHeight * scale) / 2
	for i, file in ipairs(files) do
		local tile = box.tiles[i]
		if not tile then
			tile = box:CreateTexture(nil, "ARTWORK")
			box.tiles[i] = tile
		end
		local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
		tile:SetTexture(file)
		tile:SetSize(layer.tileWidth * scale, layer.tileHeight * scale)
		tile:ClearAllPoints()
		tile:SetPoint("TOPLEFT", box, "TOPLEFT", offX + col * layer.tileWidth * scale,
			-(offY + row * layer.tileHeight * scale))
		tile:Show()
	end
	return mapID
end

local function OpenZoneMap(mapID)
	if not mapID then
		return
	end
	if InCombatLockdown() then
		ns.Print("the map can't be opened from here in combat.")
	elseif OpenWorldMap then
		OpenWorldMap(mapID)
	elseif WorldMapFrame then
		ShowUIPanel(WorldMapFrame)
		WorldMapFrame:SetMapID(mapID)
	end
end

-- Page text pool -------------------------------------------------------------------------
-- Each detail page reuses its strings, textures and zone buttons between fish.

local function NewPool(page)
	return { page = page, strings = {}, textures = {}, buttons = {}, s = 0, t = 0, b = 0 }
end

local function ResetPool(pool)
	for _, list in ipairs({ pool.strings, pool.textures, pool.buttons }) do
		for _, region in ipairs(list) do
			region:Hide()
		end
	end
	pool.s, pool.t, pool.b = 0, 0, 0
end

local function PoolString(pool, fontObject, size, color)
	pool.s = pool.s + 1
	local fs = pool.strings[pool.s]
	if not fs then
		fs = pool.page:CreateFontString(nil, "OVERLAY")
		pool.strings[pool.s] = fs
	end
	SizedFont(fs, fontObject, size)
	fs:SetTextColor(color[1], color[2], color[3])
	fs:SetShadowOffset(0, 0)
	fs:SetJustifyH("LEFT")
	fs:SetWordWrap(true)
	fs:SetWidth(0)
	fs:ClearAllPoints()
	fs:Show()
	return fs
end

local function PoolTexture(pool)
	pool.t = pool.t + 1
	local tex = pool.textures[pool.t]
	if not tex then
		tex = pool.page:CreateTexture(nil, "ARTWORK")
		pool.textures[pool.t] = tex
	end
	tex:ClearAllPoints()
	tex:SetTexCoord(0, 1, 0, 1)
	tex:SetVertexColor(1, 1, 1, 1)
	tex:SetDesaturated(false)
	tex:Show()
	return tex
end

local function PoolButton(pool)
	pool.b = pool.b + 1
	local b = pool.buttons[pool.b]
	if not b then
		b = CreateFrame("Button", nil, pool.page)
		b:SetHeight(18)
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetAllPoints()
		b.bg:SetColorTexture(0.55, 0.40, 0.15, 0.25)
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		b.left = b:CreateFontString(nil, "OVERLAY")
		b.left:SetPoint("LEFT", 6, 0)
		b.right = b:CreateFontString(nil, "OVERLAY")
		b.right:SetPoint("RIGHT", -6, 0)
		for _, fs in ipairs({ b.left, b.right }) do
			SizedFont(fs, QuestFont, 13)
			fs:SetShadowOffset(0, 0)
		end
		pool.buttons[pool.b] = b
	end
	b:ClearAllPoints()
	b:Show()
	return b
end

-- Heading with a rule running to the page edge; returns its height.
local function Heading(pool, text, x, y, right)
	local heading = PoolString(pool, QuestTitleFont, 17, INK)
	heading:SetText(text)
	heading:SetPoint("TOPLEFT", pool.page, "TOPLEFT", x, -y)
	local rule = PoolTexture(pool)
	rule:SetColorTexture(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.45)
	rule:SetHeight(1)
	rule:SetPoint("LEFT", heading, "RIGHT", 10, 0)
	rule:SetPoint("RIGHT", pool.page, "RIGHT", -right, 0)
	return heading:GetStringHeight() + 8
end

-- Grid -----------------------------------------------------------------------------------

local function QualityColor(quality)
	return ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
end

local function CreateCell(parent)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(CELL_W, CELL_H)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetSize(46, 46)
	b.icon:SetPoint("TOP", 0, -4)
	b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	b.border = b:CreateTexture(nil, "OVERLAY")
	b.border:SetTexture("Interface\\Common\\WhiteIconFrame")
	b.border:SetAllPoints(b.icon)
	b.check = b:CreateTexture(nil, "OVERLAY", nil, 2)
	b.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
	b.check:SetSize(18, 18)
	b.check:SetPoint("CENTER", b.icon, "TOPRIGHT", -2, -2)
	b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	b.count:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT", -2, 2)
	b.name = b:CreateFontString(nil, "OVERLAY")
	SizedFont(b.name, QuestFont, 12)
	b.name:SetShadowOffset(0, 0)
	b.name:SetWidth(CELL_W - 2)
	b.name:SetPoint("TOP", b.icon, "BOTTOM", 0, -5)
	b.name:SetJustifyH("CENTER")
	b.name:SetWordWrap(true)
	if b.name.SetMaxLines then
		b.name:SetMaxLines(3)
	end
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(b.icon)
	hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	hl:SetBlendMode("ADD")
	b:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		Book.ShowFish(self.fishID)
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetItemByID(self.fishID)
		local info = ns.Collection.Get(self.fishID)
		GameTooltip:AddLine(" ")
		if info.total > 0 then
			GameTooltip:AddLine(string.format("Caught %d time%s on %d character%s", info.total,
				info.total == 1 and "" or "s", #info.chars, #info.chars == 1 and "" or "s"), 0.6, 0.8, 1)
		else
			GameTooltip:AddLine("Not caught yet", 0.7, 0.7, 0.7)
		end
		GameTooltip:AddLine("Click to open its page", 0.6, 0.8, 1)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	return b
end

local function FillCell(cell, entry)
	local fish, info = entry.fish, entry.info
	local caught = info.total > 0
	cell.fishID = fish.id
	cell.icon:SetTexture(FishIcon(fish))
	cell.icon:SetDesaturated(not caught)
	cell.icon:SetVertexColor(caught and 1 or 0.55, caught and 1 or 0.55, caught and 1 or 0.55)
	local color = QualityColor(FishQuality(fish))
	if caught and color then
		cell.border:SetVertexColor(color.r, color.g, color.b)
	else
		cell.border:SetVertexColor(0.4, 0.35, 0.3)
	end
	cell.check:SetShown(caught)
	cell.count:SetText(caught and info.total > 1 and info.total or "")
	cell.name:SetText(FishName(fish))
	local ink = caught and INK or INK_SOFT
	cell.name:SetTextColor(ink[1], ink[2], ink[3], caught and 1 or 0.75)
	cell:Show()
end

local function RenderGrid()
	local list = Filtered()
	state.list = list
	local spreads = math.max(1, math.ceil(#list / (PER_PAGE * 2)))
	state.spread = math.min(state.spread, spreads)
	local start = (state.spread - 1) * PER_PAGE * 2
	for p, page in ipairs(frame.pages) do
		for i, cell in ipairs(page.cells) do
			local entry = list[start + (p - 1) * PER_PAGE + i]
			if entry then
				FillCell(cell, entry)
			else
				cell:Hide()
			end
		end
		page.number:SetText((state.spread - 1) * 2 + p)
	end
	local label = "Fish of Azeroth"
	for _, cat in ipairs(CATEGORIES) do
		if cat.key == state.cat and cat.key ~= "all" then
			label = cat.label
		end
	end
	frame.pages[1].title:SetText(label)
	frame.pages[2].title:SetText(#list == 0 and "" or string.format("%d shown", #list))
	frame.empty:SetShown(#list == 0)
	frame.pageLabel:SetText(string.format("Pages %d-%d of %d", state.spread * 2 - 1, state.spread * 2, spreads * 2))
	frame.prev:SetEnabled(state.spread > 1)
	frame.next:SetEnabled(state.spread < spreads)
end

-- Fish page ------------------------------------------------------------------------------

local function ZoneRows(fish, info)
	local rows, seen = {}, {}
	for _, zone in ipairs(fish.zones or {}) do
		rows[#rows + 1] = { zone = zone }
		seen[zone] = true
	end
	for _, extra in ipairs(fish.more or {}) do
		if not seen[extra[1]] then
			rows[#rows + 1] = { zone = extra[1], tag = extra[2] }
			seen[extra[1]] = true
		end
	end
	for zone in pairs(info.zones) do
		if not seen[zone] then
			rows[#rows + 1] = { zone = zone, tag = "found by you" }
			seen[zone] = true
		end
	end
	return rows
end

local function RenderLeft(fish, info)
	local pool = frame.leftPool
	local page = pool.page
	ResetPool(pool)
	local x, width = 32, math.max(page:GetWidth(), 400) - 64

	local icon = PoolTexture(pool)
	icon:SetTexture(FishIcon(fish))
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon:SetSize(56, 56)
	icon:SetPoint("TOPLEFT", page, "TOPLEFT", x, -30)
	icon:SetDesaturated(info.total == 0)
	local border = PoolTexture(pool)
	border:SetTexture("Interface\\Common\\WhiteIconFrame")
	border:SetAllPoints(icon)
	local color = QualityColor(FishQuality(fish))
	if color then
		border:SetVertexColor(color.r, color.g, color.b)
	end

	local name = PoolString(pool, QuestTitleFont, 22, INK)
	name:SetWidth(width - 70)
	name:SetText(FishName(fish))
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
	local kind = PoolString(pool, QuestFont, 13, INK_SOFT)
	local skill = EasiestSkill(fish)
	kind:SetText((CAT_NAME[fish.cat] or "Catch") .. (skill and ("  ·  " .. skill .. " Fishing") or ""))
	kind:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)

	local y = 30 + 56 + 18
	local function Paragraph(text, color, gap)
		local fs = PoolString(pool, QuestFont, 14, color)
		fs:SetWidth(width)
		fs:SetText(text)
		fs:SetPoint("TOPLEFT", page, "TOPLEFT", x, -y)
		y = y + fs:GetStringHeight() + (gap or 10)
	end

	local flavor = FlavorText(fish.id)
	if flavor then
		Paragraph(flavor, INK_SOFT)
	end
	Paragraph(Summary(fish), INK, 18)

	y = y + Heading(pool, "Your catches", x, y, 32)
	if info.total > 0 then
		Paragraph(string.format("Caught %s%d|r time%s on %d character%s.", LEAD, info.total,
			info.total == 1 and "" or "s", #info.chars, #info.chars == 1 and "" or "s"), INK, 6)
		for i, who in ipairs(info.chars) do
			if i > MAX_CHARS then
				Paragraph(string.format("%sand %d more|r", SOFT, #info.chars - MAX_CHARS), INK, 4)
				break
			end
			Paragraph(string.format("%s  %s%d|r", who.name, LEAD, who.count), INK, 4)
		end
		if info.first then
			y = y + 6
			Paragraph(string.format("%sFirst caught on %s by %s%s.|r", SOFT, date("%d %B %Y", info.first.time),
				info.first.char or "?", info.first.zone and (" in " .. info.first.zone) or ""), INK)
		end
	else
		local tip = fish.zones and fish.zones[1]
		Paragraph("Not caught yet." .. (tip and (" Try " .. tip .. ".") or ""), INK)
	end
end

local function RenderRight(fish, info)
	local pool = frame.rightPool
	local page = pool.page
	ResetPool(pool)
	local x, width = 32, math.max(page:GetWidth(), 400) - 64
	local y = 30

	y = y + Heading(pool, "Where to catch", x, y, 32)
	local rows = ZoneRows(fish, info)
	if not state.zone then
		state.zone = rows[1] and rows[1].zone
	end
	for i, row in ipairs(rows) do
		if i > MAX_ZONES then
			local more = PoolString(pool, QuestFont, 13, INK_SOFT)
			more:SetText(string.format("and %d more zone%s", #rows - MAX_ZONES, #rows - MAX_ZONES == 1 and "" or "s"))
			more:SetPoint("TOPLEFT", page, "TOPLEFT", x + 6, -y)
			y = y + 16
			break
		end
		local b = PoolButton(pool)
		b:SetPoint("TOPLEFT", page, "TOPLEFT", x, -y)
		b:SetWidth(width)
		b.bg:SetShown(row.zone == state.zone)
		b.left:SetText(row.zone .. (row.tag and (" " .. SOFT .. "(" .. row.tag .. ")|r") or ""))
		b.left:SetTextColor(INK[1], INK[2], INK[3])
		local needs = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[row.zone]
		local mine = info.zones[row.zone]
		local right = {}
		if needs and needs > 1 then
			right[#right + 1] = "needs " .. needs
		end
		if mine then
			right[#right + 1] = LEAD .. mine .. " caught|r"
		end
		b.right:SetText(table.concat(right, "  ·  "))
		b.right:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
		b:SetScript("OnClick", function()
			state.zone = row.zone
			Book.Refresh()
		end)
		y = y + 19
	end
	if #rows == 0 then
		local none = PoolString(pool, QuestFont, 14, INK_SOFT)
		none:SetText("No known waters yet. Catch one and OneCast will remember where.")
		none:SetWidth(width)
		none:SetPoint("TOPLEFT", page, "TOPLEFT", x, -y)
		y = y + none:GetStringHeight() + 6
	end

	-- Map of the selected zone.
	y = y + 8
	local map = frame.map
	map:ClearAllPoints()
	map:SetPoint("TOP", page, "TOP", 0, -y)
	map:Show()
	frame.mapID = DrawMap(map, state.zone)
	frame.mapCaption:SetText(state.zone or "")
	frame.openMap:SetEnabled(frame.mapID ~= nil)
	y = y + MAP_H + 34

	y = y + Heading(pool, "Used in", x, y, 32)
	local recipes = fish.recipes or {}
	for i, recipe in ipairs(recipes) do
		if i > MAX_RECIPES then
			local more = PoolString(pool, QuestFont, 13, INK_SOFT)
			more:SetText(string.format("and %d more", #recipes - MAX_RECIPES))
			more:SetPoint("TOPLEFT", page, "TOPLEFT", x + 18, -y)
			break
		end
		local dot = PoolTexture(pool)
		dot:SetTexture("Interface\\QuestFrame\\UI-Quest-BulletPoint")
		dot:SetSize(12, 12)
		dot:SetPoint("TOPLEFT", page, "TOPLEFT", x, -y - 1)
		local line = PoolString(pool, QuestFont, 14, INK)
		line:SetText(string.format("%s  %s%s %d|r", recipe[2], SOFT, recipe[3], recipe[4]))
		line:SetPoint("TOPLEFT", page, "TOPLEFT", x + 18, -y)
		y = y + 17
	end
	if #recipes == 0 then
		local none = PoolString(pool, QuestFont, 14, INK_SOFT)
		none:SetText("Not used in any recipe.")
		none:SetPoint("TOPLEFT", page, "TOPLEFT", x, -y)
	end
end

local function RenderFish()
	local entry
	for i, e in ipairs(state.list or {}) do
		if e.fish.id == state.fishID then
			entry, state.index = e, i
		end
	end
	if not entry then
		local fish = ns.FISH_BY_ID[state.fishID]
		if not fish then
			for _, found in ipairs(ns.Collection.Discovered()) do
				if found.id == state.fishID then
					fish = found
					found.cat, found.zones = "fish", {}
				end
			end
		end
		if not fish then
			state.fishID = nil
			return false
		end
		entry, state.index = { fish = fish }, nil
	end
	local info = ns.Collection.Get(entry.fish.id)
	RenderLeft(entry.fish, info)
	RenderRight(entry.fish, info)
	local count = state.list and #state.list or 0
	frame.pageLabel:SetText(state.index and string.format("%d of %d", state.index, count) or "")
	frame.prev:SetEnabled(state.index and state.index > 1 or false)
	frame.next:SetEnabled(state.index and state.index < count or false)
	return true
end

-- Window ---------------------------------------------------------------------------------

local function CreatePage(parent)
	local page = CreateFrame("Frame", nil, parent)
	local parchment = page:CreateTexture(nil, "BACKGROUND")
	parchment:SetAllPoints()
	if HasAtlas("QuestBG-Parchment") then
		parchment:SetAtlas("QuestBG-Parchment")
	else
		parchment:SetTexture("Interface\\QuestFrame\\QuestBG")
		parchment:SetTexCoord(0, 0.586, 0, 0.65)
	end
	page.title = page:CreateFontString(nil, "OVERLAY")
	SizedFont(page.title, QuestTitleFont, 18)
	page.title:SetTextColor(INK[1], INK[2], INK[3])
	page.title:SetShadowOffset(0, 0)
	page.title:SetPoint("TOP", 0, -20)
	page.number = page:CreateFontString(nil, "OVERLAY")
	SizedFont(page.number, QuestFont, 12)
	page.number:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
	page.number:SetShadowOffset(0, 0)
	page.number:SetPoint("BOTTOM", 0, 14)
	page.grid = CreateFrame("Frame", nil, page)
	page.grid:SetAllPoints()
	page.cells = {}
	local gridW = COLS * CELL_W
	for i = 1, PER_PAGE do
		local cell = CreateCell(page.grid)
		local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
		cell:SetPoint("TOPLEFT", page.grid, "TOP", -gridW / 2 + col * CELL_W, -52 - row * CELL_H)
		page.cells[i] = cell
	end
	page.detail = CreateFrame("Frame", nil, page)
	page.detail:SetAllPoints()
	return page
end

local function CreateWindow()
	local f = TryCreate("Frame", "OneCastBookFrame", UIParent, "ButtonFrameTemplate")
	if not f then
		f = CreateFrame("Frame", "OneCastBookFrame", UIParent, "BackdropTemplate")
		f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 24,
			insets = { left = 6, right = 6, top = 6, bottom = 6 } })
		local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -2, -2)
	end
	if f.SetTitle then
		f:SetTitle("Fishing Collection")
	end
	if ns.SetPortrait then
		ns.SetPortrait(f, "Interface\\Icons\\INV_Misc_Book_09")
	end
	f:SetSize(WIDTH, HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	tinsert(UISpecialFrames, f:GetName())

	local inset = f.Inset or CreateFrame("Frame", nil, f)
	inset:ClearAllPoints()
	inset:SetPoint("TOPLEFT", 4, -60)
	inset:SetPoint("BOTTOMRIGHT", -6, 30)

	-- Category tabs, like the stats window's.
	f.Tabs = {}
	for i, cat in ipairs(CATEGORIES) do
		local tab = TryCreate("Button", "OneCastBookFrameTab" .. i, f, "PanelTopTabButtonTemplate")
			or CreateFrame("Button", "OneCastBookFrameTab" .. i, f, "UIPanelButtonTemplate")
		tab:SetID(i)
		tab:SetText(cat.label)
		if not tab.Text and tab:GetWidth() < 10 then
			tab:SetSize(80, 22)
		end
		if i == 1 then
			tab:SetPoint("BOTTOMLEFT", inset, "TOPLEFT", 62, 0)
		else
			tab:SetPoint("LEFT", f.Tabs[i - 1], "RIGHT", 2, 0)
		end
		tab:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
			state.cat, state.spread, state.fishID = cat.key, 1, nil
			Book.Refresh()
		end)
		tab.cat = cat.key
		f.Tabs[i] = tab
	end
	if PanelTemplates_SetNumTabs then
		PanelTemplates_SetNumTabs(f, #CATEGORIES)
	end

	-- Progress, top right.
	f.progressText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.progressText:SetPoint("TOPRIGHT", -24, -32)
	f.progress = CreateFrame("StatusBar", nil, f)
	f.progress:SetSize(170, 8)
	f.progress:SetPoint("TOPRIGHT", f.progressText, "BOTTOMRIGHT", 0, -4)
	f.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f.progress:SetStatusBarColor(0.16, 0.36, 0.86)
	f.progress:SetMinMaxValues(0, 1)
	local progressBg = f.progress:CreateTexture(nil, "BACKGROUND")
	progressBg:SetAllPoints()
	progressBg:SetColorTexture(0, 0, 0, 0.6)

	-- Two parchment pages.
	f.pages = {}
	for p = 1, 2 do
		local page = CreatePage(inset)
		page:SetPoint("TOP", inset, "TOP", 0, -6)
		page:SetPoint("BOTTOM", inset, "BOTTOM", 0, 6)
		if p == 1 then
			page:SetPoint("LEFT", inset, "LEFT", 6, 0)
			page:SetPoint("RIGHT", inset, "CENTER", -3, 0)
		else
			page:SetPoint("LEFT", inset, "CENTER", 3, 0)
			page:SetPoint("RIGHT", inset, "RIGHT", -6, 0)
		end
		f.pages[p] = page
	end
	f.leftPool = NewPool(f.pages[1].detail)
	f.rightPool = NewPool(f.pages[2].detail)

	f.empty = f.pages[1].grid:CreateFontString(nil, "OVERLAY")
	SizedFont(f.empty, QuestFont, 15)
	f.empty:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
	f.empty:SetShadowOffset(0, 0)
	f.empty:SetPoint("TOP", 0, -80)
	f.empty:SetText("Nothing here yet.")

	-- Map box on the fish page, with its caption and an Open map button.
	f.map = CreateFrame("Frame", nil, f.pages[2].detail, "BackdropTemplate")
	f.map:SetSize(MAP_W, MAP_H)
	f.map:SetClipsChildren(true)
	f.map:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	f.map:SetBackdropColor(0.10, 0.08, 0.05, 0.25)
	f.map:SetBackdropBorderColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.8)
	f.map.tiles = {}
	f.map.empty = f.map:CreateFontString(nil, "OVERLAY")
	SizedFont(f.map.empty, QuestFont, 13)
	f.map.empty:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
	f.map.empty:SetShadowOffset(0, 0)
	f.map.empty:SetPoint("CENTER")
	f.map.empty:SetText("No map for this zone.")
	f.mapCaption = f.pages[2].detail:CreateFontString(nil, "OVERLAY")
	SizedFont(f.mapCaption, QuestFont, 13)
	f.mapCaption:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
	f.mapCaption:SetShadowOffset(0, 0)
	f.mapCaption:SetPoint("TOPLEFT", f.map, "BOTTOMLEFT", 0, -8)
	f.openMap = CreateFrame("Button", nil, f.pages[2].detail, "UIPanelButtonTemplate")
	f.openMap:SetSize(96, 20)
	f.openMap:SetPoint("TOPRIGHT", f.map, "BOTTOMRIGHT", 0, -4)
	f.openMap:SetText("Open map")
	f.openMap:SetScript("OnClick", function()
		OpenZoneMap(frame.mapID)
	end)

	-- Bottom bar.
	f.back = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.back:SetSize(150, 22)
	f.back:SetPoint("BOTTOMLEFT", 10, 4)
	f.back:SetScript("OnClick", function()
		if state.fishID then
			state.fishID, state.zone = nil, nil
		else
			local i = 1
			for n, show in ipairs(SHOW) do
				if show == state.show then
					i = n % #SHOW + 1
				end
			end
			state.show, state.spread = SHOW[i], 1
		end
		Book.Refresh()
	end)
	f.pageLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.pageLabel:SetPoint("BOTTOM", 0, 9)
	f.next = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.next:SetSize(100, 22)
	f.next:SetPoint("BOTTOMRIGHT", -10, 4)
	f.next:SetText("Next")
	f.next:SetScript("OnClick", function()
		if state.fishID and state.index then
			state.fishID, state.zone = state.list[state.index + 1].fish.id, nil
		else
			state.spread = state.spread + 1
		end
		Book.Refresh()
	end)
	f.prev = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.prev:SetSize(100, 22)
	f.prev:SetPoint("RIGHT", f.next, "LEFT", -4, 0)
	f.prev:SetText("Previous")
	f.prev:SetScript("OnClick", function()
		if state.fishID and state.index then
			state.fishID, state.zone = state.list[state.index - 1].fish.id, nil
		else
			state.spread = state.spread - 1
		end
		Book.Refresh()
	end)

	f:EnableMouseWheel(true)
	f:SetScript("OnMouseWheel", function(_, delta)
		if delta < 0 and f.next:IsEnabled() then
			f.next:Click()
		elseif delta > 0 and f.prev:IsEnabled() then
			f.prev:Click()
		end
	end)

	f:Hide()
	return f
end

function Book.Refresh()
	if not frame then
		return
	end
	for i, tab in ipairs(frame.Tabs) do
		if tab.cat == state.cat then
			if PanelTemplates_SetTab then
				PanelTemplates_SetTab(frame, i)
			else
				tab:LockHighlight()
			end
		elseif not PanelTemplates_SetTab then
			tab:UnlockHighlight()
		end
	end

	local caught, total = Progress()
	frame.progressText:SetText(string.format("Collected |cffffffff%d|r of %d", caught, total))
	frame.progress:SetValue(total > 0 and caught / total or 0)

	state.list = state.list or Filtered()
	local showFish = state.fishID ~= nil and RenderFish()
	if not showFish then
		RenderGrid()
	end
	for _, page in ipairs(frame.pages) do
		page.grid:SetShown(not showFish)
		page.detail:SetShown(showFish)
		page.title:SetShown(not showFish)
		page.number:SetShown(not showFish)
	end
	frame.back:SetText(showFish and "Back to collection" or SHOW_LABEL[state.show])
end

function Book.RefreshIfShown()
	if frame and frame:IsShown() then
		state.list = nil
		Book.Refresh()
	end
end

function Book.ShowFish(itemID)
	state.fishID, state.zone = itemID, nil
	Book.Refresh()
end

function Book.Show()
	frame = frame or CreateWindow()
	ns.Collection.SyncCharacter()
	state.list = nil
	frame:Show()
	Book.Refresh()
end

function Book.Toggle()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		Book.Show()
	end
end

-- Global for the "Fishing collection" key binding.
function OneCast_ToggleBook()
	Book.Toggle()
end

-- Item names and icons arrive from the server over time; redraw when they do.
local pending = false
local events = CreateFrame("Frame")
events:RegisterEvent("ITEM_DATA_LOAD_RESULT")
events:SetScript("OnEvent", function()
	if frame and frame:IsShown() and not pending then
		pending = true
		C_Timer.After(0.2, function()
			pending = false
			Book.RefreshIfShown()
		end)
	end
end)
