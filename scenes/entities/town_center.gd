extends Node2D

class_name TownCenter

signal villager_produced

const TEXTURE: Texture2D = preload("res://assets/shared/buildings/town_center.png")
const SPRITE_SCALE: float = 0.6
const SPRITE_OFFSET: Vector2 = Vector2(0.0, -39.0)
const PRODUCTION_TIME: float = 5.0
const COLOR_SELECTED_TINT: Color = Color(1.25, 1.25, 0.85, 1.0)

var is_selected: bool = false

var _sprite: Sprite2D = null
var _queue: int = 0
var _time_left: float = 0.0

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.offset = SPRITE_OFFSET
	add_child(_sprite)

func _process(delta: float) -> void:
	if _queue <= 0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_queue -= 1
		if _queue > 0:
			_time_left = PRODUCTION_TIME
		emit_signal("villager_produced")

func enqueue_villager() -> void:
	if _queue == 0:
		_time_left = PRODUCTION_TIME
	_queue += 1

func get_queue_size() -> int:
	return _queue

func get_time_left() -> float:
	return _time_left if _queue > 0 else 0.0

func set_selected(value: bool) -> void:
	is_selected = value
	_sprite.modulate = COLOR_SELECTED_TINT if value else Color.WHITE

func contains_point(world_pos: Vector2) -> bool:
	var local: Vector2 = world_pos - global_position
	return (absf(local.x) / 64.0 + absf(local.y) / 32.0) <= 1.0

func get_deposit_position() -> Vector2:
	return global_position
