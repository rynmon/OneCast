-- Print one release's notes from Changelog.lua as Markdown, so the GitHub release and the
-- CurseForge upload use the same notes as the in-game What's new page.
-- Usage (Lua 5.1, from the repository root): lua5.1 .github/scripts/release-notes.lua 0.1.0
-- Exits non-zero if Changelog.lua has no entry for that version.

local wanted = arg[1]
if not wanted then
	io.stderr:write("usage: release-notes.lua <version>\n")
	os.exit(2)
end

local ns = {}
local chunk = assert(loadfile("Changelog.lua"))
chunk("OneCast", ns) -- the addon's own `local ADDON, ns = ...`

for _, release in ipairs(ns.CHANGELOG) do
	if release.version == wanted then
		print("Released " .. release.date .. ".")
		print()
		for _, section in ipairs(release.sections) do
			print("### " .. section[1])
			print()
			for _, bullet in ipairs(section[2]) do
				print("- **" .. bullet[1] .. "** " .. bullet[2])
			end
			print()
		end
		print("Type `/onecast new` in game to see these notes any time.")
		os.exit(0)
	end
end

io.stderr:write("Changelog.lua has no entry for version " .. wanted .. "\n")
os.exit(1)
