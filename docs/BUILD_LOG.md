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
