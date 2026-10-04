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
const EPOCH_DAY := 20454  # 2026-01-01 as days since 1970-01-01 (UTC); day 0 of the daily list

var pictures: Array = []
var current := {}
var current_count := DAILY_COUNT
var is_daily := true

@onready var puzzle: Puzzle = $Puzzle
@onready var music: AudioStreamPlayer = $Music
var title_label: Label
var status_label: Label
var count_button: OptionButton
var music_button: Button
var ghost_button: Button
var table_button: OptionButton
var sponsor_label: Label
var finish_panel: PanelContainer
var finish_label: Label


func _ready() -> void:
	pictures = JSON.parse_string(FileAccess.get_file_as_string(PICTURES))
	_build_ui()
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	var table_index := int(cfg.get_value("play", "table", 0))
	table_button.select(clampi(table_index, 0, TABLES.size() - 1))
	_set_table(clampi(table_index, 0, TABLES.size() - 1), false)
	puzzle.solved.connect(_on_solved)
	puzzle.progress.connect(_on_progress)
	var stream: AudioStream = load(MUSIC)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	music.stream = stream
	music.volume_db = -14.0
	music.play()
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
	finish_panel.visible = false
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
	# below the finished picture, so the picture stays in view
	var view := get_viewport().get_visible_rect().size
	finish_panel.reset_size()
	finish_panel.position = Vector2((view.x - finish_panel.size.x) * 0.5, view.y - finish_panel.size.y - 44)
	puzzle.focus_board(finish_panel.size.y + 52)


func _selftest() -> void:
	var report := []
	for n in [12, 48]:
		current = pictures[today_index()]
		current_count = n
		_start(42)
		report.append("built %d asked -> %d pieces (%dx%d)" % [n, puzzle.piece_total(), puzzle.cols, puzzle.rows])
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_scattered.png")
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
	puzzle.solve_all_for_test()
	report.append("after solve: %d cluster(s), solved=%s" % [puzzle.clusters.size(), str(puzzle.is_solved)])
	await get_tree().create_timer(1.5).timeout  # let the seams fade
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_solved.png")
	report.append("daily index today: %d (%s)" % [today_index(), pictures[today_index()].caption])
	report.append("screenshots in " + ProjectSettings.globalize_path("user://"))
	print("SELFTEST " + " | ".join(report))
	get_tree().quit()
