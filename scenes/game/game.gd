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

const VILLAGER_SCENE: PackedScene = preload("res://scenes/entities/villager.tscn")
const VILLAGER_COST_WOOD: int = 50
const POP_CAP: int = 10
const STARTING_WOOD: int = 100
const STARTING_VILLAGERS: int = 3

const GROUP_OFFSETS: Array[Vector2] = [
	Vector2.ZERO, Vector2(44, 0), Vector2(-44, 0),
	Vector2(0, 22), Vector2(0, -22), Vector2(44, 22),
	Vector2(-44, -22), Vector2(44, -22), Vector2(-44, 22), Vector2(88, 0),
]

@onready var _camera: Camera2D          = $IsoCamera
@onready var _map_container: Node2D     = $MapContainer
@onready var _units_container: Node2D   = $UnitsContainer
@onready var _ui_label: Label           = $UILayer/InfoLabel
@onready var _resource_label: Label     = $UILayer/ResourceLabel
@onready var _back_button: Button       = $UILayer/BackButton
@onready var _fullscreen_button: Button = $UILayer/FullscreenButton
@onready var _produce_button: Button    = $UILayer/ProduceButton

var _villagers: Array[Villager] = []
var _selected_units: Array[Villager] = []
var _town_center: TownCenter = null

var _wood: int = STARTING_WOOD
var _gold: int = 0
var _resource_nodes: Array[ResourceNode] = []
var _occupied_tiles: Dictionary = {}

var _touch_moved: bool = false
var _touch_start_pos: Vector2 = Vector2.ZERO
const TOUCH_DRAG_THRESHOLD: float = 20.0

const DRAG_SELECT_THRESHOLD: float = 12.0
var _drag_select_active: bool = false
var _drag_select_start: Vector2 = Vector2.ZERO
var _select_rect: Panel = null

func _ready() -> void:
	_generate_tilemap()
	_spawn_town_center()
	_spawn_resources()
	_spawn_starting_villagers()
	_setup_camera_limits()
	_update_info_label(false)
	_update_resource_label()
	_back_button.pressed.connect(_on_back_pressed)
	_fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	_produce_button.pressed.connect(_on_produce_pressed)
	_build_select_rect()
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
	_town_center.villager_produced.connect(_on_villager_produced)
	_units_container.add_child(_town_center)
	_occupied_tiles[TC_TILE] = true

func _set_tc_selected(value: bool) -> void:
	_town_center.set_selected(value)
	_produce_button.visible = value
	if value:
		_ui_label.text = "Town Center — produire des villageois (%d bois)" % VILLAGER_COST_WOOD

func _on_produce_pressed() -> void:
	if _population_total() >= POP_CAP:
		_ui_label.text = "Population maximum atteinte (%d)" % POP_CAP
		return
	if _wood < VILLAGER_COST_WOOD:
		_ui_label.text = "Pas assez de bois (%d nécessaires)" % VILLAGER_COST_WOOD
		return
	_wood -= VILLAGER_COST_WOOD
	_town_center.enqueue_villager()
	_update_resource_label()

func _on_villager_produced() -> void:
	var tile: Vector2i = _find_free_tile_near(TC_TILE)
	_spawn_villager_at(tile.x, tile.y)
	_update_resource_label()
	_ui_label.text = "Nouveau villageois !"

func _population_total() -> int:
	return _villagers.size() + _town_center.get_queue_size()

func _find_free_tile_near(center: Vector2i) -> Vector2i:
	for offset: Vector2i in [
		Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 1),
		Vector2i(1, -1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1),
		Vector2i(2, 2), Vector2i(0, 2), Vector2i(2, 0),
	]:
		var t: Vector2i = center + offset
		if IsoUtils.in_bounds(t, Vector2i(MAP_W, MAP_H)) and not _occupied_tiles.has(t):
			return t
	return center + Vector2i(1, 1)

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
func _spawn_starting_villagers() -> void:
	var start_tiles: Array[Vector2i] = [
		Vector2i(MAP_W / 2, MAP_H / 2),
		Vector2i(MAP_W / 2 + 1, MAP_H / 2),
		Vector2i(MAP_W / 2, MAP_H / 2 + 1),
	]
	for i in range(mini(STARTING_VILLAGERS, start_tiles.size())):
		_spawn_villager_at(start_tiles[i].x, start_tiles[i].y)

func _spawn_villager_at(tx: int, ty: int) -> void:
	var v: Villager = VILLAGER_SCENE.instantiate() as Villager
	v.position = _tile_to_screen(tx, ty)
	_units_container.add_child(v)
	v.selected.connect(_on_villager_selected)
	v.collected.connect(_on_villager_collected)
	v.collecting_started.connect(_on_villager_collecting_started)
	_villagers.append(v)

func _on_villager_selected(v: Villager) -> void:
	if not _selected_units.has(v):
		_selected_units.append(v)
	_set_tc_selected(false)
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
	if not _selected_units.is_empty():
		_update_info_label(true)

func _deselect_all() -> void:
	for v: Villager in _selected_units:
		if is_instance_valid(v):
			v.set_selected(false)
	_selected_units.clear()

# -------------------------------------------------------------------------------
# Labels UI
# -------------------------------------------------------------------------------
func _update_info_label(has_selection: bool) -> void:
	if has_selection:
		var n: int = _selected_units.size()
		if n > 1:
			_ui_label.text = "%d villageois sélectionnés  |  Droit/tap : déplacer ou collecter" % n
		else:
			_ui_label.text = "Gauche : désélectionner  |  Droit/tap ressource : collecter  |  ZQSD : caméra"
	else:
		_ui_label.text = "Gauche : sélectionner  |  ZQSD/molette : caméra  |  Glisser (mobile)"

func _update_resource_label() -> void:
	_resource_label.text = "Bois: %d   Or: %d   Pop: %d/%d" % [_wood, _gold, _population_total(), POP_CAP]

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
	_update_production_status()

func _update_production_status() -> void:
	if _town_center == null or not _town_center.is_selected:
		return
	var queue: int = _town_center.get_queue_size()
	if queue > 0:
		_ui_label.text = "Production : %ds restantes (file : %d)" % [int(ceilf(_town_center.get_time_left())), queue]

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
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).device != -1:
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT:
			if mbe.pressed:
				_drag_select_active = true
				_drag_select_start = mbe.position
			elif _drag_select_active:
				_drag_select_active = false
				_select_rect.visible = false
				if mbe.position.distance_to(_drag_select_start) > DRAG_SELECT_THRESHOLD:
					_select_in_rect(_drag_select_start, mbe.position)
				else:
					_handle_select(_screen_to_world(mbe.position))
		elif mbe.button_index == MOUSE_BUTTON_RIGHT and mbe.pressed:
			_handle_right_action(_screen_to_world(mbe.position))

	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).device != -1:
		if _drag_select_active:
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_drag_select_active = false
				_select_rect.visible = false
			else:
				var mme := event as InputEventMouseMotion
				if mme.position.distance_to(_drag_select_start) > DRAG_SELECT_THRESHOLD:
					_update_select_rect(_drag_select_start, mme.position)

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
# Sélection au rectangle (souris uniquement)
# -------------------------------------------------------------------------------
func _build_select_rect() -> void:
	_select_rect = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.8, 1.0, 0.15)
	style.border_color = Color(0.4, 0.8, 1.0, 0.9)
	style.set_border_width_all(2)
	_select_rect.add_theme_stylebox_override("panel", style)
	_select_rect.visible = false
	_select_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UILayer.add_child(_select_rect)

func _update_select_rect(a: Vector2, b: Vector2) -> void:
	_select_rect.visible = true
	_select_rect.position = Vector2(minf(a.x, b.x), minf(a.y, b.y))
	_select_rect.size = (b - a).abs()

func _select_in_rect(a: Vector2, b: Vector2) -> void:
	var rect := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs())
	var canvas: Transform2D = get_viewport().get_canvas_transform()
	_deselect_all()
	_set_tc_selected(false)
	for v: Villager in _villagers:
		if rect.has_point(canvas * v.position):
			v.set_selected(true)
	if _selected_units.is_empty():
		_update_info_label(false)

# -------------------------------------------------------------------------------
# Logique d'action
# -------------------------------------------------------------------------------
func _handle_right_action(world_pos: Vector2) -> void:
	if _selected_units.is_empty():
		return
	var res: ResourceNode = _find_resource_at(world_pos)
	if res != null:
		for v: Villager in _selected_units:
			v.go_collect(res, _town_center.get_deposit_position())
	else:
		_handle_move(world_pos)

func _handle_tap(world_pos: Vector2) -> void:
	if not _selected_units.is_empty():
		for v: Villager in _selected_units:
			var local: Vector2 = world_pos - v.position
			if (absf(local.x) / 22.0 + absf(local.y) / 11.0) <= 1.0:
				_deselect_all()
				_update_info_label(false)
				return
		var res: ResourceNode = _find_resource_at(world_pos)
		if res != null:
			for v: Villager in _selected_units:
				v.go_collect(res, _town_center.get_deposit_position())
			_ui_label.text = "Collecte en cours..."
		else:
			_handle_move(world_pos)
	else:
		_handle_select(world_pos)

func _handle_select(world_pos: Vector2) -> void:
	_deselect_all()
	for v: Villager in _villagers:
		if v.try_select(world_pos):
			return
	if _town_center.contains_point(world_pos):
		_set_tc_selected(true)
		return
	_set_tc_selected(false)
	_update_info_label(false)

func _handle_move(world_pos: Vector2) -> void:
	if _selected_units.is_empty():
		return
	var tile: Vector2i = IsoUtils.round_tile(IsoUtils.screen_to_tile(world_pos))
	if not IsoUtils.in_bounds(tile, Vector2i(MAP_W, MAP_H)):
		return
	var base: Vector2 = _tile_to_screen(tile.x, tile.y)
	for i in range(_selected_units.size()):
		var offset: Vector2 = GROUP_OFFSETS[i % GROUP_OFFSETS.size()]
		_selected_units[i].move_to(base + offset)
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
