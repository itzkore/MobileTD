extends Node2D

@export var color: Color = Color(0.75, 0.05, 0.05, 1.0) # blood tint
@export var lifetime: float = 0.22
@export var drops: int = 14
@export var spread_degrees: float = 70.0
@export var speed_min: float = 140.0
@export var speed_max: float = 240.0
@export var size_min: float = 1.2
@export var size_max: float = 2.6

var _time: float = 0.0
var _dir: Vector2 = Vector2.ZERO
var _scale_effect: float = 1.0
var _angles: PackedFloat32Array = []
var _speeds: PackedFloat32Array = []
var _sizes: PackedFloat32Array = []

func play_effect(direction: Vector2, p_scale: float = 1.0) -> void:
	_dir = direction.normalized()
	_scale_effect = p_scale
	_init_particles()

func _init_particles():
	var rnd := RandomNumberGenerator.new()
	rnd.randomize()
	var base_angle := _dir.angle()
	
	var num_drops = int(drops * _scale_effect)
	var speed_min_scaled = speed_min * _scale_effect
	var speed_max_scaled = speed_max * _scale_effect
	var size_min_scaled = size_min * _scale_effect
	var size_max_scaled = size_max * _scale_effect

	for i in range(num_drops):
		var a := deg_to_rad(rnd.randf_range(-spread_degrees * 0.5, spread_degrees * 0.5)) + base_angle
		_angles.append(a)
		_speeds.append(rnd.randf_range(speed_min_scaled, speed_max_scaled))
		_sizes.append(rnd.randf_range(size_min_scaled, size_max_scaled))
	queue_redraw()

func _ready() -> void:
	# Initialization is now deferred to play_effect
	pass

func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(_time / max(0.001, lifetime), 0.0, 1.0)
	# Ease-out motion with quick slowdown
	var k := 1.0 - pow(t, 0.6)
	var alpha := 1.0 - t
	var col := Color(color.r, color.g, color.b, alpha)
	for i in range(_angles.size()):
		var a := _angles[i]
		var v := _speeds[i]
		var s := _sizes[i]
		var dir := Vector2(cos(a), sin(a))
		var pos := dir * v * k * 0.01 # tuned factor for 2D units
		draw_circle(pos, s, col)
