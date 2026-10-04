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
