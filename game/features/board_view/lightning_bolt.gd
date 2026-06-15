class_name LightningBolt
extends Node2D
## A jagged lightning bolt striking a destroyed cell (match-5 / L-T random
## destruction). Drawn from above the target down to it, with a bright hold
## so it is easy to notice, then a fade. Fire-and-forget.

var _target: Vector2 = Vector2.ZERO
var _points: PackedVector2Array
var _t: float = 0.0
var _color: Color = Color(0.7, 0.85, 1.0)
var _flicker: float = 0.0


func strike(target: Vector2, color: Color = Color(0.7, 0.85, 1.0), duration: float = 0.5) -> void:
	_target = target
	_color = color
	_build_path()
	var tween := create_tween()
	tween.tween_method(_advance, 0.0, 1.0, maxf(0.2, duration))
	tween.tween_callback(queue_free)


func _build_path() -> void:
	# A zig-zag from ~3 cells above straight down to the target.
	_points = PackedVector2Array()
	var start := _target + Vector2(0, -240)
	var segments := 8
	for i in range(segments + 1):
		var f := float(i) / float(segments)
		var base := start.lerp(_target, f)
		var jitter := 0.0 if i == 0 or i == segments else randf_range(-18.0, 18.0)
		_points.append(base + Vector2(jitter, 0))


func _advance(value: float) -> void:
	_t = value
	# Re-jitter the bolt a couple of times during the hold for a live arc.
	_flicker = sin(value * 40.0)
	queue_redraw()


func _draw() -> void:
	# Hold bright for the first ~55% of the life, then fade out.
	var alpha := 1.0 if _t < 0.55 else clampf((1.0 - _t) / 0.45, 0.0, 1.0)
	var wobble := _flicker * 3.0
	for i in range(_points.size() - 1):
		var a := _points[i] + Vector2(wobble if i % 2 == 0 else -wobble, 0)
		var b := _points[i + 1] + Vector2(-wobble if i % 2 == 0 else wobble, 0)
		draw_line(a, b, Color(_color, alpha * 0.5), 8.0)
		draw_line(a, b, Color(1, 1, 1, alpha), 3.0)
	# Impact flash at the target that swells then fades.
	var flash := lerpf(10.0, 30.0, minf(_t * 2.0, 1.0))
	draw_circle(_target, flash, Color(_color, alpha * 0.7))
	draw_circle(_target, flash * 0.5, Color(1, 1, 1, alpha * 0.8))
