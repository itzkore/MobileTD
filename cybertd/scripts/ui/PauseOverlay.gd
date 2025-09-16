extends Control

signal resume_requested
signal settings_requested
signal main_menu_requested

@onready var resume_btn: Button = $Panel/VBox/Resume
@onready var settings_btn: Button = $Panel/VBox/Settings
@onready var main_menu_btn: Button = $Panel/VBox/MainMenu

func _ready() -> void:
	# Allow UI to work while the tree is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Ensure children also respond while paused
	$Panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$Panel/VBox.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$Panel/VBox/Resume.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$Panel/VBox/Settings.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$Panel/VBox/MainMenu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	resume_btn.pressed.connect(func(): resume_requested.emit())
	settings_btn.pressed.connect(func(): settings_requested.emit())
	main_menu_btn.pressed.connect(func(): main_menu_requested.emit())
