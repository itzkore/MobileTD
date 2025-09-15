extends "res://scripts/Enemy.gd"

func _ready():
	# Juggernaut má specifické statistiky, které přepíší hodnoty z vlny
	max_health = 250
	armor = 20
	speed *= 0.6 # Je o 40% pomalejší než standardní nepřítel ve vlně
	reward_gold = 15
	
	# Zavoláme původní _ready() funkci z Enemy.gd, ale bez nastavení animací
	health = max_health
	add_to_group("enemies")
	z_as_relative = false
	z_index = 200
	last_pos = global_position
	# Nepoužijeme super._ready(), abychom mohli přepsat cestu k animacím
	_setup_juggernaut_animations()
	queue_redraw()
	
	# Vizuální úprava - Juggernaut je větší
	$AnimatedSprite2D.scale = Vector2(2.0, 2.0)

func _setup_juggernaut_animations() -> void:
	var sprite_frames = $AnimatedSprite2D.sprite_frames
	if not sprite_frames:
		sprite_frames = SpriteFrames.new()
		$AnimatedSprite2D.sprite_frames = sprite_frames
	
	sprite_frames.clear_all()
	
	var base_path = "res://assets/enemies/soldier_juggernaut_riot/animations/walk/"

	_create_animation_from_folder(sprite_frames, "walk_down", base_path + "south")
	_create_animation_from_folder(sprite_frames, "walk_left", base_path + "west")
	_create_animation_from_folder(sprite_frames, "walk_up",   base_path + "north")
	_create_animation_from_folder(sprite_frames, "walk_right",base_path + "east")
