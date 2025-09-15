extends "res://scripts/effects/Debuff.gd"

var damage_per_second: float = 2.0
var max_slow: float = 0.7
var speed_multiplier: float = 1.0
var can_explode: bool = false

func _init(p_target: Node2D, p_duration: float):
	super._init(p_target, p_duration)
	# Aplikujeme shader, pokud neexistuje
	if not target.material:
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = load("res://assets/shaders/heat_haze.gdshader")
		target.material = shader_mat

func apply_effect(delta: float):
	# Poškození přes čas
	target.take_damage(damage_per_second * delta)
	
	# Postupné zpomalování
	if speed_multiplier > (1.0 - max_slow):
		speed_multiplier -= delta * 0.5 # Rychlost, jakou se zpomalení aplikuje
	
	# Vizuální efekt - tetelení
	if target.material and target.material is ShaderMaterial:
		target.material.set_shader_parameter("shake_amount", (1.0 - speed_multiplier) * 0.1)

func on_remove():
	# Uklidíme vizuální efekt
	if target.material and target.material is ShaderMaterial:
		target.material.set_shader_parameter("shake_amount", 0.0)
	
	if can_explode and target.health <= 0:
		# Exploze při smrti
		var enemies = target.get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if e == target or not is_instance_valid(e):
				continue
			if e.global_position.distance_to(target.global_position) < 60:
				e.take_damage(15) # Pevné poškození explozí
