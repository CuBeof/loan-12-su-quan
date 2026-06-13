class_name ClearBurst
extends Node2D
## A short expanding ring + sparks where a tile clears, tinted to the
## tile's color. Fire-and-forget: burst() animates then frees.

var _color: Color = Color.WHITE
var _t: float = 0.0
var _max_radius: float = 30.0


func burst(color: Color, cell_px: float = 64.0) -> void:
	_color = color
	_max_radius = cell_px * 0.55
	var tween := create_tween()
	tween.tween_method(_advance, 0.0, 1.0, 0.26)
	tween.tween_callback(queue_free)


func _advance(value: float) -> void:
	_t = value
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - _t
	var ring := lerpf(_max_radius * 0.2, _max_radius, _t)
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 24, Color(_color, alpha * 0.7), 3.0)
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		var pos := Vector2.from_angle(angle) * lerpf(_max_radius * 0.15, _max_radius * 0.9, _t)
		draw_circle(pos, maxf(1.0, 3.0 * (1.0 - _t)), Color(_color, alpha))
