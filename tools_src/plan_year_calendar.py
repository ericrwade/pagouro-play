"""Plan the daily puzzle calendar for the year from 2026-11-17 by season (Eric, 2026-10-06: "spring in spring,
summer in summer"). Rewrites jigsaw/art/be/daily_schedule.json and writes docs/DAILY_CALENDAR.md.

Rules (docs/PICTURE_PACKS.md):
- Days before 2026-11-17 are never touched: everyone, updated or not, shares every daily up to then.
- 2026-11-17 .. 2027-11-16 (365 days): every picture at most once. Winter pictures fall in December to February
  (holiday ones spread through December 1-23), spring in March to May, summer in June to August, autumn in late
  November and September to mid-November. Seasonal pictures are spaced evenly among the "any season" ones that fill
  the rest. A few dates carry a fixed picture (Christmas Eve and Day, New Year's Eve, Carnival, Valentine's Day,
  Easter, May Day).
- Pictures already shown as dailies 2026-10-06 .. 2026-11-16 go to the end of the year (or are the ones left out),
  so nobody sees them twice within a few months.
- No two days in a row from the same category, where possible.
- 2027-11-17 .. 2027-12-31 repeat the start of the year.

    python tools_src/plan_year_calendar.py
"""
import datetime as dt, io, json, os, random, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BE = os.path.join(ROOT, "jigsaw", "art", "be")
EPOCH = dt.date(2026, 1, 1)
START = dt.date(2026, 11, 17)
YEAR = 365
RECENT = (dt.date(2026, 10, 6), dt.date(2026, 11, 16))

FIXED = {  # date -> picture stem (only used if that picture is in the game)
    dt.date(2026, 12, 24): "b2-030-sleigh-full-wrapped-presents",
    dt.date(2026, 12, 25): "b2-004-decorated-christmas-tree-candles",
    dt.date(2026, 12, 31): "b2-018-couples-waltzing-chandeliered-ballroom",
    dt.date(2027, 2, 9): "b2-070-venetian-carnival-masks-feathers",   # Mardi Gras 2027
    dt.date(2027, 2, 14): "b2-067-valentine-bouquet-red-roses",
    dt.date(2027, 3, 28): "b2-077-basket-painted-eggs-among",          # Easter 2027
    dt.date(2027, 5, 1): "b2-098-maypole-colored-ribbons-village",
}
HOLIDAY = re.compile(r"christmas|holly|gingerbread|carol|toy shop|wreath|festive|presents|decorated fir|stocking")
OLD_SEASON = [  # the first 160 carry no season tag; read it from the caption
    ("winter", re.compile(r"snow|skier|winter")),
    ("spring", re.compile(r"spring|blossom|cherry|wisteria|tulip|lilac|peonies|irises|flowering|daffodil")),
    ("summer", re.compile(r"summer|beach|lavender|sunflower|poppies|picnic|regatta|yacht|sunny|boardwalk|hot blue")),
    ("autumn", re.compile(r"autumn|harvest|grape|vine")),
]
AUTUMN_NEW = re.compile(r"autumn|harvest|pumpkin|mushroom|maple")
SUMMER_NEW = re.compile(r"beach|palm|tropical|seaside|bathing")


def season_of(p):
    cap = p["caption"].lower()
    s = p.get("season")
    if s in ("winter", "spring", "summer"):
        return s
    if s == "any":
        if AUTUMN_NEW.search(cap):
            return "autumn"
        return "summer" if SUMMER_NEW.search(cap) else "any"
    for name, rx in OLD_SEASON:
        if rx.search(cap):
            return name
    return "any"


def window(d):
    if d.year == 2026 and d.month == 11:
        return "late2026"  # its own window: only pictures not shown recently, never shuffled with autumn 2027
    if d.month in (12, 1, 2):
        return "winter"
    if d.month in (3, 4, 5):
        return "spring"
    if d.month in (6, 7, 8):
        return "summer"
    return "autumn"


def main():
    rng = random.Random(1888)
    pics = json.load(io.open(os.path.join(BE, "pictures.json"), encoding="utf-8"))
    stem = {os.path.basename(p["file"]).rsplit(".", 1)[0]: p for p in pics}
    cal = json.load(io.open(os.path.join(BE, "daily_schedule.json"), encoding="utf-8"))
    days = cal["days"]
    recent = {days[(d - EPOCH).days] for d in (RECENT[0] + dt.timedelta(k) for k in range((RECENT[1] - RECENT[0]).days + 1))}

    dates = [START + dt.timedelta(k) for k in range(YEAR)]
    plan = {}
    for d, s in FIXED.items():
        if s in stem:
            plan[d] = s
    used = set(plan.values())
    pools = {"holiday": [], "winter": [], "spring": [], "summer": [], "autumn": [], "any": []}
    for s, p in stem.items():
        if s in used:
            continue
        season = season_of(p)
        if s in recent:
            season = "any"  # shown Oct-Nov 2026: whatever its season, it waits for the end of the year
        if season == "winter" and HOLIDAY.search(p["caption"].lower()):
            season = "holiday"
        pools[season].append(s)
    for k in pools:
        rng.shuffle(pools[k])
    # "any" pictures: the recently shown ones last, so they land in autumn 2027 or are the ones left out
    pools["any"].sort(key=lambda s: s in recent)
    # holiday pictures: evenly through December 1-23
    advent = [d for d in dates if d.month == 12 and d.day <= 23 and d not in plan]
    nh = len(pools["holiday"])
    for k, s in enumerate(pools["holiday"]):
        plan[advent[(k * len(advent)) // nh + len(advent) // (2 * nh)]] = s
    free = {w: [d for d in dates if window(d) == w and d not in plan] for w in ("late2026", "winter", "spring", "summer", "autumn")}
    order = {w: pools.get(w, [])[:len(free[w])] for w in free}
    # fill the remaining days of every window from "any", in date order
    gaps = sorted(((d, w) for w in free for d in free[w][len(order[w]):]), key=lambda x: x[0])
    anys = list(pools["any"])
    per = {w: list(order[w]) for w in order}
    for d, w in gaps:
        per[w].append(anys.pop(0))
    left_out = anys

    def spread(items, seasonal):  # seasonal pictures evenly spaced; no two in a row from the same category
        seas = [s for s in items if s in seasonal]
        other = [s for s in items if s not in seasonal]
        rng.shuffle(seas)
        rng.shuffle(other)
        mixed, a, b = [], 0, 0
        for i in range(len(items)):
            if a < len(seas) and (b >= len(other) or a * len(items) <= i * len(seas)):
                mixed.append(seas[a]); a += 1
            else:
                mixed.append(other[b]); b += 1
        out = []
        rest = mixed
        while rest:
            for i, s in enumerate(rest[:4]):
                if not out or stem[s]["category"] != stem[out[-1]]["category"]:
                    out.append(rest.pop(i))
                    break
            else:
                out.append(rest.pop(0))
        return out

    for w in per:
        for d, s in zip(free[w], spread(per[w], set(order[w]))):
            plan[d] = s
    assert len(plan) == YEAR and len(set(plan.values())) == YEAR, (len(plan), len(set(plan.values())))

    base = (START - EPOCH).days
    while len(days) < base + YEAR:
        days.append(days[len(days) % 160])
    for d in dates:
        days[(d - EPOCH).days] = plan[d]
    for i in range(base + YEAR, len(days)):  # 2027-11-17 .. 2027-12-31 repeat the start of the year
        days[i] = days[i - YEAR]
    cal["days"] = days
    if "planned by season" not in cal["about"]:
        cal["about"] += " From 2026-11-17 the calendar is planned by season (tools_src/plan_year_calendar.py)."
    json.dump(cal, io.open(os.path.join(BE, "daily_schedule.json"), "w", encoding="utf-8", newline="\n"), indent=1, ensure_ascii=False)

    lines = ["# Daily puzzle calendar, 2026-11-17 to 2027-11-16", "",
             "Written by `tools_src/plan_year_calendar.py` (one picture per day, each at most once in the year, by season).",
             f"Pictures in the game: {len(stem)}; in this year: {YEAR}; left out of the year (still in New picture): {len(left_out)}.", ""]
    month = None
    for d in dates:
        if d.month != month:
            month = d.month
            lines += ["", f"## {d.strftime('%B %Y')}", ""]
        p = stem[plan[d]]
        mark = " (fixed)" if FIXED.get(d) == plan[d] else ""
        lines.append(f"- {d.strftime('%a %b %d')}: {p['caption']}{mark}")
    lines += ["", "## Left out of the year", ""] + [f"- {stem[s]['caption']}" for s in left_out]
    io.open(os.path.join(ROOT, "docs", "DAILY_CALENDAR.md"), "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    counts = {w: len(per[w]) for w in per}
    seas = {w: len(order[w]) for w in order}
    seas["holiday"] = nh
    print(f"year planned: {YEAR} days, unique {len(set(plan.values()))}; per window {counts}; seasonal pictures {seas}; "
          f"left out {len(left_out)} ({sum(s in recent for s in left_out)} of them shown Oct-Nov 2026); calendar {len(days)} days")


if __name__ == "__main__":
    main()
