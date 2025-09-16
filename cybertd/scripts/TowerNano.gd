extends "res://scripts/Tower.gd"

const DebuffNanoSwarm = preload("res://scripts/effects/DebuffNanoSwarm.gd")

func _shoot(target: Node):
	var enemy = target.get_parent()
	if is_instance_valid(enemy) and enemy.has_method("add_debuff"):
		var dur := 8.0
		var debuff = DebuffNanoSwarm.new(enemy, dur)
		# Level-based tuning
		# level 1 baseline is default in debuff class
		match level:
			2:
				debuff.intensity_rise = 0.5
			3:
				debuff.ramp_dps = 9.0
			4:
				debuff.spread_chance = 0.7
			5:
				debuff.duration = dur + 4.0
				debuff.base_dps = 4.0
		enemy.add_debuff(debuff)

func get_stats() -> Dictionary:
	var s := super.get_stats()
	# Show that this tower deals DoT and can spread
	s["damage"] = 0 # direct damage none
	s["splash"] = 0.0
	return s
