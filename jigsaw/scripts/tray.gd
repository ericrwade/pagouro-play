class_name Tray
extends Control
## The piece tray for phones (Eric, 2026-10-04): two rows of loose pieces along the bottom, in the shuffled order they
## came out of the box. Swipe sideways to look through them; swipe a piece up to lift it onto the board. Drop a loose
## piece back over the tray to put it away. On a computer the same works with the mouse and the wheel scrolls.

const ROWS := 2
const LIFT := 14.0     # pixels upward before a touch counts as lifting a piece
const SLIDE := 8.0     # pixels sideways before a touch counts as scrolling
# When a piece comes out, its slot stays empty for a beat, then the pieces behind it glide up to close the gap, so
# taking one out reads clearly and feels rewarding (Eric, 2026-10-05: "a tiny delay and slower slide").
const CLOSE_DELAY := 0.18
const CLOSE_TIME := 0.5

var puzzle: Puzzle
var slot := 120.0
var scroll := 0.0
var _press := Vector2.ZERO
var _pressed := false
var _mode := ""        # "", "scroll" or "lift"
var _hit := -1
var _strip: Node2D
var _thumbs := {}         # tray cluster -> its picture in the tray, kept between rebuilds so they can move
var _slot_drawn := 0.0    # the slot size the thumbs were made at; a new size (or a new puzzle) places without moving


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_strip = Node2D.new()
	add_child(_strip)
	puzzle.tray_changed.connect(rebuild)
	resized.connect(rebuild)


func _draw() -> void:
	# a paper shelf with the house gold rule and ink hairline along its top edge, like the top bar
	draw_rect(Rect2(Vector2.ZERO, size), BelleStyle.PAPER_DEEP)
	draw_rect(Rect2(0, 0, size.x, 2), BelleStyle.GOLD)
	draw_rect(Rect2(0, 3, size.x, 1), Color(BelleStyle.INK, 0.35))
	if puzzle and puzzle.tray.is_empty():
		var font := get_theme_default_font()
		var text := "All the pieces are out of the tray."
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string(font, Vector2((size.x - w) * 0.5, size.y * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BelleStyle.INK_SOFT)


func _columns() -> int:
	return int(ceil(puzzle.tray.size() / float(ROWS)))


func _max_scroll() -> float:
	return max(0.0, _columns() * slot - size.x + slot * 0.25)


func rebuild() -> void:
	if _strip == null or puzzle == null:
		return
	slot = (size.y - 8.0) / ROWS
	scroll = clamp(scroll, 0.0, _max_scroll())
	# glide only when the same tray just lost or gained a piece; a resize or a new puzzle places everything at once
	var any_kept := puzzle.tray.any(func(c): return _thumbs.has(c))
	var glide := any_kept and is_equal_approx(slot, _slot_drawn)
	_slot_drawn = slot
	# one scale for every piece, so their sizes compare the way they will on the board
	var s: float = slot * 0.78 / (1.6 * max(puzzle.cell.x, puzzle.cell.y))
	var kept := {}
	for i in range(puzzle.tray.size()):
		var cluster: Node2D = puzzle.tray[i]
		var piece: Polygon2D = cluster.get_child(0)
		var target: Vector2 = _slot_centre(i) - (piece.get_meta("centre") * s).rotated(cluster.rotation)
		var thumb: Polygon2D = _thumbs.get(cluster)
		var is_new := thumb == null or not glide
		if thumb == null:
			thumb = Polygon2D.new()
			thumb.texture = piece.texture
			thumb.polygon = piece.polygon
			thumb.uv = piece.uv
			thumb.material = piece.material  # the same smooth cut
			_strip.add_child(thumb)
		thumb.scale = Vector2(s, s)
		thumb.rotation = cluster.rotation  # shown the way it will come out of the tray
		if thumb.has_meta("tween"):
			(thumb.get_meta("tween") as Tween).kill()
			thumb.remove_meta("tween")
		if is_new or not glide or thumb.position.is_equal_approx(target):
			thumb.position = target
			if glide and is_new and not _thumbs.has(cluster):
				# a piece put back: it fades in at its place while the others make room
				thumb.modulate.a = 0.0
				var fade := create_tween()
				fade.tween_property(thumb, "modulate:a", 1.0, CLOSE_TIME).set_delay(CLOSE_DELAY)
				thumb.set_meta("tween", fade)
			else:
				thumb.modulate.a = 1.0
		else:
			var move := create_tween()
			move.tween_property(thumb, "position", target, CLOSE_TIME).set_delay(CLOSE_DELAY).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			thumb.set_meta("tween", move)
		kept[cluster] = thumb
	# a piece that left the tray (in the player's fingers now, or a new puzzle's old pieces) goes at once
	for c in _thumbs:
		if not kept.has(c) and is_instance_valid(_thumbs[c]):
			_thumbs[c].queue_free()
	_thumbs = kept
	_strip.position.x = -scroll
	queue_redraw()


func _slot_centre(i: int) -> Vector2:
	var col := i / ROWS
	var row := i % ROWS
	return Vector2(col * slot + slot * 0.5 + slot * 0.125, 8.0 + row * slot + slot * 0.5)


func _slot_at(local: Vector2) -> int:
	var x := local.x + scroll - slot * 0.125
	if x < 0 or local.y < 8.0:
		return -1
	var i := int(x / slot) * ROWS + int((local.y - 8.0) / slot)
	return i if i < puzzle.tray.size() else -1


func _gui_input(event: InputEvent) -> void:
	if puzzle == null or puzzle.is_solved:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			_scroll_by(slot * 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			_scroll_by(-slot * 0.5)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed = true
				_press = event.position
				_mode = ""
				_hit = _slot_at(event.position)
			else:
				if _mode == "lift":
					puzzle.end_drag(event.global_position)
				_pressed = false
				_mode = ""
		accept_event()
	elif event is InputEventMouseMotion and _pressed:
		var d: Vector2 = event.position - _press
		if _mode == "":
			_mode = decide(d, _hit >= 0, _max_scroll() > 0.0)
			if _mode == "lift":
				puzzle.begin_drag_from_tray(puzzle.tray[_hit], event.global_position)
		if _mode == "scroll":
			_scroll_by(-event.relative.x)
		elif _mode == "lift":
			puzzle.drag_to(event.global_position)
		accept_event()


## Lift or scroll, from how a touch on the tray has moved so far ("" = not yet decided). A piece lifts when the
## finger heads upward at all steeply (within about 60 degrees of straight up), and in any direction when the tray
## has nothing to scroll: Eric's last two pieces would not come out on a natural diagonal drag toward their holes,
## because it read as a scroll of a tray that could not scroll (2026-10-04).
static func decide(d: Vector2, on_piece: bool, can_scroll: bool) -> String:
	if on_piece and d.length() > LIFT and (not can_scroll or -d.y > abs(d.x) * 0.55):
		return "lift"
	if can_scroll and abs(d.x) > SLIDE and abs(d.x) > abs(d.y):
		return "scroll"
	return ""


func _scroll_by(dx: float) -> void:
	scroll = clamp(scroll + dx, 0.0, _max_scroll())
	_strip.position.x = -scroll
