extends Area2D

signal build_requested(spot: Node)

@export var occupied: bool = false

func _input_event(_viewport, event, _shape_idx):
    if occupied:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        build_requested.emit(self)
