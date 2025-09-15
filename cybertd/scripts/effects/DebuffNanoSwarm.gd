extends "res://scripts/effects/Debuff.gd"

var damage_per_second: float = 5.0
var spread_chance: float = 0.5
var spread_radius: float = 80.0

const NanoDebuff = preload("res://scripts/effects/DebuffNanoSwarm.gd")

func apply_effect(delta: float):
	target.take_damage(damage_per_second * delta)
	# Vizuální efekt - zelené částice
	# (Implementace by vyžadovala Particle system)

func on_remove():
	if randf() < spread_chance:
		var enemies = target.get_tree().get_nodes_in_group("enemies")
		var closest_enemy = null
		var min_dist = spread_radius
		
		for enemy in enemies:
			if enemy == target or not is_instance_valid(enemy):
				continue
			var dist = enemy.global_position.distance_to(target.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_enemy = enemy
		
		if closest_enemy:
			var new_debuff = NanoDebuff.new(closest_enemy, duration)
			closest_enemy.add_debuff(new_debuff)
