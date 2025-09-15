extends Node2D
class_name SoldierVisual

@export var body_color: Color = Color(0.15, 0.75, 0.65)
@export var helmet_color: Color = Color(0.08, 0.55, 0.5)
@export var accent_color: Color = Color(0.05, 0.35, 0.32)
@export var scale_factor: float = 1.0
@export var speed_anim: float = 3.0

var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta * speed_anim
	queue_redraw()

func _draw() -> void:
	var s: float = 10.0 * scale_factor
	# Subtle vertical bob to feel like walking
	var bob: float = sin(_t * 0.8) * 1.2
	# Ground shadow
	draw_circle(Vector2(0, s*0.9 + 1.5), s*0.6, Color(0, 0, 0, 0.15))
	# Body: rounded capsule
	var body_h: float = s * 1.6
	var body_w: float = s * 0.9
	var body_top := Vector2(0, -body_h * 0.5 + bob)
	var body_bot := Vector2(0, body_h * 0.5 + bob)
	draw_circle(body_top, body_w * 0.5, body_color)
	draw_circle(body_bot, body_w * 0.5, body_color)
	draw_rect(Rect2(Vector2(-body_w * 0.5, body_top.y), Vector2(body_w, body_h)), body_color)
	# Helmet band
	var helm_y := body_top.y - s * 0.4
	draw_rect(Rect2(Vector2(-body_w * 0.55, helm_y), Vector2(body_w * 1.1, s * 0.25)), helmet_color)
	# Minimal stride hint (knees)
	var stride: float = sin(_t) * (s * 0.25)
	draw_rect(Rect2(Vector2(-body_w * 0.4, body_bot.y - s*0.2 + stride), Vector2(body_w*0.25, s*0.15)), accent_color)
	draw_rect(Rect2(Vector2(body_w * 0.15, body_bot.y - s*0.2 - stride), Vector2(body_w*0.25, s*0.15)), accent_color)
