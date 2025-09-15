extends "res://scripts/Tower.gd"

func _shoot(target: Node) -> void:
	var b = bullet_scene.instantiate()
	if b == null:
		return
	var muzzle_pos := _get_muzzle_global()
	b.global_position = muzzle_pos
	
	var target_node = target
	if target.has_node("TargetPoint"):
		target_node = target.get_node("TargetPoint")

	if b.has_method("set_target"):
		b.set_target(target_node)
		
	b.speed = bullet_speed
	b.damage = damage
	b.armor_penetration = armor_penetration
	b.splash_radius = splash_radius
	b.impact_scale = 2.5 # Výrazně větší efekt pro snipera
	b.has_trail = bullet_trail
	
	var container = get_tree().get_first_node_in_group("bullets")
	if container:
		container.add_child(b)
	else:
		get_tree().current_scene.add_child(b)
		
	if visual and visual.has_method("trigger_recoil"):
		visual.trigger_recoil(0, recoil_amount)
