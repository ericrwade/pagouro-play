---
name: x402
description: Pay for data, APIs or services over x402 (HTTP 402 + USDC on Base) from Claude's own wallet. Use it whenever a task would be helped by data or a service you can't get free (app-store reviews, market data, search, scraping, enrichment, model calls), and look for an x402 option before saying "I can't get that". Also for checking the wallet, finding x402 services, or anything about Eric's x402 / agentic-payments work.
---

# x402: Claude's wallet

Eric wants this used. His day job involves agentic payments, so every real x402 purchase is useful evidence. Don't
be shy: when a task would be better with paid data, check the catalog. It doesn't have to be the first move, but
it's a normal one.

**The wallet is Claude's, not Eric's.** He funds it but deliberately doesn't hold the key (2026-10-05: "I want to be
able to say this is YOUR wallet").

- Address: `0x038fB781Ebf705b7f372243bAe63D4CbD0278983` on Base (eip155:8453).
- Key: `%USERPROFILE%\.ssh\pagouro-x402-wallet.key`.
- Address copy: `pagouro-x402-wallet.address.txt` beside the key.

## Hard rules
1. **Never print, cat, commit, upload or copy the key** off this box. Scripts load it inside their own process.
   Tools that only need the address read the `.address.txt` file.
2. **Stay under the cap: 1.00 USDC total**, counting every call ever recorded in `ledger.jsonl` beside this file.
   `x402_get.py` enforces it. Raise `CAP` only on Eric's literal word, and note the date.
3. **Per-call limit of 0.01 USDC by default.** Going above it needs `--max`, and the reason belongs in the post.
4. **Post every spend on issue #2** of `ericrwade/pagouro` as a `[session]` line. Include what was bought, the number
   of calls, the total, the running total and what it was for.
5. **Free and dry runs first.** Use `x402_find.py` to search the catalog, then `x402_get.py ... --dry` to read the
   price. Both cost nothing.
6. **Moving tokens is not covered.** Swaps and transfers need Eric's word each time; he authorized the VCTRAI sale.
   Only Base mainnet offers are payable: `network` `base` / `eip155:8453`, asset USDC
   `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`.
7. **Raw responses may contain personal data** such as reviewers' names. Keep them local and commit only aggregates.

## Tools (in `scripts/`, run with system Python 3.12; `x402[evm,requests]` 2.25 and eth-account 0.14 are installed)

| Command | What it does | Cost |
|---|---|---|
| `python x402_balance.py` | Shows ETH and USDC (USDC read on-chain) and the ledger total | free |
| `python x402_find.py <words> [--max-price 0.05] [--refresh]` | Searches Coinbase's x402 Bazaar (about 34.8k services, cached a day in `cache/`) | free |
| `python x402_get.py <url> <out> --dry` | Probes the price without paying | free |
| `python x402_get.py <url> <out> [--max N]` | Pays, saves the response and appends to the ledger | the price |

Bash paths: `~/.claude/skills/x402/scripts/`. Quote URLs that contain `&`.

## Known services
- **OpenWeb Ninja**, `https://x402.openwebninja.com/`: 0.003 USDC per call, works.
  - Google Play endpoints: `play-store-apps/search?q=…&region=us&language=en` and
    `play-store-apps/app-reviews?app_id=…&sort_by=MOST_RELEVANT|NEWEST&limit=100`.
  - Other OpenWeb Ninja data APIs are in the catalog under the same host.
- **x402Atlas** (`*.use.x402atlas.com`): **blocked by Eric's ISP filter** (Spectrum Security Shield). It shows up
  as TLS errors (SEC_E_INVALID_TOKEN / WRONG_VERSION_NUMBER), and plain HTTP redirects to `cujo.io/warn.html`.
  Pick another provider rather than working around the filter.

## Gotchas
- `mainnet.base.org` returns 403 without a User-Agent and lags receipts by a few seconds.
- Blockscout's token-balance index has returned an empty list for this wallet, so read balances with `eth_call`
  (`balanceOf` = `0x70a08231`).
- A failed paid call (non-200) is logged with `paid 0`. If a service took the payment anyway, check the USDC
  transfers on-chain and correct the ledger by hand.
- Payments are gasless for us (the facilitator settles), so the ETH is only for swaps and approvals.

## History
- 2026-10-05: Eric sent 0.003 ETH, a test 0.00001 USDC and 666,984 VCTRAI.
  - Sold the VCTRAI through KyberSwap for 8.468176 USDC (tx `0xce909d7f…bb34`).
- 2026-10-05, first purchase: 13 calls to OpenWeb Ninja Google Play for 0.039 USDC.
  - Bought 1,185 reviews of jigsaw apps for the Pagouro Jigsaw listing.
  - Memo: `PAGOURO_PLAY/store/MARKET_RESEARCH_2026-10-05.md`.
  - Eric called it "brilliant, and valuable".
- Open idea: the **seller side**, offering Pagouro's own models behind an x402 paywall. Not started; it would need
  Eric's go-ahead.
