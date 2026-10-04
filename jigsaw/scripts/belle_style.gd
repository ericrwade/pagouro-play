class_name BelleStyle
extends RefCounted
## The Pagouro look, kept subtle (Eric, 2026-10-03: "a tiny bit less clean than Cupertino would build … I want the BE feel
## to resonate very subtly"): paper and ink colours, a period serif, thin double rules and small corner scrolls.
## Controls and spacing stay modern; ornament never sits on top of the picture or the text.

const PAPER := Color("efe3c6")        # D-74 poster cream
const PAPER_DEEP := Color("d9c9a6")   # D-74 poster cream, one step down
const INK := Color("332822")          # D-74 warm black (never pure black)
const INK_SOFT := Color(0.2, 0.157, 0.133, 0.72)
const GOLD := Color("a8823a")         # D-74 gold ochre
const GREEN := Color("3a4a34")        # D-74 sage, darkest

const TITLE_FONT := "res://fonts/CormorantGaramond.ttf"
const TEXT_FONT := "res://fonts/EBGaramond.ttf"


static func font(path: String, weight: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = load(path)
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return f


static func title_font() -> FontVariation:
	return font(TITLE_FONT, 600)


static func box(fill: Color, border: Color, border_width: int, radius: int, pad: Vector4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad.x
	s.content_margin_top = pad.y
	s.content_margin_right = pad.z
	s.content_margin_bottom = pad.w
	return s


## The close mark every card and menu carries in its top-right corner.
static func close_x(on_close: Callable) -> Button:
	var x := Button.new()
	x.text = "×"
	x.flat = true
	x.tooltip_text = "Close"
	x.custom_minimum_size = Vector2(44, 44)  # a fingertip's worth
	x.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	x.add_theme_font_override("font", title_font())
	x.add_theme_font_size_override("font_size", 34)
	for c in ["font_color", "font_focus_color"]:
		x.add_theme_color_override(c, INK)
	for c in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		x.add_theme_color_override(c, GOLD)
	x.pressed.connect(on_close)
	return x


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = font(TEXT_FONT, 450)
	t.default_font_size = 17
	for cls in ["Label", "Button", "OptionButton"]:
		t.set_color("font_color", cls, INK)
	t.set_color("font_hover_color", "Button", GREEN)
	t.set_color("font_pressed_color", "Button", GREEN)
	t.set_color("font_hover_color", "OptionButton", GREEN)
	# a focused button (e.g. Done, which takes focus when it appears) keeps readable ink, not the engine's pale default
	for cls in ["Button", "OptionButton"]:
		t.set_color("font_focus_color", cls, GREEN)
		t.set_color("font_hover_pressed_color", cls, GREEN)
	var normal := box(PAPER, Color(INK, 0.55), 1, 3, Vector4(12, 4, 12, 5))
	var hover := box(PAPER.lightened(0.25), GOLD, 1, 3, Vector4(12, 4, 12, 5))
	var pressed := box(PAPER_DEEP, GREEN, 1, 3, Vector4(12, 4, 12, 5))
	for cls in ["Button", "OptionButton"]:
		t.set_stylebox("normal", cls, normal)
		t.set_stylebox("hover", cls, hover)
		t.set_stylebox("pressed", cls, pressed)
		t.set_stylebox("hover_pressed", cls, pressed)
		t.set_stylebox("focus", cls, StyleBoxEmpty.new())
	t.set_stylebox("panel", "PopupMenu", box(PAPER, Color(INK, 0.4), 1, 3, Vector4(6, 6, 6, 6)))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", GREEN)
	return t


## A small Art Nouveau scroll: a tightening spiral that ends in a short tail along the frame. `origin` is where the tail
## meets the frame corner, `along` and `inward` are unit directions, `size` the scroll's span.
static func scroll_points(origin: Vector2, along: Vector2, inward: Vector2, size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var tail := origin + along * size * 1.6
	pts.append(origin)
	pts.append(tail)
	var centre := tail + inward * size * 0.42 + along * size * 0.10
	var start_dir := (tail - centre).normalized()
	var start_angle := atan2(start_dir.y, start_dir.x)
	var turn := 1.0 if along.cross(inward) > 0 else -1.0
	var steps := 28
	var r0 := (tail - centre).length()
	for i in range(1, steps + 1):
		var f := float(i) / steps
		var ang := start_angle + turn * f * TAU * 0.85
		var r := r0 * (1.0 - 0.62 * f)
		pts.append(centre + Vector2(cos(ang), sin(ang)) * r)
	return pts


## The board's frame: two thin rules a little outside the picture, and a pair of scrolls at each corner.
static func frame_nodes(size: Vector2) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var unit: float = max(size.x, size.y)
	var gap := unit * 0.012
	var w_outer: float = max(2.0, unit * 0.0035)
	var w_inner: float = max(1.0, unit * 0.0015)
	for spec in [[gap * 2.2, w_outer, GOLD], [gap, w_inner, Color(INK, 0.5)]]:
		var g: float = spec[0]
		var line := Line2D.new()
		line.antialiased = true  # smooth curved edges (2D MSAA is unavailable in GL Compatibility)
		line.points = PackedVector2Array([Vector2(-g, -g), Vector2(size.x + g, -g), Vector2(size.x + g, size.y + g), Vector2(-g, size.y + g)])
		line.closed = true
		line.width = spec[1]
		line.default_color = spec[2]
		line.joint_mode = Line2D.LINE_JOINT_SHARP
		out.append(line)
	var s := unit * 0.035
	var o := gap * 2.2
	var corners := [
		[Vector2(-o, -o), Vector2(1, 0), Vector2(0, 1)], [Vector2(-o, -o), Vector2(0, 1), Vector2(1, 0)],
		[Vector2(size.x + o, -o), Vector2(-1, 0), Vector2(0, 1)], [Vector2(size.x + o, -o), Vector2(0, 1), Vector2(-1, 0)],
		[Vector2(size.x + o, size.y + o), Vector2(-1, 0), Vector2(0, -1)], [Vector2(size.x + o, size.y + o), Vector2(0, -1), Vector2(-1, 0)],
		[Vector2(-o, size.y + o), Vector2(1, 0), Vector2(0, -1)], [Vector2(-o, size.y + o), Vector2(0, -1), Vector2(1, 0)],
	]
	for c in corners:
		var curl := Line2D.new()
		curl.antialiased = true  # smooth curved edges (2D MSAA is unavailable in GL Compatibility)
		# the scroll sits outside the picture: it curls away from the board, never over it
		curl.points = scroll_points(c[0], c[1], -c[2], s)
		curl.width = w_outer * 0.9
		curl.default_color = GOLD
		curl.joint_mode = Line2D.LINE_JOINT_ROUND
		curl.begin_cap_mode = Line2D.LINE_CAP_ROUND
		curl.end_cap_mode = Line2D.LINE_CAP_ROUND
		out.append(curl)
	return out
