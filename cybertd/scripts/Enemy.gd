extends PathFollow2D

signal escaped
signal died

@export var speed: float = 120.0
@export var max_health: int = 10
@export var reward_gold: int = 2
var health: int

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

func _process(delta: float) -> void:
	progress += speed * delta
	if progress_ratio >= 1.0:
		escaped.emit()
		queue_free()

func take_damage(dmg: int) -> void:
	health -= dmg
	if health <= 0:
		died.emit()
		queue_free()

func reset_on_spawn(base_speed: float) -> void:
	speed = base_speed
	progress = 0.0