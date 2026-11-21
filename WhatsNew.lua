-- OneCast "What's new" window: versions listed on the left, the selected version's notes on the
-- right, the page-turn arrows under the list. Built from the same parts as the window's other
-- pages: its shell, gold section headers, shaded rows and cards. Also the login chat line
-- announcing the version, with a clickable [What's new] link.
--
-- Laid out to be read at a glance: each section heading in its own colour (New, Changed,
-- Fixed, Reported by), and each section a card with a bar in that colour and its changes as
-- bullet points: the change in white, what it means in grey after it.

local ADDON, ns = ...

local WhatsNew = {}
ns.WhatsNew = WhatsNew

local PROJECT_URL = "https://www.curseforge.com/wow/addons/onecast"
local LINK = "addon:" .. ADDON .. ":whatsnew"
local WIDTH, HEIGHT = 840, ns.UI.PAGE_HEIGHT -- as wide as the collection book, as tall as every page
local LIST_WIDTH = 300
local ROW_HEIGHT = 36
local EDGE, GAP, HEADER = 10, 8, 24
local LIST_TOP = -GAP - HEADER - 4 -- the first version, under the list's header
local ARROWS = 34                   -- the page-turn arrows under the list

-- Each section's colour on the dark page, for its heading and its cards' bars.
local SECTION_COLOR = {
	New = { 0.12, 1, 0 },
	Changed = { 0.4, 0.7, 1 },
	Fixed = { 1, 0.6, 0.2 },
}
local REPORTED_COLOR = { 0.8, 0.55, 1 }
local GREY = "|cff9d9d9d"

local function SectionColor(name)
	return name:find("^Reported by") and REPORTED_COLOR or SECTION_COLOR[name] or { 1, 0.82, 0 }
end

local frame
local selected = 1

local function CountChanges(release)
	local n = 0
	for _, section in ipairs(release.sections) do
		n = n + #section[2]
	end
	return n
end

local function TotalChanges()
	local n = 0
	for _, release in ipairs(ns.CHANGELOG) do
		n = n + CountChanges(release)
	end
	return n
end

-- Page --------------------------------------------------------------------------------
-- Pooled: each version's notes reuse the last one's headings and cards.

local pool = { headings = {}, cards = {}, bullets = {}, used = { headings = 0, cards = 0, bullets = 0 } }

local function Heading(content)
	pool.used.headings = pool.used.headings + 1
	local h = pool.headings[pool.used.headings]
	if not h then
		h = CreateFrame("Frame", nil, content)
		h.bar = h:CreateTexture(nil, "ARTWORK")
		h.bar:SetSize(4, 16)
		h.bar:SetPoint("LEFT")
		h.text = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		h.text:SetPoint("LEFT", h.bar, "RIGHT", 8, 0)
		h.text:SetJustifyH("LEFT")
		pool.headings[pool.used.headings] = h
	end
	h:ClearAllPoints()
	h:Show()
	return h
end

-- A section's card, and its bullet points: a dot in the section's colour, the change in white
-- and what it means in grey after it, wrapping under itself.
local function Card(content)
	pool.used.cards = pool.used.cards + 1
	local c = pool.cards[pool.used.cards]
	if not c then
		c = ns.UI.Card(content)
		pool.cards[pool.used.cards] = c
	end
	c:ClearAllPoints()
	c:Show()
	return c
end

local function Bullet(card)
	pool.used.bullets = pool.used.bullets + 1
	local b = pool.bullets[pool.used.bullets]
	if not b then
		b = {}
		b.dot = card:CreateTexture(nil, "ARTWORK")
		b.dot:SetSize(5, 5)
		b.text = card:CreateFontString(nil, "OVERLAY", "OneCastFontHighlightSmall")
		b.text:SetJustifyH("LEFT")
		b.text:SetWordWrap(true)
		b.text:SetSpacing(2)
		pool.bullets[pool.used.bullets] = b
	end
	b.dot:SetParent(card)
	b.text:SetParent(card)
	b.dot:ClearAllPoints()
	b.text:ClearAllPoints()
	b.dot:Show()
	b.text:Show()
	return b
end

local function RenderPage()
	local release = ns.CHANGELOG[selected]
	local content = frame.content
	for _, h in ipairs(pool.headings) do
		h:Hide()
	end
	for _, c in ipairs(pool.cards) do
		c:Hide()
	end
	for _, b in ipairs(pool.bullets) do
		b.dot:Hide()
		b.text:Hide()
	end
	pool.used.headings, pool.used.cards, pool.used.bullets = 0, 0, 0

	-- The header: the version, and when and how much on its right.
	local count = CountChanges(release)
	frame.pageHeader.text:SetText("Version " .. release.version)
	frame.meta:SetText(string.format("%s  ·  %d change%s%s", release.date, count, count == 1 and "" or "s",
		release.version == ns.VERSION and "  ·  |cff20ff20installed|r" or ""))

	local width = content:GetWidth()
	local y = 4
	for _, section in ipairs(release.sections) do
		local color = SectionColor(section[1])
		local h = Heading(content)
		h.bar:SetColorTexture(color[1], color[2], color[3], 0.95)
		h.text:SetText(section[1])
		h.text:SetTextColor(color[1], color[2], color[3])
		h:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
		h:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
		h:SetHeight(18)
		y = y + 24
		-- One card for the section, its changes as bullet points down it.
		local c = Card(content)
		c:SetColor(color[1], color[2], color[3], 0.08)
		local by = 9
		for _, bullet in ipairs(section[2]) do
			local b = Bullet(c)
			b.dot:SetColorTexture(color[1], color[2], color[3], 1)
			b.dot:SetPoint("TOPLEFT", c, "TOPLEFT", 14, -by - 5)
			b.text:SetWidth(width - 40)
			b.text:SetText("|cffffffff" .. bullet[1]:gsub("%.$", "") .. "|r  |cffc8c8c8" .. bullet[2] .. "|r")
			b.text:SetPoint("TOPLEFT", c, "TOPLEFT", 28, -by)
			by = by + (b.text:GetStringHeight() or 12) + 6
		end
		c:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
		c:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
		c:SetHeight(by + 4)
		y = y + by + 4 + 14
	end

	content:SetHeight(math.max(y, 1))
	frame.ScrollTo(0)
end

-- List ----------------------------------------------------------------------------------

-- The list shows as many versions as fit, scrolled so the selected one is always in view
-- (the arrows and the mouse wheel move through the rest).
local firstShown = 1

local function Fit()
	return math.max(1, math.floor((HEIGHT - 60 - 28 + LIST_TOP - ARROWS - EDGE) / ROW_HEIGHT))
end

-- `free`: moved with the scroll bar, so the list needn't show the chosen version.
local function UpdateList(free)
	local fit = Fit()
	if not free then
		if selected < firstShown then
			firstShown = selected
		elseif selected >= firstShown + fit then
			firstShown = selected - fit + 1
		end
	end
	local most = math.max(1, #frame.rows - fit + 1)
	firstShown = math.max(1, math.min(firstShown, most))
	frame.scrollBar:SetHeight(fit * ROW_HEIGHT)
	frame.scrollBar:Set(firstShown - 1, most - 1, fit, #frame.rows)
	for i, row in ipairs(frame.rows) do
		local slot = i - firstShown
		row:SetShown(slot >= 0 and slot < fit)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", EDGE, LIST_TOP - slot * ROW_HEIGHT)
		row:SetPoint("TOPRIGHT", -EDGE - 12, LIST_TOP - slot * ROW_HEIGHT)
		local isSelected = i == selected
		row.selectedBg:SetShown(isSelected)
		row.selectedEdge:SetShown(isSelected)
		local c = isSelected and HIGHLIGHT_FONT_COLOR or NORMAL_FONT_COLOR
		row.label:SetTextColor(c.r, c.g, c.b)
	end
	frame.newer:SetEnabled(selected > 1)
	frame.older:SetEnabled(selected < #ns.CHANGELOG)
	local entry = ns.CHANGELOG[selected]
	frame.pageLabel:SetText(string.format("%s  " .. GREY .. "%d of %d|r", entry and entry.version or "", selected, #ns.CHANGELOG))
end

local function Select(index)
	selected = math.max(1, math.min(#ns.CHANGELOG, index))
	UpdateList()
	RenderPage()
end

-- Window --------------------------------------------------------------------------------

local function CreateWindow()
	local UI = ns.UI
	local f, inset = UI.CreateShell("OneCastWhatsNewFrame", "What's new in OneCast  " .. GREY .. "v" .. (ns.VERSION or "?") .. "|r",
		"Interface\\Icons\\INV_Scroll_03")
	f:SetSize(WIDTH, HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	UI.RememberPosition(f, "whatsNew")

	-- Right of the portrait, above the inset: how much there is.
	local summary = f:CreateFontString(nil, "OVERLAY", "OneCastFontHighlightSmall")
	summary:SetPoint("BOTTOMLEFT", inset, "TOPLEFT", 62, 6)
	summary:SetText(string.format("%d versions and %d changes, newest first. Pick one to read it.", #ns.CHANGELOG,
		TotalChanges()))

	-- Left: the version list, under its header.
	local list = CreateFrame("Frame", nil, inset)
	list:SetPoint("TOPLEFT")
	list:SetPoint("BOTTOMLEFT")
	list:SetWidth(LIST_WIDTH)
	local listHeader = UI.SectionHeader(list, -GAP)
	listHeader.text:SetText("Versions")
	local wheel = listHeader:CreateFontString(nil, "OVERLAY", "OneCastFontDisableSmall")
	wheel:SetPoint("RIGHT", -10, 0)
	wheel:SetText("mouse wheel to move")
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", function(_, delta)
		Select(selected - delta)
	end)

	f.rows = {}
	for i, release in ipairs(ns.CHANGELOG) do
		local row = CreateFrame("Button", nil, list)
		row:SetHeight(ROW_HEIGHT - 2)
		UI.RowBackground(row, i)
		-- Chosen: a gold wash with the window's bar down its left.
		row.selectedBg = row:CreateTexture(nil, "BACKGROUND", nil, 2)
		row.selectedBg:SetAllPoints()
		row.selectedBg:SetColorTexture(1, 0.82, 0, 0.12)
		row.selectedEdge = row:CreateTexture(nil, "BORDER")
		row.selectedEdge:SetPoint("TOPLEFT")
		row.selectedEdge:SetPoint("BOTTOMLEFT")
		row.selectedEdge:SetWidth(3)
		row.selectedEdge:SetColorTexture(1, 0.82, 0, 0.95)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		row.label:SetPoint("TOPLEFT", 12, -4)
		row.label:SetText("Version " .. release.version)
		row.date = row:CreateFontString(nil, "OVERLAY", "OneCastFontHighlightSmall")
		row.date:SetTextColor(0.78, 0.78, 0.78)
		row.date:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -2)
		local n = CountChanges(release)
		row.date:SetText(release.date .. "  ·  " .. n .. (n == 1 and " change" or " changes"))
		-- The one you're running.
		row.count = row:CreateFontString(nil, "OVERLAY", "OneCastFontGreenSmall")
		row.count:SetPoint("TOPRIGHT", -10, -6) -- on the version's line, clear of the date under it
		row.count:SetText(release.version == ns.VERSION and "Installed" or "")
		row:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			Select(i)
		end)
		f.rows[i] = row
	end
	-- Its scroll bar, for the versions that don't fit: drag it, or press the track.
	f.scrollBar = UI.ScrollBar(list, function(offset)
		firstShown = offset + 1
		UpdateList(true)
	end)
	f.scrollBar:SetPoint("TOPRIGHT", list, "TOPRIGHT", -EDGE + 2, LIST_TOP)

	-- Under the list: the page-turn arrows either side of which version this is.
	local function Tip(self, text)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(text)
		GameTooltip:Show()
	end
	f.newer = UI.PageButton(list, "Prev")
	f.newer:SetPoint("BOTTOMLEFT", EDGE - 2, 4)
	f.newer:SetScript("OnClick", function() Select(selected - 1) end)
	f.newer:SetScript("OnEnter", function(self) Tip(self, "Newer version") end)
	f.newer:SetScript("OnLeave", GameTooltip_Hide)
	f.pageLabel = list:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.pageLabel:SetPoint("LEFT", f.newer, "RIGHT", 6, 0)
	f.older = UI.PageButton(list, "Next")
	f.older:SetPoint("LEFT", f.pageLabel, "RIGHT", 6, 0)
	f.older:SetScript("OnClick", function() Select(selected + 1) end)
	f.older:SetScript("OnEnter", function(self) Tip(self, "Older version") end)
	f.older:SetScript("OnLeave", GameTooltip_Hide)

	-- Right: the version's header, and its notes scrolling under it.
	local page = CreateFrame("Frame", nil, inset)
	page:SetPoint("TOPLEFT", list, "TOPRIGHT", 0, 0)
	page:SetPoint("BOTTOMRIGHT")
	f.pageHeader = UI.SectionHeader(page, -GAP)
	f.meta = f.pageHeader:CreateFontString(nil, "OVERLAY", "OneCastFontHighlightSmall")
	f.meta:SetPoint("RIGHT", -10, 0)
	f.meta:SetJustifyH("RIGHT")

	-- The notes scroll with the window's own bar, as the version list does.
	local scroll = CreateFrame("ScrollFrame", "OneCastWhatsNewScroll", page)
	scroll:SetPoint("TOPLEFT", EDGE, LIST_TOP)
	scroll:SetPoint("BOTTOMRIGHT", -EDGE - 14, EDGE)
	scroll:EnableMouseWheel(true)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(WIDTH - 10 - LIST_WIDTH - 2 * EDGE - 14, 1)
	scroll:SetScrollChild(content)
	local bar
	local function MaxScroll()
		return math.max(0, math.floor((content:GetHeight() or 0) - (scroll:GetHeight() or 0)))
	end
	local function ScrollTo(pixels)
		scroll:SetVerticalScroll(math.max(0, math.min(MaxScroll(), pixels)))
		bar:Set(math.floor(scroll:GetVerticalScroll() or 0), MaxScroll(), scroll:GetHeight() or 0, content:GetHeight() or 0)
	end
	bar = UI.ScrollBar(page, ScrollTo)
	bar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -EDGE + 2, LIST_TOP)
	bar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -EDGE + 2, EDGE)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		ScrollTo((self:GetVerticalScroll() or 0) - delta * 40)
	end)
	f.scroll, f.content, f.notesBar, f.ScrollTo = scroll, content, bar, ScrollTo

	-- With a controller: the notes as one stop (the game's navigation can't reach a scroll bar
	-- beside its text). There, the right stick and the D-pad's up and down scroll them.
	local function ScrollBy(pixels)
		ScrollTo((scroll:GetVerticalScroll() or 0) + pixels)
	end
	local notes = CreateFrame("Button", nil, page)
	notes:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
	notes:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 0)
	notes:SetFrameLevel(scroll:GetFrameLevel() + 2)
	notes:EnableMouse(false) -- the mouse reads and wheels the page as ever
	notes.padScrollStop = true
	f.notes = notes
	f.padScrollOwns = function(button)
		return button == notes
	end
	if ns.Controller then
		ns.Controller.AdjustVertical(notes, function() ScrollBy(-60) end, function() ScrollBy(60) end)
	end

	-- Along the bottom: where to send requests, and the project page, selectable to copy.
	local footer = f:CreateFontString(nil, "OVERLAY", "OneCastFontHighlightSmall")
	footer:SetPoint("BOTTOMLEFT", 14, 9)
	footer:SetText("Feature requests and bug reports are welcome on CurseForge")
	local url = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	url:SetSize(290, 18) -- the whole address, never cut short
	url:SetFontObject("OneCastFontHighlightSmall") -- not the chat font text boxes come with
	url:SetPoint("LEFT", footer, "RIGHT", 14, 0)
	url:SetAutoFocus(false)
	url:SetText(PROJECT_URL)
	url:SetCursorPosition(0)
	url:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	url:SetScript("OnTextChanged", function(self)
		if self:GetText() ~= PROJECT_URL then
			self:SetText(PROJECT_URL)
			self:HighlightText()
		end
	end)
	url:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	local hint = f:CreateFontString(nil, "OVERLAY", "OneCastFontDisableSmall")
	hint:SetPoint("LEFT", url, "RIGHT", 8, 0)
	hint:SetText("click, then Ctrl+C")

	f:Hide()
	ns.Hub.Attach("news", f)
	return f
end

function WhatsNew.Show()
	frame = frame or CreateWindow()
	frame:Show()
	Select(1)
	if ns.db then
		ns.db.seenVersion = ns.VERSION
	end
	if ns.Hub and ns.Hub.UpdateBadges then
		ns.Hub.UpdateBadges()
	end
end

function WhatsNew.Toggle()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		WhatsNew.Show()
	end
end

-- Login announcement --------------------------------------------------------------------

local function ChatLink()
	return "|cff71d5ff|H" .. LINK .. "|h[What's new]|h|r"
end

-- Clicking [What's new] in chat.
hooksecurefunc("SetItemRef", function(link)
	if link == LINK then
		WhatsNew.Show()
	end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	-- After the login chat spam, so the line isn't buried.
	C_Timer.After(4, function()
		local db = ns.db
		if not db or db.loginMessage == false then
			return
		end
		-- Until the window has been opened for this version, point at it.
		if not db.seenVersion then
			ns.Print(string.format("|cffffffffv%s|r installed. See what it does: %s or /onecast new",
				ns.VERSION, ChatLink()))
		elseif db.seenVersion ~= ns.VERSION then
			ns.Print(string.format("updated to |cffffffffv%s|r. See what changed: %s or /onecast new",
				ns.VERSION, ChatLink()))
		else
			ns.Print(string.format("|cffffffffv%s|r loaded. %s  /onecast for options", ns.VERSION, ChatLink()))
		end
	end)
end)

