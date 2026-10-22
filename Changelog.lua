-- OneCast's changelog, shown in the What's new window (WhatsNew.lua), newest first.
-- Each release: { version, date, sections = { { heading, { { lead, text }, ... } }, ... } }.
-- Add a new entry at the top for every release, with the same version as the TOC.

local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.0",
		date = "22 October 2026",
		sections = {
			{ "New", {
				{ "One-button fishing.", "Bind one key (or double right-click with a pole on): the first press casts, the next reels in your bobber. Every cast and every reel is still your own press." },
				{ "Your pole, equipped for you.", "With no pole on, the key equips the best one in your bags. Your weapons go back after a break, when combat starts, or with the sword button." },
				{ "Session stats.", "Casts, catches, catch rate, fish per hour and everything you caught, in a window that opens as you cast. Tabs for the session, the zone you're in, lifetime, and a log of recent catches." },
				{ "Is this zone right for you?", "A skill bar shows your Fishing skill, lure bonus included, against the zone's fishing level, so you know whether fish will get away. Zones without data are judged from your own catches." },
				{ "What your catch is worth.", "Vendor and auction value on every tab. Open the auction house and scan your catch with Auctionator in one click." },
				{ "Rare catch alerts.", "A raid-warning flash and sound for anything green or better, or any fish you mark as wanted with a right-click." },
				{ "Wowhead links.", "Click any caught item for its WoW Forever page on Wowhead, ready to copy. Shift-click links it in chat." },
				{ "Hear the splash.", "Sound effects turn up while your line is out; music and ambience are left alone." },
				{ "Make it yours.", "Options in the AddOns settings, a minimap button, and a stats window you can drag, scale and close." },
			} },
		},
	},
}
