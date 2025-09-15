extends Node2D

@export var fire_rate: float = 1.0 # shots per second
@export var bullet_scene: PackedScene
@export var damage: int = 1

var target: Node2D = null
var cooldown: float = 0.0

@onready var range_area: Area2D = $Range

func _ready() -> void:
    if bullet_scene == null:
        bullet_scene = load("res://scenes/Bullet.tscn")
    range_area.body_entered.connect(_on_body_entered)
    range_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    if target == null or not is_instance_valid(target):
        target = _pick_target()
        return
    # Rotate towards target (optional)
    look_at(target.global_position)
    if cooldown == 0.0:
        _shoot()

func _pick_target() -> Node2D:
    var candidates := []
    # Enemies expose an Area2D child; overlap may report either body or area depending on setup.
    var bodies := []
    if range_area.has_method("get_overlapping_bodies"):
        bodies = range_area.get_overlapping_bodies()
    for body in bodies:
        if body.is_in_group("enemies"):
            candidates.append(body)
    if range_area.has_method("get_overlapping_areas"):
        for a in range_area.get_overlapping_areas():
            var parent := a.get_parent()
            if parent and parent.is_in_group("enemies"):
                if not candidates.has(parent):
                    candidates.append(parent)
    if candidates.size() == 0:
        return null
    candidates.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
    return candidates[0]

func _shoot() -> void:
    if bullet_scene == null or target == null:
        return
    var bullet = bullet_scene.instantiate()
    bullet.global_position = global_position
    if bullet.has_method("setup"):
        bullet.setup(target, damage)
    # Find bullets container in the tree
    var root := get_tree().current_scene
    var container := root.get_node_or_null("Bullets")
    if container == null:
        container = root
    container.add_child(bullet)
    cooldown = 1.0 / max(0.01, fire_rate)

func _on_body_entered(_body: Node) -> void:
    # Target will be picked in _physics_process
    pass

func _on_body_exited(body: Node) -> void:
    if body == target:
        target = null