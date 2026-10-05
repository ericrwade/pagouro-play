# What players say about jigsaw apps on Google Play (2026-10-05)

Bought over **x402** (Pagouro's first agentic payment): 13 calls to OpenWeb Ninja's Google Play gateway
(`x402.openwebninja.com`) at 0.003 USDC each, **0.039 USDC in total**, paid from Claude's Base wallet
`0x038fB781Ebf705b7f372243bAe63D4CbD0278983` and confirmed on-chain (13 USDC transfers to the service's address).
The x402Atlas App Store service was the first choice, but Eric's ISP filter (Spectrum Security Shield) blocks that
domain from this desk.

- 1 search: "jigsaw puzzle", Google Play US: the top 30 apps, with their ads, data-safety and download figures.
- 12 review pages of 100: the most-helpful reviews of 8 leading apps (Easybrain Jigsaw Puzzles, Jigsawscapes,
  Jigsaw Puzzles HD, Jigsaw Puzzles for Adults, Jigsaw Puzzles Epic, Magic Jigsaw Puzzles, Jigsaw Puzzle - Daily
  Puzzles, Just Jigsaws) plus the newest reviews of 4 of them.
- **1,185 unique reviews**: 375 at 1-2 stars, 656 at 4-5 stars. Themes counted by keyword
  (`tools_src/analyze_reviews.py`), then the most-liked reviews in each theme read in full.

Raw responses (with reviewers' names) stay local and are not committed; only the counts below are.

## The top 30 jigsaw apps

| | Count of 30 |
|---|---|
| Contain ads | 25 |
| Collect user data (Play data safety) | 25 |
| Share user data with others | 18 |
| Paid | 1 (Pure Jigsaw Puzzle, $1.95, 100+ downloads) |

The five without ads are that paid app, three children's apps and one small app. Permissions requested range from
2 to 15. Pagouro Jigsaw: no ads, collects nothing, no purchases.

## What the unhappy reviews are about (1-2 stars, n = 375)

| Theme | Share of low reviews | Apps |
|---|---|---|
| Ads (frequency, mid-puzzle "breaks", ads that will not close, "no ads" claims that were false) | **63.5 %** | 9 of 9 |
| Price, subscriptions, "remove ads" purchases that still show ads | 24.5 % | 9 |
| Coins, locked puzzles, running out of free puzzles | 15.7 % | 9 |
| Crashes, freezes, lost progress | 13.6 % | 8 |
| Picture quality or choice | 9.3 % | 7 |
| Piece handling (snapping, zoom, tray, tiny pieces) | 8.0 % | 8 |
| Needs the internet | 3.2 % | 7 |
| Events and tournaments | 3.2 % | 6 |

The single most-liked review in the set (1,814 likes, Magic Jigsaw Puzzles) is about ads getting worse after the
player had paid to remove them.

## What happy players praise (4-5 stars, n = 656)

Variety of pictures and being able to choose them (14 %), "relaxing" (15.7 %), choosing the number of pieces,
showing only edge pieces, calm music, free daily puzzles, and, in one 298-like five-star review of Just Jigsaws,
"No ads, doesn't nag constantly for you to make a purchase."

## AI pictures: a small but loud objection

16 of 1,185 reviews mention AI or artists. Most are negative, and the second most-liked complaint about picture
quality (236 likes, Jigsaw Puzzles HD) says AI art "makes terrible puzzles because it's all distorted when you zoom
in", with a note about not paying artists. Another reviewer moved apps because "my other jigsaw game started loading
too much AI art". One praised Easybrain for using photographs, "not tacky AI".

## What this means for the store listing

1. **Lead with no ads, said plainly and exactly.** Ads are the number-one complaint in every app, and players are
   angry at "no annoying ads" claims that turned out false. Pagouro Jigsaw can say the strict version and mean it:
   no ads at all, no purchases, no coins, nothing locked.
2. **"All 160 pictures are free from the first day."** Locked packs and coin grinds are the third complaint.
3. **Data safety is a real difference.** 25 of the top 30 collect data; ours collects nothing. Worth a line.
4. **Say AI openly, and say how it was done.** The listing already says the pictures are drawn by our own AI model.
   The objections are distortion and artists' rights, so the honest answers are: the model learned its style from
   public-domain posters made before 1929, every training image has a named license in a ledger, and every picture
   in the game was checked by eye (faces especially) before it went in. Hiding it would be worse than saying it.
5. **Keep the "relaxing" note.** It is the most common praise word; the game has no time limit (it only shows how long
   the puzzle took) and a calm piano loop.

## For later versions

- Running out of free puzzles is a top-3 complaint: supports the themed bundles plan.
- Edge-only filter, choosing piece counts and a tray are praised features; zoom that only reaches one corner and
  pieces that snap to the wrong place are complained about.
- Losing progress on a new phone comes up repeatedly.
