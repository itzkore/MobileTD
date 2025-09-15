extends Area2D

var speed: float = 400.0
var damage: int = 3
var target: Node = null

func set_target(t: Node) -> void:
	target = t

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta
	if global_position.distance_to(target.global_position) < 6.0:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
