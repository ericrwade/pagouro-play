# Jigsaw by Pagouro on Google Play: everything to paste

Prepared 2026-10-04 for Eric's Play Console application. Facts below are measured from the build (0.2.6) or the
self-test, not remembered. Fill the two blanks marked ✱.

## The build

- Upload `build/pagouro-jigsaw.aab` (Android App Bundle; Play no longer takes APKs for new apps). Rebuild with
  `python tools_src/build_aab.py` after any change (bump `version/code` and `version/name` in BOTH presets of
  `jigsaw/export_presets.cfg` and `application/config/version` in `jigsaw/project.godot`).
- Signed with the **upload key** `%USERPROFILE%\.ssh\pagouro-jigsaw-release.keystore` (alias `pagouro-jigsaw`, password in
  `pagouro-jigsaw-release.password.txt` beside it). Certificate SHA-256:
  `89:05:8D:53:72:88:B3:99:FC:C5:FA:3B:1C:2B:B8:F9:A0:F4:F4:A6:97:7D:C5:F9:41:E5:F6:8A:16:68:BB:22`.
  **Back both files up offline**, like the minisign key. With Play App Signing (the default), Google holds the key that
  signs what players download; a lost upload key can be reset through Play support, but it is slow. Never commit them.
- Package name `com.pagouro.jigsaw` is permanent once uploaded.
- Permissions: none. Target SDK 36, minimum SDK 24 (Android 7.0), arm64 only.

## Store listing

**App name** (30 max): `Jigsaw by Pagouro` (renamed 2026-10-05 from Pagouro Jigsaw: phone launchers show about 10
characters, and 'Pagouro J…' hid what the app is; 'Jigsaw by…' does not)

**Short description** (80 max, this is 70):
`Relaxing Belle Époque jigsaws. No ads, nothing to buy, nothing locked.`

**Full description** (4,000 max):

```
A quiet, free jigsaw puzzle game of Belle Époque posters: poplars at sunset, the Eiffel Tower in spring, irises in a
tall vase, balloons over Paris rooftops, a black cat on a red cushion. A hundred and sixty pictures, every one drawn by our own AI picture model: Paris, gardens, dancers, castles, libraries, airships and more.

No ads at all, ever. Nothing to buy, no coins, no subscription, nothing locked: all 160 pictures are free from
the first day. No account, and the app collects no data.

No timer and no score. Take as long as you like; when you finish, it simply tells you how long the puzzle took.

THE PUZZLES
• A daily puzzle: the same picture for everyone each day.
• Any of the 160 pictures at 12, 25, 49, 100 or 156 pieces.
• Two cuts: Whimsical (waving edges, bulbs, caps and arrowheads) or Classic (a traditional die-cut look, every piece a
  little different, like real cardboard).
• Optional rotation for experts: pieces start turned; tap to turn.

THE FEEL
• A two-row tray along the bottom on phones: swipe sideways to browse, swipe a piece up onto the board.
• Pieces that fit join with a soft click; anything in its true place locks down.
• Finish the border and a gold light runs around the frame.
• Pinch to zoom, drag the table to look around.
• Your puzzle is saved as you go.
• Nine table colors from the Belle Époque palette, and a faint guide picture if you want one.

THE MUSIC
A gentle 62-minute piano loop in the style of the Paris salon, composed note by note by Pagouro Salon, our small AI
music generator, trained only on public-domain scores. It starts at a different piece each time.

HELP, WITHOUT ADS
Stuck? Help shows you one short note about the art, the music or the Belle Époque for a few seconds, then places a few
pieces for you. No video, no ad.

ABOUT THE AI PICTURES
We want to be plain about this. The pictures were drawn by Pagouro BE, our own AI picture generator. It learned its
Belle Époque style from public-domain posters made before 1929, each listed with its source in a public ledger, on
top of an open base model trained on Creative Commons-licensed images. Its sources, including the parts we did not
train ourselves, are documented at pagouro.com. The 160 pictures in the game were picked by hand from more than
1,400 drawings.

WHY IT'S FREE
It is made by Pagouro, a small project building free, open AI that runs on your own computer.
Every picture and the music are CC0: yours to keep.

The game works fully offline and asks for no permissions.

With thanks to Summer Engine (summerengine.com), the AI game engine that got us making games. The game
itself is built with Godot, the open-source engine Summer is built on.
```

**Category:** Game › Puzzle. **Tags:** jigsaw, puzzle, art, relaxing, offline.

**Contact email:** `info@pagouro.com` (public on the listing; test email delivered 2026-10-04). **Website:** `https://pagouro.com`.

**Privacy policy URL:** `https://pagouro.com/jigsaw-privacy.html` (LIVE since 2026-10-04; source `store/jigsaw-privacy.html`,
published to `ericrwade/pagouro-site` with Eric's OK).

**Graphics (ready):** icon `jigsaw/art/icon/icon_512.png` (512×512); feature graphic `store/feature_graphic.png`
(1024×500, `tools_src/make_feature_graphic.py`); phone screenshots `store/screenshots/phone_1..5.png` (1080×2160, 2:1, the
longest Play allows; staged by `-- --shots` at 525×1050 and scaled up: fresh puzzle with tray, halfway, Help card,
finished, menu). Real captures from the Pixel can replace them later; its screen is 2.22:1, so crop to 2:1.

**Checked:** the release bundle (0.2.6, code 17, sha256 fdb27387…, release `play-0.2.6`; launcher label read back from
the installed APK as 'Jigsaw by Pagouro') was turned into device APKs with bundletool 1.18.3, installed on Eric's
Pixel 11 Pro XL after removing the USB test build (Eric's go-ahead), and runs: masks bake, daily puzzle draws, no errors.

## App content forms

- **Privacy policy:** the URL above.
- **Ads:** No, the app does not contain ads. (Play's definition: third-party ad SDKs, display/banner/native ads, and
  house ads promoting your own apps. The Help card shows facts only; links to Pagouro live in About, which Play allows.)
- **App access:** all functionality is available without special access (no login).
- **Content rating (IARC questionnaire):** category "Game"; violence, fear, sexuality, nudity, crude humor, profanity,
  gambling, controlled substances: none. Users interact or share content: no. Shares location: no. Digital purchases:
  no. Checked against the 160 pictures: vineyards, a grape harvest and a bunch of grapes, café and cabaret tables (no one drinking, no bottles labeled); the pipe-smoking fisherman (x180 #143) left out for tobacco; the soldier with a bayonet (#171) left out; a nightclub scene with dancers
  and stylized colored smoke (no cigarettes or drinks). Expect "Everyone" / PEGI 3.
- **Target audience:** 13 and over (13-15, 16-17, 18+). Choosing under-13 brings the Families policy and
  teacher-approved review; nothing in the game needs it. Answer "no" to "could the app unintentionally appeal to
  children?" only if honest; a jigsaw can, and saying yes is fine because the app collects nothing.
- **Data safety:** "Does your app collect or share any of the required user data types?" **No.** Encryption in
  transit: not applicable (no data leaves the device). Account deletion: no accounts.
- **Government app / financial features / health:** no.
- **News app:** no.

## Release path for a new personal account (check the Console's own wording at sign-up)

1. Internal testing track: upload the AAB, add yourself, install from the Play link (replaces nothing on your phone only
   after you uninstall the USB test build: different signing key).
2. Closed testing: at least 12 testers opted in for 14 continuous days (the rule as of late 2024; the Console states the
   current number). Testers need a Google account and the opt-in link.
3. Apply for production access from the dashboard; Google asks a few questions about the test.

## Progress

- 2026-10-04: personal developer account started. Package `com.pagouro.jigsaw` (friendly name "Pagouro Jigsaw")
  registered with the release key's SHA-256 certificate fingerprint; status "in review".
- 2026-10-04: privacy page published at https://pagouro.com/jigsaw-privacy.html (HTTP 200 checked); contact info@pagouro.com.
- 2026-10-04: Android Developer Console confirmed: `com.pagouro.jigsaw` registered with key SHA-256 89:05:8D:…:68:BB:22
  ("From September 2026, this package name will continue to be installable on certified Android devices using the keys
  you've added"). Builds signed with any other key, such as the Godot debug key, may not install once that applies.
- 2026-10-04: fees paid by Eric: $25 Android Developer Console registration and $25 Google Play Console registration
  (two separate one-time fees, $50 in all). Play identity verification pending.
- 2026-10-05: listing text revised from the review research (`MARKET_RESEARCH_2026-10-05.md`): exact no-ads line,
  all pictures free, no data, no timer, AI stated with how it was made.
- 2026-10-05: Eric's identity and phone VERIFIED by Play Console. Next: Create app.
- 2026-10-05: renamed to Jigsaw by Pagouro (Eric), 0.2.6 / code 17. 'AI' kept out of the name on purpose (Eric agreed):
  the description states it plainly instead.
