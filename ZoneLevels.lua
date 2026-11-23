-- Fishing skill needed in each zone so that no fish get away: the zone's fishing level + 95.
-- Lure and pole bonuses count towards it. Zone skill is set by the server, not the game data,
-- and no source has published Forever's own numbers yet (10 November 2026), so these are
-- Classic's, from CMaNGOS's Classic 1.12 world database (skill_fishing_base_level), which
-- AzerothCore's matches for every Classic zone. Badlands, Blasted Lands and Searing Gorge have
-- no level there: they have no water to fish. The stats window also counts real getaways per
-- zone, with the skill they happened at: they judge zones missing from this table, overrule
-- ZONE_FISHING_NOTE, and overrule this table too when a fish gets away at or above your
-- current skill.
-- Keyed by English zone name; ZoneNames.lua swaps them for the client's own at load.

local _, ns = ...

local LEVELS = {
	[25] = {
		"Dun Morogh", "Durotar", "Elwynn Forest", "Mulgore", "Teldrassil", "Tirisfal Glades",
		-- Forever's own, from a player's /onecast report (13 November 2026): 10 catches at skill
		-- 0-24 and none got away. Its fish are the starting zones' (Brilliant Smallfish, the Mud
		-- Snappers). Not a Classic number: a getaway above 25 would overrule it, as for any zone.
		-- Three more reports (19 to 22 November 2026) agree: 2 to 5 got away at 0-24 each, and
		-- none in over 300 catches from 25 up. Mulgore's and Dun Morogh's 25 hold in Forever too
		-- (4 of 9 got away at 0-24 in Mulgore; 1 of 24 at 0-24 in Dun Morogh, none in 48 above),
		-- and Elwynn Forest's (none in 64 catches from 25 up, 22 November 2026).
		"Zephras Isle",
	},
	[75] = {
		"Darkshore", "Loch Modan", "Silverpine Forest", "Westfall",
		-- Orgrimmar's 75 is confirmed in Forever by a player's report (10 November 2026): 3 got away at
		-- skill 50-74, none in 178 catches from 75 up. Stormwind City's too (13 November 2026): 12 of
		-- 36 got away at 25-49, as 75 would have it, and none in 22 catches at 50-74. Darkshore's
		-- as well (22 November 2026): 8 of 31 got away at 50-74, none at 75 up.
		"Stormwind City", "Orgrimmar", "Ironforge", "Thunder Bluff", "Undercity", "Darnassus",
		"The Deadmines", "Wailing Caverns", "Blackfathom Deeps",
	},
	[100] = {
		-- Forever's own, from two players' /onecast reports (11 and 12 November 2026): fish got
		-- away about 7% of the time at skill 75-99 (2 of 28, and 4 of 57), and none in 33 catches
		-- at 100-124. Classic's is 75.
		"The Barrens",
	},
	[150] = {
		-- Stonetalon Mountains' 150 is confirmed in Forever by a player's report (14 November 2026):
		-- 2 of 17 got away at skill 125-149. Redridge Mountains' too (18 November 2026): 3 of 33
		-- got away at 125-149, none at 150 up.
		"Ashenvale", "Duskwood", "Hillsbrad Foothills", "Redridge Mountains",
		"Stonetalon Mountains", "Wetlands",
	},
	[225] = {
		-- Desolace's 225 is confirmed in Forever by a player's report (14 November 2026): fish got
		-- away less often as skill rose towards 225 (3 of 4 at 150-174, 2 of 7 at 175-199, 1 of 7
		-- at 200-224), and none in 231 catches from 225 up.
		-- Dustwallow Marsh's too (23 November 2026): 4 of 27 got away at 200-224, none in 46 from 250.
		"Alterac Mountains", "Arathi Highlands", "Desolace", "Dustwallow Marsh",
		"Stranglethorn Vale", "Swamp of Sorrows", "Thousand Needles", "Scarlet Monastery",
		-- Forever's own, from a player's /onecast report (10 November 2026), fishing Eastwind
		-- Shore: 3 got away at skill 150-174, none in 17 catches at 225-249. Its coast gives the
		-- same catches as Classic's 225 zones (Rockscale Cod, Spotted Yellowtail, Sturdy Locked
		-- Chest). Not a Classic number: a getaway above 225 would overrule it, as for any zone.
		"Riverglades",
		-- Forever's own, from a player's /onecast report (17 November 2026): 3 of 19 got away at
		-- skill 200-224, and none in 42 catches from 225 up. Not a Classic number.
		"City of Dalaran",
	},
	[300] = {
		-- Feralas' and Tanaris' 300 hold in Forever (23 November 2026): 9 of 21 got away at 250-274
		-- in Feralas and 4 of 6 in Tanaris, none in over 300 catches from 300 up.
		"Azshara", "Felwood", "Feralas", "Moonglade", "Tanaris", "The Hinterlands",
		"Un'Goro Crater", "Western Plaguelands", "Sunken Temple", "Maraudon",
	},
	[425] = {
		"Burning Steppes", "Deadwind Pass", "Eastern Plaguelands", "Silithus", "Winterspring",
		"Zul'Gurub", "Stratholme", "Scholomance",
	},
}

-- Dungeons by instance map ID (GetInstanceInfo), with the name used in the tables above. The
-- game's own name for a dungeon can differ from its area's: Forever calls Wailing Caverns "The
-- Wailing Caverns". So inside one, OneCast files everything under this name instead.
ns.INSTANCE_ZONES = {
	[36] = "The Deadmines",
	[43] = "Wailing Caverns",
	[48] = "Blackfathom Deeps",
	[189] = "Scarlet Monastery",
	[109] = "Sunken Temple",
	[349] = "Maraudon",
	[309] = "Zul'Gurub",
	[329] = "Stratholme",
	[289] = "Scholomance",
}

-- Names the game has been seen to use for those dungeons, moved under the tables' name.
ns.INSTANCE_ALIASES = {
	["The Wailing Caverns"] = "Wailing Caverns",
}

-- Waters inside a zone with a level of their own, keyed by the sub-zone's name (what
-- GetSubZoneText says while you stand there). Same source as above.
ns.SPOT_FISHING_SKILL = {
	["Jaguero Isle"] = 300,      -- Stranglethorn Vale
	["Jademir Lake"] = 425,      -- Feralas
	["Bay of Storms"] = 425,     -- Azshara
	["Hetaera's Clutch"] = 425,  -- Azshara
	["Scalebeard's Cave"] = 425, -- Azshara
}

ns.ZONE_FISHING_SKILL = {}
for skill, zones in pairs(LEVELS) do
	for _, zone in ipairs(zones) do
		ns.ZONE_FISHING_SKILL[zone] = skill
	end
end

-- Zones new in Forever with no level yet (Shen'dralas, Mount Hyjal, Gilneas): the stats window
-- judges them from your own catches and getaways. The book's Zones view lists them all the same.
-- Riverglades, Zephras Isle and City of Dalaran were here until players' reports measured them
-- (see 225 and 25 above).
-- Excavation Site: Wetlands is Forever's own, fished in a player's report (17 November 2026):
-- 3 catches, none got away, too few for a level.
-- The Drowned City is Forever's own too: 4 catches at skill 350-374, none got away (23 November
-- 2026), too few for a level.
ns.ZONE_FISHING_UNKNOWN = { "Shen'dralas", "Mount Hyjal", "Gilneas", "Excavation Site: Wetlands", "The Drowned City" }

-- Other names the game gives a zone, for part of it: stats are kept under the tables' name.
-- Dalaran is the city inside Forever's City of Dalaran (a player's report, 17 November 2026).
ns.ZONE_ALIASES = {
	["Dalaran"] = "City of Dalaran",
}

-- Notes shown instead of a level, until a getaway in that zone proves them wrong:
-- { [zone] = "text" }. Riverglades' "no minimum skill" (forever-bugs#189) was dropped when a
-- player's report showed fish getting away there below 175.
ns.ZONE_FISHING_NOTE = {}
