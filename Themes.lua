-- OneCast themes: recolours of every OneCast window, chosen in the options.
--
-- A window's Blizzard frames are made of textures, which take a tint without being replaced,
-- so a theme is just this file's table of colours. Windows register what should be tinted and
-- listen for changes to redraw their text. Forever is the game's own look: with it chosen from
-- the start, nothing here ever touches a texture.

local _, ns = ...

local Theme = {}
ns.Theme = Theme

Theme.DEFAULT = "forever"
Theme.ORDER = { "forever", "dark", "tidal", "abyss", "golden", "marsh", "moonlit", "lodge",
	"bootybay", "murloc", "winterspring", "deviate", "ember", "ashenvale", "darkshore", "azshara",
	"durotar", "silverpine", "hillsbrad", "stormsong", "zuldazar", "voldun", "drustvar", "suramar",
	"shadowmoon", "fel", "mechagon", "bastion", "revendreth", "ardenweald", "alliance", "horde",
	"class" }

-- frame, inset, header and button tint those parts of a window, and parchment the book's pages.
-- ink is text on the pages, inkSoft quieter text, and lead, soft, good and bad are text colours.
-- A theme with no tints leaves the game's own art alone. grain lays a tiled texture behind a
-- window, and fromClass takes the tints from the character being played.
Theme.LIST = {
	forever = {
		id = "forever",
		label = "Forever",
		ink = { 0.18, 0.10, 0.02 },
		inkSoft = { 0.36, 0.25, 0.14 },
		lead = "|cff7a2a00",
		soft = "|cff6b5233",
		good = "|cff1f6b1f",
		bad = "|cffa01c1c",
	},
	dark = {
		id = "dark",
		label = "Dark",
		frame = { 0.42, 0.43, 0.47 },
		inset = { 0.55, 0.56, 0.60 },
		header = { 0.55, 0.56, 0.62 },
		button = { 0.50, 0.51, 0.56 },
		parchment = { 0.24, 0.25, 0.29 },
		ink = { 0.93, 0.92, 0.88 },
		inkSoft = { 0.68, 0.67, 0.63 },
		lead = "|cffe6b85c",
		soft = "|cffa9a89f",
		good = "|cff62d862",
		bad = "|cffff7466",
	},
	tidal = {
		id = "tidal",
		label = "Tidal",
		frame = { 0.34, 0.58, 0.74 },
		inset = { 0.42, 0.62, 0.76 },
		header = { 0.40, 0.68, 0.86 },
		button = { 0.30, 0.56, 0.78 },
		parchment = { 0.62, 0.82, 0.92 },
		ink = { 0.03, 0.11, 0.20 },
		inkSoft = { 0.11, 0.26, 0.38 },
		lead = "|cff0a4f7a",
		soft = "|cff2a566f",
		good = "|cff0a5730",
		bad = "|cffa01a2c",
	},
	abyss = {
		id = "abyss",
		label = "Abyss",
		frame = { 0.20, 0.30, 0.40 },
		inset = { 0.30, 0.42, 0.50 },
		header = { 0.26, 0.48, 0.56 },
		button = { 0.24, 0.42, 0.52 },
		parchment = { 0.11, 0.20, 0.27 },
		ink = { 0.82, 0.95, 0.96 },
		inkSoft = { 0.55, 0.74, 0.78 },
		lead = "|cff5fdcd6",
		soft = "|cff8fb8bd",
		good = "|cff67e08a",
		bad = "|cffff8478",
	},
	golden = {
		id = "golden",
		label = "Golden Hour",
		frame = { 0.85, 0.55, 0.25 },
		inset = { 0.88, 0.64, 0.36 },
		header = { 0.95, 0.62, 0.25 },
		button = { 0.85, 0.50, 0.22 },
		parchment = { 1.00, 0.80, 0.58 },
		ink = { 0.25, 0.11, 0.03 },
		inkSoft = { 0.43, 0.24, 0.10 },
		lead = "|cff8f3a00",
		soft = "|cff6f4522",
		good = "|cff1a5c1a",
		bad = "|cff9c1414",
	},
	marsh = {
		id = "marsh",
		label = "Marsh",
		frame = { 0.36, 0.50, 0.28 },
		inset = { 0.44, 0.56, 0.34 },
		header = { 0.46, 0.62, 0.34 },
		button = { 0.40, 0.54, 0.28 },
		parchment = { 0.76, 0.86, 0.62 },
		ink = { 0.09, 0.17, 0.06 },
		inkSoft = { 0.24, 0.33, 0.16 },
		lead = "|cff3f5a10",
		soft = "|cff465a30",
		good = "|cff0b5f2a",
		bad = "|cff9a1a1a",
	},
	moonlit = {
		id = "moonlit",
		label = "Moonlit",
		frame = { 0.46, 0.44, 0.66 },
		inset = { 0.54, 0.52, 0.72 },
		header = { 0.58, 0.54, 0.78 },
		button = { 0.50, 0.47, 0.72 },
		parchment = { 0.26, 0.23, 0.38 },
		ink = { 0.94, 0.93, 0.98 },
		inkSoft = { 0.73, 0.71, 0.82 },
		lead = "|cffd9c7ff",
		soft = "|cffaaa5c4",
		good = "|cff7fe0a0",
		bad = "|cffff8a8a",
	},
	lodge = {
		id = "lodge",
		label = "Fisherman's Lodge",
		frame = { 0.62, 0.42, 0.24 },
		inset = { 0.60, 0.44, 0.28 },
		header = { 0.70, 0.46, 0.22 },
		button = { 0.66, 0.44, 0.24 },
		parchment = { 0.84, 0.68, 0.46 },
		grain = "Interface\\BlackMarket\\BlackMarketBackground-Tile",
		grainTint = { 0.95, 0.78, 0.60 },
		ink = { 0.20, 0.10, 0.03 },
		inkSoft = { 0.36, 0.22, 0.10 },
		lead = "|cff6e2f08",
		soft = "|cff4f3219",
		good = "|cff124a16",
		bad = "|cff7f1410",
	},
	-- The pirate port that hosts the Stranglethorn Fishing Extravaganza: sea-worn verdigris and
	-- sun-bleached sand, with coral-red highlights.
	bootybay = {
		id = "bootybay",
		label = "Booty Bay",
		frame = { 0.32, 0.56, 0.50 },
		inset = { 0.40, 0.60, 0.54 },
		header = { 0.36, 0.64, 0.56 },
		button = { 0.34, 0.56, 0.50 },
		parchment = { 0.96, 0.86, 0.66 },
		ink = { 0.16, 0.10, 0.05 },
		inkSoft = { 0.34, 0.24, 0.14 },
		lead = "|cffa0301c",
		soft = "|cff5c4a32",
		good = "|cff1d5e2c",
		bad = "|cff9e1b1b",
	},
	-- Azeroth's most famous fishermen. Mrglglgl! Bright aqua-green, sea foam and an orange fin.
	murloc = {
		id = "murloc",
		label = "Murloc",
		frame = { 0.22, 0.66, 0.56 },
		inset = { 0.30, 0.70, 0.60 },
		header = { 0.26, 0.76, 0.62 },
		button = { 0.24, 0.66, 0.54 },
		parchment = { 0.80, 0.97, 0.90 },
		ink = { 0.03, 0.17, 0.13 },
		inkSoft = { 0.14, 0.31, 0.26 },
		lead = "|cffa8400a",
		soft = "|cff2e5a4e",
		good = "|cff0b5a2a",
		bad = "|cffa01c24",
	},
	-- The frozen lakes of Winterspring: frosted silver-blue and icy white, in deep navy ink.
	winterspring = {
		id = "winterspring",
		label = "Winterspring",
		frame = { 0.70, 0.80, 0.92 },
		inset = { 0.76, 0.84, 0.94 },
		header = { 0.72, 0.84, 0.98 },
		button = { 0.66, 0.76, 0.90 },
		parchment = { 0.92, 0.96, 1.00 },
		ink = { 0.04, 0.09, 0.22 },
		inkSoft = { 0.18, 0.25, 0.40 },
		lead = "|cff2a4f9c",
		soft = "|cff3f5270",
		good = "|cff0e5a3a",
		bad = "|cffa01c30",
	},
	-- The Wailing Caverns' Deviate Fish: purple scales and a toxic green glow.
	deviate = {
		id = "deviate",
		label = "Deviate",
		frame = { 0.52, 0.34, 0.62 },
		inset = { 0.58, 0.42, 0.66 },
		header = { 0.60, 0.38, 0.72 },
		button = { 0.52, 0.34, 0.64 },
		parchment = { 0.88, 0.82, 0.94 },
		ink = { 0.15, 0.06, 0.20 },
		inkSoft = { 0.32, 0.20, 0.38 },
		lead = "|cff1d5208",
		soft = "|cff5a4466",
		good = "|cff17602a",
		bad = "|cffa01c3c",
	},
	-- Un'Goro's hot springs and Fireplume Ridge: charcoal and ember-lit headers over smouldering
	-- pages, in light ink.
	ember = {
		id = "ember",
		label = "Ember",
		frame = { 0.40, 0.30, 0.27 },
		inset = { 0.46, 0.34, 0.30 },
		header = { 0.88, 0.42, 0.18 },
		button = { 0.70, 0.34, 0.18 },
		parchment = { 0.26, 0.17, 0.13 },
		ink = { 0.97, 0.90, 0.80 },
		inkSoft = { 0.80, 0.69, 0.58 },
		lead = "|cffff9a40",
		soft = "|cffc4a088",
		good = "|cff86df6a",
		bad = "|cffff7a6a",
	},
	-- Ashenvale's night forest: deep teal under the canopy, with fireflies.
	ashenvale = {
		id = "ashenvale",
		label = "Ashenvale",
		frame = { 0.30, 0.42, 0.40 },
		inset = { 0.36, 0.48, 0.46 },
		header = { 0.34, 0.56, 0.52 },
		button = { 0.30, 0.48, 0.46 },
		parchment = { 0.16, 0.24, 0.24 },
		ink = { 0.86, 0.96, 0.92 },
		inkSoft = { 0.60, 0.74, 0.70 },
		lead = "|cff7fe8c8",
		soft = "|cff9fbcb4",
		good = "|cff7fe08a",
		bad = "|cffff8a80",
	},
	-- Darkshore's misty coast: moon-silver blues, with bubbles rising.
	darkshore = {
		id = "darkshore",
		label = "Darkshore",
		frame = { 0.42, 0.46, 0.56 },
		inset = { 0.48, 0.52, 0.62 },
		header = { 0.50, 0.58, 0.72 },
		button = { 0.44, 0.50, 0.64 },
		parchment = { 0.78, 0.82, 0.90 },
		ink = { 0.06, 0.09, 0.18 },
		inkSoft = { 0.22, 0.27, 0.38 },
		lead = "|cff2b4a8a",
		soft = "|cff445066",
		good = "|cff1a5c34",
		bad = "|cff9c1c2c",
	},
	-- Azshara's endless autumn: crimson and orange, with leaves falling.
	azshara = {
		id = "azshara",
		label = "Azshara",
		frame = { 0.70, 0.36, 0.30 },
		inset = { 0.74, 0.44, 0.36 },
		header = { 0.86, 0.42, 0.30 },
		button = { 0.74, 0.36, 0.28 },
		parchment = { 0.98, 0.82, 0.66 },
		ink = { 0.28, 0.08, 0.04 },
		inkSoft = { 0.46, 0.24, 0.16 },
		lead = "|cff9a2c10",
		soft = "|cff6e4430",
		good = "|cff1f5c1f",
		bad = "|cffa01414",
	},
	-- Durotar's red rock and dust, by the shore of Razor Hill.
	durotar = {
		id = "durotar",
		label = "Durotar",
		frame = { 0.62, 0.36, 0.24 },
		inset = { 0.66, 0.42, 0.30 },
		header = { 0.78, 0.38, 0.20 },
		button = { 0.66, 0.34, 0.20 },
		parchment = { 0.92, 0.76, 0.56 },
		ink = { 0.24, 0.09, 0.03 },
		inkSoft = { 0.42, 0.24, 0.12 },
		lead = "|cff8f2a08",
		soft = "|cff694028",
		good = "|cff2a5a14",
		bad = "|cff9a1010",
	},
	-- Silverpine Forest: grey-green gloom and steady rain.
	silverpine = {
		id = "silverpine",
		label = "Silverpine",
		frame = { 0.38, 0.42, 0.38 },
		inset = { 0.44, 0.48, 0.44 },
		header = { 0.46, 0.54, 0.46 },
		button = { 0.40, 0.46, 0.40 },
		parchment = { 0.20, 0.23, 0.21 },
		ink = { 0.86, 0.90, 0.86 },
		inkSoft = { 0.62, 0.68, 0.62 },
		lead = "|cffb8d8a0",
		soft = "|cff9aa898",
		good = "|cff7fd88a",
		bad = "|cffff8070",
	},
	-- Hillsbrad's meadows: soft greens and gold, with pollen drifting.
	hillsbrad = {
		id = "hillsbrad",
		label = "Hillsbrad",
		frame = { 0.52, 0.58, 0.32 },
		inset = { 0.58, 0.62, 0.38 },
		header = { 0.64, 0.70, 0.34 },
		button = { 0.54, 0.60, 0.30 },
		parchment = { 0.94, 0.92, 0.70 },
		ink = { 0.14, 0.16, 0.04 },
		inkSoft = { 0.32, 0.34, 0.16 },
		lead = "|cff4a6010",
		soft = "|cff55583a",
		good = "|cff17602a",
		bad = "|cff9a1a1a",
	},
	-- Stormsong Valley: sea-green and slate, under a passing storm.
	stormsong = {
		id = "stormsong",
		label = "Stormsong",
		frame = { 0.30, 0.44, 0.44 },
		inset = { 0.36, 0.50, 0.50 },
		header = { 0.34, 0.56, 0.58 },
		button = { 0.30, 0.48, 0.50 },
		parchment = { 0.70, 0.82, 0.80 },
		ink = { 0.04, 0.14, 0.14 },
		inkSoft = { 0.18, 0.30, 0.30 },
		lead = "|cff0e5a5a",
		soft = "|cff36504e",
		good = "|cff0e5a2a",
		bad = "|cffa01a24",
	},
	-- Zuldazar's jungle temples: teal stone and gold, glinting.
	zuldazar = {
		id = "zuldazar",
		label = "Zuldazar",
		frame = { 0.30, 0.54, 0.46 },
		inset = { 0.36, 0.58, 0.50 },
		header = { 0.90, 0.70, 0.26 },
		button = { 0.80, 0.60, 0.24 },
		parchment = { 0.98, 0.90, 0.66 },
		ink = { 0.18, 0.12, 0.02 },
		inkSoft = { 0.38, 0.28, 0.12 },
		lead = "|cff0a6a5a",
		soft = "|cff5a4a2a",
		good = "|cff1a5e22",
		bad = "|cffa01818",
	},
	-- Vol'dun's dunes: sun-baked sand, with grains on the wind.
	voldun = {
		id = "voldun",
		label = "Vol'dun",
		frame = { 0.78, 0.64, 0.42 },
		inset = { 0.82, 0.70, 0.48 },
		header = { 0.88, 0.70, 0.40 },
		button = { 0.80, 0.62, 0.36 },
		parchment = { 1.00, 0.90, 0.70 },
		ink = { 0.26, 0.16, 0.06 },
		inkSoft = { 0.44, 0.32, 0.18 },
		lead = "|cff8a4a10",
		soft = "|cff6a5434",
		good = "|cff2a5a14",
		bad = "|cff9a1a10",
	},
	-- Drustvar's witch-wood at dusk: bruised purples and wisps.
	drustvar = {
		id = "drustvar",
		label = "Drustvar",
		frame = { 0.40, 0.32, 0.36 },
		inset = { 0.46, 0.38, 0.40 },
		header = { 0.56, 0.36, 0.46 },
		button = { 0.48, 0.32, 0.40 },
		parchment = { 0.22, 0.17, 0.19 },
		ink = { 0.94, 0.88, 0.90 },
		inkSoft = { 0.72, 0.62, 0.66 },
		lead = "|cffe8a0c8",
		soft = "|cffb09aa4",
		good = "|cff8ad88a",
		bad = "|cffff7a7a",
	},
	-- Suramar's nightborne city: violet and magenta, with arcane motes.
	suramar = {
		id = "suramar",
		label = "Suramar",
		frame = { 0.40, 0.32, 0.58 },
		inset = { 0.46, 0.38, 0.64 },
		header = { 0.62, 0.40, 0.80 },
		button = { 0.50, 0.34, 0.70 },
		parchment = { 0.20, 0.15, 0.30 },
		ink = { 0.96, 0.92, 1.00 },
		inkSoft = { 0.76, 0.70, 0.86 },
		lead = "|cffe0a8ff",
		soft = "|cffb0a0c8",
		good = "|cff8ae0b0",
		bad = "|cffff8aa0",
	},
	-- Shadowmoon Valley: deep violet night, full of stars.
	shadowmoon = {
		id = "shadowmoon",
		label = "Shadowmoon",
		frame = { 0.26, 0.24, 0.42 },
		inset = { 0.32, 0.30, 0.48 },
		header = { 0.40, 0.36, 0.62 },
		button = { 0.34, 0.30, 0.54 },
		parchment = { 0.12, 0.11, 0.20 },
		ink = { 0.90, 0.90, 1.00 },
		inkSoft = { 0.66, 0.66, 0.82 },
		lead = "|cffb8b0ff",
		soft = "|cff9a98c0",
		good = "|cff80e0a8",
		bad = "|cffff8a90",
	},
	-- Tanaan's fel-soaked jungle: sickly green fire, embers rising.
	fel = {
		id = "fel",
		label = "Fel",
		frame = { 0.28, 0.40, 0.20 },
		inset = { 0.32, 0.44, 0.24 },
		header = { 0.50, 0.80, 0.20 },
		button = { 0.40, 0.66, 0.16 },
		parchment = { 0.14, 0.18, 0.10 },
		ink = { 0.90, 1.00, 0.84 },
		inkSoft = { 0.66, 0.78, 0.60 },
		lead = "|cffa0ff40",
		soft = "|cff9ab088",
		good = "|cff80ff80",
		bad = "|cffff7060",
	},
	-- Mechagon: brushed steel and copper, with sparks.
	mechagon = {
		id = "mechagon",
		label = "Mechagon",
		frame = { 0.46, 0.48, 0.50 },
		inset = { 0.52, 0.54, 0.56 },
		header = { 0.78, 0.52, 0.30 },
		button = { 0.70, 0.46, 0.26 },
		parchment = { 0.82, 0.82, 0.80 },
		ink = { 0.10, 0.11, 0.12 },
		inkSoft = { 0.30, 0.31, 0.33 },
		lead = "|cff8a4010",
		soft = "|cff4a4c50",
		good = "|cff1a5c2a",
		bad = "|cffa01818",
	},
	-- Bastion's bright heavens: white marble and gold.
	bastion = {
		id = "bastion",
		label = "Bastion",
		frame = { 0.82, 0.80, 0.74 },
		inset = { 0.88, 0.86, 0.80 },
		header = { 0.92, 0.80, 0.50 },
		button = { 0.86, 0.76, 0.50 },
		parchment = { 1.00, 0.98, 0.92 },
		ink = { 0.18, 0.14, 0.06 },
		inkSoft = { 0.38, 0.34, 0.24 },
		lead = "|cff8a6a10",
		soft = "|cff5a5440",
		good = "|cff1a5c2a",
		bad = "|cff9a1a1a",
	},
	-- Revendreth's gothic halls: crimson and shadow.
	revendreth = {
		id = "revendreth",
		label = "Revendreth",
		frame = { 0.42, 0.22, 0.24 },
		inset = { 0.48, 0.26, 0.28 },
		header = { 0.72, 0.20, 0.24 },
		button = { 0.60, 0.18, 0.22 },
		parchment = { 0.20, 0.10, 0.11 },
		ink = { 0.98, 0.88, 0.86 },
		inkSoft = { 0.78, 0.64, 0.62 },
		lead = "|cffff7070",
		soft = "|cffc09a98",
		good = "|cff86df6a",
		bad = "|cffff6a6a",
	},
	-- Ardenweald's twilight grove: dusk blue, with faerie lights.
	ardenweald = {
		id = "ardenweald",
		label = "Ardenweald",
		frame = { 0.24, 0.30, 0.50 },
		inset = { 0.30, 0.36, 0.56 },
		header = { 0.36, 0.50, 0.80 },
		button = { 0.30, 0.42, 0.70 },
		parchment = { 0.13, 0.16, 0.28 },
		ink = { 0.88, 0.94, 1.00 },
		inkSoft = { 0.64, 0.72, 0.86 },
		lead = "|cff90c8ff",
		soft = "|cff98a8c4",
		good = "|cff8ae0b0",
		bad = "|cffff8a90",
	},
	-- The Alliance: Stormwind blue and gold.
	alliance = {
		id = "alliance",
		label = "Alliance",
		frame = { 0.32, 0.40, 0.66 },
		inset = { 0.38, 0.46, 0.70 },
		header = { 0.90, 0.74, 0.30 },
		button = { 0.34, 0.44, 0.76 },
		parchment = { 0.96, 0.92, 0.80 },
		ink = { 0.06, 0.10, 0.24 },
		inkSoft = { 0.24, 0.28, 0.40 },
		lead = "|cff1a3a8a",
		soft = "|cff40486a",
		good = "|cff1a5c2a",
		bad = "|cff9a1a1a",
	},
	-- The Horde: Orgrimmar's iron, red and black.
	horde = {
		id = "horde",
		label = "Horde",
		frame = { 0.40, 0.22, 0.18 },
		inset = { 0.46, 0.28, 0.22 },
		header = { 0.78, 0.22, 0.14 },
		button = { 0.66, 0.20, 0.14 },
		parchment = { 0.90, 0.78, 0.62 },
		ink = { 0.24, 0.06, 0.02 },
		inkSoft = { 0.42, 0.22, 0.14 },
		lead = "|cff8f1a08",
		soft = "|cff683828",
		good = "|cff2a5a14",
		bad = "|cff9a1010",
	},
	class = {
		id = "class",
		label = "Class Colours",
		fromClass = true,
		parchment = { 0.24, 0.25, 0.29 },
		ink = { 0.93, 0.92, 0.88 },
		inkSoft = { 0.68, 0.67, 0.63 },
		lead = "|cffe6b85c",
		soft = "|cffa9a89f",
		good = "|cff62d862",
		bad = "|cffff7466",
	},
}

local entries = {}   -- what's been registered: { object, role, skip }
local listeners = {}
local originals = setmetatable({}, { __mode = "k" }) -- how a texture looked before any tint
local grainOwners = {} -- windows and insets that can show a theme's grain
local grainOf = setmetatable({}, { __mode = "k" })  -- owner -> its grain texture
local isGrain = setmetatable({}, { __mode = "k" })  -- grain textures, which are never tinted
local tinted = false -- a theme has been applied this session, so there's art to restore

-- Full class colours are too loud across a whole window, Priest white and Rogue yellow above
-- all, so they're mixed with grey and dimmed. The pages stay neutral so text reads the same.
local function FillClassTints(theme)
	local _, classFile = UnitClass("player")
	local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	if not color then
		return
	end
	local function Tint(strength)
		local function Part(value)
			return (value * 0.65 + 0.45 * 0.35) * strength
		end
		return { Part(color.r), Part(color.g), Part(color.b) }
	end
	theme.frame, theme.inset, theme.header, theme.button = Tint(0.75), Tint(0.85), Tint(0.90), Tint(0.85)
	local function Light(value)
		return math.floor((value * 0.75 + 0.25) * 255 + 0.5)
	end
	theme.lead = string.format("|cff%02x%02x%02x", Light(color.r), Light(color.g), Light(color.b))
end

function Theme.Current()
	local theme = Theme.LIST[ns.db and ns.db.theme] or Theme.LIST[Theme.DEFAULT]
	if theme.fromClass and not theme.frame then
		FillClassTints(theme)
	end
	return theme
end

local function TintTexture(texture, color)
	if color then
		if not originals[texture] then
			local r, g, b, a = texture:GetVertexColor()
			originals[texture] = { r or 1, g or 1, b or 1, a or 1, texture:IsDesaturated() }
		end
		texture:SetDesaturated(true)
		texture:SetVertexColor(color[1], color[2], color[3])
	else
		local original = originals[texture]
		if original then
			texture:SetVertexColor(original[1], original[2], original[3], original[4])
			texture:SetDesaturated(original[5])
		end
	end
end

local function IsPlainTexture(region)
	return region.GetObjectType and region:GetObjectType() == "Texture"
end

local function TintRegions(frame, color, skip)
	for _, region in ipairs({ frame:GetRegions() }) do
		if IsPlainTexture(region) and not isGrain[region] and not (skip and skip[region]) then
			TintTexture(region, color)
		end
	end
end

local function ApplyEntry(entry, theme)
	local object, color = entry.object, theme[entry.role]
	if IsPlainTexture(object) then
		TintTexture(object, color)
	else
		TintRegions(object, color, entry.skip)
		if object.NineSlice then
			TintRegions(object.NineSlice, color)
		end
	end
end

-- The grain is its own texture above the owner's background, so swapping themes only shows or
-- hides it and the game's art is never replaced. It's made the first time a theme needs it.
local function ApplyGrain(owner, theme)
	local grain = grainOf[owner]
	if not theme.grain then
		if grain then
			grain:Hide()
		end
		return
	end
	if not grain then
		grain = owner:CreateTexture(nil, "BACKGROUND", nil, 7)
		grain:SetPoint("TOPLEFT", 3, -3)
		grain:SetPoint("BOTTOMRIGHT", -3, 3)
		grainOf[owner], isGrain[grain] = grain, true
	end
	grain:SetTexture(theme.grain, "REPEAT", "REPEAT")
	grain:SetHorizTile(true)
	grain:SetVertTile(true)
	grain:SetVertexColor(theme.grainTint[1], theme.grainTint[2], theme.grainTint[3])
	grain:Show()
end

-- Tint this texture, or a frame's textures and its border, in the given role. `skip` is a set
-- of textures to leave alone, such as a button's icon.
function Theme.Register(object, role, skip)
	local entry = { object = object, role = role, skip = skip }
	entries[#entries + 1] = entry
	if tinted then
		ApplyEntry(entry, Theme.Current())
	end
end

local function AddSurface(owner, role)
	Theme.Register(owner, role)
	grainOwners[#grainOwners + 1] = owner
	if tinted then
		ApplyGrain(owner, Theme.Current())
	end
end

-- Scenes -----------------------------------------------------------------------------------
-- What makes a theme a place rather than a palette: a landscape along the foot of each window
-- (the game's own garrison mission scenery, faded into the background), particles drifting
-- over it, an emblem in the window's title bar, and its own water in the Fishing bar. Every
-- piece is the game's art, checked for at runtime, and the "Theme effects" option can keep the
-- scenery still or turn the lot off.
--
-- vista: a scenery name (its -Back, -Mid and -Fore layers). motes: kind ("up", "down",
-- "wander"), count, colour, size, speed, sway, alpha, twinkle, star (glint texture).
-- emblem: an item whose icon badges the portrait. water: the bar's flipbook profession and tint.
Theme.SCENES = {
	dark = { vista = "Underground", emblem = 13757,
		motes = { kind = "up", count = 8, color = { 0.8, 0.8, 0.85 }, size = { 2, 3 }, speed = { 4, 9 }, sway = 6, alpha = 0.25 } },
	tidal = { vista = "NagrandSea", emblem = 4603,
		motes = { kind = "up", count = 14, color = { 0.65, 0.9, 1 }, size = { 2, 5 }, speed = { 10, 22 }, sway = 8, alpha = 0.35 } },
	abyss = { vista = "Nazjatar", emblem = 13888,
		motes = { kind = "up", count = 16, color = { 0.4, 1, 0.95 }, size = { 2, 4 }, speed = { 6, 14 }, sway = 10, alpha = 0.4 } },
	golden = { vista = "SouthernBarrens", emblem = 8350, water = { tint = { 1, 0.78, 0.35 } },
		motes = { kind = "wander", count = 10, color = { 1, 0.85, 0.45 }, size = { 6, 10 }, speed = { 2, 5 }, sway = 4, alpha = 0.6, twinkle = 2.5, star = true } },
	marsh = { vista = "Nazmir", emblem = 6358, water = { prof = "Alchemy" },
		motes = { kind = "wander", count = 9, color = { 0.75, 1, 0.35 }, size = { 3, 4 }, speed = { 4, 9 }, sway = 12, alpha = 0.7, twinkle = 1.6 } },
	moonlit = { vista = "Valsharah", emblem = 13759, water = { prof = "Enchanting" },
		motes = { kind = "wander", count = 10, color = { 0.75, 0.85, 1 }, size = { 2, 4 }, speed = { 3, 7 }, sway = 10, alpha = 0.6, twinkle = 1.2 } },
	lodge = { vista = "Highmountain", emblem = 13889, water = { prof = "Leatherworking" },
		motes = { kind = "up", count = 7, color = { 1, 0.75, 0.4 }, size = { 2, 3 }, speed = { 3, 6 }, sway = 5, alpha = 0.3 } },
	bootybay = { vista = "TiragardeSound", emblem = 21151, water = { prof = "Jewelcrafting" },
		motes = { kind = "wander", count = 8, color = { 1, 0.85, 0.3 }, size = { 6, 10 }, speed = { 2, 4 }, sway = 3, alpha = 0.7, twinkle = 3, star = true } },
	murloc = { vista = "Islands", emblem = 1468, water = { tint = { 0.45, 1, 0.75 } },
		motes = { kind = "up", count = 14, color = { 0.55, 1, 0.75 }, size = { 2, 5 }, speed = { 10, 20 }, sway = 9, alpha = 0.35 } },
	winterspring = { vista = "FrostfireRidge", emblem = 13755, water = { tint = { 0.85, 0.95, 1 } },
		motes = { kind = "down", count = 22, color = { 1, 1, 1 }, size = { 2, 4 }, speed = { 8, 18 }, sway = 14, alpha = 0.6 } },
	deviate = { vista = "NorthernBarrens", emblem = 6522, water = { prof = "Alchemy" },
		motes = { kind = "up", count = 10, color = { 0.5, 1, 0.4 }, size = { 2, 4 }, speed = { 3, 7 }, sway = 12, alpha = 0.45, twinkle = 0.8 } },
	ember = { vista = "BlackrockMountain", emblem = 6359, water = { prof = "Blacksmithing" },
		motes = { kind = "up", count = 16, color = { 1, 0.55, 0.15 }, size = { 2, 4 }, speed = { 14, 30 }, sway = 10, alpha = 0.75, twinkle = 4 } },
	ashenvale = { vista = "Ashenvale", emblem = 6308,
		motes = { kind = "wander", count = 10, color = { 0.6, 1, 0.8 }, size = { 3, 4 }, speed = { 3, 7 }, sway = 10, alpha = 0.65, twinkle = 1.4 } },
	darkshore = { vista = "Darkshore", emblem = 12238, water = { tint = { 0.8, 0.88, 1 } },
		motes = { kind = "up", count = 14, color = { 0.75, 0.85, 1 }, size = { 2, 5 }, speed = { 8, 18 }, sway = 8, alpha = 0.35 } },
	azshara = { vista = "Azshara", emblem = 13760, water = { tint = { 1, 0.6, 0.4 } },
		motes = { kind = "down", count = 12, color = { 1, 0.55, 0.25 }, size = { 4, 6 }, speed = { 6, 12 }, sway = 18, alpha = 0.6 } },
	durotar = { vista = "Durotar", emblem = 6303, water = { tint = { 1, 0.7, 0.5 } },
		motes = { kind = "wander", count = 10, color = { 1, 0.8, 0.55 }, size = { 2, 3 }, speed = { 6, 12 }, sway = 16, alpha = 0.35 } },
	silverpine = { vista = "SilverpineForest", emblem = 21071,
		motes = { kind = "down", count = 26, color = { 0.75, 0.82, 0.9 }, size = { 1, 2 }, speed = { 60, 90 }, sway = 2, alpha = 0.35 } },
	hillsbrad = { vista = "HillsbradFoothills", emblem = 1467, water = { prof = "Herbalism" },
		motes = { kind = "wander", count = 10, color = { 1, 0.95, 0.6 }, size = { 2, 3 }, speed = { 2, 5 }, sway = 10, alpha = 0.55, twinkle = 1 } },
	stormsong = { vista = "Stormsong", emblem = 16969, water = { tint = { 0.6, 0.95, 0.9 } },
		motes = { kind = "down", count = 24, color = { 0.7, 0.9, 1 }, size = { 1, 2 }, speed = { 55, 85 }, sway = 6, alpha = 0.35 } },
	zuldazar = { vista = "Zuldazar", emblem = 19975, water = { prof = "Jewelcrafting" },
		motes = { kind = "wander", count = 8, color = { 1, 0.85, 0.35 }, size = { 6, 10 }, speed = { 2, 4 }, sway = 3, alpha = 0.7, twinkle = 2.5, star = true } },
	voldun = { vista = "Voldun", emblem = 16968, water = { tint = { 1, 0.85, 0.5 } },
		motes = { kind = "wander", count = 12, color = { 1, 0.88, 0.6 }, size = { 2, 3 }, speed = { 8, 16 }, sway = 20, alpha = 0.3 } },
	drustvar = { vista = "Drustvar", emblem = 6299, water = { prof = "Inscription" },
		motes = { kind = "wander", count = 9, color = { 0.85, 0.55, 1 }, size = { 3, 4 }, speed = { 3, 7 }, sway = 12, alpha = 0.6, twinkle = 1 } },
	suramar = { vista = "Suramar", emblem = 19805, water = { prof = "Enchanting" },
		motes = { kind = "up", count = 12, color = { 0.85, 0.6, 1 }, size = { 2, 4 }, speed = { 5, 10 }, sway = 10, alpha = 0.5, twinkle = 2 } },
	shadowmoon = { vista = "ShadowmoonValley", emblem = 13422, water = { tint = { 0.7, 0.65, 1 } },
		motes = { kind = "wander", count = 12, color = { 0.9, 0.9, 1 }, size = { 5, 8 }, speed = { 1, 2 }, sway = 2, alpha = 0.6, twinkle = 1.5, star = true } },
	fel = { vista = "TannanJungle", emblem = 6458, water = { prof = "Alchemy" },
		motes = { kind = "up", count = 16, color = { 0.5, 1, 0.2 }, size = { 2, 4 }, speed = { 12, 26 }, sway = 10, alpha = 0.7, twinkle = 3 } },
	mechagon = { vista = "Mechagon", emblem = 21150, water = { prof = "Engineering" },
		motes = { kind = "up", count = 12, color = { 1, 0.7, 0.3 }, size = { 1, 3 }, speed = { 20, 40 }, sway = 14, alpha = 0.7, twinkle = 6 } },
	bastion = { vista = "Bastion", emblem = 19806, water = { tint = { 1, 0.92, 0.6 } },
		motes = { kind = "up", count = 10, color = { 1, 0.9, 0.6 }, size = { 5, 8 }, speed = { 3, 6 }, sway = 4, alpha = 0.6, twinkle = 2, star = true } },
	revendreth = { vista = "Revendreth", emblem = 13758, water = { tint = { 1, 0.4, 0.4 } },
		motes = { kind = "up", count = 12, color = { 1, 0.3, 0.3 }, size = { 2, 4 }, speed = { 4, 9 }, sway = 8, alpha = 0.5 } },
	ardenweald = { vista = "Ardenweald", emblem = 19803, water = { tint = { 0.55, 0.75, 1 } },
		motes = { kind = "wander", count = 11, color = { 0.55, 0.8, 1 }, size = { 3, 5 }, speed = { 3, 6 }, sway = 10, alpha = 0.65, twinkle = 1.3 } },
	alliance = { vista = "TownAlliance", emblem = 6307, water = { tint = { 0.6, 0.75, 1 } },
		motes = { kind = "wander", count = 8, color = { 1, 0.85, 0.4 }, size = { 6, 9 }, speed = { 2, 4 }, sway = 3, alpha = 0.6, twinkle = 2, star = true } },
	horde = { vista = "TownHorde", emblem = 21114, water = { prof = "Blacksmithing" },
		motes = { kind = "up", count = 14, color = { 1, 0.45, 0.15 }, size = { 2, 4 }, speed = { 12, 26 }, sway = 10, alpha = 0.7, twinkle = 4 } },
	class = { class = true,
		motes = { kind = "wander", count = 8, size = { 3, 5 }, speed = { 3, 6 }, sway = 8, alpha = 0.45, twinkle = 1.4 } },
}

local VISTA_LAYERS = { { "-Back", 0.55 }, { "-Mid", 0.75 }, { "-Fore", 1 } }
local VISTA_MAX = 130   -- the scenery's height at most, so it stays a strip along the foot
local VISTA_ALPHA = 0.5 -- at its foot; it fades to nothing at its top
local scenes = {}       -- { owner, driver, vista = { textures }, motes = { particles } }
Theme._scenes = scenes  -- for the tests

local function Effects()
	local effects = ns.db and ns.db.themeEffects or "all"
	-- Reduce motion keeps the scenery but stills the particles.
	if effects == "all" and ns.ReduceMotion and ns.ReduceMotion() then
		return "still"
	end
	return effects
end

local function ClassColor()
	local _, classFile = UnitClass("player")
	local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	return color and { color.r, color.g, color.b } or { 1, 1, 1 }
end

-- The scenery layers, cropped to their lower part so they fill the width without towering.
local function LayoutVista(scene)
	local owner = scene.owner
	local width = (owner:GetWidth() or 0) - 6
	if width <= 0 then
		return
	end
	for _, tex in ipairs(scene.vista) do
		local info = tex.atlasInfo
		if info then
			local natural = width * info.height / info.width
			local height = math.min(natural, VISTA_MAX, math.max(10, (owner:GetHeight() or 0) - 6))
			local top, bottom = info.topTexCoord, info.bottomTexCoord
			tex:SetTexCoord(info.leftTexCoord, info.rightTexCoord, bottom - (bottom - top) * height / natural, bottom)
			tex:SetHeight(height)
		end
	end
end

local function ApplyVista(scene, spec)
	local name = spec and spec.vista and Effects() ~= "off" and ("_GarrMissionLocation-" .. spec.vista)
	local infos, present = {}, 0
	for i, layer in ipairs(VISTA_LAYERS) do
		local info = name and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name .. layer[1])
		if info and (info.file or info.filename) and info.width and info.width > 0 then
			infos[i], present = info, present + 1
		end
	end
	for i, layer in ipairs(VISTA_LAYERS) do
		local tex = scene.vista[i]
		local info = infos[i]
		if info then
			if not tex then
				tex = scene.owner:CreateTexture(nil, "BACKGROUND", nil, 7)
				tex:SetPoint("BOTTOMLEFT", 3, 3)
				tex:SetPoint("BOTTOMRIGHT", -3, 3)
				isGrain[tex] = true
				scene.vista[i] = tex
			end
			tex:SetTexture(info.file or info.filename)
			tex.atlasInfo = info
			-- Layers behind are fainter; a scene with one layer shows it at full strength.
			local a = VISTA_ALPHA * (present > 1 and layer[2] or 1)
			if tex.SetGradient and CreateColor then
				tex:SetVertexColor(1, 1, 1, 1)
				tex:SetGradient("VERTICAL", CreateColor(1, 1, 1, a), CreateColor(1, 1, 1, 0))
			else
				tex:SetAlpha(a * 0.6)
			end
			tex:Show()
		elseif tex then
			tex.atlasInfo = nil
			tex:Hide()
		end
	end
	LayoutVista(scene)
end

-- Particles: each a small disc (or a star, for glints), moved every frame while shown.
local function NewMote(scene)
	local owner = scene.owner
	local tex = owner:CreateTexture(nil, "BACKGROUND", nil, 7)
	isGrain[tex] = true
	tex:SetBlendMode("ADD")
	local mask = owner:CreateMaskTexture()
	mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(tex)
	return { tex = tex, mask = mask }
end

local function Rand(range)
	return range[1] + math.random() * (range[2] - range[1])
end

local function Spawn(m, spec, w, h, anywhere)
	m.size = Rand(spec.size)
	m.speed = Rand(spec.speed)
	m.phase = math.random() * 6.28
	m.x = math.random() * w
	if spec.kind == "down" then
		m.y = anywhere and math.random() * h or h + m.size
	elseif spec.kind == "up" then
		m.y = anywhere and math.random() * h or -m.size
	else
		m.y = math.random() * h
		m.life, m.age = 3 + math.random() * 5, anywhere and math.random() * 3 or 0
		local angle = math.random() * 6.28
		m.vx, m.vy = math.cos(angle) * m.speed, math.sin(angle) * m.speed
	end
	m.tex:SetSize(m.size, m.size)
end

local function ApplyMotes(scene, spec)
	local motes = spec and spec.motes
	local on = motes and Effects() == "all"
	scene.spec = on and motes or nil
	-- As many as a full window has, fewer in a smaller panel (the mini bar), so it never crowds.
	local area = (scene.owner:GetWidth() or 0) * (scene.owner:GetHeight() or 0)
	local share = area > 0 and math.min(1, math.sqrt(area / (400 * 480))) or 1
	local count = on and math.max(3, math.floor(motes.count * share + 0.5)) or 0
	scene.count = count
	local color = motes and (motes.color or (spec.class and ClassColor())) or { 1, 1, 1 }
	for i = 1, math.max(count, #scene.motes) do
		local m = scene.motes[i]
		if i <= count then
			if not m then
				m = NewMote(scene)
				scene.motes[i] = m
			end
			if motes.star then
				if m.masked then
					m.tex:RemoveMaskTexture(m.mask)
					m.masked = false
				end
				m.tex:SetTexture("Interface\\Cooldown\\star4")
			else
				m.tex:SetColorTexture(1, 1, 1, 1)
				if not m.masked then
					m.tex:AddMaskTexture(m.mask)
					m.masked = true
				end
			end
			m.tex:SetVertexColor(color[1], color[2], color[3], 1)
			m.fresh = true
			m.tex:Show()
		elseif m then
			m.tex:Hide()
		end
	end
	scene.driver:SetShown(on and true or false)
end

local function StepMotes(scene, elapsed)
	local spec = scene.spec
	if not spec then
		return
	end
	local owner = scene.owner
	local w, h = (owner:GetWidth() or 0) - 8, (owner:GetHeight() or 0) - 8
	if w <= 0 or h <= 0 then
		return
	end
	elapsed = math.min(elapsed, 0.1)
	local t = GetTime()
	for i = 1, scene.count or 0 do
		local m = scene.motes[i]
		if m.fresh then
			Spawn(m, spec, w, h, true)
			m.fresh = false
		end
		local fade
		if spec.kind == "wander" then
			m.age = m.age + elapsed
			if m.age >= m.life then
				Spawn(m, spec, w, h)
			end
			m.x = m.x + m.vx * elapsed + math.sin(t * 0.7 + m.phase) * spec.sway * elapsed
			m.y = m.y + m.vy * elapsed + math.cos(t * 0.5 + m.phase) * spec.sway * elapsed
			fade = math.sin(math.pi * m.age / m.life)
		else
			local dir = spec.kind == "down" and -1 or 1
			m.y = m.y + dir * m.speed * elapsed
			m.x = m.x + math.sin(t * 0.9 + m.phase) * spec.sway * elapsed
			if m.y > h + m.size or m.y < -m.size then
				Spawn(m, spec, w, h)
			end
			-- Fade in from where it starts and out where it leaves, so nothing pops.
			local along = dir == 1 and m.y / h or 1 - m.y / h
			fade = math.min(1, math.max(0, along) / 0.15, math.max(0, 1 - along) / 0.25)
		end
		if m.x < 0 or m.x > w then
			fade = 0
		end
		local twinkle = spec.twinkle and (0.55 + 0.45 * math.sin(t * spec.twinkle + m.phase)) or 1
		m.tex:SetAlpha(spec.alpha * fade * twinkle)
		m.tex:ClearAllPoints()
		m.tex:SetPoint("CENTER", owner, "BOTTOMLEFT", 4 + m.x, 4 + m.y)
	end
end

-- The emblem: the theme's item icon, round, in the title bar beside the portrait.
local function ApplyEmblem(scene, spec)
	local badge = scene.badge
	local icon = spec and not scene.noEmblem and Effects() ~= "off" and (spec.emblem and C_Item and C_Item.GetItemIconByID(spec.emblem))
	local classAtlas
	if spec and spec.class and not scene.noEmblem and Effects() ~= "off" then
		local _, classFile = UnitClass("player")
		classAtlas = classFile and ("classicon-" .. classFile:lower())
	end
	if not (icon or classAtlas) then
		if badge then
			badge:Hide()
		end
		return
	end
	if not badge then
		-- In the title bar, just right of the portrait: inside the frame, where it's always seen,
		-- and clear of each window's title and of its status line below.
		local f = scene.frame
		if not f then
			return
		end
		badge = CreateFrame("Frame", nil, f)
		badge:SetSize(16, 16)
		badge:SetPoint("CENTER", f, "TOPLEFT", 74, -11)
		badge:SetFrameLevel(f:GetFrameLevel() + 20)
		local ring = badge:CreateTexture(nil, "BACKGROUND")
		ring:SetSize(19, 19)
		ring:SetPoint("CENTER")
		ring:SetColorTexture(0.85, 0.65, 0.25, 1)
		local ringMask = badge:CreateMaskTexture()
		ringMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		ringMask:SetAllPoints(ring)
		ring:AddMaskTexture(ringMask)
		badge.icon = badge:CreateTexture(nil, "ARTWORK")
		badge.icon:SetAllPoints()
		local mask = badge:CreateMaskTexture()
		mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		mask:SetAllPoints(badge.icon)
		badge.icon:AddMaskTexture(mask)
		scene.badge = badge
	end
	if classAtlas and badge.icon.SetAtlas then
		badge.icon:SetAtlas(classAtlas)
		badge.icon:SetTexCoord(0, 1, 0, 1)
	else
		badge.icon:SetTexture(icon)
		badge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	badge:Show()
end

local function ApplyScene(scene, theme)
	local spec = Theme.SCENES[theme.id]
	ApplyVista(scene, spec)
	ApplyMotes(scene, spec)
	ApplyEmblem(scene, spec)
end

-- A window's scene lives on its main inset, behind everything on it.
local function AddScene(frame, inset, noEmblem)
	if not (inset and inset.CreateTexture and inset.CreateMaskTexture) then
		return
	end
	local scene = { owner = inset, frame = frame, vista = {}, motes = {}, noEmblem = noEmblem }
	-- Drives the particles; a hidden window's frames don't update, so it costs nothing then.
	scene.driver = CreateFrame("Frame", nil, inset)
	scene.driver:Hide()
	scene.driver:SetScript("OnUpdate", function(_, elapsed)
		StepMotes(scene, elapsed)
	end)
	inset:HookScript("OnSizeChanged", function()
		LayoutVista(scene)
	end)
	scenes[#scenes + 1] = scene
	if tinted then
		ApplyScene(scene, Theme.Current())
	end
end

-- The Fishing bar's water for a theme: an atlas, how many flipbook rows it has, and a tint.
function Theme.Water(theme)
	local spec = Theme.SCENES[(theme or Theme.Current()).id]
	local water = spec and spec.water
	local prof = water and water.prof
	local atlas = "Skillbar_Fill_Flipbook_Fishing"
	local flare = "Skillbar_Flare_Fishing"
	if prof and Effects() ~= "off" and C_Texture and C_Texture.GetAtlasInfo
		and C_Texture.GetAtlasInfo("Skillbar_Fill_Flipbook_" .. prof) then
		atlas = "Skillbar_Fill_Flipbook_" .. prof
		if C_Texture.GetAtlasInfo("Skillbar_Flare_" .. prof) then
			flare = "Skillbar_Flare_" .. prof
		end
	end
	return atlas, flare, water and Effects() ~= "off" and water.tint or nil
end

-- An inset panel inside a window.
function Theme.Panel(inset)
	AddSurface(inset, "inset")
end

-- A whole window: its frame and its inset panel.
function Theme.Frame(frame, inset, noEmblem)
	AddSurface(frame, "frame")
	if inset then
		Theme.Panel(inset)
		AddScene(frame, inset, noEmblem)
	end
end

-- fn runs whenever the theme changes, and once at startup for anything but Forever.
function Theme.OnChange(fn)
	listeners[#listeners + 1] = fn
end

local function Apply()
	local theme = Theme.Current()
	tinted = tinted or theme.id ~= Theme.DEFAULT
	if tinted then
		for _, entry in ipairs(entries) do
			ApplyEntry(entry, theme)
		end
		for _, owner in ipairs(grainOwners) do
			ApplyGrain(owner, theme)
		end
		for _, scene in ipairs(scenes) do
			ApplyScene(scene, theme)
		end
	end
	for _, fn in ipairs(listeners) do
		fn(theme)
	end
end
Theme.Apply = Apply

-- Called once the saved settings are loaded.
function Theme.Init()
	if Theme.Current().id ~= Theme.DEFAULT then
		Apply()
	end
end

-- Move to a named theme, or the next one if no name is given. Returns its label, or nil if
-- there's no theme of that name.
function Theme.Choose(id)
	if not id then
		local current = Theme.Current().id
		for i, candidate in ipairs(Theme.ORDER) do
			if candidate == current then
				id = Theme.ORDER[i % #Theme.ORDER + 1]
			end
		end
	end
	local theme = Theme.LIST[id]
	if not theme then
		return nil
	end
	local setting = ns.optionSettings and ns.optionSettings.theme
	if setting then
		setting:SetValue(id)
	else
		ns.db.theme = id
		Apply()
	end
	return theme.label
end
