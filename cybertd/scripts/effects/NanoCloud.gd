extends Node2D

@export var dot_count: int = 28
@export var base_radius: float = 18.0
@export var color_base: Color = Color(0.75, 0.78, 0.82, 0.7) # grey
@export var color_glow: Color = Color(0.85, 0.9, 1.0, 0.18)
@export var flicker_colors: Array[Color] = [
	Color(0.2, 0.8, 1.0, 0.9), # cyan
	Color(0.9, 0.3, 1.0, 0.9), # violet
	Color(0.3, 1.0, 0.6, 0.9), # mint
	Color(1.0, 0.6, 0.2, 0.9)  # orange
]
@export var rotation_speed: float = 2.2
@export var jitter: float = 7.0
@export var intensity: float = 0.0 # 0..1 visual strength
@export var attach_offset: Vector2 = Vector2(0, -12)
@export var flicker_rate: float = 9.0

var _angles: Array[float] = []
var _speed_mul: Array[float] = []
var _phase: Array[float] = []
var _burst_t: float = 0.0
var _fading: bool = false
@export var fade_speed: float = 2.5
var _t: float = 0.0

# travel support
var _fly_target: Node2D
var _fly_time: float = 0.0
var _fly_elapsed: float = 0.0
var _on_fly_done: Callable

func _ready() -> void:
	set_process(true)
	randomize()
	_angles.resize(dot_count)
	_speed_mul.resize(dot_count)
	_phase.resize(dot_count)
	for i in dot_count:
		_angles[i] = randf() * TAU
		_speed_mul[i] = 0.6 + randf() * 1.2 # různá rychlost částic
		_phase[i] = randf() * TAU
	z_as_relative = false
	z_index = 350

func set_intensity(v: float) -> void:
	intensity = clamp(v, 0.0, 1.5)
	queue_redraw()

func burst() -> void:
	_burst_t = 0.4 # seconds of ripple

func fade_out() -> void:
	_fading = true

func cancel_fade() -> void:
	_fading = false

func start_fly_to(target: Node2D, duration: float, on_done: Callable = Callable()) -> void:
	_fly_target = target
	_fly_time = max(0.05, duration)
	_fly_elapsed = 0.0
	_on_fly_done = on_done
	top_level = true # keep global transform independent during flight

func _process(delta: float) -> void:
	_t += delta
	# travel update
	if _fly_target and is_instance_valid(_fly_target) and _fly_elapsed < _fly_time:
		_fly_elapsed += delta
		var t: float = clamp(_fly_elapsed / _fly_time, 0.0, 1.0)
		# ease
		var tt: float = 1.0 - pow(1.0 - t, 3.0)
		var target_pos: Vector2 = _fly_target.global_position + attach_offset
		global_position = global_position.lerp(target_pos, tt)
		if _fly_elapsed >= _fly_time:
			# finish
			if _on_fly_done.is_valid():
				_on_fly_done.call()
			_fly_target = null
			top_level = false
	
	var spd: float = rotation_speed * (0.6 + intensity * 0.8)
	for i in _angles.size():
		_angles[i] = fposmod(_angles[i] + (spd * _speed_mul[i]) * delta, TAU)
	if _burst_t > 0.0:
		_burst_t = max(0.0, _burst_t - delta)
	if _fading:
		intensity = max(0.0, intensity - fade_speed * delta)
		if intensity <= 0.0 and _burst_t <= 0.0:
			queue_free()
	if Engine.get_frames_drawn() % 2 == 0:
		queue_redraw()

func _draw() -> void:
	if dot_count <= 0:
		return
	var r: float = base_radius * (0.8 + intensity * 0.6)
	# soft halo
	draw_circle(Vector2.ZERO, r + 6.0, color_glow)
	# dots
	var sz: float = 1.3 + 1.2 * intensity
	# determine flicker subset stable within a frame tick
	var flicker_idx: int = int(floor(_t * flicker_rate))
	var accent_col: Color = flicker_colors[flicker_idx % flicker_colors.size()] if flicker_colors.size() > 0 else color_base
	var accent_stride: int = max(3, int(ceil(10.0 - 8.0 * intensity))) # více akcentů při vyšší intenzitě
	for i in dot_count:
		var a: float = _angles[i]
		var rr: float = r + randf_range(-jitter, jitter)
		# přidej chaotický offset na základě času a fáze částice
		var chaos: float = sin(_t * 5.3 + _phase[i]) * jitter * 0.6 + cos(_t * 3.7 + _phase[i] * 1.7) * jitter * 0.4
		var p: Vector2 = Vector2.RIGHT.rotated(a) * (rr + chaos)
		var col: Color = color_base
		if (i + flicker_idx) % accent_stride == 0:
			col = accent_col
		draw_circle(p, sz, col)
	# ripple burst
	if _burst_t > 0.0:
		var t: float = _burst_t / 0.4
		var rr2: float = r + (1.0 - t) * 20.0
		var col: Color = Color(1.0, 1.0, 1.0, 0.18 * t)
		draw_arc(Vector2.ZERO, rr2, 0.0, TAU, 48, col, 3.0)
