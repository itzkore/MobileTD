extends Node2D
class_name CrystalCore

@export var main_color: Color = Color(0.3, 0.9, 1.0, 1.0)
@export var core_color: Color = Color(0.9, 1.0, 1.0, 1.0)
@export var glow_color: Color = Color(0.2, 0.8, 1.0, 0.18)
@export var size: float = 26.0
@export var outline_width: float = 3.0
@export var pulse_amp: float = 0.08
@export var pulse_speed: float = 1.6
@export var rotate_speed: float = 0.4

var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta
	rotation += rotate_speed * delta
	queue_redraw()

func _diamond_points(s: float) -> PackedVector2Array:
	var w: float = size * 0.7 * s
	var h: float = size * s
	return PackedVector2Array([
		Vector2(0, -h),
		Vector2(w, 0),
		Vector2(0, h),
		Vector2(-w, 0),
	])

func _draw() -> void:
	var pulse := 1.0 + sin(_t * TAU * 0.16 * pulse_speed) * pulse_amp
	# Soft glow background
	draw_circle(Vector2.ZERO, size * 1.8, glow_color)
	draw_circle(Vector2.ZERO, size * 1.2, glow_color * Color(1,1,1,0.6))
	# Core inner facet
	var inner := _diamond_points(pulse * 0.65)
	draw_colored_polygon(inner, core_color)
	# Main crystal
	var outer := _diamond_points(pulse)
	draw_colored_polygon(outer, main_color)
	# Outline
	var outline := _diamond_points(pulse * 1.02)
	# Close the loop for polyline
	outline.append(outline[0])
	draw_polyline(outline, main_color.darkened(0.25), outline_width, true)
