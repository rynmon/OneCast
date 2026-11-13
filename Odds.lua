-- How likely each catch is, per cast, from Classic's loot tables: CMaNGOS's Classic 1.12
-- fishing loot (open water, by zone) and fishing pool loot (by pool). In each, one item is picked
-- from a group: rows with a chance get it, the rest share what's left. These are Classic's odds:
-- Forever's may differ, and the game doesn't say. Generated (scratchpad odds.py), so don't hand-edit.
--
-- [itemID] = { water = { [zone] = percent per catch, best place first }, pool = { name, percent } }
-- Items Classic's tables don't have (Forever's own) aren't here.

local _, ns = ...

ns.ODDS = {
	[6292] = { water = { ["Dun Morogh"] = 0.1, ["Durotar"] = 0.1, ["Elwynn Forest"] = 0.1, ["Mulgore"] = 0.1, ["Teldrassil"] = 0.1 } }, -- 10 Pound Mud Snapper
	[13917] = { water = { ["Azshara"] = 0.01 } }, -- 103 Pound Mightfish
	[13909] = { water = { ["Azshara"] = 0.15 } }, -- 12 Pound Lobster
	[6294] = { water = { ["Dun Morogh"] = 0.07, ["Durotar"] = 0.07, ["Elwynn Forest"] = 0.07, ["Mulgore"] = 0.07, ["Teldrassil"] = 0.07 } }, -- 12 Pound Mud Snapper
	[13910] = { water = { ["Azshara"] = 0.08 } }, -- 15 Pound Lobster
	[6295] = { water = { ["Dun Morogh"] = 0.03, ["Durotar"] = 0.03, ["Elwynn Forest"] = 0.03, ["Mulgore"] = 0.03, ["Teldrassil"] = 0.03 } }, -- 15 Pound Mud Snapper
	[13901] = { water = { ["Burning Steppes"] = 0.2, ["Eastern Plaguelands"] = 0.2, ["Feralas"] = 0.2, ["Scholomance"] = 0.2, ["Silithus"] = 0.2, ["Stratholme"] = 0.2, ["Winterspring"] = 0.2, ["Zul'Gurub"] = 0.2 } }, -- 15 Pound Salmon
	[6309] = { water = { ["Darkshore"] = 0.4, ["Darnassus"] = 0.4, ["Ironforge"] = 0.4, ["Orgrimmar"] = 0.4, ["Stonetalon Mountains"] = 0.4, ["Stormwind City"] = 0.4, ["The Barrens"] = 0.4, ["The Deadmines"] = 0.4, ["Thunder Bluff"] = 0.4, ["Undercity"] = 0.4, ["Wailing Caverns"] = 0.4, ["Westfall"] = 0.4, ["Feralas"] = 0.1 } }, -- 17 Pound Catfish
	[13902] = { water = { ["Burning Steppes"] = 0.1, ["Eastern Plaguelands"] = 0.1, ["Feralas"] = 0.1, ["Scholomance"] = 0.1, ["Silithus"] = 0.1, ["Stratholme"] = 0.1, ["Winterspring"] = 0.1, ["Zul'Gurub"] = 0.1 } }, -- 18 Pound Salmon
	[6310] = { water = { ["Alterac Mountains"] = 0.2, ["Arathi Highlands"] = 0.2, ["Ashenvale"] = 0.2, ["Darkshore"] = 0.2, ["Darnassus"] = 0.2, ["Desolace"] = 0.2, ["Duskwood"] = 0.2, ["Dustwallow Marsh"] = 0.2, ["Hillsbrad Foothills"] = 0.2, ["Ironforge"] = 0.2, ["Orgrimmar"] = 0.2, ["Redridge Mountains"] = 0.2, ["Scarlet Monastery"] = 0.2, ["Stonetalon Mountains"] = 0.2, ["Stormwind City"] = 0.2, ["Stranglethorn Vale"] = 0.2, ["Swamp of Sorrows"] = 0.2, ["The Barrens"] = 0.2, ["The Deadmines"] = 0.2, ["Thousand Needles"] = 0.2, ["Thunder Bluff"] = 0.2, ["Undercity"] = 0.2, ["Wailing Caverns"] = 0.2, ["Westfall"] = 0.2, ["Wetlands"] = 0.2, ["Feralas"] = 0.1 } }, -- 19 Pound Catfish
	[13911] = { water = { ["Azshara"] = 0.06 } }, -- 19 Pound Lobster
	[13912] = { water = { ["Azshara"] = 0.03 } }, -- 21 Pound Lobster
	[6311] = { water = { ["Feralas"] = 0.1, ["Alterac Mountains"] = 0.06, ["Arathi Highlands"] = 0.06, ["Ashenvale"] = 0.06, ["Darkshore"] = 0.06, ["Darnassus"] = 0.06, ["Desolace"] = 0.06, ["Duskwood"] = 0.06, ["Dustwallow Marsh"] = 0.06, ["Hillsbrad Foothills"] = 0.06, ["Ironforge"] = 0.06, ["Orgrimmar"] = 0.06, ["Redridge Mountains"] = 0.06, ["Scarlet Monastery"] = 0.06, ["Stonetalon Mountains"] = 0.06, ["Stormwind City"] = 0.06, ["Stranglethorn Vale"] = 0.06, ["Swamp of Sorrows"] = 0.06, ["The Barrens"] = 0.06, ["The Deadmines"] = 0.06, ["Thousand Needles"] = 0.06, ["Thunder Bluff"] = 0.06, ["Undercity"] = 0.06, ["Wailing Caverns"] = 0.06, ["Westfall"] = 0.06, ["Wetlands"] = 0.06 } }, -- 22 Pound Catfish
	[13913] = { water = { ["Azshara"] = 0.01 } }, -- 22 Pound Lobster
	[13903] = { water = { ["Burning Steppes"] = 0.06, ["Eastern Plaguelands"] = 0.06, ["Feralas"] = 0.06, ["Scholomance"] = 0.06, ["Silithus"] = 0.06, ["Stratholme"] = 0.06, ["Winterspring"] = 0.06, ["Zul'Gurub"] = 0.06 } }, -- 22 Pound Salmon
	[13904] = { water = { ["Burning Steppes"] = 0.03, ["Eastern Plaguelands"] = 0.03, ["Feralas"] = 0.03, ["Scholomance"] = 0.03, ["Silithus"] = 0.03, ["Stratholme"] = 0.03, ["Winterspring"] = 0.03, ["Zul'Gurub"] = 0.03 } }, -- 25 Pound Salmon
	[6363] = { water = { ["Feralas"] = 0.1, ["Alterac Mountains"] = 0.03, ["Arathi Highlands"] = 0.03, ["Ashenvale"] = 0.03, ["Darkshore"] = 0.03, ["Darnassus"] = 0.03, ["Desolace"] = 0.03, ["Duskwood"] = 0.03, ["Dustwallow Marsh"] = 0.03, ["Hillsbrad Foothills"] = 0.03, ["Ironforge"] = 0.03, ["Orgrimmar"] = 0.03, ["Redridge Mountains"] = 0.03, ["Scarlet Monastery"] = 0.03, ["Stonetalon Mountains"] = 0.03, ["Stormwind City"] = 0.03, ["Stranglethorn Vale"] = 0.03, ["Swamp of Sorrows"] = 0.03, ["The Barrens"] = 0.03, ["The Deadmines"] = 0.03, ["Thousand Needles"] = 0.03, ["Thunder Bluff"] = 0.03, ["Undercity"] = 0.03, ["Wailing Caverns"] = 0.03, ["Westfall"] = 0.03, ["Wetlands"] = 0.03 } }, -- 26 Pound Catfish
	[13905] = { water = { ["Burning Steppes"] = 0.01, ["Eastern Plaguelands"] = 0.01, ["Feralas"] = 0.01, ["Scholomance"] = 0.01, ["Silithus"] = 0.01, ["Stratholme"] = 0.01, ["Winterspring"] = 0.01, ["Zul'Gurub"] = 0.01 } }, -- 29 Pound Salmon
	[6364] = { water = { ["Alterac Mountains"] = 0.01, ["Arathi Highlands"] = 0.01, ["Ashenvale"] = 0.01, ["Darkshore"] = 0.01, ["Darnassus"] = 0.01, ["Desolace"] = 0.01, ["Duskwood"] = 0.01, ["Dustwallow Marsh"] = 0.01, ["Feralas"] = 0.01, ["Hillsbrad Foothills"] = 0.01, ["Ironforge"] = 0.01, ["Orgrimmar"] = 0.01, ["Redridge Mountains"] = 0.01, ["Scarlet Monastery"] = 0.01, ["Stonetalon Mountains"] = 0.01, ["Stormwind City"] = 0.01, ["Stranglethorn Vale"] = 0.01, ["Swamp of Sorrows"] = 0.01, ["The Barrens"] = 0.01, ["The Deadmines"] = 0.01, ["Thousand Needles"] = 0.01, ["Thunder Bluff"] = 0.01, ["Undercity"] = 0.01, ["Wailing Caverns"] = 0.01, ["Westfall"] = 0.01, ["Wetlands"] = 0.01 } }, -- 32 Pound Catfish
	[13885] = { water = { ["Azshara"] = 0.3, ["Felwood"] = 0.3, ["Maraudon"] = 0.3, ["Moonglade"] = 0.3, ["The Hinterlands"] = 0.3, ["Un'Goro Crater"] = 0.3, ["Western Plaguelands"] = 0.3 } }, -- 34 Pound Redgill
	[13886] = { water = { ["Azshara"] = 0.2, ["Felwood"] = 0.2, ["Maraudon"] = 0.2, ["Moonglade"] = 0.2, ["The Hinterlands"] = 0.2, ["Un'Goro Crater"] = 0.2, ["Western Plaguelands"] = 0.2 } }, -- 37 Pound Redgill
	[13876] = { water = { ["Azshara"] = 0.4, ["Tanaris"] = 0.4 } }, -- 40 Pound Yellowtail
	[13882] = { water = { ["Azshara"] = 0.1, ["Felwood"] = 0.1, ["Maraudon"] = 0.1, ["Moonglade"] = 0.1, ["The Hinterlands"] = 0.1, ["Un'Goro Crater"] = 0.1, ["Western Plaguelands"] = 0.1 } }, -- 42 Pound Redgill
	[13883] = { water = { ["Azshara"] = 0.06, ["Felwood"] = 0.06, ["Maraudon"] = 0.06, ["Moonglade"] = 0.06, ["The Hinterlands"] = 0.06, ["Un'Goro Crater"] = 0.06, ["Western Plaguelands"] = 0.06 } }, -- 45 Pound Redgill
	[13877] = { water = { ["Azshara"] = 0.2, ["Tanaris"] = 0.2 } }, -- 47 Pound Yellowtail
	[13884] = { water = { ["Azshara"] = 0.03, ["Felwood"] = 0.03, ["Maraudon"] = 0.03, ["Moonglade"] = 0.03, ["The Hinterlands"] = 0.03, ["Un'Goro Crater"] = 0.03, ["Western Plaguelands"] = 0.03 } }, -- 49 Pound Redgill
	[13887] = { water = { ["Azshara"] = 0.01, ["Felwood"] = 0.01, ["Maraudon"] = 0.01, ["Moonglade"] = 0.01, ["The Hinterlands"] = 0.01, ["Un'Goro Crater"] = 0.01, ["Western Plaguelands"] = 0.01 } }, -- 52 Pound Redgill
	[13878] = { water = { ["Azshara"] = 0.06, ["Tanaris"] = 0.06 } }, -- 53 Pound Yellowtail
	[13879] = { water = { ["Azshara"] = 0.03, ["Tanaris"] = 0.03 } }, -- 59 Pound Yellowtail
	[13880] = { water = { ["Azshara"] = 0.01, ["Tanaris"] = 0.01 } }, -- 68 Pound Yellowtail
	[13907] = { water = { ["Azshara"] = 0.3 } }, -- 7 Pound Lobster
	[13914] = { water = { ["Azshara"] = 0.2 } }, -- 70 Pound Mightfish
	[13915] = { water = { ["Azshara"] = 0.06 } }, -- 85 Pound Mightfish
	[13908] = { water = { ["Azshara"] = 0.2 } }, -- 9 Pound Lobster
	[13916] = { water = { ["Azshara"] = 0.03 } }, -- 92 Pound Mightfish
	[6356] = { water = { ["Durotar"] = 2, ["Teldrassil"] = 2, ["Tirisfal Glades"] = 2 } }, -- Battered Chest
	[7973] = { water = { ["Azshara"] = 10, ["Tanaris"] = 8 } }, -- Big-mouth Clam
	[6643] = { water = { ["Dun Morogh"] = 0.2, ["Durotar"] = 0.2, ["Elwynn Forest"] = 0.2, ["Mulgore"] = 0.2, ["Teldrassil"] = 0.2 } }, -- Bloated Brilliant Smallfish
	[6647] = { water = { ["Ashenvale"] = 0.3, ["Duskwood"] = 0.3, ["Hillsbrad Foothills"] = 0.3, ["Redridge Mountains"] = 0.3, ["Stonetalon Mountains"] = 0.3, ["Wetlands"] = 0.3 } }, -- Bloated Bristle Whisker Catfish
	[8366] = { water = { ["Alterac Mountains"] = 0.3, ["Arathi Highlands"] = 0.3, ["Desolace"] = 0.3, ["Dustwallow Marsh"] = 0.3, ["Scarlet Monastery"] = 0.3, ["Stranglethorn Vale"] = 0.3, ["Swamp of Sorrows"] = 0.3, ["Thousand Needles"] = 0.3, ["Feralas"] = 0.2 } }, -- Bloated Mithril Head Trout
	[6645] = { water = { ["Darkshore"] = 0.3, ["Darnassus"] = 0.3, ["Ironforge"] = 0.3, ["Orgrimmar"] = 0.3, ["Stonetalon Mountains"] = 0.3, ["Stormwind City"] = 0.3, ["The Barrens"] = 0.3, ["The Deadmines"] = 0.3, ["Thunder Bluff"] = 0.3, ["Undercity"] = 0.3, ["Wailing Caverns"] = 0.3, ["Westfall"] = 0.3 } }, -- Bloated Mud Snapper
	[13881] = { water = { ["Azshara"] = 0.3, ["Felwood"] = 0.3, ["Maraudon"] = 0.3, ["Moonglade"] = 0.3, ["The Hinterlands"] = 0.3, ["Un'Goro Crater"] = 0.3, ["Western Plaguelands"] = 0.3 } }, -- Bloated Redgill
	[13891] = { water = { ["Burning Steppes"] = 0.4, ["Eastern Plaguelands"] = 0.4, ["Feralas"] = 0.4, ["Scholomance"] = 0.4, ["Silithus"] = 0.4, ["Stratholme"] = 0.4, ["Winterspring"] = 0.4, ["Zul'Gurub"] = 0.4 } }, -- Bloated Whitescale Salmon
	[6651] = { water = { ["The Barrens"] = 0.1 } }, -- Broken Wine Bottle
	[19803] = { pool = { "School of Tastyfish", 0.1 } }, -- Brownell's Blue Striped Racer
	[13888] = { water = { ["Azshara"] = 39.87 } }, -- Darkclaw Lobster
	[12238] = { water = { ["Darkshore"] = 30 } }, -- Darkshore Grouper
	[6351] = { water = { ["Darkshore"] = 0.5, ["Silverpine Forest"] = 0.5, ["The Barrens"] = 0.5, ["Westfall"] = 0.5 } }, -- Dented Crate
	[6522] = { water = { ["The Barrens"] = 30, ["Wailing Caverns"] = 30 }, pool = { "School of Deviate Fish", 85 } }, -- Deviate Fish
	[19806] = { pool = { "School of Tastyfish", 0.1 } }, -- Dezian Queenfish
	[6359] = { water = { ["Ashenvale"] = 15, ["Hillsbrad Foothills"] = 15, ["Wetlands"] = 15, ["Arathi Highlands"] = 12, ["Desolace"] = 12, ["Dustwallow Marsh"] = 12, ["Stranglethorn Vale"] = 12, ["Swamp of Sorrows"] = 12, ["Azshara"] = 10, ["Tanaris"] = 10 }, pool = { "Firefin Snapper School", 85 } }, -- Firefin Snapper
	[13874] = { water = { ["Azshara"] = 0.6, ["Tanaris"] = 0.5 } }, -- Heavy Crate
	[13875] = { water = { ["Azshara"] = 0.5, ["Tanaris"] = 0.5 } }, -- Ironbound Locked Chest
	[19805] = { pool = { "School of Tastyfish", 0.1 } }, -- Keefer's Angelfish
	[13893] = { water = { ["Azshara"] = 5 } }, -- Large Raw Mightfish
	[13757] = { water = { ["Burning Steppes"] = 12, ["Eastern Plaguelands"] = 12, ["Feralas"] = 12, ["Scholomance"] = 12, ["Silithus"] = 12, ["Stratholme"] = 12, ["Winterspring"] = 12, ["Zul'Gurub"] = 12, ["Azshara"] = 7, ["Deadwind Pass"] = 7, ["Felwood"] = 7, ["Maraudon"] = 7, ["Moonglade"] = 7, ["The Hinterlands"] = 7, ["Un'Goro Crater"] = 7, ["Western Plaguelands"] = 7 } }, -- Lightning Eel
	[6307] = { water = { ["Darkshore"] = 0.5, ["Silverpine Forest"] = 0.5, ["The Barrens"] = 0.5, ["Westfall"] = 0.5, ["Ashenvale"] = 0.4, ["Hillsbrad Foothills"] = 0.4, ["Wetlands"] = 0.4 } }, -- Message in a Bottle
	[6458] = { water = { ["Stonetalon Mountains"] = 10, ["The Barrens"] = 10 } }, -- Oil Covered Fish
	[6358] = { water = { ["Ashenvale"] = 25, ["Hillsbrad Foothills"] = 25, ["Wetlands"] = 25, ["Silverpine Forest"] = 15, ["The Barrens"] = 15, ["Westfall"] = 15, ["Arathi Highlands"] = 12, ["Desolace"] = 12, ["Dustwallow Marsh"] = 12, ["Stranglethorn Vale"] = 12, ["Swamp of Sorrows"] = 12, ["Azshara"] = 10, ["Darkshore"] = 10, ["Felwood"] = 10, ["Maraudon"] = 10, ["Moonglade"] = 10, ["The Hinterlands"] = 10, ["Un'Goro Crater"] = 10, ["Western Plaguelands"] = 10 }, pool = { "Oily Blackmouth School", 85 } }, -- Oily Blackmouth
	[6291] = { water = { ["Dun Morogh"] = 58.8, ["Durotar"] = 58.8, ["Elwynn Forest"] = 58.8, ["Mulgore"] = 58.8, ["Teldrassil"] = 58.8, ["Darkshore"] = 18, ["Darnassus"] = 18, ["Ironforge"] = 18, ["Orgrimmar"] = 18, ["Stormwind City"] = 18, ["The Barrens"] = 18, ["The Deadmines"] = 18, ["Thunder Bluff"] = 18, ["Westfall"] = 18, ["Wailing Caverns"] = 13, ["Undercity"] = 12.5, ["Stonetalon Mountains"] = 7 } }, -- Raw Brilliant Smallfish
	[6308] = { water = { ["Ashenvale"] = 63.35, ["Duskwood"] = 63.35, ["Hillsbrad Foothills"] = 63.35, ["Redridge Mountains"] = 63.35, ["Stonetalon Mountains"] = 63.35, ["Wetlands"] = 63.35, ["Alterac Mountains"] = 40, ["Arathi Highlands"] = 40, ["Desolace"] = 40, ["Dustwallow Marsh"] = 40, ["Feralas"] = 40, ["Scarlet Monastery"] = 40, ["Stranglethorn Vale"] = 40, ["Swamp of Sorrows"] = 40, ["Thousand Needles"] = 40, ["Darnassus"] = 30, ["Ironforge"] = 30, ["Orgrimmar"] = 30, ["Stormwind City"] = 30, ["The Barrens"] = 30, ["The Deadmines"] = 30, ["Thunder Bluff"] = 30, ["Westfall"] = 30, ["Darkshore"] = 15, ["Undercity"] = 15, ["Wailing Caverns"] = 15 } }, -- Raw Bristle Whisker Catfish
	[13754] = { water = { ["Azshara"] = 15, ["Tanaris"] = 15 } }, -- Raw Glossy Mightfish
	[21153] = { pool = { "Greater Sagefish School", 85 } }, -- Raw Greater Sagefish
	[6317] = { water = { ["Loch Modan"] = 25 } }, -- Raw Loch Frenzy
	[6289] = { water = { ["Darnassus"] = 49.95, ["Ironforge"] = 49.95, ["Orgrimmar"] = 49.95, ["Stormwind City"] = 49.95, ["The Barrens"] = 49.95, ["The Deadmines"] = 49.95, ["Thunder Bluff"] = 49.95, ["Westfall"] = 49.95, ["Dun Morogh"] = 40, ["Durotar"] = 40, ["Elwynn Forest"] = 40, ["Mulgore"] = 40, ["Teldrassil"] = 40, ["Wailing Caverns"] = 40, ["Undercity"] = 39.95, ["Stonetalon Mountains"] = 36, ["Ashenvale"] = 35, ["Darkshore"] = 35, ["Duskwood"] = 35, ["Hillsbrad Foothills"] = 35, ["Redridge Mountains"] = 35, ["Wetlands"] = 35, ["Blackfathom Deeps"] = 30, ["Silverpine Forest"] = 30, ["Tirisfal Glades"] = 30 } }, -- Raw Longjaw Mud Snapper
	[8365] = { water = { ["Alterac Mountains"] = 58.4, ["Arathi Highlands"] = 58.4, ["Desolace"] = 58.4, ["Dustwallow Marsh"] = 58.4, ["Scarlet Monastery"] = 58.4, ["Stranglethorn Vale"] = 58.4, ["Swamp of Sorrows"] = 58.4, ["Thousand Needles"] = 58.4, ["Feralas"] = 58.39, ["Azshara"] = 10, ["Felwood"] = 10, ["Maraudon"] = 10, ["Moonglade"] = 10, ["The Hinterlands"] = 10, ["Un'Goro Crater"] = 10, ["Western Plaguelands"] = 10 } }, -- Raw Mithril Head Trout
	[13759] = { water = { ["Azshara"] = 18, ["Felwood"] = 18, ["Maraudon"] = 18, ["Moonglade"] = 18, ["The Hinterlands"] = 18, ["Un'Goro Crater"] = 18, ["Western Plaguelands"] = 18, ["Burning Steppes"] = 17, ["Eastern Plaguelands"] = 17, ["Feralas"] = 17, ["Scholomance"] = 17, ["Silithus"] = 17, ["Stratholme"] = 17, ["Winterspring"] = 17, ["Zul'Gurub"] = 17 } }, -- Raw Nightfin Snapper
	[13890] = { water = { ["Burning Steppes"] = 17, ["Eastern Plaguelands"] = 17, ["Feralas"] = 17, ["Scholomance"] = 17, ["Silithus"] = 17, ["Stratholme"] = 17, ["Winterspring"] = 17, ["Zul'Gurub"] = 17 } }, -- Raw Plated Armorfish
	[6361] = { water = { ["Ashenvale"] = 58.75, ["Hillsbrad Foothills"] = 58.75, ["Wetlands"] = 58.75, ["Silverpine Forest"] = 50, ["The Barrens"] = 50, ["Westfall"] = 50, ["Darkshore"] = 40 } }, -- Raw Rainbow Fin Albacore
	[13758] = { water = { ["Azshara"] = 35.4, ["Felwood"] = 35.4, ["Maraudon"] = 35.4, ["Moonglade"] = 35.4, ["The Hinterlands"] = 35.4, ["Un'Goro Crater"] = 35.4, ["Western Plaguelands"] = 35.4, ["Burning Steppes"] = 5, ["Eastern Plaguelands"] = 5, ["Feralas"] = 5, ["Scholomance"] = 5, ["Silithus"] = 5, ["Stratholme"] = 5, ["Winterspring"] = 5, ["Zul'Gurub"] = 5 } }, -- Raw Redgill
	[6362] = { water = { ["Arathi Highlands"] = 55.2, ["Desolace"] = 55.2, ["Dustwallow Marsh"] = 55.2, ["Stranglethorn Vale"] = 55.2, ["Swamp of Sorrows"] = 55.2, ["Azshara"] = 10, ["Tanaris"] = 10 } }, -- Raw Rockscale Cod
	[21071] = { pool = { "Sagefish School", 85 } }, -- Raw Sagefish
	[6303] = { water = { ["Durotar"] = 98, ["Teldrassil"] = 98, ["Tirisfal Glades"] = 98, ["Silverpine Forest"] = 33.5, ["The Barrens"] = 33.5, ["Westfall"] = 33.5, ["Darkshore"] = 18.5 } }, -- Raw Slitherskin Mackerel
	[4603] = { water = { ["Azshara"] = 25.3, ["Tanaris"] = 25.3, ["Arathi Highlands"] = 20, ["Desolace"] = 20, ["Dustwallow Marsh"] = 20, ["Stranglethorn Vale"] = 20, ["Swamp of Sorrows"] = 20 } }, -- Raw Spotted Yellowtail
	[13756] = { water = { ["Azshara"] = 30, ["Tanaris"] = 25, ["Feralas"] = 10, ["Stranglethorn Vale"] = 10, ["The Hinterlands"] = 10 } }, -- Raw Summer Bass
	[13760] = { water = { ["Azshara"] = 18, ["Felwood"] = 18, ["Maraudon"] = 18, ["Moonglade"] = 18, ["The Hinterlands"] = 18, ["Un'Goro Crater"] = 18, ["Western Plaguelands"] = 18, ["Burning Steppes"] = 17, ["Eastern Plaguelands"] = 17, ["Feralas"] = 17, ["Scholomance"] = 17, ["Silithus"] = 17, ["Stratholme"] = 17, ["Winterspring"] = 17, ["Zul'Gurub"] = 17 } }, -- Raw Sunscale Salmon
	[13889] = { water = { ["Burning Steppes"] = 30.5, ["Eastern Plaguelands"] = 30.5, ["Feralas"] = 30.5, ["Scholomance"] = 30.5, ["Silithus"] = 30.5, ["Stratholme"] = 30.5, ["Winterspring"] = 30.5, ["Zul'Gurub"] = 30.5 } }, -- Raw Whitescale Salmon
	[13755] = { water = { ["Azshara"] = 10, ["Feralas"] = 10, ["Stranglethorn Vale"] = 10, ["Tanaris"] = 10, ["The Hinterlands"] = 10 } }, -- Raw Winter Squid
	[13918] = { water = { ["Azshara"] = 0.4 } }, -- Reinforced Locked Chest
	[21151] = { pool = { "Floating Wreckage", 20 } }, -- Rumsey Rum Black Label
	[21114] = { pool = { "Floating Wreckage", 20 } }, -- Rumsey Rum Dark
	[20709] = { pool = { "Floating Debris", 20 } }, -- Rumsey Rum Light
	[6357] = { water = { ["Arathi Highlands"] = 0.4, ["Desolace"] = 0.4, ["Dustwallow Marsh"] = 0.4, ["Stranglethorn Vale"] = 0.4, ["Swamp of Sorrows"] = 0.4 } }, -- Sealed Crate
	[6299] = { water = { ["Blackfathom Deeps"] = 15, ["Silverpine Forest"] = 15, ["Tirisfal Glades"] = 15, ["Undercity"] = 15 } }, -- Sickly Looking Fish
	[6353] = { water = { ["Darkshore"] = 0.5, ["Silverpine Forest"] = 0.5, ["The Barrens"] = 0.5, ["Westfall"] = 0.5 } }, -- Small Chest
	[6354] = { water = { ["Ashenvale"] = 0.4, ["Hillsbrad Foothills"] = 0.4, ["Wetlands"] = 0.4 } }, -- Small Locked Chest
	[19807] = { pool = { "School of Tastyfish", 84.6 } }, -- Speckled Tastyfish
	[6360] = { water = { ["Ashenvale"] = 0.05, ["Hillsbrad Foothills"] = 0.05, ["Wetlands"] = 0.05 } }, -- Steelscale Crushfish
	[13422] = { water = { ["Azshara"] = 18, ["Tanaris"] = 15 }, pool = { "Stonescale Eel Swarm", 85 } }, -- Stonescale Eel
	[6355] = { water = { ["Arathi Highlands"] = 0.4, ["Desolace"] = 0.4, ["Dustwallow Marsh"] = 0.4, ["Stranglethorn Vale"] = 0.4, ["Swamp of Sorrows"] = 0.4 } }, -- Sturdy Locked Chest
	[8350] = { water = { ["Darnassus"] = 0.05, ["Ironforge"] = 0.05, ["Orgrimmar"] = 0.05, ["Stormwind City"] = 0.05, ["The Barrens"] = 0.05, ["The Deadmines"] = 0.05, ["Thunder Bluff"] = 0.05, ["Undercity"] = 0.05, ["Westfall"] = 0.05 } }, -- The 1 Ring
	[20708] = { pool = { "Floating Debris", 60 } }, -- Tightly Sealed Trunk
	[6352] = { water = { ["Ashenvale"] = 0.4, ["Hillsbrad Foothills"] = 0.4, ["Wetlands"] = 0.4 } }, -- Waterlogged Crate
	[19975] = { pool = { "Muddy Churning Waters", 100 } }, -- Zulian Mudskunk
}

-- A catch's rarity from its best chance anywhere: tier, percent, place, and whether that's a pool.
local TIERS = {
	{ min = 10, key = "common", label = "Common" },
	{ min = 1, key = "uncommon", label = "Uncommon" },
	{ min = 0.1, key = "rare", label = "Rare" },
	{ min = 0, key = "veryrare", label = "Very rare" },
}

function ns.Rarity(itemID)
	local odds = ns.ODDS[itemID]
	if not odds then
		return nil
	end
	-- On a tie, the zone the collection lists first (most caught there), else by name.
	local order = {}
	local fish = ns.FISH_BY_ID and ns.FISH_BY_ID[itemID]
	for i, zone in ipairs(fish and fish.zones or {}) do
		order[zone] = i
	end
	local function Before(a, b)
		local oa, ob = order[a] or 999, order[b] or 999
		if oa ~= ob then
			return oa < ob
		end
		return a < b
	end
	local best, where, isPool, others = 0, nil, false, 0
	for zone, pct in pairs(odds.water or {}) do
		if pct > best then
			best, where, others = pct, zone, 0
		elseif pct == best then
			others = others + 1
			if Before(zone, where) then
				where = zone
			end
		end
	end
	if odds.pool and odds.pool[2] > best then
		best, where, isPool, others = odds.pool[2], odds.pool[1], true, 0
	end
	for _, tier in ipairs(TIERS) do
		if best >= tier.min then
			return { key = tier.key, label = tier.label, pct = best, where = where, pool = isPool, others = others }
		end
	end
end

-- Where the best odds are: "in Stormwind City and 8 more zones", "from an Oily Blackmouth School".
function ns.RarityWhere(r)
	if r.pool then
		return "from " .. (r.where:match("^[AEIOU]") and "an " or "a ") .. r.where
	end
	return "in " .. r.where .. (r.others > 0 and string.format(" and %d more zone%s", r.others, r.others == 1 and "" or "s") or "")
end

-- Each tier's colour, on dark backgrounds (tooltips) and on the book's parchment.
ns.RARITY_COLOR = { common = "|cffffffff", uncommon = "|cff1eff00", rare = "|cff0070dd", veryrare = "|cffa335ee" }
ns.RARITY_INK = { common = "|cff4f3219", uncommon = "|cff1f6b1f", rare = "|cff0a4f9c", veryrare = "|cff6b2a9c" }

-- "1 in 2,000" for a percent per catch.
function ns.OneIn(pct)
	local n = math.floor(100 / pct + 0.5)
	local s = tostring(n)
	while true do
		local k
		s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return "1 in " .. s
end
