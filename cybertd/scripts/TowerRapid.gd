extends "res://scripts/Tower.gd"

var _barrel_cycle: int = 0

func _shoot(target: Node) -> void:
	var b = bullet_scene.instantiate()
	if b == null:
		return
	
	var muzzle_points = _get_muzzle_points()
	var muzzle_index = 0
	if muzzle_points.size() > 1:
		muzzle_index = _barrel_cycle
	
	var muzzle_pos = _get_muzzle_global(muzzle_index)
	b.global_position = muzzle_pos
	
	var target_node = target
	if target.has_node("get_parent") and target.get_parent() is PathFollow2D:
		target_node = target.get_parent()

	if b.has_method("set_target"):
		b.set_target(target_node)
		
	b.speed = bullet_speed
	b.damage = damage
	b.armor_penetration = armor_penetration
	b.splash_radius = splash_radius
	b.impact_scale = 1.0
	b.has_trail = bullet_trail
	
	var container = get_tree().get_first_node_in_group("bullets")
	if container:
		container.add_child(b)
	else:
		get_tree().current_scene.add_child(b)
		
	if visual and visual.has_method("trigger_recoil"):
		visual.trigger_recoil(muzzle_index, recoil_amount)
	
	if muzzle_points.size() > 1:
		_barrel_cycle = 1 - _barrel_cycle

func _get_muzzle_points() -> Array[Node2D]:
	var points: Array[Node2D] = []
	if visual:
		# Seřadíme je podle jména, aby bylo pořadí konzistentní
		var muzzle_nodes: Array[Node2D] = []
		for child in visual.get_children():
			if child is Marker2D and child.name.begins_with("MuzzlePoint"):
				muzzle_nodes.append(child)
		muzzle_nodes.sort_custom(func(a, b): return a.name < b.name)
		return muzzle_nodes
	return points

func _get_muzzle_global(idx: int = 0) -> Vector2:
	var muzzle_points = _get_muzzle_points()
	if not muzzle_points.is_empty():
		var point_index = clamp(idx, 0, muzzle_points.size() - 1)
		return muzzle_points[point_index].global_position
	
	return global_position
