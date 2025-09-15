extends Control

@export var game_scene: PackedScene
@onready var play_button: Button = $Center/VBox/PlayButton
@onready var quit_button: Button = $Center/VBox/QuitButton

func _ready() -> void:
	if game_scene == null:
		game_scene = load("res://scenes/Main.tscn")
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)

func _on_quit_pressed() -> void:
	get_tree().quit()
