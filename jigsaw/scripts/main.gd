extends Node
## Jigsaw by Pagouro: the screen around the puzzle. Picks the picture (today's daily, or a random one), sets the piece
## count, plays the Pagouro Salon loop, shows the "free, thanks to Pagouro" line and the finished card.
## Run with `-- --selftest` to build a puzzle, solve it programmatically, save a screenshot and quit (no player input).

const PICTURES := "res://art/be/pictures.json"
const MUSIC := "res://music/salon-loop-v1.ogg"
## Pieces on offer, as the true counts the grid gives a square picture (Eric, 2026-10-04: "is that a true 150? because
## it seems like 156"). Near-square pieces can't make every number: 150 would be 12 x 12.5.
const COUNTS := [12, 25, 49, 100, 156]
const DAILY_COUNT := 49
## Table colours to play on, so a picture never disappears into its background (Eric, 2026-10-03). Every one is a
## colour of the locked D-74 house palette (Belle Epoque poster), light to dark; the choice is kept between sessions.
const TABLES := [
	["Poster cream", Color("efe3c6")], ["Sage", Color("c3ceae")], ["Dusty rose", Color("ecc3c6")], ["Chrome yellow", Color("f8dd6a")],
	["Prussian blue", Color("2d6fa0")], ["Deep sage", Color("3a4a34")], ["Plum", Color("7a3c4a")], ["Prussian night", Color("0e2a44")], ["Warm black", Color("1a1410")],
]
const SETTINGS := "user://settings.cfg"
## The puzzle in progress, saved after every move and whenever the app is put away, so a phone that closes the app in
## the background never loses a half-done puzzle.
const PROGRESS := "user://progress.json"
const PANELS := "res://content/panels.json"
const EPOCH_DAY := 20454  # 2026-01-01 as days since 1970-01-01 (UTC); day 0 of the daily list

var pictures: Array = []
var current := {}
var current_count := DAILY_COUNT
var daily_count := DAILY_COUNT  # the player's own size for the daily, remembered (Eric, 2026-10-05: "start it at 100")
var is_daily := true
var current_seed := 0

@onready var puzzle: Puzzle = $Puzzle
@onready var music: AudioStreamPlayer = $Music
var title_label: Label
var top_panel: PanelContainer
var top_rows: VBoxContainer
var hairline: ColorRect
var status_label: Label
var count_button: OptionButton
var music_button: Button
var sounds_button: Button
var rotation_button: Button
var click: AudioStreamPlayer
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
var finish_credit: Label
var share_button: Button
var solved_seconds := 0.0
var bar: HBoxContainer
var daily_button: Button
var random_button: Button
var menu_button: Button
var menu_layer: Control
var menu_panel: PanelContainer
var menu_box: VBoxContainer
var about_layer: Control
var compact := false
var progress_path := PROGRESS
var _restoring := false


func _ready() -> void:
	get_tree().quit_on_go_back = false  # Back closes menus and cards first (see _notification)
	_apply_scale()
	if "--selftest" in OS.get_cmdline_user_args() or "--shots" in OS.get_cmdline_user_args():
		progress_path = "user://selftest_progress.json"  # never touch the player's own saved puzzle
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
	daily_count = int(cfg.get_value("play", "daily_count", DAILY_COUNT))
	if not daily_count in COUNTS:
		daily_count = DAILY_COUNT
	var cut_index := clampi(int(cfg.get_value("play", "cut", 0)), 0, 1)
	cut_button.select(cut_index)
	puzzle.cut_style = PieceShape.Style.WHIMSICAL if cut_index == 0 else PieceShape.Style.CLASSIC
	var rotation_on := bool(cfg.get_value("play", "rotation", false))
	rotation_button.set_pressed_no_signal(rotation_on)
	rotation_button.text = "Rotation on" if rotation_on else "Rotation off"
	puzzle.rotation_on = rotation_on
	# the tray starts on for a tall (phone-shaped) window, off for a wide one; the player's choice is kept
	var view := get_viewport().get_visible_rect().size
	var tray_on := bool(cfg.get_value("play", "tray", view.y > view.x))
	tray_button.set_pressed_no_signal(tray_on)
	_set_tray(tray_on, false)
	get_viewport().size_changed.connect(_on_resized)
	_apply_layout()
	puzzle.solved.connect(_on_solved)
	puzzle.progress.connect(_on_progress)
	var sounds_on := bool(cfg.get_value("play", "sounds", true))
	sounds_button.set_pressed_no_signal(sounds_on)
	sounds_button.text = "Sounds on" if sounds_on else "Sounds off"
	click = AudioStreamPlayer.new()
	click.stream = ClickSound.make()
	click.volume_db = -8.0
	click.max_polyphony = 3
	add_child(click)
	puzzle.placed.connect(func():
		if sounds_button.button_pressed:
			click.pitch_scale = randf_range(0.94, 1.06)  # never quite the same twice
			click.play())
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
	elif "--shots" in OS.get_cmdline_user_args():
		_shots.call_deferred()
	elif not _restore_progress():
		start_daily()


## Days since 1970 on the player's own calendar, so the daily turns over at local midnight (as Wordle does), not at
## midnight UTC, which is 5 pm in California.
func today() -> int:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))  # minutes east of UTC
	return int((Time.get_unix_time_from_system() + bias * 60.0) / 86400.0)


func today_index() -> int:
	var day := today() - EPOCH_DAY
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
	current_count = daily_count
	_select_count(daily_count)
	_start(today())


func start_random() -> void:
	is_daily = false
	current = pictures[randi() % pictures.size()]
	_start(randi())


func _start(seed_value: int) -> void:
	current_seed = seed_value
	finish_panel.visible = false
	tray_panel.visible = puzzle.tray_mode
	_select_count(current_count)
	# smooth when shrunk: give the picture mipmaps here (in memory, so the app download stays the same size)
	var img: Image = (load(current.file) as Texture2D).get_image()
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	puzzle.build(tex, current_count, seed_value)
	_layout_tray()  # a new puzzle: the sponsor line goes back above the tray
	_update_title()
	_save_progress()


func _update_title() -> void:
	if current.is_empty():
		return
	title_label.text = ("Today's puzzle: " if is_daily and not compact else "") + String(current.caption).capitalize()


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
	top_panel = top
	top.resized.connect(_on_top_resized)
	hairline = ColorRect.new()
	hairline.color = Color(BelleStyle.INK, 0.35)
	hairline.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hairline.offset_top = 59
	hairline.offset_bottom = 60
	hairline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hairline)
	top_rows = VBoxContainer.new()
	top_rows.add_theme_constant_override("separation", 2)
	top.add_child(top_rows)
	bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	top_rows.add_child(bar)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.max_lines_visible = 2
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size.x = 120  # a wrapping label needs a width
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
	daily_button = daily
	daily.text = "Daily"
	daily.pressed.connect(start_daily)
	bar.add_child(daily)
	random_button = Button.new()
	random_button.text = "New picture"
	random_button.pressed.connect(start_random)
	bar.add_child(random_button)
	count_button = OptionButton.new()
	for n in COUNTS:
		count_button.add_item("%d pieces" % n)
	# on the daily, a new size replays today's picture at that size and becomes the daily's size from then on;
	# on any other picture it cuts the same picture again at the new size
	count_button.item_selected.connect(func(i):
		if is_daily:
			daily_count = COUNTS[i]
			_save("daily_count", daily_count)
			start_daily()
		else:
			current_count = COUNTS[i]
			_start(randi()))
	bar.add_child(count_button)
	cut_button = OptionButton.new()
	cut_button.add_item("Whimsical cut")
	cut_button.add_item("Classic cut")
	cut_button.item_selected.connect(_set_cut)
	bar.add_child(cut_button)
	tray_button = Button.new()
	tray_button.text = "Tray off"
	tray_button.toggle_mode = true
	tray_button.tooltip_text = "Keep loose pieces in a tray along the bottom (best on a phone)"
	tray_button.toggled.connect(_set_tray)
	bar.add_child(tray_button)
	rotation_button = Button.new()
	rotation_button.text = "Rotation off"
	rotation_button.toggle_mode = true
	rotation_button.tooltip_text = "Pieces start turned; tap one to turn it (right-click on a computer)"
	rotation_button.toggled.connect(func(on):
		rotation_button.text = "Rotation on" if on else "Rotation off"
		puzzle.set_rotation_mode(on)
		_save("rotation", on)
		_save_progress())
	bar.add_child(rotation_button)
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
	ghost_button.text = "Hint off"
	ghost_button.toggle_mode = true
	ghost_button.button_pressed = false
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
	sounds_button = Button.new()
	sounds_button.text = "Sounds on"
	sounds_button.toggle_mode = true
	sounds_button.button_pressed = true
	sounds_button.toggled.connect(func(on):
		sounds_button.text = "Sounds on" if on else "Sounds off"
		_save("sounds", on))
	bar.add_child(sounds_button)
	menu_button = Button.new()
	menu_button.text = "Menu"
	menu_button.pressed.connect(_open_menu)
	bar.add_child(menu_button)
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
	_build_menu(root)
	_build_about(root)
	help_card = HelpCard.new()
	root.add_child(help_card)
	help_card.finished.connect(_give_hints)
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
	var finish_head := HBoxContainer.new()
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(44, 0)
	finish_head.add_child(balance)
	finish_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_head.add_child(finish_label)
	finish_head.add_child(BelleStyle.close_x(_close_finish))
	box.add_child(finish_head)
	var credit := Label.new()
	finish_credit = credit
	credit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credit.custom_minimum_size.x = 560  # a wrapping label needs a width, or it measures absurdly tall
	credit.text = "This picture was drawn by Pagouro BE, a free image model that runs offline.\nNot every picture it draws is a masterpiece; this one made the cut."
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size", 17)
	box.add_child(credit)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	share_button = Button.new()
	share_button.text = "Share"
	share_button.pressed.connect(_share)
	buttons.add_child(share_button)
	var again := Button.new()
	again.text = "Another picture"
	again.pressed.connect(start_random)
	buttons.add_child(again)


## Phones: when the window is taller than wide, lay the screen out for a 480-unit width, which makes everything about
## two and a half times larger on a phone than the 1280-wide computer layout would.
func _apply_scale() -> void:
	var win := DisplayServer.window_get_size()
	var want := Vector2i(480, 800) if win.y > win.x else Vector2i(1280, 800)
	if get_tree().root.content_scale_size != want:
		get_tree().root.content_scale_size = want


func _on_resized() -> void:
	_apply_scale()
	_apply_layout()
	_layout_tray()


## Wide screens keep Daily, New picture and the piece count in the bar; narrow ones move them into the Menu too.
## The rest (cut, tray, table, hint, music, About) always live in the Menu.
func _apply_layout() -> void:
	if bar == null or menu_box == null:
		return
	compact = get_viewport().get_visible_rect().size.x < 900
	var in_bar := [] if compact else [daily_button, random_button, count_button]
	var in_menu := ([daily_button, random_button, count_button] if compact else []) + [cut_button, tray_button, rotation_button, table_button, ghost_button, music_button, sounds_button]
	for c in in_bar:
		if c.get_parent() != bar:
			c.reparent(bar)
		c.size_flags_horizontal = Control.SIZE_FILL
	for i in range(in_menu.size()):
		var c: Control = in_menu[i]
		if c.get_parent() != menu_box:
			c.reparent(menu_box)
		menu_box.move_child(c, i + 1)  # after the menu's own heading row
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.move_child(menu_button, bar.get_child_count() - 1)
	# a phone gives the title its own row under the buttons (two lines at most); a computer keeps it in the bar
	if compact and title_label.get_parent() != top_rows:
		title_label.reparent(top_rows)
		var spacer := Control.new()
		spacer.name = "TitleSpacer"
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_child(spacer)
		bar.move_child(spacer, 0)
	elif not compact and title_label.get_parent() != bar:
		title_label.reparent(bar)
		bar.move_child(title_label, 0)
		if bar.has_node("TitleSpacer"):
			bar.get_node("TitleSpacer").free()
	title_label.add_theme_font_size_override("font_size", 20 if compact else 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
	sponsor_label.text = "Free, thanks to Pagouro · pagouro.com" if compact else "Free, thanks to Pagouro · pictures by Pagouro BE, music by Pagouro Salon · pagouro.com"
	_update_title()


func _build_menu(root: Control) -> void:
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.visible = false
	menu_layer.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_close_menu())
	root.add_child(menu_layer)
	menu_panel = PanelContainer.new()
	menu_panel.add_theme_stylebox_override("panel", BelleStyle.box(BelleStyle.PAPER, BelleStyle.GOLD, 2, 2, Vector4(14, 12, 14, 12)))
	menu_layer.add_child(menu_panel)
	menu_box = VBoxContainer.new()
	menu_box.custom_minimum_size.x = 230
	menu_box.add_theme_constant_override("separation", 8)
	menu_panel.add_child(menu_box)
	var menu_head := HBoxContainer.new()
	var menu_title := Label.new()
	menu_title.text = "Menu"
	menu_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_title.add_theme_font_override("font", BelleStyle.title_font())
	menu_title.add_theme_font_size_override("font_size", 24)
	menu_title.add_theme_color_override("font_color", BelleStyle.GREEN)
	menu_head.add_child(menu_title)
	menu_head.add_child(BelleStyle.close_x(_close_menu))
	menu_box.add_child(menu_head)
	var about := Button.new()
	about.text = "About and credits"
	about.pressed.connect(func():
		_close_menu()
		about_layer.visible = true)
	menu_box.add_child(about)
	daily_button.pressed.connect(_close_menu)
	random_button.pressed.connect(_close_menu)


func _open_menu() -> void:
	menu_layer.visible = true
	menu_panel.reset_size()
	var view := get_viewport().get_visible_rect().size
	menu_panel.position = Vector2(view.x - menu_panel.size.x - 8, top_panel.size.y + 6)


func _close_menu() -> void:
	menu_layer.visible = false


## Closing the finish card leaves the finished picture to look at; Menu still offers the next one.
func _close_finish() -> void:
	finish_panel.visible = false
	puzzle.focus_board(40.0)  # keep clear of the sponsor line at the bottom


func _on_top_resized() -> void:
	hairline.offset_top = top_panel.size.y + 3
	hairline.offset_bottom = top_panel.size.y + 4
	puzzle.top_bar = top_panel.size.y + 8
	if menu_layer and menu_layer.visible:
		_open_menu()


## Credits and licenses: everything in the game is free to share, and the engine's license asks for its notice.
func _build_about(root: Control) -> void:
	about_layer = Control.new()
	about_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	about_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	about_layer.visible = false
	root.add_child(about_layer)
	var dim := ColorRect.new()
	dim.color = Color(BelleStyle.INK, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	about_layer.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	about_layer.add_child(margin)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", BelleStyle.box(BelleStyle.PAPER, BelleStyle.GOLD, 2, 2, Vector4(22, 16, 22, 14)))
	margin.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var heading := Label.new()
	heading.text = "Jigsaw by Pagouro"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", BelleStyle.title_font())
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", BelleStyle.GREEN)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var about_head := HBoxContainer.new()
	var balance := Control.new()  # keeps the heading centred against the close mark
	balance.custom_minimum_size = Vector2(44, 0)
	about_head.add_child(balance)
	about_head.add_child(heading)
	about_head.add_child(BelleStyle.close_x(func(): about_layer.visible = false))
	box.add_child(about_head)
	var version := Label.new()  # keep application/config/version and the Android preset's version/name in step
	version.text = "Version %s" % ProjectSettings.get_setting("application/config/version", "?")
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 15)
	version.add_theme_color_override("font_color", BelleStyle.INK_SOFT)
	box.add_child(version)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("font_size", 16)
	var lines := [
		"Free, thanks to Pagouro (pagouro.com). No ads, no tracking, no account.",
		"",
		"Find Pagouro: pagouro.com; X @pagouro; Reddit r/pagouro; GitHub ericrwade/pagouro and ericrwade/pagouro-be; Hugging Face, under Pagouro.",
		"",
		"Pictures: drawn by Pagouro BE, a free image model. CC0 1.0.",
		"Music: composed by Pagouro Salon, a free music model; piano sound Upright Piano KW by FreePats (CC0); rendered with FluidSynth. CC0 1.0.",
		"Lettering: Cormorant Garamond and EB Garamond, SIL Open Font License 1.1.",
		"Game code: Apache License 2.0.",
		"Made with the Godot Engine (godotengine.org).",
		"With thanks to Summer Engine (summerengine.com), the AI game engine that got us making games. This jigsaw is built on Godot, the open-source engine Summer is built on.",
		"",
		"GODOT ENGINE LICENSE",
		_reflow(Engine.get_license_text()),
		"THIRD-PARTY COMPONENTS IN THE GODOT ENGINE",
	]
	for info in Engine.get_copyright_info():
		var licenses := []
		for part in info.get("parts", []):
			if not licenses.has(part.get("license", "")):
				licenses.append(part.get("license", ""))
		lines.append("%s: %s" % [info.get("name", ""), ", ".join(licenses)])
	lines.append("")
	lines.append("LICENSE TEXTS")
	var license_info := Engine.get_license_info()
	for key in license_info.keys():
		lines.append("")
		lines.append(String(key))
		lines.append(_reflow(String(license_info[key])))
	text.text = "\n".join(lines)
	scroll.add_child(text)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func(): about_layer.visible = false)
	box.add_child(close)


## License texts come with hard line breaks; join each paragraph so it wraps cleanly on a narrow screen.
func _reflow(text: String) -> String:
	var paras := []
	for para in text.replace("\r", "").split("\n\n"):
		paras.append(" ".join(Array(para.split("\n")).map(func(l): return l.strip_edges())))
	return "\n\n".join(paras)


## Save the puzzle in progress (cheap: one small JSON file). Skipped while a saved puzzle is being put back.
func _save_progress() -> void:
	if _restoring or puzzle.texture == null or puzzle.is_solved or current.is_empty():
		return
	var data := {"version": 1, "file": current.file, "caption": current.caption, "count": current_count, "seed": current_seed,
		"cut": puzzle.cut_style, "daily": is_daily, "day": today(), "state": puzzle.snapshot()}
	var f := FileAccess.open(progress_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


## Put back the puzzle that was in progress when the app last closed. False if there is none (or it can't be read).
func _restore_progress() -> bool:
	if not FileAccess.file_exists(progress_path):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(progress_path))
	if not (data is Dictionary) or not ResourceLoader.exists(String(data.get("file", ""))):
		return false
	current = {"file": data.file, "caption": data.get("caption", "")}
	current_count = int(data.get("count", DAILY_COUNT))
	is_daily = bool(data.get("daily", false)) and int(data.get("day", -1)) == today()
	puzzle.cut_style = int(data.get("cut", PieceShape.Style.WHIMSICAL))
	cut_button.select(0 if puzzle.cut_style == PieceShape.Style.WHIMSICAL else 1)
	_restoring = true
	_start(int(data.get("seed", 0)))
	puzzle.restore(data.get("state", {}))
	_restoring = false
	_save_progress()
	return true


func _clear_progress() -> void:
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(progress_path))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Android Back: close whatever is open, and only then leave the game (the puzzle is saved first)
		if about_layer and about_layer.visible:
			about_layer.visible = false
		elif finish_panel and finish_panel.visible:
			_close_finish()
		elif menu_layer and menu_layer.visible:
			_close_menu()
		elif help_card and help_card.visible:
			help_card._end(help_card._done.visible)
		else:
			_save_progress()
			get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()


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
	tray_button.text = "Tray on" if on else "Tray off"
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
	# the sponsor line sits just above the tray while there is one, and drops to the bottom once the puzzle is done
	var shown := on and not puzzle.is_solved
	sponsor_label.offset_top = -30 - (height if shown else 0.0)
	sponsor_label.offset_bottom = -(height if shown else 0.0)


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


## The hint: several pieces on bigger puzzles, a quarter second apart so each can be seen landing.
func _give_hints(give: bool) -> void:
	if not give:
		return
	for i in range(puzzle.hint_count()):
		if not puzzle.hint():
			break
		await get_tree().create_timer(0.25).timeout


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
	# nearest, so a puzzle saved under the old labels (24, 48, 96, 150) still shows its row
	var i := 0
	for k in range(COUNTS.size()):
		if abs(COUNTS[k] - n) < abs(COUNTS[i] - n):
			i = k
	count_button.select(i)


func _on_progress(joined: int, total: int) -> void:
	status_label.text = "%d / %d" % [joined, total]
	_save_progress()


## The text Share copies, like the Wordle and Connections results families post: the daily gets a number and no
## picture name (so it spoils nothing for anyone who hasn't done it yet).
func share_text() -> String:
	var t := "%d:%02d" % [int(solved_seconds) / 60, int(solved_seconds) % 60]
	if is_daily:
		var number := today() - EPOCH_DAY + 1
		return "Jigsaw by Pagouro #%d 🧩\n%d pieces in %s\npagouro.com" % [number, puzzle.rows * puzzle.cols, t]
	return "Jigsaw by Pagouro 🧩\n%s\n%d pieces in %s\npagouro.com" % [String(current.caption).capitalize(), puzzle.rows * puzzle.cols, t]


## Godot has no share sheet, so Share copies the result; the button says so, then turns back.
func _share() -> void:
	DisplayServer.clipboard_set(share_text())
	share_button.text = "Copied! Paste it in a chat"
	get_tree().create_timer(2.5).timeout.connect(func(): share_button.text = "Share")


func _on_solved(seconds: float) -> void:
	solved_seconds = seconds
	share_button.text = "Share"
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	finish_label.text = "Finished in %d:%02d" % [m, s]
	_clear_progress()
	finish_credit.custom_minimum_size.x = min(560.0, get_viewport().get_visible_rect().size.x - 110.0)
	finish_panel.visible = true
	tray_panel.visible = false
	_layout_tray()  # the sponsor line comes down to the bottom
	finish_panel.modulate.a = 0.0
	await get_tree().process_frame  # let the wrapped text settle before measuring the card
	# below the finished picture, so the picture stays in view
	var view := get_viewport().get_visible_rect().size
	finish_panel.reset_size()
	finish_panel.position = Vector2((view.x - finish_panel.size.x) * 0.5, view.y - finish_panel.size.y - 44)
	finish_panel.modulate.a = 1.0
	puzzle.focus_board(finish_panel.size.y + 52)


## Self-test helper: every cluster's pieces, position and lock, as a sorted list, to compare two puzzle states.
func _layout_signature() -> Array:
	var sig := []
	for c in puzzle.clusters:
		var rcs := []
		for p in c.get_children():
			rcs.append(p.get_meta("rc"))
		rcs.sort()
		sig.append([str(rcs), c.position.round(), c.has_meta("locked"), puzzle.turn_of(c)])
	sig.sort()
	return sig



## Self-test helper: a finger touching or leaving the screen, as Android would send it.
func _touch(index: int, at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = get_tree().root.get_final_transform() * at  # layout units to window pixels, as a real finger arrives
	e.pressed = down
	Input.parse_input_event(e)


## Store screenshots (`-- --shots`, run silently and off-screen like the self-test): staged phone screens saved as
## user://shot_N.png. Uses its own progress file and never saves settings.
func _shots() -> void:
	var by_file := func(part: String) -> Dictionary:
		for p in pictures:
			if String(p.file).contains(part):
				return p
		return pictures[0]
	tray_button.set_pressed_no_signal(true)
	_set_tray(true, false)
	table_button.select(0)
	_set_table(0, false)
	var shoot := func(n: int) -> void:
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shot_%d.png" % n)
	# 1: a fresh puzzle, pieces waiting in the tray
	current = by_file.call("black-cat")
	current_count = 49
	is_daily = false
	_start(1101)
	await shoot.call(1)
	# 2: halfway, on a darker table
	current = by_file.call("irises")
	current_count = 49
	table_button.select(6)
	_set_table(6, false)
	_start(1102)
	var all := puzzle.clusters.duplicate()
	for k in range(all.size() * 3 / 5):
		var c: Node2D = all[k]
		if is_instance_valid(c) and puzzle.clusters.has(c):
			puzzle.tray.erase(c)
			c.visible = true
			c.position = Vector2.ZERO
			puzzle._settle(c)
	puzzle.tray_changed.emit()
	await shoot.call(2)
	# 3: Help, the informative card in place of an ad
	help_card.show_panel(panels[3])
	await shoot.call(3)
	help_card._end(false)
	# 4: finished
	current = by_file.call("eiffel")
	table_button.select(0)
	_set_table(0, false)
	_start(1104)
	puzzle.solve_all_for_test()
	await get_tree().create_timer(1.8).timeout
	finish_label.text = "Finished in 21:37"
	await shoot.call(4)
	# 5: the menu
	current = by_file.call("balloon")
	table_button.select(3)
	_set_table(3, false)
	_start(1105)
	_open_menu()
	await shoot.call(5)
	_close_menu()
	print("SHOTS written to ", ProjectSettings.globalize_path("user://"))
	get_tree().quit()

func _selftest() -> void:
	var report := []
	report.append("music at %.1f s of the loop" % music.get_playback_position())
	for style in [PieceShape.Style.WHIMSICAL, PieceShape.Style.CLASSIC]:
		var worst := [0.0, 0.0]
		var mix := [0, 0, 0, 0, 0]
		PieceShape.neck_stats = [9.0, 9.0]
		PieceShape.reach_stats = [9.0, -9.0, 0.0]
		var broken := 0
		for sd in range(20):
			var ar := PieceShape.area_report(7, 7, 1000 + sd, style)
			broken += ar[3]
			worst = [max(worst[0], ar[0]), max(worst[1], ar[1])]
			for i in range(5):
				mix[i] += ar[2][i]
		report.append("%s areas, worst of 20 cuts at 49 pieces: inside largest/smallest %.2f, all %.2f, inside pieces by tabs out 0/1/2/3/4: %s of 500" % ["whimsical" if style == PieceShape.Style.WHIMSICAL else "classic", worst[0], worst[1], str(mix)])
		report.append("  narrowest neck %.3f cell, smallest neck/head %.2f, tabs reach along %.2f..%.2f and out %.3f, invalid piece outlines %d of 980" % [PieceShape.neck_stats[0], PieceShape.neck_stats[1], PieceShape.reach_stats[0], PieceShape.reach_stats[1], PieceShape.reach_stats[2], broken])
	for n in [12, 48]:
		current = pictures[today_index()]
		current_count = n
		_start(42)
		report.append("built %d asked -> %d pieces (%dx%d), edge masks %.2f px per picture px baked in %d ms" % [n, puzzle.piece_total(), puzzle.cols, puzzle.rows, puzzle.mask_scale, puzzle.mask_ms])
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_scattered.png")
	_open_menu()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_menu.png")
	_close_menu()
	about_layer.visible = true
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_about.png")
	about_layer.visible = false
	report.append("layout compact=%s viewport %s" % [str(compact), str(get_viewport().get_visible_rect().size)])
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
	# a pinch whose second finger lifts over the top bar must not leave a ghost finger behind, and one finger must
	# then pick a piece up again (Eric, 2026-10-04: after zooming on the phone, the last pieces would not move)
	var view_size := get_viewport().get_visible_rect().size
	var table_pt := view_size * Vector2(0.5, 0.45)
	_touch(0, table_pt, true)
	_touch(1, table_pt + Vector2(80, 0), true)
	await get_tree().process_frame
	_touch(1, Vector2(view_size.x * 0.3, 20), false)  # lifted over the top bar
	_touch(0, table_pt, false)
	await get_tree().process_frame
	var ghosts: int = puzzle._touches.size()
	var piece_screen: Vector2 = puzzle.get_canvas_transform() * (free.transform * free.get_child(0).get_meta("centre"))
	_touch(0, piece_screen, true)
	await get_tree().process_frame
	var picked: bool = puzzle.dragging != null
	_touch(0, piece_screen, false)
	await get_tree().process_frame
	report.append("ghost fingers after a pinch lifted over the bar: %d, one finger then picks a piece up=%s" % [ghosts, str(picked)])
	report.append("tray drag reads as: diagonal up-right, nothing to scroll -> %s; 45 degrees up -> %s; sideways -> %s; sideways, nothing to scroll -> %s" % [Tray.decide(Vector2(40, -22), true, false), Tray.decide(Vector2(20, -20), true, true), Tray.decide(Vector2(30, -6), true, true), Tray.decide(Vector2(30, -6), true, false)])
	# save and restore: the half-done puzzle is rebuilt from its seed and put back exactly
	var snap := puzzle.snapshot()
	var sig_before := _layout_signature()
	_start(42)
	puzzle.restore(snap)
	report.append("restore: clusters %d, layout identical=%s" % [puzzle.clusters.size(), str(_layout_signature() == sig_before)])
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
	var done_early: bool = help_card._done.visible
	await get_tree().create_timer(HelpCard.SECONDS + 0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_help_done.png")
	report.append("help card: Done shown during countdown=%s, after=%s, card still open=%s" % [str(done_early), str(help_card._done.visible), str(help_card.visible)])
	help_card._end(false)
	var before_hint := puzzle.pieces_left()
	var hinted := true
	_give_hints(true)
	await get_tree().create_timer(2.0).timeout
	report.append("hints per Help at 49 pieces: %d" % puzzle.hint_count())
	report.append("hint given=%s pieces left %d -> %d" % [str(hinted), before_hint, puzzle.pieces_left()])
	report.append("%d help panels" % panels.size())
	# finish with the tray on, the way a phone plays: the sponsor line must come down when the tray goes
	tray_button.set_pressed_no_signal(true)
	_set_tray(true, false)
	puzzle.solve_all_for_test()
	report.append("after solve: %d cluster(s), solved=%s" % [puzzle.clusters.size(), str(puzzle.is_solved)])
	_share()
	report.append("share (daily=%s, copied=%s): %s" % [str(is_daily), str(DisplayServer.clipboard_get().replace(char(13), "") == share_text()), share_text().replace("\n", " | ")])
	report.append("border glow played=%s; Help pieces at 156 with 156/78/40/10 left: %s" % [str(puzzle.border_done), str([156, 78, 40, 10].map(func(l): return max(1, int(round(min(156, 2 * l) / 24.0)))))])
	await get_tree().create_timer(0.8).timeout  # the border light mid-run
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_glow.png")
	await get_tree().create_timer(0.9).timeout  # let the seams fade
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_solved.png")
	# the finished card closed: the picture recentres and the sponsor line sits clear below it (Eric, 2026-10-04)
	_close_finish()
	await get_tree().create_timer(1.1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_closed.png")
	# rotation: pieces start turned; four quarter turns come back; a turned piece is grabbed where it shows; a turned
	# piece at home does not lock and an upright one does; save and restore keep every turn
	puzzle.rotation_on = true
	current_count = 12
	_start(77)
	var turned_start: int = puzzle.clusters.filter(func(c): return puzzle.turn_of(c) != 0).size()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://selftest_rotation.png")
	var r0: Node2D = puzzle.clusters[0]
	var t_before := r0.transform
	for k in range(4):
		puzzle._set_turn(r0, (puzzle.turn_of(r0) + 1) % 4)
	var round_trip := r0.transform.is_equal_approx(t_before)
	var r1: Node2D = puzzle.clusters[1]
	puzzle._set_turn(r1, 3)
	r1.visible = true
	var grab_turned: bool = puzzle._cluster_at(r1.transform * r1.get_child(0).get_meta("centre")) == r1
	puzzle._set_turn(r0, 1)
	r0.visible = true
	r0.position = Vector2.ZERO
	puzzle._settle(r0)
	var locks_turned := r0.has_meta("locked")
	puzzle._set_turn(r0, 0)
	r0.position = Vector2.ZERO
	puzzle._settle(r0)
	var locks_upright := r0.has_meta("locked")
	var rsnap := puzzle.snapshot()
	var rsig := _layout_signature()
	_start(77)
	puzzle.restore(rsnap)
	report.append("rotation: %d of 12 start turned, four quarter turns round-trip=%s, turned piece grabbable=%s, turned piece at home locks=%s, upright locks=%s, restore identical=%s" % [turned_start, str(round_trip), str(grab_turned), str(locks_turned), str(locks_upright), str(_layout_signature() == rsig)])
	puzzle.rotation_on = false
	report.append("daily index today: %d (%s)" % [today_index(), pictures[today_index()].caption])
	# daily size: picking 100 on the daily keeps today's picture, is remembered, and Daily uses it again (the player's
	# saved size is put back afterwards)
	var saved_size := daily_count
	start_daily()
	count_button.select(COUNTS.find(100))
	count_button.item_selected.emit(COUNTS.find(100))
	var same_pic: bool = is_daily and current == pictures[today_index()] and puzzle.rows * puzzle.cols == 100
	start_random()
	start_daily()
	var cfg_check := ConfigFile.new()
	cfg_check.load(SETTINGS)
	report.append("daily at 100: today's picture=%s, Daily again gives %d pieces, saved=%s" % [str(same_pic), puzzle.rows * puzzle.cols, str(cfg_check.get_value("play", "daily_count", -1))])
	daily_count = saved_size
	_save("daily_count", saved_size)
	report.append("screenshots in " + ProjectSettings.globalize_path("user://"))
	print("SELFTEST " + " | ".join(report))
	get_tree().quit()
