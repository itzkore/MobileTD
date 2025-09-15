extends Node2D

@export var text: String = ""
@export var color: Color = Color(1, 1, 1, 1)
@export var duration: float = 0.8
@export var rise: float = 24.0

var _label: Label
var _time: float = 0.0
var _start_pos: Vector2

func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.modulate = color
	_label.pivot_offset = Vector2.ZERO
	_label.position = Vector2(-_label.size.x * 0.5, -18)
	add_child(_label)
	_start_pos = global_position

func setup(value_text: String, at: Vector2, col: Color = Color(1,1,1,1)) -> void:
	text = value_text
	color = col
	global_position = at
	_start_pos = at
	_time = 0.0
	modulate.a = 1.0
	if _label:
		_label.text = text
		_label.modulate = color

func _process(delta: float) -> void:
	_time += delta
	var t: float = clampf(_time / duration, 0.0, 1.0)
	global_position = _start_pos + Vector2(0, -rise * t)
	var a: float = 1.0 - t
	modulate.a = a
	if t >= 1.0:
		queue_free()
