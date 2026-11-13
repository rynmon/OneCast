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
	"bootybay", "murloc", "winterspring", "deviate", "ember", "class" }

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
	class = { class = true,
		motes = { kind = "wander", count = 8, size = { 3, 5 }, speed = { 3, 6 }, sway = 8, alpha = 0.45, twinkle = 1.4 } },
}

local VISTA_LAYERS = { { "-Back", 0.55 }, { "-Mid", 0.75 }, { "-Fore", 1 } }
local VISTA_MAX = 130   -- the scenery's height at most, so it stays a strip along the foot
local VISTA_ALPHA = 0.5 -- at its foot; it fades to nothing at its top
local scenes = {}       -- { owner, driver, vista = { textures }, motes = { particles } }
Theme._scenes = scenes  -- for the tests

local function Effects()
	return ns.db and ns.db.themeEffects or "all"
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
