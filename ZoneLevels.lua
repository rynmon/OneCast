-- Fishing skill needed in each zone so that no fish get away, from Classic Era data
-- (zone fishing level + 95). Lure and pole bonuses count towards it. Forever may have
-- retuned some zones, so the stats window also counts real getaways per zone.
-- Keyed by English zone name (GetRealZoneText); other client languages show "unknown".

local _, ns = ...

local LEVELS = {
	[25] = {
		"Dun Morogh", "Durotar", "Elwynn Forest", "Mulgore", "Teldrassil", "Tirisfal Glades",
		"Stormwind City", "Orgrimmar", "Ironforge", "Thunder Bluff", "Undercity", "Darnassus",
	},
	[75] = {
		"The Barrens", "Darkshore", "Loch Modan", "Silverpine Forest", "Westfall",
	},
	[150] = {
		"Ashenvale", "Duskwood", "Hillsbrad Foothills", "Redridge Mountains",
		"Stonetalon Mountains", "Wetlands",
	},
	[225] = {
		"Alterac Mountains", "Arathi Highlands", "Badlands", "Desolace", "Dustwallow Marsh",
		"Stranglethorn Vale", "Swamp of Sorrows", "Thousand Needles",
	},
	[300] = {
		"Azshara", "Blasted Lands", "Burning Steppes", "Deadwind Pass", "Eastern Plaguelands",
		"Felwood", "Feralas", "Moonglade", "Searing Gorge", "Silithus", "Tanaris",
		"The Hinterlands", "Un'Goro Crater", "Western Plaguelands", "Winterspring",
	},
}

ns.ZONE_FISHING_SKILL = {}
for skill, zones in pairs(LEVELS) do
	for _, zone in ipairs(zones) do
		ns.ZONE_FISHING_SKILL[zone] = skill
	end
end

-- Zones new in Forever. Wowhead's Forever database has no zone fishing levels, so these
-- come from player reports and say so in the stats window.
ns.ZONE_FISHING_NOTE = {
	-- Forever bug report (ClassicWoWCommunity/forever-bugs#189, Sept 2026): skill 1 catches
	-- every time here, though its fish are 225+ tier. Expect Blizzard to add a minimum.
	["Riverglades"] = "no minimum skill reported (beta bug)",
}
ns.ZONE_FISHING_SKILL["Riverglades"] = 1
