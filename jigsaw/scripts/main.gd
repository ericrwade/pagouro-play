extends Node
## Pagouro Jigsaw: the screen around the puzzle. Picks the picture (today's daily, or a random one), sets the piece
## count, plays the Pagouro Salon loop, shows the "free, thanks to Pagouro" line and the finished card.
## Run with `-- --selftest` to build a puzzle, solve it programmatically, save a screenshot and quit (no player input).

const PICTURES := "res://art/be/pictures.json"
const MUSIC := "res://music/salon-loop-v1.ogg"
const COUNTS := [12, 24, 48, 96, 150]
const DAILY_COUNT := 48
## Table colours to play on, so a picture never disappears into its background (Eric, 2026-10-03). Every one is a
## colour of the locked D-74 house palette (Belle Epoque poster), light to dark; the choice is kept between sessions.
const TABLES := [
	["Poster cream", Color("efe3c6")], ["Sage", Color("c3ceae")], ["Dusty rose", Color("ecc3c6")], ["Chrome yellow", Color("f8dd6a")],
	["Prussian blue", Color("2d6fa0")], ["Deep sage", Color("3a4a34")], ["Plum", Color("7a3c4a")], ["Prussian night", Color("0e2a44")], ["Warm black", Color("1a1410")],
]
const SETTINGS := "user://settings.cfg"
const PANELS := "res://content/panels.json"
const EPOCH_DAY := 20454  # 2026-01-01 as days since 1970-01-01 (UTC); day 0 of the daily list

var pictures: Array = []
var current := {}
var current_count := DAILY_COUNT
var is_daily := true
var current_seed := 0

@onready var puzzle: Puzzle = $Puzzle
@onready var music: AudioStreamPlayer = $Music
var title_label: Label
var status_label: Label
var count_button: OptionButton
var music_button: Button
var ghost_button: Button
var table_button: OptionButton
var sponsor_label: Label
var cut_button: OptionButton
var tray_button: Button
var tray_panel: Tray
var help_card: HelpCard
var panels: Array = []
var finish_panel: PanelContainer
var finish_label: Label


func _ready() -> void:
	pictures = JSON.parse_string(FileAccess.get_file_as_string(PICTURES))
	if FileAccess.file_exists(PANELS):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PANELS))
		if parsed is Array:
			panels = parsed
	if panels.is_empty():
		panels = [{"title": "Free, thanks to Pagouro", "text": "Follow us on X @pagouro."}]
	_build_ui()
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	var table_index := int(cfg.get_value("play", "table", 0))
	table_button.select(clampi(table_index, 0, TABLES.size() - 1))
	_set_table(clampi(table_index, 0, TABLES.size() - 1), false)
	var cut_index := clampi(int(cfg.get_value("play", "cut", 0)), 0, 1)
	cut_button.select(cut_index)
	puzzle.cut_style = PieceShape.Style.WHIMSICAL if cut_index == 0 else PieceShape.Style.CLASSIC
	# the tray starts on for a tall (phone-shaped) window, off for a wide one; the player's choice is kept
	var view := get_viewport().get_visible_rect().size
	var tray_on := bool(cfg.get_value("play", "tray", view.y > view.x))
	tray_button.set_pressed_no_signal(tray_on)
	_set_tray(tray_on, false)
	get_viewport().size_changed.connect(_layout_tray)
	puzzle.solved.connect(_on_solved)
	puzzle.progress.connect(_on_progress)
	var stream: AudioStream = load(MUSIC)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	music.stream = stream
	# start at a random piece of the loop, not always the same opening notes (Eric, 2026-10-04): a second before the piece,
	# inside the 2.5 s pause, with a short fade in
	var start := 0.0
	var starts_file := MUSIC.get_basename() + ".starts.json"
	if FileAccess.file_exists(starts_file):
		var info = JSON.parse_string(FileAccess.get_file_as_string(starts_file))
		if info is Dictionary and info.get("starts", []).size() > 0:
			start = max(0.0, float(info.starts.pick_random()) - 1.0)
	music.volume_db = -40.0
	music.play(start)
	create_tween().tween_property(music, "volume_db", -14.0, 2.5)
	if "--selftest" in OS.get_cmdline_user_args():
		_selftest.call_deferred()
	else:
		start_daily()


func today_index() -> int:
	var day := int(Time.get_unix_time_from_system() / 86400.0) - EPOCH_DAY
	# a fixed shuffle of the list, so consecutive days are not consecutive pictures; same for every player
	var order := range(pictures.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1888  # the year of the first Gymnopédie
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = order[i]; order[i] = order[j]; order[j] = t
	return order[posmod(day, order.size())]


func start_daily() -> void:
	is_daily = true
	current = pictures[today_index()]
	current_count = DAILY_COUNT
	_select_count(DAILY_COUNT)
	_start(int(Time.get_unix_time_from_system() / 86400.0))


func start_random() -> void:
	is_daily = false
	current = pictures[randi() % pictures.size()]
	_start(randi())


func _start(seed_value: int) -> void:
	current_seed = seed_value
	finish_panel.visible = false
	tray_panel.visible = puzzle.tray_mode
	_select_count(current_count)
	var tex: Texture2D = load(current.file)
	puzzle.build(tex, current_count, seed_value)
	title_label.text = ("Today's puzzle: " if is_daily else "") + String(current.caption).capitalize()


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = BelleStyle.theme()
	ui.add_child(root)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size.y = 56
	# paper bar with a thin gold rule beneath and an ink hairline under that
	var bar_style := BelleStyle.box(BelleStyle.PAPER_DEEP, BelleStyle.GOLD, 0, 0, Vector4(14, 8, 14, 8))
	bar_style.border_width_bottom = 2
	top.add_theme_stylebox_override("panel", bar_style)
	root.add_child(top)
	var hairline := ColorRect.new()
	hairline.color = Color(BelleStyle.INK, 0.35)
	hairline.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hairline.offset_top = 59
	hairline.offset_bottom = 60
	hairline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hairline)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	top.add_child(bar)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_font_override("font", BelleStyle.title_font())
	title_label.add_theme_font_size_override("font_size", 24)
	bar.add_child(title_label)
	status_label = Label.new()
	bar.add_child(status_label)
	var help := Button.new()
	help.text = "Help"
	help.tooltip_text = "A few seconds about Pagouro, then a piece finds its place"
	help.pressed.connect(_on_help)
	bar.add_child(help)
	var daily := Button.new()
	daily.text = "Daily"
	daily.pressed.connect(start_daily)
	bar.add_child(daily)
	var random_button := Button.new()
	random_button.text = "New picture"
	random_button.pressed.connect(start_random)
	bar.add_child(random_button)
	count_button = OptionButton.new()
	for n in COUNTS:
		count_button.add_item("%d pieces" % n)
	count_button.item_selected.connect(func(i):
		current_count = COUNTS[i]
		is_daily = false
		_start(randi()))
	bar.add_child(count_button)
	cut_button = OptionButton.new()
	cut_button.add_item("Whimsical cut")
	cut_button.add_item("Classic cut")
	cut_button.item_selected.connect(_set_cut)
	bar.add_child(cut_button)
	tray_button = Button.new()
	tray_button.text = "Tray"
	tray_button.toggle_mode = true
	tray_button.tooltip_text = "Keep loose pieces in a tray along the bottom (best on a phone)"
	tray_button.toggled.connect(_set_tray)
	bar.add_child(tray_button)
	table_button = OptionButton.new()
	for t in TABLES:
		var swatch := Image.create(14, 14, false, Image.FORMAT_RGBA8)
		swatch.fill(t[1])
		table_button.add_icon_item(ImageTexture.create_from_image(swatch), t[0])
	table_button.tooltip_text = "Table colour"
	table_button.fit_to_longest_item = false
	table_button.custom_minimum_size.x = 130
	table_button.item_selected.connect(_set_table)
	bar.add_child(table_button)
	ghost_button = Button.new()
	ghost_button.text = "Hint on"
	ghost_button.toggle_mode = true
	ghost_button.button_pressed = true
	ghost_button.toggled.connect(func(on):
		puzzle.set_ghost(on)
		ghost_button.text = "Hint on" if on else "Hint off")
	bar.add_child(ghost_button)
	music_button = Button.new()
	music_button.text = "Music on"
	music_button.toggle_mode = true
	music_button.button_pressed = true
	music_button.toggled.connect(func(on):
		music.stream_paused = not on
		music_button.text = "Music on" if on else "Music off")
	bar.add_child(music_button)
	# the only "ad": one quiet line at the bottom
	var sponsor := Label.new()
	sponsor_label = sponsor
	sponsor.text = "Free, thanks to Pagouro · pictures by Pagouro BE, music by Pagouro Salon · pagouro.com"
	sponsor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sponsor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sponsor.offset_top = -30
	sponsor.add_theme_font_size_override("font_size", 15)
	sponsor.add_theme_color_override("font_color", BelleStyle.INK_SOFT)
	sponsor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sponsor)
	tray_panel = Tray.new()
	tray_panel.puzzle = puzzle
	tray_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tray_panel.visible = false
	root.add_child(tray_panel)
	help_card = HelpCard.new()
	root.add_child(help_card)
	help_card.finished.connect(func(give): if give: puzzle.hint())
	finish_panel = PanelContainer.new()
	finish_panel.set_anchors_preset(Control.PRESET_CENTER)
	finish_panel.visible = false
	# a paper card with a gold double edge: the outer border here, the inner rule drawn by the margin container below
	finish_panel.add_theme_stylebox_override("panel", BelleStyle.box(BelleStyle.PAPER, BelleStyle.GOLD, 2, 2, Vector4(6, 6, 6, 6)))
	root.add_child(finish_panel)
	var inner := PanelContainer.new()
	inner.add_theme_stylebox_override("panel", BelleStyle.box(BelleStyle.PAPER, Color(BelleStyle.INK, 0.45), 1, 1, Vector4(28, 18, 28, 18)))
	finish_panel.add_child(inner)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	inner.add_child(box)
	finish_label = Label.new()
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.add_theme_font_override("font", BelleStyle.title_font())
	finish_label.add_theme_font_size_override("font_size", 34)
	finish_label.add_theme_color_override("font_color", BelleStyle.GREEN)
	box.add_child(finish_label)
	var credit := Label.new()
	credit.text = "This picture was drawn by Pagouro BE, a free image model that runs offline.\nNot every picture it draws is a masterpiece; this one made the cut."
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size", 17)
	box.add_child(credit)
	var again := Button.new()
	again.text = "Another picture"
	again.pressed.connect(start_random)
	box.add_child(again)


func _set_table(i: int, save := true) -> void:
	var c: Color = TABLES[i][1]
	puzzle.set_table_color(c)
	# the sponsor line sits on the table: ink on light tables, paper on dark ones
	sponsor_label.add_theme_color_override("font_color", BelleStyle.INK_SOFT if c.get_luminance() > 0.45 else Color(BelleStyle.PAPER, 0.8))
	if save:
		var cfg := ConfigFile.new()
		cfg.load(SETTINGS)
		cfg.set_value("play", "table", i)
		cfg.save(SETTINGS)


## Whimsical or classic pieces; the current picture is cut again from the start.
func _set_cut(i: int) -> void:
	puzzle.cut_style = PieceShape.Style.WHIMSICAL if i == 0 else PieceShape.Style.CLASSIC
	_save("cut", i)
	if not current.is_empty():
		_start(current_seed)


func _set_tray(on: bool, save := true) -> void:
	if save:
		_save("tray", on)
	_layout_tray()
	puzzle.set_tray_mode(on)
	tray_panel.visible = on and not puzzle.is_solved
	_layout_tray()


## Size the tray so a phone shows about six pieces (two rows of three) and a computer a longer shelf.
func _layout_tray() -> void:
	var view := get_viewport().get_visible_rect().size
	var slot: float = min(view.x / 3.2, view.y * 0.15)
	var height := slot * Tray.ROWS + 8.0
	var on := tray_button.button_pressed
	tray_panel.offset_top = -height
	tray_panel.offset_bottom = 0
	puzzle.tray_height = height if on else 0.0
	# the sponsor line sits just above the tray when there is one
	sponsor_label.offset_top = -30 - (height if on else 0.0)
	sponsor_label.offset_bottom = -(height if on else 0.0)


## The next panel. The very first Help a player ever presses shows the panel marked "first" (Eric, 2026-10-04: the
## first one says most of this was built with AI); after that, a fixed shuffle of the rest whose place is kept, so a
## player sees every panel before any repeats.
func next_panel() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	var n := int(cfg.get_value("play", "help_next", 0))
	if not bool(cfg.get_value("play", "help_intro_seen", false)):
		for p in panels:
			if p.get("first", false):
				_save("help_intro_seen", true)
				return p
	var rest := panels.filter(func(p): return not p.get("first", false))
	if rest.is_empty():
		rest = panels
	var order := range(rest.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1900  # the Paris Exposition Universelle
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = order[i]; order[i] = order[j]; order[j] = t
	_save("help_next", (n + 1) % rest.size())
	return rest[order[n % rest.size()]]


func _on_help() -> void:
	if puzzle.is_solved or help_card.visible or puzzle.texture == null:
		return
	help_card.show_panel(next_panel())


func _save(key: String, value) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("play", key, value)
	cfg.save(SETTINGS)


func _select_count(n: int) -> void:
	var i := COUNTS.find(n)
	if i >= 0:
		count_button.select(i)


func _on_progress(joined: int, total: int) -> void:
	status_label.text = "%d / %d" % [joined, total]


func _on_solved(seconds: float) -> void:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	finish_label.text = "Finished in %d:%02d" % [m, s]
	finish_panel.visible = true
	tray_panel.visible = false
	# below the finished picture, so the picture stays in view
	var view := get_viewport().get_visible_rect().size
	finish_panel.reset_size()
	finish_panel.position = Vector2((view.x - finish_panel.size.x) * 0.5, view.y - finish_panel.size.y - 44)
	puzzle.focus_board(finish_panel.size.y + 52)


func _selftest() -> void:
	var report := []
	report.append("music at %.1f s of the loop" % music.get_playback_position())
	for style in [PieceShape.Style.WHIMSICAL, PieceShape.Style.CLASSIC]:
		var worst := [0.0, 0.0]
		var mix := [0, 0, 0, 0, 0]
		PieceShape.neck_stats = [9.0, 9.0]
		for sd in range(20):
			var ar := PieceShape.area_report(7, 7, 1000 + sd, style)
			worst = [max(worst[0], ar[0]), max(worst[1], ar[1])]
			for i in range(5):
				mix[i] += ar[2][i]
		report.append("%s areas, worst of 20 cuts at 49 pieces: inside largest/smallest %.2f, all %.2f, inside pieces by tabs out 0/1/2/3/4: %s of 500" % ["whimsical" if style == PieceShape.Style.WHIMSICAL else "classic", worst[0], worst[1], str(mix)])
		report.append("  narrowest neck %.3f cell, smallest neck/head %.2f" % [PieceShape.neck_stats[0], PieceShape.neck_stats[1]])
	for n in [12, 48]:
		current = pictures[today_index()]
		current_count = n
		_start(42)
		report.append("built %d asked -> %d pieces (%dx%d)" % [n, puzzle.piece_total(), puzzle.cols, puzzle.rows])
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_scattered.png")
	puzzle.cut_style = PieceShape.Style.CLASSIC
	_start(42)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_classic.png")
	puzzle.cut_style = PieceShape.Style.WHIMSICAL
	_start(42)
	tray_button.set_pressed_no_signal(true)
	_set_tray(true, false)
	var before := puzzle.tray.size()
	var lifted: Node2D = puzzle.tray[0]
	puzzle.begin_drag_from_tray(lifted, Vector2(640, 300))
	puzzle.end_drag(Vector2(640, 300))
	report.append("tray %d -> %d after one lift, lifted piece visible=%s" % [before, puzzle.tray.size(), str(lifted.visible)])
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_tray.png")
	tray_button.set_pressed_no_signal(false)
	_set_tray(false, false)
	report.append("tray off: %d in tray, %d hidden" % [puzzle.tray.size(), puzzle.clusters.filter(func(c): return not c.visible).size()])
	_set_table(7, false)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_night.png")
	_set_table(0, false)
	# join about half of the pieces, then shoot again
	var half := puzzle.clusters.slice(0, puzzle.clusters.size() / 2)
	for c in half:
		if is_instance_valid(c) and puzzle.clusters.has(c):
			c.position = Vector2.ZERO
			puzzle._settle(c)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_half.png")
	var locked: Array = puzzle.clusters.filter(func(c): return c.has_meta("locked"))
	var loose: Array = puzzle.clusters.filter(func(c): return not c.has_meta("locked"))
	var probe: Node2D = locked[0]
	var grab_locked = puzzle._cluster_at(probe.position + probe.get_child(0).get_meta("centre"))
	var free: Node2D = loose[0]
	var grab_loose = puzzle._cluster_at(free.position + free.get_child(0).get_meta("centre"))
	report.append("locked clusters %d, placed piece grabbable=%s, loose piece grabbable=%s" % [locked.size(), str(grab_locked != null), str(grab_loose == free)])
	help_card.show_panel(panels[0])
	var keep_settings := FileAccess.get_file_as_string(SETTINGS)
	_save("help_intro_seen", false)
	report.append("first help panels: %s, %s" % [next_panel().get("id"), next_panel().get("id")])
	var f := FileAccess.open(SETTINGS, FileAccess.WRITE)
	f.store_string(keep_settings)
	f.close()
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_help.png")
	help_card._end(false)
	var before_hint := puzzle.clusters.size()
	var hinted := puzzle.hint()
	await get_tree().create_timer(1.2).timeout
	report.append("hint given=%s clusters %d -> %d" % [str(hinted), before_hint, puzzle.clusters.size()])
	report.append("%d help panels" % panels.size())
	puzzle.solve_all_for_test()
	report.append("after solve: %d cluster(s), solved=%s" % [puzzle.clusters.size(), str(puzzle.is_solved)])
	await get_tree().create_timer(1.5).timeout  # let the seams fade
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_solved.png")
	report.append("daily index today: %d (%s)" % [today_index(), pictures[today_index()].caption])
	report.append("screenshots in " + ProjectSettings.globalize_path("user://"))
	print("SELFTEST " + " | ".join(report))
	get_tree().quit()
