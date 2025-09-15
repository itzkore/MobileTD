extends Node2D

func _draw():
	# Základna
	draw_circle(Vector2.ZERO, 20.0, Color(0.2, 0.2, 0.25))
	draw_circle(Vector2.ZERO, 16.0, Color(0.3, 0.3, 0.35))
	
	# Parabolická anténa
	var antenna_color = Color(0.8, 0.8, 0.9)
	draw_arc(Vector2(10, 0), 18.0, deg_to_rad(90), deg_to_rad(270), 32, antenna_color, 4.0)
	
	# Emitor uprostřed
	draw_circle(Vector2(15, 0), 4.0, Color(0.5, 0.8, 1.0))
