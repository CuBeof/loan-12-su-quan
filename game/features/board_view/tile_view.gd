class_name TileView
extends Node2D
## Visual of one tile. While TileDefinition.texture is empty it draws a
## colored rounded square with a per-type glyph, so the board is fully
## playable before any art exists.

var type: int = 0
var special: int = TileTypes.Special.NONE
var size_px: float = 64.0

var _def: TileDefinition
var _selected: bool = false


func setup(type_: int, special_: int, def: TileDefinition, size_px_: float) -> void:
	type = type_
	special = special_
	_def = def
	size_px = size_px_
	queue_redraw()


func set_special(special_: int) -> void:
	special = special_
	queue_redraw()


func set_selected(selected: bool) -> void:
	_selected = selected
	scale = Vector2.ONE * (1.1 if selected else 1.0)
	queue_redraw()


func _draw() -> void:
	var color := _def.color if _def != null else Color.GRAY
	var half := size_px * 0.5
	var inset := size_px * 0.04
	var rect := Rect2(-half + inset, -half + inset, size_px - inset * 2.0, size_px - inset * 2.0)

	if _def != null and _def.texture != null:
		draw_texture_rect(_def.texture, rect, false)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(int(size_px * 0.18))
		if _selected:
			style.border_color = Color.WHITE
			style.set_border_width_all(maxi(2, int(size_px * 0.05)))
		draw_style_box(style, rect)
		_draw_glyph()
	_draw_special_marker()


func _draw_glyph() -> void:
	var r := size_px * 0.22
	var glyph_color := Color(1, 1, 1, 0.85)
	match type:
		TileTypes.Type.ATTACK:
			var points := PackedVector2Array([Vector2(0, -r), Vector2(r * 0.85, r * 0.8), Vector2(-r * 0.85, r * 0.8)])
			draw_colored_polygon(points, glyph_color)
		TileTypes.Type.HEALTH:
			var w := r * 0.55
			draw_rect(Rect2(-w * 0.5, -r, w, r * 2.0), glyph_color)
			draw_rect(Rect2(-r, -w * 0.5, r * 2.0, w), glyph_color)
		TileTypes.Type.GOLD:
			draw_circle(Vector2.ZERO, r, glyph_color)
			var hole := r * 0.35
			var dark := Color(0, 0, 0, 0.25)
			draw_rect(Rect2(-hole * 0.5, -hole * 0.5, hole, hole), dark)
		TileTypes.Type.ENERGY:
			var points := PackedVector2Array([Vector2(0, -r), Vector2(r * 0.7, 0), Vector2(0, r), Vector2(-r * 0.7, 0)])
			draw_colored_polygon(points, glyph_color)
		TileTypes.Type.EXP:
			draw_colored_polygon(_star_points(r), glyph_color)


func _draw_special_marker() -> void:
	var r := size_px * 0.38
	var marker := Color(1, 1, 1, 0.95)
	var width := maxf(2.0, size_px * 0.05)
	match special:
		TileTypes.Special.SWEEP_H:
			draw_line(Vector2(-r, -r * 0.45), Vector2(r, -r * 0.45), marker, width)
			draw_line(Vector2(-r, r * 0.45), Vector2(r, r * 0.45), marker, width)
		TileTypes.Special.SWEEP_V:
			draw_line(Vector2(-r * 0.45, -r), Vector2(-r * 0.45, r), marker, width)
			draw_line(Vector2(r * 0.45, -r), Vector2(r * 0.45, r), marker, width)
		TileTypes.Special.BOMB:
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, marker, width)
		TileTypes.Special.TRANSFORM:
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, marker, width)
			for i in range(4):
				var angle := TAU * float(i) / 4.0 + TAU / 8.0
				draw_circle(Vector2.from_angle(angle) * r, width * 0.9, marker)


static func _star_points(r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(10):
		var radius := r if i % 2 == 0 else r * 0.45
		var angle := -TAU / 4.0 + TAU * float(i) / 10.0
		points.append(Vector2.from_angle(angle) * radius)
	return points
