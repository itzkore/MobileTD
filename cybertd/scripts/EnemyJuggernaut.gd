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

func _create_animation_from_folder(sprite_frames: SpriteFrames, anim_name: String, folder_path: String) -> void:
	# Reuse the same Android-friendly loader used in Enemy.gd: enumerate frame_XXX.png
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_loop(anim_name, true)
	sprite_frames.set_animation_speed(anim_name, 6.5)

	var index := 0
	var added := 0
	while true:
		var fname := "frame_%03d.png" % index
		var res_path := folder_path.path_join(fname)
		if ResourceLoader.exists(res_path):
			var texture := load(res_path)
			if texture:
				sprite_frames.add_frame(anim_name, texture)
				added += 1
			index += 1
		else:
			break

	if added == 0:
		push_error("Juggernaut Animation Error: No frames for '%s' in %s" % [anim_name, folder_path])
