class_name BorderGlow
extends Node2D
## The border is done (Eric, 2026-10-04: "a glow chasing around the edge of the puzzle when you snap in the last edge
## piece"). A short gold light runs once around the board's edge with a fading tail, then is gone. Gold is the D-74 gold.

const SECONDS := 1.8
const TAIL := 0.22          # tail length, as a share of the perimeter
const SEGMENTS := 28        # tail drawn as this many fading pieces

var board_size := Vector2.ZERO
var _t := -1.0              # 0..1 while running; -1 when idle


## Run the light once around a board of `size` (picture pixels, with the board at the origin).
func play(size: Vector2) -> void:
	board_size = size
	_t = 0.0
	visible = true
	var tw := create_tween()
	tw.tween_method(func(v: float):
		_t = v
		queue_redraw(), 0.0, 1.0 + TAIL, SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		_t = -1.0
		queue_redraw())


func _point(s: float) -> Vector2:
	# along the edge clockwise from the top-left corner; s in 0..1 of the perimeter
	var w := board_size.x
	var h := board_size.y
	var d := fposmod(s, 1.0) * 2.0 * (w + h)
	if d < w:
		return Vector2(d, 0)
	d -= w
	if d < h:
		return Vector2(w, d)
	d -= h
	if d < w:
		return Vector2(w - d, h)
	return Vector2(0, h - (d - w))


func _draw() -> void:
	if _t < 0.0:
		return
	var zoom: float = get_viewport().get_canvas_transform().get_scale().x
	var width: float = 6.0 / max(zoom, 0.01)  # about six screen pixels at any zoom
	for i in range(SEGMENTS):
		var a := _t - TAIL * float(i) / SEGMENTS
		var b := _t - TAIL * float(i + 1) / SEGMENTS
		if a < 0.0 or a > 1.0:
			continue
		b = clamp(b, 0.0, 1.0)
		var fade := 1.0 - float(i) / SEGMENTS
		var pts := PackedVector2Array()
		for k in range(5):
			pts.append(_point(lerp(b, a, k / 4.0)))
		draw_polyline(pts, Color(BelleStyle.GOLD, 0.28 * fade), width * 3.2 * (0.5 + 0.5 * fade), true)  # the soft halo
		draw_polyline(pts, Color(BelleStyle.GOLD, fade), width * (0.5 + 0.5 * fade), true)
		if i == 0:
			draw_circle(_point(a), width * 0.9, Color(BelleStyle.PAPER, 0.9))
