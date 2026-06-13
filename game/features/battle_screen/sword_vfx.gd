class_name SwordVFX
extends Node2D
## A sword that flies from a matched attack tile toward the target. Pure
## presentation; draws a placeholder blade until `texture` is assigned.
## Fire-and-forget: launch() animates then frees itself.

@export var texture: Texture2D

var _crit: bool = false
var _length: float = 56.0


func launch(from: Vector2, to: Vector2, crit: bool, delay: float = 0.0) -> void:
	_crit = crit
	global_position = from
	rotation = (to - from).angle()
	scale = Vector2.ONE * (1.5 if crit else 1.0)
	modulate.a = 0.0
	queue_redraw()
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.05)
	tween.parallel().tween_property(self, "global_position", to, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.07)
	tween.tween_callback(queue_free)


func _draw() -> void:
	if texture != null:
		draw_texture(texture, -texture.get_size() * 0.5)
		return
	# Placeholder: a blade pointing along +X (the node is rotated to aim).
	var blade := Color(1.0, 0.86, 0.35) if _crit else Color(0.86, 0.92, 1.0)
	var steel := blade.darkened(0.25)
	var l := _length
	draw_colored_polygon(PackedVector2Array([
		Vector2(l * 0.5, 0), Vector2(-l * 0.1, -l * 0.11), Vector2(-l * 0.1, l * 0.11)]), blade)
	draw_line(Vector2(-l * 0.1, -l * 0.22), Vector2(-l * 0.1, l * 0.22), steel, 4.0) # guard
	draw_rect(Rect2(-l * 0.32, -l * 0.05, l * 0.22, l * 0.10), steel) # handle
	# A faint motion streak behind the blade.
	draw_line(Vector2(-l * 0.1, 0), Vector2(-l * 0.6, 0), Color(blade, 0.35), 3.0)
