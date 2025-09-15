extends PathFollow2D

@export var speed: float = 120.0
@export var max_health: int = 10
var health: int

func _ready() -> void:
    add_to_group("enemies")
    health = max_health
    progress = 0.0

func reset_on_spawn(base_speed: float = 120.0) -> void:
    speed = base_speed
    health = max_health
    progress = 0.0

func _process(delta: float) -> void:
    progress += speed * delta
    # In Godot 4, PathFollow2D has progress_ratio (0..1)
    if progress_ratio >= 1.0:
        queue_free()

func take_damage(dmg: int) -> void:
    health -= dmg
    if health <= 0:
        queue_free()