"""Search Coinbase's x402 Bazaar (the public catalog of x402 services) by keyword. Free; spends nothing.

    python x402_find.py <word> [<word> ...] [--refresh] [--max-price 0.05]

Caches the whole catalog (~35k entries) to ~/.claude/skills/x402/cache/bazaar.json for a day, then prints matching services with
price (USDC), network and URL, cheapest first. Only Base mainnet (eip155:8453 / "base") offers are payable by us.
"""
import io, json, os, sys, time, urllib.request

sys.stdout.reconfigure(encoding="utf-8")
CACHE = os.path.join(os.path.expanduser("~"), ".claude", "skills", "x402", "cache", "bazaar.json")
API = "https://api.cdp.coinbase.com/platform/v2/x402/discovery/resources?limit=1000&offset={}"

args = sys.argv[1:]
max_price = None
if "--max-price" in args:
    max_price = float(args[args.index("--max-price") + 1])
    del args[args.index("--max-price"):args.index("--max-price") + 2]
refresh = "--refresh" in args
words = [a.lower() for a in args if a != "--refresh"]

if refresh or not os.path.exists(CACHE) or time.time() - os.path.getmtime(CACHE) > 86400:
    items, off = [], 0
    while True:
        req = urllib.request.Request(API.format(off), headers={"User-Agent": "pagouro/1"})
        page = json.load(urllib.request.urlopen(req, timeout=60))
        batch = page.get("items") or page.get("resources") or []
        items += batch
        if len(batch) < 1000:
            break
        off += 1000
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    json.dump(items, io.open(CACHE, "w", encoding="utf-8"))
items = json.load(io.open(CACHE, encoding="utf-8"))

rows = []
for it in items:
    blob = json.dumps(it, ensure_ascii=False).lower()
    if not all(w in blob for w in words):
        continue
    for a in it.get("accepts") or [{}]:
        amt = a.get("maxAmountRequired") or a.get("amount")
        try:
            usd = int(amt) / 1e6
        except (TypeError, ValueError):
            usd = None
        if max_price is not None and (usd is None or usd > max_price):
            continue
        desc = (a.get("description") or it.get("description") or "").replace("\n", " ")[:90]
        rows.append((usd if usd is not None else 9e9, a.get("network", "?"), it.get("resource", "?"), desc))
rows.sort()
print(f"{len(items)} services in catalog; {len(rows)} offers match {words}")
for usd, net, url, desc in rows[:60]:
    print(f"{usd:9.6f}  {net:14s} {url}\n           {desc}")
