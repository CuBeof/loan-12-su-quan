class_name SweepBeam
extends Node2D
## A bright beam sweeping along a cleared row or column (the sweeper
## special). Local board coordinates; fire-and-forget.

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _color: Color = Color.WHITE
var _thick: float = 18.0
var _t: float = 0.0


func sweep(from: Vector2, to: Vector2, color: Color, thick: float) -> void:
	_from = from
	_to = to
	_color = color
	_thick = thick
	var tween := create_tween()
	tween.tween_method(_advance, 0.0, 1.0, 0.28)
	tween.tween_callback(queue_free)


func _advance(value: float) -> void:
	_t = value
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - _t
	# Full-length glow that fades, plus a bright core racing along it.
	draw_line(_from, _to, Color(_color, alpha * 0.55), _thick)
	draw_line(_from, _to, Color(1, 1, 1, alpha * 0.6), _thick * 0.4)
	var head := _from.lerp(_to, clampf(_t * 1.4, 0.0, 1.0))
	draw_circle(head, _thick * 0.85, Color(1, 1, 1, alpha))
