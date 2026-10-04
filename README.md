# Pagouro Play

Free games sponsored by Pagouro (decision S-4 in `PAGOURO_SALON/docs/DECISIONS.md`). No third-party ads, no tracking, no account, no
paid unlock: one quiet line says the game is free thanks to Pagouro.

## Pagouro Jigsaw (`jigsaw/`)

A jigsaw puzzle of Belle Époque posters drawn by [Pagouro BE](https://github.com/ericrwade/pagouro-be), with the
Pagouro Salon piano loop playing softly underneath. Runs on Windows and Android (a test build; not in any store yet).

- **Daily puzzle**: the same picture for every player each day, 48 pieces, chosen from the date by a fixed shuffle
  (works offline, no server).
- **Any picture**: 30 pictures bundled; 12, 24, 48, 96 or 150 pieces.
- **Two cuts**: *Whimsical* (the default: corners off the grid, waving edges, round, bulbous, cap and arrowhead tabs) and
  *Classic* (a traditional die-cut look with mild hand-cut variation). Piece sizes are held close and measured by the
  self-test; every tab's neck is at least half its head's width (the cardboard rule).
- **Play**: drag pieces; neighbors that fit join; anything in its true place on the board locks. Drag the empty table
  to pan; pinch (phone) or the mouse wheel (computer) to zoom.
- **Tray**: on a phone, loose pieces wait in a two-row tray along the bottom; swipe sideways to browse, swipe a piece up.
- **Help**: a few seconds of one short panel about the project (152 of them, each with the source of its facts in
  `jigsaw/content/panels.json`), then a Done button and a hint that places about one piece per 24.
- **Table colors**: nine, all from the locked Belle Époque house palette (D-74).
- **Music**: the 62-minute Pagouro Salon loop, starting at a random piece each launch.
- **Saved as you go**: the puzzle in progress survives the app being closed.
- **Phones**: a 480-wide layout on tall screens, a Menu for the settings, About with every credit and license, and the
  Android Back button closes cards and menus before leaving.

Built with Godot 4.7.2, the engine Summer Engine is built on, so the project can move into Summer later. It runs as a
separate program and never touches the Summer Engine editor or its settings.

```
PLAY-JIGSAW.bat                                         play it on this PC
tools\godot\Godot_v4.7.2-stable_win64_console.exe --path jigsaw --audio-driver Dummy --position -4000,-4000 -- --selftest
                                                        build, solve, measure, screenshot, quit, silently and off-screen
                                                        (screenshots in %APPDATA%\Godot\app_userdata\Pagouro Jigsaw)
tools\godot-export\Godot_v4.7.2-stable_win64_console.exe --headless --path jigsaw --export-debug "Android" ../build/pagouro-jigsaw.apk
                                                        the Android test build (see docs/HANDOFF.md for the toolchain)
```

`tools/` (Godot, its export templates, Java 17 and the Android SDK, each verified against its published checksum) and
`build/` are not in the repository.

## Licenses

Code: Apache 2.0 (`LICENSE`). Fonts: Cormorant Garamond and EB Garamond, SIL Open Font License 1.1 (license texts in
`jigsaw/fonts/`). Pictures: CC0 1.0 (drawn by Pagouro BE; prompts and seeds in `jigsaw/art/be/pictures.json`). Music:
CC0 1.0 (composed by Pagouro Salon round 1, rendered with the CC0 Upright Piano KW SoundFont; tracklist in
`jigsaw/music/salon-loop-v1.tracklist.json`). Engine: Godot, MIT; its license and third-party notices are shown in the
game under Menu, About and credits.
