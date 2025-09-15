class_name AuthService
extends Node

signal signed_in(user_id: String, provider: String)
signal signed_out()

var user_id: String = ""
var provider: String = "guest" # guest|google

func is_signed_in() -> bool:
	return user_id != ""

func sign_in_guest() -> void:
	provider = "guest"
	# Generate a stable guest id and persist locally
	var id := _load_or_create_guest_id()
	user_id = id
	signed_in.emit(user_id, provider)

func sign_out() -> void:
	user_id = ""
	provider = "guest"
	signed_out.emit()

func sign_in_google() -> void:
	# Android plugin detection – only works on Android builds
	if OS.get_name() != "Android":
		push_warning("Google sign-in only available on Android build. Running as stub on %s" % OS.get_name())
		return
	var gpgs = Engine.get_singleton("GodotGooglePlayGames") if Engine.has_singleton("GodotGooglePlayGames") else null
	if gpgs:
		provider = "google"
		if gpgs.has_method("sign_in"):
			gpgs.call("sign_in")
			var tries := 10
			while tries > 0 and user_id == "":
				await get_tree().create_timer(0.1).timeout
				if gpgs.has_method("is_signed_in") and gpgs.call("is_signed_in"):
					var pid := ""
					if gpgs.has_method("get_player_id"):
						pid = String(gpgs.call("get_player_id"))
					elif gpgs.has_method("get_user_id"):
						pid = String(gpgs.call("get_user_id"))
					if pid == "":
						var display_name := String(gpgs.call("get_display_name")) if gpgs.has_method("get_display_name") else ""
						pid = display_name if display_name != "" else str("gpgs-", Time.get_unix_time_from_system())
					user_id = pid
					signed_in.emit(user_id, provider)
					return
				tries -= 1
			# Fallback even if not confirmed
			var fallback_id := String(gpgs.call("get_player_id")) if gpgs.has_method("get_player_id") else str("gpgs-", Time.get_unix_time_from_system())
			user_id = fallback_id
			signed_in.emit(user_id, provider)
			return
	var gsi = Engine.get_singleton("GodotGoogleSignIn") if Engine.has_singleton("GodotGoogleSignIn") else null
	if gsi:
		provider = "google"
		if gsi.has_method("sign_in"):
			gsi.call("sign_in")
			await get_tree().create_timer(0.5).timeout
			var uid := ""
			if gsi.has_method("get_user_id"):
				uid = String(gsi.call("get_user_id"))
			if uid == "":
				uid = str("gsi-", Time.get_unix_time_from_system())
			user_id = uid
			signed_in.emit(user_id, provider)
			return
	push_warning("No Android Google sign-in plugin found. Please install GPGS or Google Sign-In plugin.")

func _load_or_create_guest_id() -> String:
	var cfg := ConfigFile.new()
	var path := "user://guest.cfg"
	var err := cfg.load(path)
	if err == OK:
		var id = cfg.get_value("auth", "guest_id", "")
		if String(id) != "":
			return String(id)
	var new_id := str("guest-", Time.get_unix_time_from_system())
	cfg.set_value("auth", "guest_id", new_id)
	cfg.save(path)
	return new_id
