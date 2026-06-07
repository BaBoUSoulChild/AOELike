extends Node2D

class_name ResourceNode

enum Type { WOOD, GOLD }

signal depleted(node: ResourceNode)

var resource_type: Type = Type.WOOD
var quantity: int = 50

const HALF_W: float = 24.0
const HALF_H: float = 12.0
const COLOR_WOOD: Color = Color(0.55, 0.33, 0.10, 1.0)
const COLOR_GOLD: Color = Color(0.95, 0.78, 0.10, 1.0)

var _poly: Polygon2D = null

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	_poly = Polygon2D.new()
	_poly.polygon = _make_diamond(HALF_W, HALF_H)
	_poly.color = COLOR_WOOD if resource_type == Type.WOOD else COLOR_GOLD
	add_child(_poly)

	var border := Line2D.new()
	border.points = PackedVector2Array([
		Vector2(0.0, -HALF_H), Vector2(HALF_W, 0.0),
		Vector2(0.0, HALF_H), Vector2(-HALF_W, 0.0),
		Vector2(0.0, -HALF_H),
	])
	border.default_color = Color(0.1, 0.1, 0.1, 0.6)
	border.width = 1.5
	add_child(border)

func _make_diamond(hw: float, hh: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -hh), Vector2(hw, 0.0),
		Vector2(0.0, hh), Vector2(-hw, 0.0),
	])

func collect(amount: int) -> int:
	var taken: int = mini(amount, quantity)
	quantity -= taken
	var ratio: float = float(quantity) / 50.0
	_poly.color = (_make_base_color()).lerp(Color(0.25, 0.20, 0.15, 1.0), 1.0 - ratio)
	if quantity <= 0:
		emit_signal("depleted", self)
		queue_free()
	return taken

func _make_base_color() -> Color:
	return COLOR_WOOD if resource_type == Type.WOOD else COLOR_GOLD

func contains_point(world_pos: Vector2) -> bool:
	var local: Vector2 = world_pos - global_position
	return (absf(local.x) / HALF_W + absf(local.y) / HALF_H) <= 1.0
