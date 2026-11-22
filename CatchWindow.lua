-- OneCast's catch window: this session's catch, popped out of the stats window into a small
-- window of its own, to keep beside you while you fish. The same rows as the stats window's
-- list (hover, click and right-click do the same), sorted the same way. Drag it anywhere, pull
-- its corner for more rows, scroll for the rest. Opened by Pop out on the list's header or the
-- Catch window setting, which keeps it open across sessions and reloads; its X turns that off.

local _, ns = ...

local CatchWindow = {}
ns.CatchWindow = CatchWindow

local WIDTH = 300
local BORDER = 9          -- inside the dialog border
local BAND_HEIGHT = 22    -- the title band
local TITLE_HEIGHT = BORDER + BAND_HEIGHT + 1
local PAD = 6
local MIN_ROWS, MAX_ROWS = 3, 20
local GREY = "|cff9d9d9d"

local frame
local offset = 0

local function RowHeight()
	return ns.UI and ns.UI.ITEM_HEIGHT or 22
end

-- Rows that fit the window's height now.
local function Fit()
	local h = frame:GetHeight() - TITLE_HEIGHT - BORDER - 2 * PAD
	return math.max(MIN_ROWS, math.min(MAX_ROWS, math.floor(h / RowHeight())))
end

local function HeightFor(rows)
	return TITLE_HEIGHT + BORDER + 2 * PAD + rows * RowHeight()
end

local function Create()
	local UI = ns.UI
	local f = CreateFrame("Frame", "OneCastCatchWindow", UIParent, "BackdropTemplate")
	local border = UI.TryCreate and UI.TryCreate("Frame", nil, f, "DialogBorderTemplate")
	if border then
		border:SetAllPoints()
		border:SetFrameLevel(f:GetFrameLevel() + 3)
		if border.Bg then
			border.Bg:Hide()
		end
	elseif f.SetBackdrop then
		f:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16,
			insets = { left = BORDER, right = BORDER, top = BORDER, bottom = BORDER } })
	end
	local backing = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	backing:SetPoint("TOPLEFT", 4, -4)
	backing:SetPoint("BOTTOMRIGHT", -4, 4)
	backing:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark", "REPEAT", "REPEAT")
	backing:SetHorizTile(true)
	backing:SetVertTile(true)

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetSize(22, 22)
	close:SetPoint("TOPRIGHT", -BORDER + 1, -BORDER + 1)
	close:SetFrameLevel(f:GetFrameLevel() + 5)
	f.CloseButton = close
	-- Its X works in combat too, and turns the setting off.
	f.onCloseCallback = function()
		if ns.db then
			ns.db.catchWindow = false
		end
		f:Hide()
		return false
	end

	local band = f:CreateTexture(nil, "ARTWORK")
	band:SetPoint("TOPLEFT", BORDER, -BORDER)
	band:SetPoint("RIGHT", close, "LEFT", 0, 0)
	band:SetHeight(BAND_HEIGHT)
	if UI.HasAtlas and UI.HasAtlas("common-button-list-collapseExpand") then
		band:SetAtlas("common-button-list-collapseExpand")
	else
		band:SetColorTexture(0.25, 0.18, 0.10, 0.95)
	end
	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.title:SetPoint("LEFT", band, "LEFT", 10, 0)
	f.count = f:CreateFontString(nil, "OVERLAY", "OneCastFontHighlightSmall")
	f.count:SetPoint("RIGHT", band, "RIGHT", -8, 0)
	f.count:SetJustifyH("RIGHT")

	local inset = CreateFrame("Frame", nil, f)
	inset:SetPoint("TOPLEFT", BORDER, -TITLE_HEIGHT)
	inset:SetPoint("BOTTOMRIGHT", -BORDER, BORDER)
	f.inset = inset
	ns.Theme.Frame(f, inset, true)
	ns.Theme.Register(band, "header")
	if border then
		ns.Theme.Register(border, "frame")
	end

	f.rows = {}
	for i = 1, MAX_ROWS do
		local row = UI.ItemRow(inset, i, 0)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -PAD - (i - 1) * RowHeight())
		row:SetPoint("TOPRIGHT", 0, -PAD - (i - 1) * RowHeight())
		row:Hide()
		f.rows[i] = row
	end
	f.empty = inset:CreateFontString(nil, "OVERLAY", "OneCastFontHighlightSmall")
	f.empty:SetPoint("TOPLEFT", PAD + 4, -PAD - 4)
	f.empty:SetPoint("RIGHT", -PAD - 4, 0)
	f.empty:SetJustifyH("LEFT")
	f.empty:SetWordWrap(true)
	f.empty:SetText(GREY .. "Nothing caught yet this session. Your catch shows here as it comes in.|r")
	f.more = inset:CreateFontString(nil, "OVERLAY", "OneCastFontDisableSmall")
	f.more:SetPoint("BOTTOMRIGHT", -PAD, 2)

	f:SetSize(WIDTH, HeightFor(8))
	f:SetPoint("RIGHT", UIParent, "RIGHT", -60, 0)
	f:SetFrameStrata("MEDIUM")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetResizable(true)
	if f.SetResizeBounds then
		f:SetResizeBounds(WIDTH, HeightFor(MIN_ROWS), WIDTH, HeightFor(MAX_ROWS))
	end
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	if UI.RememberPosition then
		UI.RememberPosition(f, "catches")
	end
	-- Pull the corner for more rows; the height is kept.
	local grip = CreateFrame("Button", nil, f)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -4, 4)
	grip:SetFrameLevel(f:GetFrameLevel() + 6)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetScript("OnMouseDown", function()
		f:StartSizing("BOTTOM")
	end)
	grip:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		local rows = Fit()
		f:SetHeight(HeightFor(rows))
		if ns.db then
			ns.db.catchWindowRows = rows
		end
		CatchWindow.Refresh()
	end)
	f:SetScript("OnSizeChanged", function()
		if f:IsShown() then
			CatchWindow.Refresh()
		end
	end)
	f:EnableMouseWheel(true)
	f:SetScript("OnMouseWheel", function(_, delta)
		offset = offset - delta * 3
		CatchWindow.Refresh()
	end)
	f:SetScript("OnShow", function()
		CatchWindow.Refresh()
	end)
	f:Hide()
	if ns.db and ns.db.catchWindowRows then
		f:SetHeight(HeightFor(math.max(MIN_ROWS, math.min(MAX_ROWS, ns.db.catchWindowRows))))
	end
	return f
end

function CatchWindow.Refresh()
	if not (frame and frame:IsShown() and ns.Stats and ns.Stats.SessionRows) then
		return
	end
	local rows = ns.Stats.SessionRows()
	local fit = Fit()
	offset = math.max(0, math.min(offset, #rows - fit))
	frame.title:SetText("Caught this session")
	frame.count:SetText(#rows > 0 and (GREY .. #rows .. (#rows == 1 and " kind" or " kinds") .. "|r") or "")
	for i, row in ipairs(frame.rows) do
		local r = i <= fit and rows[offset + i]
		if r then
			local color = ns.Stats.QualityColor(r.quality)
			row.itemID, row.itemName = r.id, r.name
			row.spot, row.zone, row.pick, row.missing, row.note, row.session = nil, nil, nil, nil, nil, nil
			row.icon:SetTexture(r.icon)
			row.icon:SetDesaturated(false)
			ns.Stats.TreeRow(row, r.child, r.last)
			row.name:SetText(r.label or r.name or ("item:" .. tostring(r.id)))
			row.name:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
			row.border:SetVertexColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
			row.right:SetText(r.right or "")
			row:Show()
		else
			row.itemID = nil
			row:Hide()
		end
	end
	frame.empty:SetShown(#rows == 0)
	local below = #rows - fit - offset
	frame.more:SetText(below > 0 and string.format("%d more: scroll", below) or "")
end

function CatchWindow.Show()
	frame = frame or Create()
	offset = 0
	frame:Show()
	if ns.CleanView and ns.CleanView.KeepNew then
		ns.CleanView.KeepNew()
	end
	CatchWindow.Refresh()
end

function CatchWindow.Hide()
	if frame then
		frame:Hide()
	end
end

-- Pop out from the stats window: on, and kept on, or off again.
function CatchWindow.Toggle()
	local on = not (frame and frame:IsShown())
	if ns.db then
		ns.db.catchWindow = on
	end
	CatchWindow.Apply()
end

-- The setting changed, or the game loaded: open or close to match it.
function CatchWindow.Apply()
	if ns.db and ns.db.catchWindow then
		CatchWindow.Show()
	else
		CatchWindow.Hide()
	end
end

function CatchWindow.Window()
	return frame
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	CatchWindow.Apply()
end)
