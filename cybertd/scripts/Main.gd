extends Node2D

@onready var path: Path2D = $Path2D
@onready var spawn_timer: Timer = $SpawnTimer
@onready var towers_container: Node2D = $Towers
@onready var bullets_container: Node2D = $Bullets
@onready var build_spots: Node = $BuildSpots
@onready var hud: Control = $UI/HUD
@onready var right_panel: Control = $UI/RightPanel
@onready var grid_painter: Node2D = $GridPainter
@onready var effects_container: Node2D = $EffectsContainer
@onready var ui_effects_layer: CanvasLayer = $UIEffectsLayer

var enemy_scene: PackedScene
var juggernaut_scene: PackedScene
var tower_scene: PackedScene
const BuildSpotClass = preload("res://scripts/BuildSpot.gd")

# Grid
const CELL: int = 64
const GRID_OFFSET: Vector2 = Vector2(0, 0)

# Game state
var wave_index: int = 0
var lives: int = 20
var gold: int = 50
var wave_clear_bonus: int = 5 # Odměna za vyčištění vlny
var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var next_wave_timer: Timer

# Effects
var FloatingTextScene: PackedScene = preload("res://scenes/FloatingText.tscn")
var ImpactEffectScene: PackedScene = preload("res://scenes/ImpactEffect.tscn")
@onready var camera: Camera2D = $Camera2D
var screenshake_on_kill: bool = false

# Build selection - JEDINÝ ZDROJ PRAVDY PRO DATA O VĚŽÍCH
var tower_definitions := {
	"rapid": {
		"scene": preload("res://scenes/TowerRapid.tscn"),
		"cost": 10, "name": "Rapid Tower", "damage": 2, "armor_penetration": 1,
		"visual_config": {
			"custom_detail_color": Color(0.9, 0.8, 0.2, 1),
			"twin_barrels": true
		}
	},
	"sniper": {
		"scene": preload("res://scenes/TowerSniper.tscn"),
		"cost": 18, "name": "Sniper Tower", "damage": 12, "armor_penetration": 10,
		"visual_config": {
			"custom_detail_color": Color(0.9, 0.2, 0.2, 1),
			"barrel_length": 40.0, "barrel_width": 4.0, "twin_barrels": false
		}
	},
	"splash": {
		"scene": preload("res://scenes/TowerSplash.tscn"),
		"cost": 14, "name": "Splash Tower", "damage": 3, "armor_penetration": 0,
		"visual_config": {
			"custom_detail_color": Color(0.2, 0.6, 0.9, 1),
			"splash_turret": true, "barrel_length": 18.0, "barrel_width": 8.0
		}
	},
	"microwave": {
		"scene": preload("res://scenes/TowerMicrowave.tscn"),
		"cost": 25, "name": "Microwave", "damage": 2, "armor_penetration": 0,
		"visual_config": {
			"custom_detail_color": Color(0.2, 0.8, 0.9, 1),
			"barrel_length": 20.0, "barrel_width": 15.0, "twin_barrels": false
		}
	},
	"acoustic": {
		"scene": preload("res://scenes/TowerAcoustic.tscn"),
		"cost": 30, "name": "Acoustic", "damage": 0, "armor_penetration": 0,
		"visual_config": {
			"custom_detail_color": Color(0.8, 0.3, 0.9, 1),
			"base_radius": 20.0, "twin_barrels": false
		}
	},
	"nano": {
		"scene": preload("res://scenes/TowerNano.tscn"),
		"cost": 40, "name": "Nano Swarm", "damage": 5, "armor_penetration": 0,
		"visual_config": {
			"custom_detail_color": Color(0.3, 0.9, 0.4, 1),
			"base_radius": 18.0, "twin_barrels": false
		}
	}
}
var selected_build: String = "rapid"

# Wave config: (count, speed, health, reward, armor, juggernauts)
var waves := [
	{"count": 6,  "speed": 24.0, "health": 10, "reward": 2, "armor": 0},
	{"count": 8,  "speed": 25.2, "health": 12, "reward": 2, "armor": 0},
	{"count": 10, "speed": 26.4, "health": 14, "reward": 3, "armor": 1},
	{"count": 10, "speed": 27.6, "health": 16, "reward": 3, "armor": 1},
	{"count": 12, "speed": 28.8, "health": 18, "reward": 3, "armor": 2, "juggernauts": 1}, # První Juggernaut
	{"count": 12, "speed": 30.0, "health": 22, "reward": 3, "armor": 2},
	{"count": 14, "speed": 31.2, "health": 24, "reward": 4, "armor": 3},
	{"count": 14, "speed": 32.4, "health": 28, "reward": 4, "armor": 3},
	{"count": 16, "speed": 33.6, "health": 30, "reward": 4, "armor": 4},
	{"count": 16, "speed": 34.8, "health": 34, "reward": 4, "armor": 4, "juggernauts": 2}, # Dva Juggernauti
	{"count": 18, "speed": 36.0, "health": 36, "reward": 5, "armor": 5},
	{"count": 18, "speed": 37.2, "health": 40, "reward": 5, "armor": 5},
	{"count": 20, "speed": 38.4, "health": 44, "reward": 5, "armor": 6},
	{"count": 20, "speed": 39.6, "health": 48, "reward": 5, "armor": 6},
	{"count": 22, "speed": 40.8, "health": 52, "reward": 6, "armor": 7, "juggernauts": 3}, # Tři Juggernauti
	{"count": 22, "speed": 42.0, "health": 56, "reward": 6, "armor": 7},
	{"count": 24, "speed": 43.2, "health": 60, "reward": 6, "armor": 8},
	{"count": 24, "speed": 44.4, "health": 66, "reward": 6, "armor": 8},
	{"count": 26, "speed": 45.6, "health": 72, "reward": 7, "armor": 9},
	{"count": 28, "speed": 48.0, "health": 80, "reward": 8, "armor": 10, "juggernauts": 4},
]

func _ready() -> void:
	# Nastavení tmavého pozadí pro Godot 4
	RenderingServer.set_default_clear_color(Color(0.1, 0.12, 0.15, 1.0))

	enemy_scene = load("res://scenes/Enemy.tscn")
	juggernaut_scene = load("res://scenes/EnemyJuggernaut.tscn")
	tower_scene = load("res://scenes/Tower.tscn")
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	bullets_container.add_to_group("bullets")
	_setup_path_points()
	_update_path_line()
	_wire_build_spots()
	_hud_set()
	_hud_enable(true, "Start Wave")
	# Next wave timer
	next_wave_timer = Timer.new()
	next_wave_timer.one_shot = true
	add_child(next_wave_timer)
	next_wave_timer.timeout.connect(func():
		if wave_index < waves.size():
			_on_start_wave_pressed()
	)
	# Propojíme časovač s HUDem
	if hud and "next_wave_timer" in hud:
		hud.next_wave_timer = next_wave_timer

	# Ensure UIEffectsLayer is discoverable by towers for range indicators
	if is_instance_valid(ui_effects_layer):
		ui_effects_layer.add_to_group("ui_effects_layer")
		
	# Start with panel hidden; show only on selection
	if right_panel and right_panel.has_method("close_panel"):
		right_panel.close_panel()

func _wire_build_spots() -> void:
	for spot in build_spots.get_children():
		if spot.has_signal("build_requested"):
			var cb := Callable(self, "_on_build_requested")
			if not spot.build_requested.is_connected(cb):
				spot.build_requested.connect(_on_build_requested)

func _hud_set() -> void:
	if hud and hud.has_method("set_stats"):
		hud.set_stats(lives, gold, wave_index + 1)
	if hud and hud.has_signal("start_wave_pressed"):
		if hud.start_wave_pressed.is_connected(_on_start_wave_pressed):
			hud.start_wave_pressed.disconnect(_on_start_wave_pressed)
		hud.start_wave_pressed.connect(_on_start_wave_pressed)
	if hud and hud.has_signal("speed_changed"):
		if hud.speed_changed.is_connected(_on_speed_changed):
			hud.speed_changed.disconnect(_on_speed_changed)
		hud.speed_changed.connect(_on_speed_changed)
	if hud and hud.has_signal("build_selected"):
		if hud.build_selected.is_connected(_on_build_selected):
			hud.build_selected.disconnect(_on_build_selected)
		hud.build_selected.connect(_on_build_selected)
	if hud and hud.has_method("set_build_visible"):
		hud.set_build_visible(true)
	if right_panel:
		if right_panel.has_signal("build_choice"):
			if right_panel.build_choice.is_connected(_on_build_selected):
				right_panel.build_choice.disconnect(_on_build_selected)
			right_panel.build_choice.connect(_on_build_selected)
		if right_panel.has_signal("upgrade_damage"):
			if right_panel.upgrade_damage.is_connected(_on_upgrade_damage):
				right_panel.upgrade_damage.disconnect(_on_upgrade_damage)
			right_panel.upgrade_damage.connect(_on_upgrade_damage)
		if right_panel.has_signal("sell_requested"):
			if right_panel.sell_requested.is_connected(_on_sell_requested):
				right_panel.sell_requested.disconnect(_on_sell_requested)
			right_panel.sell_requested.connect(_on_sell_requested)

func _hud_enable(enabled: bool, text: String) -> void:
	if hud and hud.has_method("set_button_enabled"):
		hud.set_button_enabled(enabled, text)

func _on_start_wave_pressed() -> void:
	if wave_index >= waves.size():
		return
	
	# Zastavíme časovač, pokud byl spuštěn
	if is_instance_valid(next_wave_timer) and not next_wave_timer.is_stopped():
		next_wave_timer.stop()
		
	var w = waves[wave_index]
	enemies_to_spawn = int(w.get("count", 0))
	# Přidáme Juggernauty do celkového počtu
	enemies_to_spawn += int(w.get("juggernauts", 0))
	
	enemies_alive = 0
	spawn_timer.wait_time = 1.4
	spawn_timer.start()
	_hud_enable(false, "Spawning...")
	_hud_set_enemies_left(enemies_to_spawn + enemies_alive)

func _on_spawn_timer_timeout() -> void:
	if enemies_to_spawn > 0:
		var wave_data = waves[wave_index]
		var juggernauts_in_wave = int(wave_data.get("juggernauts", 0))
		var soldiers_in_wave = int(wave_data.get("count", 0))
		
		# Rozhodneme, zda spawnout Juggernauta nebo vojáka
		# Spawnujeme Juggernauty rovnoměrně během vlny
		var spawn_juggernaut = false
		if juggernauts_in_wave > 0:
			var total_enemies = soldiers_in_wave + juggernauts_in_wave
			# Compute a safe integer interval (at least 1) to avoid division/modulo issues
			var spawn_interval: int = int(max(1.0, floor(float(total_enemies) / float(juggernauts_in_wave))))
			if spawn_interval <= 0:
				spawn_interval = 1
			if ((total_enemies - enemies_to_spawn) % spawn_interval) == 0:
				spawn_juggernaut = true

		if spawn_juggernaut:
			_spawn_enemy(juggernaut_scene, wave_data)
		else:
			_spawn_enemy(enemy_scene, wave_data)
			
		enemies_to_spawn -= 1
		if enemies_to_spawn == 0:
			spawn_timer.stop()
			_hud_enable(false, "Wave Running")

func _spawn_enemy(scene: PackedScene, wave: Dictionary) -> void:
	if scene == null:
		return
	var e = scene.instantiate()
	# Initialize stats BEFORE adding to the tree so _ready doesn't set health from old max
	e.speed = float(wave.get("speed", 120.0))
	e.max_health = int(wave.get("health", 10))
	e.health = e.max_health
	e.reward_gold = int(wave.get("reward", 2))
	e.armor = int(wave.get("armor", 0))
	path.add_child(e)
	e.reset_on_spawn(e.speed)
	enemies_alive += 1
	_hud_set_enemies_left(enemies_to_spawn + enemies_alive)
	e.escaped.connect(_on_enemy_escaped.bind(e))
	e.died.connect(_on_enemy_died.bind(e))
	if e.has_signal("damaged"):
		e.damaged.connect(_on_enemy_damaged.bind(e))

func _on_enemy_escaped(_e) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	lives -= 1
	_hud_set()
	_hud_set_enemies_left(enemies_to_spawn + enemies_alive)
	_check_wave_end()

func _on_enemy_died(e) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	gold += int(e.reward_gold)
	_spawn_effect_impact((e as Node2D).global_position, Vector2.UP, 1.2) # Větší efekt při smrti
	if screenshake_on_kill:
		_shake_camera(0.12, 5.0)
	_hud_set()
	_hud_set_enemies_left(enemies_to_spawn + enemies_alive)
	_check_wave_end()

func _on_enemy_damaged(amount: int, e) -> void:
	var pos := (e as Node2D).global_position + Vector2(0, -20)
	_spawn_floating_text("-%d" % amount, pos, Color(1, 0.8, 0.4, 1))
	# Poznámka: Efekt zásahu se nyní spawnuje ze střely (Bullet.gd), ne zde.

func _check_wave_end() -> void:
	if enemies_to_spawn == 0 and enemies_alive == 0:
		if lives <= 0:
			if hud and hud.has_method("show_state"):
				hud.show_state("Defeat! Press Esc for Menu")
			return
		
		# Přidáme odměnu za vlnu
		gold += wave_clear_bonus
		_hud_set() # Aktualizujeme HUD se zlatem
		
		wave_index += 1
		_hud_set()
		if wave_index >= waves.size():
			if hud and hud.has_method("show_state"):
				hud.show_state("Victory! Press Esc for Menu")
			_hud_enable(false, "Done")
		else:
			_hud_enable(true, "Next Wave") # Zobrazíme tlačítko
			# Auto-start next wave in 5 seconds
			if is_instance_valid(next_wave_timer):
				next_wave_timer.start(5.0)
	else:
		_hud_set_enemies_left(enemies_to_spawn + enemies_alive)

func _hud_set_enemies_left(n: int) -> void:
	if hud and hud.has_method("set_enemies_left"):
		hud.set_enemies_left(max(0, n))

func _on_build_requested(spot: Node) -> void:
	_pending_spot = spot
	if right_panel and right_panel.has_method("open_build"):
		right_panel.open_build(tower_definitions)

func _on_build_selected(t: String) -> void:
	selected_build = t
	if _pending_spot:
		var tower_def = tower_definitions.get(selected_build)
		if gold >= tower_def.cost and tower_def.scene != null:
			var tower: Node2D = tower_def.scene.instantiate()
			if _pending_spot is Node2D:
				tower.global_position = (_pending_spot as Node2D).global_position
			towers_container.add_child(tower)
			gold -= tower_def.cost
			_hud_set()
			if _pending_spot is BuildSpotClass:
				(_pending_spot as BuildSpotClass).occupied = true
			_pending_spot.queue_free()
		if right_panel and right_panel.has_method("close_panel"):
			right_panel.close_panel()
		_pending_spot = null

var _pending_spot: Node = null

var _selected_tower: Node2D = null

func _on_upgrade_damage() -> void:
	if _selected_tower:
		# Check max level and cost
		var can_upgrade := true
		var cost := 0
		var level_now := 1
		if "level" in _selected_tower:
			level_now = _selected_tower.level
		if "max_level" in _selected_tower and level_now >= _selected_tower.max_level:
			can_upgrade = false
		if _selected_tower.has_method("get_upgrade_cost"):
			cost = _selected_tower.get_upgrade_cost()
		if can_upgrade and gold >= cost:
			gold -= cost
			if _selected_tower.has_method("upgrade_level"):
				_selected_tower.upgrade_level()
			else:
				if "damage" in _selected_tower:
					_selected_tower.damage += 1
			_hud_set()
		# Refresh panel stats after attempted upgrade
		if right_panel and right_panel.has_method("open_tower"):
			var stats = _get_tower_stats(_selected_tower)
			right_panel.open_tower(stats)
			if right_panel.has_method("set_upgrade_state"):
				var cost2 := 0
				var can2 := true
				var lvl := 1
				if _selected_tower and ("level" in _selected_tower):
					lvl = _selected_tower.level
				if _selected_tower and _selected_tower.has_method("get_upgrade_cost"):
					cost2 = _selected_tower.get_upgrade_cost()
				if _selected_tower and ("max_level" in _selected_tower) and lvl >= _selected_tower.max_level:
					can2 = false
				if gold < cost2:
					can2 = false
				right_panel.set_upgrade_state(cost2, can2)

func _on_sell_requested() -> void:
	if _selected_tower:
		_selected_tower.queue_free()
		_selected_tower = null
	if right_panel and right_panel.has_method("close_panel"):
		right_panel.close_panel()

func _on_tower_selected(tower: Node2D) -> void:
	# Deselect previous
	if _selected_tower and _selected_tower != tower and _selected_tower.has_method("deselect"):
		_selected_tower.deselect()
	_selected_tower = tower
	if _selected_tower and _selected_tower.has_method("select"):
		_selected_tower.select()
	if right_panel and right_panel.has_method("open_tower"):
		var stats = _get_tower_stats(tower)
		right_panel.open_tower(stats)
		if right_panel.has_method("set_upgrade_state"):
			var cost := 0
			var can := true
			var level_now := 1
			if tower and ("level" in tower):
				level_now = tower.level
			if tower and tower.has_method("get_upgrade_cost"):
				cost = tower.get_upgrade_cost()
			if tower and ("max_level" in tower) and level_now >= tower.max_level:
				can = false
			if gold < cost:
				can = false
			right_panel.set_upgrade_state(cost, can)

func _get_tower_stats(tower: Node) -> Dictionary:
	if tower and tower.has_method("get_stats"):
		return tower.get_stats()
	# Fallback for generic Node2D towers using Tower.gd API
	var dmg := 0
	var fr := 1.0
	var splash := 0.0
	var rng := 0.0
	var lvl := 1
	if tower:
		if "damage" in tower:
			dmg = tower.damage
		if "fire_rate" in tower:
			fr = max(0.001, float(tower.fire_rate))
		if "splash_radius" in tower:
			splash = float(tower.splash_radius)
		if tower.has_method("get_range_radius"):
			rng = float(tower.get_range_radius())
		if "level" in tower:
			lvl = int(tower.level)
	return {
		"damage": dmg,
		"cooldown": 1.0 / fr,
		"splash": splash,
		"range": rng,
		"level": lvl,
	}

func clear_selection() -> void:
	if _selected_tower and _selected_tower.has_method("deselect"):
		_selected_tower.deselect()
	_selected_tower = null
	_pending_spot = null
	if right_panel and right_panel.has_method("close_panel"):
		right_panel.close_panel()

func _update_path_line() -> void:
	if not path or not path.curve:
		return
	var pts: PackedVector2Array = path.curve.get_baked_points()
	if has_node("PathLine"):
		$PathLine.points = pts
	if has_node("PathEdge"):
		$PathEdge.points = pts
	if has_node("PathInner"):
		$PathInner.points = pts

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var menu := load("res://scenes/MainMenu.tscn") as PackedScene
		if menu:
			get_tree().change_scene_to_packed(menu)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Změna priority: Nejprve zkusíme stavět.
		var build_spot_was_selected = _try_build_at_mouse(event.position)
		
		# Pokud jsme neklikli na stavební parcelu, zkusíme vybrat věž.
		if not build_spot_was_selected:
			var tower_was_selected = _try_select_tower_at_mouse(event.position)
			
			# Pokud jsme neklikli ani na věž, zrušíme výběr.
			if not tower_was_selected:
				clear_selection()

func _on_speed_changed(mult: float) -> void:
	Engine.time_scale = clampf(mult, 0.25, 4.0)

func _try_build_at_mouse(pos: Vector2) -> bool:
	# Fallback picking for BuildSpot in case _input_event is blocked by anything
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 2 # BuildSpot layer
	var results = space.intersect_point(params, 16)
	for r in results:
		var col = r.get("collider")
		if col is BuildSpotClass:
			_on_build_requested(col)
			return true
		if col and col.get_parent() is BuildSpotClass:
			_on_build_requested(col.get_parent())
			return true
	return false

func _try_select_tower_at_mouse(pos: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 4 # Tower ClickArea layer
	var results = space.intersect_point(params, 16)
	for r in results:
		var col = r.get("collider")
		if col and col.get_parent() is Node2D:
			var t := col.get_parent() as Node2D
			if t and has_method("_on_tower_selected"):
				_on_tower_selected(t)
				return true
	return false

func _setup_path_points() -> void:
	# Build a right-angle path on a 64px grid and spawn build spots along path sides
	if not path:
		return
	var grid_points: Array[Vector2i] = [
		Vector2i(1, 6), Vector2i(4, 6), Vector2i(4, 4), Vector2i(8, 4), Vector2i(8, 2), Vector2i(12, 2)
	]
	var c := Curve2D.new()
	var world_pts: Array[Vector2] = []
	for gp in grid_points:
		# Use cell centers for a centered path
		var wp := GRID_OFFSET + Vector2(gp.x * CELL + CELL * 0.5, gp.y * CELL + CELL * 0.5)
		world_pts.append(wp)
		c.add_point(wp)
	path.curve = c
	_update_path_line()
	_place_markers_grid(grid_points)
	var path_cells := _cells_along_path(grid_points)
	_spawn_grid_build_spots_grid(grid_points)
	_update_grid_painter(path_cells)
	_center_camera_on_path()

func _place_markers_grid(grid_pts: Array[Vector2i]) -> void:
	if grid_pts.is_empty():
		return
	var start_cell: Vector2i = grid_pts.front()
	var end_cell: Vector2i = grid_pts.back()
	var start_p: Vector2 = GRID_OFFSET + Vector2(start_cell.x * CELL + CELL * 0.5, start_cell.y * CELL + CELL * 0.5)
	var end_p: Vector2 = GRID_OFFSET + Vector2(end_cell.x * CELL + CELL * 0.5, end_cell.y * CELL + CELL * 0.5)
	if has_node("StartMarker"):
		$StartMarker.position = start_p
	if has_node("Core") and $Core is Node2D:
		($Core as Node2D).position = end_p

func _spawn_grid_build_spots_grid(grid_pts: Array[Vector2i]) -> void:
	# Clear existing spots
	for child in build_spots.get_children():
		child.queue_free()
	if grid_pts.size() < 2:
		return
	var path_cells: = _cells_along_path(grid_pts)
	var spot_cells: = _adjacent_side_cells(path_cells)
	var spot_scene: PackedScene = load("res://scenes/BuildSpot.tscn")
	if spot_scene == null:
		return
	for cell in spot_cells:
		var pos := GRID_OFFSET + Vector2(cell.x * CELL + CELL * 0.5, cell.y * CELL + CELL * 0.5)
		var s: Area2D = spot_scene.instantiate()
		(s as Node2D).global_position = pos
		build_spots.add_child(s)
		if s.has_signal("build_requested"):
			var cb := Callable(self, "_on_build_requested")
			if not s.build_requested.is_connected(cb):
				s.build_requested.connect(_on_build_requested)

func _cells_along_path(grid_pts: Array[Vector2i]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(grid_pts.size() - 1):
		var a: Vector2i = grid_pts[i]
		var b: Vector2i = grid_pts[i + 1]
		if a.x == b.x:
			var step: int = 1 if b.y > a.y else -1
			for y in range(a.y, b.y + step, step):
				cells.append(Vector2i(a.x, y))
		elif a.y == b.y:
			var stepx: int = 1 if b.x > a.x else -1
			for x in range(a.x, b.x + stepx, stepx):
				cells.append(Vector2i(x, a.y))
	# Deduplicate
	var uniq := {}
	var out: Array[Vector2i] = []
	for c in cells:
		if not uniq.has(c):
			uniq[c] = true
			out.append(c)
	return out

func _adjacent_side_cells(path_cells: Array[Vector2i]) -> Array[Vector2i]:
	var set_path := {}
	for c in path_cells:
		set_path[c] = true
	var spots := {}
	# Determine side cells for each path cell based on local direction
	for i in range(path_cells.size()):
		var cur := path_cells[i]
		var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		# neighbors orthogonal to path cell considered as candidates
		for n in dirs:
			var cand: Vector2i = cur + n
			if set_path.has(cand):
				continue
			spots[cand] = true
	# Convert to array
	var out: Array[Vector2i] = []
	for k in spots.keys():
		out.append(k)
	return out

func _update_grid_painter(path_cells: Array[Vector2i]) -> void:
	if grid_painter and grid_painter.has_method("set_cells"):
		var spots := _adjacent_side_cells(path_cells)
		(grid_painter as Node).call("set_cells", path_cells, spots)
		if grid_painter.has_method("set_offset"):
			(grid_painter as Node).call("set_offset", GRID_OFFSET)
	# Optionally hide old line visuals for a crisp tile grid look
	if has_node("PathLine"):
		$PathLine.visible = false
	if has_node("PathEdge"):
		$PathEdge.visible = false
	if has_node("PathInner"):
		$PathInner.visible = false

func _center_camera_on_path() -> void:
	if not is_instance_valid(camera):
		return
	if not path or not path.curve:
		return
	var pts: PackedVector2Array = path.curve.get_baked_points()
	if pts.is_empty():
		return
	var min_v := pts[0]
	var max_v := pts[0]
	for p in pts:
		min_v.x = min(min_v.x, p.x)
		min_v.y = min(min_v.y, p.y)
		max_v.x = max(max_v.x, p.x)
		max_v.y = max(max_v.y, p.y)
	var center := (min_v + max_v) * 0.5
	camera.position = center

# ---- Effects helpers ----
func _spawn_floating_text(text: String, pos: Vector2, color: Color) -> void:
	if FloatingTextScene == null:
		return
	var ft = FloatingTextScene.instantiate()
	effects_container.add_child(ft) # Opraveno
	if ft.has_method("setup"):
		ft.setup(text, pos, color)

func _spawn_effect_impact(pos: Vector2, direction: Vector2, p_scale: float = 1.0) -> void:
	if ImpactEffectScene == null:
		return
	var fx = ImpactEffectScene.instantiate()
	effects_container.add_child(fx) # Opraveno
	fx.global_position = pos
	if fx.has_method("play_effect"):
		fx.play_effect(direction, p_scale)

func _shake_camera(duration: float, strength: float) -> void:
	if camera and camera.has_method("shake"):
		camera.shake(duration, strength)
