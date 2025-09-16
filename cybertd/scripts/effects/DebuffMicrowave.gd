extends "res://scripts/effects/Debuff.gd"

var damage_per_second: float = 2.0
var max_slow: float = 0.7
var speed_multiplier: float = 1.0
var can_explode: bool = false

func _init(p_target: Node2D, p_duration: float):
	super._init(p_target, p_duration)
	# Attach heat haze shader to the visual (AnimatedSprite2D) if available
	var canvas := target
	if target and target.has_method("get_visual_canvasitem"):
		canvas = target.get_visual_canvasitem()
	if canvas and canvas is CanvasItem:
		var mat := canvas.material
		if mat == null or not (mat is ShaderMaterial):
			var shader := load("res://assets/shaders/heat_haze.gdshader")
			if shader:
				var shader_mat := ShaderMaterial.new()
				shader_mat.shader = shader
				canvas.material = shader_mat

func apply_effect(delta: float):
	# Poškození přes čas (tiché, bez spamování floating textu)
	if target and target.has_method("take_damage_silent"):
		target.take_damage_silent(damage_per_second * delta)
	else:
		# Fallback if silent method is missing
		var amt := int(max(1.0, round(damage_per_second * delta)))
		target.take_damage(amt)
	
	# Postupné zpomalování
	if speed_multiplier > (1.0 - max_slow):
		speed_multiplier = max(1.0 - max_slow, speed_multiplier - delta * 0.5) # Rychlost aplikace zpomalení
	
	# Vizuální efekt - tetelení
	var canvas := target
	if target and target.has_method("get_visual_canvasitem"):
		canvas = target.get_visual_canvasitem()
	if canvas and canvas is CanvasItem and canvas.material and canvas.material is ShaderMaterial:
		canvas.material.set_shader_parameter("shake_amount", (1.0 - speed_multiplier) * 0.1)


func on_remove():
	# Uklidíme vizuální efekt
	var canvas := target
	if target and target.has_method("get_visual_canvasitem"):
		canvas = target.get_visual_canvasitem()
	if canvas and canvas is CanvasItem and canvas.material and canvas.material is ShaderMaterial:
		canvas.material.set_shader_parameter("shake_amount", 0.0)
	
	if can_explode and target.health <= 0:
		# Exploze při smrti
		var enemies = target.get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if e == target or not is_instance_valid(e):
				continue
			if e.global_position.distance_to(target.global_position) < 60:
				e.take_damage(15) # Pevné poškození explozí
