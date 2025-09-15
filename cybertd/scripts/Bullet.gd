extends Area2D

var speed: float = 400.0
var damage: int = 3
var armor_penetration: int = 0
var target: Node = null
@export var splash_radius: float = 0.0
@export var has_trail: bool = false
var impact_scale: float = 1.0
var _trail: Array[Vector2] = []
var _trail_max: int = 10
@export var width: float = 3.0
@export var length: float = 8.0
@export var color: Color = Color(0.95, 0.95, 0.95, 1.0)

func set_target(t: Node) -> void:
	target = t

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return

	var target_pos = target.global_position
	var dir: Vector2 = (target_pos - global_position).normalized()
	var distance_to_target = global_position.distance_to(target_pos)
	var move_distance = speed * delta

	# Robustní detekce zásahu pro rychlé střely
	# Pokud je vzdálenost, kterou urazíme, větší než vzdálenost k cíli,
	# znamená to, že jsme cíl v tomto snímku "přeskočili" a jedná se o zásah.
	if move_distance >= distance_to_target:
		_hit_target(target)
		# Umístíme střelu přesně na cíl pro vizuální efekt
		global_position = target_pos
		return

	# Standardní pohyb
	rotation = dir.angle()
	global_position += dir * move_distance

	if has_trail:
		_trail.append(global_position)
		if _trail.size() > _trail_max:
			_trail.pop_front()
		queue_redraw()

func _hit_target(hit_node: Node) -> void:
	var enemy_node = hit_node.get_parent()
	if not is_instance_valid(enemy_node):
		queue_free()
		return

	if enemy_node.has_method("take_damage"):
		# Výpočet finálního poškození
		var target_armor = enemy_node.get("armor") if "armor" in enemy_node else 0
		var effective_armor = max(0, target_armor - armor_penetration)
		var final_damage = max(1, damage - effective_armor) # Minimálně 1 poškození
		
		enemy_node.take_damage(final_damage)
		
		var main = get_tree().current_scene
		if main and main.has_method("_spawn_effect_impact"):
			# Použijeme pozici hitboxu pro efekt
			var hit_dir: Vector2 = (hit_node.global_position - global_position).normalized()
			main._spawn_effect_impact(hit_node.global_position, hit_dir, impact_scale)
			
	if splash_radius > 0.0:
		_apply_splash_damage()
		
	queue_free()

func _draw() -> void:
	# Bullet body (capsule) pointing to the +X axis, rotation is applied via node rotation
	var half_w := width * 0.5
	var body_len := length
	var front := Vector2(body_len * 0.5, 0)
	var back := Vector2(-body_len * 0.5, 0)
	# Rectangle body
	var p0 := back + Vector2(0, -half_w)
	var p1 := front + Vector2(0, -half_w)
	var p2 := front + Vector2(0, half_w)
	var p3 := back + Vector2(0, half_w)
	draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), color)
	# Rounded ends
	draw_circle(front, half_w, color)
	draw_circle(back, half_w, color)
	# Optional trail
	if has_trail and not _trail.is_empty():
		var col := Color(0.9, 0.95, 1.0, 0.5)
		var n := _trail.size()
		for i in range(n - 1):
			var a := _trail[i]
			var b := _trail[i + 1]
			var t := float(i) / float(n - 1)
			var c := col.lerp(Color(col.r, col.g, col.b, 0.0), t)
			draw_line(to_local(a), to_local(b), c, 2.0)

func _apply_splash_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == target:
			continue
		if e is Node2D and e.has_method("take_damage"):
			if (e as Node2D).global_position.distance_to(global_position) <= splash_radius:
				# Výpočet finálního poškození pro splash
				var target_armor = e.get("armor") if "armor" in e else 0
				var effective_armor = max(0, target_armor - armor_penetration)
				var final_damage = max(1, damage - effective_armor)
				
				e.take_damage(final_damage)
