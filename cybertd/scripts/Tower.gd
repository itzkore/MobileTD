extends Node2D

@export var fire_rate: float = 1.0
@export var bullet_speed: float = 300.0
@export var damage: int = 3

var bullet_scene: PackedScene
var time_accum: float = 0.0

@onready var range_area: Area2D = $Range

func _ready() -> void:
    bullet_scene = load("res://scenes/Bullet.tscn")

func _process(delta: float) -> void:
    time_accum += delta
    if time_accum >= (1.0 / max(0.001, fire_rate)):
        var target = _pick_target()
        if target and bullet_scene:
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
    b.global_position = global_position
    if b.has_method("set_target"):
        b.set_target(target)
    var container = get_tree().get_first_node_in_group("bullets")
    if container:
        container.add_child(b)
    else:
        get_tree().current_scene.add_child(b)