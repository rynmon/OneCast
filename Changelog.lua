-- OneCast's changelog, shown in the What's new window (WhatsNew.lua), newest first.
-- Each release: { version, date, sections = { { heading, { { lead, text }, ... } }, ... } }.
-- Add a new entry at the top for every release, with the same version as the TOC.

local _, ns = ...

ns.CHANGELOG = {
	{
		version = "1.0.6",
		date = "21 November 2026",
		sections = {
			{ "New", {
				{ "Luremaster.", "Counts the extra fish from the Legacy tree talent, and warns when your lure runs out." },
				{ "Sort your catch.", "By count, value, latest or name. Opened trunks are worth their contents." },
				{ "Row shading.", "Alternating row backgrounds, Strong by default (Options, Accessibility)." },
			} },
			{ "Changed", {
				{ "A new look.", "Every page redesigned to match, with no parchment outside the collection." },
				{ "Camp page.", "Camp is its own page now, not a tab of the collection." },
				{ "Larger text.", "Scales the whole window, so nothing gets squeezed." },
				{ "Taller window.", "Three more catches show before you scroll." },
				{ "Options.", "Stats and alerts is split into Stats and sessions, and Alerts." },
				{ "Scroll bars.", "Drag them, or click the track to jump." },
			} },
			{ "Fixed", {
				{ "Gear names.", "Gear you've never owned showed as ... in the Gear guide." },
				{ "Cut-off text.", "Long zone and item names are shown in full." },
			} },
			{ "Reported by elegant_curran1390022", {
				{ "Fishing food.", "Shows your Well Fed bonus, eats the best food you have, and reminds you when it wears off." },
			} },
			{ "Reported by festivejelly", {
				{ "Automatic sessions.", "Start a new session after a break, at login, each day, or on Done fishing." },
			} },
		},
	},
	{
		version = "1.0.5",
		date = "20 November 2026",
		sections = {
			{ "Reported by TionTales", {
				{ "Hide the interface while fishing.", "The game's interface fades while your line is out. Off by default." },
			} },
			{ "Reported by lunnati", {
				{ "Bobber marker options.", "Marker style, height and a custom beam colour are back. Set them again once." },
			} },
		},
	},
	{
		version = "1.0.4",
		date = "18 November 2026",
		sections = {
			{ "Fixed", {
				{ "World map card.", "No more repeated errors on continent and world maps." },
			} },
		},
	},
	{
		version = "1.0.3",
		date = "18 November 2026",
		sections = {
			{ "Fixed", {
				{ "Volume message.", "Said once a login instead of on every cast. Thanks to duerrewildstar!" },
			} },
		},
	},
	{
		version = "1.0.2",
		date = "17 November 2026",
		sections = {
			{ "Reported by brisi73", {
				{ "World map card.", "Drag it anywhere, Ctrl + wheel to size it, right-click to reset." },
			} },
		},
	},
	{
		version = "1.0.1",
		date = "17 November 2026",
		sections = {
			{ "New", {
				{ "Open stats with your pole.", "Optional: the stats open whenever you equip a pole." },
				{ "Fishing 300.", "At the cap, the Session tab shows your total skill and what's left to catch." },
				{ "Auction price source.", "Pick Auctionator, TSM or Naowh Forever, or leave it on Automatic." },
			} },
			{ "Changed", {
				{ "Pool tooltips.", "Odds add up properly, and name the trunk and rum each pool gives." },
				{ "Auction worth.", "Items without an auction price count at the vendor's price." },
				{ "Extravaganza fish.", "Keefer's Angelfish, Dezian Queenfish and Speckled Tastyfish confirmed in Forever." },
			} },
			{ "Fixed", {
				{ "Rums.", "Loot after drinking a rum is no longer filed under it." },
				{ "Fishing 300.", "No more advice to train higher at the cap." },
				{ "Dalaran.", "Catches in Dalaran count as City of Dalaran." },
			} },
			{ "Reported by Cyndaria", {
				{ "City of Dalaran needs 225.", "" },
				{ "Missed casts.", "Casts that miss the water no longer count." },
			} },
			{ "Reported by OhhMyGeek", {
				{ "Deviate Scale.", "Added as a Wailing Caverns catch. Stranglethorn's 225 confirmed." },
			} },
			{ "Reported by mooshroomdragon", {
				{ "Deviate Scale in The Barrens.", "Stormwind City's 75 confirmed again." },
			} },
			{ "Reported by jfenn30000", {
				{ "Quest items.", "No longer show as new in the data report." },
			} },
			{ "Reported by more of you", {
				{ "Thank you.", "Tide, SivvyGG, BreadGar, clank0819, user_ylmtyqo58jc23fsc, user_3esotn7e32yjuggw67334 and user_grzw4jp0w7586q7x." },
			} },
		},
	},
	{
		version = "1.0.0",
		date = "16 November 2026",
		sections = {
			{ "New", {
				{ "Choose your cast key.", "A welcome window asks for it. /onecast setup brings it back." },
				{ "Controller support.", "Cast, reel and navigate OneCast with a gamepad, with button icons and rumble." },
				{ "Done fishing.", "Puts your gear back and sums up the session. Thanks to DashiDoshi!" },
				{ "Shirt slot.", "In the fishing wardrobe. Thanks to clank0819!" },
				{ "What was inside.", "Opened trunks and clams count towards your catch." },
				{ "Catch worth.", "Each catch's value, getaways and fish per hour against your best." },
				{ "Fast loot.", "Takes your catch the moment the loot window opens. Off by default." },
				{ "Search.", "Catches, zones, pools, recipes, gear, ranks and settings in one search." },
				{ "Gear guide.", "Every fishing pole and piece of gear, with waypoints to get them." },
				{ "Zones ladder.", "Every zone by Fishing level, with your skill marked on it." },
				{ "Recipe sellers.", "Who sells each fish recipe, with a waypoint to the nearest." },
				{ "Camp, rebuilt.", "Reagents against your bags, blueprint drops and your current buff." },
				{ "Extravaganza prizes.", "What each contest fish and coin trades for." },
				{ "Accessibility.", "Larger text, bigger controller buttons, ticks off, reduced motion." },
				{ "Window settings.", "Choose whether Done fishing and Escape close OneCast." },
			} },
			{ "Changed", {
				{ "Forever's look.", "Follows the game's own interface. Themes removed." },
				{ "Sessions.", "Last until you press Reset." },
				{ "Escape.", "Left to the game unless you turn it on." },
				{ "Wanted list.", "Wanted fish and catch goals are one list." },
				{ "Data report.", "Redesigned in two columns, with no chat messages." },
				{ "Pools on the map.", "Shown with the game's fishing-hole icon." },
				{ "Data checked.", "Against Forever's game data. Outland pools removed." },
				{ "Removed.", "The Catch next row, and uncaught fish in the session list." },
			} },
			{ "Fixed", {
				{ "Closing in combat.", "No more Interface action failed errors." },
				{ "Sound.", "Your volumes come back when your weapons go back on." },
				{ "Game options.", "No more blocked-action errors. Thanks to BreadGar!" },
				{ "Larger text.", "Pages fit." },
				{ "Journey zones.", "Long zone lists no longer run off the card." },
				{ "Mini bar.", "Comes back after a break, and closes with mini mode." },
				{ "Wardrobe total.", "No arrow when you're already wearing the outfit." },
			} },
			{ "Reported by Cyndaria", {
				{ "Desolace needs 225, Stonetalon Mountains 150.", "" },
			} },
		},
	},
	{
		version = "0.9.1a",
		date = "14 November 2026",
		sections = {
			{ "New", {
				{ "Auto loot while fishing.", "On with your pole, off without it. Thanks to JesterClown!" },
			} },
		},
	},
	{
		version = "0.9.0",
		date = "13 November 2026",
		sections = {
			{ "New", {
				{ "Bobber light beam.", "A glowing beam marks your bobber, in a colour you choose." },
				{ "Theme scenery.", "Each theme gets its own scenery, particles and water." },
				{ "Mini mode.", "A small bar in place of the stats while you fish." },
				{ "Skill-ups.", "+1 Fishing on screen, and a Catch next suggestion." },
				{ "Extravaganza help.", "Tastyfish count, time left, and a waypoint to Riggle at 40." },
				{ "Hide tabs.", "Right-click a side tab to hide it." },
				{ "Catch goals.", "Set a target for any catch and track it." },
				{ "Pool tooltips.", "What each pool gives, and what you haven't caught." },
				{ "Fisherman's journey.", "The four Fishing ranks: where to learn them and where to fish." },
				{ "Fishing wardrobe.", "Pick the gear you fish in. It goes on with your pole." },
				{ "Session history.", "Past sessions under All-time records." },
				{ "In reach and junk.", "A filter for reachable fish, a world map strip, and junk selling." },
				{ "New Options page.", "One category at a time, with details on hover." },
				{ "Naowh Forever prices.", "Supported alongside Auctionator and TSM. Thanks to Zycko!" },
				{ "More treasure.", "Three trunks and the Rockhide Strongfish." },
			} },
			{ "Changed", {
				{ "Turn things off.", "Every feature that shows or says something has a setting." },
				{ "Plainer words.", "Zone status says what it means." },
				{ "Data report.", "Flags new items, Blueprint drops and journey finds." },
				{ "Every language.", "Pools, gear bonuses and fishing messages work in all clients." },
				{ "What's new.", "Easier to read, with your version marked." },
			} },
			{ "Fixed", {
				{ "Remembering pools.", "Every pool you hover is marked." },
				{ "Item menu.", "Solid, and wide enough for its text." },
				{ "Speed.", "Faster tooltips and collection." },
			} },
			{ "Reported by DevanHyrax", {
				{ "Fishing Hut Blueprint.", "Reported from Jammal'an the Prophet." },
			} },
			{ "Reported by Roezz", {
				{ "Mithril Bound Trunk.", "Added, with three more missing catches." },
			} },
			{ "Reported by user_hzctcyub5il0ubj3", {
				{ "Zephras Isle needs 25.", "" },
			} },
			{ "Reported by user_wwbl1xmh9xl6rbb7", {
				{ "City of Dalaran.", "Added to the Zones tab." },
			} },
		},
	},
	{
		version = "0.8.2",
		date = "13 November 2026",
		sections = {
			{ "New", {
				{ "Treasure tab.", "Rings, rums, bottles, trunks and chests. Thanks to DevanHyrax!" },
				{ "Roomier fish pages.", "Every zone in two columns, and a bigger map." },
				{ "Catch menu.", "Right-click any catch for everything you can do with it." },
				{ "Wowhead links.", "Right-click anything in the collection for its Wowhead page." },
				{ "Rarity.", "Every catch's odds, from Common to Very rare." },
				{ "Item tooltips.", "Show rarity and which characters caught it." },
			} },
			{ "Fixed", {
				{ "Newer game APIs.", "Lures, recipes, alerts and links use current functions." },
				{ "Data report.", "Fewer false \"level may be lower\" findings." },
			} },
			{ "Reported by user_6zyawui5bf5c0btl", {
				{ "Stormwind City confirmed at 75.", "" },
			} },
		},
	},
	{
		version = "0.8.1",
		date = "12 November 2026",
		sections = {
			{ "New", {
				{ "More fish locations.", "36 fish gained zones from Wowhead's Forever data." },
			} },
			{ "Fixed", {
				{ "Data report.", "Older catches show, and fewer stray messages." },
				{ "Resizing.", "Closing mid-resize stops it." },
			} },
			{ "Reported by bertas88", {
				{ "The Barrens needs 100.", "" },
			} },
			{ "Reported by user_h2k2opfztmgqkcf2", {
				{ "The Barrens confirmed at 100.", "" },
			} },
		},
	},
	{
		version = "0.8.0",
		date = "11 November 2026",
		sections = {
			{ "New", {
				{ "One window.", "Every page in one window, with side tabs." },
				{ "New stats window.", "Session, Spots and All-time records tabs." },
				{ "Forever's Fishing bar.", "With a zone status strip under it." },
				{ "Clearer data report.", "Findings, three steps to share, and the text." },
				{ "Smarter window.", "Badges, auto-close, fading, locking and reopening." },
				{ "Five new themes.", "Booty Bay, Murloc, Winterspring, Deviate and Ember." },
				{ "Options in the window.", "Every setting, without leaving OneCast." },
			} },
		},
	},
	{
		version = "0.7.5",
		date = "11 November 2026",
		sections = {
			{ "Fixed", {
				{ "Pole not going back on.", "After casting from an action bar. Thanks to user_1u9o7vfe00qi4c4k47561!" },
			} },
			{ "Reported by user_ovzr5k4e4heovaq6", {
				{ "Raw Longjaw Mud Snapper in Dun Morogh.", "And Dun Morogh's 25 holds up." },
			} },
			{ "Reported by Falconetti", {
				{ "New locations.", "Mud Snapper in Hillsbrad Foothills, Catfish in Undercity." },
			} },
		},
	},
	{
		version = "0.7.4",
		date = "10 November 2026",
		sections = {
			{ "Reported by pysznyhanys", {
				{ "Raw Sagefish in Silverpine Forest.", "And Orgrimmar confirmed at 75." },
				{ "Thank you!", "OneCast's first data report." },
			} },
		},
	},
	{
		version = "0.7.3",
		date = "10 November 2026",
		sections = {
			{ "Fixed", {
				{ "Login error.", "Camp buff tracking starts again. Thanks to meleegod!" },
			} },
		},
	},
	{
		version = "0.7.2",
		date = "10 November 2026",
		sections = {
			{ "Fixed", {
				{ "Slow servers.", "Pole and weapon swaps finish. Thanks to xDevastation1988x!" },
				{ "Stuck reeling.", "The key casts again after a loading screen." },
				{ "Double lures.", "No second lure spent on a slow server." },
				{ "Item is locked.", "Weapons are asked for once." },
			} },
		},
	},
	{
		version = "0.7.1",
		date = "10 November 2026",
		sections = {
			{ "Fixed", {
				{ "CurseForge links.", "Point to the new address." },
			} },
		},
	},
	{
		version = "0.7.0",
		date = "10 November 2026",
		sections = {
			{ "New", {
				{ "Camp tab.", "Fish Bowl, Fishing Rack and Fishing Hut, with their reagents." },
				{ "Camp buffs.", "Time left, a reminder, and what you catch with them." },
				{ "Data report.", "/onecast report, to help find Forever's real zone levels." },
				{ "Data alerts.", "Says when you find something OneCast doesn't know." },
			} },
			{ "Quality of life", {
				{ "Minimap menu.", "Every OneCast window in one place." },
				{ "Spots on the map.", "Click a spot for a waypoint." },
				{ "Tooltips everywhere.", "Recipes, fish and camp items, Shift-click to link." },
				{ "Maps from the book.", "Right-click a zone for its map." },
				{ "Windows remember.", "Every window opens where you left it." },
				{ "Chat links.", "Lures, Tastyfish and buffs in chat are links." },
			} },
			{ "Fixed", {
				{ "Riverglades needs 225.", "Forever's first measured level." },
				{ "Getaways.", "Counted in Forever, in any language." },
				{ "Options.", "Opening and closing them leaves your windows alone." },
				{ "Dungeons.", "Recognised by map, whatever the name." },
				{ "Common fish.", "More locations from players' reports." },
			} },
		},
	},
	{
		version = "0.6.1",
		date = "10 November 2026",
		sections = {
			{ "Fixed", {
				{ "Zone levels.", "Corrected for high-level zones and capitals." },
				{ "Fish locations.", "Zulian Mudskunk and Deviate Fish only where they're caught." },
				{ "Zul'Gurub's pool.", "Remembered on the maps." },
				{ "Weapons.", "Says so when one won't go back on." },
				{ "Commands.", "No longer react to similar words." },
			} },
			{ "New", {
				{ "Dungeons and lakes.", "Fishing levels for dungeons and lakes with their own." },
				{ "Three more catches.", "Crushfish, Grouper and Oil Covered Fish." },
				{ "\"Secret\" Bait.", "Forever's new +25 lure." },
				{ "Zephras Isle.", "On the Zones tab." },
			} },
		},
	},
	{
		version = "0.6.0",
		date = "9 November 2026",
		sections = {
			{ "New", {
				{ "Themes.", "Pick a look for OneCast's windows." },
			} },
			{ "Changed", {
				{ "Options menu.", "Grouped into short pages." },
			} },
		},
	},
	{
		version = "0.5.2",
		date = "8 November 2026",
		sections = {
			{ "Fixed", {
				{ "Options search.", "No more errors. Thanks to onkl for the report and the fix!" },
			} },
		},
	},
	{
		version = "0.5.1",
		date = "8 November 2026",
		sections = {
			{ "New", {
				{ "Mark your bobber.", "The gear icon over your bobber. Thanks to insertnamehere255!" },
			} },
			{ "Fixed", {
				{ "Other languages.", "Zone data works on non-English clients." },
				{ "Lures.", "Reeling in no longer counts as a failed lure." },
				{ "Weapons.", "Go back on after a fight." },
				{ "Your pole.", "The one you used last stays picked." },
				{ "Extravaganza.", "Turning reminders off stops the warning too." },
				{ "Stats window.", "Lighter on your computer." },
				{ "Options.", "Closing them leaves your windows open." },
				{ "Combat.", "Reels in a line left out after a fight." },
				{ "Poles.", "Moves on from one the game won't equip." },
				{ "Fish page fonts.", "Headings stay headings." },
			} },
		},
	},
	{
		version = "0.5.0",
		date = "7 November 2026",
		sections = {
			{ "New", {
				{ "Tackle box.", "Your lure, its count and time left. Thanks to raffle0!" },
				{ "Choose your lure.", "Per character, never swapped for another." },
				{ "Apply with the cast key.", "Optional: the key applies your lure first." },
				{ "Remembered pools.", "Marked on the collection's maps." },
				{ "Bags full warning.", "When you cast with no space." },
				{ "Low on lures.", "A note at vendors selling yours." },
				{ "Lure stats.", "Fish per hour with and without one." },
				{ "Key bindings.", "Apply lure and Tackle box." },
			} },
			{ "Changed", {
				{ "Lure hints.", "Names a lure that would cover a zone." },
				{ "Getaways.", "Recorded with your skill." },
				{ "Options.", "Grouped into sections." },
			} },
		},
	},
	{
		version = "0.4.0",
		date = "7 November 2026",
		sections = {
			{ "New", {
				{ "Zones tab.", "Every zone's Fishing level. Thanks to Lintence!" },
				{ "Zone filter levels.", "Each zone's level in the menu." },
			} },
		},
	},
	{
		version = "0.3.1",
		date = "6 November 2026",
		sections = {
			{ "New", {
				{ "Quiet other sounds.", "Turns music and ambience down while fishing. Thanks to paxcow55!" },
			} },
		},
	},
	{
		version = "0.3.0",
		date = "5 November 2026",
		sections = {
			{ "New", {
				{ "Skill-ups.", "Skill gained, and catches to the next point." },
				{ "Session summary.", "In chat after a 2-minute break." },
				{ "Best spots.", "Compare spots by fish per hour." },
				{ "Time of day.", "When you caught each fish." },
				{ "Find any fish.", "Zone filter and search in the collection." },
				{ "Fishing Extravaganza.", "Countdown, Tastyfish counter and reminders." },
				{ "Auto loot.", "Offers to turn it on." },
			} },
			{ "Changed", {
				{ "Auction scan.", "Moved to the stats window and /onecast scan." },
				{ "Lifetime tab.", "Shows your collection progress." },
			} },
		},
	},
	{
		version = "0.2.1",
		date = "5 November 2026",
		sections = {
			{ "Updated for launch", {
				{ "88 catches.", "Checked against Forever's launch build." },
				{ "Data sources.", "Classic and reported zones are marked." },
				{ "Maps.", "Fully revealed on fish pages." },
				{ "Riverglades.", "Real getaways trusted over the bug report." },
			} },
			{ "Fixed", {
				{ "Weapons.", "No longer stuck after levelling up." },
				{ "Loading screens.", "Casts don't count under a blank zone." },
				{ "What's new.", "The version list scrolls." },
			} },
		},
	},
	{
		version = "0.2.0",
		date = "23 October 2026",
		sections = {
			{ "New", {
				{ "Fishing collection.", "A book of every fish in WoW Forever." },
				{ "Fish pages.", "Description, your catches and when you first caught it." },
				{ "Where to catch it.", "Zones, skill needed and a map." },
				{ "Recipes.", "What each fish is used in." },
				{ "Account-wide.", "Counts every character." },
				{ "New fish alerts.", "When you catch one for the first time." },
			} },
			{ "How to open it", {
				{ "Anywhere.", "Stats window, minimap, options, key binding or /onecast book." },
			} },
		},
	},
	{
		version = "0.1.0",
		date = "22 October 2026",
		sections = {
			{ "New", {
				{ "One-button fishing.", "One key casts and reels in." },
				{ "Pole equipped for you.", "Your weapons go back afterwards." },
				{ "Session stats.", "Catches, rate, fish per hour and more." },
				{ "Zone check.", "Your skill against the zone's level." },
				{ "Catch value.", "Vendor and auction prices." },
				{ "Rare catch alerts.", "For anything green or better, or wanted." },
				{ "Wowhead links.", "For any caught item." },
				{ "Hear the splash.", "Sound turned up while your line is out." },
				{ "Options.", "A minimap button and a movable window." },
			} },
		},
	},
}
