class_name DamagePopup
extends Label
## Floating damage number above the struck combatant. Bigger and red on
## a critical hit. Fire-and-forget: show_number() animates then frees.


func show_number(amount: int, crit: bool) -> void:
	text = ("%d!" % amount) if crit else str(amount)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override(&"font_size", 44 if crit else 26)
	add_theme_color_override(&"font_color", Color(1.0, 0.32, 0.22) if crit else Color(1.0, 0.95, 0.9))
	add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.7))
	add_theme_constant_override(&"outline_size", 5)
	z_index = 100
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 80.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.55).set_delay(0.25)
	if crit:
		scale = Vector2.ONE * 0.6
		tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	queue_free()


## Smaller "+N" gain popup for collected support resources, tinted to the
## resource color. Floats up and fades.
func show_gain(amount: int, color: Color) -> void:
	text = "+%d" % amount
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override(&"font_size", 22)
	add_theme_color_override(&"font_color", color)
	add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.7))
	add_theme_constant_override(&"outline_size", 4)
	z_index = 100
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 55.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.25)
	await tween.finished
	queue_free()

