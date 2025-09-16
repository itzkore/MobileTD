extends Node

const VERSION := 1
const SAVE_DIR := "user://saves"

var data: Dictionary = {
	"version": VERSION,
	"settings": {"haptics": true, "music_volume": 0.8, "sfx_volume": 0.9, "auto_resume": true},
	"last_run": {"map": "default", "wave": 0, "lives": 20, "gold": 50, "timestamp": 0},
	"snapshot": {}, # runtime snapshot for exact resume
	"meta": {"best_wave": 0}
}

var _resume_requested: bool = false

func _ready() -> void:
	# Load existing save on startup
	load_all()

func _ensure_dir() -> void:
	var d := DirAccess.open("user://")
	if not d.dir_exists(SAVE_DIR):
		d.make_dir_recursive(SAVE_DIR)

func _path_for(user_id: String, provider: String) -> String:
	return "%s/progress_%s_%s.json" % [SAVE_DIR, provider, user_id]

func _get_ids() -> Dictionary:
	var g = get_tree().root.get_node_or_null("Game")
	if g and g.auth and g.auth.is_signed_in():
		return {"user_id": String(g.auth.user_id), "provider": String(g.auth.provider)}
	return {"user_id": "guest", "provider": "guest"}

func load_all() -> Dictionary:
	var ids := _get_ids()
	_ensure_dir()
	var p := _path_for(ids.user_id, ids.provider)
	if not FileAccess.file_exists(p):
		return data
	var f := FileAccess.open(p, FileAccess.READ)
	if f:
		var txt := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(txt)
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
			# Forward/backward compatibility
			if not data.has("version"): data.version = VERSION
			if not data.has("settings"): data.settings = {"haptics": true, "music_volume": 0.8, "sfx_volume": 0.9, "auto_resume": true}
			# Backfill any missing settings keys
			if data.has("settings"):
				if not data.settings.has("haptics"): data.settings.haptics = true
				if not data.settings.has("music_volume"): data.settings.music_volume = 0.8
				if not data.settings.has("sfx_volume"): data.settings.sfx_volume = 0.9
				if not data.settings.has("auto_resume"): data.settings.auto_resume = true
			if not data.has("last_run"): data.last_run = {"map": "default", "wave": 0, "lives": 20, "gold": 50, "timestamp": 0}
			if not data.has("meta"): data.meta = {"best_wave": 0}
	return data

func save_all() -> void:
	var ids := _get_ids()
	_ensure_dir()
	data.version = VERSION
	var p := _path_for(ids.user_id, ids.provider)
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func autosave_run(map_name: String, wave_index: int, lives: int, gold: int) -> void:
	# Save snapshot of current run and keep best_wave in meta
	data.last_run = {
		"map": map_name,
		"wave": wave_index,
		"lives": lives,
		"gold": gold,
		"timestamp": Time.get_unix_time_from_system()
	}
	data.meta.best_wave = max(int(data.meta.get("best_wave", 0)), wave_index)
	save_all()
	# Keep SaveService profile in sync (best_wave)
	var g = get_tree().root.get_node_or_null("Game")
	if g:
		g.profile["best_wave"] = max(int(g.profile.get("best_wave", 0)), wave_index)
		if g.has_method("save_profile"):
			g.save_profile()

func save_snapshot(snapshot: Dictionary) -> void:
	# Store full runtime snapshot (towers, enemies, timers)
	data.snapshot = snapshot
	save_all()

func load_snapshot() -> Dictionary:
	return data.get("snapshot", {})

func clear_snapshot() -> void:
	data.snapshot = {}
	save_all()

func clear_run() -> void:
	data.last_run = {"map": "default", "wave": 0, "lives": 20, "gold": 50, "timestamp": 0}
	save_all()

func get_last_run() -> Dictionary:
	return data.get("last_run", {})

func get_settings() -> Dictionary:
	return data.get("settings", {})

func set_setting(key: String, value) -> void:
	data.settings[key] = value
	save_all()

func request_resume() -> void:
	_resume_requested = true

func consume_resume() -> bool:
	var r := _resume_requested
	_resume_requested = false
	return r
