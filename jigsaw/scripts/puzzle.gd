class_name Puzzle
extends Node2D
## The puzzle table. Works in the picture's own pixel space: the board is the picture's rectangle at (0, 0), pieces are
## Polygon2D nodes textured with the picture, grouped in clusters (Node2D). A piece's place inside its cluster is its home
## position, so two clusters fit together exactly when their positions are equal: snapping and joining compare cluster
## positions only. The camera fits the whole table (board plus a scatter margin) to the window.

signal solved(seconds: float)
signal progress(joined: int, total: int)

const SNAP_FRACTION := 0.18   # snap when within this fraction of a cell
const MARGIN := 0.3           # scatter margin around the board, as a fraction of the board size

var texture: Texture2D
var rows := 0
var cols := 0
var cell := Vector2.ZERO
var clusters: Array[Node2D] = []
var dragging: Node2D = null
var drag_offset := Vector2.ZERO
var started_ms := 0
var is_solved := false
var show_ghost := true

@onready var camera: Camera2D = $Camera2D
@onready var board: Node2D = $Board
@onready var pieces_root: Node2D = $Pieces


func build(tex: Texture2D, piece_count: int, seed_value: int) -> void:
	for c in clusters:
		c.queue_free()
	clusters.clear()
	is_solved = false
	texture = tex
	var size := tex.get_size()
	# a grid near the asked count with near-square cells
	cols = max(2, int(round(sqrt(piece_count * size.x / size.y))))
	rows = max(2, int(round(float(piece_count) / cols)))
	cell = Vector2(size.x / cols, size.y / rows)
	var edges := PieceShape.make_edges(rows, cols, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + 13
	var table := _table_rect()
	for r in range(rows):
		for c in range(cols):
			var signs := PieceShape.piece_signs(edges, rows, cols, r, c)
			var unit := PieceShape.outline(signs)
			var home := Vector2(c * cell.x, r * cell.y)
			var poly := PackedVector2Array()
			var uv := PackedVector2Array()
			for p in unit:
				var px := home + Vector2(p.x * cell.x, p.y * cell.y)
				poly.append(px)
				uv.append(px)
			var piece := Polygon2D.new()
			piece.texture = tex
			piece.polygon = poly
			piece.uv = uv
			piece.set_meta("rc", Vector2i(c, r))
			var edge := Line2D.new()
			edge.points = poly
			edge.closed = true
			edge.width = max(1.5, cell.x * 0.012)
			edge.default_color = Color(BelleStyle.INK, 0.5)
			edge.joint_mode = Line2D.LINE_JOINT_ROUND
			piece.add_child(edge)
			var cluster := Node2D.new()
			cluster.add_child(piece)
			# scatter: anywhere on the table, mostly off the board
			var spot := Vector2.ZERO
			for _i in range(12):
				spot = Vector2(rng.randf_range(table.position.x, table.end.x - cell.x), rng.randf_range(table.position.y, table.end.y - cell.y))
				if not Rect2(Vector2.ZERO, size).grow(-cell.x * 0.5).has_point(spot + cell * 0.5):
					break
			cluster.position = spot - home
			pieces_root.add_child(cluster)
			clusters.append(cluster)
	_draw_board()
	_fit_camera()
	started_ms = Time.get_ticks_msec()
	progress.emit(0, rows * cols)


func piece_total() -> int:
	return rows * cols


func _table_rect() -> Rect2:
	var size := texture.get_size()
	var table := Rect2(-size * MARGIN, size * (1.0 + 2.0 * MARGIN))
	# match the window's shape, so a wide screen gets more table at the sides and a tall one more above and below
	var view := get_viewport_rect().size - Vector2(0, 104)
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
	frame.color = BelleStyle.PAPER_DEEP
	board.add_child(frame)
	if show_ghost:
		var ghost := Sprite2D.new()
		ghost.texture = texture
		ghost.centered = false
		ghost.modulate = Color(1, 1, 1, 0.12)
		board.add_child(ghost)
	for node in BelleStyle.frame_nodes(size):
		board.add_child(node)


func set_ghost(on: bool) -> void:
	show_ghost = on
	if texture:
		_draw_board()


func _fit_camera() -> void:
	var table := _table_rect()
	var view := get_viewport_rect().size
	var top_bar := 64.0
	var bottom_bar := 40.0
	var usable := Vector2(view.x, max(100.0, view.y - top_bar - bottom_bar))
	var z: float = min(usable.x / table.size.x, usable.y / table.size.y)
	camera.zoom = Vector2(z, z)
	camera.position = table.get_center() + Vector2(0, (bottom_bar - top_bar) * 0.5 / z)


## Glide the view to frame the finished picture in the space above a card of `reserved_bottom` pixels.
func focus_board(reserved_bottom: float) -> void:
	var size := texture.get_size() * 1.08  # the frame and its scrolls
	var view := get_viewport_rect().size
	var top_bar := 64.0
	var usable := Vector2(view.x * 0.9, max(80.0, view.y - top_bar - reserved_bottom - 16.0))
	var z: float = min(usable.x / size.x, usable.y / size.y)
	var centre_screen_y := top_bar + 8.0 + usable.y * 0.5
	var target := texture.get_size() * 0.5 + Vector2(0, (view.y * 0.5 - centre_screen_y) / z)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera, "zoom", Vector2(z, z), 0.9)
	t.tween_property(camera, "position", target, 0.9)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and texture:
		_fit_camera()


func _ready() -> void:
	get_viewport().size_changed.connect(func(): if texture: _fit_camera())


func _cluster_at(world: Vector2) -> Node2D:
	for i in range(pieces_root.get_child_count() - 1, -1, -1):
		var cluster: Node2D = pieces_root.get_child(i)
		var local := world - cluster.position
		for piece in cluster.get_children():
			if piece is Polygon2D and Geometry2D.is_point_in_polygon(local, piece.polygon):
				return cluster
	return null


func _unhandled_input(event: InputEvent) -> void:
	if is_solved or texture == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var world := get_global_mouse_position()
		if event.pressed:
			var hit := _cluster_at(world)
			if hit:
				dragging = hit
				drag_offset = hit.position - world
				pieces_root.move_child(hit, pieces_root.get_child_count() - 1)
				get_viewport().set_input_as_handled()
		elif dragging:
			var dropped := dragging
			dragging = null
			_settle(dropped)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		dragging.position = get_global_mouse_position() + drag_offset
		get_viewport().set_input_as_handled()


## After a drop: join any neighbouring cluster that sits at (nearly) the same position, and snap to the board.
func _settle(cluster: Node2D) -> void:
	var snap := cell.x * SNAP_FRACTION
	var joined := true
	while joined:
		joined = false
		for other in clusters:
			if other == cluster or not is_instance_valid(other):
				continue
			if cluster.position.distance_to(other.position) <= snap and _are_neighbours(cluster, other):
				_merge(other, cluster)  # keep the one already in place, move the dropped pieces into it
				cluster = other
				joined = true
				break
	if cluster.position.length() <= snap:
		cluster.position = Vector2.ZERO
	progress.emit(piece_total() - clusters.size() + 1, piece_total())
	if clusters.size() == 1 and cluster.position == Vector2.ZERO:
		is_solved = true
		# the seams melt away: the finished picture shows whole
		var fade := create_tween().set_parallel(true)
		for piece in cluster.get_children():
			for edge in piece.get_children():
				if edge is Line2D:
					fade.tween_property(edge, "modulate:a", 0.0, 1.2)
		solved.emit((Time.get_ticks_msec() - started_ms) / 1000.0)


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
	pieces_root.move_child(into, pieces_root.get_child_count() - 1)


## Test helper: move every cluster home and settle, one by one (used by the self-test, never by the player).
func solve_all_for_test() -> void:
	for c in clusters.duplicate():
		if is_instance_valid(c) and clusters.has(c):
			c.position = Vector2.ZERO
			_settle(c)
