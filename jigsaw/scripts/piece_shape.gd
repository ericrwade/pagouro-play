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
## How far an inside corner may wander, in cells. Was 0.13, which with unbalanced tabs let one piece have 1.98 times
## the area of another (measured; Eric saw it at once). 0.035 keeps the irregular look with sizes held close (Eric: "rein it in a little").
const JITTER := 0.035
## The area every tab is scaled to, in square cells (about a classic round tab's).
const TAB_AREA := 0.045
## Share of edges flipped after balancing: gives about half two-and-two pieces, the rest mostly three-and-one, a few
## four-and-none (measured in the self-test).
const MIX_FLIP := 0.2
## Under each tab the edge curves gently into the piece that holds it, giving back this share of the tab's area, so a
## four-tab piece is not much bigger than a four-blank one (real die-cut pieces do the same).
const BOW_SHARE := 0.85
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
				var j := JITTER
				if c > 0 and c < cols:
					p.x += rng.randf_range(-j, j)
				if r > 0 and r < rows:
					p.y += rng.randf_range(-j, j)
			row.append(p)
		corners.append(row)
	var dirs := _balanced_dirs(rows, cols, rng)
	var h := []
	for r in range(rows + 1):
		var row := []
		for c in range(cols):
			var inner := r > 0 and r < rows
			row.append(_edge(corners[r][c], corners[r][c + 1], true, inner, dirs.h.get(Vector2i(r, c), 1.0), rng, whimsical))
		h.append(row)
	var v := []
	for r in range(rows):
		var row := []
		for c in range(cols + 1):
			var inner := c > 0 and c < cols
			row.append(_edge(corners[r][c], corners[r + 1][c], false, inner, dirs.v.get(Vector2i(r, c), 1.0), rng, whimsical))
		v.append(row)
	return {"corners": corners, "h": h, "v": v, "dirs": dirs}


## Tab directions, balanced the way real puzzles are: every inside piece gets exactly two tabs out and two blanks in,
## because a piece with four tabs out has far more picture than one with four blanks (measured: up to 1.47 times the area
## in the classic cut with coin-toss tabs). Method: the pieces and their shared edges form a graph; join the odd-degree
## border pieces to one extra node, walk an Euler circuit (Hierholzer) choosing the next edge at random, and give each
## edge's tab to the piece the walk leaves. A circuit leaves every node as often as it enters it, so each piece is
## balanced exactly (border pieces to within one). h[(r, c)] is the edge on the line above row r (+1 = the tab points
## down, out of the piece above); v[(r, c)] is the edge on the line left of column c (+1 = points right).
static func _balanced_dirs(rows: int, cols: int, rng: RandomNumberGenerator) -> Dictionary:
	var edges := []  # [kind, key, piece a, piece b]; +1 gives the tab to a
	for r in range(1, rows):
		for c in range(cols):
			edges.append(["h", Vector2i(r, c), Vector2i(r - 1, c), Vector2i(r, c)])
	for r in range(rows):
		for c in range(1, cols):
			edges.append(["v", Vector2i(r, c), Vector2i(r, c - 1), Vector2i(r, c)])
	var extra := Vector2i(-1, -1)
	var adj := {}
	for e in edges:
		for p in [e[2], e[3]]:
			if not adj.has(p):
				adj[p] = []
	var all_edges := edges.duplicate()
	for p in adj.keys():
		if adj[p].size() == 0:
			pass
	var degree := {}
	for e in edges:
		degree[e[2]] = degree.get(e[2], 0) + 1
		degree[e[3]] = degree.get(e[3], 0) + 1
	adj[extra] = []
	for p in degree.keys():
		if degree[p] % 2 == 1:
			all_edges.append(["x", null, p, extra])
	for i in range(all_edges.size()):
		adj[all_edges[i][2]].append(i)
		adj[all_edges[i][3]].append(i)
	for p in adj.keys():
		var list: Array = adj[p]
		for i in range(list.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = list[i]; list[i] = list[j]; list[j] = t
	var used := []
	used.resize(all_edges.size())
	used.fill(false)
	var out := {"h": {}, "v": {}}
	# Hierholzer, iterative; the graph is connected, so one circuit covers every edge
	var stack: Array = [Vector2i(0, 0)]
	while not stack.is_empty():
		var u: Vector2i = stack[stack.size() - 1]
		var list: Array = adj[u]
		var next_edge := -1
		while not list.is_empty():
			var i: int = list.pop_back()
			if not used[i]:
				next_edge = i
				break
		if next_edge < 0:
			stack.pop_back()
			continue
		used[next_edge] = true
		var e: Array = all_edges[next_edge]
		var w: Vector2i = e[3] if e[2] == u else e[2]
		if e[0] != "x":
			out[e[0]][e[1]] = 1.0 if e[2] == u else -1.0  # the walk leaves u: u gets the tab
		stack.append(w)
	# then roughness: flip about one edge in five, so the puzzle also has three-and-one pieces and the odd four-tab
	# star or four-blank piece (Eric: exact two-and-two everywhere "is not acceptable")
	for kind in ["h", "v"]:
		for key in out[kind].keys():
			if rng.randf() < MIX_FLIP:
				out[kind][key] = -out[kind][key]
	return out


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
static func _edge(a: Vector2, b: Vector2, horizontal: bool, inner: bool, dir: float, rng: RandomNumberGenerator, whimsical: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	if not inner:
		out.append(a)
		out.append(b)
		return out
	var t := b - a
	var n := (Vector2(-t.y, t.x) if horizontal else Vector2(t.y, -t.x)).normalized()
	var len_t := t.length()
	# a gentle wave along the whole edge (whimsical only), zero at both corners so edges meet cleanly
	var wave_amp := rng.randf_range(0.02, 0.055) * (1.0 if rng.randi() % 2 == 0 else -1.0) if whimsical else 0.0
	var wave_k := 2.0  # an S-wave: out as much as in, so it changes the look but not the piece's area
	# the bow: a hump of area BOW_SHARE * TAB_AREA into the tab holder (against the tab's direction); zero at both corners
	var bow := BOW_SHARE * TAB_AREA * PI / 2.0
	var base := func(x: float) -> float: return wave_amp * sin(PI * x * wave_k) - bow * sin(PI * x)
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
	# every tab holds about the same amount of picture whatever its shape (a bulb has several times a spike's area),
	# so pieces stay close in size: scale it about its foot to TAB_AREA, varied by +-8 %
	var area := 0.0
	for i in range(pts.size()):
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[(i + 1) % pts.size()]
		area += p.x * q.y - q.x * p.y
	area = abs(area) * 0.5
	var k := sqrt(TAB_AREA * rng.randf_range(0.92, 1.08) / max(area, 1e-4))
	var scaled := []
	for p in pts:
		scaled.append(Vector2(cx + (p.x - cx) * k, p.y * k))
	return scaled


## Piece areas, measured: [largest / smallest over inside pieces, largest / smallest over all pieces] for one cut.
## Used by the self-test to hold the cut to a size limit (Eric, 2026-10-04: some pieces had "1.5x the landmass" of others).
static func area_report(rows: int, cols: int, seed_value: int, style: int) -> Array:
	var cut := make_cut(rows, cols, seed_value, style)
	var inner := []
	var all := []
	for r in range(rows):
		for c in range(cols):
			var pts := piece_outline(cut, r, c)
			var a := 0.0
			for i in range(pts.size()):
				var p: Vector2 = pts[i]
				var q: Vector2 = pts[(i + 1) % pts.size()]
				a += p.x * q.y - q.x * p.y
			a = abs(a) * 0.5
			all.append(a)
			if r > 0 and c > 0 and r < rows - 1 and c < cols - 1:
				inner.append(a)
	var mix := [0, 0, 0, 0, 0]
	for r in range(1, rows - 1):
		for c in range(1, cols - 1):
			var outs := int(cut.dirs.h[Vector2i(r, c)] < 0) + int(cut.dirs.h[Vector2i(r + 1, c)] > 0) + int(cut.dirs.v[Vector2i(r, c)] < 0) + int(cut.dirs.v[Vector2i(r, c + 1)] > 0)
			mix[outs] += 1
	return [inner.max() / inner.min(), all.max() / all.min(), mix]
