class_name HelpCard
extends Control
## The Help card (Eric, 2026-10-04). Paid jigsaws make you watch an ad for a hint; here the "ad" is a few seconds of one
## short panel about the project: where the pictures and music came from, Pagouro, the Belle Époque and its posters.
## A gold rule runs down while it shows; when it ends a Done button appears, and the hint comes when the player presses
## it, so anyone reading can stay as long as they like (Eric, 2026-10-04). "Not now" closes it early with no hint.

signal finished(give_hint: bool)

const SECONDS := 6.0

var _card: PanelContainer
var _title: Label
var _text: Label
var _count: Label
var _bar: ColorRect
var _bar_full := 0.0
var _left := 0.0
var _running := false
var _skip: Button
var _done: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # the table is paused under the card
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(BelleStyle.INK, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	# the same paper card with a gold double edge as the finish card
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", BelleStyle.box(BelleStyle.PAPER, BelleStyle.GOLD, 2, 2, Vector4(6, 6, 6, 6)))
	centre.add_child(_card)
	var inner := PanelContainer.new()
	inner.add_theme_stylebox_override("panel", BelleStyle.box(BelleStyle.PAPER, Color(BelleStyle.INK, 0.45), 1, 1, Vector4(30, 20, 30, 18)))
	_card.add_child(inner)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	inner.add_child(box)
	var logo := TextureRect.new()
	logo.texture = load("res://art/pagouro_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 66)
	box.add_child(logo)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", BelleStyle.title_font())
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", BelleStyle.GREEN)
	box.add_child(_title)
	_text = Label.new()
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(520, 0)
	_text.add_theme_font_size_override("font_size", 21)
	box.add_child(_text)
	# the countdown: a gold rule that shortens, and a quiet line under it
	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 3)
	box.add_child(track)
	_bar = ColorRect.new()
	_bar.color = BelleStyle.GOLD
	_bar.size = Vector2(0, 2)
	track.add_child(_bar)
	track.resized.connect(func(): _bar_full = track.size.x)
	var row := HBoxContainer.new()
	box.add_child(row)
	_count = Label.new()
	_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count.add_theme_font_size_override("font_size", 16)
	_count.add_theme_color_override("font_color", BelleStyle.INK_SOFT)
	row.add_child(_count)
	_skip = Button.new()
	_skip.text = "Not now"
	_skip.pressed.connect(func(): _end(false))
	row.add_child(_skip)
	_done = Button.new()
	_done.text = "Done"
	_done.visible = false
	_done.pressed.connect(func(): _end(true))
	row.add_child(_done)


func show_panel(panel: Dictionary) -> void:
	_title.text = String(panel.get("title", "Pagouro"))
	_text.text = String(panel.get("text", ""))
	_text.custom_minimum_size.x = min(520.0, get_viewport_rect().size.x - 110.0)  # narrower on a phone
	_left = SECONDS
	_running = true
	_skip.visible = true
	_done.visible = false
	visible = true
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.25)


func _process(delta: float) -> void:
	if not _running:
		return
	_left -= delta
	_bar.size.x = _bar_full * clamp(_left / SECONDS, 0.0, 1.0)
	if _left > 0.0:
		_count.text = "Your hint in %d…" % int(ceil(_left))
	elif not _done.visible:
		_count.text = "Your hint is ready."
		_skip.visible = false
		_done.visible = true
		_done.grab_focus()


func _end(give_hint: bool) -> void:
	if not _running:
		return
	_running = false
	visible = false
	finished.emit(give_hint)
