# Resume here — Jigsaw by Pagouro on Google Play

Saved 2026-10-04, evening, at Eric's request before an aside ("a fork of this conversation"). Everything below is
committed and pushed (`ericrwade/pagouro-play`, PUBLIC since 2026-10-06 by Eric's word, main). Read this, then `store/PLAY_STORE.md`, then the last two
entries of `docs/BUILD_LOG.md`. `docs/HANDOFF.md` has the toolchain and guardrails.

## NOW (saved 2026-10-08, Eric restarting the PC) — read this block first; the sections below are older history

- **Closed test (Alpha):** Testers Community started 2026-10-06 10:42 AM (16 days, 15 testers). 0.2.9 (code 20) is on
  Alpha. Earliest production application about 2026-10-22; public launch target **2026-10-25** (Eric's birthday):
  turn Managed publishing ON a few days before; add the Play link to pagouro.com/jigsaw on launch day.
- **0.3.0 (code 21) built, NOT yet uploaded** (Eric chose to wait a day or two into the test). `build/pagouro-jigsaw.aab`,
  127,545,084 bytes, SHA-256 `8bcdb788fc366d20a066b7fcd83140270c0e9f460fab724762c1af915fe7d6f3`, signed CN=Pagouro,
  backed up on release `play-0.3.0` (verified by download hash). Rebuilt 2026-10-07 for two Help-panel fixes
  (daily = 49 pieces; 382 pictures) and the iOS-only safe area. Contents: 382 pictures, seasonal calendar from
  2026-11-17, Share shows the date. Must be live before 2026-11-03. Release name `0.3.0 (21)`; notes: "222 new
  pictures: 382 in all, a full year of daily puzzles, with seasonal pictures in their season. Share now shows the date."
- **After 0.3.0 is live:** change 160 -> 382 in the Play listing and on pagouro.com/jigsaw (exact lines at the end of
  `store/PLAY_STORE.md`, including the reworded "chosen from more than 4,400 drawings" line).
- **iPhone:** free first step DONE: iOS preset, 1024 icon, safe area, and `.github/workflows/ios-build.yml` (GitHub
  macOS 26 runner, Xcode 26) built an unsigned arm64 app, run 37571962708 BUILD SUCCEEDED. BLOCKED on Eric's Apple
  account: personal Apple ID `ericrwade@pagouro.com` (NOT the work MacBook, kept separate on purpose); Apple's sign-up
  rejected it at first, but by 2026-10-08 10 PM the account EXISTS (Eric Wade, ericrwade@pagouro.com, two-factor on,
  1 trusted phone; seen on account.apple.com). Developer Program: Eric ENROLLED as Individual and PAID $99
  (2026-10-08, his own card), waiting for Apple's approval email. After approval, plan: Eric creates an App Store
  Connect team API key (App Manager) + the app record (bundle com.pagouro.jigsaw), puts ASC_KEY_ID, ASC_ISSUER_ID,
  ASC_KEY_P8 (base64) and APPLE_TEAM_ID in GitHub repo secrets; the job then archives with xcodebuild
  -allowProvisioningUpdates + -authenticationKey* (Apple's cloud-managed signing, so no certificate secret to keep)
  and uploads to TestFlight. Never use the Apple ID password (in PAGOURO_BUILD/.env) for any of this. Then: Developer Program as
  Individual ($99/yr, his word), then signing cert + App Store Connect API key as repo secrets, then signed IPA ->
  TestFlight from the same job. `joshuaswarren/omarchy-apple-dev` was checked: Linux/SwiftUI/Flutter, still needs an
  Apple ID and paid membership for TestFlight; not useful to us.
- **Paid picture packs:** direction only, revisit at 60-90 days (`docs/PICTURE_PACKS.md`, Play Billing).
- **Self-test:** only via `tools_src/guarded_selftest.ps1` (memory guard). Last run clean 2026-10-07.

## Where things stood (2026-10-04)

- **Game:** Pagouro Jigsaw 0.2.4 (version code 15), tag `v0.2.4`. Eric is happy with it ("I'm very happy with the game").
  The RELEASE build (from the Play bundle, via bundletool) is installed on Eric's Pixel 11 Pro XL; the old debug test
  build was removed with his OK.
- **Play bundle:** `build/pagouro-jigsaw.aab`, built by `python tools_src/build_aab.py`; backed up on the private
  release `play-0.2.4` (SHA-256 6812ad30…570ca9, verified by download).
- **Signing:** upload/release key `%USERPROFILE%\.ssh\pagouro-jigsaw-release.keystore`, password in the `.password.txt`
  beside it (never printed, never in a repo). Cert SHA-256
  `89:05:8D:53:72:88:B3:99:FC:C5:FA:3B:1C:2B:B8:F9:A0:F4:F4:A6:97:7D:C5:F9:41:E5:F6:8A:16:68:BB:22`. Public cert in
  `store/pagouro-jigsaw-release-cert.pem/.der`. Eric still needs to back the keystore + password up offline.
- **Android Developer Console:** package `com.pagouro.jigsaw` ("Pagouro Jigsaw") REGISTERED with that key. From
  September 2026 only builds signed with registered keys install on certified devices, so sign every test build with
  the release key from now on (the debug key is not registered).
- **Play Console:** personal account, developer name **Pagouro**, device check done (Play Console app installed).
  **Identity and phone VERIFIED 2026-10-05** (after re-uploading an unexpired driver's license). Paste kit with every
  field in Console order: https://claude.ai/artifact/Qe77BYTzw5uvnTsHVVACnt (generated from PLAY_STORE.md). Fees: $25 Developer Console + $25 Play Console, both paid by Eric.
- **Privacy policy:** LIVE at https://pagouro.com/jigsaw-privacy.html (pushed to `ericrwade/pagouro-site` with Eric's OK).
  Contact `info@pagouro.com`, confirmed delivering.
- **Store kit ready** in `store/`: listing text and every form answer (`PLAY_STORE.md`), `feature_graphic.png`
  (1024×500), `screenshots/phone_1..5.png` (1080×2160), icon `jigsaw/art/icon/icon_512.png`.
- **Pagouro Salon** backed up: private `ericrwade/pagouro-salon` + release `backup-r2-2026-10-04` (model, loop v2).
- **Summer Engine** credited in About, README and the store description.

## Pictures (2026-10-04, later)

- **160 pictures** in the game now (was 30): 41 more from the x180 set (`PAGOURO_BE/showcase/x180`, clean
  lettering-free picks, faces checked by eye; 001, 097, 107, 143 pipe, 164, 171 bayonet left out) and 89 from
  **jigsaw batch 1** (`PAGOURO_BE/showcase/jigsaw_b1/README.md`: 1,272 drawn on a RunPod A100 for ~$1.40, judged with
  a strict faces check, every face checked by eye). Files `jigsaw/art/be/b1-NNN-slug.jpg`.
- **0.2.6 / code 17 (2026-10-05): renamed Jigsaw by Pagouro** (launcher showed 'Pagouro J…'); release `play-0.2.6`,
  AAB sha256 fdb27387…, installed on Eric's Pixel over 0.2.5 (same key, saves kept). Package name unchanged.
- **Closed test sent for review 2026-10-05**, Testers Community engaged (details in `store/PLAY_STORE.md`, Progress).
- **Rebuilt 2026-10-05 as 0.2.5 / code 16** with all 160 (pictures lossy 0.9 like the first 30; lossless had made the bundle 178 MB, now 82 MB), backed up on private release `play-0.2.5`, installed on Eric's Pixel. (Was: bump to 0.2.5 / code 16 in BOTH presets
  and project.godot). Bundle grows by about 23 MB of pictures.
- Eric's next ideas: themed **bundles** and, in a later version, a page to choose bundles (download packs would
  need the internet permission: update the store line, privacy page and Data safety first, or check Play Asset
  Delivery's on-demand packs).
- The jigsaw now opens in **Summer Engine** (0.5.68; Eric: "force it into the loop"); Summer normalized project.godot
  (same settings). It runs there with 0 runtime errors.

## Next, when Eric is verified

1. Play Console → Create app: name `Jigsaw by Pagouro`, English (United States), Game, Free, tick both declarations.
2. Store listing: paste from `PLAY_STORE.md`; upload icon, feature graphic, screenshots; category Game › Puzzle;
   contact info@pagouro.com; privacy URL above.
3. App content forms: answers in `PLAY_STORE.md` (no ads, collects nothing, IARC all "none", audience 13+).
4. Internal testing: upload the AAB (rebuild first if anything changed; bump the version in BOTH presets and
   project.godot).
5. Closed test: 12+ testers opted in for 14 continuous days (Eric is collecting Gmail addresses), then apply for
   production.

## Open, not urgent

- Loop v2 (round-2 Salon music) is not in the game yet; Eric's ears decide.
- The "Le Robot Désolé" poster idea (the adb-keystrokes moment), offered, waiting on Eric's go.
- Web export for iPhones via pagouro.com (before paying Apple $99/yr); F-Droid later; the same APK on a public
  GitHub release the day the Play version ships.

## Engine note (Eric, 2026-10-04)

Eric had wanted to use Summer Engine. The jigsaw was built in standalone Godot only because Summer's editor was busy with
AMPLYFi and its tools act on whatever project is open (no interference was the rule). Not an efficiency choice. Next
time Summer is free: offer to move the jigsaw into Summer, or build Solitaire in Summer from the start, and say so up
front if a project can't use it.

## x402 (Claude's wallet, agentic payments)

- **Wallet:** Claude's own Base wallet `0x038fB781Ebf705b7f372243bAe63D4CbD0278983`. Eric funds it but deliberately
  doesn't hold the key, which lives in `%USERPROFILE%\.ssh\pagouro-x402-wallet.key` and is never printed or copied.
- **Cap:** 1.00 USDC total. Every spend is posted on issue #2.
- **How-to:** the `x402` Claude Code skill in `~/.claude/skills/x402/` (SKILL.md, scripts, and the one shared
  ledger). Mirrored here as `tools_src/x402_SKILL.md`, `x402_get.py`, `x402_find.py` and `x402_balance.py`.
- **2026-10-05:** first purchase, 0.039 USDC for 1,185 Google Play reviews. Results in
  `store/MARKET_RESEARCH_2026-10-05.md`; the listing recommendations there are not yet applied to `PLAY_STORE.md`.
