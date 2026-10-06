# Picture packs: how new pictures reach the game

Decided with Eric, 2026-10-06. Revisit after 60 to 90 days of real players.

## The model

New pictures ship **inside app updates** (no server, no downloads), so the game keeps its promises: offline, no
permissions, no data collected. A pack of about 30 pictures roughly matches what the daily uses up in a month.
**There is no commitment to monthly packs.** The game works indefinitely without them: past the end of the calendar
the dailies simply repeat.

## The daily calendar (`jigsaw/art/be/daily_schedule.json`)

- `days[0]` is 2026-01-01 (puzzle #1); one picture name per day; it covers 2026-01-01 to 2027-12-31.
- It was written from the old whole-list shuffle by `tools_src/write_daily_schedule.gd`, and the self-test proves
  it matches that shuffle on all 730 days (so 0.2.8 and 0.2.9 players see the same dailies).
- **Append-only in time.** A pack may replace entries only for dates at least two weeks after the pack ships.
  Everyone who has updated by then shares every daily; someone who never updates sees the old picture on changed
  days (unavoidable without a server).
- Past its end, the calendar repeats from the start. Before 2027 ends, extend it (append more days).

## New picture ("more puzzles", the FIFO Eric described)

New picture never deals today's daily or the next 89 (`UPCOMING_DAILIES` in `main.gd`). So a new picture is held
back until it has been a daily, then joins free play by itself. With 160 pictures the free-play pool is 70, moving
by one picture a day.

## Size

- Each picture adds about 0.2 to 0.25 MB to the download (Godot-imported JPEG at lossy 0.9). The music is 22 MB.
- 0.2.9 is 82 MB with 160 pictures. 365 pictures would be about 125 MB; Play's limit for the base download is 200 MB.
- Updates download only what changed (Play patches installed apps), so a 30-picture pack is a download of roughly
  6 to 8 MB, not the whole app.

## Paid packs (direction only, not built)

Decided with Eric, 2026-10-06; revisit at 60 to 90 days, and only if there are players asking for more.

- The base game stays free forever: 382 pictures (0.3.0), a year of dailies.
- Beyond that, optional picture packs for about $4.99, sold **through Google Play Billing** (Google keeps 15%).
  Not a website sale that unlocks content in the app: Play's payments policy covers that case.
- Paid packs would arrive as Play Asset Delivery on-demand packs, not in the base download (0.3.0 is already
  127.5 MB of the 200 MB base limit).
- Packs are drawn and eye-checked ahead of time, never generated per purchase: about 1 in 5 judge-passed pictures
  fail the eye check (batch 2).
- The store listing currently says "nothing to buy, nothing locked". It must be reworded on purpose when packs
  ship, e.g. "the game and its 382 pictures are free forever; extra packs are optional."
- Anyone can still draw their own with Pagouro BE (free, CC0 output). Getting those into the game would need a
  "puzzle from your own picture" import, which is a separate, free feature.

## Adding a pack (checklist)

1. Draw with Pagouro BE (about 95 s per picture on the desktop; Eric keeps roughly 1 in 9), Eric picks.
2. Add to `art/be/` and `pictures.json` (append at the end), then **diff a new `.import` against an old one**
   (lossy 0.9; lesson 2026-10-05) and check the export size.
3. Edit `daily_schedule.json` only for dates two or more weeks past the planned release.
4. Run `tools_src/guarded_selftest.ps1` (memory guard; never an unguarded test, lesson 2026-10-06).
