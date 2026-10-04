class_name PieceMasks
extends RefCounted
## Smooth piece edges (Eric, 2026-10-04: "build the high-res piece shapes"). A Polygon2D's edge is all-or-nothing per
## pixel and GL Compatibility has no 2D antialiasing that works, so the cut looks grainy. Instead each piece gets a mask:
## its exact shape drawn white at SUPERSAMPLE times the mask resolution, then halved twice, so every edge pixel holds
## its true coverage (16 samples). With mipmaps the mask stays smooth zoomed out, and linear filtering keeps it smooth
## zoomed in. The piece is then drawn slightly larger than its shape and the shader (piece.gdshader) cuts it with the mask.

const SUPERSAMPLE := 4      # render scale over the mask scale (two halvings)
const PAGE := 4096          # one render page; every phone this targets handles 4096-pixel textures
const PAD := 2.0            # mask margin around the shape, in picture pixels
const MASK_PIXELS := 4.5e6  # total mask pixels for a whole puzzle; sets the mask scale whatever the piece count
const SHADER := preload("res://scripts/piece.gdshader")


## How many mask pixels per picture pixel, for shapes whose bounding boxes cover `bbox_area` picture pixels in all.
static func mask_scale(bbox_area: float) -> float:
	return clamp(sqrt(MASK_PIXELS / max(bbox_area, 1.0)), 0.75, 2.0)


## Bake one mask per shape (shapes in picture pixels) and give each piece its material. `host` must be in the tree:
## the render pages are drawn on the spot with RenderingServer.force_draw, so the puzzle is ready the moment build returns.
static func apply(host: Node, pieces: Array, shapes: Array, tex_size: Vector2) -> float:
	var rects := []
	var area := 0.0
	for s in shapes:
		var r := _bounds(s).grow(PAD)
		rects.append(r)
		area += r.get_area()
	var ms := mask_scale(area)
	var rs := ms * SUPERSAMPLE
	# shelf-pack the render rectangles into pages
	var slots := []  # [page, Rect2i in page pixels, mask size]
	var page := 0
	var x := 0
	var y := 0
	var shelf := 0
	for r in rects:
		var mask := Vector2i(ceili(r.size.x * ms), ceili(r.size.y * ms))
		var big := mask * SUPERSAMPLE
		if x + big.x > PAGE:
			x = 0
			y += shelf
			shelf = 0
		if y + big.y > PAGE:
			page += 1
			x = 0
			y = 0
			shelf = 0
		slots.append([page, Rect2i(Vector2i(x, y), big), mask])
		x += big.x
		shelf = max(shelf, big.y)
	for p in range(page + 1):
		var vp := SubViewport.new()
		vp.size = Vector2i(PAGE, PAGE)
		vp.transparent_bg = true
		vp.disable_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		host.add_child(vp)
		# draw straight through the RenderingServer: a Polygon2D only queues its drawing for the next frame, and
		# force_draw would then render an empty page
		var ci := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(ci, vp.find_world_2d().canvas)
		for i in range(shapes.size()):
			if slots[i][0] != p:
				continue
			var poly := PackedVector2Array()
			var origin: Vector2 = rects[i].position
			var at: Vector2 = Vector2(slots[i][1].position)
			for v in shapes[i]:
				poly.append(at + (v - origin) * rs)
			var tris := Geometry2D.triangulate_polygon(poly)
			var colors := PackedColorArray()
			colors.resize(poly.size())
			colors.fill(Color.WHITE)
			RenderingServer.canvas_item_add_triangle_array(ci, tris, poly, colors)
		RenderingServer.force_draw(false)
		var img := vp.get_texture().get_image()
		for i in range(shapes.size()):
			if slots[i][0] != p:
				continue
			var m := img.get_region(slots[i][1])
			m.shrink_x2()
			m.shrink_x2()
			m.convert(Image.FORMAT_L8)
			m.generate_mipmaps()
			var mat := ShaderMaterial.new()
			mat.shader = SHADER
			mat.set_shader_parameter("mask", ImageTexture.create_from_image(m))
			# the mask covers exactly mask-size / ms picture pixels from the rectangle's corner
			var size: Vector2 = Vector2(slots[i][2]) / ms
			mat.set_shader_parameter("rect", Vector4(rects[i].position.x, rects[i].position.y, size.x, size.y))
			mat.set_shader_parameter("tex_size", tex_size)
			mat.set_shader_parameter("rim", 0.6)  # set explicitly: a parameter left at its shader default reads back null, and the finish fade cannot tween it
			mat.set_shader_parameter("solid", 0.0)
			pieces[i].material = mat
		RenderingServer.free_rid(ci)
		vp.queue_free()
	return ms


static func _bounds(poly: PackedVector2Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for v in poly:
		r = r.expand(v)
	return r


## The drawn polygon: the shape pushed out by a picture pixel and a half, so the mask, not the polygon, makes the edge.
static func grown(poly: PackedVector2Array) -> PackedVector2Array:
	var out := Geometry2D.offset_polygon(poly, 1.5, Geometry2D.JOIN_ROUND)
	var best := poly
	var best_area := 0.0
	for o in out:
		var a := absf(_area(o))
		if a > best_area:  # the outer outline; a hole would be smaller
			best = o
			best_area = a
	return best


static func _area(p: PackedVector2Array) -> float:
	var s := 0.0
	for i in range(p.size()):
		s += p[i].cross(p[(i + 1) % p.size()])
	return s * 0.5
