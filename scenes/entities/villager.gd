extends CharacterBody2D

class_name Villager

signal selected(villager: Villager)
signal collected(resource_type: int, amount: int)

enum State { FREE, GOING_TO_RES, COLLECTING, GOING_TO_DEPOT }

@export var move_speed: float = 120.0
@export var color_normal: Color    = Color(0.2, 0.75, 0.2, 1.0)
@export var color_selected: Color  = Color(0.4, 1.0, 0.4, 1.0)
@export var color_highlight: Color = Color(1.0, 1.0, 0.3, 1.0)
@export var collect_interval: float = 1.5
@export var collect_per_tick: int = 10
@export var carry_capacity: int = 30

const ARRIVAL_DIST: float = 8.0

var is_selected: bool = false
var _state: State = State.FREE
var _target: Vector2 = Vector2.ZERO
var _moving: bool = false

var _target_resource: ResourceNode = null
var _depot_pos: Vector2 = Vector2.ZERO
var _carry_amount: int = 0
var _carry_type: int = 0
var _collect_timer: float = 0.0

var _body_poly: Polygon2D
var _ring_poly: Polygon2D

func _ready() -> void:
	_build_visuals()
	z_index = 10

func _build_visuals() -> void:
	_ring_poly = Polygon2D.new()
	_ring_poly.polygon = _make_diamond(28.0, 14.0)
	_ring_poly.color = color_highlight
	_ring_poly.visible = false
	add_child(_ring_poly)

	_body_poly = Polygon2D.new()
	_body_poly.polygon = _make_diamond(22.0, 11.0)
	_body_poly.color = color_normal
	add_child(_body_poly)

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
	_body_poly.color = color_selected if value else color_normal
	_ring_poly.visible = value
	if value:
		emit_signal("selected", self)

func try_select(world_pos: Vector2) -> bool:
	var local: Vector2 = world_pos - position
	var in_diamond: bool = (absf(local.x) / 22.0 + absf(local.y) / 11.0) <= 1.0
	if in_diamond:
		set_selected(true)
	return in_diamond
