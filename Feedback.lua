-- OneCast feedback: a bug report, an idea or the data report, built in the window and copied
-- out. WoW can't open a web page or send anything itself, so the page builds the text (with the
-- version and setup if you like) and holds the links to paste it at: CurseForge's comments or a
-- GitHub issue. The data report (Report.lua) is this character's fishing numbers, with what
-- they've found that OneCast doesn't know. No character name, realm or guild in any of it.

local _, ns = ...

local Feedback = {}
ns.Feedback = Feedback

Feedback.LINKS = {
	{ label = "CurseForge", url = "https://www.curseforge.com/wow/addons/onecast/comments" },
	{ label = "GitHub", bug = "https://github.com/rynmon/OneCast/issues/new?template=bug-report.yml",
		idea = "https://github.com/rynmon/OneCast/issues/new?template=feature-request.yml",
		data = "https://github.com/rynmon/OneCast/issues/new?template=data-report.yml" },
}
local MAX_LETTERS = 2000
local LINK_ROW, LINK_WIDTH = 28, 480 -- wide enough for the longest address, whole

local PAGE_WIDTH, EDGE, GAP, PAD = 660, 10, 8, 10
local HEADER = 24
local GREY, GOOD, GOLD = "|cff9d9d9d", "|cff20ff20", "|cffffd100"
local page

local KINDS = {
	bug = { label = "Bug", title = "Bug report", ask = "What went wrong?",
		hint = "What you did, what you expected, and what happened instead." },
	idea = { label = "Idea", title = "Feature request", ask = "What would you like?",
		hint = "What it would do for you, and where in OneCast it would go." },
	data = { label = "Data report", ask = "What you've found",
		hint = "Nobody knows Forever's real fishing levels and loot. Your catches can tell: share them. The last line, the code, is all OneCast needs. No names." },
}
local KIND_ORDER = { "bug", "idea", "data" }
local KIND_WIDTH, KIND_STEP = 96, 102 -- three in the column: 10 + 2 * 102 + 96 = 310 of 315
local FOUND_ROWS = 40 -- findings shown at most; the report itself holds them all

local function Draft()
	local db = ns.db
	if not db then
		return { kind = "bug", text = "", setup = true }
	end
	db.feedback = db.feedback or { kind = "bug", text = "", setup = true }
	return db.feedback
end

-- Settings changed from their defaults, as "key=value", sorted.
local function ChangedSettings()
	local out = {}
	for key, default in pairs(ns.DEFAULTS or {}) do
		local value = ns.db and ns.db[key]
		if value ~= nil and value ~= default and type(value) ~= "table" then
			out[#out + 1] = key .. "=" .. tostring(value)
		end
	end
	table.sort(out)
	return out
end

-- Other addons turned on, by folder name.
local function OtherAddons()
	local out = {}
	local addons = C_AddOns
	local count = addons and addons.GetNumAddOns and addons.GetNumAddOns() or 0
	for i = 1, count do
		local name = addons.GetAddOnInfo(i)
		if type(name) == "string" and name ~= "OneCast" and addons.IsAddOnLoaded and addons.IsAddOnLoaded(i) then
			out[#out + 1] = name
		end
	end
	table.sort(out)
	return out
end

-- The version and setup, a fact a line.
function Feedback.SetupLines()
	local lines = {}
	local version, build = GetBuildInfo()
	lines[#lines + 1] = string.format("OneCast %s  ·  game %s (%s)  ·  %s", ns.VERSION or "?", tostring(version or "?"),
		tostring(build or "?"), GetLocale and GetLocale() or "?")
	-- Called on its own: "a and f()" would keep only f's first value, and the cap showed as 0.
	local rank, maxRank, modifier
	if ns.Stats then
		rank, maxRank, modifier = ns.Stats.FishingSkill()
	end
	if rank then
		lines[#lines + 1] = string.format("Fishing %d/%d%s", rank, maxRank or 0, (modifier or 0) > 0 and (" +" .. modifier) or "")
	end
	lines[#lines + 1] = "Controller: " .. ((ns.Controller and ns.Controller.Active and ns.Controller.Active()) and "yes" or "no")
	local changed = ChangedSettings()
	lines[#lines + 1] = "Settings changed: " .. (#changed > 0 and table.concat(changed, ", ") or "none")
	local addons = OtherAddons()
	lines[#lines + 1] = "Other addons: " .. (#addons > 0 and table.concat(addons, ", ") or "none")
	return lines
end

-- The whole text to paste.
function Feedback.Text()
	local draft = Draft()
	if draft.kind == "data" then
		return ns.Report and ns.Report.Text() or ""
	end
	local kind = KINDS[draft.kind] or KINDS.bug
	local body = (draft.text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local out = { kind.title, "", body ~= "" and body or "(nothing written yet)" }
	if draft.setup then
		out[#out + 1] = ""
		out[#out + 1] = "---"
		for _, line in ipairs(Feedback.SetupLines()) do
			out[#out + 1] = line
		end
	end
	return table.concat(out, "\n")
end

local function LinkFor(link)
	return link.url or link[Draft().kind] or link.bug
end

---------------------------------------------------------------------------------------------
-- The page: write it on the left; the text to copy and where to paste it on the right.

local function Text(parent, font)
	local fs = parent:CreateFontString(nil, "OVERLAY", font or "OneCastFontHighlightSmall")
	fs:SetJustifyH("LEFT")
	page.strings[#page.strings + 1] = fs
	return fs
end

-- A dark box with a thin border, for writing in and for copying from.
local function Box(parent)
	local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	if box.SetBackdrop then
		box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		box:SetBackdropColor(0, 0, 0, 0.45)
		box:SetBackdropBorderColor(0.4, 0.4, 0.42, 1)
	end
	local scroll = CreateFrame("ScrollFrame", nil, box)
	scroll:SetPoint("TOPLEFT", 8, -6)
	scroll:SetPoint("BOTTOMRIGHT", -8, 6)
	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(false)
	edit:SetFontObject("OneCastFontHighlightSmall")
	edit:SetTextInsets(0, 0, 0, 0)
	edit:SetScript("OnEscapePressed", edit.ClearFocus)
	scroll:SetScrollChild(edit)
	scroll:SetScript("OnSizeChanged", function(self, width)
		edit:SetWidth(width)
	end)
	-- Keep the cursor in view as you type, and scroll with the wheel.
	edit:SetScript("OnCursorChanged", function(_, _, y, _, height)
		local top = scroll:GetVerticalScroll()
		local view = scroll:GetHeight()
		y = -y
		if y < top then
			scroll:SetVerticalScroll(y)
		elseif y + height > top + view then
			scroll:SetVerticalScroll(math.max(0, y + height - view))
		end
	end)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local most = math.max(0, edit:GetHeight() - self:GetHeight())
		self:SetVerticalScroll(math.min(most, math.max(0, self:GetVerticalScroll() - delta * 24)))
	end)
	box:EnableMouse(true)
	box:SetScript("OnMouseDown", function()
		edit:SetFocus()
	end)
	box.edit, box.scroll = edit, scroll
	return box
end

-- A web address to copy: read-only, all of it selected when clicked.
local function LinkBox(parent)
	local box = ns.UI.TryCreate("EditBox", nil, parent, "InputBoxTemplate") or CreateFrame("EditBox", nil, parent)
	box:SetAutoFocus(false)
	box:SetFontObject("OneCastFontHighlightSmall")
	box:SetHeight(20)
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(self.url or "")
			self:HighlightText()
		end
	end)
	box:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
		page.status:SetText(GOLD .. "Link selected: Ctrl+C to copy, then paste it in your browser.|r")
	end)
	box:SetScript("OnEditFocusLost", function(self)
		self:HighlightText(0, 0)
		self:SetCursorPosition(0)
	end)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", box.ClearFocus)
	return box
end

-- The data report's findings, a row each: what was found, why it's worth sending, and whether
-- the report's been copied since.
local function FoundRow(parent, i)
	local UI = ns.UI
	local row = UI.Card(parent)
	row:SetIndex(i)
	row.title = Text(row, "OneCastFontNormalSmall")
	row.title:SetPoint("TOPLEFT", PAD, -6)
	row.title:SetWordWrap(true)
	row.tag = Text(row)
	row.tag:SetPoint("TOPRIGHT", -PAD, -6)
	row.tag:SetJustifyH("RIGHT")
	row.detail = Text(row)
	row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
	row.detail:SetWordWrap(true)
	row.detail:SetTextColor(0.85, 0.85, 0.85)
	return row
end

local function PaintFound(f)
	local found = ns.Report and ns.Report.Findings() or {}
	local unshared = {}
	for _, u in ipairs(ns.Report and ns.Report.Unshared() or {}) do
		unshared[u.key] = true
	end
	-- What's new first, then what's been shared, each in the report's order.
	local new, old = {}, {}
	for _, finding in ipairs(found) do
		table.insert(unshared[finding.key] and new or old, finding)
	end
	for _, finding in ipairs(old) do
		new[#new + 1] = finding
	end
	local width = f.foundScroll:GetWidth() or 0
	if width < 50 then
		width = f.foundWidth
	end
	local y = 0
	for i = 1, FOUND_ROWS do
		local finding = new[i]
		local row = f.found[i]
		if finding then
			if not row then
				row = FoundRow(f.foundList, i)
				f.found[i] = row
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 0, -y)
			row:SetWidth(width)
			local fresh = unshared[finding.key]
			row.tag:SetText(fresh and (GOOD .. "New|r") or (GREY .. "Shared|r"))
			local tagWidth = math.ceil(row.tag:GetStringWidth() or 40)
			row.title:SetWidth(width - 2 * PAD - tagWidth - 8)
			row.title:SetText(finding.title or finding.text)
			row.detail:SetWidth(width - 2 * PAD)
			row.detail:SetText(finding.detail or finding.text)
			local h = 6 + (row.title:GetStringHeight() or 12) + 3 + (row.detail:GetStringHeight() or 12) + 7
			row:SetHeight(math.ceil(h))
			row:Show()
			y = y + math.ceil(h)
		elseif row then
			row:Hide()
		end
	end
	f.foundList:SetSize(width, math.max(1, y))
	local most = math.max(0, y - (f.foundScroll:GetHeight() or 0))
	f.foundScroll.most = most
	f.foundScroll:SetVerticalScroll(math.min(f.foundScroll:GetVerticalScroll() or 0, most))
	f.foundEmpty:SetShown(#found == 0)
	local count = #found == 0 and "" or (#found - #old > 0
		and string.format("%s%d new|r%s", GOOD, #found - #old, #old > 0 and (GREY .. ", " .. #old .. " shared|r") or "")
		or string.format("%s%d, all shared|r", GREY, #found))
	f.letters:SetText(count)
end

local function Paint()
	local f = page
	if not (f and f:IsShown()) then
		return
	end
	local draft = Draft()
	local kind = KINDS[draft.kind] or KINDS.bug
	local data = draft.kind == "data"
	for key, b in pairs(f.kinds) do
		local on = key == draft.kind
		local label = b:GetFontString()
		if label then
			label:SetTextColor(on and 1 or 0.75, on and 0.82 or 0.75, on and 0 or 0.75)
		end
		if on then
			b:LockHighlight()
		else
			b:UnlockHighlight()
		end
	end
	f.ask:SetText(kind.ask)
	f.hint:SetText(kind.hint)
	-- Writing, for a bug or an idea; the findings, for the data report.
	for _, part in ipairs(f.writing) do
		part:SetShown(not data)
	end
	f.foundScroll:SetShown(data)
	f.foundEmpty:SetShown(false)
	f.write:ClearAllPoints()
	f.write:SetPoint("TOPLEFT", f.hint, "BOTTOMLEFT", -4, -8)
	f.write:SetPoint("BOTTOMRIGHT", -EDGE, 64)
	if data then
		PaintFound(f)
	else
		if f.write.edit:GetText() ~= draft.text then
			f.write.edit:SetText(draft.text or "")
		end
		f.setup:SetChecked(draft.setup and true or false)
		f.letters:SetText(string.format("%s%d of %d|r", GREY, #(draft.text or ""), MAX_LETTERS))
	end
	f.copyHeader.text:SetText(data and "Your report" or "Your message")
	f.copy.edit:SetText(Feedback.Text())
	f.copy.edit:SetCursorPosition(0)
	for _, row in ipairs(f.links) do
		row.box.url = LinkFor(row.link)
		row.box:SetText(row.box.url)
		row.box:SetCursorPosition(0)
	end
end
Feedback.Paint = Paint

local function CreatePage()
	local UI = ns.UI
	local f, inset = UI.CreateShell("OneCastFeedbackFrame", "Feedback", "Interface\\Icons\\INV_Letter_15")
	page = f
	f.strings = {}
	f:SetSize(PAGE_WIDTH, UI.PAGE_HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	UI.RememberPosition(f, "feedback")

	-- Two columns over a band the full width, for the links: each address shown whole.
	local BAND = GAP + HEADER + 4 + #Feedback.LINKS * LINK_ROW + EDGE
	local L = CreateFrame("Frame", nil, inset)
	L:SetPoint("TOPLEFT")
	L:SetPoint("BOTTOMRIGHT", inset, "BOTTOM", 0, BAND)
	local R = CreateFrame("Frame", nil, inset)
	R:SetPoint("TOPLEFT", inset, "TOP", 0, 0)
	R:SetPoint("BOTTOMRIGHT", 0, BAND)
	local B = CreateFrame("Frame", nil, inset)
	B:SetPoint("BOTTOMLEFT")
	B:SetPoint("BOTTOMRIGHT")
	B:SetHeight(BAND)

	-- Left: write it.
	local header = UI.SectionHeader(L, -GAP)
	header.text:SetText("Send feedback")
	local intro = Text(L)
	intro:SetPoint("TOPLEFT", EDGE + 4, -GAP - HEADER - 8)
	intro:SetPoint("RIGHT", -EDGE, 0)
	intro:SetWordWrap(true)
	intro:SetTextColor(0.78, 0.78, 0.78)
	intro:SetText("Found a bug, or have an idea? Write it here, or share your data report, then copy it to CurseForge or GitHub.")

	f.kinds = {}
	local x = EDGE
	for _, key in ipairs(KIND_ORDER) do
		local b = UI.GoldButton(L, KIND_WIDTH, 22)
		b:SetPoint("TOPLEFT", x, -GAP - HEADER - 48)
		b:SetText(KINDS[key].label)
		b:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			Draft().kind = key
			Paint()
		end)
		f.kinds[key] = b
		x = x + KIND_STEP
	end

	f.ask = Text(L, "GameFontNormal")
	f.ask:SetPoint("TOPLEFT", EDGE + 4, -GAP - HEADER - 84)
	f.letters = Text(L)
	f.letters:SetPoint("TOPRIGHT", -EDGE - 4, -GAP - HEADER - 86)
	f.letters:SetJustifyH("RIGHT")
	f.hint = Text(L)
	f.hint:SetPoint("TOPLEFT", f.ask, "BOTTOMLEFT", 0, -4)
	f.hint:SetPoint("RIGHT", -EDGE, 0)
	f.hint:SetWordWrap(true)
	f.hint:SetTextColor(0.66, 0.66, 0.66)

	local write = Box(L)
	write:SetPoint("TOPLEFT", EDGE, -GAP - HEADER - 132)
	write:SetPoint("BOTTOMRIGHT", -EDGE, 64)
	write.edit:SetMaxLetters(MAX_LETTERS)
	write.edit:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			Draft().text = self:GetText()
			f.letters:SetText(string.format("%s%d of %d|r", GREY, #Draft().text, MAX_LETTERS))
			f.copy.edit:SetText(Feedback.Text())
			f.copy.edit:SetCursorPosition(0)
		end
	end)
	f.write = write

	-- The data report's findings, in place of the writing, scrolled with the wheel.
	local scroll = CreateFrame("ScrollFrame", nil, L)
	scroll:SetPoint("TOPLEFT", f.hint, "BOTTOMLEFT", -4, -8)
	scroll:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
	local list = CreateFrame("Frame", nil, scroll)
	scroll:SetScrollChild(list)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		self:SetVerticalScroll(math.min(self.most or 0, math.max(0, self:GetVerticalScroll() - delta * 30)))
	end)
	scroll:Hide()
	f.foundScroll, f.foundList, f.found = scroll, list, {}
	f.foundWidth = PAGE_WIDTH / 2 - 10 - 2 * EDGE
	f.foundEmpty = Text(L)
	f.foundEmpty:SetPoint("TOPLEFT", scroll, "TOPLEFT", 4, -4)
	f.foundEmpty:SetPoint("RIGHT", -EDGE, 0)
	f.foundEmpty:SetWordWrap(true)
	f.foundEmpty:SetTextColor(0.66, 0.66, 0.66)
	f.foundEmpty:SetText("Nothing new yet. Keep fishing: a zone's real level, a fish or treasure OneCast doesn't know, "
		.. "or what a camp buff brings in shows up here, ready to share. The report on the right still holds your numbers.")
	f.foundEmpty:Hide()

	local setup = CreateFrame("CheckButton", nil, L, "UICheckButtonTemplate")
	setup:SetSize(24, 24)
	setup:SetPoint("BOTTOMLEFT", EDGE - 2, 34)
	setup:SetScript("OnClick", function(self)
		Draft().setup = self:GetChecked() and true or false
		Paint()
	end)
	f.setup = setup
	local setupLabel = Text(L)
	f.writing = { write, setup, setupLabel }
	setupLabel:SetPoint("LEFT", setup, "RIGHT", 4, 1)
	setupLabel:SetText("Add your setup")
	local setupNote = Text(L)
	setupNote:SetPoint("TOPLEFT", setup, "BOTTOMLEFT", 4, -2)
	setupNote:SetPoint("RIGHT", -EDGE, 0)
	setupNote:SetWordWrap(true)
	setupNote:SetTextColor(0.66, 0.66, 0.66)
	setupNote:SetText("Versions, language, Fishing, controller, changed settings and other addons. No names.")
	table.insert(f.writing, setupNote)

	-- Right: the text to copy, and where to paste it.
	local copyHeader = UI.SectionHeader(R, -GAP)
	copyHeader.text:SetText("Your message")
	f.copyHeader = copyHeader
	local selectAll = UI.HeaderButton(copyHeader)
	selectAll:SetPoint("RIGHT", -4, 0)
	selectAll:SetLabel(nil, "Select all")
	local copy = Box(R)
	copy:SetPoint("TOPLEFT", EDGE, -GAP - HEADER - 6)
	copy:SetPoint("BOTTOMRIGHT", -EDGE, 40)
	copy.edit:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(Feedback.Text())
			self:HighlightText()
		end
	end)
	copy.edit:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
		f.status:SetText(GOLD .. "Selected: Ctrl+C to copy, then paste it at one of the links below.|r")
		-- Selecting the report to copy counts its findings as shared: the tab's badge goes.
		if Draft().kind == "data" and ns.Report then
			ns.Report.MarkShared()
			PaintFound(f)
		end
	end)
	copy.edit:SetScript("OnEditFocusLost", function(self)
		self:HighlightText(0, 0)
	end)
	selectAll:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		copy.edit:SetFocus()
		copy.edit:HighlightText()
	end)
	f.copy = copy
	f.status = Text(R)
	f.status:SetPoint("TOPLEFT", copy, "BOTTOMLEFT", 4, -6)
	f.status:SetPoint("RIGHT", -EDGE, 0)
	f.status:SetWordWrap(true)
	f.status:SetText(GREY .. "Select all, Ctrl+C, then paste it at one of the links below.|r")

	-- Along the bottom: where to paste it, a row each, the address whole on the right.
	local pasteHeader = UI.SectionHeader(B, -GAP)
	pasteHeader.text:SetText("Then paste it on")
	f.links = {}
	local y = GAP + HEADER + 4
	for i, link in ipairs(Feedback.LINKS) do
		local row = CreateFrame("Frame", nil, B)
		row:SetPoint("TOPLEFT", EDGE, -y)
		row:SetPoint("TOPRIGHT", -EDGE, -y)
		row:SetHeight(LINK_ROW)
		UI.RowBackground(row, i)
		row.label = Text(row, "OneCastFontNormalSmall")
		row.label:SetPoint("LEFT", PAD, 0)
		row.label:SetText(link.label .. ":")
		row.box = LinkBox(row)
		row.box:SetWidth(LINK_WIDTH)
		row.box:SetPoint("RIGHT", -PAD, 0)
		row.link = link
		f.links[i] = row
		y = y + LINK_ROW
	end

	f:SetScript("OnShow", Paint)
	f:Hide()
	ns.Hub.Attach("feedback", f)
	return f
end

-- The Feedback page, from the window's tab or /onecast feedback.
function Feedback.Show()
	page = page or CreatePage()
	page:Show()
	Paint()
end

-- The data report: the Feedback page with Data report picked.
function Feedback.ShowReport()
	Draft().kind = "data"
	Feedback.Show()
end

function Feedback.ToggleReport()
	if page and page:IsShown() and Draft().kind == "data" then
		page:Hide()
	else
		Feedback.ShowReport()
	end
end

-- A catch or getaway while the data report is open: its findings and text again.
function Feedback.RefreshReport()
	if page and page:IsShown() and Draft().kind == "data" and not page.copy.edit:HasFocus() then
		Paint()
	end
end

function Feedback.Toggle()
	if page and page:IsShown() then
		page:Hide()
	else
		Feedback.Show()
	end
end

function Feedback.Page()
	return page
end
