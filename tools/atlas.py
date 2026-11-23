"""The Forever fishing atlas: players' data reports, pasted from CurseForge comments into
reports/*.txt, read and merged into AtlasData.lua (shipped with the addon) and
reports/summary.md (for you: what's confirmed, what's new, and draft changelog credits).

Usage, from the repository root:  python tools/atlas.py

Paste comments into any .txt file under reports/ just as they come off the page: names, "2 hours
ago", double-spaced lines and all. Reads the report code (OneCast:H,...) that 1.2 and later add,
and the readable reports of older versions. Each character's newest report counts once: reports
hold all-time totals. Codes carry a random per-character ID; older reports go by commenter name.
"""
import re, os, glob, datetime
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STEP = 25
DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

def b36(s):
    return int(s, 36) if s else 0

def checksum(s):
    total = 0
    for i, ch in enumerate(s.encode("utf-8"), start=1):
        total = (total + i * ch) % 1679616
    out = ""
    n = total
    if n == 0:
        return "0"
    while n:
        out = DIGITS[n % 36] + out
        n //= 36
    return out

# --- What the addon already lists ------------------------------------------------------------
def read(path):
    return open(os.path.join(ROOT, path), encoding="utf-8").read()

AREA_OF = {name: int(i) for name, i in re.findall(r'\["([^"]+)"\]\s*=\s*(\d+)', read("ZoneNames.lua"))}
NAME_OF = {}
for name, i in AREA_OF.items():
    NAME_OF.setdefault(i, name)
LISTED = {}
levels = read("ZoneLevels.lua")
for block in re.finditer(r"\[(\d+)\]\s*=\s*\{(.*?)\n\t\}", levels[:levels.index("ns.ZONE_FISHING_SKILL")], re.S):
    body = re.sub(r"--[^\n]*", "", block.group(2))
    for name in re.findall(r'"([^"]+)"', body):
        LISTED[name] = int(block.group(1))

def zone_key(token):
    """A zone from a code: an area ID in base 36, or @Name+With+Plus."""
    if token.startswith("@"):
        name = token[1:].replace("+", " ")
        return AREA_OF.get(name, name)
    return b36(token)

def zone_name(key):
    return NAME_OF.get(key, str(key)) if isinstance(key, int) else key

# --- Reading the pastes ----------------------------------------------------------------------
AGO = re.compile(r"^(just now|\d+\s+(second|minute|hour|day|week|month|year)s?\s+ago)$", re.I)
CODE = re.compile(r"OneCast:H,[0-9A-Za-z.,!@+:\-']+")

def new_report(source, author):
    return {"source": source, "author": author, "id": None, "date": "", "version": "",
            "zones": {}, "camp": {}, "containers": {}, "journey": [], "drops": []}

def parse_code(code, source, author, problems):
    body, _, check = code.rpartition("!X,")
    if not body or checksum(body) != check.strip():
        problems.append(f"{source}: a report code from {author or 'someone'} didn't add up (cut short or changed in pasting), skipped")
        return None
    r = new_report(source, author)
    target = None  # the record I lines belong to
    for rec in body[len("OneCast:"):].split("!"):
        f = rec.split(",")
        kind = f[0]
        if kind == "H":
            r["version"], r["locale"], r["id"] = f[2], f[3], f[4]
            r["rank"], r["cap"], r["date"] = b36(f[5]), b36(f[6]), f[7]
        elif kind == "Z":
            z = {"casts": b36(f[2]), "catches": b36(f[3]), "getaways": b36(f[4]), "steps": {}, "items": {}}
            r["zones"][zone_key(f[1])] = z
            target = z["items"]
            current = z
        elif kind == "S":
            current["steps"][b36(f[1]) * STEP] = [b36(f[2]), b36(f[3])]
        elif kind == "I" and target is not None:
            target[b36(f[1])] = target.get(b36(f[1]), 0) + b36(f[2])
        elif kind == "B":
            r["camp"][f[1]] = {"catches": b36(f[2]), "items": {}}
            target = r["camp"][f[1]]["items"]
        elif kind == "O":
            r["containers"][b36(f[1])] = {"opened": b36(f[2]), "items": {}}
            target = r["containers"][b36(f[1])]["items"]
        elif kind == "J":
            r["journey"].append({"kind": f[1], "id": b36(f[2]), "how": f[3], "npc": b36(f[4]), "zone": zone_key(f[5]), "bonus": b36(f[6])})
            target = None
        elif kind == "D":
            r["drops"].append({"item": b36(f[1]), "npc": b36(f[2]), "zone": zone_key(f[3]), "count": b36(f[4]), "object": len(f) > 5 and f[5] == "o"})
            target = None
    return r

CAMP_KEY = {"Rare Fishing": "hut", "Uncommon Fishing": "rack"}

def parse_text(lines, source, author):
    """A readable report from before the code (1.0.0 to 1.1)."""
    r = new_report(source, author)
    section, current, camp = None, None, None
    for line in lines:
        s = line.strip()
        m = re.match(r"OneCast (\S+) data report", s)
        if m:
            r["version"] = m.group(1)
            continue
        m = re.match(r"Fishing (\d+)/(\d+)", s)
        if m:
            r["rank"], r["cap"] = int(m.group(1)), int(m.group(2))
            continue
        m = re.match(r"Game .*?, (\w{4}), (\d{4})-(\d\d)-(\d\d)$", s)
        if m:
            r["locale"], r["date"] = m.group(1), m.group(2) + m.group(3) + m.group(4)
            continue
        if s.startswith("New to OneCast"):
            section = "new"; continue
        if s.startswith("Zone levels:"):
            section = "zones"; continue
        if s.startswith("Camp buffs:"):
            section = "camp"; continue
        if s.startswith("What fished-up containers held"):
            section = "containers"; continue
        if s.startswith("Unrecognised fishing messages"):
            section = "messages"; continue
        if section == "new":
            m = re.match(r"- Learned (.+?) \((\d+)\) from the trainer (.+?) \[(\d+)\] in (.+)$", s)
            if m:
                r["journey"].append({"kind": "s", "id": int(m.group(2)), "how": "t", "npc": int(m.group(4)), "zone": AREA_OF.get(m.group(5), m.group(5)), "bonus": 0, "name": m.group(3)})
            m = re.match(r"- Learned (\w+) Fishing \(up to (\d+)\) from the trainer (.+?) \[(\d+)\] in (.+)$", s)
            if m:
                r["journey"].append({"kind": "r", "id": int(m.group(2)), "how": "t", "npc": int(m.group(4)), "zone": AREA_OF.get(m.group(5), m.group(5)), "bonus": 0, "name": m.group(3)})
        elif section == "zones":
            m = re.match(r"(.+?)(?: \[(\d+)\])?, (?:OneCast lists \d+|no level known)$", s)
            if m:
                key = int(m.group(2)) if m.group(2) else AREA_OF.get(m.group(1), m.group(1))
                current = {"casts": 0, "catches": 0, "getaways": 0, "steps": {}, "items": {}}
                r["zones"][key] = current
                continue
            m = re.match(r"skill (\d+)-\d+: (\d+) caught(?:, (\d+) got away)?$", s)
            if m and current is not None:
                c, a = int(m.group(2)), int(m.group(3) or 0)
                current["steps"][int(m.group(1))] = [c, a]
                current["catches"] += c
                current["getaways"] += a
        elif section == "camp":
            m = re.match(r"(.+?) \((.+?)\): (\d+) caught", s)
            if m:
                key = CAMP_KEY.get(m.group(1), m.group(1))
                camp = {"catches": int(m.group(3)), "items": {}}
                r["camp"][key] = camp
                continue
            if camp is not None:
                for _, item, count in re.findall(r"(.+?) \((\d+)\) x(\d+)", s):
                    camp["items"][int(item)] = int(count)
        elif section == "containers":
            m = re.match(r"(.+?) \((\d+)\), opened (\d+): (.+)$", s)
            if m:
                box = {"opened": int(m.group(3)), "items": {}}
                for _, item, count in re.findall(r"(.+?) \((\d+)\) x(\d+)", m.group(4)):
                    box["items"][int(item)] = int(count)
                r["containers"][int(m.group(2))] = box
    return r

def read_pastes(problems):
    reports = []
    for path in sorted(glob.glob(os.path.join(ROOT, "reports", "*.txt"))):
        source = os.path.basename(path)
        lines = [l.rstrip() for l in open(path, encoding="utf-8").read().splitlines()]
        # Who posted each line: a name, then "2 hours ago" (or "Just now") under it.
        author, authors = None, []
        nonblank = [l for l in lines if l.strip()]
        for i, l in enumerate(nonblank):
            if AGO.match(l.strip()) and i > 0:
                author = nonblank[i - 1].strip()
            authors.append(author)
        # Split into reports at each "OneCast x data report" (or a bare code).
        blocks, block, block_author = [], [], None
        for l, a in zip(nonblank, authors):
            starts = re.match(r"\s*OneCast \S+ data report", l)
            if starts and block:
                blocks.append((block, block_author))
                block = []
            if starts or block:
                if not block:
                    block_author = a
                block.append(l)
            elif CODE.search(l):
                blocks.append(([l], a))
        if block:
            blocks.append((block, block_author))
        for block, a in blocks:
            text = "\n".join(block)
            code = CODE.search(text.replace("\n", "")) if "OneCast:H," in text else None
            r = parse_code(code.group(0), source, a, problems) if code else None
            if r is None:
                r = parse_text(block, source, a)
            if r["zones"] or r["camp"] or r["containers"] or r["journey"]:
                reports.append(r)
    return reports

# --- Merging ---------------------------------------------------------------------------------
def merge(reports):
    """The newest report per character: by code ID, else by commenter. Newest: the latest date,
    then the higher Fishing, then the one higher up the page."""
    newest = {}
    for order, r in enumerate(reports):
        who = ("id:" + r["id"]) if r["id"] else ("name:" + (r["author"] or f"unknown{order}"))
        # CurseForge lists the newest comment first, and a character's skill only rises.
        key = (r["date"], r.get("rank", 0), -order)
        if who not in newest or key > newest[who][0]:
            newest[who] = (key, r)
    return [r for _, r in newest.values()]

def build(chosen):
    zones = defaultdict(lambda: {"reports": 0, "catches": 0, "getaways": 0, "steps": defaultdict(lambda: [0, 0]), "items": defaultdict(int)})
    camp = defaultdict(lambda: {"reports": 0, "catches": 0, "items": defaultdict(int)})
    containers = defaultdict(lambda: {"opened": 0, "items": defaultdict(int)})
    trainers = defaultdict(set)
    for r in chosen:
        for key, z in r["zones"].items():
            a = zones[key]
            a["reports"] += 1
            a["catches"] += z["catches"]
            a["getaways"] += z["getaways"]
            for step, (c, g) in z["steps"].items():
                a["steps"][step][0] += c
                a["steps"][step][1] += g
            for item, n in z["items"].items():
                a["items"][item] += n
        for key, b in r["camp"].items():
            camp[key]["reports"] += 1
            camp[key]["catches"] += b["catches"]
            for item, n in b["items"].items():
                camp[key]["items"][item] += n
        for item, box in r["containers"].items():
            containers[item]["opened"] += box["opened"]
            for i, n in box["items"].items():
                containers[item]["items"][i] += n
        for j in r["journey"]:
            if j["how"] == "t":
                trainers[(j["kind"], j["id"])].add((j["npc"], zone_name(j["zone"])))
    return zones, camp, containers, trainers

def judge(key, a):
    """What a zone's catches and getaways say of its level, against what OneCast lists."""
    steps = a["steps"]
    away = [s for s, (c, g) in steps.items() if g > 0]
    low = max(away) + STEP if away else None  # no fish get away from here up, at the least
    clean = sum(c for s, (c, g) in steps.items() if low is not None and s >= low)
    listed = LISTED.get(zone_name(key))
    above = sum(g for s, (c, g) in steps.items() if listed is not None and s >= listed)
    level, verdict = None, "too little to tell yet"
    if listed is not None:
        if low is not None and low > listed and above >= 2:
            level, verdict = low, f"Forever's is higher: fish got away at {low - STEP}-{low - 1}, above the {listed} listed"
        elif low == listed:
            verdict = f"confirmed at {listed}"
        elif low is not None and low < listed:
            verdict = f"consistent with {listed} (fish got away up to {low - 1})"
        elif low is None and a["catches"] > 0:
            verdict = f"no getaways in {a['catches']} catches"
    elif low is not None and clean >= 10:
        level, verdict = low, f"measured: {low} (getaways up to {low - 1}, none in {clean} catches from {low} up)"
    elif low is not None:
        verdict = f"at least {low} (fish got away up to {low - 1})"
    return {"low": low, "clean": clean, "listed": listed, "level": level, "verdict": verdict}

# --- Writing ---------------------------------------------------------------------------------
def lua_key(k):
    return f"[{k}]" if isinstance(k, int) else '["' + k.replace('"', '\\"') + '"]'

def lua_map(d):
    return "{ " + ", ".join(f"[{k}] = {v}" for k, v in sorted(d.items()) if v) + " }"

def write(chosen, zones, camp, containers, trainers):
    today = datetime.date.today().isoformat()
    out = [
        "-- The Forever fishing atlas: generated by tools/atlas.py from players' data reports.",
        "-- Don't edit by hand: paste new reports into reports/ and run the script again.",
        "-- zones: [area ID or name] = { reports, catches, getaways, low (none get away from here up),",
        "--   level (set only where Forever's data overrules the listed one), steps, items }.",
        "",
        "local _, ns = ...",
        "",
        "ns.ATLAS = {",
        f'\tgenerated = "{today}",',
        f"\tplayers = {len(chosen)},",
        "\tzones = {",
    ]
    for key in sorted(zones, key=lambda k: zone_name(k)):
        a = zones[key]
        j = judge(key, a)
        steps = "{ " + ", ".join(f"[{s}] = {{ {c}, {g} }}" for s, (c, g) in sorted(a["steps"].items())) + " }"
        fields = [f"reports = {a['reports']}", f"catches = {a['catches']}", f"getaways = {a['getaways']}"]
        if j["low"] is not None:
            fields.append(f"low = {j['low']}")
        if j["level"] is not None:
            fields.append(f"level = {j['level']}")
        fields.append(f"steps = {steps}")
        if a["items"]:
            fields.append(f"items = {lua_map(a['items'])}")
        out.append(f"\t\t{lua_key(key)} = {{ {', '.join(fields)} }}, -- {zone_name(key)}: {j['verdict']}")
    out.append("\t},")
    out.append("\tcamp = {")
    for key, b in sorted(camp.items()):
        out.append(f'\t\t{lua_key(key)} = {{ reports = {b["reports"]}, catches = {b["catches"]}, items = {lua_map(b["items"])} }},')
    out.append("\t},")
    out.append("\tcontainers = {")
    for item, box in sorted(containers.items()):
        out.append(f"\t\t[{item}] = {{ opened = {box['opened']}, items = {lua_map(box['items'])} }},")
    out.append("\t},")
    out.append("}")
    open(os.path.join(ROOT, "AtlasData.lua"), "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")

def summary(chosen, zones, camp, containers, trainers, problems):
    lines = [f"# Atlas summary, {datetime.date.today().isoformat()}", "",
             f"{len(chosen)} players' newest reports, from {', '.join(sorted({r['source'] for r in chosen}))}.", ""]
    if problems:
        lines += ["## Problems", ""] + [f"- {p}" for p in problems] + [""]
    lines += ["## Zones", "", "| Zone | Listed | Reports | Catches | Getaways | Verdict |", "|---|---|---|---|---|---|"]
    for key in sorted(zones, key=lambda k: zone_name(k)):
        a, j = zones[key], judge(key, zones[key])
        lines.append(f"| {zone_name(key)} | {j['listed'] or '-'} | {a['reports']} | {a['catches']} | {a['getaways']} | {j['verdict']} |")
    lines += ["", "## Trainers seen", ""]
    for (kind, ident), seen in sorted(trainers.items()):
        lines.append(f"- {'rank up to ' + str(ident) if kind == 'r' else 'spell ' + str(ident)}: " + "; ".join(f"npc {n} in {z}" for n, z in sorted(seen, key=str)))
    lines += ["", "## Draft changelog credits", ""]
    for r in sorted(chosen, key=lambda r: (r["author"] or "")):
        if r["author"]:
            zs = ", ".join(sorted({zone_name(k) for k in r["zones"]}))[:200]
            lines.append(f'- Reported by {r["author"]}: {zs or "camp, containers or trainers"}')
    os.makedirs(os.path.join(ROOT, "reports"), exist_ok=True)
    open(os.path.join(ROOT, "reports", "summary.md"), "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")

def main():
    problems = []
    reports = read_pastes(problems)
    chosen = merge(reports)
    zones, camp, containers, trainers = build(chosen)
    write(chosen, zones, camp, containers, trainers)
    summary(chosen, zones, camp, containers, trainers, problems)
    print(f"{len(reports)} reports read, {len(chosen)} players' newest kept, {len(zones)} zones.")
    for p in problems:
        print("problem:", p)
    changed = [(zone_name(k), judge(k, a)) for k, a in zones.items() if judge(k, a)["level"]]
    for name, j in changed:
        print(f"level from Forever's data: {name} -> {j['level']} ({j['verdict']})")
    print("Wrote AtlasData.lua and reports/summary.md.")

if __name__ == "__main__":
    main()
