extends Node2D

class_name TownCenter

const HALF_W: float = 52.0
const HALF_H: float = 26.0

func _ready() -> void:
	_build_visual()
	z_index = 5

func _build_visual() -> void:
	var body := Polygon2D.new()
	body.polygon = _make_diamond(HALF_W, HALF_H)
	body.color = Color(0.15, 0.40, 0.85, 1.0)
	add_child(body)

	var roof := Polygon2D.new()
	roof.polygon = _make_diamond(HALF_W * 0.45, HALF_H * 0.45)
	roof.color = Color(0.35, 0.65, 1.0, 1.0)
	add_child(roof)

	var border := Line2D.new()
	border.points = PackedVector2Array([
		Vector2(0.0, -HALF_H), Vector2(HALF_W, 0.0),
		Vector2(0.0, HALF_H), Vector2(-HALF_W, 0.0),
		Vector2(0.0, -HALF_H),
	])
	border.default_color = Color(0.05, 0.15, 0.45, 0.9)
	border.width = 2.5
	add_child(border)

	var lbl := Label.new()
	lbl.text = "TC"
	lbl.position = Vector2(-10.0, -9.0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)

func _make_diamond(hw: float, hh: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -hh), Vector2(hw, 0.0),
		Vector2(0.0, hh), Vector2(-hw, 0.0),
	])

func get_deposit_position() -> Vector2:
	return global_position
