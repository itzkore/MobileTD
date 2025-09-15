extends Node2D

@export var fire_rate: float = 1.0
@export var bullet_speed: float = 300.0
@export var damage: int = 3
@export var splash_radius: float = 0.0
@export var aim_offset_degrees: float = 0.0
@export var bullet_trail: bool = false
@export var recoil_amount: float = 3.0
@export var max_level: int = 5
@export var base_upgrade_factor: float = 0.6
@export var upgrade_multiplier: float = 1.5
@export var build_cost: int = 10
@export var damage_per_level: int = 1
@export var range_growth: float = 1.08
@export var fire_rate_growth: float = 1.10

var level: int = 1
var show_range: bool = false
var _barrel_cycle: int = 0

var bullet_scene: PackedScene
var time_accum: float = 0.0

@onready var range_area: Area2D = $Range
@onready var click_area: Area2D = $ClickArea
@onready var sprite: Node2D = $Sprite2D
@onready var visual: Node2D = $Sprite2D/Visual
@onready var _range_shape_node: CollisionShape2D = $Range/CollisionShape2D
var _range_shape: CircleShape2D
var _base_range_radius: float = 0.0
var _base_fire_rate: float = 1.0

func _ready() -> void:
	bullet_scene = load("res://scenes/Bullet.tscn")
	if click_area:
		click_area.input_event.connect(_on_click_input)
		# Ensure the click area is pickable for mouse input
		click_area.input_pickable = true
	# Cache base stats for progressive upgrades
	_base_fire_rate = max(0.001, fire_rate)
	if _range_shape_node and _range_shape_node.shape is CircleShape2D:
		_range_shape = _range_shape_node.shape as CircleShape2D
		_base_range_radius = _range_shape.radius

func _process(delta: float) -> void:
	time_accum += delta
	var target = _pick_target()
	if target:
		_aim_at(target)
		if time_accum >= (1.0 / max(0.001, fire_rate)) and bullet_scene:
			_shoot(target)
			time_accum = 0.0

func _pick_target() -> Node:
	for area in range_area.get_overlapping_areas():
		var parent := area.get_parent()
		if parent and parent.is_in_group("enemies"):
			return parent
	return null

func _shoot(target: Node) -> void:
	var b = bullet_scene.instantiate()
	if b == null:
		return
	var twin := visual and bool(visual.get("twin_barrels"))
	var muzzle_index := 0
	if twin:
		muzzle_index = _barrel_cycle
	var muzzle_pos := _get_muzzle_global(muzzle_index)
	b.global_position = muzzle_pos
	if b.has_method("set_target"):
		b.set_target(target)
	# Bullet.tscn uses Bullet.gd, which defines these properties.
	# Set them directly to avoid invalid has_variable checks.
	b.speed = bullet_speed
	b.damage = damage
	b.splash_radius = splash_radius
	# Bullet.gd defines has_trail; set directly
	b.has_trail = bullet_trail
	var container = get_tree().get_first_node_in_group("bullets")
	if container:
		container.add_child(b)
	else:
		get_tree().current_scene.add_child(b)
	# Trigger visual recoil after shot
	if visual and visual.has_method("trigger_recoil"):
		visual.trigger_recoil(muzzle_index, recoil_amount)
	if twin:
		_barrel_cycle = 1 - _barrel_cycle

func _get_muzzle_global(idx: int = 0) -> Vector2:
	if visual and visual.has_method("get_muzzle_points_local"):
		var pts: Array = visual.call("get_muzzle_points_local")
		if pts.size() > 0:
			var local: Vector2 = pts[clamp(idx, 0, pts.size() - 1)]
			return sprite.to_global(local)
	return global_position

func _aim_at(target: Node) -> void:
	if sprite == null:
		return
	if not (target is Node2D):
		return
	var dir: Vector2 = (target as Node2D).global_position - global_position
	var ang := dir.angle() + deg_to_rad(aim_offset_degrees)
	sprite.rotation = ang

func _on_click_input(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var main = get_tree().current_scene
		if main and main.has_method("_on_tower_selected"):
			main._on_tower_selected(self)
		# Mark as handled so _unhandled_input in Main doesn't clear selection
		if get_viewport():
			get_viewport().set_input_as_handled()

func get_range_radius() -> float:
	if range_area and range_area.has_node("CollisionShape2D"):
		var cs = range_area.get_node("CollisionShape2D")
		if cs and cs is CollisionShape2D and (cs as CollisionShape2D).shape is CircleShape2D:
			return ((cs as CollisionShape2D).shape as CircleShape2D).radius
	return 0.0

func select() -> void:
	show_range = true
	queue_redraw()
	# Forward level to visual for rank chevrons if supported
	if visual:
		visual.level = level
		visual.queue_redraw()

func deselect() -> void:
	show_range = false
	queue_redraw()

func get_stats() -> Dictionary:
	return {
		"damage": damage,
		"cooldown": 1.0 / max(0.001, fire_rate),
		"splash": splash_radius,
		"range": get_range_radius(),
		"level": level,
	}

func get_upgrade_cost() -> int:
	# Progressive cost based on original build_cost and current level
	var base := float(build_cost) * base_upgrade_factor
	var mult := pow(upgrade_multiplier, float(level - 1))
	return int(ceil(max(1.0, base * mult)))

func upgrade_level() -> void:
	level += 1
	# Progressive increases
	damage += damage_per_level
	# Fire rate and range scale from base using current level (stable over multiple upgrades)
	fire_rate = _base_fire_rate * pow(fire_rate_growth, float(level - 1))
	if _range_shape:
		_range_shape.radius = _base_range_radius * pow(range_growth, float(level - 1))
	# Inform visual
	if visual:
		visual.level = level
		visual.queue_redraw()
	# Redraw range ring if currently shown
	queue_redraw()

func _draw() -> void:
	if not show_range:
		return
	var r := get_range_radius()
	if r <= 0.0:
		return
	# Subtle filled circle + ring
	var fill_col := Color(0.2, 0.8, 1.0, 0.07)
	var ring_col := Color(0.2, 0.8, 1.0, 0.25)
	draw_circle(Vector2.ZERO, r, fill_col)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, ring_col, 2.0)
