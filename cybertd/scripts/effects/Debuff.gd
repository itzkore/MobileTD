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
