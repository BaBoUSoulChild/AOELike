extends Node2D

class_name ResourceNode

enum Type { WOOD, GOLD }

signal depleted(node: ResourceNode)

var resource_type: Type = Type.WOOD
var quantity: int = 50
var _is_depleted: bool = false

const HALF_W: float = 24.0
const HALF_H: float = 12.0
const COLOR_WOOD: Color = Color(0.55, 0.33, 0.10, 1.0)
const COLOR_GOLD: Color = Color(0.95, 0.78, 0.10, 1.0)
const COLOR_EMPTY: Color = Color(0.78, 0.78, 0.78, 0.55)

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
	if _is_depleted:
		return 0
	var taken: int = mini(amount, quantity)
	quantity -= taken
	if quantity <= 0:
		_is_depleted = true
		_poly.color = COLOR_EMPTY
		emit_signal("depleted", self)
	else:
		var ratio: float = float(quantity) / 50.0
		_poly.color = _make_base_color().lerp(COLOR_EMPTY, 1.0 - ratio)
	return taken

func _make_base_color() -> Color:
	return COLOR_WOOD if resource_type == Type.WOOD else COLOR_GOLD

func contains_point(world_pos: Vector2) -> bool:
	if _is_depleted:
		return false
	var local: Vector2 = world_pos - global_position
	return (absf(local.x) / 64.0 + absf(local.y) / 32.0) <= 1.0
