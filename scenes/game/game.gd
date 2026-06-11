extends Node2D

const MAP_W: int = 20
const MAP_H: int = 20

const TILE_W: int = 128
const TILE_H: int = 64

const GRASS_SCALE: float = TILE_W / 132.0
const GRASS_TEXTURES: Array[Texture2D] = [
	preload("res://assets/shared/terrain/grass_a.png"),
	preload("res://assets/shared/terrain/grass_b.png"),
]

const WOOD_COUNT: int = 15
const GOLD_COUNT: int = 8
const TC_TILE: Vector2i = Vector2i(5, 10)

@onready var _camera: Camera2D          = $IsoCamera
@onready var _map_container: Node2D     = $MapContainer
@onready var _units_container: Node2D   = $UnitsContainer
@onready var _ui_label: Label           = $UILayer/InfoLabel
@onready var _resource_label: Label     = $UILayer/ResourceLabel
@onready var _back_button: Button       = $UILayer/BackButton
@onready var _fullscreen_button: Button = $UILayer/FullscreenButton

var _villager: Villager = null
var _selected_unit: Villager = null
var _town_center: TownCenter = null

var _wood: int = 0
var _gold: int = 0
var _resource_nodes: Array[ResourceNode] = []
var _occupied_tiles: Dictionary = {}

var _touch_moved: bool = false
var _touch_start_pos: Vector2 = Vector2.ZERO
const TOUCH_DRAG_THRESHOLD: float = 20.0

func _ready() -> void:
	_generate_tilemap()
	_spawn_town_center()
	_spawn_resources()
	_spawn_villager()
	_setup_camera_limits()
	_update_info_label(false)
	_update_resource_label()
	_back_button.pressed.connect(_on_back_pressed)
	_fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			(function(){
				var c = document.getElementById('canvas') || document.querySelector('canvas');
				if (!c) return;
				c.setAttribute('tabindex', '0');
				c.focus();
				document.addEventListener('click', function(){ c.focus(); });
				document.addEventListener('keydown', function(e){ e.stopPropagation(); });
			})();
		""")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_fullscreen_pressed() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_fullscreen_button.text = "⛶ Plein écran"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_fullscreen_button.text = "✕ Fenêtré"

# -------------------------------------------------------------------------------
# Town Center
# -------------------------------------------------------------------------------
func _spawn_town_center() -> void:
	_town_center = TownCenter.new()
	_town_center.position = _tile_to_screen(TC_TILE.x, TC_TILE.y)
	_units_container.add_child(_town_center)
	_occupied_tiles[TC_TILE] = true

# -------------------------------------------------------------------------------
# Ressources
# -------------------------------------------------------------------------------
func _spawn_resources() -> void:
	_spawn_resource_batch(ResourceNode.Type.WOOD, WOOD_COUNT)
	_spawn_resource_batch(ResourceNode.Type.GOLD, GOLD_COUNT)

func _spawn_resource_batch(type: ResourceNode.Type, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var spawned: int = 0
	var attempts: int = 0
	while spawned < count and attempts < 500:
		attempts += 1
		var tx: int = rng.randi_range(0, MAP_W - 1)
		var ty: int = rng.randi_range(0, MAP_H - 1)
		var tile := Vector2i(tx, ty)
		if _occupied_tiles.has(tile):
			continue
		if Vector2(tile).distance_to(Vector2(MAP_W / 2, MAP_H / 2)) < 3.0:
			continue
		_occupied_tiles[tile] = true
		var node := ResourceNode.new()
		node.resource_type = type
		node.position = _tile_to_screen(tx, ty)
		node.depleted.connect(_on_resource_depleted)
		_units_container.add_child(node)
		_resource_nodes.append(node)
		spawned += 1

func _on_resource_depleted(node: ResourceNode) -> void:
	var idx: int = _resource_nodes.find(node)
	if idx >= 0:
		_resource_nodes.remove_at(idx)

# -------------------------------------------------------------------------------
# Villageois
# -------------------------------------------------------------------------------
func _spawn_villager() -> void:
	var scene_path := "res://scenes/entities/villager.tscn"
	if ResourceLoader.exists(scene_path):
		var packed: PackedScene = load(scene_path)
		_villager = packed.instantiate() as Villager
	else:
		_villager = Villager.new()
	_villager.position = _tile_to_screen(MAP_W / 2, MAP_H / 2)
	_units_container.add_child(_villager)
	_villager.selected.connect(_on_villager_selected)
	_villager.collected.connect(_on_villager_collected)
	_villager.collecting_started.connect(_on_villager_collecting_started)

func _on_villager_selected(_v: Villager) -> void:
	_selected_unit = _villager
	_update_info_label(true)

func _on_villager_collecting_started() -> void:
	_ui_label.text = "Collecte en cours..."

func _on_villager_collected(resource_type: int, amount: int) -> void:
	if resource_type == ResourceNode.Type.WOOD:
		_wood += amount
	else:
		_gold += amount
	_update_resource_label()
	_ui_label.text = "+%d %s déposé" % [amount, "bois" if resource_type == ResourceNode.Type.WOOD else "or"]
	await get_tree().create_timer(1.5).timeout
	if _selected_unit != null:
		_update_info_label(true)

# -------------------------------------------------------------------------------
# Labels UI
# -------------------------------------------------------------------------------
func _update_info_label(has_selection: bool) -> void:
	if has_selection:
		_ui_label.text = "Gauche : désélectionner  |  Droit/tap ressource : collecter  |  ZQSD : caméra"
	else:
		_ui_label.text = "Gauche : sélectionner  |  ZQSD/molette : caméra  |  Glisser (mobile)"

func _update_resource_label() -> void:
	_resource_label.text = "Bois: %d   Or: %d" % [_wood, _gold]

# -------------------------------------------------------------------------------
# Génération de la carte
# -------------------------------------------------------------------------------
func _generate_tilemap() -> void:
	for tx in range(MAP_W):
		for ty in range(MAP_H):
			var tile := Sprite2D.new()
			tile.texture = GRASS_TEXTURES[(tx + ty) % 2]
			tile.scale = Vector2(GRASS_SCALE, GRASS_SCALE)
			tile.position = _tile_to_screen(tx, ty)
			_map_container.add_child(tile)

# -------------------------------------------------------------------------------
# Caméra
# -------------------------------------------------------------------------------
func _setup_camera_limits() -> void:
	var corners: Array[Vector2] = [
		_tile_to_screen(0, 0), _tile_to_screen(MAP_W - 1, 0),
		_tile_to_screen(0, MAP_H - 1), _tile_to_screen(MAP_W - 1, MAP_H - 1),
	]
	var min_x: float = corners[0].x
	var max_x: float = corners[0].x
	var min_y: float = corners[0].y
	var max_y: float = corners[0].y
	for c: Vector2 in corners:
		min_x = minf(min_x, c.x)
		max_x = maxf(max_x, c.x)
		min_y = minf(min_y, c.y)
		max_y = maxf(max_y, c.y)
	var margin := 200.0
	_camera.position = _tile_to_screen(MAP_W / 2, MAP_H / 2)
	_camera.set("cam_limit_left",   min_x - margin)
	_camera.set("cam_limit_right",  max_x + margin)
	_camera.set("cam_limit_top",    min_y - margin)
	_camera.set("cam_limit_bottom", max_y + margin)

func _process(delta: float) -> void:
	_move_camera_keyboard(delta)

func _move_camera_keyboard(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if dir == Vector2.ZERO:
		return
	var speed: float = 400.0 / _camera.zoom.x
	_camera.position += dir.normalized() * speed * delta
	_camera.position.x = clampf(_camera.position.x,
		_camera.get("cam_limit_left"), _camera.get("cam_limit_right"))
	_camera.position.y = clampf(_camera.position.y,
		_camera.get("cam_limit_top"), _camera.get("cam_limit_bottom"))

# -------------------------------------------------------------------------------
# Inputs
# -------------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).device != -1:
		var mbe := event as InputEventMouseButton
		if mbe.pressed:
			var world_pos: Vector2 = _screen_to_world(mbe.position)
			if mbe.button_index == MOUSE_BUTTON_LEFT:
				_handle_select(world_pos)
			elif mbe.button_index == MOUSE_BUTTON_RIGHT:
				_handle_right_action(world_pos)

	elif event is InputEventScreenTouch:
		var ste := event as InputEventScreenTouch
		if ste.pressed:
			_touch_moved = false
			_touch_start_pos = ste.position
		else:
			if not _touch_moved:
				_handle_tap(_screen_to_world(ste.position))

	elif event is InputEventScreenDrag:
		var sde := event as InputEventScreenDrag
		if sde.position.distance_to(_touch_start_pos) > TOUCH_DRAG_THRESHOLD:
			_touch_moved = true

# -------------------------------------------------------------------------------
# Logique d'action
# -------------------------------------------------------------------------------
func _handle_right_action(world_pos: Vector2) -> void:
	if _selected_unit == null:
		return
	var res: ResourceNode = _find_resource_at(world_pos)
	if res != null:
		_selected_unit.go_collect(res, _town_center.get_deposit_position())
	else:
		_handle_move(world_pos)

func _handle_tap(world_pos: Vector2) -> void:
	if _selected_unit != null:
		var local: Vector2 = world_pos - _villager.position
		var on_villager: bool = (absf(local.x) / 22.0 + absf(local.y) / 11.0) <= 1.0
		if on_villager:
			_selected_unit.set_selected(false)
			_selected_unit = null
			_update_info_label(false)
			return
		var res: ResourceNode = _find_resource_at(world_pos)
		if res != null:
			_selected_unit.go_collect(res, _town_center.get_deposit_position())
			_ui_label.text = "Collecte en cours..."
		else:
			_handle_move(world_pos)
	else:
		_handle_select(world_pos)

func _handle_select(world_pos: Vector2) -> void:
	if _villager == null:
		return
	var hit: bool = _villager.try_select(world_pos)
	if not hit and _selected_unit != null:
		_selected_unit.set_selected(false)
		_selected_unit = null
		_update_info_label(false)

func _handle_move(world_pos: Vector2) -> void:
	if _selected_unit != null:
		var tile: Vector2i = IsoUtils.round_tile(IsoUtils.screen_to_tile(world_pos))
		if IsoUtils.in_bounds(tile, Vector2i(MAP_W, MAP_H)):
			_selected_unit.move_to(_tile_to_screen(tile.x, tile.y))
			_ui_label.text = "Déplacement vers (%d, %d)" % [tile.x, tile.y]

func _find_resource_at(world_pos: Vector2) -> ResourceNode:
	for node: ResourceNode in _resource_nodes:
		if is_instance_valid(node) and node.contains_point(world_pos):
			return node
	return null

# -------------------------------------------------------------------------------
# Coordonnées
# -------------------------------------------------------------------------------
func _tile_to_screen(tx: int, ty: int) -> Vector2:
	return IsoUtils.tile_to_screen(float(tx), float(ty))

func _screen_to_world(viewport_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * viewport_pos
