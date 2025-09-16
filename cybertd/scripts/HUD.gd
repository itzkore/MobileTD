extends Control

signal start_wave_pressed
signal speed_changed(mult: float)
signal pause_requested

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
@onready var pause_btn: Button = $HUDFrame/Inner/Pause

var next_wave_timer: Timer

func _physics_process(_delta: float) -> void:
	if is_instance_valid(next_wave_timer) and not next_wave_timer.is_stopped():
		var time_left = next_wave_timer.time_left
		set_button_enabled(true, "Next Wave (%.1fs)" % time_left)
	elif start_button.text.begins_with("Next Wave"):
		# Časovač doběhl, ale tlačítko se ještě neaktualizovalo
		set_button_enabled(true, "Next Wave")


func _ready() -> void:
	# Apply global UI scale for mobile
	var scaler = get_tree().root.get_node_or_null("UIScaler")
	if scaler and scaler.has_method("apply_to"):
		scaler.apply_to(self)
		var sf: float = scaler.scale_factor if "scale_factor" in scaler else 1.0
		var win: Vector2i = DisplayServer.window_get_size()
		var compact: bool = win.x < 1200
		var lbl_base: float = 18.0 if compact else 22.0
		var btn_base: float = 20.0 if compact else 24.0
		var lbl_font: int = int(lbl_base * max(1.0, sf))
		var btn_font: int = int(btn_base * max(1.0, sf))
		var btn_min: Vector2 = Vector2(84, 60) if compact else Vector2(96, 72)
		# Shorten labels when compact to save horizontal space
		if compact:
			if is_instance_valid(lives_bottom): lives_bottom.text = "Lives: 0" # unchanged but smaller font
			if is_instance_valid(gold_bottom): gold_bottom.text = "Gold: 0"
			if is_instance_valid(enemies_left_label): enemies_left_label.text = "Enemies: 0"
			if is_instance_valid(wave_label_bottom): wave_label_bottom.text = "Wave: 1"
		for l in [enemies_left_label, wave_label_bottom, lives_bottom, gold_bottom]:
			if l:
				l.add_theme_font_size_override("font_size", lbl_font)
		for b in [start_button, speed1, speed2, speed3]:
			if b:
				b.add_theme_font_size_override("font_size", btn_font)
				b.custom_minimum_size = btn_min
	# Safe area bottom inset
	if OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS":
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var win: Vector2i = DisplayServer.window_get_size()
		var bottom_inset := 0
		if safe.size.x > 0 and safe.size.y > 0 and safe.size.x <= win.x and safe.size.y <= win.y:
			bottom_inset = max(0, win.y - (safe.position.y + safe.size.y))
		var hud_frame := get_node_or_null("HUDFrame")
		if hud_frame and hud_frame is Control:
			var hf := hud_frame as Control
			hf.offset_bottom = -float(max(0, bottom_inset))
	state_panel.visible = false
	start_button.pressed.connect(_on_start_pressed)
	set_enemies_left(0)
	if is_instance_valid(speed1):
		speed1.pressed.connect(_on_speed1)
	if is_instance_valid(speed2):
		speed2.pressed.connect(_on_speed2)
	if is_instance_valid(speed3):
		speed3.pressed.connect(_on_speed3)
	if is_instance_valid(pause_btn):
		pause_btn.pressed.connect(func(): pause_requested.emit())

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
