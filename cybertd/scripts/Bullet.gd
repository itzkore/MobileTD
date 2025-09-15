extends Area2D

var speed: float = 400.0
var damage: int = 3
var target: Node = null
@export var splash_radius: float = 0.0
@export var has_trail: bool = false
var _trail: Array[Vector2] = []
var _trail_max: int = 10

func set_target(t: Node) -> void:
	target = t

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	rotation = dir.angle()
	if has_trail:
		_trail.append(global_position)
		if _trail.size() > _trail_max:
			_trail.pop_front()
		queue_redraw()
	global_position += dir * speed * delta
	if global_position.distance_to(target.global_position) < 6.0:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		if splash_radius > 0.0:
			_apply_splash_damage()
		queue_free()

func _draw() -> void:
	if not has_trail or _trail.is_empty():
		return
	# Draw a fading trail line from oldest to newest
	var col := Color(0.9, 0.95, 1.0, 0.6)
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
				e.take_damage(damage)
