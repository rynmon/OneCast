-- OneCast: one-button fishing for WoW Forever (interface 16001, modern addon API).
--
-- How it works, without secure snippets (loadstring_untainted is missing on Forever,
-- so SecureHandler templates are out):
--   * OneCastButton is a plain SecureActionButton that casts Fishing. Bind a key to it
--     in Options > Keybindings > AddOns > OneCast, or double right-click with a pole.
--   * When the Fishing channel starts, that same key is overridden to INTERACTTARGET
--     and soft-interact is switched on, so the next press reels in the bobber.
--   * When the channel ends the override is dropped and the key casts again.
-- Every cast and every reel is still one hardware press by the player.

local ADDON, ns = ...

-- From the TOC's ## Version line, so there's one place to bump it.
ns.VERSION = C_AddOns.GetAddOnMetadata(ADDON, "Version") or "?"

local FISHING_SPELL_IDS = { 7620, 131474 } -- Classic rank 1, modern profession spell
local DOUBLE_CLICK_WINDOW = 0.4
local BUTTON_NAME = "OneCastButton"
local BINDING_COMMAND = "CLICK " .. BUTTON_NAME .. ":LeftButton"

local defaults = {
	doubleClick = true,
	softInteract = true,
	soundBoost = true,
	minimapButton = true,
	minimapAngle = 225,
	alert = true,
	alertQuality = 2, -- Uncommon
	openOnCast = true,
	loginMessage = true,
	statsScale = 100, -- percent
	autoEquip = true,
	restoreOnCombat = true,
	restoreDelay = 60, -- seconds without casting before weapons go back on; 0 = never
}

-- Options shown in the settings panel and toggled by /onecast <cmd>, in display order.
local OPTIONS = {
	{ cmd = "doubleclick", key = "doubleClick", label = "Double right-click to cast",
		tooltip = "With a fishing pole equipped, double right-click the world to cast. Right-click the bobber to reel in." },
	{ cmd = "softinteract", key = "softInteract", label = "Soft-interact while fishing",
		tooltip = "While the line is out, make the bobber the soft-interact target so the cast key reels it in." },
	{ cmd = "sound", key = "soundBoost", label = "Louder splash while fishing",
		tooltip = "While the line is out, turn sound effects up to full so the splash is easy to hear. Music and ambience aren't touched." },
	{ cmd = "autoequip", key = "autoEquip", label = "Auto-equip fishing pole",
		tooltip = "If no pole is equipped, the cast key equips the best one in your bags first (press again to cast). Your weapons are saved and put back afterwards." },
	{ cmd = "combatgear", key = "restoreOnCombat", label = "Re-equip weapons when combat starts",
		tooltip = "Try to put your weapons back the moment combat starts. Anything the game blocks in combat is finished when combat ends." },
	{ cmd = "autoopen", key = "openOnCast", label = "Open stats when you cast",
		tooltip = "Open the stats window when you start fishing. If you close it (X or minimap button), it stays closed until you take a 2-minute break from fishing." },
	{ cmd = "alert", key = "alert", label = "Rare catch alert",
		tooltip = "Sound and a raid-warning flash when you catch something at or above the alert quality, or an item you've marked as wanted (right-click it in the stats window)." },
	{ cmd = "loginmessage", key = "loginMessage", label = "Version in chat at login",
		tooltip = "Say OneCast's version in chat when you log in, with a link to What's new." },
	{ cmd = "minimap", key = "minimapButton", label = "Show minimap button",
		tooltip = "Show the OneCast button on the minimap. Drag it to move it." },
}

-- CVars changed only for the length of a cast, and restored afterwards only if
-- nothing else changed them in the meantime.
local SOFT_INTERACT_CVARS = {
	SoftTargetInteract = "3",      -- always soft-target interactables
	SoftTargetInteractArc = "2",   -- 360 degrees
	SoftTargetInteractRange = "30",
}
-- Only sound effects are raised; music and ambience are left as the player set them.
local SOUND_CVARS = {
	Sound_EnableSFX = "1",
	Sound_SFXVolume = "1",
}

_G.BINDING_HEADER_ONECAST = "OneCast"
_G["BINDING_NAME_" .. BINDING_COMMAND] = "Cast / reel (one button fishing)"
_G.BINDING_NAME_ONECAST_RESTORE = "Re-equip weapons"

local db
local fishingName
local fishing = false
local lastRightClick = 0
local leased = {} -- cvar -> { original = value, ours = value }

-- Separate owners so dropping the double-click override never drops the reel one.
local reelOwner = CreateFrame("Frame")
local clickOwner = CreateFrame("Frame")

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33bbffOneCast|r: " .. msg)
end
ns.Print = Print
ns.GetFishingName = function()
	return fishingName
end

local function SpellName(spellID)
	if C_Spell.GetSpellName then
		return C_Spell.GetSpellName(spellID)
	end
	local info = C_Spell.GetSpellInfo(spellID)
	return info and info.name
end

local function ResolveFishingName()
	for _, id in ipairs(FISHING_SPELL_IDS) do
		local name = SpellName(id)
		if name then
			return name
		end
	end
end

local function IsFishingPole(slot)
	local itemID = GetInventoryItemID("player", slot)
	if not itemID then
		return false
	end
	local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
	return classID == Enum.ItemClass.Weapon and subclassID == Enum.ItemWeaponSubclass.Fishingpole
end

local function HasFishingPole()
	-- Main hand on Classic-style characters; the profession tool slot (28) on modern ones.
	return IsFishingPole(INVSLOT_MAINHAND or 16) or IsFishingPole(28)
end
ns.HasFishingPole = HasFishingPole

local function LeaseCVars(cvars)
	for name, value in pairs(cvars) do
		local current = C_CVar.GetCVar(name)
		if current ~= nil and not leased[name] then
			leased[name] = { original = current, ours = value }
			C_CVar.SetCVar(name, value)
		end
	end
end

local function ReleaseCVars()
	for name, lease in pairs(leased) do
		if C_CVar.GetCVar(name) == lease.ours then
			C_CVar.SetCVar(name, lease.original)
		end
		leased[name] = nil
	end
end

local function StartReelMode()
	if InCombatLockdown() then
		return
	end
	if db.softInteract then
		LeaseCVars(SOFT_INTERACT_CVARS)
	end
	if db.soundBoost then
		LeaseCVars(SOUND_CVARS)
	end
	for _, key in ipairs({ GetBindingKey(BINDING_COMMAND) }) do
		SetOverrideBinding(reelOwner, true, key, "INTERACTTARGET")
	end
end

local function StopReelMode()
	if not InCombatLockdown() then
		ClearOverrideBindings(reelOwner)
	end
	ReleaseCVars()
end

-- The secure cast button. Attributes are set once, out of combat, at login.
local button = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
button:RegisterForClicks("AnyUp", "AnyDown")
button:SetAttribute("type", "spell")
button:HookScript("PreClick", function(self)
	-- No pole equipped: this press equips one from the bags (Gear.lua) instead of casting.
	if not InCombatLockdown() and ns.Gear.PreClick() then
		self:SetAttribute("type", nil)
	end
end)
button:HookScript("PostClick", function(self)
	if not InCombatLockdown() then
		self:SetAttribute("type", "spell")
		-- The double-click override is one-shot: hand right-click back to the camera.
		ClearOverrideBindings(clickOwner)
	end
end)

-- Double right-click on the world casts. The second press's mouse-down rebinds
-- BUTTON2 to the cast button, so its mouse-up fires the cast.
WorldFrame:HookScript("OnMouseDown", function(_, mouseButton)
	if mouseButton ~= "RightButton" or not db or not db.doubleClick then
		return
	end
	if fishing or InCombatLockdown() or not HasFishingPole() then
		return
	end
	local now = GetTime()
	if now - lastRightClick <= DOUBLE_CLICK_WINDOW then
		lastRightClick = 0
		SetOverrideBindingClick(clickOwner, true, "BUTTON2", BUTTON_NAME)
	else
		lastRightClick = now
	end
end)

local function BoundKeysText()
	local keys = { GetBindingKey(BINDING_COMMAND) }
	return #keys > 0 and table.concat(keys, ", ") or "not bound"
end

-- Minimap button: a plain round button orbiting the minimap, dragged to any angle.
local minimapButton

-- Forever's minimap is square; a minimap addon can say otherwise via GetMinimapShape.
local function MinimapIsRound()
	return GetMinimapShape and GetMinimapShape() == "ROUND"
end

local function UpdateMinimapPosition()
	local angle = math.rad(db.minimapAngle)
	local x, y = math.cos(angle), math.sin(angle)
	local halfW, halfH = Minimap:GetWidth() / 2, Minimap:GetHeight() / 2
	if MinimapIsRound() then
		x, y = x * (halfW + 5), y * (halfH + 5)
	else
		-- Slide along the square's edge instead of a circle.
		local edge = math.max(math.abs(x), math.abs(y))
		x, y = x / edge * (halfW + 10), y / edge * (halfH + 10)
	end
	minimapButton:ClearAllPoints()
	minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function UpdateMinimapVisibility()
	if minimapButton then
		minimapButton:SetShown(db.minimapButton)
	end
end

-- Settings panel (Options > AddOns > OneCast).
local settingsCategory

local function OpenSettings()
	if InCombatLockdown() then
		Print("options can't be opened in combat.")
		return
	end
	Settings.OpenToCategory(settingsCategory:GetID())
end
ns.OpenSettings = OpenSettings

local function SetupSettings()
	local category, layout = Settings.RegisterVerticalLayoutCategory("OneCast")
	if CreateSettingsListSectionHeaderInitializer then
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("OneCast v" .. ns.VERSION))
	end
	if CreateSettingsButtonInitializer then
		layout:AddInitializer(CreateSettingsButtonInitializer("What's new", "What's new", function()
			ns.WhatsNew.Show()
		end, "See what changed in each version of OneCast.", true))
	end

	-- The cast/reel key, editable right here (same binding as Keybindings > AddOns).
	if CreateKeybindingEntryInitializer then
		for i = 1, GetNumBindings() do
			if GetBinding(i) == BINDING_COMMAND then
				if CreateSettingsListSectionHeaderInitializer then
					layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Key"))
				end
				layout:AddInitializer(CreateKeybindingEntryInitializer(i, true))
				break
			end
		end
	end
	if CreateSettingsListSectionHeaderInitializer then
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Options"))
	end

	for _, opt in ipairs(OPTIONS) do
		local setting = Settings.RegisterAddOnSetting(category, "OneCast_" .. opt.key, opt.key,
			db, "boolean", opt.label, defaults[opt.key])
		if opt.key == "minimapButton" then
			setting:SetValueChangedCallback(UpdateMinimapVisibility)
		end
		Settings.CreateCheckbox(category, setting, opt.tooltip)
		opt.setting = setting

		if opt.key == "autoEquip" and Settings.CreateSlider and Settings.CreateSliderOptions then
			local delay = Settings.RegisterAddOnSetting(category, "OneCast_restoreDelay", "restoreDelay",
				db, "number", "Re-equip weapons after", defaults.restoreDelay)
			local options = Settings.CreateSliderOptions(0, 300, 15)
			if MinimalSliderWithSteppersMixin then
				options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
					return value == 0 and "Never" or (value .. " s")
				end)
			end
			Settings.CreateSlider(category, delay, options,
				"Seconds without casting before your weapons are put back. 0 keeps the pole on until you re-equip by hand.")
		end

		if opt.key == "openOnCast" then
			local scale = Settings.RegisterAddOnSetting(category, "OneCast_statsScale", "statsScale",
				db, "number", "Stats window scale", defaults.statsScale)
			scale:SetValueChangedCallback(function(_, value)
				ns.Stats.SetScale(value)
			end)
			ns.scaleSetting = scale
			if Settings.CreateSlider and Settings.CreateSliderOptions then
				local options = Settings.CreateSliderOptions(50, 200, 5)
				if MinimalSliderWithSteppersMixin then
					options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
						return value .. "%"
					end)
				end
				Settings.CreateSlider(category, scale, options,
					"Size of the stats window. You can also drag its bottom-right corner, or Ctrl + mouse wheel over it.")
			end
		end

		if opt.key == "alert" and Settings.CreateDropdown and Settings.CreateControlTextContainer then
			local quality = Settings.RegisterAddOnSetting(category, "OneCast_alertQuality", "alertQuality",
				db, "number", "Alert quality", defaults.alertQuality)
			Settings.CreateDropdown(category, quality, function()
				local container = Settings.CreateControlTextContainer()
				for q = 2, 5 do
					local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
					local label = _G["ITEM_QUALITY" .. q .. "_DESC"] or tostring(q)
					container:Add(q, (color and color.hex or "") .. label .. (color and "|r" or "") .. " or better")
				end
				return container:GetData()
			end, "The lowest item quality that triggers the rare catch alert.")
		end
	end

	Settings.RegisterAddOnCategory(category)
	settingsCategory = category
end

local function SetupMinimapButton()
	local b = CreateFrame("Button", "OneCastMinimapButton", Minimap)
	b:SetSize(31, 31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("AnyUp")
	b:RegisterForDrag("LeftButton")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local background = b:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetPoint("CENTER")

	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetTexture("Interface\\Icons\\INV_Misc_Fish_68")
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	icon:SetPoint("CENTER")

	local border = b:CreateTexture(nil, "OVERLAY")
	border:SetSize(50, 50)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetPoint("TOPLEFT")

	b:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			ns.Stats.Toggle()
		else
			OpenSettings()
		end
	end)

	b:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			db.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
			UpdateMinimapPosition()
		end)
	end)
	b:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)

	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddDoubleLine("OneCast", "v" .. ns.VERSION, nil, nil, nil, 0.6, 0.6, 0.6)
		GameTooltip:AddLine("Cast / reel: " .. BoundKeysText(), 1, 1, 1)
		GameTooltip:AddLine(ns.Stats.Summary(), 1, 1, 1)
		GameTooltip:AddLine("Left-click: options", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Right-click: session stats", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Drag: move", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)

	minimapButton = b
	UpdateMinimapPosition()
	UpdateMinimapVisibility()
end

-- Addon compartment (the addons dropdown by the minimap), declared in the TOC.
function OneCast_OnAddonCompartmentClick()
	OpenSettings()
end

local function IsFishingSpell(spellID)
	if not spellID or (issecretvalue and issecretvalue(spellID)) then
		return false
	end
	return SpellName(spellID) == fishingName
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

events:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		if ... == ADDON then
			OneCastDB = OneCastDB or {}
			for k, v in pairs(defaults) do
				if OneCastDB[k] == nil then
					OneCastDB[k] = v
				end
			end
			db = OneCastDB
			db.wanted = db.wanted or {}
			ns.db = db
			SetupSettings()
			SetupMinimapButton()
		end
	elseif event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED" then
		local name = ResolveFishingName()
		if name and name ~= fishingName and not InCombatLockdown() then
			fishingName = name
			button:SetAttribute("spell", name)
		end
		if event == "PLAYER_LOGIN" and not GetBindingKey(BINDING_COMMAND) then
			Print("bind a key under Options > Keybindings > AddOns > OneCast, or double right-click with a pole. /onecast for options.")
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		local _, _, spellID = ...
		if IsFishingSpell(spellID) then
			fishing = true
			StartReelMode()
			ns.Stats.OnCast()
			ns.Gear.OnCast()
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if fishing then
			fishing = false
			StopReelMode()
			ns.Gear.OnFishingStopped()
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		ns.Gear.OnCombatStart()
		-- Last chance before lockdown: give every key back to its normal binding.
		fishing = false
		ClearOverrideBindings(reelOwner)
		ClearOverrideBindings(clickOwner)
		ReleaseCVars()
	elseif event == "PLAYER_LOGOUT" then
		-- CVars are saved on logout; never save ours.
		ReleaseCVars()
	end
end)

SLASH_ONECAST1 = "/onecast"
SlashCmdList.ONECAST = function(msg)
	local cmd = strlower(strtrim(msg or ""))
	if cmd == "" then
		OpenSettings()
		return
	elseif cmd == "stats" then
		ns.Stats.Toggle()
		return
	elseif cmd == "session" or cmd == "zone" or cmd == "lifetime" or cmd == "log" then
		ns.Stats.Toggle(cmd)
		return
	elseif cmd == "reset" then
		ns.Stats.Reset()
		Print("session stats reset.")
		return
	elseif cmd == "gear" then
		OneCast_RestoreWeapons()
		return
	elseif cmd == "scan" then
		ns.Prices.Scan()
		return
	elseif cmd == "new" or cmd == "whatsnew" then
		ns.WhatsNew.Toggle()
		return
	elseif cmd:match("^scale") then
		local percent = tonumber(cmd:match("^scale%s+(%d+)"))
		if percent then
			ns.Stats.SetScale(percent)
			Print("stats window scale: " .. db.statsScale .. "%")
		else
			Print("usage: /onecast scale 50-200")
		end
		return
	end
	for _, opt in ipairs(OPTIONS) do
		if opt.cmd == cmd then
			-- Through the setting, so the panel and its callbacks stay in sync.
			opt.setting:SetValue(not db[opt.key])
			Print(opt.label .. ": " .. (db[opt.key] and "on" or "off"))
			return
		end
	end
	Print("v" .. ns.VERSION .. " | key: " .. BoundKeysText() .. " | spell: " .. tostring(fishingName))
	Print("/onecast - open options")
	Print("/onecast new - what's new in each version")
	Print("/onecast stats - stats window (or /onecast session|zone|lifetime|log for a tab)")
	Print("/onecast reset - start a new session")
	Print("/onecast gear - put your weapons back on")
	Print("/onecast scan - price your catch with Auctionator (auction house open)")
	Print("/onecast scale 50-200 - stats window size in percent")
	for _, opt in ipairs(OPTIONS) do
		Print("/onecast " .. opt.cmd .. " - " .. opt.label .. " (" .. (db[opt.key] and "on" or "off") .. ")")
	end
end
