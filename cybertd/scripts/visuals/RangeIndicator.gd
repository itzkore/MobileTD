extends Control

var _is_shown: bool = false # Přejmenováno z 'is_visible'
var radius: float = 0.0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw() -> void:
	if not _is_shown or radius <= 0.0:
		return
		
	var fill_col := Color(0.2, 0.8, 1.0, 0.07)
	var ring_col := Color(0.2, 0.8, 1.0, 0.25)
	
	draw_circle(Vector2.ZERO, radius, fill_col)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, ring_col, 2.0)

func show_indicator(p_radius: float) -> void:
	radius = p_radius
	_is_shown = true
	queue_redraw()

func hide_indicator() -> void:
	_is_shown = false
	queue_redraw()
