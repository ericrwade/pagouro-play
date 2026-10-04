class_name PieceShape
extends RefCounted
## Classic jigsaw outlines. A puzzle of rows x cols cells gets one random tab direction per inner edge (seeded, so a
## given puzzle always cuts the same way). Each piece's outline is a closed polygon in cell units (the cell is 1 x 1,
## its top-left at 0,0); tabs reach up to 0.28 of a cell beyond it.

const NECK_X := 0.40      # where the tab's neck starts and ends along the edge (0.40 .. 0.60)
const NECK_H := 0.06      # how far out the neck reaches before the knob
const KNOB_C := 0.17      # knob centre, distance out from the edge
const KNOB_R := 0.11      # knob radius
const ARC_STEPS := 14


## Tab directions for every inner edge: h_edges[r][c] between row r and r+1 at column c; v_edges[r][c] between
## column c and c+1 in row r. +1 means the tab belongs to the first piece and sticks out of it.
static func make_edges(rows: int, cols: int, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var h_edges := []
	for r in range(rows - 1):
		var row := []
		for c in range(cols):
			row.append(1 if rng.randi() % 2 == 0 else -1)
		h_edges.append(row)
	var v_edges := []
	for r in range(rows):
		var row := []
		for c in range(cols - 1):
			row.append(1 if rng.randi() % 2 == 0 else -1)
		v_edges.append(row)
	return {"h": h_edges, "v": v_edges}


## The four edge signs of piece (r, c): top, right, bottom, left. 0 = flat border, +1 = tab out, -1 = tab in.
static func piece_signs(edges: Dictionary, rows: int, cols: int, r: int, c: int) -> Array:
	var top := 0 if r == 0 else -int(edges.h[r - 1][c])
	var bottom := 0 if r == rows - 1 else int(edges.h[r][c])
	var left := 0 if c == 0 else -int(edges.v[r][c - 1])
	var right := 0 if c == cols - 1 else int(edges.v[r][c])
	return [top, right, bottom, left]


## One edge from a to b (cell units), with its tab pushed out along the outward normal when sign is +1, in when -1.
static func _edge(a: Vector2, b: Vector2, sign_value: int, out: PackedVector2Array) -> void:
	var t := b - a
	var n := Vector2(t.y, -t.x)  # outward normal for a clockwise outline
	if sign_value == 0:
		out.append(a)
		return
	var s := float(sign_value)
	var p := func(x: float, h: float) -> Vector2: return a + t * x + n * (h * s)
	out.append(a)
	out.append(p.call(NECK_X - 0.02, 0.0))
	out.append(p.call(NECK_X, NECK_H))
	# the knob: a circle arc in (along, out) space from the left neck point over the top to the right neck point
	var radius := Vector2(NECK_X - 0.5, NECK_H - KNOB_C).length()
	var left_angle := atan2(NECK_H - KNOB_C, NECK_X - 0.5)
	var right_angle := atan2(NECK_H - KNOB_C, 0.5 - NECK_X)
	var end_angle := right_angle - TAU
	for i in range(1, ARC_STEPS):
		var ang: float = lerp(left_angle, end_angle, float(i) / ARC_STEPS)
		out.append(p.call(0.5 + radius * cos(ang), KNOB_C + radius * sin(ang)))
	out.append(p.call(1.0 - NECK_X, NECK_H))
	out.append(p.call(1.0 - NECK_X + 0.02, 0.0))


## The closed outline of piece (r, c) in cell units, clockwise on screen.
static func outline(signs: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	_edge(Vector2(0, 0), Vector2(1, 0), signs[0], pts)
	_edge(Vector2(1, 0), Vector2(1, 1), signs[1], pts)
	_edge(Vector2(1, 1), Vector2(0, 1), signs[2], pts)
	_edge(Vector2(0, 1), Vector2(0, 0), signs[3], pts)
	return pts
