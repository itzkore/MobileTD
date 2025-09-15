extends Node2D

@onready var path: Path2D = $Path2D
@onready var spawn_timer: Timer = $SpawnTimer
@onready var towers_container: Node = $Towers
@onready var bullets_container: Node = $Bullets

@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene

@export var spawn_interval: float = 1.5
@export var enemy_base_speed: float = 120.0

func _ready() -> void:
    # Ensure there's a usable path; auto-generate a simple one if empty.
    _ensure_default_path()
    
    # Fallback scenes if not set in the inspector
    if enemy_scene == null:
        enemy_scene = load("res://scenes/Enemy.tscn")
    if tower_scene == null:
        tower_scene = load("res://scenes/Tower.tscn")

    spawn_timer.wait_time = spawn_interval
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    spawn_timer.start()

    # Mark bullets container for easy lookup by towers
    bullets_container.add_to_group("bullets")

    # Place a sample tower so you can press Play and see it shooting.
    if tower_scene:
        var t: Node2D = tower_scene.instantiate()
        t.position = Vector2(200, 140)
        towers_container.add_child(t)

func _ensure_default_path() -> void:
    if path.curve == null:
        path.curve = Curve2D.new()
    if path.curve.get_point_count() < 2:
        path.curve.clear_points()
        path.curve.add_point(Vector2(40, 200))
        path.curve.add_point(Vector2(360, 200))

func _on_spawn_timer_timeout() -> void:
    _spawn_enemy()

func _spawn_enemy() -> void:
    if enemy_scene == null:
        return
    var e = enemy_scene.instantiate()
    # Enemy is a PathFollow2D; add it under Path2D so it follows the curve.
    path.add_child(e)
    if e.has_method("reset_on_spawn"):
        e.reset_on_spawn(enemy_base_speed)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        var menu := load("res://scenes/MainMenu.tscn") as PackedScene
        get_tree().change_scene_to_packed(menu)