import glob, io, json, os, re, collections, sys

sys.stdout.reconfigure(encoding="utf-8")
D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "x402")
THEMES = {
    "ads": r"\bads?\b|advert|commercial",
    "subscription / price / VIP": r"subscri|\bvip\b|premium|pay(ing)? (for|to)|paywall|purchas|\$\d|price|expensive|money",
    "coins / energy / locked pictures": r"\bcoins?\b|unlock|locked|energy|currency|gems|keys?\b|tickets?",
    "needs internet / offline": r"internet|offline|wi-?fi|connection|data\b",
    "events / tournaments / competition": r"tournament|event|compet|leaderboard|race",
    "crashes / bugs / lost progress": r"crash|freez|bug|glitch|lost (my|all)|progress|reset|won'?t (load|open)|keeps closing",
    "piece handling (snap, tray, tiny, sort)": r"snap|tray|tiny|small pieces|sort|drag|zoom|edge pieces|stack|overlap|tap",
    "picture quality / choice": r"blur|resolution|quality of (the )?(pic|image)|pixel|same pictures|repeat|choose|choice|categor",
    "relaxing / calm (praise)": r"relax|calm|soothing|peaceful|unwind|stress",
    "rotation": r"rotat|turn(ed)? pieces",
    "no timer / timer": r"timer|\btime limit|clock",
}
APPS = collections.Counter()
reviews = []
for f in glob.glob(os.path.join(D, "rev_*.json")):
    app = os.path.basename(f)[8:-5]
    for r in json.load(io.open(f, encoding="utf-8"))["data"]["reviews"]:
        reviews.append((app, r))
seen, uniq = set(), []
for app, r in reviews:
    if r["review_id"] not in seen:
        seen.add(r["review_id"]); uniq.append((app, r))
print("reviews", len(reviews), "unique", len(uniq), "apps", len({a for a, _ in uniq}))
low = [(a, r) for a, r in uniq if (r["review_rating"] or 5) <= 2]
high = [(a, r) for a, r in uniq if (r["review_rating"] or 0) >= 4]
print("1-2 stars", len(low), "| 4-5 stars", len(high))
for name, pat in THEMES.items():
    rx = re.compile(pat, re.I)
    nl = sum(1 for _, r in low if rx.search(r["review_text"] or ""))
    nh = sum(1 for _, r in high if rx.search(r["review_text"] or ""))
    apps = len({a for a, r in low if rx.search(r["review_text"] or "")})
    print(f"{name:42s} low {nl:4d} ({100 * nl / len(low):4.1f}%) in {apps} apps | high {nh:4d} ({100 * nh / len(high):4.1f}%)")
if "--dump" in sys.argv:
    k = sys.argv[sys.argv.index("--dump") + 1]
    rx = re.compile(THEMES[k], re.I)
    for a, r in sorted(low if "--high" not in sys.argv else high, key=lambda x: -(x[1]["review_likes"] or 0)):
        if rx.search(r["review_text"] or ""):
            print(f"\n[{r['review_rating']}* {r['review_likes']} likes, {a}] {r['review_text'][:400]}")
