extends PathFollow2D

signal escaped
signal died

@export var speed: float = 120.0
@export var max_health: int = 10
@export var armor: int = 0
@export var reward_gold: int = 2
@export var damage_taken_mult: float = 1.0
var health: int
signal damaged(amount: int)

const DebuffClass = preload("res://scripts/effects/Debuff.gd")

var last_pos: Vector2 = Vector2.ZERO
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var debuffs: Array = []
var _dot_accum: float = 0.0 # accumulates fractional DOT damage until it reaches 1

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	z_as_relative = false
	z_index = 200
	last_pos = global_position
	_setup_animations()
	queue_redraw()

func _process(delta: float) -> void:
	var speed_modifier = 1.0
	
	for i in range(debuffs.size() - 1, -1, -1):
		var debuff = debuffs[i]
		if debuff.process_debuff(delta):
			debuff.on_remove()
			debuffs.remove_at(i)
		
		if "speed_multiplier" in debuff:
			speed_modifier *= debuff.speed_multiplier

	progress += (speed * speed_modifier) * delta
	if progress_ratio >= 1.0:
		escaped.emit()
		queue_free()
		return
	
	_update_animation()
	
	if Engine.get_frames_drawn() % 2 == 0:
		queue_redraw()

func _update_animation() -> void:
	var current_pos = global_position
	if current_pos.is_equal_approx(last_pos):
		return
		
	var direction = (current_pos - last_pos).normalized()
	last_pos = current_pos

	var angle = fmod(rad_to_deg(direction.angle()) + 360, 360)
	
	if angle > 45 and angle <= 135:
		animated_sprite.play("walk_down")
	elif angle > 135 and angle <= 225:
		animated_sprite.play("walk_left")
	elif angle > 225 and angle <= 315:
		animated_sprite.play("walk_up")
	else:
		animated_sprite.play("walk_right")

func get_visual_canvasitem() -> CanvasItem:
	# Returns the drawable node used for visuals (for shaders/effects)
	return animated_sprite

func add_debuff(debuff) -> void:
	for d in debuffs:
		if d.get_script() == debuff.get_script():
			d.time_elapsed = 0
			return
	debuffs.append(debuff)
	if debuff and debuff.has_method("on_added"):
		debuff.on_added()

func _setup_animations() -> void:
	var sprite_frames = animated_sprite.sprite_frames
	if not sprite_frames:
		sprite_frames = SpriteFrames.new()
		animated_sprite.sprite_frames = sprite_frames
	
	sprite_frames.clear_all()
	
	var base_path = "res://assets/enemies/realistic_soldier_2025_warfare/animations/walk/"

	_create_animation_from_folder(sprite_frames, "walk_down", base_path + "south")
	_create_animation_from_folder(sprite_frames, "walk_left", base_path + "west")
	_create_animation_from_folder(sprite_frames, "walk_up",   base_path + "north")
	_create_animation_from_folder(sprite_frames, "walk_right",base_path + "east")

func _create_animation_from_folder(sprite_frames: SpriteFrames, anim_name: String, folder_path: String) -> void:
	# Avoid directory listing on exported PCK (Android). Instead, enumerate
	# sequentially named frames: frame_000.png, frame_001.png, ... until missing.
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_loop(anim_name, true)
	sprite_frames.set_animation_speed(anim_name, 7.2)

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
		push_error("Animation Error: No frames found for '%s' in %s" % [anim_name, folder_path])

func take_damage(dmg: int) -> void:
	var mod_amount: int = int(max(1.0, round(float(dmg) * max(0.0, damage_taken_mult))))
	health -= mod_amount
	damaged.emit(mod_amount)
	if health <= 0:
		died.emit()
		queue_free()
	else:
		queue_redraw()

# Applies damage-over-time without emitting the 'damaged' signal, and
# safely accumulates fractional values across frames.
func take_damage_silent(dmg: float) -> void:
	if dmg <= 0.0:
		return
	_dot_accum += max(0.0, dmg) * max(0.0, damage_taken_mult)
	var whole: int = int(floor(_dot_accum))
	if whole >= 1:
		health -= whole
		_dot_accum -= float(whole)
		if health <= 0:
			died.emit()
			queue_free()
			return
		queue_redraw()

func reset_on_spawn(base_speed: float) -> void:
	speed = base_speed
	progress = 0.0

func _draw() -> void:
	if max_health <= 0:
		return
	var w := 30.0
	var h := 6.0
	var y := -46.0
	var ratio: float = clamp(float(health) / float(max_health), 0.0, 1.0)
	# subtle border for clarity
	draw_rect(Rect2(Vector2(-w * 0.5 - 1, y - 1), Vector2(w + 2, h + 2)), Color(0, 0, 0, 0.35))
	# background
	draw_rect(Rect2(Vector2(-w * 0.5, y), Vector2(w, h)), Color(0, 0, 0, 0.7))
	# fill
	draw_rect(Rect2(Vector2(-w * 0.5 + 1, y + 1), Vector2((w - 2) * ratio, h - 2)), Color(0.2, 1.0, 0.2, 1.0))
