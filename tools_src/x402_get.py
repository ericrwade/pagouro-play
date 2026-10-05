"""Pay-per-call GET over x402 from Claude's Pagouro wallet, with a hard per-call limit and a running spend ledger.

    python x402_get.py <url> <out_file> [--max 0.01] [--dry]

--dry      read the price (unpaid 402 probe) and stop; spends nothing.
--max N    per-call ceiling in USDC (default 0.01). The client refuses any offer above it.

Refuses to run once the ledger reaches CAP (Eric's total cap). The ledger lives in the x402 skill
(~/.claude/skills/x402/ledger.jsonl) so every session and project shares one running total.
Prints only status, price, running total and response size; the key never leaves this process.
"""
import json, os, sys, time

KEY = os.path.join(os.path.expanduser("~"), ".ssh", "pagouro-x402-wallet.key")
LEDGER = os.path.join(os.path.expanduser("~"), ".claude", "skills", "x402", "ledger.jsonl")  # one ledger for every copy
CAP = 1_000_000        # 1.00 USDC in total (Eric's cap, 2026-10-05). Raise only on his word.

args = [a for a in sys.argv[1:]]
dry = "--dry" in args
per_call = 10_000
if "--max" in args:
    per_call = int(round(float(args[args.index("--max") + 1]) * 1e6))
    del args[args.index("--max"):args.index("--max") + 2]
args = [a for a in args if a != "--dry"]
url, out = args[0], args[1]

spent = sum(json.loads(l)["paid"] for l in open(LEDGER)) if os.path.exists(LEDGER) else 0
if spent >= CAP:
    sys.exit(f"cap reached: {spent / 1e6:.6f} USDC spent of {CAP / 1e6:.2f}")

import requests
probe = requests.get(url, timeout=60, headers={"User-Agent": "pagouro/1"})
price, offer = 0, {}
if probe.status_code == 402:
    try:
        body = probe.json()
        offer = body["accepts"][0]
        price = int(offer.get("maxAmountRequired") or offer.get("amount"))
    except Exception:
        price = per_call
print(f"probe {probe.status_code} | price {price / 1e6:.6f} USDC | network {offer.get('network', '?')} | "
      f"spent so far {spent / 1e6:.6f} of {CAP / 1e6:.2f}")
if dry or probe.status_code != 402:
    if probe.status_code != 402:
        with open(out, "wb") as f:
            f.write(probe.content)
        print(f"free response saved, {len(probe.content)} bytes")
    sys.exit(0)
if price > per_call:
    sys.exit(f"price {price / 1e6:.6f} is above the per-call limit {per_call / 1e6:.6f}; pass --max to allow")
if spent + price > CAP:
    sys.exit(f"would exceed cap: spent {spent / 1e6:.6f} + {price / 1e6:.6f}")

from eth_account import Account
from x402 import x402ClientSync, max_amount
from x402.mechanisms.evm.exact.register import register_exact_evm_client
from x402.http.clients.requests import x402_requests

acct = Account.from_key(open(KEY, encoding="ascii").read().strip())
client = register_exact_evm_client(x402ClientSync(), acct, policies=[max_amount(per_call)])
r = x402_requests(client).get(url, timeout=120)
paid = price if r.status_code == 200 else 0
receipt = r.headers.get("payment-response") or r.headers.get("x-payment-response") or ""
with open(LEDGER, "a") as f:
    f.write(json.dumps({"t": time.strftime("%Y-%m-%dT%H:%M:%S"), "url": url, "status": r.status_code, "paid": paid,
                        "receipt": receipt[:400]}) + "\n")
with open(out, "wb") as f:
    f.write(r.content)
print(f"status {r.status_code} | paid {paid / 1e6:.6f} USDC | total {(spent + paid) / 1e6:.6f} | saved {len(r.content)} bytes")
