class_name SaveService
extends Node

const SAVE_DIR := "user://saves"

func _ensure_dir() -> void:
	var d := DirAccess.open("user://")
	if not d.dir_exists(SAVE_DIR):
		d.make_dir_recursive(SAVE_DIR)

func _save_path(user_id: String, provider: String = "guest") -> String:
	return "%s/%s_%s.save" % [SAVE_DIR, provider, user_id]

func load_profile(user_id: String, provider: String = "guest") -> Dictionary:
	_ensure_dir()
	var path := _save_path(user_id, provider)
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	if err != OK:
		return {
			"gold": 0,
			"unlocks": [],
			"best_wave": 0
		}
	return {
		"gold": int(cfg.get_value("meta", "gold", 0)),
		"unlocks": Array(cfg.get_value("meta", "unlocks", [])),
		"best_wave": int(cfg.get_value("meta", "best_wave", 0))
	}

func save_profile(user_id: String, provider: String, data: Dictionary) -> void:
	_ensure_dir()
	var path := _save_path(user_id, provider)
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "gold", data.get("gold", 0))
	cfg.set_value("meta", "unlocks", data.get("unlocks", []))
	cfg.set_value("meta", "best_wave", data.get("best_wave", 0))
	cfg.save(path)
