class_name PieceShape
extends RefCounted
## Jigsaw cuts. A puzzle of rows x cols cells is cut once, seeded (a given puzzle always cuts the same way): a lattice of
## corners, then one shared polyline per inner edge, so the two pieces on either side of an edge fit exactly. A piece's
## outline is its four edges walked clockwise, in the puzzle's cell units (the whole picture is cols x rows).
##
## Two styles (Eric, 2026-10-04: "the variation of the tabs and blanks ... there is none" and "Random cut or whimsical
## cut: each piece has a unique, irregular shape and size ... some bulbous protrusions and some spiky"):
##   CLASSIC   - a straight grid, but every tab differs: where it sits along the edge, its size, height, lean and neck.
##   WHIMSICAL - corners pushed off the grid (pieces differ in size and lean), edges that wave, and tabs of several
##               kinds: round, bulbous, flat mushroom caps and spiky arrowheads.
## A blank is simply the neighbour's tab seen from the other side, so blanks vary exactly as tabs do.

enum Style { CLASSIC, WHIMSICAL }

const ARC_STEPS := 16
const WAVE_STEPS := 6     # points per straight stretch of a wavy edge


## Cut the whole puzzle. Returns {"corners": [[Vector2]], "h": [[PackedVector2Array]], "v": [[PackedVector2Array]]}.
## h[r][c] runs left to right along the line under row r - 1 (r = 0 .. rows), v[r][c] runs top to bottom along the line
## left of column c (c = 0 .. cols). Border edges are straight.
static func make_cut(rows: int, cols: int, seed_value: int, style: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var whimsical := style == Style.WHIMSICAL
	var corners := []
	for r in range(rows + 1):
		var row := []
		for c in range(cols + 1):
			var p := Vector2(c, r)
			if whimsical:
				# inner corners wander, border corners slide only along their border
				var j := 0.13
				if c > 0 and c < cols:
					p.x += rng.randf_range(-j, j)
				if r > 0 and r < rows:
					p.y += rng.randf_range(-j, j)
			row.append(p)
		corners.append(row)
	var h := []
	for r in range(rows + 1):
		var row := []
		for c in range(cols):
			var inner := r > 0 and r < rows
			row.append(_edge(corners[r][c], corners[r][c + 1], true, inner, rng, whimsical))
		h.append(row)
	var v := []
	for r in range(rows):
		var row := []
		for c in range(cols + 1):
			var inner := c > 0 and c < cols
			row.append(_edge(corners[r][c], corners[r + 1][c], false, inner, rng, whimsical))
		v.append(row)
	return {"corners": corners, "h": h, "v": v}


## The closed outline of piece (r, c), clockwise on screen, in cell units.
static func piece_outline(cut: Dictionary, r: int, c: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	_append(pts, cut.h[r][c], false)        # top, left to right
	_append(pts, cut.v[r][c + 1], false)    # right, top to bottom
	_append(pts, cut.h[r + 1][c], true)     # bottom, right to left
	_append(pts, cut.v[r][c], true)         # left, bottom to top
	return pts


static func _append(pts: PackedVector2Array, edge: PackedVector2Array, reverse: bool) -> void:
	var n := edge.size()
	for i in range(n - 1):  # each edge contributes its start, not its end (the next edge starts there)
		pts.append(edge[n - 1 - i] if reverse else edge[i])


## One edge from a to b, both endpoints included. Points are built in (along, out) space, along 0..1 from a to b and
## out measured in cells; a horizontal edge's tab points down when dir is +1, a vertical edge's points right.
static func _edge(a: Vector2, b: Vector2, horizontal: bool, inner: bool, rng: RandomNumberGenerator, whimsical: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	if not inner:
		out.append(a)
		out.append(b)
		return out
	var t := b - a
	var n := (Vector2(-t.y, t.x) if horizontal else Vector2(t.y, -t.x)).normalized()
	var dir := 1.0 if rng.randi() % 2 == 0 else -1.0
	var len_t := t.length()
	# a gentle wave along the whole edge (whimsical only), zero at both corners so edges meet cleanly
	var wave_amp := rng.randf_range(0.02, 0.055) * (1.0 if rng.randi() % 2 == 0 else -1.0) if whimsical else 0.0
	var wave_k := float(rng.randi_range(1, 2))
	var base := func(x: float) -> float: return wave_amp * sin(PI * x * wave_k)  # zero at both corners
	var profile := _tab_profile(rng, whimsical)  # list of Vector2(along, out) for the tab, out measured from the base line
	var start_x: float = profile[0].x
	var end_x: float = profile[profile.size() - 1].x
	var pt := func(x: float, h: float) -> Vector2: return a + t * x + n * (h + base.call(x)) * dir * len_t
	for i in range(WAVE_STEPS):
		out.append(pt.call(start_x * i / WAVE_STEPS, 0.0))
	for q in profile:
		out.append(pt.call(q.x, q.y))
	for i in range(1, WAVE_STEPS + 1):
		var x: float = lerp(end_x, 1.0, float(i) / WAVE_STEPS)
		out.append(pt.call(x, 0.0))
	return out


## The tab, as (along, out) points from where it leaves the base line to where it returns. Kept inside along
## 0.27 .. 0.73 and at most 0.27 cells out, so two blanks in one piece never meet.
static func _tab_profile(rng: RandomNumberGenerator, whimsical: bool) -> Array:
	var cx := rng.randf_range(0.43, 0.57) if not whimsical else rng.randf_range(0.40, 0.60)
	var kind := "round"
	if whimsical:
		kind = ["round", "round", "bulb", "cap", "point", "point"][rng.randi() % 6]
	var lean := rng.randf_range(-0.025, 0.025) if not whimsical else rng.randf_range(-0.05, 0.05)
	var pts := []
	match kind:
		"point":
			# a spiky arrowhead: narrow neck, barbs, a sharp tip that may lean
			var nw := rng.randf_range(0.035, 0.05)
			var barb := rng.randf_range(0.10, 0.13)
			var neck_h := rng.randf_range(0.05, 0.08)
			var tip := rng.randf_range(0.21, 0.26)
			pts = [Vector2(cx - nw - 0.02, 0.0), Vector2(cx - nw, neck_h * 0.6), Vector2(cx - nw, neck_h),
				Vector2(cx - barb + lean * 0.4, neck_h - 0.015), Vector2(cx + lean, tip),
				Vector2(cx + barb + lean * 0.4, neck_h - 0.015), Vector2(cx + nw, neck_h), Vector2(cx + nw, neck_h * 0.6),
				Vector2(cx + nw + 0.02, 0.0)]
		_:
			var rx := rng.randf_range(0.095, 0.125)
			var ry := rx * rng.randf_range(0.9, 1.1)
			var nw := rng.randf_range(0.045, 0.065)
			if kind == "bulb":     # a big round head on a thin neck
				rx = rng.randf_range(0.125, 0.14)
				ry = rx * rng.randf_range(0.95, 1.08)
				nw = rng.randf_range(0.035, 0.045)
			elif kind == "cap":    # a wide, flat mushroom cap
				rx = rng.randf_range(0.13, 0.145)
				ry = rng.randf_range(0.065, 0.08)
				nw = rng.randf_range(0.04, 0.055)
			nw = min(nw, rx * 0.75)
			var phi := asin(nw / rx)
			var neck_top := rng.randf_range(0.03, 0.06)
			var centre := Vector2(cx + lean, neck_top + ry * cos(phi))
			centre.y = min(centre.y, 0.27 - ry)
			centre.y = max(centre.y, ry * cos(phi) + 0.02)
			pts.append(Vector2(cx - nw - 0.025, 0.0))
			pts.append(Vector2(cx - nw, 0.02))
			# from the lower left of the ellipse, up over the top, down to the lower right (decreasing angle)
			var start := -PI / 2.0 - phi
			var finish := -PI / 2.0 + phi - TAU
			for i in range(ARC_STEPS + 1):
				var ang: float = lerp(start, finish, float(i) / ARC_STEPS)
				pts.append(Vector2(centre.x + rx * cos(ang), centre.y + ry * sin(ang)))
			pts.append(Vector2(cx + nw, 0.02))
			pts.append(Vector2(cx + nw + 0.025, 0.0))
	return pts
