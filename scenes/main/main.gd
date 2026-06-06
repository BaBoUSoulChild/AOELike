extends Control

@onready var _play_button: Button = $CenterContainer/VBoxContainer/PlayButton

func _ready() -> void:
	set_process_input(true)
	_play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
