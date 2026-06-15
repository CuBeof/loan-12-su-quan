class_name LightningBolt
extends Node2D
## A jagged lightning bolt striking a destroyed cell (match-5 / L-T random
## destruction). Drawn from above the target down to it. Fire-and-forget.

var _target: Vector2 = Vector2.ZERO
var _points: PackedVector2Array
var _t: float = 0.0
var _color: Color = Color(0.7, 0.85, 1.0)


func strike(target: Vector2, color: Color = Color(0.7, 0.85, 1.0)) -> void:
	_target = target
	_color = color
	_build_path()
	var tween := create_tween()
	tween.tween_method(_advance, 0.0, 1.0, 0.22)
	tween.tween_callback(queue_free)


func _build_path() -> void:
	# A zig-zag from ~3 cells above straight down to the target.
	_points = PackedVector2Array()
	var start := _target + Vector2(0, -220)
	var segments := 7
	for i in range(segments + 1):
		var f := float(i) / float(segments)
		var base := start.lerp(_target, f)
		var jitter := 0.0 if i == 0 or i == segments else randf_range(-16.0, 16.0)
		_points.append(base + Vector2(jitter, 0))


func _advance(value: float) -> void:
	_t = value
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - _t
	# Glow + bright core along the bolt.
	for i in range(_points.size() - 1):
		draw_line(_points[i], _points[i + 1], Color(_color, alpha * 0.5), 7.0)
		draw_line(_points[i], _points[i + 1], Color(1, 1, 1, alpha), 2.5)
	# Impact flash at the target.
	draw_circle(_target, lerpf(6.0, 26.0, _t), Color(_color, alpha * 0.7))
