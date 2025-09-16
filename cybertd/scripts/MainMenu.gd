extends Control

const SCN_MAIN: PackedScene = preload("res://scenes/Main.tscn")
const SCN_CODEX: PackedScene = preload("res://scenes/Codex.tscn")
const SCN_PROFILE: PackedScene = preload("res://scenes/Profile.tscn")

@onready var user_lbl: Label = $Header/UserLabel
@onready var gold_lbl: Label = $Header/GoldLabel
@onready var play_btn: Button = $Center/VBox/Play
@onready var codex_btn: Button = $Center/VBox/Codex
@onready var profile_btn: Button = $Center/VBox/Profile
@onready var quit_btn: Button = $Center/VBox/Quit

func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	codex_btn.pressed.connect(_on_codex)
	profile_btn.pressed.connect(_on_profile)
	quit_btn.pressed.connect(_on_quit)
	_refresh_header()

func _refresh_header() -> void:
	var g = get_tree().root.get_node_or_null("Game")
	if not g:
		return
	var provider: String = "guest"
	if g.auth and g.auth.provider:
		provider = String(g.auth.provider)
	user_lbl.text = "User: %s" % ("Guest" if provider == "guest" else "Google")
	gold_lbl.text = "Gold: %d" % int(g.profile.get("gold", 0))

func _on_play() -> void:
	# Give quick visual feedback and try to switch scenes.
	play_btn.disabled = true
	play_btn.text = "Loading..."
	var err := get_tree().change_scene_to_packed(SCN_MAIN)
	if err != OK:
		play_btn.disabled = false
		play_btn.text = "Play"
		OS.alert("Failed to load Main scene (error %d)." % err, "Load error")

func _on_codex() -> void:
	var err := get_tree().change_scene_to_packed(SCN_CODEX)
	if err != OK:
		OS.alert("Failed to load Codex (error %d)." % err, "Load error")

func _on_profile() -> void:
	var err := get_tree().change_scene_to_packed(SCN_PROFILE)
	if err != OK:
		OS.alert("Failed to load Profile (error %d)." % err, "Load error")

func _on_quit() -> void:
	get_tree().quit()
