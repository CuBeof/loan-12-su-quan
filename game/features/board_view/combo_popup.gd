class_name ComboPopup
extends Label
## "Combo xN" flourish, bigger and hotter as the combo climbs.
## Fire-and-forget.


func show_combo(combo: int) -> void:
	text = "COMBO x%d" % combo
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var heat := clampf(float(combo - 2) / 6.0, 0.0, 1.0)
	add_theme_font_size_override(&"font_size", int(lerpf(30.0, 64.0, heat)))
	add_theme_color_override(&"font_color", Color(1.0, lerpf(0.85, 0.35, heat), lerpf(0.4, 0.2, heat)))
	add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.75))
	add_theme_constant_override(&"outline_size", 6)
	z_index = 120
	pivot_offset = size * 0.5
	scale = Vector2.ONE * 0.4
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
