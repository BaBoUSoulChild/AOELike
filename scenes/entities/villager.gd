extends CharacterBody2D

class_name Villager

signal selected(villager: Villager)
signal collected(resource_type: int, amount: int)
signal collecting_started

enum State { FREE, GOING_TO_RES, COLLECTING, GOING_TO_DEPOT }

@export var move_speed: float = 120.0
@export var collect_interval: float = 1.5
@export var collect_per_tick: int = 10
@export var carry_capacity: int = 30

const ARRIVAL_DIST: float = 32.0

const TEXTURE: Texture2D = preload("res://assets/shared/units/villager.png")
const SPRITE_SCALE: float = 0.7
const SPRITE_OFFSET: Vector2 = Vector2(0.0, -40.0)
const COLOR_RING: Color = Color(1.0, 1.0, 0.3, 1.0)
const COLOR_SELECTED_TINT: Color = Color(1.3, 1.3, 0.85, 1.0)

var is_selected: bool = false
var _state: State = State.FREE
var _target: Vector2 = Vector2.ZERO
var _moving: bool = false

var _target_resource: ResourceNode = null
var _depot_pos: Vector2 = Vector2.ZERO
var _carry_amount: int = 0
var _carry_type: int = 0
var _collect_timer: float = 0.0

var _sprite: Sprite2D
var _ring_poly: Polygon2D

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	_ring_poly = Polygon2D.new()
	_ring_poly.polygon = _make_diamond(28.0, 14.0)
	_ring_poly.color = COLOR_RING
	_ring_poly.visible = false
	add_child(_ring_poly)

	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.offset = SPRITE_OFFSET
	add_child(_sprite)

	var coll := CollisionPolygon2D.new()
	coll.polygon = _make_diamond(22.0, 11.0)
	add_child(coll)

func _make_diamond(half_w: float, half_h: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -half_h), Vector2(half_w, 0.0),
		Vector2(0.0, half_h), Vector2(-half_w, 0.0),
	])

func _process(delta: float) -> void:
	match _state:
		State.FREE:
			if _moving:
				if _move_towards(_target, delta):
					_moving = false
		State.GOING_TO_RES:
			if not is_instance_valid(_target_resource):
				_state = State.FREE
				return
			if _move_towards(_target_resource.position, delta):
				_collect_timer = 0.0
				_state = State.COLLECTING
				emit_signal("collecting_started")
		State.COLLECTING:
			if not is_instance_valid(_target_resource):
				_state = State.GOING_TO_DEPOT
				return
			_collect_timer += delta
			if _collect_timer >= collect_interval:
				_collect_timer = 0.0
				var taken: int = _target_resource.collect(collect_per_tick)
				_carry_type = int(_target_resource.resource_type)
				_carry_amount += taken
				if _carry_amount >= carry_capacity or taken == 0:
					_state = State.GOING_TO_DEPOT
		State.GOING_TO_DEPOT:
			if _move_towards(_depot_pos, delta):
				if _carry_amount > 0:
					emit_signal("collected", _carry_type, _carry_amount)
					_carry_amount = 0
				_state = State.FREE

func _move_towards(dest: Vector2, _delta: float) -> bool:
	var dist: float = position.distance_to(dest)
	if dist < ARRIVAL_DIST:
		velocity = Vector2.ZERO
		return true
	velocity = (dest - position).normalized() * move_speed
	if absf(velocity.x) > 1.0:
		_sprite.flip_h = velocity.x < 0.0
	move_and_slide()
	return false

func move_to(world_pos: Vector2) -> void:
	_target_resource = null
	_carry_amount = 0
	_state = State.FREE
	_target = world_pos
	_moving = true

func go_collect(resource: ResourceNode, depot_pos: Vector2) -> void:
	_target_resource = resource
	_depot_pos = depot_pos
	_carry_amount = 0
	_collect_timer = 0.0
	_state = State.GOING_TO_RES

func set_selected(value: bool) -> void:
	is_selected = value
	_sprite.modulate = COLOR_SELECTED_TINT if value else Color.WHITE
	_ring_poly.visible = value
	if value:
		emit_signal("selected", self)

func try_select(world_pos: Vector2) -> bool:
	var local: Vector2 = world_pos - position
	var in_diamond: bool = (absf(local.x) / 22.0 + absf(local.y) / 11.0) <= 1.0
	if in_diamond:
		set_selected(true)
	return in_diamond
