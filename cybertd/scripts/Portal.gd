extends Node2D
class_name Portal

@export var color_outer: Color = Color(0.2, 1.0, 0.6, 1.0)
@export var color_glow: Color = Color(0.2, 1.0, 0.6, 0.18)
@export var base_radius: float = 18.0
@export var pulse_radius: float = 6.0
@export var ring_width: float = 5.0
@export var speed: float = 2.0
@export var tick_count: int = 8
@export var tick_len: float = 6.0

var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta
	rotation += 0.3 * delta
	queue_redraw()

func _draw() -> void:
	var r: float = base_radius + sin(_t * TAU * 0.16 * speed) * pulse_radius
	# Outer glow
	draw_circle(Vector2.ZERO, r + ring_width * 1.6, color_glow)
	# Ring
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 72, color_outer, ring_width, true)
	# Small ticks around the ring for portal feel
	for i in tick_count:
		var ang := float(i) / float(max(1, tick_count)) * TAU
		var from := Vector2(cos(ang), sin(ang)) * (r - tick_len * 0.5)
		var to := Vector2(cos(ang), sin(ang)) * (r + tick_len * 0.5)
		draw_line(from, to, color_outer, 2.0)
