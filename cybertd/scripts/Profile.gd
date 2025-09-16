extends Control

@onready var back_btn: Button = $VBox/Back
@onready var user_lbl: Label = $VBox/Info/User
@onready var gold_lbl: Label = $VBox/Info/Gold
@onready var guest_btn: Button = $VBox/Buttons/Guest
@onready var google_btn: Button = $VBox/Buttons/Google
@onready var save_btn: Button = $VBox/Buttons/Save
@onready var load_btn: Button = $VBox/Buttons/Load
@onready var reset_btn: Button = $VBox/Buttons/Reset
@onready var clear_snapshot_btn: Button = $VBox/Buttons/ClearSnapshot
@onready var auto_resume_cb: CheckBox = $VBox/Settings/AutoResume

func _ready() -> void:
	# Prevent Android back from minimizing the app; we'll handle it explicitly.
	if OS.get_name() == "Android":
		get_tree().set_auto_accept_quit(false)
	back_btn.pressed.connect(_on_back)
	guest_btn.pressed.connect(_on_guest)
	google_btn.pressed.connect(_on_google)
	if is_instance_valid(save_btn):
		save_btn.pressed.connect(_on_save)
	if is_instance_valid(load_btn):
		load_btn.pressed.connect(_on_load)
	if is_instance_valid(reset_btn):
		reset_btn.pressed.connect(_on_reset)
	if is_instance_valid(clear_snapshot_btn):
		clear_snapshot_btn.pressed.connect(_on_clear_snapshot)
	if is_instance_valid(auto_resume_cb):
		auto_resume_cb.toggled.connect(_on_auto_resume_toggled)
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Treat Android back as clicking our Back button.
		_on_back()

func _refresh() -> void:
	var g = get_tree().root.get_node_or_null("Game")
	if not g:
		return
	var provider: String = "guest"
	if g.auth and g.auth.provider:
		provider = String(g.auth.provider)
	var user_name = "Guest" if provider == "guest" else "Google"
	user_lbl.text = "User: %s" % user_name
	gold_lbl.text = "Gold: %d" % int(g.profile.get("gold", 0))
	# Load settings state
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if saver and saver.has_method("get_settings") and is_instance_valid(auto_resume_cb):
		var settings: Dictionary = saver.get_settings()
		auto_resume_cb.button_pressed = bool(settings.get("auto_resume", true))

func _on_back() -> void:
	if is_instance_valid(back_btn):
		back_btn.disabled = true
		back_btn.text = "Loading..."
	var scene := load("res://scenes/MainMenu.tscn") as PackedScene
	if scene:
		# Defer scene change to outside of input callback (Android-safe)
		get_tree().call_deferred("change_scene_to_packed", scene)

func _on_guest() -> void:
	var g = get_tree().root.get_node_or_null("Game")
	if g:
		g.auth.sign_in_guest()
		_refresh()

func _on_google() -> void:
	var g = get_tree().root.get_node_or_null("Game")
	if g:
		g.auth.sign_in_google()
		_refresh()

func _on_save() -> void:
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if saver and saver.has_method("save_all"):
		saver.save_all()

func _on_load() -> void:
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if saver and saver.has_method("load_all"):
		saver.load_all()
		_refresh()

func _on_reset() -> void:
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if saver and saver.has_method("clear_run"):
		saver.clear_run()
		_refresh()

func _on_clear_snapshot() -> void:
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if saver and saver.has_method("clear_snapshot"):
		saver.clear_snapshot()

func _on_auto_resume_toggled(pressed: bool) -> void:
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if saver and saver.has_method("set_setting"):
		saver.set_setting("auto_resume", pressed)
