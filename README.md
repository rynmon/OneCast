# OneCast

One-button fishing for WoW Forever (interface `16001`).

- **One key:** bind *Options > Keybindings > AddOns > OneCast > Cast / reel*. Press once to cast; press again when the bobber splashes to reel in.
- **One click:** with a fishing pole equipped, double right-click the world to cast; right-click the bobber to reel.
- **Options:** *Options > AddOns > OneCast*, the minimap button (left-click; right-click for status; drag to move), the addon compartment, or `/onecast`. The panel also has the cast/reel key binding.
- **Session stats:** right-click the minimap button or `/onecast stats` for casts, catches, catch rate, fish per hour (counting only time actually fishing), catches in the current zone, and everything caught. A cast after 30 minutes idle starts a new session; `/onecast reset` or the window's button starts one by hand.
- **Tabs:** *Session*, *Zone* (the zone you're in, all time), *Lifetime*, and *Log* (the last 100 catches with times; the newest 10 are shown). Everything is kept per character. `/onecast session|zone|lifetime|log` opens a tab directly.
- **Auto-equip pole:** with no pole equipped, the cast key equips the best pole in your bags (the one you used last, else highest item level); press again to cast. Your main- and off-hand weapons are saved per character and put back after a stretch without casting (60 s by default, set under Options; 0 = never), when combat starts (anything blocked in combat finishes when it ends), or on demand with the *Re-equip weapons* key binding, the sword button in the stats window, or `/onecast gear`. Equipping a different weapon by hand forgets the saved ones. Double right-click still needs the pole equipped, so it never swaps gear from a stray double-click.
- **Scalable:** drag the stats window's bottom-right corner, Ctrl + mouse wheel over it, the *Stats window scale* slider (50-200%), or `/onecast scale 120`.
- **Opens on cast** (toggle under Options or `/onecast autoopen`). Closing it with its X or the minimap button keeps it closed until you take a 2-minute break from fishing; Escape, Alt+Z and cutscenes don't count.
- **Zone check:** a skill bar shows your Fishing skill (with lure/pole bonus) and whether it meets the zone's fishing level, so no fish get away. Levels are Classic Era data in `ZoneLevels.lua` (English zone names); the Zone tab also counts real getaways to confirm them on Forever.
- **Value:** vendor value of the catch for each tab, and auction value when Auctionator or TradeSkillMaster is installed (the game has no price API of its own).
- **Scan prices with Auctionator:** with the auction house open, click *Scan fish prices* on the auction house, the coin button in the stats window, or `/onecast scan`. OneCast hands every item you've caught to Auctionator's own search (`MultiSearchExact`), which stores the prices; the stats window updates when Auctionator's data changes.
- **Rare catch alert:** a raid-warning flash, sound, and chat link when you catch something at or above the alert quality (Uncommon by default, set under Options), or anything you've marked as wanted. Right-click an item in the stats window to mark it (shown with a gold `*`); wanted items are account-wide.
- **What's new:** `/onecast new`, the button at the top of OneCast's options, or the *[What's new]* link in the login chat line. Versions on the left, notes on the right. Add each release's notes at the top of `Changelog.lua` with the same version as the TOC.
- `/onecast <doubleclick|softinteract|sound|autoequip|combatgear|autoopen|alert|minimap>` toggles an option; `/onecast help` shows the key and options.

## How it works

Forever runs the modern (Midnight-era) addon API but `loadstring_untainted` is missing, so SecureHandler snippets don't work. OneCast avoids them:

1. `OneCastButton` is a `SecureActionButtonTemplate` button with `type=spell`, `spell=<Fishing>` (name resolved from spell ID 7620, falling back to 131474).
2. On `UNIT_SPELLCAST_CHANNEL_START` for Fishing, the key bound to the button is overridden to `INTERACTTARGET`, and `SoftTargetInteract=3`, `SoftTargetInteractArc=2` and `SoftTargetInteractRange=30` are set so the bobber is the soft-interact target. Optionally, SFX volume is raised to full; music and ambience are left alone.
3. On `UNIT_SPELLCAST_CHANNEL_STOP` the override is cleared, and each CVar is restored only if it still holds OneCast's value.
4. `PLAYER_REGEN_DISABLED` drops every override before combat lockdown; `PLAYER_LOGOUT` restores CVars so they're never saved.

Each cast and reel is still one hardware press; nothing is automated.

## Install

Copy this folder to `World of Warcraft\_<forever folder>_\Interface\AddOns\OneCast`.

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
