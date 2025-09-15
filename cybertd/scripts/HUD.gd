extends Control

signal start_wave_pressed

@onready var lives_label: Label = $Top/Lives
@onready var gold_label: Label = $Top/Gold
@onready var wave_label: Label = $Top/Wave
@onready var start_button: Button = $Bottom/StartWave
@onready var state_panel: ColorRect = $State
@onready var state_text: Label = $State/Text

func _ready() -> void:
    state_panel.visible = false
    start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
    start_wave_pressed.emit()

func set_stats(lives: int, gold: int, wave: int) -> void:
    lives_label.text = "Lives: %d" % lives
    gold_label.text = "Gold: %d" % gold
    wave_label.text = "Wave: %d" % wave

func set_button_enabled(enabled: bool, text: String = "Start Wave") -> void:
    start_button.text = text
    start_button.disabled = not enabled

func show_state(text: String) -> void:
    state_text.text = text
    state_panel.visible = true

func hide_state() -> void:
    state_panel.visible = false
