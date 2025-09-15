extends Node2D
class_name TurretVisual

@export var barrel_length: float = 26.0
@export var barrel_width: float = 6.0
@export var barrel_color: Color = Color(0.2, 0.2, 0.22)
@export var muzzle_color: Color = Color(0.9, 0.9, 0.95)
@export var base_radius: float = 14.0
@export var base_color: Color = Color(0.18, 0.18, 0.2)
@export var ring_color: Color = Color(0.35, 0.35, 0.4)
@export var details_color: Color = Color(0.6, 0.6, 0.65)
@export var twin_barrels: bool = false
@export var splash_turret: bool = false
@export var level: int = 1
@export var rank_color: Color = Color(0.95, 0.8, 0.2)
@export var recoil_decay: float = 9.0
@export var recoil_default: float = 3.0

var _recoil_a: float = 0.0
var _recoil_b: float = 0.0
var _head_recoil: float = 0.0

func _process(delta: float) -> void:
	var d: float = recoil_decay * delta
	var prev = _recoil_a + _recoil_b + _head_recoil
	_recoil_a = max(0.0, _recoil_a - d)
	_recoil_b = max(0.0, _recoil_b - d)
	_head_recoil = max(0.0, _head_recoil - d)
	if (_recoil_a + _recoil_b + _head_recoil) != prev:
		queue_redraw()

func _draw() -> void:
	# Base plate
	draw_circle(Vector2.ZERO, base_radius + 3, ring_color)
	draw_circle(Vector2.ZERO, base_radius, base_color)
	# Swivel ring highlights
	draw_arc(Vector2.ZERO, base_radius * 0.8, deg_to_rad(-30), deg_to_rad(60), 24, details_color, 2.0)
	# Barrel(s)
	var b_len := barrel_length
	var b_w := barrel_width
	if twin_barrels:
		# Two parallel barrels for rapid/sniper variants
		_draw_barrel(Vector2(0, -b_w*0.7), b_len, b_w, _recoil_a)
		_draw_barrel(Vector2(0, b_w*0.7), b_len, b_w, _recoil_b)
	else:
		_draw_barrel(Vector2.ZERO, b_len, b_w, _recoil_a)
	# Splash turret mortar head
	if splash_turret:
		var r := base_radius * 0.65
		var ofs := Vector2(-_head_recoil, 0)
		draw_circle(ofs, r, details_color)
		draw_circle(ofs, r*0.5, muzzle_color)

	_draw_ranks()

func _draw_barrel(offset: Vector2, length: float, width: float, recoil: float = 0.0) -> void:
	var rx: float = max(0.0, recoil)
	var p0 := offset + Vector2(0 - rx, -width * 0.5)
	var p1 := offset + Vector2(length - rx, -width * 0.5)
	var p2 := offset + Vector2(length - rx, width * 0.5)
	var p3 := offset + Vector2(0 - rx, width * 0.5)
	draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), barrel_color)
	# Muzzle ring
	draw_rect(Rect2(offset + Vector2(length - 3 - rx, -width * 0.6), Vector2(3, width * 1.2)), muzzle_color)

func get_muzzle_points_local() -> Array[Vector2]:
	var points: Array[Vector2] = []
	if splash_turret:
		# Mortar fires from center top of the head
		points.append(Vector2(0, 0))
		return points
	var b_len := barrel_length
	var b_w := barrel_width
	if twin_barrels:
		points.append(Vector2(b_len, -b_w * 0.35))
		points.append(Vector2(b_len, b_w * 0.35))
	else:
		points.append(Vector2(b_len, 0))
	return points

func trigger_recoil(barrel_index: int, amount: float = -1.0) -> void:
	var amt: float = recoil_default if amount < 0.0 else amount
	if splash_turret:
		_head_recoil = max(_head_recoil, amt)
		queue_redraw()
		return
	if twin_barrels:
		if (barrel_index % 2) == 0:
			_recoil_a = max(_recoil_a, amt)
		else:
			_recoil_b = max(_recoil_b, amt)
	else:
		_recoil_a = max(_recoil_a, amt)
	queue_redraw()

func _draw_ranks() -> void:
	# Draw small golden chevrons stacked at bottom-right of the base
	var n: int = clamp(level - 1, 0, 5) # up to 5 chevrons
	if n <= 0:
		return
	var corner: Vector2 = Vector2(base_radius * 0.85, base_radius * 0.85)
	var w: float = 6.0
	var h: float = 3.5
	var gap: float = 2.0
	for i in range(n):
		var yofs: float = -float(i) * (h + gap)
		var p0 := corner + Vector2(-w * 0.5, yofs)
		var p1 := corner + Vector2(0, yofs + h)
		var p2 := corner + Vector2(w * 0.5, yofs)
		draw_polygon(PackedVector2Array([p0, p1, p2]), PackedColorArray([rank_color, rank_color, rank_color]))
