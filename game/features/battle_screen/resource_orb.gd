class_name ResourceOrb
extends Node2D
## A glowing orb that flies from a matched support tile (health/energy/
## gold/exp) to the owner's panel. Pure presentation; draws a placeholder
## orb until `texture` is assigned. Fire-and-forget.

@export var texture: Texture2D

var _color: Color = Color.WHITE
var _radius: float = 15.0


func launch(from: Vector2, to: Vector2, color: Color, delay: float = 0.0) -> void:
	_color = color
	global_position = from
	modulate.a = 0.0
	queue_redraw()
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.06)
	tween.parallel().tween_property(self, "global_position", to, 0.34) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.07)
	tween.tween_callback(queue_free)


func _draw() -> void:
	if texture != null:
		draw_texture(texture, -texture.get_size() * 0.5)
		return
	draw_circle(Vector2.ZERO, _radius, Color(_color, 0.35)) # glow
	draw_circle(Vector2.ZERO, _radius * 0.62, _color) # core
	draw_circle(Vector2(-_radius * 0.22, -_radius * 0.22), _radius * 0.22, Color(1, 1, 1, 0.85)) # highlight
