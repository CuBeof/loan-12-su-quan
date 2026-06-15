class_name ArrowVFX
extends Node2D
## An arrow that flies from a matched attack tile toward the opponent —
## one arrow per attack gem. Pure presentation; draws a placeholder arrow
## until `texture` is assigned. Fire-and-forget.

@export var texture: Texture2D

var _crit: bool = false
var _length: float = 56.0


func launch(from: Vector2, to: Vector2, crit: bool, delay: float = 0.0) -> void:
	_crit = crit
	global_position = from
	rotation = (to - from).angle()
	scale = Vector2.ONE * (1.4 if crit else 1.0)
	modulate.a = 0.0
	queue_redraw()
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.05)
	tween.parallel().tween_property(self, "global_position", to, 0.24) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.07)
	tween.tween_callback(queue_free)


func _draw() -> void:
	if texture != null:
		draw_texture(texture, -texture.get_size() * 0.5)
		return
	# Placeholder arrow pointing along +X (the node is rotated to aim).
	var color := Color(1.0, 0.86, 0.35) if _crit else Color(0.9, 0.94, 1.0)
	var shaft := color.darkened(0.15)
	var l := _length
	draw_line(Vector2(-l * 0.5, 0), Vector2(l * 0.3, 0), shaft, maxf(2.5, l * 0.05)) # shaft
	draw_colored_polygon(PackedVector2Array([
		Vector2(l * 0.5, 0), Vector2(l * 0.22, -l * 0.15), Vector2(l * 0.22, l * 0.15)]), color) # head
	# Fletching at the tail.
	draw_line(Vector2(-l * 0.5, 0), Vector2(-l * 0.62, -l * 0.13), color, 2.5)
	draw_line(Vector2(-l * 0.5, 0), Vector2(-l * 0.62, l * 0.13), color, 2.5)
	# Faint motion streak.
	draw_line(Vector2(-l * 0.5, 0), Vector2(-l * 0.85, 0), Color(color, 0.3), 2.0)
