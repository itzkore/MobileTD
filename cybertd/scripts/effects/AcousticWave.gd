extends Area2D

const StunDebuff = preload("res://scripts/effects/DebuffStun.gd")

var speed: float = 250.0
var max_range: float = 150.0
var stun_duration: float = 1.5
var initial_width: float = 10.0
var final_width: float = 80.0

var distance_traveled: float = 0.0
@onready var polygon: Polygon2D = $Polygon2D

func _ready():
	var enemies = get_overlapping_bodies()
	for enemy in enemies:
		if enemy.has_method("add_debuff"):
			var stun_debuff = StunDebuff.new(enemy, stun_duration)
			enemy.add_debuff(stun_debuff)

func _process(delta: float):
	var move_dist = speed * delta
	global_position += transform.x * move_dist
	distance_traveled += move_dist
	
	var t = distance_traveled / max_range
	if t >= 1.0:
		queue_free()
		return
	
	var current_width = lerp(initial_width, final_width, t)
	var points = PackedVector2Array([
		Vector2(0, -initial_width / 2),
		Vector2(distance_traveled, -current_width / 2),
		Vector2(distance_traveled, current_width / 2),
		Vector2(0, initial_width / 2)
	])
	polygon.polygon = points
	polygon.global_position = global_position
	polygon.global_rotation = rotation
