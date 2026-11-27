-- OneCast: one-button fishing for WoW Forever (interface 16001, modern addon API).
--
-- How it works, without secure snippets (loadstring_untainted is missing on Forever,
-- so SecureHandler templates are out):
--   * OneCastButton is a plain SecureActionButton that casts Fishing. Bind a key to it
--     in Options > Keybindings > OneCast, or double right-click with a pole.
--   * When the Fishing channel starts, that same key is overridden to INTERACTTARGET
--     and soft-interact is switched on, so the next press reels in the bobber.
--   * When the channel ends the override is dropped and the key casts again.
-- Every cast and every reel is still one hardware press by the player.

local ADDON, ns = ...
local L = ns.L -- translations (Locale.lua)

-- From the TOC's ## Version line, so there's one place to bump it.
ns.VERSION = C_AddOns.GetAddOnMetadata(ADDON, "Version") or "?"

local FISHING_SPELL_IDS = { 7620, 131474 } -- Classic rank 1, modern profession spell
local DOUBLE_CLICK_WINDOW = 0.4
local BUTTON_NAME = "OneCastButton"
local BINDING_COMMAND = "CLICK " .. BUTTON_NAME .. ":LeftButton"
ns.BINDING_COMMAND = BINDING_COMMAND

local defaults = {
	largerText = false,      -- accessibility: OneCast's small print at the normal size
	glyphSize = "normal",    -- accessibility: controller button icons, normal, large or largest
	theme = "forever",       -- the windows' colours (Themes.lua); Forever is the game's own look
	themeEffects = "all",    -- what a theme adds besides colour: all, still or off
	rowShading = "strong",   -- accessibility: every other row of a list shaded, off, light or strong
	collectionTicks = true,  -- accessibility: a tick on what you've caught
	reduceMotion = false,    -- accessibility: OneCast's animations stopped
	doubleClick = true,
	softInteract = true,
	soundBoost = true,
	quietOthers = false,
	quietLevel = 0, -- percent of the player's own music, ambience and dialog volume
	minimapButton = true,
	minimapAngle = 225,
	closeOnDone = true,
	doneCloses = false,
	escapeCloses = false,
	catchTooltip = true,
	fadeStats = false,
	catchWindow = false, -- this session's catch in a small window of its own
	lockWindow = false,
	tabSide = "right", -- the OneCast window's side tabs: "right" or "left"
	language = "", -- OneCast's language: a locale ("deDE"), or "" for the game's own
	alert = true,
	alertQuality = 2, -- Uncommon
	openOnCast = true,
	openOnPole = false,
	auctionSource = "auto",
	loginMessage = true,
	statsScale = 100, -- percent
	autoEquip = true,
	fishingOutfit = true,
	statsMini = false,
	junkMode = "button",
	poolTooltip = true,
	mapStrip = true,
	newCatchMessage = true,
	goalAlerts = true,
	alertSound = true,
	tabBadges = true,
	skillToast = true,
	restoreOnCombat = true,
	restoreDelay = 60, -- seconds without casting before weapons go back on; 0 = never
	sessionSummary = true,
	autoLootHint = true,
	autoLootFishing = false,
	fastLoot = false,
	openWithCast = false,
	padFishing = true,   -- a controller button casts and reels while the pole is on
	padButton = "PAD1",  -- A / Cross
	padStart = "both",   -- LT + RT + the button works with no pole on
	padWindow = "PAD4",  -- Y / Triangle opens the OneCast window
	padHints = true,
	padRumble = true,
	extravaganza = true,
	bagWarning = true,
	tackleBox = true,
	lureVendorHint = true,
	rememberPools = true,
	bobberMarker = false,
	beamColor = "arcane",
	bobberStyle = "beam",
	cleanView = false,
	foodReminder = true,
	sessionStart = "manual", -- when a new session starts: only with Reset, by default
	sessionBreak = 30,       -- minutes away from fishing, for sessionStart "break"
	bobberHeight = 0,
	campReminder = true,
}
-- Per character: skill and bags differ, and lures get used up.
ns.DEFAULTS = defaults -- for the feedback page's "settings changed"
local charDefaults = {
	autoLure = false,
	lureChoice = 0, -- Lure.NONE
	conjuredFirst = false,
}

-- The Language setting's "reload now?" (its text is set as it's shown, in the language in use).
StaticPopupDialogs["ONECAST_LANGUAGE"] = {
	OnAccept = function()
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

-- Checkboxes in the settings panel, each also toggled by /onecast <cmd>.
local OPTIONS = ns.Retranslate({
	{ cmd = "largetext", key = "largerText", label = L["Larger text"],
		tooltip = L["Every OneCast window, and the mini bar, 15% bigger, on top of Window scale: the text grows with the room around it, so nothing is squeezed."] },
	{ cmd = "ticks", key = "collectionTicks", label = L["Ticks on what you've caught"],
		tooltip = L["A green tick on each catch you've caught in the collection, and on fishing gear you have. Off, what you have shows in full colour and what you don't is greyed, with nothing over the icon."] },
	{ cmd = "motion", key = "reduceMotion", label = L["Reduce motion"],
		tooltip = L["Stop OneCast's animations: the water flowing in the Fishing bar, its shine and glint, the bars sliding, and the bobber's light breathing. Alerts still appear and fade."] },
	{ cmd = "doubleclick", key = "doubleClick", label = L["Double right-click to cast"],
		tooltip = L["With a fishing pole equipped, double right-click the world to cast. Right-click the bobber to reel in."] },
	{ cmd = "softinteract", key = "softInteract", label = L["Soft-interact while fishing"],
		tooltip = L["While the line is out, make the bobber the soft-interact target so the cast key reels it in."] },
	{ cmd = "foodreminder", key = "foodReminder", label = L["Fishing food reminders"],
		tooltip = L["While your pole is on, say in chat when your fishing food's Well Fed wears off, and which food in your bags to eat. Some cooked fish raise your Fishing skill for 15 minutes; the tackle box has a button to eat the best you have."] },
	{ cmd = "clean", key = "cleanView", label = L["Hide the game's interface while fishing"],
		tooltip = L["While your line is out, the game's interface fades away, leaving the water, your bobber and OneCast's own windows (the stats with Done fishing, the mini bar, the tackle box). It comes back when the pole comes off, combat starts, you move, or a window opens. Keys and bindings work as ever."] },
	{ cmd = "bobbermarker", key = "bobberMarker", label = L["Mark your bobber"],
		tooltip = L["While the line is out, your bobber glows with a column of light rising from it, so you can tell it from other people's on busy water (Beam colour, below). It can't show when a fish bites: the game doesn't tell addons that."] },
	{ cmd = "bagwarning", key = "bagWarning", label = L["Warn when your bags are full"],
		tooltip = L["Warn once when you cast with no free bag space, because a catch may not fit."] },
	{ cmd = "sound", key = "soundBoost", label = L["Louder splash while fishing"],
		tooltip = L["While the line is out, turn sound effects up to full so the splash is easy to hear."] },
	{ cmd = "quiet", key = "quietOthers", label = L["Quiet other sounds while fishing"],
		tooltip = L["While your fishing pole is equipped, turn music, ambience and dialog down (or off) so the splash stands out. They go back to your own levels when your weapons go back on, or if you change them yourself."] },
	{ cmd = "autoequip", key = "autoEquip", label = L["Auto-equip fishing pole"],
		tooltip = L["If no pole is equipped, the cast key equips the best one in your bags first (press again to cast). Your weapons are saved and put back afterwards."] },
	{ cmd = "outfit", key = "fishingOutfit", label = L["Wear fishing gear with the pole"],
		tooltip = L["When the pole goes on, so does any gear in your bags with a Fishing bonus (a fishing hat, boots, gloves with the Fishing enchant), where it beats what you're wearing. What you had on goes back with your weapons."] },
	{ cmd = "combatgear", key = "restoreOnCombat", label = L["Re-equip weapons when combat starts"],
		tooltip = L["Try to put your weapons back the moment combat starts. Anything the game blocks in combat is finished when combat ends."] },
	{ cmd = "tacklebox", key = "tackleBox", label = L["Show the tackle box button"],
		tooltip = L["Show a small button while a fishing pole is in your main hand, with your lure and its time left. Left-click applies your lure, right-click opens its settings, Shift-drag moves it."] },
	{ cmd = "autolure", key = "autoLure", char = true, label = L["Apply lure with the cast key"],
		tooltip = L["With no lure on your pole, the cast key applies your chosen lure first, then casts on the next press. It uses up the lure, so it's off until you turn it on. Set for each character."] },
	{ cmd = "conjured", key = "conjuredFirst", char = true, label = L["Use conjured lures first"],
		tooltip = L["While you have a conjured lure (Camper's Lure, \"Secret\" Bait), the best of them goes on before your chosen lure, so the lures you bought last longer. When they run out, your choice takes over. Never with No lure. Set for each character."] },
	{ cmd = "lurevendor", key = "lureVendorHint", label = L["Low lure hint at vendors"],
		tooltip = L["At a vendor selling your chosen lure, say so in chat if you have fewer than 5. Buying stays up to you."] },
	{ cmd = "autoclose", key = "closeOnDone", label = L["Close stats when you stop fishing"],
		tooltip = L["When your weapons go back on, close the stats window, if it opened by itself when you cast. A window you opened yourself stays open."] },
	{ cmd = "doneclose", key = "doneCloses", label = L["Done fishing closes the stats window"],
		tooltip = L["When you press Done fishing, close the stats window (or the mini bar) as well as putting your weapons and gear back on. Off, it stays open, even if it opened by itself when you cast."] },
	{ cmd = "escclose", key = "escapeCloses", label = L["Escape closes OneCast windows"],
		tooltip = L["Escape closes OneCast's windows, newest first, once the game's own windows (bags, map) are closed, and then opens the game menu as usual. Off, OneCast's windows stay open through Escape and close with their X."] },
	{ cmd = "catches", key = "catchWindow", label = L["Catch window"],
		tooltip = L["This session's catch in a small window of its own, to keep beside you while you fish. Drag it anywhere and pull its corner for more rows. Pop out on the stats window's list opens it too."] },
	{ cmd = "fade", key = "fadeStats", label = L["Fade stats while fishing"],
		tooltip = L["While you're fishing, the stats window fades to see-through when your mouse isn't over it, so it hides less of the water."] },
	{ cmd = "lock", key = "lockWindow", label = L["Lock the window"],
		tooltip = L["Stop OneCast's window being moved or resized by accident. Turn it off to move it again."] },
	{ cmd = "autoopen", key = "openOnCast", label = L["Open stats when you cast"],
		tooltip = L["Open the stats window (or the mini bar) every time you cast. Closing it only hides it until your next cast."] },
	{ cmd = "openpole", key = "openOnPole", label = L["Open stats when your pole goes on"],
		tooltip = L["Open the stats window (or the mini bar) every time you equip a fishing pole, even if you closed it while fishing earlier. It won't take over the OneCast window while another page is open."] },
	{ cmd = "mini", key = "statsMini", label = L["Mini bar instead of the stats window"],
		tooltip = L["When you cast, open a slim bar in place of the stats window: your skill and the zone, catches and fish per hour, your lure and your wanted list. Click it for the full stats. /onecast mini turns it on or off."] },
	{ cmd = "summary", key = "sessionSummary", label = L["Session summary in chat"],
		tooltip = L["After a 2-minute break from fishing, sum up the session in chat: catches, fish per hour, vendor value, skill gained and new fish for your collection."] },
	{ cmd = "controller", key = "padFishing", label = L["Fish with a controller button"],
		tooltip = L["With a controller in use, one of its buttons casts and reels while your fishing pole is on, in place of what it normally does (A is Jump). It goes back to normal the moment the pole comes off or combat starts. Nothing changes without a controller."] },
	{ cmd = "padhints", key = "padHints", label = L["Show your controller's buttons"],
		tooltip = L["With a controller in use, OneCast shows its buttons as the game draws them for your controller: your fishing button over your bobber (in place of the game's Interact button, which doesn't reel in for OneCast), which button casts on the mini bar, and the triggers and bumpers beside the tabs."] },
	{ cmd = "rumble", key = "padRumble", label = L["Rumble with alerts"],
		tooltip = L["The controller rumbles for a moment with OneCast's on-screen alerts: a rare catch, a goal reached, 40 Tastyfish in the Extravaganza."] },
	{ cmd = "fishloot", key = "autoLootFishing", label = L["Auto loot while fishing"],
		tooltip = L["Turn the game's auto loot on while your fishing pole is equipped, so catches go straight to your bags, and back to how you had it when your weapons go back on. Auto loot that's already on stays on."] },
	{ cmd = "fastloot", key = "fastLoot", label = L["Fast loot"],
		tooltip = L["With auto loot on, take a catch the instant its loot window opens, all at once, quicker than the game's own auto loot takes it item by item. Only fishing loot and what's inside the trunks and crates you fish up; other loot is left to the game."] },
	{ cmd = "openclams", key = "openWithCast", label = L["Cast key opens containers"],
		tooltip = L["With your pole on, the cast key opens a clam, bloated fish or unlocked crate you fished up before it casts again, one each press, so you don't have to open them in your bags. Not with your bags full or a loot window open, and one that won't open is left for a minute, so it never stops you fishing."] },
	{ cmd = "autoloot", key = "autoLootHint", label = L["Offer to turn on auto loot"],
		tooltip = L["If auto loot is off when you catch something, offer once per login to turn it on, so catches go straight to your bags."] },
	{ cmd = "alertsound", key = "alertSound", label = L["Play a sound with it"],
		tooltip = L["The raid warning sound with each rare catch alert. Off, the alert shows without a sound."] },
	{ cmd = "skillup", key = "skillToast", label = L["Skill-up pop-up"],
		tooltip = L["When your Fishing goes up, \"+1 Fishing\" rises and fades on screen, over the mini bar if it's open."] },
	{ cmd = "wanted", key = "goalAlerts", label = L["Wanted catch alerts"],
		tooltip = L["An alert when you catch something on your wanted list (right-click a catch to add it). With a number wanted, a word in chat halfway and an alert when you have them all. They count either way."] },
	{ cmd = "newcatch", key = "newCatchMessage", label = L["Say when a catch is new for your collection"],
		tooltip = L["A line in chat when you catch something none of your characters has caught before."] },
	{ cmd = "alert", key = "alert", label = L["Rare catch alert"],
		tooltip = L["Sound and a raid-warning flash when you catch something at or above the alert quality, Wanted fish have their own alert."] },
	{ cmd = "pools", key = "rememberPools", label = L["Remember fishing pools"],
		tooltip = L["Hover over a fishing pool with your pole on and cast, and the spot you fished it from is marked on the collection book's zone maps. Pools move, so a mark shows where one has been. Not on Portuguese or Italian clients yet: the game's names for pools there aren't known. /onecast forgetpools clears them."] },
	{ cmd = "campreminder", key = "campReminder", label = L["Camp buff reminders"],
		tooltip = L["Say in chat when the Uncommon or Rare Fishing buff from a Fishing Rack or Fishing Hut wears off. The Camp page has more on camps."] },
	{ cmd = "extravaganza", key = "extravaganza", label = L["Fishing Extravaganza reminders"],
		tooltip = L["Say in chat shortly before the Stranglethorn Fishing Extravaganza starts, and when it does (Sundays 14:00-16:00 realm time)."] },
	{ cmd = "loginmessage", key = "loginMessage", label = L["Version in chat at login"],
		tooltip = L["Say OneCast's version in chat when you log in, with a link to What's new."] },
	{ cmd = "caughtby", key = "catchTooltip", label = L["Rarity and who caught it, on items"],
		tooltip = L["On the tooltip of anything in the collection, wherever you see it (bags, chat links, the auction house), say how rare it is (Classic's odds per catch) and which of your characters caught it."] },
	{ cmd = "pooltips", key = "poolTooltip", label = L["What a pool gives, on its tooltip"],
		tooltip = L["Hover a fishing pool to see what it gives, with Classic's odds, and what you haven't caught yet."] },
	{ cmd = "map", key = "mapStrip", label = L["Fishing levels on the world map"],
		tooltip = L["A small card on the world map with the zone's fishing level, how your skill stands and your fish caught there. On a continent, it follows the zone under the mouse. Drag it anywhere, Ctrl + mouse wheel over it to size it, right-click to put it back."] },
	{ cmd = "badges", key = "tabBadges", label = L["Green dots on the side tabs"],
		tooltip = L["A green dot on the Feedback tab when your data report has something new to share, and on What's new when there's a version you haven't read."] },
	{ cmd = "minimap", key = "minimapButton", label = L["Show minimap button"],
		tooltip = L["Show the OneCast button on the minimap. Drag it to move it."] },
})

-- The sub-pages under OneCast in the options, each a list of { heading, keys... }. A key is an
-- OPTIONS entry, or one of the sliders and dropdowns built in SetupSettings.
-- Fishing: how you cast and reel, your pole and gear, and what you catch. While fishing: what
-- you see and hear with the line out.
-- l10n: keys (page and section names are keys: Hub.lua translates them as it shows them)
local OPTION_PAGES = {
	{ name = "Fishing",
		{ "Casting", "castKey", "doubleClick", "softInteract" },
		{ "Pole and gear", "autoEquip", "fishingOutfit", "restoreDelay", "restoreOnCombat" },
		{ "Loot and bags", "autoLootFishing", "fastLoot", "openWithCast", "autoLootHint", "bagWarning", "junkMode", "auctionSource" },
	},
	{ name = "Lures",
		{ "Your lure", "lureChoice", "conjuredFirst", "autoLure" },
		{ "Tackle box", "tackleBox", "lureVendorHint" },
	},
	{ name = "While fishing",
		{ "Your bobber", "bobberMarker", "bobberStyle", "beamColor", "bobberHeight" },
		{ "Sound", "soundBoost", "quietOthers", "quietLevel" },
		{ "Immersion", "cleanView", "fadeStats" },
	},
	{ name = "Controller",
		{ "Fishing button", "padFishing", "padButton", "padStart", "padWindow" },
		{ "Feedback", "padHints", "padRumble" },
	},
	{ name = "Accessibility",
		{ "Text and buttons", "largerText", "rowShading", "glyphSize" },
		{ "Motion", "reduceMotion" },
	},
	{ name = "Stats and sessions",
		{ "Windows", "openOnCast", "openOnPole", "statsMini", "catchWindow", "closeOnDone", "doneCloses", "escapeCloses", "lockWindow" },
		{ "Sessions", "sessionStart", "sessionBreak", "sessionSummary" },
	},
	{ name = "Alerts",
		{ "Alerts", "alert", "alertSound", "alertQuality", "goalAlerts", "newCatchMessage", "skillToast" },
		{ "Reminders", "foodReminder", "campReminder", "extravaganza" },
	},
}
-- A page scrolls past about 554 px (24 a row, 40 a section), but one that fits reads better.
-- l10n: end
-- Greyed out and indented while the option they belong to is off.
-- { key, value }: the setting belongs to that choice, and is greyed out unless it's chosen.
local OPTION_PARENT = {
	sessionBreak = { "sessionStart", "break" },
	beamColor = "bobberMarker",
	bobberStyle = "bobberMarker",
	bobberHeight = "bobberMarker",
	quietLevel = "quietOthers",
	padButton = "padFishing",
	padStart = "padFishing",
	padWindow = "padFishing",
	alertQuality = "alert",
	alertSound = "alert",
}

local UpdateQuiet -- below: quiet other sounds while fishing
local UpdateLoot -- below: auto loot while fishing

-- Every setting that isn't a checkbox, described once: the options panel and the window's Options
-- page are both built from this. A `list` setting is a dropdown of { value, text } pairs; the others
-- are sliders from `min` to `max` in `step`s, shown with `format`. `char` keeps it per character.
local CHOICES = ns.Retranslate({
	sessionStart = { label = L["Start a new session"], kind = "string",
		tooltip = L["When OneCast starts a new session by itself. The one before goes into your session history (the Records tab), so you can still see how it went. Reset always starts one."],
		list = function()
			return { { "manual", L["Only when I press Reset"] }, { "break", L["After a break from fishing"] },
				{ "login", L["Each time I log in"] }, { "day", L["Each new day"] }, { "done", L["When I press Done fishing"] } }
		end },
	sessionBreak = { label = L["Break length"], kind = "number", min = 10, max = 240, step = 5,
		tooltip = L["With After a break from fishing: how long without a cast before your next cast starts a new session."],
		format = function(value)
			if value >= 60 then
				local h, m = math.floor(value / 60), value % 60
				return m > 0 and string.format(L["%dh %02dm"], h, m) or (h .. "h")
			end
			return value .. " min"
		end },
	bobberStyle = { label = L["Marker"], kind = "string",
		tooltip = L["How your bobber is marked: glowing with a light beam rising from it, the glow alone, the game's gear icon over it, or the beam and the icon."],
		list = function()
			return { { "beam", L["Light beam"] }, { "glow", L["Glow"] }, { "icon", L["Gear icon"] }, { "both", L["Beam and icon"] } }
		end,
		onChange = function()
			if ns.Bobber then
				ns.Bobber.Update()
			end
		end },
	bobberHeight = { label = L["Marker height"], kind = "number", min = -100, max = 100, step = 5,
		tooltip = L["Moves the bobber's glow and beam up or down, if they don't sit right on your bobber. 0 is where OneCast puts them."],
		format = function(value)
			return (value > 0 and "+" or "") .. value
		end,
		onChange = function()
			if ns.Bobber then
				ns.Bobber.Replace()
			end
		end },
	beamColor = { label = L["Beam colour"], kind = "string",
		tooltip = L["The colour of your bobber's glow and light beam. Custom opens the colour picker (or /onecast beam)."],
		list = function()
			local swatch = function(key, text)
				local c = ns.Bobber and ns.Bobber.COLORS[key]
				return c and string.format(L["|cff%02x%02x%02x%s|r"], c[1] * 255, c[2] * 255, c[3] * 255, text) or text
			end
			return { { "arcane", swatch("arcane", "Arcane") }, { "gold", swatch("gold", "Gold") }, { "white", swatch("white", "White") },
				{ "blue", swatch("blue", L["Ice blue"]) }, { "teal", swatch("teal", "Teal") }, { "green", swatch("green", "Green") },
				{ "red", swatch("red", "Red") }, { "purple", swatch("purple", "Purple") }, { "pink", swatch("pink", "Pink") },
				{ "class", L["Class colour"] }, { "custom", L["Custom..."] } }
		end,
		onChange = function(_, value)
			if not ns.Bobber then
				return
			end
			ns.Bobber.Retint()
			-- Stepping onto Custom opens the colour picker.
			if value == "custom" then
				ns.Bobber.PickColor()
			end
		end },
	auctionSource = { label = L["Auction prices from"], kind = "string",
		tooltip = L["Which addon the stats take auction prices from, if you have more than one: Automatic takes Auctionator's, then TSM's, then Naowh Forever's, whichever has a price. Only the ones you have installed are listed."],
		list = function()
			local list = { { "auto", L["Automatic"] } }
			for _, source in ipairs(ns.Stats and ns.Stats.PriceSources and ns.Stats.PriceSources() or {}) do
				list[#list + 1] = { source.key, source.name }
			end
			return list
		end,
		onChange = function()
			if ns.Stats then
				ns.Stats.RefreshIfShown()
			end
		end },
	junkMode = { label = L["Fishing junk at vendors"], kind = "string",
		tooltip = L["The grey junk you've fished up, and nothing else, at a vendor: a button under the vendor window that sells it when you click, sold as soon as you open the vendor, or left alone."],
		list = function()
			return { { "button", L["Sell button"] }, { "auto", L["Sell automatically"] }, { "off", L["Leave it"] } }
		end,
		onChange = function()
			if ns.Junk then
				ns.Junk.UpdateButton()
			end
		end },
	padButton = { label = L["Fishing button"], kind = "string",
		tooltip = L["The controller button that casts and reels while your fishing pole is on. A / Cross is under your thumb, and Jump comes back when the pole comes off."],
		list = function()
			local list = {}
			for _, b in ipairs(ns.Controller and ns.Controller.BUTTONS or {}) do
				list[#list + 1] = { b[1], b[2] }
			end
			return list
		end,
		onChange = function()
			if ns.Controller then
				ns.Controller.Update()
			end
		end },
	padStart = { label = L["Put your pole on with"], kind = "string",
		tooltip = L["With no fishing pole on, your fishing button is still Jump. Hold the trigger or triggers shown and press it, and OneCast puts your pole on; from then on the button alone casts and reels, until the pole comes off. Off: put your pole on yourself, or with the cast key."],
		list = function()
			local list = {}
			for _, s in ipairs(ns.Controller and ns.Controller.STARTS or {}) do
				list[#list + 1] = { s[1], ns.Controller.StartLabel(s[1]) }
			end
			return list
		end,
		onChange = function()
			if ns.Controller then
				ns.Controller.Update()
			end
		end },
	padWindow = { label = L["OneCast window button"], kind = "string",
		tooltip = L["A second controller button that opens and closes the OneCast window while your fishing pole is on. Off leaves it alone."],
		list = function()
			local list = { { "off", L["Off"] } }
			for _, b in ipairs(ns.Controller and ns.Controller.BUTTONS or {}) do
				list[#list + 1] = { b[1], b[2] }
			end
			return list
		end,
		onChange = function()
			if ns.Controller then
				ns.Controller.Update()
			end
		end },
	theme = { label = L["Theme"], kind = "string",
		tooltip = L["The colours of OneCast's windows, every page of them. Forever is the game's own look. Changes as soon as you pick one."],
		list = function()
			local list = {}
			for _, id in ipairs(ns.Theme.ORDER) do
				list[#list + 1] = { id, ns.Theme.LIST[id].label }
			end
			return list
		end,
		onChange = function()
			ns.Theme.Apply()
		end },
	themeEffects = { label = L["Theme effects"], kind = "string",
		tooltip = L["What a theme adds besides its colours: scenery along the foot of each window, particles drifting over it (bubbles, snow, embers, fireflies), an emblem in the title bar and its own water in the Fishing bar. Still keeps everything but the particles, as Reduce motion does."],
		list = function()
			return { { "all", L["Full"] }, { "still", L["Still"] }, { "off", L["Colours only"] } }
		end,
		onChange = function()
			ns.Theme.Apply()
		end },
	rowShading = { label = L["Row shading"], kind = "string",
		tooltip = L["Shades every other row of OneCast's lists (stats, catches and options), so your eye can follow a row across, and the backing of the headline numbers. Light is fainter; Off leaves the rows plain."],
		list = function()
			return { { "off", L["Off"] }, { "light", L["Light"] }, { "strong", L["Strong"] } }
		end,
		onChange = function()
			if ns.UI and ns.UI.ApplyRowShading then
				ns.UI.ApplyRowShading()
			end
		end },
	glyphSize = { label = L["Controller button size"], kind = "string",
		tooltip = L["How big OneCast draws your controller's buttons: in the button guide under each window, over your bobber, in the welcome and in tooltips."],
		list = function()
			return { { "normal", L["Normal"] }, { "large", L["Large"] }, { "largest", L["Largest"] } }
		end,
		onChange = function()
			if ns.Controller then
				ns.Controller.Update()
			end
		end },
	language = { label = L["Language"], kind = "string",
		tooltip = L["The language OneCast speaks. The game's own names (zones, items) stay in the game's language. Russian, Chinese and Korean are offered on clients whose letters can show them. Changes after a reload."],
		list = function()
			local list = { { "", L["Game's language"] } }
			for _, code in ipairs(ns.Languages()) do
				list[#list + 1] = { code, ns.LANGUAGE_NAMES[code] }
			end
			return list
		end,
		onChange = function()
			-- Saved settings arrive after OneCast's files have run, so a new language needs a reload.
			local popup = StaticPopupDialogs.ONECAST_LANGUAGE
			popup.text = L["OneCast's language changes after a reload. Reload now?"]
			popup.button1, popup.button2 = L["Reload"], L["Later"]
			StaticPopup_Show("ONECAST_LANGUAGE")
		end },
	tabSide = { label = L["Side tabs"], kind = "string",
		tooltip = L["Which side of the OneCast window its tabs sit on."],
		list = function()
			return { { "right", L["Right"] }, { "left", L["Left"] } }
		end,
		onChange = function()
			ns.Hub.UpdateSide()
		end },
	statsScale = { label = L["Window scale"], kind = "number", min = 50, max = 200, step = 5,
		tooltip = L["Size of OneCast's window, every page of it. You can also drag any page's bottom-right corner, or Ctrl + mouse wheel over the stats page."],
		format = function(value)
			return value .. "%"
		end,
		onChange = function(_, value)
			ns.Stats.SetScale(value)
		end },
	lureChoice = { label = L["Lure to use"], kind = "number", char = true,
		tooltip = L["The lure the tackle box, the Apply lure key and the cast key use. Your choice is never swapped for another (only Use conjured lures first goes before it): if it runs out, OneCast fishes without one. \"Best I can use\" can spend your rarest lures. Set for each character."],
		list = function()
			local list = { { ns.Lure.NONE, L["No lure"] }, { ns.Lure.BEST, L["Best I can use"] } }
			for _, lure in ipairs(ns.Lure.LIST) do
				list[#list + 1] = { lure.id, string.format("%s (+%d)", ns.Lure.Name(lure), lure.bonus) }
			end
			return list
		end,
		onChange = function()
			ns.Lure.OnSettingChanged()
		end },
	restoreDelay = { label = L["Re-equip weapons after"], kind = "number", min = 0, max = 300, step = 15,
		tooltip = L["Seconds without casting before your weapons are put back. 0 keeps the pole on until you re-equip by hand."],
		format = function(value)
			return value == 0 and "Never" or (value .. " s")
		end },
	quietLevel = { label = L["Other sounds"], kind = "number", min = 0, max = 100, step = 5,
		tooltip = L["How loud music, ambience and dialog stay while your pole is equipped, as a share of your own volume. 0 mutes them."],
		format = function(value)
			return value == 0 and "Muted" or (value .. "%")
		end,
		onChange = function()
			UpdateQuiet(true)
		end },
	alertQuality = { label = L["Alert quality"], kind = "number",
		tooltip = L["The lowest item quality that triggers the rare catch alert."],
		list = function()
			local list = {}
			for q = 2, 5 do
				local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
				local label = _G["ITEM_QUALITY" .. q .. "_DESC"] or tostring(q)
				list[#list + 1] = { q, (color and color.hex or "") .. label .. (color and "|r" or "") .. L[" or better"] }
			end
			return list
		end },
})

-- The options on the main page, before OPTION_PAGES, for the window's Options page.
-- l10n: keys (page and section names are keys: Hub.lua translates them as it shows them)
local OPTION_MAIN = {
	{ "Look", "theme", "themeEffects", "tabSide", "statsScale", "collectionTicks" },
	{ "General", "language", "minimapButton", "tabBadges", "loginMessage" },
	{ "Tooltips and map", "catchTooltip", "poolTooltip", "mapStrip", "rememberPools" },
}
-- l10n: end

-- CVars changed only for the length of a cast, and restored afterwards only if
-- nothing else changed them in the meantime.
local SOFT_INTERACT_CVARS = {
	SoftTargetInteract = "3",      -- always soft-target interactables
	SoftTargetInteractArc = "2",   -- 360 degrees
	SoftTargetInteractRange = "30",
}
-- The game's gear icon over the soft-interact target: your bobber, and nobody else's.
local BOBBER_MARKER_CVARS = {
	SoftTargetIconGameObject = "1",
	SoftTargetIconInteract = "1",
}
-- Sound effects raised for the cast. Music, ambience and dialog are only touched by the
-- separate "quiet" option (QUIET_CVARS), which follows the pole rather than the cast.
local SOUND_CVARS = {
	Sound_EnableSFX = "1",
	Sound_SFXVolume = "1",
}

_G["BINDING_NAME_" .. BINDING_COMMAND] = L["Cast / reel (one button fishing)"]
_G.BINDING_NAME_ONECAST_RESTORE = L["Re-equip weapons"]
_G.BINDING_NAME_ONECAST_DONE = L["Done fishing (weapons and gear back on)"]
_G.BINDING_NAME_ONECAST_BOOK = L["Fishing collection"]
_G.BINDING_NAME_ONECAST_WARDROBE = L["Fishing wardrobe"]
_G.BINDING_NAME_ONECAST_JOURNEY = L["Fisherman's journey"]
_G.BINDING_NAME_ONECAST_WINDOW = L["OneCast window (the page you last used)"]

local db
local fishingName
local fishing = false
local lastRightClick = 0
-- Borrowed CVars by group, each cvar -> { original = value, ours = value }: "cast" for the
-- length of one cast, "quiet" for as long as the pole is equipped. No CVar is in both.
local leases = { cast = {}, quiet = {}, loot = {} }
-- Turned down while the pole is on, to quietLevel percent of the player's own volume.
local QUIET_CVARS = { "Sound_MusicVolume", "Sound_AmbienceVolume", "Sound_DialogVolume" }

-- Separate owners so dropping the double-click override never drops the reel one.
local reelOwner = CreateFrame("Frame")
local clickOwner = CreateFrame("Frame")

-- OneCast's small print -------------------------------------------------------------------------
-- Its own font objects, which every OneCast window uses for its text. A font object's changes
-- reach every text that uses it. The game's own fonts at their own sizes (GameFontHighlight and
-- the like), as its group finder and Seeker LFG use them, with the grey a little lighter for
-- contrast. "Larger text" doesn't change them: it scales the windows (ns.TextScale), so the
-- text grows with the room around it and nothing gets squeezed.
local SMALL_FONTS = {
	{ "OneCastFontHighlightSmall", "GameFontHighlightSmall", "GameFontHighlight" },
	{ "OneCastFontNormalSmall", "GameFontNormalSmall", "GameFontNormal" },
	{ "OneCastFontDisableSmall", "GameFontDisableSmall", "GameFontDisable", { 0.66, 0.66, 0.66 } },
	{ "OneCastFontGreenSmall", "GameFontGreenSmall", "GameFontGreen" },
	{ "OneCastFontHighlightSmallOutline", "GameFontHighlightSmallOutline", "GameFontHighlightOutline" },
}
for _, spec in ipairs(SMALL_FONTS) do
	if CreateFont and not _G[spec[1]] then
		CreateFont(spec[1])
	end
end

function ns.LargerText()
	return ns.db and ns.db.largerText and true or false
end

-- "Larger text": every OneCast window this much bigger, on top of its Window scale.
local LARGER_TEXT_SCALE = 1.15
function ns.TextScale()
	return ns.LargerText() and LARGER_TEXT_SCALE or 1
end

function ns.ApplyTextSize()
	for _, spec in ipairs(SMALL_FONTS) do
		local font, from = _G[spec[1]], _G[spec[3]] or _G[spec[2]]
		if font and from and font.CopyFontObject then
			font:CopyFontObject(from)
			if spec[4] then
				font:SetTextColor(spec[4][1], spec[4][2], spec[4][3])
			end
		end
	end
end
ns.ApplyTextSize()

-- "Reduce motion": OneCast's animations stopped (the water flowing, shines and glints, the
-- bobber's light breathing).
function ns.ReduceMotion()
	return ns.db and ns.db.reduceMotion and true or false
end

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33bbffOneCast|r: " .. msg)
end
ns.Print = Print

-- Register the first of `names` the game knows, for an event whose name has changed between
-- game versions. Registering an unknown event is an error that stops the rest of the file
-- loading, so each is checked first. Returns the name registered, or nil.
function ns.RegisterAnyEvent(frame, names)
	for _, name in ipairs(names) do
		local valid
		if C_EventUtils and C_EventUtils.IsEventValid then
			valid = C_EventUtils.IsEventValid(name)
		else
			valid = pcall(frame.RegisterEvent, frame, name)
			if valid then
				return name
			end
		end
		if valid then
			frame:RegisterEvent(name)
			return name
		end
	end
end

-- How many of an item are in the bags.
function ns.ItemCount(item)
	return (C_Item.GetItemCount or GetItemCount)(item) or 0
end

-- An item as a chat link, to hover or Shift-click, or `fallback` until the game has its data.
function ns.ItemLink(itemID, fallback)
	return select(2, C_Item.GetItemInfo(itemID)) or fallback
end

-- The game's current APIs first, then the old names: those live in Blizzard's deprecated files,
-- which only load while the loadDeprecationFallbacks setting is on, and go at the next expansion.

-- Milliseconds of temporary enchant (a lure) on the main hand, or nil if none.
function ns.MainHandEnchantMs()
	local paperDoll = C_PaperDollInfo
	if paperDoll and paperDoll.GetTemporaryEnchantmentInfo then
		local info = paperDoll.GetTemporaryEnchantmentInfo(INVSLOT_MAINHAND or 16)
		local ms = info and info.remainingTimeMs
		if ms and not (issecretvalue and issecretvalue(ms)) then
			return ms
		end
		return nil
	end
	if GetWeaponEnchantInfo then
		local has, ms = GetWeaponEnchantInfo()
		return has and ms or nil
	end
end

-- True if this character knows the spell (a recipe), nil if the game can't say.
function ns.KnowsSpell(spellID)
	local spellBook = C_SpellBook
	if spellBook and spellBook.IsSpellKnown and Enum.SpellBookSpellBank then
		return spellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Player) and true or false
	end
	if IsPlayerSpell then
		return IsPlayerSpell(spellID) and true or false
	end
end

-- A raid-warning flash in the middle of the screen.
function ns.RaidWarning(text)
	if ns.Controller then
		ns.Controller.Rumble()
	end
	local color = ChatTypeInfo and ChatTypeInfo.RAID_WARNING
	if RaidWarningUtil and RaidWarningUtil.AddMessage then
		RaidWarningUtil.AddMessage(text, color)
	elseif RaidNotice_AddMessage and RaidWarningFrame then
		RaidNotice_AddMessage(RaidWarningFrame, text, color)
	end
end

-- Put a link into chat: into the chat box if it's open, else opening it with the link in. The
-- game's current ChatFrameUtil, or the old names it keeps (deprecated) for older clients.
function ns.InsertChatLink(link)
	if not link then
		return false
	end
	local util = ChatFrameUtil
	local insert = (util and util.InsertLink) or ChatEdit_InsertLink
	if insert and insert(link) then
		return true
	end
	local open = (util and util.OpenChat) or ChatFrame_OpenChat
	if open then
		open(link)
		return true
	end
	return false
end
ns.GetFishingName = function()
	return fishingName
end
ns.IsFishing = function()
	return fishing
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
	return ns.Gear.IsPole(GetInventoryItemID("player", slot))
end

local function HasFishingPole()
	-- Main hand on Classic-style characters; the profession tool slot (28) on modern ones.
	return IsFishingPole(INVSLOT_MAINHAND or 16) or IsFishingPole(28)
end
ns.HasFishingPole = HasFishingPole

local function LeaseCVars(group, cvars)
	local leased = leases[group]
	for name, value in pairs(cvars) do
		local current = C_CVar.GetCVar(name)
		if current ~= nil and not leased[name] then
			C_CVar.SetCVar(name, value)
			-- Read back: the game may store the number formatted its own way.
			leased[name] = { original = current, ours = C_CVar.GetCVar(name) }
		end
	end
end

-- The same value, however the game writes it: "0.3" and "0.300000" are one volume.
local function SameValue(a, b)
	if a == b then
		return true
	end
	local x, y = tonumber(a), tonumber(b)
	return x ~= nil and y ~= nil and math.abs(x - y) < 0.001
end

local CVAR_NAMES = { Sound_MusicVolume = L["music volume"], Sound_AmbienceVolume = L["ambience volume"],
	Sound_DialogVolume = L["dialog volume"], Sound_SFXVolume = L["sound effects volume"], Sound_EnableSFX = L["sound effects"],
	autoLootDefault = L["auto loot"] }

-- Give the group's CVars back, each only if it still holds OneCast's value: one changed
-- meanwhile (by you, or by another addon that also turns up the splash) stays as it is. Chat
-- says so once a login for each, not on every cast when another addon does it each time.
local leftAlone = {}
local function ReleaseCVars(group)
	local leased = leases[group]
	for name, lease in pairs(leased) do
		if SameValue(C_CVar.GetCVar(name), lease.ours) then
			C_CVar.SetCVar(name, lease.original)
		elseif CVAR_NAMES[name] and not leftAlone[name] then
			leftAlone[name] = true
			Print(L["left your "] .. CVAR_NAMES[name] .. L[" as it was changed while fishing (by you or another addon), and won't say so again this session."])
		end
		leased[name] = nil
	end
end

-- Quiet music, ambience and dialog while a pole is equipped, if the option is on.
function UpdateQuiet(reapply)
	local want = db and db.quietOthers and HasFishingPole()
	local active = next(leases.quiet) ~= nil
	if active and (reapply or not want) then
		ReleaseCVars("quiet")
		active = false
	end
	if want and not active then
		local level = math.max(0, math.min(100, db.quietLevel or 0)) / 100
		local cvars = {}
		for _, name in ipairs(QUIET_CVARS) do
			local current = tonumber((C_CVar.GetCVar(name))) -- one value, even if the game gives none
			if current then
				cvars[name] = tostring(math.floor(current * level * 100 + 0.5) / 100)
			end
		end
		LeaseCVars("quiet", cvars)
	end
end

-- Auto loot on while a pole is equipped, if the option is on; back as it was after.
function UpdateLoot()
	local want = db and db.autoLootFishing and HasFishingPole()
	local active = next(leases.loot) ~= nil
	if active and not want then
		ReleaseCVars("loot")
	elseif want and not active then
		LeaseCVars("loot", { autoLootDefault = "1" })
	end
end
ns.UpdateLoot = UpdateLoot

-- Warn once each time the bags fill up, when a line goes out.
local bagsFullWarned = false

local function CheckBagSpace()
	local free = 0
	for bag = 0, NUM_BAG_SLOTS or 4 do
		local slots, family = C_Container.GetContainerNumFreeSlots(bag)
		if (family or 0) == 0 then
			free = free + (slots or 0)
		end
	end
	if free > 0 then
		bagsFullWarned = false
	elseif db.bagWarning and not bagsFullWarned then
		bagsFullWarned = true
		Print(L["your bags are full, so a catch may not fit."])
		if UIErrorsFrame then
			UIErrorsFrame:AddMessage(L["Your bags are full"], 1, 0.3, 0.1)
		end
	end
end

local function StartReelMode()
	if InCombatLockdown() then
		return
	end
	if db.softInteract or db.bobberMarker then -- the icon goes on the soft-interact target
		LeaseCVars("cast", SOFT_INTERACT_CVARS)
	end
	if db.bobberMarker then
		LeaseCVars("cast", BOBBER_MARKER_CVARS)
	end
	if db.soundBoost then
		LeaseCVars("cast", SOUND_CVARS)
	end
	for _, key in ipairs({ GetBindingKey(BINDING_COMMAND) }) do
		SetOverrideBinding(reelOwner, true, key, "INTERACTTARGET")
	end
	-- A controller's fishing button reels too: its cast binding steps aside first.
	if ns.Controller then
		ns.Controller.Update()
		for _, key in ipairs(ns.Controller.ReelKeys()) do
			SetOverrideBinding(reelOwner, true, key, "INTERACTTARGET")
		end
	end
end

local function StopReelMode()
	if not InCombatLockdown() then
		ClearOverrideBindings(reelOwner)
	end
	ReleaseCVars("cast")
	if ns.Controller then
		ns.Controller.Update() -- the fishing button casts again
	end
end

local equippingPress = false -- the key went down and equipped a pole, and hasn't come up yet
local reelEndedAt = 0        -- when the line last came in
local doubleClickArmed = false -- a double right-click's mouse-up is about to cast
local REEL_RELEASE_WINDOW = 1 -- seconds a key-up still counts as releasing that reel-in

-- The secure cast button. Attributes are set once, out of combat, at login.
local button = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
button:RegisterForClicks("AnyUp", "AnyDown")
button:SetAttribute("type", "spell")
button:HookScript("PreClick", function(self, _, down)
	if InCombatLockdown() then
		return
	end
	-- The line can come in before the key does: the release of a reel-in press isn't a cast.
	local reelRelease = not down and not doubleClickArmed and GetTime() - reelEndedAt < REEL_RELEASE_WINDOW
	reelEndedAt = 0
	if reelRelease then
		self:SetAttribute("type", nil)
		return
	end
	-- The pole can land before the key comes up: the press that equipped it stays spent.
	local equippedOnDown = equippingPress
	equippingPress = false
	if equippedOnDown and not down then
		self:SetAttribute("type", nil)
		return
	end
	-- No pole equipped: this press equips one from the bags (Gear.lua) instead of casting.
	if ns.Gear.PreClick() then
		self:SetAttribute("type", nil)
		equippingPress = down
		return
	end
	-- A fished-up clam in the bags (Cast key opens containers): this press opens it instead.
	-- Never while a lure is going on: using an item would cut its cast short.
	if HasFishingPole() and not ns.Lure.IsCasting() then
		local open = ns.Stats.OpenPress and ns.Stats.OpenPress()
		if open then
			self:SetAttribute("type", "macro")
			self:SetAttribute("macrotext", open)
			return
		end
	end
	-- A lure wanted, or one going on: this press applies it or waits, instead of casting.
	local lure = ns.Lure.CastPress(down)
	if lure == "wait" then
		self:SetAttribute("type", nil)
	elseif lure then
		self:SetAttribute("type", "macro")
		self:SetAttribute("macrotext", lure)
	end
end)
button:HookScript("PostClick", function(self)
	if not InCombatLockdown() then
		self:SetAttribute("type", "spell")
		self:SetAttribute("macrotext", nil)
		-- The double-click override is one-shot: hand right-click back to the camera.
		ClearOverrideBindings(clickOwner)
		doubleClickArmed = false
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
		doubleClickArmed = true
	else
		lastRightClick = now
	end
end)

local function BoundKeysText()
	local keys = { GetBindingKey(BINDING_COMMAND) }
	return #keys > 0 and table.concat(keys, ", ") or L["not bound"]
end

-- Minimap button: a plain round button orbiting the minimap, dragged to any angle.
local minimapButton

-- Round unless a minimap addon says otherwise through GetMinimapShape, the convention
-- minimap buttons share (Forever's minimap can be round or square).
local function MinimapIsRound()
	return not GetMinimapShape or GetMinimapShape() == "ROUND"
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

-- Blizzard's options panel opens the game menu whenever it closes, however it was opened. Opened
-- from OneCast (minimap button, /onecast, a window's Options button), closing it should just close
-- it. So: note that OneCast asked, and when that panel closes, hide the game menu it brings up in
-- the moment after. Opened from the game menu itself, closing still goes back there. Only hooks,
-- after Blizzard's own code, so the options panel is never tainted.
local settingsRequestedAt = -10
local settingsOpenedByUs = false
local skipGameMenuUntil = 0
local settingsHooks = {} -- owner of the options-panel callback

local function OpenSettings()
	if InCombatLockdown() then
		Print(L["options can't be opened in combat."])
		return
	end
	settingsRequestedAt = GetTime()
	if Settings.KEYBINDINGS_CATEGORY_ID then
		-- OneCast's keys have a section of their own (Bindings.xml's category), and the list
		-- scrolls to it. It opens with a click on its +: opening it from here would mean writing
		-- into the game's own settings, which is what got an action blocked on the Social page.
		Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, "OneCast")
		Print(string.format(L["your cast key: open OneCast (its +), then \"%s\"."],
			_G["BINDING_NAME_" .. BINDING_COMMAND] or L["Cast / reel"]))
	elseif settingsCategory then
		Settings.OpenToCategory(settingsCategory:GetID())
	end
	if SettingsPanel and SettingsPanel:IsShown() then
		settingsOpenedByUs = true
	end
end

if SettingsPanel then
	SettingsPanel:HookScript("OnShow", function()
		settingsOpenedByUs = GetTime() - settingsRequestedAt < 1
	end)
end
if EventRegistry then
	EventRegistry:RegisterCallback("SettingsPanel.OnHide", function()
		if settingsOpenedByUs then
			settingsOpenedByUs = false
			skipGameMenuUntil = GetTime() + 0.5
		end
	end, settingsHooks)
end
if GameMenuFrame then
	GameMenuFrame:HookScript("OnShow", function(self)
		if GetTime() < skipGameMenuUntil then
			skipGameMenuUntil = 0
			HideUIPanel(self)
		end
	end)
end
ns.OpenSettings = OpenSettings
ns.OPTIONS = OPTIONS
ns.OPTION_CHOICES = CHOICES
ns.OPTION_MAIN = OPTION_MAIN
ns.OPTION_PAGES = OPTION_PAGES
ns.OPTION_PARENT = OPTION_PARENT

-- Every setting, as one object each: its value from the saved variables, set, and what happens
-- when it changes. The window's Options page and the slash commands use these.
--
-- The game's own options get a page of OneCast's own frames (a word on where everything is, and
-- buttons to open it), not the game's checkboxes, sliders and dropdowns. Those come from a pool
-- the game shares between every page of its options, and a control an addon has set up can be
-- handed to one of the game's own pages afterwards: there, an action only the game may take (the
-- Social page's) is blocked and blamed on the addon.
local function NewSetting(key, store, default, onChange)
	local setting = { key = key, callbacks = {} }
	function setting:GetValue()
		local value = store[key]
		if value == nil then
			return default
		end
		return value
	end
	function setting:SetValue(value)
		store[key] = value
		for _, callback in ipairs(self.callbacks) do
			callback(self, value)
		end
	end
	function setting:SetValueChangedCallback(callback)
		self.callbacks[#self.callbacks + 1] = callback
	end
	if onChange then
		setting:SetValueChangedCallback(onChange)
	end
	ns.optionSettings[key] = setting
	return setting
end

local function SettingsPage()
	local f = CreateFrame("Frame")
	f:Hide()
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L["OneCast"])
	local version = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 2)
	version:SetText("v" .. (ns.VERSION or "?"))
	local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
	text:SetPoint("RIGHT", -24, 0)
	text:SetJustifyH("LEFT")
	text:SetSpacing(3)
	text:SetText(L["Every OneCast setting is in its own window, on the Options tab. Your cast key is with the game's key bindings, in OneCast's own section."])
	local y = -96
	local function Button(label, onClick, x)
		local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		b:SetSize(200, 26)
		b:SetPoint("TOPLEFT", x or 16, y)
		b:SetText(label)
		b:SetScript("OnClick", onClick)
		return b
	end
	Button(L["Open OneCast's options"], function()
		ns.Hub.ShowOptions()
	end)
	Button(L["Key bindings"], function()
		ns.OpenSettings()
	end, 232)
	y = y - 46
	local open = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	open:SetPoint("TOPLEFT", 16, y)
	open:SetText(L["Open"])
	y = y - 22
	for i, entry in ipairs({
		{ L["Stats window"], function() ns.Stats.Toggle() end },
		{ L["Tackle box"], function() ns.TackleBox.ToggleWindow() end },
		{ L["Fishing wardrobe"], function() ns.Wardrobe.Show() end },
		{ L["Fishing collection"], function() ns.Book.Show() end },
		{ L["Fisherman's journey"], function() ns.Journey.Show() end },
		{ L["Feedback"], function() ns.Feedback.Show() end },
		{ L["Data report"], function() ns.Feedback.ShowReport() end },
		{ L["What's new"], function() ns.WhatsNew.Show() end },
	}) do
		Button(entry[1], entry[2], i % 2 == 1 and 16 or 232)
		if i % 2 == 0 then
			y = y - 32
		end
	end
	return f
end

local function SetupSettings()
	ns.optionSettings = {}

	local ON_CHANGE = {
		minimapButton = UpdateMinimapVisibility,
		catchWindow = function()
			if ns.CatchWindow then
				ns.CatchWindow.Apply()
			end
		end,
		escapeCloses = function()
			if ns.UI and ns.UI.UpdateEscape then
				ns.UI.UpdateEscape()
			end
		end,
		quietOthers = function()
			UpdateQuiet()
		end,
		autoLootFishing = function()
			UpdateLoot()
		end,
		padFishing = function()
			if ns.Controller then
				ns.Controller.Update()
			end
		end,
		padHints = function()
			if ns.Mini then
				ns.Mini.Refresh()
			end
		end,
		statsMini = function()
			if not db.statsMini and ns.Mini then
				ns.Mini.Hide()
			end
		end,
		tackleBox = function()
			ns.Lure.OnSettingChanged()
		end,
		autoLure = function()
			ns.Lure.OnSettingChanged()
		end,
		conjuredFirst = function()
			ns.Lure.OnSettingChanged()
		end,
		lockWindow = function()
			ns.Hub.UpdateLock()
		end,
		tabBadges = function()
			ns.Hub.UpdateBadges()
		end,
		largerText = function()
			-- The windows, bigger or back: Window scale times the text scale.
			if ns.Stats and ns.Stats.SetScale then
				ns.Stats.SetScale(db.statsScale or 100)
			end
			if ns.Mini and ns.Mini.ApplyScale then
				ns.Mini.ApplyScale()
			end
		end,
		collectionTicks = function()
			if ns.Book and ns.Book.RefreshIfShown then
				ns.Book.RefreshIfShown()
			end
			if ns.Journey and ns.Journey.Refresh then
				ns.Journey.Refresh()
			end
		end,

		mapStrip = function()
			if ns.WorldMap then
				ns.WorldMap.Update()
			end
		end,
	}

	for _, opt in ipairs(OPTIONS) do
		opt.setting = NewSetting(opt.key, opt.char and OneCastCharDB or db,
			opt.char and charDefaults[opt.key] or defaults[opt.key], ON_CHANGE[opt.key])
	end
	for key, spec in pairs(CHOICES) do
		local setting = NewSetting(key, spec.char and OneCastCharDB or db,
			spec.char and charDefaults[key] or defaults[key], spec.onChange)
		if key == "statsScale" then
			ns.scaleSetting = setting
		end
	end

	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local category = Settings.RegisterCanvasLayoutCategory(SettingsPage(), "OneCast")
		if category then
			Settings.RegisterAddOnCategory(category)
			settingsCategory = category
		end
	end
end

-- The tooltip for the minimap button and the addon compartment, laid out like the game's own:
-- the name and version, then gold labels with white values, then what a click does. Rows with
-- nothing to say are left out. `isMinimap` adds the clicks only the minimap button has.
local GOLD, WHITE, GREY, GREEN, RED = { 1, 0.82, 0 }, { 1, 1, 1 }, { 0.6, 0.6, 0.6 }, { 0.12, 1, 0 }, { 1, 0.3, 0.3 }
local HINT = { 0.6, 0.8, 1 }

function ns.FillTooltip(tip, isMinimap)
	local function Row(label, value, color)
		color = color or WHITE
		tip:AddDoubleLine(label, value, GOLD[1], GOLD[2], GOLD[3], color[1], color[2], color[3])
	end
	local function Hint(click, action)
		tip:AddDoubleLine(click, action, HINT[1], HINT[2], HINT[3], WHITE[1], WHITE[2], WHITE[3])
	end
	tip:AddDoubleLine(L["OneCast"], "v" .. ns.VERSION, 1, 1, 1, GREY[1], GREY[2], GREY[3])
	tip:AddLine(" ")

	local keys = { GetBindingKey(BINDING_COMMAND) }
	Row(L["Cast / reel"], #keys > 0 and table.concat(keys, ", ") or L["not bound"], #keys > 0 and WHITE or RED)
	local session = ns.Stats.Summary()
	Row(L["Session"], session or L["nothing yet"], session and WHITE or GREY)
	local lure, problem = ns.Lure.StatusLine()
	if lure then
		Row(L["Lure"], lure, problem and RED or WHITE)
	end
	local camp = ns.Camp and ns.Camp.StatusText()
	if camp then
		Row(L["Camp"], camp, GREEN)
	end
	local contest = ns.Extravaganza and ns.Extravaganza.StatusLine(ns.Stats.CurrentZone())
	if contest then
		Row(L["Extravaganza"], contest)
		local pace = ns.Extravaganza.PaceLine()
		if pace then
			Row(L["Race"], pace)
		end
	end

	tip:AddLine(" ")
	if isMinimap then
		Hint(L["Left-click"], L["Menu: every window"])
		Hint(L["Right-click"], L["Stats window"])
		Hint(L["Shift-click"], L["Fishing collection"])
		Hint(L["Drag"], L["Move this button"])
	else
		Hint(L["Left-click"], L["Options"])
	end
end

-- Every OneCast window in one menu, from the minimap button's left-click. Tooltips can't hold
-- buttons, so this is how the collection and the rest are one click away. OneCast's own small
-- menu rather than the game's: the game's runs its choices inside a protected call, where
-- opening a window was failing without a word. This one's buttons are plain buttons.
local MENU = ns.Retranslate({
	{ L["Stats window"], function() ns.Stats.Toggle() end },
	{ L["Tackle box"], function() ns.TackleBox.ToggleWindow() end },
	{ L["Fishing wardrobe"], function() ns.Wardrobe.Show() end },
	{ L["Fishing collection"], function() ns.Book.Toggle() end },
	{ L["Fisherman's journey"], function() ns.Journey.Show() end },
	{ L["Camp"], function() ns.Camp.ShowPage() end },
	{ L["Fishing Extravaganza"], function() ns.Extravaganza.ShowPage() end },
	{ L["Feedback"], function() ns.Feedback.Toggle() end },
	{ L["Data report"], function() ns.Feedback.ToggleReport() end },
	{ L["What's new"], function() ns.WhatsNew.Toggle() end },
	false, -- a divider
	{ L["Options"], function() ns.Hub.ShowOptions() end },
})
local MENU_WIDTH, MENU_ROW, MENU_PAD = 170, 20, 10

local menuFrame

local function CreateMenu()
	local f = (ns.UI and ns.UI.TryCreate and ns.UI.TryCreate("Frame", "OneCastMenu", UIParent, "TooltipBackdropTemplate"))
		or CreateFrame("Frame", "OneCastMenu", UIParent, "BackdropTemplate")
	if not f.NineSlice and f.SetBackdrop then
		f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
		f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	end
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:Hide()
	ns.UI.EscapeCloses(f)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", MENU_PAD + 2, -MENU_PAD)
	title:SetText(L["OneCast"])
	local y = -MENU_PAD - 18
	f.buttons = {}
	for _, entry in ipairs(MENU) do
		if entry then
			local b = CreateFrame("Button", nil, f)
			b:SetPoint("TOPLEFT", MENU_PAD - 2, y)
			b:SetPoint("TOPRIGHT", -MENU_PAD + 2, y)
			b:SetHeight(MENU_ROW)
			b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			b.text:SetPoint("LEFT", 4, 0)
			b.text:SetText(entry[1])
			b.label = entry[1]
			b:SetScript("OnClick", function()
				f:Hide()
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				entry[2]()
			end)
			f.buttons[#f.buttons + 1] = b
			y = y - MENU_ROW
		else
			local line = f:CreateTexture(nil, "ARTWORK")
			line:SetColorTexture(1, 1, 1, 0.15)
			line:SetHeight(1)
			line:SetPoint("TOPLEFT", MENU_PAD, y - 5)
			line:SetPoint("TOPRIGHT", -MENU_PAD, y - 5)
			y = y - 11
		end
	end
	f:SetSize(MENU_WIDTH, -y + MENU_PAD)

	-- A click anywhere else closes it, as the game's menus do.
	f:SetScript("OnShow", function(self)
		self:RegisterEvent("GLOBAL_MOUSE_DOWN")
	end)
	f:SetScript("OnHide", function(self)
		self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
	end)
	f:SetScript("OnEvent", function(self)
		if not self:IsMouseOver() and not (self.owner and self.owner:IsMouseOver()) then
			self:Hide()
		end
	end)
	return f
end

local function OpenMenu(owner)
	menuFrame = menuFrame or CreateMenu()
	if menuFrame:IsShown() then
		menuFrame:Hide()
		return
	end
	-- Open away from the screen edge the button is nearest.
	menuFrame.owner = owner
	menuFrame:ClearAllPoints()
	local x, y = owner:GetCenter()
	local right = x and x > UIParent:GetWidth() / 2
	local top = y and y > UIParent:GetHeight() / 2
	menuFrame:SetPoint((top and "TOP" or "BOTTOM") .. (right and "RIGHT" or "LEFT"), owner,
		(top and "BOTTOM" or "TOP") .. (right and "LEFT" or "RIGHT"))
	if ns.Controller then
		ns.Controller.Navigate(menuFrame, true)
	end
	menuFrame:Show()
end
ns.OpenMenu = OpenMenu

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
		elseif IsShiftKeyDown() then
			ns.Book.Toggle()
		else
			GameTooltip:Hide()
			OpenMenu(b)
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
		ns.FillTooltip(GameTooltip, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)

	minimapButton = b
	UpdateMinimapPosition()
	UpdateMinimapVisibility()
end

-- Addon compartment (the addons dropdown by the minimap), declared in the TOC.
function OneCast_OnAddonCompartmentClick()
	ns.Hub.ShowOptions()
end

function OneCast_OnAddonCompartmentEnter(_, menuButtonFrame)
	GameTooltip:SetOwner(menuButtonFrame or UIParent, "ANCHOR_LEFT")
	ns.FillTooltip(GameTooltip, false)
	GameTooltip:Show()
end

function OneCast_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

-- A secure button's attributes can't change in combat, so this waits until it's over.
local function ApplyFishingSpell()
	if fishingName and not InCombatLockdown() and button:GetAttribute("spell") ~= fishingName then
		button:SetAttribute("spell", fishingName)
	end
end

local function IsFishingSpell(spellID)
	if not spellID or (issecretvalue and issecretvalue(spellID)) then
		return false
	end
	return SpellName(spellID) == fishingName
end

-- The line comes in: the key goes back to casting, and the weapons' idle timer starts.
local function LineIn()
	fishing = false
	reelEndedAt = GetTime()
	StopReelMode()
	ns.Gear.OnFishingStopped()
end

-- While the key is borrowed for reeling, check now and then that a line really is out. The
-- game says when a cast ends, but if that's ever missed (a loading screen, a disconnect) the key
-- would stay on "interact" and never cast again. Checked out of combat only: in a fight the key
-- is already given back (PLAYER_REGEN_DISABLED), and bindings can't change.
local WATCH_EVERY = 2
local watch

local function LineIsOut()
	local _, _, _, _, _, _, _, spellID = UnitChannelInfo("player")
	return IsFishingSpell(spellID)
end

local function StopWatch()
	if watch then
		watch:Cancel()
		watch = nil
	end
end

local function Watch()
	StopWatch()
	watch = C_Timer.NewTicker(WATCH_EVERY, function()
		if not fishing then
			StopWatch()
		elseif not InCombatLockdown() and not LineIsOut() then
			StopWatch()
			LineIn()
		end
	end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
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
			ns.db = db
			ns.UseLanguage(db.language) -- before anything below builds text
			-- Key binding names were set as the files ran, in English: now in the language in use.
			for name, label in pairs(_G) do
				if type(name) == "string" and name:find("^BINDING_NAME_") and (name:find("ONECAST") or name:find("OneCast"))
					and type(label) == "string" then
					_G[name] = L[label]
				end
			end
			-- Settings of features 1.0 removed (themes, milestones, the clean view, the bobber's
			-- styles and height, the auction source, the report's chat hints): gone from the saves.
			for _, key in ipairs({ "pageTheme",
				"reportHint", "milestones", "milestonesSeeded", "milestonesOn",
				"milestoneAlerts", "sellJunk" }) do
				db[key] = nil
			end
			-- A beam colour that followed the theme, or a custom one: the default now.
			if db.beamColor == "theme" then
				db.beamColor = defaults.beamColor
			end
			OneCastCharDB = OneCastCharDB or {}
			OneCastCharDB.milestones, OneCastCharDB.milestonesSeeded = nil, nil
			for k, v in pairs(charDefaults) do
				if OneCastCharDB[k] == nil then
					OneCastCharDB[k] = v
				end
			end
			ns.ApplyTextSize()
			ns.Theme.Init()
			SetupSettings()
			SetupMinimapButton()
		end
	elseif event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED" then
		local name = ResolveFishingName()
		if name then
			fishingName = name
		end
		ApplyFishingSpell()
		if event == "PLAYER_LOGIN" then
			UpdateQuiet() -- logged in with the pole on
			UpdateLoot()
		end
		if event == "PLAYER_LOGIN" and ns.Onboarding then
			ns.Onboarding.OnLogin() -- no cast key yet: the welcome, to choose one
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		local _, _, spellID = ...
		if IsFishingSpell(spellID) then
			fishing = true
			StartReelMode()
			Watch()
			CheckBagSpace()
			ns.Pools.OnCast()
			ns.Stats.OnCast()
			ns.Gear.OnCast()
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if fishing then
			StopWatch()
			LineIn()
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Past a loading screen, a line that was out is gone.
		if fishing and not InCombatLockdown() and not LineIsOut() then
			StopWatch()
			LineIn()
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		ns.Gear.OnCombatStart()
		-- Last chance before lockdown: give every key back to its normal binding.
		fishing = false
		ClearOverrideBindings(reelOwner)
		ClearOverrideBindings(clickOwner)
		ReleaseCVars("cast") -- the quiet ones follow the pole, which combat puts away
	elseif event == "PLAYER_REGEN_ENABLED" then
		ApplyFishingSpell()
		-- A line still out: combat took the reel key away, and pressing it now would recast.
		local _, _, _, _, _, _, _, spellID = UnitChannelInfo("player")
		if IsFishingSpell(spellID) then
			fishing = true
			StartReelMode()
			Watch()
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		UpdateQuiet()
		UpdateLoot()
	elseif event == "PLAYER_LOGOUT" then
		-- CVars are saved on logout; never save ours.
		ReleaseCVars("cast")
		ReleaseCVars("quiet")
		ReleaseCVars("loot")
	end
end)

SLASH_ONECAST1 = "/onecast"
SlashCmdList.ONECAST = function(msg)
	local cmd = strlower(strtrim(msg or ""))
	if cmd == "" then
		ns.Hub.ShowOptions()
		return
	elseif cmd == "setup" or cmd == "welcome" or cmd == "key" then
		ns.Onboarding.Show() -- choose the cast key
		return
	elseif cmd == "keys" or cmd == "settings" then
		OpenSettings() -- the game's options: the cast key is set there
		return
	elseif cmd == "beam" then
		-- The bobber beam's own colour, from the game's colour picker.
		if ns.Bobber then
			ns.Bobber.PickColor()
		end
		return
	elseif cmd == "riggle" then
		-- A waypoint to Riggle Bassbait, for the Fishing Extravaganza.
		if not ns.Extravaganza.Waypoint() then
			ns.Print(L["couldn't set a waypoint right now (in combat, or the map isn't ready)."])
		end
		return
	elseif cmd == "journey" or cmd == "ranks" then
		ns.Journey.Show()
		return
	elseif cmd == "wardrobe" then
		ns.Wardrobe.Show()
		return
	elseif cmd == "pad" then
		if ns.Controller then
			ns.Controller.Status()
		end
		return
	elseif cmd:match("^search%s") or cmd == "search" then
		local text = msg:match("^%s*%S+%s+(.-)%s*$") or ""
		if ns.Book and ns.Book.Search then
			ns.Book.Search(text)
		end
		return
	elseif cmd == "pad watch" then
		if ns.Controller then
			ns.Controller.Watch()
		end
		return
	elseif cmd == "stats" then
		ns.Stats.Toggle()
		return
	elseif cmd == "session" or cmd == "spots" or cmd == "alltime" or cmd == "farm" or cmd == "records" then
		ns.Stats.Toggle(cmd)
		return
	elseif cmd == "reset" then
		ns.Stats.Reset()
		Print(L["session stats reset."])
		return
	elseif cmd == "gear" then
		OneCast_RestoreWeapons()
		return
	elseif cmd == "done" then
		OneCast_DoneFishing()
		return
	elseif cmd == "scan" then
		ns.Prices.Scan()
		return
	elseif cmd == "book" or cmd == "collection" then
		ns.Book.Toggle()
		return
	elseif cmd == "camp" then
		ns.Camp.ShowPage()
		return
	elseif cmd == "contest" then
		ns.Extravaganza.ShowPage()
		return
	elseif cmd == "feedback" or cmd == "bug" then
		ns.Feedback.Show()
		return
	elseif cmd == "report" or cmd == "data" then
		ns.Feedback.ShowReport()
		return
	elseif cmd == "new" or cmd == "whatsnew" then
		ns.WhatsNew.Toggle()
		return
	elseif cmd == "tackle" then
		ns.TackleBox.ToggleWindow()
		return
	elseif cmd == "tackle reset" then
		Print(ns.TackleBox.ResetPosition() and L["tackle box button back to its first place."]
			or L["the tackle box button can't move during combat."])
		return
	elseif cmd == "forgetpools" then
		ns.Pools.Forget()
		ns.Book.RefreshIfShown()
		Print(L["remembered pools cleared."])
		return
	elseif cmd == "theme" or cmd:match("^theme%s") then
		local name = cmd:match("^theme%s+(%a+)")
		local label = ns.Theme.Choose(name)
		Print(label and (L["theme: "] .. label) or (L["no theme called "] .. name .. L[". Try "] .. table.concat(ns.Theme.ORDER, ", ") .. "."))
		return
	elseif cmd == "scale" or cmd:match("^scale%s") then
		local percent = tonumber(cmd:match("^scale%s+(%d+)"))
		if percent then
			ns.Stats.SetScale(percent)
			Print(L["window scale: "] .. db.statsScale .. "%")
		else
			Print(L["usage: /onecast scale 50-200"])
		end
		return
	end
	for _, opt in ipairs(OPTIONS) do
		if opt.cmd == cmd then
			-- Through the setting, so the panel and its callbacks stay in sync.
			local store = opt.char and OneCastCharDB or db
			opt.setting:SetValue(not store[opt.key])
			Print(opt.label .. ": " .. (store[opt.key] and "on" or "off"))
			return
		end
	end
	Print("v" .. ns.VERSION .. L[" | key: "] .. BoundKeysText() .. L[" | spell: "] .. tostring(fishingName))
	Print(L["/onecast - open options"])
	Print(L["/onecast setup - choose your cast key"])
	Print(L["/onecast new - what's new in each version"])
	Print(L["/onecast pad - what OneCast sees of your controller, if it isn't behaving"])
	Print(L["/onecast search <words> - search catches, zones, recipes, gear, ranks and settings"])
	Print(L["/onecast wardrobe - choose what you wear to fish"])
	Print(L["/onecast journey - the Fishing ranks, and where to learn the next"])
	Print(L["/onecast contest - the Fishing Extravaganza (/onecast riggle for a waypoint to Booty Bay)"])
	Print(L["/onecast beam - pick your own colour for the bobber's beam"])
	Print(L["/onecast book - fishing collection (/onecast camp for the Camp page)"])
	Print(L["/onecast feedback - report a bug or suggest an idea"])
	Print(L["/onecast report - your fishing data, to share and help fill in Forever's numbers"])
	Print(L["/onecast theme [name] - window colours (no name: the next one)"])
	Print(L["/onecast tackle - tackle box (/onecast tackle reset moves its button back)"])
	Print(L["/onecast stats - stats window (or /onecast session|spots|alltime for a tab)"])
	Print(L["/onecast reset - start a new session"])
	Print(L["/onecast gear - put your weapons back on"])
	Print(L["/onecast done - done fishing: weapons and gear back on"])
	Print(L["/onecast scan - price your catch with Auctionator (auction house open)"])
	Print(L["/onecast scale 50-200 - window size in percent"])
	for _, opt in ipairs(OPTIONS) do
		local store = opt.char and OneCastCharDB or db
		Print("/onecast " .. opt.cmd .. " - " .. opt.label .. " (" .. (store[opt.key] and "on" or "off") .. ")")
	end
end
