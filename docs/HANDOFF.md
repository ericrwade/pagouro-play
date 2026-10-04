# Pagouro Play — handoff

Written 2026-10-04 (overnight) so any session, or Eric, can pick this up cold. Read this first, then the latest entries
of `docs/BUILD_LOG.md` (the story, with every measurement and every mistake).

## What it is

Pagouro Jigsaw: a free jigsaw of the 30 lettering-free Pagouro BE showcase pictures, with the Pagouro Salon piano loop.
Sponsored by Pagouro (S-4 in `PAGOURO_SALON/docs/DECISIONS.md`): no ads, no tracking, no account, no paid unlock.
Godot 4.7.2 (GL Compatibility). Windows build plays from `PLAY-JIGSAW.bat`; Android test build 0.1.0 exists
(`build/pagouro-jigsaw.apk`, debug-signed, not in any store; also attached to the private prerelease
`android-test-0.1.0` on GitHub, SHA-256 `e2a0140b…dd398`, verified by download). Not yet played by Eric on a phone.

Repository: local `C:\Users\Eric Wade\PAGOURO_PLAY`; GitHub `ericrwade/pagouro-play`, created PRIVATE on 2026-10-04 as a
backup (making it public, and any GitHub Pages site, is Eric's call).

## Where things are

| path | what |
|---|---|
| `jigsaw/scripts/main.gd` | the screen: daily puzzle, menus, Help, About, save/restore, phone scale, Back, self-test |
| `jigsaw/scripts/puzzle.gd` | the table: build, drag, join, lock, tray hand-off, hints, zoom/pan/pinch, snapshot/restore |
| `jigsaw/scripts/piece_shape.gd` | the cut: corner lattice, Euler-balanced tabs plus a 20 % flip, tab kinds, equal tab areas, bowed edges, neck rule, `area_report` |
| `jigsaw/scripts/tray.gd` | the two-row phone tray |
| `jigsaw/scripts/help_card.gd` | the Help card (6 s countdown, then Done) |
| `jigsaw/scripts/belle_style.gd` | the house look: D-74 palette values only, fonts, frame with corner scrolls |
| `jigsaw/content/panels.json` | 152 Help panels, each with `source` for its facts; `intro-01` is pinned first |
| `jigsaw/music/salon-loop-v1.*` | the loop, its tracklist, and the per-piece start times used for the random start |
| `jigsaw/art/be/` | 30 pictures (JPEG, imported lossy 0.9) + `pictures.json` (prompts, seeds) |
| `jigsaw/art/icon/` | crab icons (cropped from `PAGOURO_BUILD/brand/pagouro_mark_1024.png`) |
| `jigsaw/export_presets.cfg` | Android preset: `com.pagouro.jigsaw`, arm64 only, no permissions, version 0.1.0 / code 1 |
| `tools/` (gitignored) | `godot/` (play + self-test), `godot-export/` (self-contained copy for exports), `jdk17/`, `android-sdk/`, `dl/` |
| `build/` (gitignored) | the APK and `INSTALL-ON-ANDROID.txt` |

## How to

- **Play**: `PLAY-JIGSAW.bat`.
- **Test**: `tools\godot\Godot_v4.7.2-stable_win64_console.exe --path jigsaw --audio-driver Dummy --position -4000,-4000 -- --selftest`
  (add `--resolution 405x880` for the phone layout). ALWAYS silent and off-screen: a visible run pops onto Eric's
  desktop, plays music and once made him think the game had a 0:01 bug. It prints one SELFTEST line (piece-area spread
  and tab mix for both cuts, neck widths, tray, locking, save/restore identity, Help, hints, solve) and writes
  screenshots to `%APPDATA%\Godot\app_userdata\Pagouro Jigsaw\`. LOOK at the screenshots: the off-screen finish card and
  the invisible Done label were both found only that way. It uses its own progress file, never the player's.
- **After adding a script with a new `class_name`**: run `--headless --path jigsaw --import` once first.
- **Android build**: `tools\godot-export\Godot_v4.7.2-stable_win64_console.exe --headless --path jigsaw --export-debug "Android" ../build/pagouro-jigsaw.apk`.
  `godot-export/` is a self-contained copy (`._sc_` file) so its editor settings, debug keystore and templates live in
  `tools/godot-export/editor_data/` and never touch `%APPDATA%\Godot` — which Summer Engine shares. Its editor settings
  point at Java and the SDK by 8.3 short path (`C:/Users/ERICWA~1/PA3F94~1/tools/...`) because Android's `.bat` tools
  break on the space in "Eric Wade". Check the result with
  `tools\android-sdk\build-tools\36.1.0\aapt2.exe dump badging build\pagouro-jigsaw.apk`.
- Android SDK packages are installed with the new `android.exe` in `cmdline-tools/latest/bin` (`android --sdk=<short path> sdk install ...`);
  `sdkmanager` now says it is deprecated and silently installed nothing.

## Decisions (with Eric, 2026-10-03/04)

- Belle Époque touch on all Pagouro graphics, colors only from the locked D-74 palette (`PAGOURO_BUILD/docs/STYLE_GUIDE.md`).
- Placed pieces lock on the board; the table stays free-floating; an inside piece on its true spot locks without the border.
- Whimsical cut is the default; Classic has mild hand-cut variation. Real tab mix (about 55 % two-and-two, about 40 %
  three-and-one, about 4 % four-and-none), sizes held by bowed edges. Eric rejected "exactly two-and-two everywhere".
- Necks at least half the head's width ("can't have tabs with a neck so narrow that it would just tear off").
- Help = an informative "ad": 6 s, then Done; hints scale ~1 per 24 pieces; first panel "Built with AI".
- Music starts at a random piece each launch.
- Shells (rewards) would be device-only, no login; not built.
- Splash screen: Eric floated a 3-5 s logo splash; agreed short (2-3 s), skippable, launch only; not built beyond the
  crab on Godot's boot screen.

## Open / next

1. **Eric installs the APK on his Android phone** and reports what feels wrong. Expect touch-feel issues no desktop test
   can show (grab size, snap distance, pinch while carrying a piece).
2. Store path (needs Eric's word and money): Google Play developer account ($25 once); new personal accounts must run a
   closed test with at least 12 testers for 14 days before production (as of my training data — check at sign-up).
   A RELEASE keystore must be made for the store build and kept OUTSIDE every repo, like the minisign key; losing it
   means never updating the app. The data-safety form is "collects nothing"; privacy policy goes on pagouro.com.
   Apple ($99/yr, Eric's Mac, TestFlight) after Android.
3. Not built: piece rotation option, saving more than one puzzle, shells, the logo splash, a themed (monochrome) icon,
   the round-2 Salon loop (B2L is the chosen model; its checkpoints are home in `PAGOURO_SALON/runs/salon_r2/B2L/best`).
4. Solitaire (S-4) comes after the jigsaw.

## Guardrails that apply here

Never touch Summer Engine or its project (AMPLYFi): no Summer MCP tools for this, and if both can't run, the jigsaw
waits. Numbers are measured, never remembered. No spend and nothing public without Eric's word. American spelling in
new writing. Status channel for Pagouro work: issue #2 on `ericrwade/pagouro`, `[session]` lines.
