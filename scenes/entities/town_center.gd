extends Node2D

class_name TownCenter

const TEXTURE: Texture2D = preload("res://assets/shared/buildings/town_center.png")
const SPRITE_SCALE: float = 0.6
const SPRITE_OFFSET: Vector2 = Vector2(0.0, -39.0)

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.offset = SPRITE_OFFSET
	add_child(sprite)

func get_deposit_position() -> Vector2:
	return global_position
