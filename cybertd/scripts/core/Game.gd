extends Node

const AuthServiceClass = preload("res://scripts/services/AuthService.gd")
const SaveServiceClass = preload("res://scripts/services/SaveService.gd")

var auth
var save

var profile: Dictionary = {}

func _ready() -> void:
	# Initialize services
	auth = AuthServiceClass.new()
	add_child(auth)
	save = SaveServiceClass.new()
	add_child(save)

	# Auto sign-in guest on first run
	auth.sign_in_guest()
	_load_profile()
	auth.signed_in.connect(_on_signed_in)

func _on_signed_in(_user_id: String, _provider: String) -> void:
	_load_profile()

func _load_profile() -> void:
	if not auth.is_signed_in():
		profile = {}
		return
	profile = save.load_profile(auth.user_id, auth.provider)

func save_profile() -> void:
	if auth.is_signed_in():
		save.save_profile(auth.user_id, auth.provider, profile)

func add_meta_gold(amount: int) -> void:
	profile["gold"] = int(profile.get("gold", 0)) + amount
	save_profile()
