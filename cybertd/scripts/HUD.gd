extends Control

signal start_wave_pressed
signal speed_changed(mult: float)

@onready var start_button: Button = $HUDFrame/Inner/StartWave
@onready var state_panel: ColorRect = $State
@onready var state_text: Label = $State/Text
@onready var enemies_left_label: Label = $HUDFrame/Inner/EnemiesLeft
@onready var wave_label_bottom: Label = $HUDFrame/Inner/WaveInfo
@onready var lives_bottom: Label = $HUDFrame/Inner/LivesBottom
@onready var gold_bottom: Label = $HUDFrame/Inner/GoldBottom
@onready var speed1: Button = $HUDFrame/Inner/Speed1x
@onready var speed2: Button = $HUDFrame/Inner/Speed2x
@onready var speed3: Button = $HUDFrame/Inner/Speed3x

var next_wave_timer: Timer

func _physics_process(_delta: float) -> void:
	if is_instance_valid(next_wave_timer) and not next_wave_timer.is_stopped():
		var time_left = next_wave_timer.time_left
		set_button_enabled(true, "Next Wave (%.1fs)" % time_left)
	elif start_button.text.begins_with("Next Wave"):
		# Časovač doběhl, ale tlačítko se ještě neaktualizovalo
		set_button_enabled(true, "Next Wave")


func _ready() -> void:
	state_panel.visible = false
	start_button.pressed.connect(_on_start_pressed)
	set_enemies_left(0)
	if is_instance_valid(speed1):
		speed1.pressed.connect(_on_speed1)
	if is_instance_valid(speed2):
		speed2.pressed.connect(_on_speed2)
	if is_instance_valid(speed3):
		speed3.pressed.connect(_on_speed3)

func _on_speed1() -> void:
	speed_changed.emit(1.0)

func _on_speed2() -> void:
	speed_changed.emit(2.0)

func _on_speed3() -> void:
	speed_changed.emit(3.0)

func _on_start_pressed() -> void:
	start_wave_pressed.emit()

func set_stats(lives: int, gold: int, wave: int) -> void:
	if is_instance_valid(lives_bottom):
		lives_bottom.text = "Lives: %d" % lives
	if is_instance_valid(gold_bottom):
		gold_bottom.text = "Gold: %d" % gold
	if is_instance_valid(wave_label_bottom):
		wave_label_bottom.text = "Wave: %d" % wave

func set_button_enabled(enabled: bool, text: String = "Start Wave") -> void:
	start_button.text = text
	start_button.disabled = not enabled

func show_state(text: String) -> void:
	state_text.text = text
	state_panel.visible = true

func hide_state() -> void:
	state_panel.visible = false

func set_enemies_left(n: int) -> void:
	enemies_left_label.text = "Enemies left: %d" % n
