# Resume here — Pagouro Jigsaw on Google Play

Saved 2026-10-04, evening, at Eric's request before an aside ("a fork of this conversation"). Everything below is
committed and pushed (`ericrwade/pagouro-play`, private, main). Read this, then `store/PLAY_STORE.md`, then the last two
entries of `docs/BUILD_LOG.md`. `docs/HANDOFF.md` has the toolchain and guardrails.

## Where things stand

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
  **Waiting on Google's identity verification.** Fees: $25 Developer Console + $25 Play Console, both paid by Eric.
- **Privacy policy:** LIVE at https://pagouro.com/jigsaw-privacy.html (pushed to `ericrwade/pagouro-site` with Eric's OK).
  Contact `info@pagouro.com`, confirmed delivering.
- **Store kit ready** in `store/`: listing text and every form answer (`PLAY_STORE.md`), `feature_graphic.png`
  (1024×500), `screenshots/phone_1..5.png` (1080×2160), icon `jigsaw/art/icon/icon_512.png`.
- **Pagouro Salon** backed up: private `ericrwade/pagouro-salon` + release `backup-r2-2026-10-04` (model, loop v2).
- **Summer Engine** credited in About, README and the store description. Eric plans to email the Summer Engine builder
  (name uncertain; he said "Mathias???") once the closed test needs testers, by email, not Discord (his Discord name
  is not his real name and he doesn't want them linked).

## Pictures (2026-10-04, later)

- **160 pictures** in the game now (was 30): 41 more from the x180 set (`PAGOURO_BE/showcase/x180`, clean
  lettering-free picks, faces checked by eye; 001, 097, 107, 143 pipe, 164, 171 bayonet left out) and 89 from
  **jigsaw batch 1** (`PAGOURO_BE/showcase/jigsaw_b1/README.md`: 1,272 drawn on a RunPod A100 for ~$1.40, judged with
  a strict faces check, every face checked by eye). Files `jigsaw/art/be/b1-NNN-slug.jpg`.
- **Rebuilt 2026-10-05 as 0.2.5 / code 16** with all 160 (pictures lossy 0.9 like the first 30; lossless had made the bundle 178 MB, now 82 MB), backed up on private release `play-0.2.5`, installed on Eric's Pixel. (Was: bump to 0.2.5 / code 16 in BOTH presets
  and project.godot). Bundle grows by about 23 MB of pictures.
- Eric's next ideas: themed **bundles** and, in a later version, a page to choose bundles (download packs would
  need the internet permission: update the store line, privacy page and Data safety first, or check Play Asset
  Delivery's on-demand packs).
- The jigsaw now opens in **Summer Engine** (0.5.68; Eric: "force it into the loop"); Summer normalized project.godot
  (same settings). It runs there with 0 runtime errors.

## Next, when Eric is verified

1. Play Console → Create app: name `Pagouro Jigsaw`, English (United States), Game, Free, tick both declarations.
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
