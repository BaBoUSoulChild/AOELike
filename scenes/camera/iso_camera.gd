## iso_camera.gd
## Caméra isométrique déplaçable.
## - Desktop : ZQSD / flèches directionnelles, molette pour zoom
## - Mobile  : drag un doigt pour déplacer, pinch deux doigts pour zoom

extends Camera2D

# --- Paramètres exportés -------------------------------------------------------
@export var move_speed: float = 400.0          ## pixels/s au clavier
@export var zoom_min: float = 0.5
@export var zoom_max: float = 2.5
@export var zoom_step: float = 0.15            ## par cran de molette
@export var drag_sensitivity: float = 1.0

# --- État interne ---------------------------------------------------------------
var _is_dragging: bool = false
var _drag_start_screen: Vector2 = Vector2.ZERO
var _drag_start_camera: Vector2 = Vector2.ZERO

# Pinch
var _touch_points: Dictionary = {}             ## finger_id → position
var _pinch_start_distance: float = 0.0
var _pinch_start_zoom: float = 1.0

# --- Limites de déplacement custom ----------------------------------------------
## Remplies par game.gd après génération de la carte.
## Nommées cam_limit_* pour ne pas masquer les propriétés built-in de Camera2D.
var cam_limit_left: float   = -INF
var cam_limit_right: float  = INF
var cam_limit_top: float    = -INF
var cam_limit_bottom: float = INF

# -------------------------------------------------------------------------------
func _ready() -> void:
	zoom = Vector2(1.0, 1.0)

func _process(delta: float) -> void:
	_handle_keyboard(delta)

func _input(event: InputEvent) -> void:
	# -- Souris ------------------------------------------------------------------
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	# -- Tactile -----------------------------------------------------------------
	elif event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)

# -------------------------------------------------------------------------------
# Clavier
func _handle_keyboard(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		var speed := move_speed / zoom.x        # compense le zoom
		position += dir.normalized() * speed * delta
		_clamp_position()

# Molette souris
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_apply_zoom(zoom_step, event.position)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_apply_zoom(-zoom_step, event.position)
	# Drag souris (bouton du milieu ou gauche sans clic sur unité — géré dans game.gd)
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_dragging = event.pressed
		if _is_dragging:
			_drag_start_screen = event.position
			_drag_start_camera = position

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_dragging:
		var delta := (event.position - _drag_start_screen) * drag_sensitivity / zoom.x
		position = _drag_start_camera - delta
		_clamp_position()

# Tactile — un doigt (drag) ou deux doigts (pinch)
func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_points[event.index] = event.position
	else:
		_touch_points.erase(event.index)
		_is_dragging = false

	if _touch_points.size() == 1:
		_is_dragging = true
		var pos := _touch_points.values()[0]
		_drag_start_screen = pos
		_drag_start_camera = position
	elif _touch_points.size() == 2:
		_is_dragging = false
		_pinch_start_distance = _get_touch_distance()
		_pinch_start_zoom = zoom.x

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	_touch_points[event.index] = event.position

	if _touch_points.size() == 2:
		# Pinch-to-zoom
		var dist := _get_touch_distance()
		if _pinch_start_distance > 0.0:
			var ratio := dist / _pinch_start_distance
			var new_zoom := clampf(_pinch_start_zoom * ratio, zoom_min, zoom_max)
			zoom = Vector2(new_zoom, new_zoom)
	elif _touch_points.size() == 1 and _is_dragging:
		var delta := (event.position - _drag_start_screen) * drag_sensitivity / zoom.x
		position = _drag_start_camera - delta
		_clamp_position()

# -------------------------------------------------------------------------------
func _apply_zoom(delta_zoom: float, pivot_screen: Vector2) -> void:
	var old_zoom := zoom.x
	var new_zoom := clampf(old_zoom + delta_zoom, zoom_min, zoom_max)
	# Zoom centré sur le curseur
	var world_before := (pivot_screen - get_viewport_rect().size / 2.0) / old_zoom + position
	zoom = Vector2(new_zoom, new_zoom)
	var world_after := (pivot_screen - get_viewport_rect().size / 2.0) / new_zoom + position
	position += world_before - world_after
	_clamp_position()

func _clamp_position() -> void:
	position.x = clampf(position.x, cam_limit_left, cam_limit_right)
	position.y = clampf(position.y, cam_limit_top, cam_limit_bottom)

func _get_touch_distance() -> float:
	var pts := _touch_points.values()
	if pts.size() < 2:
		return 0.0
	return (pts[0] as Vector2).distance_to(pts[1] as Vector2)
