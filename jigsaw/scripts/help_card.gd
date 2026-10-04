class_name HelpCard
extends Control
## The Help card (Eric, 2026-10-04). Paid jigsaws make you watch an ad for a hint; here the "ad" is a few seconds of one
## short panel about the project: where the pictures and music came from, Pagouro, the Belle Époque and its posters.
## A gold rule runs down while it shows; when it ends the hint is given. "Not now" closes it with no hint.

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
	var close := Button.new()
	close.text = "Not now"
	close.pressed.connect(func(): _end(false))
	row.add_child(close)


func show_panel(panel: Dictionary) -> void:
	_title.text = String(panel.get("title", "Pagouro"))
	_text.text = String(panel.get("text", ""))
	_left = SECONDS
	_running = true
	visible = true
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.25)


func _process(delta: float) -> void:
	if not _running:
		return
	_left -= delta
	_bar.size.x = _bar_full * clamp(_left / SECONDS, 0.0, 1.0)
	_count.text = "Your hint in %d…" % int(ceil(max(_left, 0.0)))
	if _left <= 0.0:
		_end(true)


func _end(give_hint: bool) -> void:
	if not _running:
		return
	_running = false
	visible = false
	finished.emit(give_hint)
