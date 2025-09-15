extends Control

signal start_wave_pressed

@onready var start_button: Button = $HUDFrame/Inner/StartWave
@onready var state_panel: ColorRect = $State
@onready var state_text: Label = $State/Text
@onready var enemies_left_label: Label = $HUDFrame/Inner/EnemiesLeft
@onready var wave_label_bottom: Label = $HUDFrame/Inner/WaveInfo
@onready var lives_bottom: Label = $HUDFrame/Inner/LivesBottom
@onready var gold_bottom: Label = $HUDFrame/Inner/GoldBottom

func _ready() -> void:
    state_panel.visible = false
    start_button.pressed.connect(_on_start_pressed)
    set_enemies_left(0)

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
