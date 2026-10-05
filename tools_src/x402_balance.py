"""Show the wallet's public balances on Base and the ledger total. Free; reads only public data.

    python x402_balance.py

Uses Blockscout (the public RPC mainnet.base.org lags receipts by seconds). Reads the ADDRESS file, never the key.
"""
import json, os, sys, urllib.request

ADDR = open(os.path.join(os.path.expanduser("~"), ".ssh", "pagouro-x402-wallet.address.txt"), encoding="ascii").read().strip()
LEDGER = os.path.join(os.path.expanduser("~"), ".claude", "skills", "x402", "ledger.jsonl")


def get(url):
    return json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "pagouro/1"}), timeout=60))


B = "https://base.blockscout.com/api/v2/addresses/" + ADDR
eth = int(get(B)["coin_balance"] or 0) / 1e18
print(f"wallet {ADDR}\n  ETH  {eth:.6f}")
# USDC straight from the chain (Blockscout's token index has come back empty for this address).
USDC = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
call = {"jsonrpc": "2.0", "id": 1, "method": "eth_call",
        "params": [{"to": USDC, "data": "0x70a08231" + ADDR[2:].lower().rjust(64, "0")}, "latest"]}
req = urllib.request.Request("https://mainnet.base.org", data=json.dumps(call).encode(),
                             headers={"Content-Type": "application/json", "User-Agent": "pagouro/1"})
print(f"  USDC {int(json.load(urllib.request.urlopen(req, timeout=60))['result'], 16) / 1e6:.6f}  (on-chain)")
for t in get(B + "/token-balances"):
    if t["token"]["address_hash"].lower() == USDC.lower():
        continue
    tok = t["token"]
    d = int(tok.get("decimals") or 0)
    print(f"  {tok.get('symbol') or '?':5s} {int(t['value']) / 10 ** d:,.6f}  ({tok['address_hash']})")
if os.path.exists(LEDGER):
    L = [json.loads(l) for l in open(LEDGER)]
    print(f"ledger: {len(L)} calls, {sum(x['paid'] for x in L) / 1e6:.6f} USDC paid over x402")
