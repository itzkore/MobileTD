extends Node2D

@onready var path: Path2D = $Path2D
@onready var spawn_timer: Timer = $SpawnTimer
@onready var towers_container: Node2D = $Towers
@onready var bullets_container: Node2D = $Bullets
@onready var build_spots: Node = $BuildSpots
@onready var hud: Control = $UI/HUD
@onready var right_panel: Control = $UI/RightPanel
@onready var grid_painter: Node2D = $GridPainter

var enemy_scene: PackedScene
var tower_scene: PackedScene
const BuildSpotClass = preload("res://scripts/BuildSpot.gd")

# Grid
const CELL: int = 64
const GRID_OFFSET: Vector2 = Vector2(0, 0)

# Game state
var wave_index: int = 0
var lives: int = 20
var gold: int = 20
var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var next_wave_timer: Timer

# Build selection
var selected_build: String = "rapid"
var tower_scenes := {
	"rapid": preload("res://scenes/TowerRapid.tscn"),
	"sniper": preload("res://scenes/TowerSniper.tscn"),
	"splash": preload("res://scenes/TowerSplash.tscn"),
}
var tower_costs := {"rapid": 10, "sniper": 18, "splash": 14}

# Wave config: pairs of (count, speed, health, reward)
var waves := [
	{"count": 6,  "speed": 40.0, "health": 10, "reward": 2},
	{"count": 8,  "speed": 42.0, "health": 12, "reward": 2},
	{"count": 10, "speed": 44.0, "health": 14, "reward": 3},
	{"count": 10, "speed": 46.0, "health": 16, "reward": 3},
	{"count": 12, "speed": 48.0, "health": 18, "reward": 3},
	{"count": 12, "speed": 50.0, "health": 22, "reward": 3},
	{"count": 14, "speed": 52.0, "health": 24, "reward": 4},
	{"count": 14, "speed": 54.0, "health": 28, "reward": 4},
	{"count": 16, "speed": 56.0, "health": 30, "reward": 4},
	{"count": 16, "speed": 58.0, "health": 34, "reward": 4},
	{"count": 18, "speed": 60.0, "health": 36, "reward": 5},
	{"count": 18, "speed": 62.0, "health": 40, "reward": 5},
	{"count": 20, "speed": 64.0, "health": 44, "reward": 5},
	{"count": 20, "speed": 66.0, "health": 48, "reward": 5},
	{"count": 22, "speed": 68.0, "health": 52, "reward": 6},
	{"count": 22, "speed": 70.0, "health": 56, "reward": 6},
	{"count": 24, "speed": 72.0, "health": 60, "reward": 6},
	{"count": 24, "speed": 74.0, "health": 66, "reward": 6},
	{"count": 26, "speed": 76.0, "health": 72, "reward": 7},
	{"count": 28, "speed": 80.0, "health": 80, "reward": 8},
]

func _ready() -> void:
	enemy_scene = load("res://scenes/Enemy.tscn")
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
	var w = waves[wave_index]
	enemies_to_spawn = int(w["count"])
	enemies_alive = 0
	spawn_timer.wait_time = 1.4
	spawn_timer.start()
	_hud_enable(false, "Spawning...")
	_hud_set_enemies_left(enemies_to_spawn + enemies_alive)

func _on_spawn_timer_timeout() -> void:
	if enemies_to_spawn > 0:
		_spawn_enemy_for_wave(waves[wave_index])
		enemies_to_spawn -= 1
		if enemies_to_spawn == 0:
			spawn_timer.stop()
			_hud_enable(false, "Wave Running")

func _spawn_enemy_for_wave(wave: Dictionary) -> void:
	if enemy_scene == null:
		return
	var e = enemy_scene.instantiate()
	# Initialize stats BEFORE adding to the tree so _ready doesn't set health from old max
	e.speed = float(wave.get("speed", 120.0))
	e.max_health = int(wave.get("health", 10))
	e.health = e.max_health
	e.reward_gold = int(wave.get("reward", 2))
	path.add_child(e)
	e.reset_on_spawn(e.speed)
	enemies_alive += 1
	_hud_set_enemies_left(enemies_to_spawn + enemies_alive)
	e.escaped.connect(_on_enemy_escaped.bind(e))
	e.died.connect(_on_enemy_died.bind(e))

func _on_enemy_escaped(_e) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	lives -= 1
	_hud_set()
	_hud_set_enemies_left(enemies_to_spawn + enemies_alive)
	_check_wave_end()

func _on_enemy_died(e) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	gold += int(e.reward_gold)
	_hud_set()
	_hud_set_enemies_left(enemies_to_spawn + enemies_alive)
	_check_wave_end()

func _check_wave_end() -> void:
	if enemies_to_spawn == 0 and enemies_alive == 0:
		if lives <= 0:
			if hud and hud.has_method("show_state"):
				hud.show_state("Defeat! Press Esc for Menu")
			return
		wave_index += 1
		_hud_set()
		if wave_index >= waves.size():
			if hud and hud.has_method("show_state"):
				hud.show_state("Victory! Press Esc for Menu")
			_hud_enable(false, "Done")
		else:
			_hud_enable(false, "Wave Running")
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
		right_panel.open_build(tower_costs)

func _on_build_selected(t: String) -> void:
	selected_build = t
	if _pending_spot:
		var scene: PackedScene = tower_scenes.get(selected_build, null)
		var cost: int = tower_costs.get(selected_build, 10)
		if gold >= cost and scene != null:
			var tower: Node2D = scene.instantiate()
			if _pending_spot is Node2D:
				tower.global_position = (_pending_spot as Node2D).global_position
			towers_container.add_child(tower)
			gold -= cost
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
	return {
		"damage": tower.damage if tower and ("damage" in tower) else 0,
		"cooldown": 1.0 / (tower.fire_rate if tower and ("fire_rate" in tower) else 1.0),
		"splash": tower.splash_radius if tower and ("splash_radius" in tower) else 0.0,
		"range": tower.get_range_radius() if tower and tower.has_method("get_range_radius") else 0.0,
		"level": tower.level if tower and ("level" in tower) else 1,
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
		if not _try_build_at_mouse(event.position):
			# Try selecting a tower by physics picking fallback
			if not _try_select_tower_at_mouse(event.position):
				# Empty click: clear selection
				clear_selection()

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
