class_name ExtraTurnBanner
extends Label
## A banner that sweeps across to announce an earned extra turn.
## Fire-and-forget.


func announce(message: String) -> void:
	text = message
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override(&"font_size", 40)
	add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.2))
	add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override(&"outline_size", 6)
	z_index = 120
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.12)
	tween.tween_property(self, "position:y", position.y - 24.0, 0.5)
	tween.parallel().tween_interval(0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
