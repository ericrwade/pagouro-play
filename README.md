# Pagouro Play

Free games sponsored by Pagouro (decision S-4 in `PAGOURO_SALON/docs/DECISIONS.md`). No ads, no tracking, no account, no
paid unlock: one quiet line says the game is free thanks to Pagouro.

## Pagouro Jigsaw (`jigsaw/`)

A jigsaw puzzle of Belle Époque posters drawn by [Pagouro BE](https://github.com/ericrwade/pagouro-be), with the
Pagouro Salon piano loop playing softly underneath.

- **Daily puzzle**: the same picture for every player each day, 48 pieces, chosen from the date by a fixed shuffle
  (works offline, no server).
- **Any picture**: 30 pictures bundled; 12, 24, 48, 96 or 150 pieces; classic interlocking shapes cut from a seed.
- **Play**: drag pieces; neighbors that fit join, and the picture snaps into the frame. A faint hint image can be turned off.
- **Music**: the 62-minute Pagouro Salon loop, version 1, mono Vorbis, looping; a button turns it off.

Built with Godot 4.7.2, the engine Summer Engine is built on, so the project can move into Summer later. It runs as a
separate program and never touches the Summer Engine editor.

```
PLAY-JIGSAW.bat                                         play it on this PC
tools\godot\Godot_v4.7.2-stable_win64_console.exe --path jigsaw -- --selftest
                                                        build, solve, screenshot, quit (screenshots in %APPDATA%\Godot\app_userdata\Pagouro Jigsaw)
```

`tools/` (the Godot binary, verified against the official SHA-512 list) is not in the repository.

## Licenses

Fonts: Cormorant Garamond and EB Garamond, SIL Open Font License 1.1 (license texts in `jigsaw/fonts/`). Code: Apache 2.0. Pictures: CC0 1.0 (drawn by Pagouro BE; prompts and seeds in `jigsaw/art/be/pictures.json`). Music:
CC0 1.0 (composed by Pagouro Salon round 1, rendered with the CC0 Upright Piano KW SoundFont; tracklist in
`jigsaw/music/salon-loop-v1.tracklist.json`).
