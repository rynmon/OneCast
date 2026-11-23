"""OneCast's translations: wrap player-facing strings as L["..."], and list the phrases.

    python tools/l10n.py wrap        wrap new player-facing strings in every Lua file (safe to rerun)
    python tools/l10n.py phrases     print every phrase (L["x"] = true)
    python tools/l10n.py unwrapped   list sentence-like strings left alone, to look over by hand
    python tools/l10n.py missing deDE  list a language's untranslated phrases, "id<TAB>English"
    python tools/l10n.py apply deDE f  add "id<TAB>translation" lines from a file to Locales/deDE.lua
    python tools/l10n.py check       check every translation keeps its placeholders, colours and spaces

A string is wrapped when it's in a call that shows text (SetText, AddLine, AddDoubleLine, Print,
string.format, SetLabel, ...), assigned to a display field (label, tooltip, title, hint, ...), or
reads like a sentence (spaces, lowercase words, end punctuation). Never wrapped: strings compared
(==, ~=) or used as keys, in calls that take names rather than words (events, attributes, CVars,
textures, fonts, find/match/gsub), capitalised names ("Stranglethorn Vale", which OneCast uses as
keys), and the data files. The data report's text stays English: it's read by tools/atlas.py.
"""
import re, sys, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_FILES = {"FishData.lua", "Odds.lua", "MapOverlays.lua", "RecipeSellers.lua", "ZoneNames.lua", "ZoneLevels.lua",
              "AtlasData.lua", "Changelog.lua", "Report.lua", "Locale.lua"}
WRAP_CALLS = {"SetText", "AddLine", "AddDoubleLine", "Print", "format", "SetLabel", "SetTitle", "SetFormattedText",
              "RaidWarning", "Tip", "Hover", "Paragraph", "ShowMenu", "SetIndeterminateText"}
SKIP_CALLS = {"RegisterEvent", "RegisterUnitEvent", "UnregisterEvent", "RegisterAnyEvent", "SetAttribute", "GetAttribute",
              "CreateFrame", "CreateTexture", "CreateFontString", "CreateMaskTexture", "CreateAnimationGroup", "CreateAnimation",
              "SetTexture", "SetAtlas", "SetFontObject", "SetPoint", "SetScript", "HookScript", "GetScript", "find", "match",
              "gmatch", "gsub", "sub", "rep", "byte", "GetCVar", "SetCVar", "GetCVarBool", "PlaySound", "PlaySoundFile",
              "TryCreate", "IsModifiedClick", "SetBinding", "GetBindingKey", "GetBindingAction", "SetOverrideBinding",
              "SetOverrideBindingClick", "SetOverrideBindingSpell", "SizedFont", "SetJustifyH", "SetJustifyV", "SetBlendMode",
              "SetDrawLayer", "SetFrameStrata", "RegisterForClicks", "RegisterForDrag", "SetHighlightTexture",
              "SetNormalTexture", "SetPushedTexture", "SetDisabledTexture", "SetCheckedTexture", "StartSizing",
              "SetOrientation", "SetGradient", "GetAtlasInfo", "HasAtlas", "tinsert", "SetPortrait",
              "SetIconArt", "Attach", "RememberPosition", "GetItemInfoInstant", "issecretvalue", "pcall",
              "rawget", "type", "tonumber", "tostring", "select", "ipairs", "pairs", "concat", "insert", "sort",
              "SetStatusBarTexture", "SetFlipBookRows", "SetSmoothing", "SetLooping", "GetPlayerAuraBySpellID",
              "RegisterStateDriver", "SetMovable", "PoolString", "SetPropagateKeyboardInput", "Wheel", "Theme",
              "OptionValue", "SetOption", "date", "error", "assert", "Register", "OnChange", "SetFont", "Skip", "NoStop",
              "Glyph", "GameTooltip_SetDefaultAnchor", "UnitClass", "UnitName", "UnitGUID", "GetLocale",
              "SetCursor", "Mute", "Claim", "ToggleWindow", "ShowPage", "Show", "Choose"}
FIELDS = {"label", "title", "tooltip", "tip", "hint", "ask", "how", "from", "short", "effect", "does", "blurb", "text",
          "note", "caption", "status", "detail", "desc", "blueprintFrom", "lead", "say", "help", "explain"}
# Never words: textures, frame and font names, constants, identifiers ("journey:rank:"), macros and
# slash commands ("/use item:%d").
NOT_TEXT = re.compile(r"^(\|c(?:ff)?[0-9a-fA-F]{6,8}$|\|cff%02x%02x%02x$|\|T|Interface\\|OneCast[A-Z]|GameFont|OneCastFont|UI-|[A-Z0-9_]+$|[a-z][A-Za-z0-9]*$|[a-z][A-Za-z0-9]*:[\w:]*$|%[sd]$|\s*$)")

def sentence_like(s):
    words = re.findall(r"[A-Za-z']+", s)
    lower = [w for w in words if len(w) >= 3 and w[0].islower()]
    # Words with spaces between them: an identifier has none, and must stay as it is.
    return " " in s.strip() and bool(lower)

def lex(src):
    """Yield (kind, start, end) for code, strings and comments, with each string's enclosing call."""
    i, n = 0, len(src)
    stack = []  # (call name or None) per open paren
    tokens = []
    while i < n:
        c = src[i]
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            if m:
                end = src.find("]" + m.group(1) + "]", i)
                i = n if end < 0 else end + len(m.group(1)) + 2
            else:
                end = src.find("\n", i)
                i = n if end < 0 else end
            continue
        if c == "[" and re.match(r"\[(=*)\[", src[i:]):
            m = re.match(r"\[(=*)\[", src[i:])
            end = src.find("]" + m.group(1) + "]", i)
            i = n if end < 0 else end + len(m.group(1)) + 2
            continue
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            tokens.append((i, j + 1, stack[-1] if stack else None))
            i = j + 1
            continue
        if c == "(":
            m = re.search(r"([A-Za-z_][A-Za-z0-9_]*)\s*$", src[max(0, i - 60):i])
            stack.append(m.group(1) if m else None)
        elif c == ")":
            if stack:
                stack.pop()
        elif c in "{}" :
            # A table constructor: strings inside belong to no call (stack marker).
            if c == "{":
                stack.append("{")
            elif stack and stack[-1] == "{":
                stack.pop()
        i += 1
    return tokens

def decide(src, start, end, call):
    s = src[start + 1:end - 1]
    if src[start] != '"' or not re.search(r"[A-Za-z]{2}", s) or NOT_TEXT.match(s) or "Interface\\\\" in s:
        return False
    # A macro or slash command stays as it is; a help line ("/onecast tackle - tackle box") is words.
    if s.startswith("/") and " - " not in s:
        return False
    before = src[max(0, start - 40):start].rstrip()
    after = src[end:end + 6].lstrip()
    if before.endswith(("==", "~=", "[", "L")) or after.startswith(("==", "~=", "]")):
        return False
    if call in SKIP_CALLS:
        return False
    field = re.search(r"\b([A-Za-z_]+)\s*=\s*$", before)
    if field and field.group(1) in FIELDS:
        return True
    if call in WRAP_CALLS:
        return True
    return bool(sentence_like(s))

def key_regions(src):
    """Blocks marked "-- l10n: keys" ... "-- l10n: end": their names are keys, so they stay plain
    in the code (whatever shows them translates them), but go to translators all the same."""
    return [(m.start(), m.end()) for m in re.finditer(r"-- l10n: keys.*?-- l10n: end", src, re.S)]

def in_regions(pos, regions):
    return any(a <= pos < b for a, b in regions)

def files():
    toc = open(os.path.join(ROOT, "OneCast.toc"), encoding="utf-8").read()
    return [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua") and "/" not in l and "\\" not in l]

def wrap():
    total = 0
    for f in files():
        if f in SKIP_FILES:
            continue
        path = os.path.join(ROOT, f)
        src = open(path, encoding="utf-8").read()
        out, last, count = [], 0, 0
        regions = key_regions(src)
        for start, end, call in lex(src):
            if not in_regions(start, regions) and decide(src, start, end, call):
                out.append(src[last:start] + "L[" + src[start:end] + "]")
                last = end
                count += 1
        if count:
            out.append(src[last:])
            src = "".join(out)
            if not re.search(r"^local L = ns\.L\b", src, re.M):
                src = re.sub(r"^(local [A-Za-z_]+, ns = \.\.\.\n)", r"\1local L = ns.L -- translations (Locale.lua)\n", src, count=1, flags=re.M)
            open(path, "w", encoding="utf-8", newline="").write(src)
            total += count
            print(f"{f}: {count}")
    print("wrapped", total)

def phrases():
    seen = []
    for f in files():
        src = open(os.path.join(ROOT, f), encoding="utf-8").read()
        for m in re.finditer(r'\bL\[("(?:\\.|[^"\\])*")\]', src):
            if m.group(1) not in seen:
                seen.append(m.group(1))
        # Names in key blocks, shown translated by whatever draws them.
        for a, b in key_regions(src):
            for m in re.finditer(r'"((?:\\.|[^"\\])*)"', src[a:b]):
                if re.search(r"[A-Za-z]{2}", m.group(1)) and not NOT_TEXT.match(m.group(1)) and m.group(0) not in seen:
                    seen.append(m.group(0))
    for p in seen:
        print(f"L[{p}] = true")

def unwrapped():
    for f in files():
        if f in SKIP_FILES:
            continue
        src = open(os.path.join(ROOT, f), encoding="utf-8").read()
        for start, end, call in lex(src):
            s = src[start + 1:end - 1]
            if src[start] == '"' and sentence_like(s) and not decide(src, start, end, call) and not src[max(0, start - 2):start].endswith("L["):
                line = src.count("\n", 0, start) + 1
                print(f"{f}:{line} ({call}) {s[:90]}")

def unwrap():
    """Every L["..."] back to its plain string, to wrap again with changed rules."""
    for f in files():
        if f in SKIP_FILES:
            continue
        path = os.path.join(ROOT, f)
        src = open(path, encoding="utf-8").read()
        new = re.sub(r'(?<![\w.])L\[("(?:\\.|[^"\\])*")\]', r"\1", src)
        if new != src:
            open(path, "w", encoding="utf-8", newline="").write(new)

# --- Translations, written into Locales/ ---------------------------------------------------------
# A language's file is its header and one L["phrase"] = "translation" line a phrase. Translations
# are done against a numbered sheet (`sheet`), so a translation names its phrase by number.
LANGS = {"deDE": ["deDE"], "frFR": ["frFR"], "esES": ["esES", "esMX"], "ruRU": ["ruRU"], "zhCN": ["zhCN"],
         "koKR": ["koKR"], "ptBR": ["ptBR"]}

def all_phrases():
    """Every phrase, as its Lua string literal (with its escapes), in the order they're met."""
    out = []
    for line in phrases_lines():
        out.append(line[len("L["):line.index('"] = true') + 1])
    return out

def phrases_lines():
    seen, lines = set(), []
    for f in files():
        src = open(os.path.join(ROOT, f), encoding="utf-8").read()
        found = [m.group(1) for m in re.finditer(r'\bL\[("(?:\\.|[^"\\])*")\]', src)]
        for a, b in key_regions(src):
            for m in re.finditer(r'"((?:\\.|[^"\\])*)"', src[a:b]):
                if re.search(r"[A-Za-z]{2}", m.group(1)) and not NOT_TEXT.match(m.group(1)):
                    found.append(m.group(0))
        for literal in found:
            if literal not in seen:
                seen.add(literal)
                lines.append(f"L[{literal}] = true")
    return lines

def locale_path(lang):
    return os.path.join(ROOT, "Locales", lang + ".lua")

def read_locale(lang):
    """A language's translations: { phrase literal: translation literal }."""
    path = locale_path(lang)
    if not os.path.exists(path):
        return {}
    out = {}
    for m in re.finditer(r'^L\[("(?:\\.|[^"\\])*")\]\s*=\s*("(?:\\.|[^"\\])*")\s*$', open(path, encoding="utf-8").read(), re.M):
        out[m.group(1)] = m.group(2)
    return out

def write_locale(lang, table):
    clients = LANGS[lang]
    order = all_phrases()
    # Every language loads (Locale.lua picks the one in use, from the Language setting), so no
    # GetLocale() guard here.
    lines = [f"-- OneCast in {lang}{' (and ' + ', '.join(clients[1:]) + ')' if len(clients) > 1 else ''}. Written with tools/l10n.py",
             "-- (apply); a phrase not here stays English. Corrections welcome.",
             "local _, ns = ...", "local L = {}", f'ns.LOCALES["{lang}"] = L', ""]
    for literal in order:
        if literal in table:
            lines.append(f"L[{literal}] = {table[literal]}")
    open(locale_path(lang), "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")

def lua_unquote(literal):
    return bytes(literal[1:-1], "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8") if "\\" in literal else literal[1:-1]

def lua_quote(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'

def sheet(path):
    """Every phrase numbered, one a line: "id<TAB>phrase" (as it reads, \\n for a new line)."""
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        for i, literal in enumerate(all_phrases(), start=1):
            f.write(f"{i}\t{literal[1:-1]}\n")
    print(f"{len(all_phrases())} phrases to {path}")

def apply(lang, path):
    """Translations "id<TAB>text" (text as Lua string contents, escapes and all) into a language."""
    order = all_phrases()
    table = read_locale(lang)
    count = 0
    for line in open(path, encoding="utf-8").read().splitlines():
        if "\t" not in line:
            continue
        i, text = line.split("\t", 1)
        if not i.strip().isdigit() or not text.strip():
            continue
        literal = order[int(i) - 1]
        # The phrase's own spacing at the ends joins it to its neighbours:
        # take it from the English, as editors often strip trailing spaces.
        english = literal[1:-1]
        lead = english[:len(english) - len(english.lstrip(" "))]
        trail = english[len(english.rstrip(" ")):]
        text = lead + text.strip(" ") + trail
        table[literal] = '"' + text.replace('"', '\\"').replace('\\\\"', '\\"') + '"'
        count += 1
    write_locale(lang, table)
    print(f"{lang}: {count} applied, {len(table)} of {len(order)} translated")

def missing(lang):
    table = read_locale(lang)
    order = all_phrases()
    gaps = [(i, p) for i, p in enumerate(order, start=1) if p not in table]
    for i, p in gaps:
        print(f"{i}\t{p[1:-1]}")
    print(f"-- {len(gaps)} of {len(order)} not translated", file=sys.stderr)

SPEC = re.compile(r"%[-+#0]*\d*(?:\.\d+)?[sdfgixXc%]") # no space flag: "15% größer" is no placeholder
COLOR = re.compile(r"\|c[0-9a-fA-F]{8}|\|r|\|T[^|]*\|t|\|n")

def check():
    """Every translation keeps its phrase's placeholders, in order, and its colour codes: a lost
    %d breaks string.format in that language."""
    problems = 0
    order = set(all_phrases())
    for lang in LANGS:
        for phrase, text in read_locale(lang).items():
            if phrase not in order:
                continue  # an old phrase no longer used: harmless
            if SPEC.findall(phrase) != SPEC.findall(text):
                print(f"{lang}: placeholders differ: {phrase} -> {text}")
                problems += 1
            if sorted(COLOR.findall(phrase)) != sorted(COLOR.findall(text)):
                print(f"{lang}: colour codes differ: {phrase} -> {text}")
                problems += 1
            if phrase[1:].startswith(" ") != text[1:].startswith(" ") or phrase.endswith(' "') != text.endswith(' "'):
                print(f"{lang}: spacing at the ends differs: {phrase} -> {text}")
                problems += 1
    print(f"{problems} problems")
    sys.exit(1 if problems else 0)

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")  # phrases in every script, on any console
    cmd = sys.argv[1] if len(sys.argv) > 1 else "unwrapped"
    if cmd == "sheet":
        sheet(sys.argv[2]); sys.exit(0)
    if cmd == "apply":
        apply(sys.argv[2], sys.argv[3]); sys.exit(0)
    if cmd == "missing":
        missing(sys.argv[2]); sys.exit(0)
    if cmd == "check":
        check()
    {"wrap": wrap, "phrases": phrases, "unwrapped": unwrapped, "unwrap": unwrap}[sys.argv[1] if len(sys.argv) > 1 else "unwrapped"]()
