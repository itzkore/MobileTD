extends Node2D

@onready var path: Path2D = $Path2D
@onready var spawn_timer: Timer = $SpawnTimer
@onready var towers_container: Node2D = $Towers
@onready var bullets_container: Node2D = $Bullets
@onready var build_spots: Node = $BuildSpots
@onready var hud: Control = $HUD

var enemy_scene: PackedScene
var tower_scene: PackedScene

# Game state
var wave_index: int = 0
var lives: int = 20
var gold: int = 20
var enemies_to_spawn: int = 0
var enemies_alive: int = 0

# Wave config: pairs of (count, speed, health, reward)
var waves := [
    {"count": 6,  "speed": 100.0, "health": 8,  "reward": 2},
    {"count": 10, "speed": 120.0, "health": 12, "reward": 3},
    {"count": 14, "speed": 140.0, "health": 18, "reward": 4},
]

func _ready() -> void:
    enemy_scene = load("res://scenes/Enemy.tscn")
    tower_scene = load("res://scenes/Tower.tscn")
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    bullets_container.add_to_group("bullets")
    _wire_build_spots()
    _hud_set()
    _hud_enable(true, "Start Wave")

func _wire_build_spots() -> void:
    for spot in build_spots.get_children():
        if spot.has_signal("build_requested"):
            spot.build_requested.connect(_on_build_requested)

func _hud_set() -> void:
    if hud and hud.has_method("set_stats"):
        hud.set_stats(lives, gold, wave_index + 1)
    if hud and hud.has_signal("start_wave_pressed"):
        if hud.start_wave_pressed.is_connected(_on_start_wave_pressed):
            hud.start_wave_pressed.disconnect(_on_start_wave_pressed)
        hud.start_wave_pressed.connect(_on_start_wave_pressed)

func _hud_enable(enabled: bool, text: String) -> void:
    if hud and hud.has_method("set_button_enabled"):
        hud.set_button_enabled(enabled, text)

func _on_start_wave_pressed() -> void:
    if wave_index >= waves.size():
        return
    var w = waves[wave_index]
    enemies_to_spawn = int(w["count"])
    enemies_alive = 0
    spawn_timer.wait_time = max(0.3, 1.0)
    spawn_timer.start()
    _hud_enable(false, "Spawning...")

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
    path.add_child(e)
    e.speed = float(wave.get("speed", 120.0))
    e.max_health = int(wave.get("health", 10))
    e.reward_gold = int(wave.get("reward", 2))
    e.reset_on_spawn(e.speed)
    enemies_alive += 1
    e.escaped.connect(_on_enemy_escaped.bind(e))
    e.died.connect(_on_enemy_died.bind(e))

func _on_enemy_escaped(_e) -> void:
    enemies_alive = max(0, enemies_alive - 1)
    lives -= 1
    _hud_set()
    _check_wave_end()

func _on_enemy_died(e) -> void:
    enemies_alive = max(0, enemies_alive - 1)
    gold += int(e.reward_gold)
    _hud_set()
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
            _hud_enable(true, "Next Wave")

func _on_build_requested(spot: Node) -> void:
    var cost := 10
    if gold < cost or tower_scene == null:
        return
    var t: Node2D = tower_scene.instantiate()
    t.global_position = spot.global_position
    towers_container.add_child(t)
    gold -= cost
    _hud_set()
    if spot.has_variable("occupied"):
        spot.occupied = true
    spot.queue_free()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        var menu := load("res://scenes/MainMenu.tscn") as PackedScene
        if menu:
            get_tree().change_scene_to_packed(menu)