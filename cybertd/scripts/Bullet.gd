extends Area2D

@export var speed: float = 420.0
var target: Node2D = null
var damage: int = 1

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)
    # Safety timeout
    var t := Timer.new()
    t.one_shot = true
    t.wait_time = 4.0
    add_child(t)
    t.timeout.connect(queue_free)
    t.start()

func setup(tgt: Node2D, dmg: int = 1) -> void:
    target = tgt
    damage = dmg

func _physics_process(delta: float) -> void:
    if target == null or not is_instance_valid(target):
        queue_free()
        return
    look_at(target.global_position)
    var dir := (target.global_position - global_position).normalized()
    global_position += dir * speed * delta

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("enemies"):
        if body.has_method("take_damage"):
            body.take_damage(damage)
        queue_free()

func _on_area_entered(area: Area2D) -> void:
    var e := area.get_parent()
    if e and e.is_in_group("enemies"):
        if e.has_method("take_damage"):
            e.take_damage(damage)
        queue_free()