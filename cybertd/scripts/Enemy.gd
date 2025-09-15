extends PathFollow2D

signal escaped
signal died

@export var speed: float = 120.0
@export var max_health: int = 10
@export var reward_gold: int = 2
var health: int
signal damaged(amount: int)

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	z_as_relative = false
	z_index = 200
	queue_redraw()

func _process(delta: float) -> void:
	progress += speed * delta
	if progress_ratio >= 1.0:
		escaped.emit()
		queue_free()
		return
	if Engine.get_frames_drawn() % 2 == 0:
		queue_redraw()

func take_damage(dmg: int) -> void:
	health -= dmg
	damaged.emit(max(0, dmg))
	if health <= 0:
		died.emit()
		queue_free()
	else:
		queue_redraw()

func reset_on_spawn(base_speed: float) -> void:
	speed = base_speed
	progress = 0.0

func _draw() -> void:
	# Draw simple HP bar above the enemy
	if max_health <= 0:
		return
	var w := 28.0
	var h := 5.0
	var y := -22.0
	var ratio: float = clamp(float(health) / float(max_health), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-w * 0.5, y), Vector2(w, h)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(Vector2(-w * 0.5 + 1, y + 1), Vector2((w - 2) * ratio, h - 2)), Color(0.2, 1.0, 0.2, 1.0))