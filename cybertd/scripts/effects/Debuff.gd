extends Node
class_name Debuff

var target: Node2D
var duration: float = 0.0
var time_elapsed: float = 0.0

func _init(p_target: Node2D, p_duration: float):
	target = p_target
	duration = p_duration

func process_debuff(delta: float) -> bool:
	time_elapsed += delta
	apply_effect(delta)
	return time_elapsed >= duration

func apply_effect(_delta: float):
	# Tato metoda bude přepsána v konkrétních debuffech
	pass

func on_remove():
	# Tato metoda bude přepsána, pokud je potřeba něco uklidit
	pass

func on_added() -> void:
	# Volitelný hook při přidání na cíl
	pass

func on_target_died() -> void:
	# Volitelný hook při smrti cíle (pro přesměrování/spršku atd.)
	pass

# ---- Serialization helpers ----
func to_dict() -> Dictionary:
	return {
		"script": get_script().resource_path if get_script() and get_script().resource_path != "" else "",
		"remaining": max(0.0, duration - time_elapsed)
	}

static func from_dict(d: Dictionary, p_target: Node2D) -> Debuff:
	if not d.has("script"):
		return null
	var scr_path: String = String(d.get("script", ""))
	if scr_path == "" or not ResourceLoader.exists(scr_path):
		return null
	var scr = load(scr_path)
	var rem: float = float(d.get("remaining", 0.0))
	var inst = scr.new(p_target, max(0.0, rem))
	if inst and inst is Debuff:
		return inst
	return null
