extends Node2D

class_name ResourceNode

enum Type { WOOD, GOLD }

signal depleted(node: ResourceNode)

var resource_type: Type = Type.WOOD
var quantity: int = 50
var _is_depleted: bool = false

const COLOR_EMPTY: Color = Color(0.6, 0.6, 0.6, 0.6)
const SPRITE_SCALE: float = 0.72

const TEX_WOOD: Texture2D = preload("res://assets/shared/resources/tree.png")
const TEX_GOLD: Texture2D = preload("res://assets/shared/resources/gold_rock.png")
const OFFSET_WOOD: Vector2 = Vector2(0.0, -28.0)
const OFFSET_GOLD: Vector2 = Vector2(0.0, -1.5)

var _sprite: Sprite2D = null

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	_sprite = Sprite2D.new()
	if resource_type == Type.WOOD:
		_sprite.texture = TEX_WOOD
		_sprite.offset = OFFSET_WOOD
	else:
		_sprite.texture = TEX_GOLD
		_sprite.offset = OFFSET_GOLD
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(_sprite)

func collect(amount: int) -> int:
	if _is_depleted:
		return 0
	var taken: int = mini(amount, quantity)
	quantity -= taken
	if quantity <= 0:
		_is_depleted = true
		_sprite.modulate = COLOR_EMPTY
		emit_signal("depleted", self)
	else:
		var ratio: float = float(quantity) / 50.0
		_sprite.modulate = Color.WHITE.lerp(COLOR_EMPTY, 1.0 - ratio)
	return taken

func contains_point(world_pos: Vector2) -> bool:
	if _is_depleted:
		return false
	var local: Vector2 = world_pos - global_position
	return (absf(local.x) / 64.0 + absf(local.y) / 32.0) <= 1.0
