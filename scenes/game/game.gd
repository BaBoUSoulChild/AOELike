## game.gd
## Scène principale du jeu isométrique (Sprint 2).
## Gère :
##   - Génération de la carte isométrique par code (Polygon2D, pas de TileMapLayer)
##   - Placement et sélection du villageois
##   - Routage des inputs (clic gauche → sélection, clic droit → déplacement)
##   - Double-tap mobile → déplacement
##   - Bouton Menu → retour à main.tscn

extends Node2D

# --- Constantes de carte -------------------------------------------------------
const MAP_W: int = 20
const MAP_H: int = 20

# Couleurs des tuiles (deux tons pour damier lisible)
const COLOR_TILE_A: Color = Color(0.36, 0.55, 0.25, 1.0)  ## herbe claire
const COLOR_TILE_B: Color = Color(0.28, 0.44, 0.18, 1.0)  ## herbe foncée
const COLOR_TILE_BORDER: Color = Color(0.1, 0.1, 0.1, 0.4)

# Taille des tuiles iso (doit correspondre à IsoUtils)
const TILE_W: int = 128
const TILE_H: int = 64

# --- Nœuds (référencés depuis la scène) ----------------------------------------
@onready var _camera: Camera2D = $IsoCamera
@onready var _map_container: Node2D = $MapContainer
@onready var _units_container: Node2D = $UnitsContainer
@onready var _ui_label: Label = $UILayer/InfoLabel
@onready var _back_button: Button = $UILayer/BackButton
@onready var _fullscreen_button: Button = $UILayer/FullscreenButton

# --- État -----------------------------------------------------------------------
var _villager: Villager = null
var _selected_unit: Villager = null

# Double-tap mobile
var _last_tap_time: float = -1.0
var _last_tap_pos: Vector2 = Vector2.ZERO
const DOUBLE_TAP_DELAY: float = 0.35
const DOUBLE_TAP_DIST: float = 40.0

# Détection drag vs tap sur mobile
var _touch_moved: bool = false
var _touch_start_pos: Vector2 = Vector2.ZERO
const TOUCH_DRAG_THRESHOLD: float = 20.0

# -------------------------------------------------------------------------------
func _ready() -> void:
	_generate_tilemap()
	_spawn_villager()
	_setup_camera_limits()
	_update_label(false)
	_back_button.pressed.connect(_on_back_pressed)
	_fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	# Garde le focus sur le canvas pour que ZQSD fonctionne sur PC/Chrome.
	# Le listener re-focalise après chaque clic (sinon le focus part dans le vide).
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
# Label contextuel
# -------------------------------------------------------------------------------
func _update_label(has_selection: bool) -> void:
	if has_selection:
		_ui_label.text = "Clic gauche : désélectionner  |  Clic droit : déplacer  |  ZQSD/molette : caméra"
	else:
		_ui_label.text = "Clic gauche : sélectionner  |  ZQSD/molette : caméra  |  Glisser (mobile)"

# -------------------------------------------------------------------------------
# Génération de la carte
# -------------------------------------------------------------------------------
func _generate_tilemap() -> void:
	# On crée les tuiles iso en tant que Polygon2D dans un Node2D.
	# Chaque tuile = losange (4 points).
	for tx in range(MAP_W):
		for ty in range(MAP_H):
			var screen_pos := _tile_to_screen(tx, ty)
			var tile := Polygon2D.new()
			tile.polygon = _make_tile_polygon()
			tile.color = COLOR_TILE_A if (tx + ty) % 2 == 0 else COLOR_TILE_B
			tile.position = screen_pos
			# Bord
			var border := Line2D.new()
			border.points = _make_tile_border()
			border.default_color = COLOR_TILE_BORDER
			border.width = 1.0
			tile.add_child(border)
			_map_container.add_child(tile)

func _make_tile_polygon() -> PackedVector2Array:
	var hw: float = TILE_W / 2.0
	var hh: float = TILE_H / 2.0
	return PackedVector2Array([
		Vector2(0.0,  -hh),
		Vector2(hw,    0.0),
		Vector2(0.0,   hh),
		Vector2(-hw,   0.0),
	])

func _make_tile_border() -> PackedVector2Array:
	var hw: float = TILE_W / 2.0
	var hh: float = TILE_H / 2.0
	return PackedVector2Array([
		Vector2(0.0,  -hh),
		Vector2(hw,    0.0),
		Vector2(0.0,   hh),
		Vector2(-hw,   0.0),
		Vector2(0.0,  -hh),   # fermeture
	])

# -------------------------------------------------------------------------------
# Caméra
# -------------------------------------------------------------------------------
func _setup_camera_limits() -> void:
	# Calcule les extremes de la carte pour borner la caméra
	var corners: Array[Vector2] = [
		_tile_to_screen(0, 0),
		_tile_to_screen(MAP_W - 1, 0),
		_tile_to_screen(0, MAP_H - 1),
		_tile_to_screen(MAP_W - 1, MAP_H - 1),
	]
	var min_x := corners[0].x
	var max_x := corners[0].x
	var min_y := corners[0].y
	var max_y := corners[0].y
	for c in corners:
		min_x = minf(min_x, c.x)
		max_x = maxf(max_x, c.x)
		min_y = minf(min_y, c.y)
		max_y = maxf(max_y, c.y)

	var margin := 200.0
	_camera.position = _tile_to_screen(MAP_W / 2, MAP_H / 2)
	# Passe les limites via les propriétés publiques d'iso_camera.gd (cam_limit_*)
	_camera.set("cam_limit_left",   min_x - margin)
	_camera.set("cam_limit_right",  max_x + margin)
	_camera.set("cam_limit_top",    min_y - margin)
	_camera.set("cam_limit_bottom", max_y + margin)

# -------------------------------------------------------------------------------
# Villageois
# -------------------------------------------------------------------------------
func _spawn_villager() -> void:
	var scene_path := "res://scenes/entities/villager.tscn"
	var packed: PackedScene
	if ResourceLoader.exists(scene_path):
		packed = load(scene_path)
		_villager = packed.instantiate() as Villager
	else:
		# Fallback : instancie directement le script
		_villager = Villager.new()

	# Positionne au centre de la carte
	_villager.position = _tile_to_screen(MAP_W / 2, MAP_H / 2)
	_villager.z_index = 10
	_units_container.add_child(_villager)
	_villager.selected.connect(_on_villager_selected)

func _on_villager_selected(_v: Villager) -> void:
	_selected_unit = _villager
	_update_label(true)

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
	# --- Souris ------------------------------------------------------------------
	if event is InputEventMouseButton and (event as InputEventMouseButton).device != -1:
		var mbe := event as InputEventMouseButton
		if mbe.pressed:
			var world_pos := _screen_to_world(mbe.position)
			if mbe.button_index == MOUSE_BUTTON_LEFT:
				_handle_select(world_pos)
			elif mbe.button_index == MOUSE_BUTTON_RIGHT:
				_handle_move(world_pos)

	# --- Tactile -----------------------------------------------------------------
	elif event is InputEventScreenTouch:
		var ste := event as InputEventScreenTouch
		if ste.pressed:
			_touch_moved = false
			_touch_start_pos = ste.position
		elif not ste.pressed:
			var world_pos := _screen_to_world(ste.position)
			if _touch_moved:
				_ui_label.text = "TAP BLOQUÉ (drag détecté)"
			elif _selected_unit != null:
				var local := world_pos - _villager.position
				var on_villager := (absf(local.x) / 22.0 + absf(local.y) / 11.0) <= 1.0
				if on_villager:
					_selected_unit.set_selected(false)
					_selected_unit = null
					_update_label(false)
				else:
					_handle_move(world_pos)
			else:
				_handle_select(world_pos)

	elif event is InputEventScreenDrag:
		if (event as InputEventScreenDrag).position.distance_to(_touch_start_pos) > TOUCH_DRAG_THRESHOLD:
			_touch_moved = true

func _handle_select(world_pos: Vector2) -> void:
	if _villager == null:
		return
	var hit := _villager.try_select(world_pos)
	if not hit and _selected_unit != null:
		_selected_unit.set_selected(false)
		_selected_unit = null
		_update_label(false)

func _handle_move(world_pos: Vector2) -> void:
	if _selected_unit != null:
		var tile := IsoUtils.round_tile(IsoUtils.screen_to_tile(world_pos))
		if IsoUtils.in_bounds(tile, Vector2i(MAP_W, MAP_H)):
			var dest := _tile_to_screen(tile.x, tile.y)
			_selected_unit.move_to(dest)
			_ui_label.text = "Déplacement vers (%d, %d)" % [tile.x, tile.y]

# -------------------------------------------------------------------------------
# Conversions de coordonnées
# -------------------------------------------------------------------------------
func _tile_to_screen(tx: int, ty: int) -> Vector2:
	return IsoUtils.tile_to_screen(float(tx), float(ty))

func _screen_to_world(viewport_pos: Vector2) -> Vector2:
	## Convertit une position viewport (pixels écran) en position monde 2D.
	## get_canvas_transform() donne la transform viewport→monde pour la caméra active.
	return get_viewport().get_canvas_transform().affine_inverse() * viewport_pos
