extends Node2D

@export var custom_detail_color: Color = Color(0.2, 0.8, 0.9, 1.0)
@export var barrel_length: float = 20.0
@export var barrel_width: float = 15.0
@export var twin_barrels: bool = false
@export var level: int = 1

func _draw():
	# Základna
	var base_col_outer = Color(0.2, 0.2, 0.25)
	var base_col_inner = Color(0.3, 0.3, 0.35)
	draw_circle(Vector2.ZERO, 20.0, base_col_outer)
	draw_circle(Vector2.ZERO, 16.0, base_col_inner)
	
	# Parabolická anténa
	var antenna_color = Color(0.8, 0.8, 0.9)
	draw_arc(Vector2(10, 0), 18.0, deg_to_rad(90), deg_to_rad(270), 32, antenna_color, 4.0)
	
	# Emitor uprostřed
	draw_circle(Vector2(15, 0), 4.0, Color(0.5, 0.8, 1.0))
