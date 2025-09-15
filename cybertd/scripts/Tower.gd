extends Node2D

@export var fire_rate: float = 1.0
@export var bullet_speed: float = 300.0
@export var damage: int = 3
@export var armor_penetration: int = 0
@export var tower_range: float = 120.0
@export var turn_rate: float = 180.0 # Rychlost otáčení ve stupních za sekundu
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
@export var turn_rate_growth: float = 1.05 # Zlepšení rychlosti otáčení o 5% za úroveň

var level: int = 1
var show_range: bool = false
var bullet_scene: PackedScene
var time_accum: float = 0.0

# Nahrazeno bezpečnějším načítáním v _ready()
var range_area: Area2D
var click_area: Area2D
var sprite: Node2D
var visual: Node2D
var _range_shape_node: CollisionShape2D

var _range_shape: CircleShape2D
var _base_range_radius: float = 0.0
var _base_fire_rate: float = 1.0
var _base_turn_rate: float = 1.0
var _range_indicator: Control

var RangeIndicatorScene = preload("res://scenes/ui/RangeIndicator.tscn")

func _ready() -> void:
	# Bezpečné načtení uzlů
	range_area = get_node_or_null("Range")
	click_area = get_node_or_null("ClickArea")
	sprite = get_node_or_null("Sprite2D")
	# _range_indicator se nyní vytváří dynamicky
	if sprite:
		visual = sprite.get_node_or_null("Visual")
	if range_area:
		_range_shape_node = range_area.get_node_or_null("CollisionShape2D")

	# Kontrola, zda byly uzly nalezeny, aby se předešlo pádu
	if not range_area or not click_area or not sprite or not _range_shape_node:
		printerr("Chyba ve struktuře věže! Jeden nebo více požadovaných uzlů chybí: Range, ClickArea, Sprite2D, nebo CollisionShape2D.")
		return

	bullet_scene = load("res://scenes/Bullet.tscn")
	click_area.input_event.connect(_on_click_input)
	click_area.input_pickable = true
	
	# Cache base stats for progressive upgrades
	_base_fire_rate = max(0.001, fire_rate)
	_base_turn_rate = max(0.1, turn_rate)
	if _range_shape_node and _range_shape_node.shape is CircleShape2D:
		_range_shape = _range_shape_node.shape as CircleShape2D
		_base_range_radius = _range_shape.radius
	
	# Synchronizace poloměru s proměnnou 'tower_range'
	if _range_shape:
		_range_shape.radius = tower_range


func _process(delta: float) -> void:
	time_accum += delta
	var target = _pick_target()
	if target:
		var can_shoot = _aim_at(target, delta)
		if can_shoot and time_accum >= (1.0 / max(0.001, fire_rate)) and bullet_scene:
			_shoot(target)
			time_accum = 0.0

func _pick_target() -> Node:
	for area in range_area.get_overlapping_areas():
		var parent := area.get_parent()
		if parent and parent.is_in_group("enemies"):
			return area # Vrátíme přímo hitbox (Area2D), ne jeho rodiče
	return null

func _shoot(target: Node) -> void:
	var b = bullet_scene.instantiate()
	if b == null:
		return
	
	var muzzle_pos = _get_muzzle_global()
	b.global_position = muzzle_pos
	
	var target_node = target
	if target.has_node("TargetPoint"):
		target_node = target.get_node("TargetPoint")

	if b.has_method("set_target"):
		b.set_target(target_node)
	# Bullet.tscn uses Bullet.gd, which defines these properties.
	# Set them directly to avoid invalid has_variable checks.
	b.speed = bullet_speed
	b.damage = damage
	b.armor_penetration = armor_penetration
	b.splash_radius = splash_radius
	b.impact_scale = 1.0 # Standardní velikost efektu
	# Bullet.gd defines has_trail; set directly
	b.has_trail = bullet_trail
	var container = get_tree().get_first_node_in_group("bullets")
	if container:
		container.add_child(b)
	else:
		get_tree().current_scene.add_child(b)
		
	if visual and visual.has_method("trigger_recoil"):
		visual.trigger_recoil(0, recoil_amount)

func _get_muzzle_global() -> Vector2:
	if visual:
		var muzzle_point = visual.get_node_or_null("MuzzlePoint")
		if muzzle_point and muzzle_point is Marker2D:
			return muzzle_point.global_position
	
	return global_position

func _aim_at(target: Node, delta: float) -> bool:
	if sprite == null or not (target is Node2D):
		return false
		
	var target_pos = (target as Node2D).global_position
	var dir: Vector2 = target_pos - global_position
	var target_angle = dir.angle() + deg_to_rad(aim_offset_degrees)
	
	# Plynulé otáčení k cíli
	var turn_speed_rad = deg_to_rad(turn_rate)
	sprite.rotation = move_toward(sprite.rotation, target_angle, turn_speed_rad * delta)
	
	# Vrací true, pokud je věž zaměřená (s malou tolerancí)
	var angle_diff = abs(angle_difference(sprite.rotation, target_angle))
	return angle_diff < deg_to_rad(5.0)

func _on_click_input(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var main = get_tree().current_scene
		if main and main.has_method("_on_tower_selected"):
			main._on_tower_selected(self)
		# Mark as handled so _unhandled_input in Main doesn't clear selection
		if get_viewport():
			get_viewport().set_input_as_handled()

func get_range_radius() -> float:
	# Vždy vrátí aktuální poloměr přímo z uzlu, což je nejspolehlivější.
	if _range_shape_node and _range_shape_node.shape is CircleShape2D:
		return (_range_shape_node.shape as CircleShape2D).radius
	return 0.0

func select() -> void:
	if not is_instance_valid(_range_indicator):
		_range_indicator = RangeIndicatorScene.instantiate()
		var ui_effects_layer = get_tree().get_first_node_in_group("ui_effects_layer")
		if ui_effects_layer:
			ui_effects_layer.add_child(_range_indicator)
		else: # Záložní varianta
			get_tree().current_scene.add_child(_range_indicator)
		_range_indicator.global_position = global_position

	if _range_indicator.has_method("show_indicator"):
		_range_indicator.show_indicator(get_range_radius())
	# Forward level to visual for rank chevrons if supported
	if visual:
		visual.level = level
		visual.queue_redraw()

func deselect() -> void:
	if is_instance_valid(_range_indicator):
		_range_indicator.queue_free()
		_range_indicator = null

func get_stats() -> Dictionary:
	return {
		"damage": damage,
		"cooldown": 1.0 / max(0.001, fire_rate),
		"splash": splash_radius,
		"range": get_range_radius(),
		"turn_rate": turn_rate,
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
	turn_rate = _base_turn_rate * pow(turn_rate_growth, float(level - 1))
	if _range_shape:
		_range_shape.radius = _base_range_radius * pow(range_growth, float(level - 1))
	# Inform visual
	if visual:
		visual.level = level
		visual.queue_redraw()
	# Redraw range ring if currently shown
	if _range_indicator and _range_indicator.has_method("show_indicator"):
		_range_indicator.show_indicator(get_range_radius())
