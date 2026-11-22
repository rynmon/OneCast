-- OneCast's clean view: the game's interface out of the way while you fish, leaving the water,
-- your bobber's light and OneCast's own windows. "Hide the game's interface while fishing"
-- (cleanView), off by default.
--
-- The game's interface is all one frame, UIParent. It's faded to nothing when your line goes
-- out and stays so between casts while your pole is on. It's never hidden outright: hiding and
-- showing UIParent from an addon runs every Blizzard frame's show and hide code as the addon's,
-- which taints them (the game then blocks its own protected actions and blames the addon).
-- Fading touches nothing but how it's drawn.
--
-- It comes back the moment the pole comes off, combat starts, you move, or a window opens
-- (the map, your bags, a loot window you'd have to click), and while it's faded it's only
-- invisible, not gone: keys and bindings all work as ever. Every OneCast frame (the stats with
-- their Done button, the mini bar, the tackle box button, the side tabs and every page) and
-- the tooltips ignore the fade, so they stay on screen; the bobber's light is on its
-- nameplate, which isn't part of the interface.

local _, ns = ...

local Clean = {}
ns.CleanView = Clean

local faded = false     -- OneCast has the interface faded out
local lootOpen = false  -- shown for a loot window that needs clicking

-- What stays on screen while the interface is faded: OneCast's own frames, by name (so a page
-- built later is found when it's there), and the tooltips. A fixed list, never UIParent's
-- children: some of those are the game's forbidden frames (the shop, Edit Mode), which addon
-- code can't so much as ask the name of.
local KEEP = {
	"OneCastStatsFrame", "OneCastMiniFrame", "OneCastCatchWindow", "OneCastSkillToast", "OneCastHubTabs",
	"OneCastTackleButton", "OneCastApplyLureButton", "OneCastTackleWindow", "OneCastBookFrame",
	"OneCastWardrobeFrame", "OneCastJourneyFrame", "OneCastCampFrame", "OneCastContestFrame", "OneCastFeedbackFrame", "OneCastOptionsWindow",
	"OneCastWhatsNewFrame", "OneCastWelcome", "OneCastMenu", "OneCastItemMenu",
	"GameTooltip", "ItemRefTooltip",
}
local function Keepers()
	local list = {}
	for _, name in ipairs(KEEP) do
		local f = _G[name]
		if type(f) == "table" and not (f.IsForbidden and f:IsForbidden()) then
			list[#list + 1] = f
		end
	end
	return list
end
Clean.KEEP = KEEP -- for the tests

local function Keep(keep)
	for _, f in ipairs(Keepers()) do
		if f.SetIgnoreParentAlpha then
			f:SetIgnoreParentAlpha(keep)
		end
	end
end

function Clean.Active()
	return faded
end

-- Fade the interface out, if the setting's on and nothing stands in the way.
function Clean.Hide()
	if not (ns.db and ns.db.cleanView) or faded or lootOpen or InCombatLockdown() then
		return
	end
	if not (ns.HasFishingPole and ns.HasFishingPole()) then
		return
	end
	Keep(true)
	faded = true
	UIParent:SetAlpha(0)
end

-- Bring it back, if OneCast faded it.
function Clean.Restore()
	if not faded then
		return
	end
	faded = false
	UIParent:SetAlpha(1)
	Keep(false)
end

-- A OneCast window built or opened while the interface is faded: it stays visible too.
function Clean.KeepNew()
	if faded then
		Keep(true)
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("PLAYER_STARTED_MOVING")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("LOOT_CLOSED")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
events:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LOGOUT" or event == "PLAYER_STARTED_MOVING" then
		Clean.Restore()
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		C_Timer.After(0.2, function()
			if not (ns.HasFishingPole and ns.HasFishingPole()) then
				Clean.Restore()
			end
		end)
	elseif event == "LOOT_OPENED" then
		local autoLoot = ...
		if faded and not autoLoot then
			-- A loot window to click: the interface back while it's open.
			Clean.Restore()
			lootOpen = true
		end
	elseif event == "LOOT_CLOSED" then
		if lootOpen then
			lootOpen = false
			C_Timer.After(0.3, function()
				if ns.IsFishing and ns.IsFishing() then
					Clean.Hide()
				end
			end)
		end
	else
		-- The line went out: after OneCast's own handler has noted it.
		C_Timer.After(0, function()
			if ns.IsFishing and ns.IsFishing() then
				Clean.Hide()
			end
		end)
	end
end)

-- A window opening (the map, bags) brings the interface back with it.
if EventRegistry and EventRegistry.RegisterCallback then
	EventRegistry:RegisterCallback("UIParentPanelManager.ShowUIPanel", function()
		Clean.Restore()
	end, Clean)
end
