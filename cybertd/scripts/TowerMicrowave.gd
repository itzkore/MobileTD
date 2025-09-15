extends "res://scripts/Tower.gd"

const DebuffMicrowave = preload("res://scripts/effects/DebuffMicrowave.gd")

var damage_per_second: float = 2.0
var max_slow: float = 0.7
var can_chain: bool = false
var can_explode: bool = false

func _process(delta: float):
	var target = _pick_target()
	if target:
		_aim_at(target, delta)
		_apply_microwave_beam(target)
		
		if can_chain:
			_apply_chain_beam(target)

func _apply_microwave_beam(target_area: Area2D):
	var enemy = target_area.get_parent()
	if is_instance_valid(enemy) and enemy.has_method("add_debuff"):
		var debuff = DebuffMicrowave.new(enemy, 1.0)
		debuff.damage_per_second = damage_per_second
		debuff.max_slow = max_slow
		debuff.can_explode = can_explode
		enemy.add_debuff(debuff)

func _apply_chain_beam(original_target: Area2D):
	var _enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var min_dist = 100 # Max chain distance
	
	for enemy_area in range_area.get_overlapping_areas():
		if enemy_area == original_target:
			continue
		var dist = enemy_area.global_position.distance_to(original_target.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_enemy = enemy_area
	
	if closest_enemy:
		_apply_microwave_beam(closest_enemy)

func upgrade_level():
	super.upgrade_level()
	match level:
		2:
			max_slow = 0.8
		3:
			damage_per_second = 4.0
		4:
			can_chain = true
		5:
			can_explode = true
