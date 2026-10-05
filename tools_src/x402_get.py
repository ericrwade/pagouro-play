"""Pay-per-call GET over x402 from the Pagouro wallet, with a hard per-call price limit and a running spend ledger.

    python x402_get.py <url> <out.json>

Refuses any payment above 0.01 USDC per call, and refuses to run once the ledger reaches the 1.00 USDC cap Eric set.
Prints only status, price paid and the size of the saved response; the key never leaves this process.
"""
import json, os, sys, time
from eth_account import Account
from x402 import x402ClientSync, max_amount
from x402.mechanisms.evm.exact.register import register_exact_evm_client
from x402.http.clients.requests import x402_requests

KEY = os.path.join(os.path.expanduser("~"), ".ssh", "pagouro-x402-wallet.key")
HERE = os.path.dirname(os.path.abspath(__file__))
LEDGER = os.path.join(HERE, "x402_ledger.jsonl")
PER_CALL = 10_000      # 0.01 USDC (6 decimals)
CAP = 1_000_000        # 1.00 USDC in total

url, out = sys.argv[1], sys.argv[2]
spent = sum(json.loads(l)["paid"] for l in open(LEDGER)) if os.path.exists(LEDGER) else 0
if spent >= CAP:
    sys.exit(f"cap reached: {spent / 1e6:.6f} USDC spent")

acct = Account.from_key(open(KEY, encoding="ascii").read().strip())
client = register_exact_evm_client(x402ClientSync(), acct, policies=[max_amount(PER_CALL)])
s = x402_requests(client)

# Read the price first (unpaid request), so the ledger records what was actually offered.
probe = s.__class__().get(url, timeout=60)
price = 0
if probe.status_code == 402:
    try:
        price = int(probe.json()["accepts"][0].get("maxAmountRequired") or probe.json()["accepts"][0].get("amount"))
    except Exception:
        price = PER_CALL
if spent + price > CAP:
    sys.exit(f"would exceed cap: spent {spent / 1e6:.6f} + {price / 1e6:.6f}")

r = s.get(url, timeout=120)
paid = price if (probe.status_code == 402 and r.status_code == 200) else 0
receipt = r.headers.get("payment-response") or r.headers.get("x-payment-response") or ""
with open(LEDGER, "a") as f:
    f.write(json.dumps({"t": time.strftime("%Y-%m-%dT%H:%M:%S"), "url": url, "status": r.status_code, "paid": paid,
                        "receipt": receipt[:400]}) + "\n")
with open(out, "wb") as f:
    f.write(r.content)
print(f"status {r.status_code} | paid {paid / 1e6:.6f} USDC | total {(spent + paid) / 1e6:.6f} | saved {len(r.content)} bytes")
