extends "res://scripts/effects/Debuff.gd"

@export var base_dps: float = 3.0
@export var ramp_dps: float = 6.0 # added over lifetime as intensity grows
@export var spread_chance: float = 0.5
@export var spread_radius: float = 90.0
@export var intensity_rise: float = 0.35 # per second intensity growth up to 1.0
@export var armor_shred_per_sec: float = 0.6 # snižuje armor postupně (může jít i do mínusu)
@export var damage_taken_bonus_max: float = 0.15 # maximální bonus k damage taken při plné intenzitě
@export var max_retargets: int = 1
@export var retarget_intensity_factor: float = 0.4
@export var retarget_duration_factor: float = 0.7
@export var retarget_armor_factor: float = 0.5
@export var retarget_vuln_factor: float = 0.5
@export var spread_chance_after_retarget: float = 0.15

const NanoCloudScene = preload("res://scenes/effects/NanoCloud.tscn")

var _intensity: float = 0.0
var _cloud: Node2D
var _applied_armor_reduction: float = 0.0
var _orig_damage_taken_mult: float = 1.0
var _retargets_done: int = 0
var _armor_shred_curr: float = 0.0
var _damage_taken_bonus_curr: float = 0.0

func apply_effect(delta: float):
	# Ramp intensity over time on the same target
	_intensity = clamp(_intensity + intensity_rise * delta, 0.0, 1.0)
	var dps := base_dps + ramp_dps * _intensity
	if target and target.has_method("take_damage_silent"):
		target.take_damage_silent(dps * delta)
	else:
		target.take_damage(int(max(1.0, round(dps * delta))))
	# Visual swarm
	_ensure_cloud()
	if _cloud:
		# Follow as child with a local offset
		if _cloud.get_parent() != target:
			_cloud.reparent(target)
			_cloud.position = _cloud.get("attach_offset") if _cloud.has_method("get") else Vector2(0, -12)
		_cloud.call_deferred("cancel_fade")
		_cloud.call_deferred("set_intensity", _intensity)

	# Apply armor shred over time (can go negative)
	if target:
		var shred_amount: float = ( _armor_shred_curr if _armor_shred_curr > 0.0 else armor_shred_per_sec ) * delta
		target.armor = int(floor(target.armor - shred_amount))
		_applied_armor_reduction += shred_amount

	# Mild damage taken increase that scales with intensity (capped)
	if target:
		var bonus_cap: float = _damage_taken_bonus_curr if _damage_taken_bonus_curr > 0.0 else damage_taken_bonus_max
		var bonus: float = clamp(_intensity, 0.0, 1.0) * bonus_cap
		target.damage_taken_mult = _orig_damage_taken_mult * (1.0 + bonus)

func _ensure_cloud() -> void:
	if _cloud and is_instance_valid(_cloud):
		return
	if not target:
		return
	_cloud = NanoCloudScene.instantiate()
	# Parent under target so it follows perfectly
	target.add_child(_cloud)
	_cloud.position = _cloud.get("attach_offset") if _cloud.has_method("get") else Vector2(0, -12)
	# record baseline damage multiplier for clean updates
	if target:
		_orig_damage_taken_mult = max(0.0, float(target.damage_taken_mult))

func on_remove():
	# Trigger spread burst and start fade
	if _cloud and is_instance_valid(_cloud):
		_cloud.call_deferred("burst")
		_cloud.call_deferred("fade_out")
	# Restore damage multiplier baseline
	if target:
		target.damage_taken_mult = _orig_damage_taken_mult
	# Armor stays reduced (persists), by design
	var spread_p := spread_chance
	if _retargets_done > 0:
		spread_p = spread_chance_after_retarget
	if randf() < spread_p and target:
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
			var new_debuff = get_script().new(closest_enemy, duration)
			closest_enemy.add_debuff(new_debuff)

func on_added() -> void:
	# Hook enemy death to retarget while time remains
	if target and target.has_signal("died"):
		target.died.connect(on_target_died)
	# initialize dynamic factors
	_armor_shred_curr = armor_shred_per_sec
	_damage_taken_bonus_curr = damage_taken_bonus_max

func on_target_died() -> void:
	# Try to retarget to next closest enemy and continue for remaining duration
	var remaining: float = max(0.0, duration - time_elapsed)
	if remaining <= 0.0:
		return
	if _retargets_done >= max_retargets:
		if _cloud and is_instance_valid(_cloud):
			_cloud.call_deferred("burst")
			_cloud.call_deferred("fade_out")
			_cloud = null
		return
	# find nearest enemy to last target position
	var old_target = target
	var root = target.get_tree() if target else null
	var origin_pos: Vector2 = target.global_position if target else Vector2.ZERO
	var enemies = root.get_nodes_in_group("enemies") if root else []
	var best = null
	var best_d = INF
	for e in enemies:
		if not is_instance_valid(e) or e == target:
			continue
		var d = e.global_position.distance_to(origin_pos)
		if d < best_d:
			best_d = d
			best = e
	if best:
		# If best already has this debuff type, merge into it and finish this one
		var existing = null
		for d in best.debuffs:
			if d.get_script() == get_script():
				existing = d
				break
		if existing and existing != self:
			# merge remaining time and intensity
			existing.duration = max(existing.duration, existing.time_elapsed + remaining)
			if "_intensity" in existing:
				existing._intensity = max(existing._intensity, _intensity)
			# transfer visual burst and end this instance
			if _cloud and is_instance_valid(_cloud):
				_cloud.call_deferred("burst")
				_cloud.call_deferred("fade_out")
				_cloud = null
			# mark self as completed
			time_elapsed = duration
			return
		# Switch processing ownership: move this debuff into best's list
		# Remove from old target list if still present
		if old_target and old_target.debuffs.has(self):
			old_target.debuffs.erase(self)
		# Attach to new target
		target = best
		if not best.debuffs.has(self):
			best.debuffs.append(self)
		# Apply retarget nerfs and reset timing to continue for reduced remaining time
		_retargets_done += 1
		_intensity *= retarget_intensity_factor
		_armor_shred_curr *= retarget_armor_factor
		_damage_taken_bonus_curr *= retarget_vuln_factor
		time_elapsed = 0.0
		duration = remaining * retarget_duration_factor
		# Update baseline damage multiplier for the new target
		_orig_damage_taken_mult = max(0.0, float(best.damage_taken_mult))
		# Reparent/ensure visual
		if _cloud and is_instance_valid(_cloud):
			if _cloud.get_parent() != best:
				_cloud.reparent(best)
				_cloud.position = _cloud.get("attach_offset") if _cloud.has_method("get") else Vector2(0, -12)
				_cloud.call_deferred("cancel_fade")
		else:
			_ensure_cloud()
		# Reconnect death signal to new target
		if best.has_signal("died"):
			best.died.connect(on_target_died)
