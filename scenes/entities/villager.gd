## villager.gd
## Unité villageois placeholder.
## Représentée par un losange vert (Polygon2D).
## Sélectionnable au clic gauche / tap.
## Se déplace vers une destination via lerp (pathfinding simplifié).

extends CharacterBody2D

class_name Villager

# --- Signaux -------------------------------------------------------------------
signal selected(villager: Villager)

# --- Paramètres exportés -------------------------------------------------------
@export var move_speed: float = 120.0          ## pixels/s
@export var color_normal: Color = Color(0.2, 0.75, 0.2, 1.0)
@export var color_selected: Color = Color(0.4, 1.0, 0.4, 1.0)
@export var color_highlight: Color = Color(1.0, 1.0, 0.3, 1.0)  ## anneau de sélection

# --- État -----------------------------------------------------------------------
var is_selected: bool = false
var _target: Vector2 = Vector2.ZERO
var _moving: bool = false

# --- Nœuds (créés dans _ready) --------------------------------------------------
var _body_poly: Polygon2D
var _ring_poly: Polygon2D

# -------------------------------------------------------------------------------
func _ready() -> void:
	_build_visuals()
	z_index = 1

func _build_visuals() -> void:
	# Anneau de sélection (légèrement plus grand, jaune)
	_ring_poly = Polygon2D.new()
	_ring_poly.polygon = _make_diamond(28.0, 14.0)
	_ring_poly.color = color_highlight
	_ring_poly.visible = false
	add_child(_ring_poly)

	# Corps principal (losange vert)
	_body_poly = Polygon2D.new()
	_body_poly.polygon = _make_diamond(22.0, 11.0)
	_body_poly.color = color_normal
	add_child(_body_poly)

	# Collider
	var coll := CollisionPolygon2D.new()
	coll.polygon = _make_diamond(22.0, 11.0)
	add_child(coll)

func _make_diamond(half_w: float, half_h: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -half_h),
		Vector2(half_w, 0.0),
		Vector2(0.0, half_h),
		Vector2(-half_w, 0.0),
	])

# -------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _moving:
		var dist := position.distance_to(_target)
		if dist < 2.0:
			position = _target
			_moving = false
			velocity = Vector2.ZERO
		else:
			var dir := (_target - position).normalized()
			velocity = dir * move_speed
			move_and_slide()

# -------------------------------------------------------------------------------
func set_selected(value: bool) -> void:
	is_selected = value
	_body_poly.color = color_selected if value else color_normal
	_ring_poly.visible = value
	if value:
		emit_signal("selected", self)

func move_to(world_pos: Vector2) -> void:
	_target = world_pos
	_moving = true

# -------------------------------------------------------------------------------
## Appelé par game.gd lors d'un InputEventMouseButton ou ScreenTouch
func try_select(world_pos: Vector2) -> bool:
	# Teste si world_pos est dans le losange (distance de Manhattan approx.)
	var local := world_pos - position
	var in_diamond: bool = (absf(local.x) / 22.0 + absf(local.y) / 11.0) <= 1.0
	if in_diamond:
		set_selected(true)
	return in_diamond
