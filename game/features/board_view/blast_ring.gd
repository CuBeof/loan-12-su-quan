class_name BlastRing
extends Node2D
## An expanding explosion ring for a bomb's 3x3 blast. Local board
## coordinates; fire-and-forget.

var _color: Color = Color(1.0, 0.6, 0.2)
var _max_radius: float = 96.0
var _t: float = 0.0


func blast(color: Color, max_radius: float) -> void:
	_color = color
	_max_radius = max_radius
	var tween := create_tween()
	tween.tween_method(_advance, 0.0, 1.0, 0.3)
	tween.tween_callback(queue_free)


func _advance(value: float) -> void:
	_t = value
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - _t
	var radius := lerpf(_max_radius * 0.2, _max_radius, _t)
	# Filled flash core that shrinks, plus an expanding shockwave ring.
	draw_circle(Vector2.ZERO, _max_radius * 0.5 * (1.0 - _t), Color(1.0, 0.95, 0.7, alpha * 0.8))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(_color, alpha), 5.0)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		draw_circle(Vector2.from_angle(angle) * radius, maxf(1.5, 5.0 * alpha), Color(_color, alpha))
