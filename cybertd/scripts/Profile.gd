extends Control

@onready var back_btn: Button = $VBox/Back
@onready var user_lbl: Label = $VBox/Info/User
@onready var gold_lbl: Label = $VBox/Info/Gold
@onready var guest_btn: Button = $VBox/Buttons/Guest
@onready var google_btn: Button = $VBox/Buttons/Google

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	guest_btn.pressed.connect(_on_guest)
	google_btn.pressed.connect(_on_google)
	_refresh()

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

func _on_back() -> void:
	var scene := load("res://scenes/MainMenu.tscn") as PackedScene
	if scene:
		get_tree().change_scene_to_packed(scene)

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
