class_name Puzzle
extends Node2D
## The puzzle table. Works in the picture's own pixel space: the board is the picture's rectangle at (0, 0), pieces are
## Polygon2D nodes textured with the picture, grouped in clusters (Node2D). A piece's place inside its cluster is its home
## position, so two clusters fit together exactly when their positions are equal: snapping and joining compare cluster
## positions only. The camera fits the whole table (board plus a scatter margin) to the window.
##
## Tray mode (Eric, 2026-10-04, for phones): loose pieces wait in a two-row tray along the bottom instead of on the
## table, and the view frames the board alone. A piece in the tray is a hidden cluster; the Tray control draws it and
## hands it back here when the player swipes it up.

signal solved(seconds: float)
signal progress(joined: int, total: int)
signal tray_changed
signal placed  # pieces joined or locked into place: the screen plays the click
signal border_finished  # the last border piece locked in

const SNAP_FRACTION := 0.18   # snap when within this fraction of a cell
const MARGIN := 0.3           # scatter margin around the board, as a fraction of the board size
const TRAY_MARGIN := 0.05     # in tray mode, the little table left around the board
const MAX_ZOOM := 4.0         # how far in the player can zoom, relative to the whole-table view

var texture: Texture2D
var rows := 0
var cols := 0
var cell := Vector2.ZERO
var clusters: Array[Node2D] = []
var dragging: Node2D = null
var drag_offset := Vector2.ZERO
var started_ms := 0
var is_solved := false
var show_ghost := false  # the faint guide picture starts off (Eric, 2026-10-04); Menu, Hint turns it on
var table_color := BelleStyle.PAPER
var cut_style := PieceShape.Style.WHIMSICAL
var tray_mode := false
var tray_height := 0.0        # screen pixels the tray covers at the bottom (set by the screen)
var tray: Array[Node2D] = []  # clusters waiting in the tray, in tray order
var fit_zoom := 1.0           # the zoom that shows the whole table; the player may zoom in from it up to MAX_ZOOM times
var fit_centre := Vector2.ZERO  # where the whole-table view puts the camera
var panning := false
var _touches := {}            # finger index -> screen position, for two-finger pinch and pan on phones
var _pinch_dist := 0.0
var _pinch_mid := Vector2.ZERO
var border_done := false
## Rotation (Eric, 2026-10-04): when on, pieces start turned by quarter turns and a tap turns one 90 degrees. Pieces
## join only when they face the same way, and lock only the right way up. A cluster's quarter turns live in its
## "turn" meta (0..3); its rotation is always turn * 90 degrees once a turn has finished.
var rotation_on := false
var _press_screen := Vector2.ZERO
var _press_ms := 0
var glow: BorderGlow

@onready var camera: Camera2D = $Camera2D
@onready var board: Node2D = $Board
@onready var pieces_root: Node2D = $Pieces


func build(tex: Texture2D, piece_count: int, seed_value: int) -> void:
	for c in clusters:
		c.queue_free()
	clusters.clear()
	tray.clear()
	dragging = null
	is_solved = false
	border_done = false
	texture = tex
	var size := tex.get_size()
	# a grid near the asked count with near-square cells
	cols = max(2, int(round(sqrt(piece_count * size.x / size.y))))
	rows = max(2, int(round(float(piece_count) / cols)))
	cell = Vector2(size.x / cols, size.y / rows)
	var cut := PieceShape.make_cut(rows, cols, seed_value, cut_style)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + 13
	var table := _table_rect(false)
	for r in range(rows):
		for c in range(cols):
			var poly := PackedVector2Array()
			for p in PieceShape.piece_outline(cut, r, c):
				poly.append(Vector2(p.x * cell.x, p.y * cell.y))
			var piece := Polygon2D.new()
			piece.texture = tex
			piece.set_meta("shape", poly)  # the exact cut: grabbing and the outline use this
			var drawn := PieceMasks.grown(poly)  # drawn a little larger; the mask makes the edge
			piece.polygon = drawn
			piece.uv = drawn
			piece.set_meta("rc", Vector2i(c, r))
			var k: Array = cut.corners
			var centre: Vector2 = (k[r][c] + k[r][c + 1] + k[r + 1][c] + k[r + 1][c + 1]) * 0.25
			piece.set_meta("centre", Vector2(centre.x * cell.x, centre.y * cell.y))
			var cluster := Node2D.new()
			cluster.add_child(piece)
			# scatter: anywhere on the table, mostly off the board
			var home := Vector2(c * cell.x, r * cell.y)
			var spot := Vector2.ZERO
			for _i in range(12):
				spot = Vector2(rng.randf_range(table.position.x, table.end.x - cell.x), rng.randf_range(table.position.y, table.end.y - cell.y))
				if not Rect2(Vector2.ZERO, size).grow(-cell.x * 0.5).has_point(spot + cell * 0.5):
					break
			cluster.position = spot - home
			cluster.set_meta("scatter", cluster.position)
			pieces_root.add_child(cluster)
			clusters.append(cluster)
	if rotation_on:
		var turns := RandomNumberGenerator.new()
		turns.seed = seed_value * 31 + 7
		for cl in clusters:
			_set_turn(cl, turns.randi_range(0, 3))
	# smooth edges: one baked mask per piece
	var pieces := []
	var shapes := []
	for cl in clusters:
		pieces.append(cl.get_child(0))
		shapes.append(cl.get_child(0).get_meta("shape"))
	var t0 := Time.get_ticks_msec()
	mask_scale = PieceMasks.apply(self, pieces, shapes, size)
	mask_ms = Time.get_ticks_msec() - t0
	print("Jigsaw by Pagouro: %d edge masks baked in %d ms" % [pieces.size(), mask_ms])
	# the tray takes the pieces in a shuffled order, the way they would fall out of a box
	var order := clusters.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = order[i]; order[i] = order[j]; order[j] = t
	for c in order:
		c.set_meta("tray_rank", order.find(c))
	if tray_mode:
		_fill_tray()
	_draw_board()
	_fit_camera()
	started_ms = Time.get_ticks_msec()
	progress.emit(0, rows * cols)


func piece_total() -> int:
	return rows * cols


## Switch between pieces on the table and pieces in the tray. Loose single pieces move between the two; anything already
## joined or placed stays on the table, pulled into view if the smaller tray-mode table would hide it.
func set_tray_mode(on: bool) -> void:
	tray_mode = on
	if texture == null:
		return
	if on:
		_fill_tray()
		var view := _table_rect(true)
		for c in clusters:
			if c.visible and c.position != Vector2.ZERO:
				var centre := _cluster_centre(c)
				var inside := Vector2(clamp(centre.x, view.position.x, view.end.x), clamp(centre.y, view.position.y, view.end.y))
				c.position += inside - centre
	else:
		for c in tray:
			c.visible = true
			c.position = c.get_meta("scatter")
		tray.clear()
		tray_changed.emit()
	_fit_camera()


func _fill_tray() -> void:
	for c in clusters:
		if c.get_child_count() == 1 and c.position != Vector2.ZERO and not tray.has(c):
			c.visible = false
			tray.append(c)
	tray.sort_custom(func(x, y): return x.get_meta("tray_rank") < y.get_meta("tray_rank"))
	tray_changed.emit()


func _cluster_centre(c: Node2D) -> Vector2:
	var sum := Vector2.ZERO
	for p in c.get_children():
		sum += p.get_meta("centre")
	return c.transform * (sum / max(1, c.get_child_count()))


func _table_rect(for_tray: bool) -> Rect2:
	var size := texture.get_size()
	var margin := TRAY_MARGIN if for_tray else MARGIN
	var table := Rect2(-size * margin, size * (1.0 + 2.0 * margin))
	# match the window's shape, so a wide screen gets more table at the sides and a tall one more above and below
	var view := get_viewport_rect().size - Vector2(0, 104 + (tray_height if for_tray else 0.0))
	if view.x > 0 and view.y > 0:
		var want: float = view.x / view.y
		var have: float = table.size.x / table.size.y
		if have < want:
			table = table.grow_individual((table.size.y * want - table.size.x) * 0.5, 0, (table.size.y * want - table.size.x) * 0.5, 0)
		else:
			table = table.grow_individual(0, (table.size.x / want - table.size.y) * 0.5, 0, (table.size.x / want - table.size.y) * 0.5)
	return table


func _draw_board() -> void:
	for child in board.get_children():
		child.queue_free()
	var size := texture.get_size()
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	# the board is a shade off the table, darker on a light table and lighter on a dark one
	frame.color = table_color.darkened(0.07) if table_color.get_luminance() > 0.45 else table_color.lightened(0.10)
	board.add_child(frame)
	if show_ghost:
		var ghost := Sprite2D.new()
		ghost.texture = texture
		ghost.centered = false
		ghost.modulate = Color(1, 1, 1, 0.12)
		board.add_child(ghost)
	for node in BelleStyle.frame_nodes(size):
		board.add_child(node)


func set_table_color(c: Color) -> void:
	table_color = c
	RenderingServer.set_default_clear_color(c)
	if texture:
		_draw_board()


func set_ghost(on: bool) -> void:
	show_ghost = on
	if texture:
		_draw_board()


## Height of the screen's top bar, set by main; the title's own lines on a phone make it taller.
var top_bar := 64.0
var mask_scale := 0.0  # mask pixels per picture pixel (self-test report)
var mask_ms := 0  # how long the masks took to bake (self-test report)
func _fit_camera() -> void:
	var table := _table_rect(tray_mode)
	var view := get_viewport_rect().size
	var bottom_bar := 40.0 + (tray_height if tray_mode else 0.0)
	var usable := Vector2(view.x, max(100.0, view.y - top_bar - bottom_bar))
	var z: float = min(usable.x / table.size.x, usable.y / table.size.y)
	camera.zoom = Vector2(z, z)
	camera.position = table.get_center() + Vector2(0, (bottom_bar - top_bar) * 0.5 / z)
	fit_zoom = z
	fit_centre = camera.position


## Glide the view to frame the finished picture in the space above a card of `reserved_bottom` pixels.
func focus_board(reserved_bottom: float) -> void:
	var size := texture.get_size() * 1.08  # the frame and its scrolls
	var view := get_viewport_rect().size
	var usable := Vector2(view.x * 0.9, max(80.0, view.y - top_bar - reserved_bottom - 16.0))
	var z: float = min(usable.x / size.x, usable.y / size.y)
	var centre_screen_y := top_bar + 8.0 + usable.y * 0.5
	var target := texture.get_size() * 0.5 + Vector2(0, (view.y * 0.5 - centre_screen_y) / z)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera, "zoom", Vector2(z, z), 0.9)
	t.tween_property(camera, "position", target, 0.9)


func _ready() -> void:
	glow = BorderGlow.new()
	add_child(glow)  # after the pieces, so it draws over them
	get_viewport().size_changed.connect(func(): if texture and not is_solved: _fit_camera())


func screen_to_world(screen: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen


func _cluster_at(world: Vector2) -> Node2D:
	for i in range(pieces_root.get_child_count() - 1, -1, -1):
		var cluster: Node2D = pieces_root.get_child(i)
		if not cluster.visible or cluster.has_meta("locked") or cluster.has_meta("turning"):
			continue  # placed pieces are locked down
		var local := cluster.transform.affine_inverse() * world
		for piece in cluster.get_children():
			if piece is Polygon2D and Geometry2D.is_point_in_polygon(local, piece.get_meta("shape")):
				return cluster
	return null


## The tray hands a piece over: it leaves the tray and follows the finger, centred under it.
func begin_drag_from_tray(cluster: Node2D, screen: Vector2) -> void:
	tray.erase(cluster)
	tray_changed.emit()
	var world := screen_to_world(screen)
	cluster.visible = true
	cluster.position += world - _cluster_centre(cluster)
	pieces_root.move_child(cluster, pieces_root.get_child_count() - 1)
	dragging = cluster
	drag_offset = cluster.position - world


func drag_to(screen: Vector2) -> void:
	if dragging:
		dragging.position = screen_to_world(screen) + drag_offset


func end_drag(screen: Vector2) -> void:
	if dragging == null:
		return
	var dropped := dragging
	dragging = null
	# dropped back over the tray: a loose piece goes back in, at the front
	if tray_mode and screen.y > get_viewport_rect().size.y - tray_height and dropped.get_child_count() == 1:
		dropped.visible = false
		tray.push_front(dropped)
		tray_changed.emit()
		return
	_settle(dropped)


func _unhandled_input(event: InputEvent) -> void:
	if is_solved or texture == null:
		return
	# two fingers on a phone: pinch to zoom, move together to pan (a piece being carried is put down first)
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			if dragging:
				end_drag(get_viewport().get_mouse_position())
			panning = false
			var pts: Array = _touches.values()
			_pinch_dist = pts[0].distance_to(pts[1])
			_pinch_mid = (pts[0] + pts[1]) * 0.5
		return
	if event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 2:
			var pts: Array = _touches.values()
			var dist: float = pts[0].distance_to(pts[1])
			var mid: Vector2 = (pts[0] + pts[1]) * 0.5
			if _pinch_dist > 0.0:
				zoom_at(mid, dist / _pinch_dist)
			pan_by(mid - _pinch_mid)
			_pinch_dist = dist
			_pinch_mid = mid
			get_viewport().set_input_as_handled()
		return
	if _touches.size() >= 2:
		return  # the emulated mouse from the first finger is ignored while pinching
	# trackpads and mice on a computer
	if event is InputEventMagnifyGesture:
		zoom_at(event.position, event.factor)
		return
	if event is InputEventPanGesture:
		pan_by(-event.delta * 12.0)
		return
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		zoom_at(event.position, 1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and rotation_on:
		var turned := _cluster_at(screen_to_world(event.position))
		if turned:
			turn_cluster(turned)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var world := screen_to_world(event.position)
			var hit := _cluster_at(world)
			_press_screen = event.position
			_press_ms = Time.get_ticks_msec()
			if hit:
				dragging = hit
				drag_offset = hit.position - world
				pieces_root.move_child(hit, pieces_root.get_child_count() - 1)
			else:
				panning = true  # dragging the empty table moves the view
			get_viewport().set_input_as_handled()
		elif dragging:
			# a tap (no real movement, quickly let go) turns the piece instead of dropping it
			if rotation_on and event.position.distance_to(_press_screen) < 12.0 and Time.get_ticks_msec() - _press_ms < 400:
				var tapped := dragging
				dragging = null
				turn_cluster(tapped)
			else:
				end_drag(event.position)
			get_viewport().set_input_as_handled()
		else:
			panning = false
	elif event is InputEventMouseMotion and dragging:
		drag_to(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and panning:
		pan_by(event.relative)
		get_viewport().set_input_as_handled()


## Zoom by `factor` keeping the point under `screen` fixed; never further out than the whole table, never past MAX_ZOOM.
func zoom_at(screen: Vector2, factor: float) -> void:
	var before := screen_to_world(screen)
	var z: float = clamp(camera.zoom.x * factor, fit_zoom, fit_zoom * MAX_ZOOM)
	camera.zoom = Vector2(z, z)
	camera.position += before - screen_to_world(screen)
	_clamp_camera()


## Move the view by a screen-space amount (the table follows the finger).
func pan_by(screen_delta: Vector2) -> void:
	camera.position -= screen_delta / camera.zoom.x
	_clamp_camera()


## Keep the view over the table: at the whole-table zoom it sits exactly where the fit put it; zoomed in, its centre
## stays over the table.
func _clamp_camera() -> void:
	if camera.zoom.x <= fit_zoom * 1.001:
		camera.position = fit_centre
		return
	var table := _table_rect(tray_mode)
	camera.position = Vector2(clamp(camera.position.x, table.position.x, table.end.x), clamp(camera.position.y, table.position.y, table.end.y))


## Everything needed to put this puzzle back exactly as it is (the cut itself is rebuilt from its seed).
func snapshot() -> Dictionary:
	var out := []
	for c in clusters:
		var rcs := []
		for p in c.get_children():
			var rc: Vector2i = p.get_meta("rc")
			rcs.append([rc.x, rc.y])
		out.append({"pieces": rcs, "x": c.position.x, "y": c.position.y, "locked": c.has_meta("locked"), "tray": tray.find(c), "turn": turn_of(c)})
	return {"clusters": out, "elapsed": (Time.get_ticks_msec() - started_ms) / 1000.0}


## Put a freshly built puzzle (same picture, count, seed and cut) back into a saved state.
func restore(data: Dictionary) -> void:
	var by_rc := {}
	for c in clusters:
		by_rc[c.get_child(0).get_meta("rc")] = c
	tray.clear()
	var in_tray := []
	for entry in data.get("clusters", []):
		var rcs: Array = entry.pieces
		var first: Node2D = by_rc.get(Vector2i(int(rcs[0][0]), int(rcs[0][1])))
		if first == null:
			continue
		for k in range(1, rcs.size()):
			var other: Node2D = by_rc.get(Vector2i(int(rcs[k][0]), int(rcs[k][1])))
			if other and other != first and clusters.has(other):
				_merge(first, other)
		first.set_meta("turn", int(entry.get("turn", 0)))
		first.rotation = int(entry.get("turn", 0)) * PI / 2.0
		first.position = Vector2(float(entry.x), float(entry.y))
		first.visible = true
		if entry.get("locked", false):
			first.set_meta("locked", true)
			pieces_root.move_child(first, 0)
		if int(entry.get("tray", -1)) >= 0:
			in_tray.append([int(entry.tray), first])
	in_tray.sort_custom(func(a, b): return a[0] < b[0])
	for t in in_tray:
		t[1].visible = false
		tray.append(t[1])
	tray_changed.emit()
	border_done = _border_complete()  # a restored puzzle does not replay the glow
	started_ms = Time.get_ticks_msec() - int(float(data.get("elapsed", 0.0)) * 1000.0)
	progress.emit(piece_total() - clusters.size() + 1, piece_total())


## After a drop: join any neighbouring cluster that sits at (nearly) the same position, and snap to the board.
func _settle(cluster: Node2D) -> void:
	var snap := cell.x * SNAP_FRACTION
	var dropped := {}
	for p in cluster.get_children():
		dropped[p.get_meta("rc")] = true
	var was_locked := cluster.has_meta("locked")
	var joined_any := false
	var joined := true
	while joined:
		joined = false
		for other in clusters:
			if other == cluster or not is_instance_valid(other) or not other.visible:
				continue
			if turn_of(cluster) == turn_of(other) and cluster.position.distance_to(other.position) <= snap and _are_neighbours(cluster, other):
				_merge(other, cluster)  # keep the one already in place, move the dropped pieces into it
				cluster = other
				joined = true
				joined_any = true
				break
	if cluster.position.length() <= snap and turn_of(cluster) == 0:
		cluster.position = Vector2.ZERO
	if _is_home(cluster):
		_lock(cluster)
	if joined_any or (_is_home(cluster) and not was_locked):
		_pulse_neighbours(cluster, dropped)
		placed.emit()
	if not border_done and _border_complete():
		border_done = true
		glow.play(texture.get_size())
		border_finished.emit()
	progress.emit(piece_total() - clusters.size() + 1, piece_total())
	if clusters.size() == 1 and _is_home(cluster):
		is_solved = true
		# the seams melt away: the finished picture shows whole
		var fade := create_tween().set_parallel(true)
		for piece in cluster.get_children():
			if piece.material:
				fade.tween_property(piece.material, "shader_parameter/rim", 0.0, 1.2)
				fade.tween_property(piece.material, "shader_parameter/solid", 1.0, 1.2)
		solved.emit((Time.get_ticks_msec() - started_ms) / 1000.0)


## In its true place on the board a cluster locks (Eric, 2026-10-04: in his commercial jigsaw a placed piece "locks
## down", and he likes it). Building stays free on the table; only finished work is fixed, so a careless drag can't
## knock it loose. Locked work sits beneath loose pieces, and gives a small glint as it settles.
func _lock(cluster: Node2D) -> void:
	var first := not cluster.has_meta("locked")
	cluster.set_meta("locked", true)
	pieces_root.move_child(cluster, 0)
	cluster.modulate = Color(1.22, 1.18, 1.08)
	create_tween().tween_property(cluster, "modulate", Color.WHITE, 0.45 if first else 0.3)


## The pieces a drop just fitted against give a soft pulse (Eric, 2026-10-04: his commercial app "mildly pulses the
## pieces directly attached when you drop a piece in"). When the drop only met the board, the dropped pieces pulse.
func _pulse_neighbours(cluster: Node2D, dropped: Dictionary) -> void:
	var hit := []
	for p in cluster.get_children():
		var rc: Vector2i = p.get_meta("rc")
		if dropped.has(rc):
			continue
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if dropped.has(rc + d):
				hit.append(p)
				break
	if hit.is_empty():
		for p in cluster.get_children():
			if dropped.has(p.get_meta("rc")):
				hit.append(p)
	for p in hit:
		p.modulate = Color(1.28, 1.24, 1.12)
		create_tween().tween_property(p, "modulate", Color.WHITE, 0.35).set_ease(Tween.EASE_OUT)


## Every border piece is on the board and locked.
func _border_complete() -> bool:
	for c in clusters:
		var home := c.position == Vector2.ZERO and c.has_meta("locked")
		if home:
			continue
		for p in c.get_children():
			var rc: Vector2i = p.get_meta("rc")
			if rc.x == 0 or rc.y == 0 or rc.x == cols - 1 or rc.y == rows - 1:
				return false
	return true


## In its true place: at the origin and the right way up.
func _is_home(c: Node2D) -> bool:
	return c.position == Vector2.ZERO and turn_of(c) == 0


func turn_of(c: Node2D) -> int:
	return int(c.get_meta("turn", 0))


## Set a cluster's quarter turns at once, turning it about its own centre.
func _set_turn(c: Node2D, turn: int) -> void:
	var about := _cluster_centre(c)
	var delta := (turn - turn_of(c)) * PI / 2.0
	c.position = about + (c.position - about).rotated(delta)
	c.rotation = turn * PI / 2.0
	c.set_meta("turn", turn)


## A tap: turn a quarter clockwise about the cluster's centre, briskly animated, then settle (it may now fit).
func turn_cluster(c: Node2D) -> void:
	if c.has_meta("turning") or c.has_meta("locked"):
		return
	var about := _cluster_centre(c)
	var from_pos := c.position
	var from_rot := c.rotation
	var turn := (turn_of(c) + 1) % 4
	c.set_meta("turning", true)
	c.set_meta("turn", turn)
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(a: float):
		c.rotation = from_rot + a
		c.position = about + (from_pos - about).rotated(a), 0.0, PI / 2.0, 0.14)
	tw.tween_callback(func():
		if not is_instance_valid(c):
			return
		c.rotation = turn * PI / 2.0
		c.position = about + (from_pos - about).rotated(PI / 2.0)
		c.remove_meta("turning")
		if clusters.has(c):
			_settle(c))


## Menu: Rotation. Turning it on spins the loose single pieces (tray included); turning it off sets every loose
## piece upright where it lies.
func set_rotation_mode(on: bool) -> void:
	rotation_on = on
	if texture == null or is_solved:
		return
	for c in clusters:
		if c.has_meta("locked") or c.has_meta("hinting"):
			continue
		if on and c.get_child_count() == 1:
			_set_turn(c, randi_range(0, 3))
		elif not on and turn_of(c) != 0:
			_set_turn(c, 0)
	tray_changed.emit()


func _are_neighbours(a: Node2D, b: Node2D) -> bool:
	var cells_b := {}
	for p in b.get_children():
		cells_b[p.get_meta("rc")] = true
	for p in a.get_children():
		var rc: Vector2i = p.get_meta("rc")
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if cells_b.has(rc + d):
				return true
	return false


func _merge(into: Node2D, from: Node2D) -> void:
	for p in from.get_children():
		from.remove_child(p)
		into.add_child(p)
	clusters.erase(from)
	from.queue_free()
	if into.has_meta("locked"):
		pieces_root.move_child(into, 0)
	else:
		pieces_root.move_child(into, pieces_root.get_child_count() - 1)


## The Help hint: one loose piece glides to its place, the way a friend sitting down at the table would help (Eric,
## 2026-10-04: the old grid-order choice was "very engineery"; random is "funner"). While the border is unfinished it
## picks border pieces; after that, pieces that fit against work already on the board; failing both, any loose piece;
## and when nothing loose is left, the smallest cluster still off the board. Within that choice it picks at random, and
## stays away from pieces another hint is already carrying, so one Help's pieces land in different places.
## Returns false when there is nothing to help with.
func hint() -> bool:
	if is_solved or dragging:
		return false
	var placed := {}
	var flying := {}
	for c in clusters:
		if _is_home(c) and c.visible:
			for p in c.get_children():
				placed[p.get_meta("rc")] = true
		if c.has_meta("hinting"):
			for p in c.get_children():
				flying[p.get_meta("rc")] = true
	var border_open := not _border_complete()
	var tiers := [[], [], []]  # 0: border while it is open, 1: fits placed work, 2: any loose piece
	var smallest: Node2D = null
	for c in clusters:
		if (_is_home(c) and c.visible) or c.has_meta("hinting"):
			continue
		if c.get_child_count() > 1:
			if smallest == null or c.get_child_count() < smallest.get_child_count():
				smallest = c
			continue
		var rc: Vector2i = c.get_child(0).get_meta("rc")
		var on_border := rc.x == 0 or rc.y == 0 or rc.x == cols - 1 or rc.y == rows - 1
		var fits := false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if placed.has(rc + d):
				fits = true
		if border_open and on_border:
			tiers[0].append(c)
		elif fits:
			tiers[1].append(c)
		else:
			tiers[2].append(c)
	var best: Node2D = null
	for tier in tiers:
		if tier.is_empty():
			continue
		# spread: prefer pieces at least two cells from any piece already on its way
		var apart: Array = tier.filter(func(c):
			var rc: Vector2i = c.get_child(0).get_meta("rc")
			for f in flying:
				if absi(f.x - rc.x) + absi(f.y - rc.y) < 3:
					return false
			return true)
		var pool: Array = apart if not apart.is_empty() else tier
		best = pool[randi() % pool.size()]
		break
	if best == null:
		best = smallest
	if best == null:
		return false
	if tray.has(best):
		tray.erase(best)
		tray_changed.emit()
		# it rises from the bottom of the view, where the tray is
		var view := get_viewport_rect().size
		best.position += screen_to_world(Vector2(view.x * 0.5, view.y - tray_height * 0.5)) - _cluster_centre(best)
		best.visible = true
	best.set_meta("hinting", true)
	pieces_root.move_child(best, pieces_root.get_child_count() - 1)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(best, "position", Vector2.ZERO, 0.9)
	if turn_of(best) != 0:
		t.parallel().tween_property(best, "rotation", 0.0 if turn_of(best) <= 2 else TAU, 0.9)
	best.set_meta("turn", 0)
	t.tween_callback(func():
		if is_instance_valid(best) and clusters.has(best):
			best.remove_meta("hinting")
			best.rotation = 0.0
			_settle(best))
	return true


## How many pieces one Help places: about one per 24 pieces of the puzzle (12 and 25 get 1, 49 gets 2, 100 gets 4,
## 156 gets 7), so help is worth about the same share of any puzzle (Eric, 2026-10-04). Past halfway it scales with
## what is left instead, down to one (Eric: "if you only have 10 pieces left ... and a help does 6 of them is that
## what we want?"): count twice the pieces still to place, capped at the whole puzzle.
func hint_count() -> int:
	return max(1, int(round(min(piece_total(), 2 * pieces_left()) / 24.0)))


## Pieces not yet locked in their true place.
func pieces_left() -> int:
	var n := 0
	for c in clusters:
		if not (c.position == Vector2.ZERO and c.has_meta("locked")):
			n += c.get_child_count()
	return n


## Test helper: move every cluster home and settle, one by one (used by the self-test, never by the player).
func solve_all_for_test() -> void:
	tray.clear()
	tray_changed.emit()
	for c in clusters.duplicate():
		if is_instance_valid(c) and clusters.has(c):
			c.visible = true
			c.set_meta("turn", 0)
			c.rotation = 0.0
			c.position = Vector2.ZERO
			_settle(c)
