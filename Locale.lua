-- OneCast's translations. Every player-facing string is looked up as L["English text"]; a phrase
-- with no translation in the language in use is its English self, so nothing can go missing.
-- Each language's file (Locales/) puts its phrases in ns.LOCALES. All of them load, so OneCast's
-- Language setting can pick any. The setting is saved, and saved settings only arrive after every
-- file has run (ADDON_LOADED), so:
-- - L looks the phrase up each time rather than once at load;
-- - while the files run, L gives English. Text kept in a table at load (labels, tab names) is then
--   its English phrase, and is looked up again, L[text], where it's shown. Looking up a phrase that's
--   already translated gives it back unchanged, so a second L[] never hurts.

local _, ns = ...

-- Clients that read another language's phrases.
local SHARED = { esMX = "esES", enGB = "enUS" }

ns.LOCALES = {}
ns.locale = "enUS" -- until ADDON_LOADED (UseLanguage)

ns.L = setmetatable({}, {
	__index = function(_, phrase)
		local phrases = ns.LOCALES[ns.locale]
		return phrases and phrases[phrase] or phrase
	end,
})

-- Tables of text built while the files run (tab names, option labels): their strings are English
-- then, and UseLanguage swaps each for the language in use. Only display tables go here, never
-- ones whose strings are keys: a string that's a phrase gets translated, wherever it sits.
local retranslate = {}
function ns.Retranslate(t)
	retranslate[#retranslate + 1] = t
	return t
end

-- Fields that are keys or names the code matches, never shown as they are: a theme called
-- "Ashenvale" mustn't turn a map's zone = "Ashenvale" into German.
local KEYS = { zone = true, faction = true, key = true, id = true, kind = true, cmd = true, name = true,
	buffName = true, blueprintName = true }

local function Swap(t, seen)
	if seen[t] then
		return
	end
	seen[t] = true
	for k, v in pairs(t) do
		if not KEYS[k] then
			if type(v) == "string" then
				local text = ns.L[v]
				if text ~= v then
					t[k] = text
				end
			elseif type(v) == "table" then
				Swap(v, seen)
			end
		end
	end
end

-- The language OneCast speaks: the setting's choice, or "" for the game's own. Once, at
-- ADDON_LOADED, before anything shows.
function ns.UseLanguage(choice)
	-- Settings are shared by the account: Russian picked on a Russian client mustn't come out blank
	-- on an English one, so only a language this client can show is used.
	local showable = false
	for _, code in ipairs(ns.Languages()) do
		showable = showable or code == choice
	end
	if showable and (choice == "enUS" or ns.LOCALES[choice]) then
		ns.locale = choice
	else
		ns.locale = SHARED[GetLocale()] or GetLocale()
	end
	if ns.locale ~= "enUS" then
		local seen = {}
		for _, t in ipairs(retranslate) do
			Swap(t, seen)
		end
	end
	retranslate = {}
end

-- The languages this client can show: its letters come from the game's fonts, so a Latin-script
-- client can't draw Russian, Chinese or Korean (they'd come out blank), while those clients' fonts
-- also hold Latin letters.
local LATIN = { "enUS", "deDE", "frFR", "esES", "ptBR" }
local OWN_SCRIPT = { ruRU = true, zhCN = true, zhTW = "zhCN", koKR = true }
function ns.Languages()
	local list = {}
	for _, code in ipairs(LATIN) do
		list[#list + 1] = code
	end
	local client = GetLocale()
	local own = OWN_SCRIPT[client]
	if own then
		list[#list + 1] = own == true and client or own
	end
	return list
end

-- Each language's name, in that language.
ns.LANGUAGE_NAMES = {
	enUS = "English", deDE = "Deutsch", frFR = "Français", esES = "Español", ptBR = "Português",
	ruRU = "Русский", zhCN = "简体中文", koKR = "한국어",
}
