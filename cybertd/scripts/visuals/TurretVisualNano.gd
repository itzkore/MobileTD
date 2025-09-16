extends Node2D

@export var base_radius: float = 16.0
@export var base_color: Color = Color(0.24, 0.24, 0.26)
@export var ring_color: Color = Color(0.36, 0.36, 0.42)
@export var glow_color: Color = Color(0.85, 0.9, 1.0, 0.14)
@export var accent_colors: Array[Color] = [
	Color(0.2, 0.8, 1.0, 0.95),  # cyan
	Color(0.9, 0.3, 1.0, 0.95),  # violet
	Color(0.3, 1.0, 0.6, 0.95),  # mint
	Color(1.0, 0.6, 0.2, 0.95)   # orange
]
@export var spin_speed: float = 1.8
@export var pulse_rate: float = 1.6
@export var level: int = 1

var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta
	rotation += deg_to_rad(60.0) * spin_speed * delta * 0.2
	if int(_t * 30.0) % 2 == 0:
		queue_redraw()

func _draw() -> void:
	var r: float = base_radius
	# Base plate
	draw_circle(Vector2.ZERO, r + 3.0, ring_color)
	draw_circle(Vector2.ZERO, r, base_color)
	# Soft glow
	draw_circle(Vector2.ZERO, r + 8.0, glow_color)
	# Hex ring
	var hex_r: float = r * 0.95
	var pts: PackedVector2Array = []
	for i in range(6):
		var a: float = TAU * (float(i) / 6.0)
		pts.append(Vector2.RIGHT.rotated(a) * hex_r)
	draw_polyline(pts + PackedVector2Array([pts[0]]), ring_color, 2.0)
	# Inner rotating crescents
	var arc_r: float = r * 0.55
	var arc_w: float = 3.0
	var flick: int = int(floor(_t * 9.0))
	var accent: Color = accent_colors[flick % accent_colors.size()] if accent_colors.size() > 0 else ring_color
	draw_arc(Vector2.ZERO, arc_r, 0.0, TAU * 0.35, 24, accent, arc_w)
	draw_arc(Vector2.ZERO, arc_r, TAU * 0.5, TAU * 0.85, 24, accent.lightened(0.15), arc_w)
	# Nucleus pulse
	var pulse_t: float = 0.5 + 0.5 * sin(_t * TAU * pulse_rate)
	var nucleus_r: float = 3.5 + 2.0 * pulse_t
	draw_circle(Vector2.ZERO, nucleus_r, accent)
	# Muzzle hint (for systems that need it) - draw a tiny notch at +X
	var notch_p0: Vector2 = Vector2(r + 2.0, -2.0)
	var notch_p1: Vector2 = Vector2(r + 6.0, 2.0)
	draw_rect(Rect2(notch_p0, notch_p1 - notch_p0), accent)

func trigger_recoil(_barrel_index: int, _amount: float = 0.0) -> void:
	# Nano tower has no physical recoil, but keep API parity.
	pass
