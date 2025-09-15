extends "res://scripts/Tower.gd"

const DebuffNanoSwarm = preload("res://scripts/effects/DebuffNanoSwarm.gd")

func _shoot(target: Node):
	var enemy = target.get_parent()
	if is_instance_valid(enemy) and enemy.has_method("add_debuff"):
		var debuff = DebuffNanoSwarm.new(enemy, 8.0) # Trvání 8 sekund
		enemy.add_debuff(debuff)
