# Pagouro Play — build log

## 2026-10-03 — Pagouro Jigsaw, first playable

Eric: "keep working autonomously on the other pieces of the jigsaw … I have Summer Engine already working on AMPLYFi game
under ChatGPT - make sure that Pagouro Jigsaw doesn't interfere. If they can't both run, then you take back seat and wait."

**Not touching Summer Engine.** The Summer MCP tools bind to whatever project the running editor has open (AMPLYFi), so
the jigsaw does not use them. It is a plain Godot project run by the standalone Godot 4.7.2 (the same engine version
Summer 4.7.2 reports), downloaded from the official GitHub release and checked against its SHA-512 list. Both run side by
side; the jigsaw can be opened in Summer later without conversion.

**What exists.** `jigsaw/scripts/piece_shape.gd` cuts classic interlocking outlines (one seeded tab direction per inner
edge; neck plus a circular knob). `puzzle.gd` keeps everything in the picture's pixel space: pieces are textured
Polygon2D nodes inside cluster nodes, and a piece's place inside its cluster is its home position, so two clusters fit
together exactly when their positions are equal; joining and snapping to the frame compare positions only. The table is
the board plus a margin, widened to the window's shape. `main.gd` holds the daily puzzle (fixed shuffle seeded 1888,
indexed by days since 2026-01-01 UTC), the piece-count menu, hint and music toggles, the sponsor line and the finish card.

**Assets.** The 30 lettering-free showcase pictures from the Pagouro BE Gallery set, as JPEG quality 90 (44 MB of PNG down
to 7.3 MB). The Salon loop version 1, re-encoded mono Vorbis quality 2 (42 MB down to 22 MB).

**Verified** with the self-test (`-- --selftest`): 12 asked gives 12 pieces (3 x 4), 48 asked gives 49 (7 x 7); joining
half the pieces and then all of them ends in one cluster on the frame and the finish card; screenshots looked at for the
scattered, half-done and solved states. Fixed after the first look: the piece-count menu did not follow the puzzle, the
board was too small, and on a wide window the pieces used only a narrow column.

Not yet done: playtesting by a person with a mouse and on a phone, piece rotation option, edge-pieces tray, saving a
puzzle in progress, the ratings and the generated-art packs (S-4), Android and Mac builds.

**The Pagouro look (Eric, same evening):** "whenever we design anything graphical for Pagouro let's lean a little bit
into the Belle Epoque visuals such as the curlycues and edging etc. Not too much, but stylishly a tiny bit less clean
than Cupertino would build." `belle_style.gd` holds it: paper and ink colours, Cormorant Garamond for titles and EB
Garamond for text (both SIL OFL), buttons with thin ink borders on paper, a gold rule and ink hairline under the top bar,
a gold-and-ink double frame around the board with a pair of small Art Nouveau scrolls at each corner (outside the
picture, never over it), and a double-edged finish card. Also: on completion the piece seams fade out and the view glides
to frame the finished picture above the card, so the card never covers it.

**Table colours (Eric: "The jigsaw game I have allows for the background color to be changed in case it matches the
artwork too closely, too. Makes it easier to play.").** A menu of eight period-flavoured table colours, light to dark:
Paper, Sage, Rose, Slate blue, Bottle green, Burgundy, Night, Charcoal. The board takes a shade just off the table
(darker on light tables, lighter on dark ones), the sponsor line switches between ink and paper so it stays readable,
and the choice is kept between sessions in `user://settings.cfg`. Checked on Night: cream and lavender pieces stand out.

**Colors snapped to the locked house palette (Eric, 2026-10-03: "Is everything you are doing still honoring our original
color scheme?").** The first pass picked paper, ink, gold and the table colors by eye; they were close to D-74 but not
it. Now every color is a value from D-74's Belle Époque palette (`PAGOURO_BUILD/docs/STYLE_GUIDE.md`): poster cream
`#efe3c6` paper, warm black `#332822` ink, gold ochre `#a8823a` rules, and nine table colors from its ramps (poster cream,
sage, dusty rose, chrome yellow, Prussian blue, deep sage, plum, Prussian night, warm black). Self-test passes; screenshots
checked on poster cream and Prussian night.

## 2026-10-04 — Eric's first playtest: tray, tab variety, whimsical cut

Eric: "It's great for how little instruction you got!" Notes: on a phone his jigsaw keeps loose pieces in a two-row tray
along the bottom that slides left and right (4-6 pieces in view), swiped up onto the board; the tabs and blanks had no
variation; and he asked for a random or whimsical cut ("some bulbous protrusions and some spiky").

**Cuts** (`piece_shape.gd`, rewritten). The puzzle is now cut once as a lattice of corners plus one shared polyline per
inner edge, so neighbours always fit exactly whatever the shapes. *Classic*: straight grid, every tab different (place
along the edge, size, height, lean, neck). *Whimsical* (the default): inner corners wander up to 0.13 of a cell, so
pieces differ in size and lean; edges wave; tabs are round, bulbous, flat mushroom caps or spiky arrowheads. Blanks are
the neighbour's tab seen from the other side, so they vary the same way. A "Whimsical cut / Classic cut" menu re-cuts
the current picture; the choice is kept.

**Tray** (`tray.gd`, new). Two rows of loose pieces in a shuffled box order, on a paper shelf with the gold rule.
Swipe sideways to scroll (mouse wheel on a computer), swipe a piece up to lift it onto the board, drop a loose piece back
over the tray to put it away. In tray mode the view frames the board alone. On by default when the window is taller than
wide; the "Tray" button switches it and the choice is kept. Sized so a phone shows six pieces.

Verified by the self-test (both cuts, tray 49 -> 48 after a lift, tray off leaves nothing hidden, solve still ends in
one cluster) at 1280 x 800 and 450 x 900, screenshots looked at. Still to do for phones: the top bar is built for a
computer and is too small to tap on a phone; it needs its own compact layout.

**Help button (Eric, same day).** Paid jigsaws make you watch an ad for a hint, some "obnoxiously long and sticky". Here
Help shows one short panel about the project for 6 seconds on a paper card with the crab logo, a gold rule running
down; then one piece glides to its place (first choice: a piece that joins placed work; then a border piece). "Not now"
closes it without a hint. Panels come from `jigsaw/content/panels.json`, each with the source file for its facts, in a
fixed shuffle whose place is kept, so a player sees every panel before any repeats.

**Placed pieces lock (Eric: in his commercial jigsaw a placed piece locks down; "I'll let you decide what best game play
is").** Decision: anything that reaches its true place on the board locks and can no longer be dragged; the table stays
free-floating, so chunks can still be built on the side and carried in. Unlike the commercial game, an inside piece
dropped exactly on its spot locks too, without the border being done first: a right placement is right. Locked work
sits beneath loose pieces and glints once as it settles. Self-test: a placed piece cannot be picked up, a loose one can.

**A "Finished in 0:01" that was the self-test.** Eric saw a finish card reading 0:01 and thought I had done the puzzle;
I had. The self-test runs the real game in a real window, solves it programmatically and shows the finish card, so each
run popped up on his desktop (with a burst of music). Not a timing bug: his own rounds measured correctly. The self-test
now runs silent and off-screen (`--audio-driver Dummy --position -4000,-4000`), which still renders the screenshots.

**Whimsical cut reined in (Eric: "Some pieces are 1.5x the landmass of others ... You're not doing this all by
freehand, are you?").** I was: the corner wander and tab sizes were picked by eye and never measured. Now measured in
the self-test (`PieceShape.area_report`: worst largest-to-smallest piece area over 20 cuts of 49 pieces):

| step | whimsical, inside pieces | classic, inside pieces |
|---|---|---|
| as first built (coin-toss tabs, corners wander 0.13 cell) | 1.98 | 1.47 |
| tab directions balanced (greedy, then repair) | 1.37 | 1.23 |
| balanced exactly: Euler circuit, every inside piece two tabs and two blanks | 1.33 | 1.06 |
| every tab scaled to the same area (+-8 %) whatever its shape | 1.37 | 1.02 |
| S-waves only (area-neutral), corners wander 0.035 | **1.17** | **1.02** |

What it took: (1) real puzzles mostly give a piece two tabs and two blanks, and coin tosses don't; walking an Euler
circuit over the pieces and giving each edge's tab to the piece the walk leaves balances every inside piece exactly while
staying random. (2) A fat bulb holds several times a spike's picture, so each tab is scaled to one area. (3) A
one-hump wave bows a whole edge out; an S-wave goes out as much as in. Draradech's open-source generator (the common
reference) keeps the grid straight and jitters only the tab shapes, by 4 %; ours still lets corners wander a little,
since that is most of the whimsical look.

**Tab mix restored (Eric: exact two-and-two "is not acceptable. There has to be some 4 and 0 and also some 1 and 3").**
I had over-corrected. Now: balance by Euler circuit first, then flip one edge in five at random (`MIX_FLIP` 0.2), and
under each tab bow the edge gently into the piece that holds it, giving back 85 % of the tab's area (`BOW_SHARE`), the
way die-cut pieces are shaped, so a four-tab piece is not much bigger than a four-blank one. Measured over 20 cuts of
49 pieces (500 inside pieces per style):

| | tabs out 0 / 1 / 2 / 3 / 4 | worst largest / smallest |
|---|---|---|
| whimsical | 10 / 113 / 259 / 107 / 11 | 1.19 |
| classic | 10 / 101 / 286 / 92 / 11 | 1.06 |

(With a 60 % bow the same mix measured 1.27 and 1.16.)

**Cardboard rule for necks (Eric: no tab "with a neck so narrow that it would just tear off if it was real").** Every
tab's neck is now at least half as wide as the head it carries (`NECK_TO_HEAD` 0.5), arrowheads included. Measured over
the same 20 cuts per style: before, the narrowest neck was 0.058 of a cell and a quarter of its head's width
(whimsical; 0.082 and 0.36 classic); now 0.105 and one half in both cuts. Areas and the tab mix are unchanged
(1.19 / 1.06; same 0-4 tab counts).

**Music starts at a random piece (Eric: "start the music at a random time code ... so we don't always start with the
exact same few notes").** Not a random second, which would often land mid-phrase: `music/salon-loop-v1.starts.json`
holds the start of each of the loop's 20 pieces, computed from the Salon tracklist (piece lengths plus 2.5 s pauses;
all 20 agree with the tracklist's rounded times, and the computed 62.08 minutes matches the file's length to 0.3 s).
At launch the game picks one, starts a second before it inside the pause, and fades in over 2.5 s. Three launches
started at 951.8, 2126.5 and 3333.7 s, each exactly one second before a piece.

**Help waits for the reader; hints scale with the puzzle (Eric, same day).** The 6-second countdown now ends in a Done
button instead of closing the card, so someone reading can stay as long as they like; the hint comes on Done. "Not
now" is there during the countdown (no hint). One Help places about one piece per 24 (12 and 24 pieces: 1; 48: 2; 96:
4; 150: 6), a quarter second apart; pieces already gliding home are not picked twice. Self-test: Done hidden during the
countdown, shown after it with the card still open; one Help on the 49-piece puzzle took 26 clusters to 24. Found by
looking at the screenshot: a focused button drew its label in the engine's pale default, so "Done" was nearly
invisible; the theme now gives focused buttons the house green.

Design note, not built: "shells" earned for solving need no login or cookie for one player on one device; they would
sit in `user://` beside the settings (phone app storage until uninstall; browser storage on the web). Accounts and a
server only come in for shells that follow a player across devices, leaderboards, or shells worth cheating for.

**Classic cut, a little less geometric (Eric: "Even real cardboard stodgy puzzles have some variation").** Classic
had varied tabs but ruler-straight edges and square corners. Now: corners wander 0.015 of a cell (`CLASSIC_JITTER`),
edges carry a faint S-wave (0.006-0.016), and tabs vary a bit more in place (0.42-0.58), lean (+-0.035) and shape
(round to slightly oval, 0.86-1.14). Measured: worst largest/smallest 1.10 (was 1.06); necks still at least half
their heads; same tab mix.

## 2026-10-04 (overnight) — ready for a phone

Eric, going to sleep: "Yes, I have a droid so go ahead and build it ... If I 'wake up with my game ready' then we can
brag in the morning, right?" Done unattended; nothing below needed him.

**Phone layout.** On a tall screen the game lays itself out 480 units wide instead of 1280, so everything is about two
and a half times larger on a phone. The top bar keeps the title, progress, Help and a new Menu; the menu holds Daily,
New picture and the piece count (on a phone) plus cut, tray, table color, hint, music and About. On a computer the bar
keeps Daily, New picture and the count, and the full puzzle title now fits. Help and finish cards size to the screen.

**Zoom and pan.** Pinch with two fingers (a carried piece is put down first), the mouse wheel or a trackpad pinch on a
computer; drag the empty table to pan. Never further out than the whole table, never past four times in; at the
whole-table zoom the view cannot drift.

**Saved as you go.** After every move and whenever the app is put away, the puzzle is written to
`user://progress.json`: picture, count, seed, cut, and each cluster's pieces, position, lock and tray place. On launch
an unfinished puzzle comes back (rebuilt from its seed, then put back); finishing deletes it. Self-test: a half-done
puzzle rebuilt and restored has an identical layout. The self-test writes its own progress file, never the player's.

**Android Back** closes About, the menu or the Help card first, and only then saves and leaves.

**About and credits** (in the menu): Pagouro, pictures, music, piano sound, fonts and code licenses, then Godot's MIT
license, its third-party components and their license texts from the engine itself (reflowed to wrap on a phone).
Added the Apache 2.0 `LICENSE` file the README promised.

**Android build.** Toolchain fetched into `tools/` and checked: Godot 4.7.2 export templates (SHA-512 from the official
list; my first check reported a mismatch because the list has two template lines, the hashes were identical), Temurin
JDK 17.0.20.1 (SHA-256 from Adoptium), Android command-line tools (SHA-1 from Google's index), build-tools 36.1.0 and
platform 36. Google's `sdkmanager` now announces it is deprecated and silently installed nothing; the new `android`
tool did it. Android's batch tools break on the space in the user folder, so their paths go in as 8.3 short names.
Exports run from a self-contained Godot copy so nothing touches `%APPDATA%\Godot`, which Summer Engine shares.

First APK: 109.5 MB. Two causes: a 32-bit engine copy (29 MB; dropped, every current phone and Play require 64-bit)
and the pictures imported lossless (29 MB; now lossy at 0.9, no visible difference in the finished-picture screenshot).
Result: **57.5 MB**, package `com.pagouro.jigsaw`, version 0.1.0, min Android 7.0, target Android 16, arm64, **no
permissions**, launcher icon the hermit crab from the Pagouro mark (cropped above the lettering). The crab also
replaces Godot's logo on the boot screen.

**Found by looking at screenshots, fixed:** the finish card ballooned off the top of the screen (a word-wrapping label
with no width yet measures absurdly tall; it now has a width from the start and is measured a frame later); and a
duplicated block of declarations when I applied a patch script twice (Godot refused to parse; removed).

Not tested: a real phone. An emulator needs a hypervisor driver, and installs of that kind wait for Eric.

## 2026-10-04 (day) — Eric plays it on his Pixel; 0.1.1 to 0.2.3

Installed over USB (adb) on Eric's Pixel 11 Pro XL (Android 17) and iterated from his play. Every build: self-test at
405x880 and 1280x800, Android export, install, version bumped in BOTH `project.godot` and `export_presets.cfg`,
APK replaced on the private prerelease `android-test-0.1.0`.

- 0.1.1: a close mark on every card and menu; phone title on its own row; hint picture off by default; "no third-party
  ads" (reverted in 0.1.2); license text reflow fixed (a heredoc had turned "\r" into a real newline, so words ran together).
- 0.1.2: "No ads" made true by Google Play's definition (third-party ad SDKs, display/banner ads, house ads promoting
  your own apps): the 8 call-to-action Help panels left the timed card (152 -> 144); where to find Pagouro is one line in
  About; no sponsorship ask in the app.
- 0.1.3: smooth cut edges. Polygon2D antialiasing does nothing in GL Compatibility and 2D MSAA is unsupported (tested in
  a side-by-side project), so each piece gets a 16-sample mask baked at puzzle start (`piece_masks.gd`, force_draw through
  RenderingServer canvas items; 0.2 s for 49 pieces on the PC, 0.9-1.0 s for 156 on the Pixel) and `piece.gdshader` cuts
  the picture with it and draws the ink cut line. Seams close when joined (alpha opaque from the true edge in) and vanish
  when finished. Version shown in About.
- 0.1.4-0.1.6, 0.2.1: Help wording: every Pagouro Salon / Pagouro BE / text-model mention says what it is; "the name
  Pagouro"; "from any folder, even a USB stick" (checked against both release READMEs and launchers).
- 0.1.7: classic tabs 25 % larger in area; self-test now measures tab reach and outline validity (0 invalid of 980).
- 0.1.8: true piece counts 12/25/49/100/156 (150 was always 12 x 13); Help scales by pieces left past halfway
  (156 pieces: 7, 7, 3, 1 at 156/78/40/10 left); gold light around a finished border; soft pulse on attached pieces and a
  click synthesized in code (Menu: Sounds).
- 0.1.9: Help picks at random like a friend would (border first, then pieces that fit placed work, spread apart); new
  icon: the crab medallion cut in four, one piece loose (`tools_src/make_icons.py`, 192/256/512 + adaptive).
- 0.2.0: Rotation (Menu, off by default): quarter turns, tap or right-click turns, joins need the same facing, locks need
  upright (a turned piece exactly at home used to lock: fixed via `_is_home`), Help turns pieces upright, saved/restored.
- 0.2.2: the sponsor line drops to the bottom when the tray goes at the finish (Eric saw the picture over it). The
  self-test now finishes with the tray on and shoots the closed-card view; the rotation test had been placed between the
  solve and the finish screenshots, so those shots showed the wrong puzzle for two versions.
- 0.2.3: last tray pieces would not come out on a diagonal drag (read as a scroll of a tray that could not scroll).
  Reproduced on the phone, fixed with `Tray.decide` (lift within ~60 degrees of up, any direction when nothing scrolls).
  The self-test's simulated fingers were in layout units, not window pixels, so its touch checks were void until fixed.

Mistake to remember: an adb test swipe went to the phone while Eric had Telegram open and landed on his keyboard. Never
send adb input without checking the foreground app first.

## 2026-10-04 (afternoon) — 0.2.4: ready for Google Play

- Summer Engine thanked in About and the README (Eric: a fair rep, not overdone).
- Release (upload) key made outside every repo: `%USERPROFILE%\.ssh\pagouro-jigsaw-release.keystore`, password in the
  `.password.txt` beside it (generated, never printed). Cert SHA-256 89:05:8D:…:68:BB:22. Eric to back both up offline.
- Play bundle: second preset "Android Play" (Gradle build, AAB), built by `tools_src/build_aab.py` (keys through env vars
  only; Gradle cache in `tools/gradle-home`; build template in the ignored `jigsaw/android/`). First run 12 min of
  downloads; later runs 34 s. A Gradle daemon left running held Godot's output open, so the script turns the daemon off.
- Verified the release build itself: bundletool 1.18.3 made device APKs; with Eric's go-ahead the USB test build was
  removed and the release installed on his Pixel; it runs (49 masks in 823 ms, no errors).
- Store kit in `store/`: PLAY_STORE.md (listing text, form answers, release path), jigsaw-privacy.html (for pagouro.com,
  not published), feature_graphic.png, screenshots/phone_1..5.png (from the new `-- --shots` mode).
- Pagouro Salon backed up: private repo ericrwade/pagouro-salon (code and docs) plus a private release holding the B2L
  model and loop v2 (checksums verified by download).


## 2026-10-05 — 0.2.5, 160 pictures, and the first purchase by an agent

- 0.2.5 (code 16) adds 130 Belle Époque pictures, for 160 in all. The first bundle was 178 MB because the new pictures
  imported lossless (Godot's project default), while the first 30 had been set to lossy 0.9. Matching them brought the
  bundle to 82 MB. Release `play-0.2.5`, checksum verified by download, installed on Eric's Pixel. Eric, the next
  morning, over coffee: "a beautiful, very satisfying experience".
- Eric set a task: find an honest reason for an agentic x402 payment (HTTP 402, paid in USDC on Base) that touches
  Pagouro. The answer was market research for the store listing.
  - Claude made its own wallet. The key stays on this box and Eric deliberately doesn't hold it.
  - Eric sent ETH and a token (VCTRAI), which was sold for 8.468 USDC.
  - Thirteen calls to a Google Play data service at 0.003 USDC each bought 1,185 reviews of eight leading jigsaw
    apps, for 0.039 USDC in total.
- Findings are in `store/MARKET_RESEARCH_2026-10-05.md`:
  - Ads come up in 63.5 % of one- and two-star reviews, in every app.
  - 25 of the top 30 apps show ads and collect data.
  - A small, loud minority objects to AI art.
- Mistake, kept in: Claude first told Eric that every free app in the top 30 had ads, having read only 20 of the 30
  rows. Five are ad-free (one paid, three for children, one small). The memo and the report carry the correction.
- The first choice of service, x402Atlas, turned out to be blocked by Eric's internet provider's security filter.
  It looked like a broken TLS server until a plain-HTTP request redirected to the filter's warning page.
- The payment tools became an `x402` Claude Code skill: free catalog search, a free price probe, and one shared
  ledger enforcing Eric's 1.00 USDC cap. Mirrored in `tools_src/`.
- Google Play: the identity check restarted after Eric found that the driver's license he first uploaded had expired.

## 2026-10-05 (evening): 0.2.7 / code 18, Share button

- Eric got the closed-test build from Play (Early Access listing, 70.71 MB download).
- Asked for a share like the Wordle/Connections results his mom posts in the family chat. The finish card now has
  **Share**: it copies `Jigsaw by Pagouro #278 🧩 / 49 pieces in 4:12 / pagouro.com` (the daily gets a number and no
  picture name, so nothing is spoiled; other puzzles name the picture). Godot has no Android share sheet, so it is the
  clipboard ("Copied! Paste it in a chat"); a real share sheet would need an Android plugin.
- The daily now turns over at the player's LOCAL midnight (it was UTC, i.e. 5 pm in California). Number #1 = 2026-01-01.
- Piece count comes from the built puzzle (asked 48 can build 49).
- Self-test: `share (daily=true, copied=true): Jigsaw by Pagouro #278 🧩 | 49 pieces in 0:09 | pagouro.com`.
- AAB sha256 a908968a…, signed with the release key. NOT uploaded to Play yet (Eric's call when).
