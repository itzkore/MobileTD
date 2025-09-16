extends Control

const MenuStyleUtil = preload("res://scripts/ui/MenuStyle.gd")

@onready var panel: Control = $Panel
@onready var music_slider: HSlider = $Panel/VBox/Music
@onready var sfx_slider: HSlider = $Panel/VBox/SFX
@onready var haptics_cb: CheckBox = $Panel/VBox/Haptics
@onready var auto_resume_cb: CheckBox = $Panel/VBox/AutoResume
@onready var close_btn: Button = $Panel/VBox/Close

var _scrim: ColorRect

func _ready() -> void:
	# Allow the settings UI to work even if game is paused beneath
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# Fullscreen root to host scrim behind panel
	anchor_left = 0; anchor_top = 0; anchor_right = 1; anchor_bottom = 1
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_scrim()

	# Load current settings
	var saver = get_tree().root.get_node_or_null("SaveGame")
	var settings: Dictionary = {} if not saver or not saver.has_method("get_settings") else saver.get_settings()
	music_slider.value = float(settings.get("music_volume", 0.8))
	sfx_slider.value = float(settings.get("sfx_volume", 0.9))
	haptics_cb.button_pressed = bool(settings.get("haptics", true))
	auto_resume_cb.button_pressed = bool(settings.get("auto_resume", true))
	# Apply immediate effects
	_apply_audio()
	# Wire signals
	music_slider.value_changed.connect(_on_music)
	sfx_slider.value_changed.connect(_on_sfx)
	haptics_cb.toggled.connect(_on_haptics)
	auto_resume_cb.toggled.connect(_on_auto_resume)
	close_btn.pressed.connect(close_modal)

	_apply_style()
	# Hidden until opened
	visible = false
	modulate.a = 0.0
	panel.scale = Vector2(0.97, 0.97)
	set_process_unhandled_input(true)

func open_modal() -> void:
	visible = true
	if _scrim:
		_scrim.visible = true
		_scrim.modulate.a = 0.0
		var ts := _scrim.create_tween()
		ts.tween_property(_scrim, "modulate:a", 0.35, 0.12)
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 1.0, 0.14)
	t.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18)

func close_modal() -> void:
	var t := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.parallel().tween_property(panel, "scale", Vector2(0.98, 0.98), 0.12)
	if _scrim:
		var ts := _scrim.create_tween()
		ts.tween_property(_scrim, "modulate:a", 0.0, 0.12)
	t.finished.connect(func(): queue_free())

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		close_modal()

func _build_scrim() -> void:
	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = Color(0,0,0,0.35)
	_scrim.anchor_left = 0; _scrim.anchor_top = 0; _scrim.anchor_right = 1; _scrim.anchor_bottom = 1
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_scrim)
	_scrim.move_to_front()
	_scrim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			close_modal()
	)

func _apply_style() -> void:
	# Style buttons and labels
	MenuStyleUtil.style_button(close_btn, 22, Vector2(200, 56))
	for child in panel.get_children():
		if child is Label:
			MenuStyleUtil.style_label(child, 20)
		elif child is Button and child != close_btn:
			MenuStyleUtil.style_button(child, 22, Vector2(200, 56))

func _on_music(v: float) -> void:
	_set_setting("music_volume", clampf(v, 0.0, 1.0))
	_apply_audio()

func _on_sfx(v: float) -> void:
	_set_setting("sfx_volume", clampf(v, 0.0, 1.0))
	_apply_audio()

func _on_haptics(b: bool) -> void:
	_set_setting("haptics", b)

func _on_auto_resume(b: bool) -> void:
	_set_setting("auto_resume", b)

func _set_setting(k: String, v) -> void:
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if saver and saver.has_method("set_setting"):
		saver.set_setting(k, v)

func _apply_audio() -> void:
	var saver = get_tree().root.get_node_or_null("SaveGame")
	var settings: Dictionary = {} if not saver or not saver.has_method("get_settings") else saver.get_settings()
	var mv: float = float(settings.get("music_volume", 0.8))
	var sv: float = float(settings.get("sfx_volume", 0.9))
	# Expect two buses: "Music" and "SFX" (fallback to Master)
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus < 0: music_bus = AudioServer.get_bus_index("Master")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus < 0: sfx_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(clampf(mv, 0.0, 1.0)))
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(clampf(sv, 0.0, 1.0)))

func _on_close() -> void:
	close_modal()
