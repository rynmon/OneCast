# Developing OneCast

The player-facing description is in [README.md](README.md), the same text as the CurseForge page.

## How it works

Forever runs the modern (Midnight-era) addon API but `loadstring_untainted` is missing, so SecureHandler snippets don't work. OneCast avoids them:

1. `OneCastButton` is a `SecureActionButtonTemplate` button with `type=spell`, `spell=<Fishing>` (name resolved from spell ID 7620, falling back to 131474).
2. On `UNIT_SPELLCAST_CHANNEL_START` for Fishing, the key bound to the button is overridden to `INTERACTTARGET`, and `SoftTargetInteract=3`, `SoftTargetInteractArc=2` and `SoftTargetInteractRange=30` are set so the bobber is the soft-interact target. Optionally, SFX volume is raised to full; music and ambience are left alone.
3. On `UNIT_SPELLCAST_CHANNEL_STOP` the override is cleared, and each CVar is restored only if it still holds OneCast's value.
4. `PLAYER_REGEN_DISABLED` drops every override before combat lockdown; `PLAYER_LOGOUT` restores CVars so they're never saved.

Each cast and reel is still one hardware press; nothing is automated.

### Files

| File | What it holds |
|---|---|
| `OneCast.lua` | Cast button, reel key override, CVar leases, options panel, minimap button, slash commands |
| `Gear.lua` | Equipping the pole from the bags and putting weapons back |
| `Stats.lua` | Session, zone, lifetime and log stats, and the stats window |
| `Prices.lua` | Handing the catch to Auctionator's search |
| `ZoneLevels.lua` | Zone fishing levels (Classic Era data plus Forever player reports) |
| `Changelog.lua` | Release notes, shown in the What's new window and used for releases |
| `WhatsNew.lua` | The What's new window and the login chat line |
| `Media/*.tga` | Button glyphs: white with a dark outline, tinted gold in game |

### Details worth knowing

- **Auto-equip pole:** with no pole equipped, the cast key equips the best pole in the bags (the one used last, else highest item level) from the button's `PreClick`, and that press doesn't cast. Weapons are saved per character and put back after the idle delay (60 s by default; 0 = never), when combat starts (anything blocked in combat finishes when it ends), or on demand. Equipping a different weapon by hand forgets the saved ones. Double right-click needs the pole equipped, so a stray double-click never swaps gear.
- **Sessions:** a cast after 30 minutes idle starts a new session. Fish per hour counts only time actually fishing (gaps over 2 minutes between casts don't count).
- **Opens on cast:** closing the window with its X or the minimap button keeps it closed until a 2-minute break from fishing; Escape, Alt+Z and cutscenes don't count.
- **Zone levels** are keyed by English zone name (`GetRealZoneText`). The Zone tab counts real getaways (`ERR_FISH_ESCAPED`), and zones without data are judged from them.
- **Auction prices** come from Auctionator (`GetAuctionPriceByItemID`) or TSM (`dbmarket`). The scan hands every caught item to Auctionator's `MultiSearchExact`.
- **Wanted items** are account-wide (`OneCastDB.wanted`); stats are per character (`OneCastCharDB`).

## Install for testing

Copy this folder to `World of Warcraft\_<forever folder>_\Interface\AddOns\OneCast`. New files or a changed TOC need a full game restart; other changes need only `/reload`.

## Releasing

`.github/workflows/release.yml` checks every push and pull request: it syntax-checks the Lua files and makes sure `Changelog.lua` has notes for the TOC's `## Version:`.

To release:

1. Add the new version's notes at the top of `Changelog.lua` and bump `## Version:` in `OneCast.toc` to match.
2. Commit, then tag and push: `git tag v0.1.1` and `git push origin main v0.1.1`.
3. The workflow builds `OneCast-0.1.1.zip` with `git archive` (one `OneCast/` folder, leaving out what `.gitattributes` marks `export-ignore`), and publishes a GitHub release with that zip and the notes from `Changelog.lua`. A version containing `alpha` or `beta` is marked as a pre-release.

A tag that doesn't match the TOC version fails the release, so the two can't drift apart.

### CurseForge uploads

The same run uploads the zip to CurseForge once the repository has (Settings → Secrets and variables → Actions):

| Name | Kind | Value |
|---|---|---|
| `CF_API_TOKEN` | secret | An API token from authors.curseforge.com → API Tokens |
| `CURSEFORGE_PROJECT_ID` | variable | The project ID shown on the CurseForge project page |
| `CURSEFORGE_GAME_VERSION_ID` | variable | CurseForge's ID for the WoW Forever game version (comma-separate several) |

To find the game version ID, list CurseForge's WoW versions with your token and pick the Forever one:

```bash
curl -s -H "X-Api-Token: YOUR_TOKEN" https://wow.curseforge.com/api/game/versions
```

Until the two variables are set, the upload step is skipped and you upload the zip from the GitHub release by hand.
