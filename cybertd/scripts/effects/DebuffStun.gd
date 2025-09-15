extends "res://scripts/effects/Debuff.gd"

var speed_multiplier: float = 0.0 # Úplné zastavení

func _init(p_target: Node2D, p_duration: float):
	super._init(p_target, p_duration)
	# Vizuální efekt - probliknutí bíle
	if "material" in target and target.material != null:
		target.material.set_shader_parameter("flash_modifier", 1.0)

func on_remove():
	# Uklidíme vizuální efekt
	if "material" in target and target.material != null:
		target.material.set_shader_parameter("flash_modifier", 0.0)
