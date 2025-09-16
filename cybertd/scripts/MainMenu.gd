extends Control

const SCN_MAIN: PackedScene = preload("res://scenes/Main.tscn")
const SCN_CODEX: PackedScene = preload("res://scenes/Codex.tscn")
const SCN_PROFILE: PackedScene = preload("res://scenes/Profile.tscn")
## MenuStyle is a global class; use it directly

const ENABLE_RADAR := false

@onready var user_lbl: Label = $Header/UserLabel
@onready var gold_lbl: Label = $Header/GoldLabel
@onready var play_btn: Button = $Center/VBox/Play
@onready var codex_btn: Button = $Center/VBox/Codex
@onready var profile_btn: Button = $Center/VBox/Profile
@onready var settings_btn: Button = $Center/VBox/Settings
@onready var quit_btn: Button = $Center/VBox/Quit
@onready var resume_btn: Button = $Center/VBox/Resume

# Layer nodes created at runtime to control z-order cleanly
var _bg_layer: Control
var _overlay_layer: Control


func _ready() -> void:
	# On Android, handle back ourselves to avoid launcher minimize glitches
	if OS.get_name() == "Android":
		get_tree().set_auto_accept_quit(false)
	_ensure_layers()
	_build_background()
	_apply_scale_and_sizes()

	_apply_safe_area()

	_build_military_hud()

	play_btn.pressed.connect(_on_play)
	if is_instance_valid(resume_btn):
		resume_btn.pressed.connect(_on_resume)
	codex_btn.pressed.connect(_on_codex)
	profile_btn.pressed.connect(_on_profile)
	if is_instance_valid(settings_btn):
		settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	_refresh_header()

	# Show/hide Resume depending on last_run
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if is_instance_valid(resume_btn):
		var can_resume := false
		if saver and saver.has_method("get_last_run"):
			var last = saver.get_last_run()
			can_resume = int(last.get("wave", 0)) > 0 and int(last.get("lives", 0)) > 0
		resume_btn.visible = can_resume

	# Ask before continuing last run: if snapshot exists, show a confirmation dialog instead of auto-resuming
	if saver and saver.has_method("get_last_run") and saver.has_method("load_snapshot"):
		var last: Dictionary = saver.get_last_run()
		var snap: Dictionary = saver.load_snapshot()
		var can_resume_any := int(last.get("wave", 0)) > 0 and int(last.get("lives", 0)) > 0 and not snap.is_empty()
		if can_resume_any:
			call_deferred("_prompt_resume_dialog", last)
		else:
			_animate_menu_in()
			_wire_micro_animations()
	set_process(true)
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_safe_area()
		_apply_scale_and_sizes()
		_apply_responsive_layout()

func _apply_scale_and_sizes() -> void:
	var scaler = get_tree().root.get_node_or_null("UIScaler")
	var sf: float = 1.0
	if scaler and scaler.has_method("apply_to"):
		scaler.apply_to(self)
		if "scale_factor" in scaler:
			sf = float(scaler.scale_factor)
	var win: Vector2i = DisplayServer.window_get_size()
	var compact: bool = win.x < 1200
	var base_font: float = 24.0 if compact else 28.0
	var btn_font: int = int(base_font * max(1.0, sf))
	var min_size: Vector2 = Vector2(260, 72) if compact else Vector2(320, 88)
	# Apply shared style
	if Engine.has_singleton("MenuStyle"):
		pass
	for b in [play_btn, codex_btn, profile_btn, settings_btn, quit_btn, resume_btn]:
		if b:
			MenuStyle.style_button(b, btn_font, min_size)
	if user_lbl:
		MenuStyle.style_label(user_lbl, int(20 * max(1.0, sf)))
	if gold_lbl:
		MenuStyle.style_label(gold_lbl, int(20 * max(1.0, sf)))

func _apply_safe_area() -> void:
	if OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS":
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var win: Vector2i = DisplayServer.window_get_size()
		var margin := 24
		var safe_valid := safe.size.x > 0 and safe.size.y > 0 and safe.size.x <= win.x and safe.size.y <= win.y
		var left_inset: int = 0
		var top_inset: int = 0
		var right_inset: int = 0
		var bottom_inset: int = 0
		if safe_valid:
			left_inset = safe.position.x
			top_inset = safe.position.y
			right_inset = max(0, win.x - (safe.position.x + safe.size.x))
			bottom_inset = max(0, win.y - (safe.position.y + safe.size.y))
		var c := get_node_or_null("Center")
		if c and c is Control:
			var cc := c as Control
			cc.offset_left = float(max(margin, left_inset))
			cc.offset_top = float(max(margin, top_inset))
			cc.offset_right = -float(max(margin, right_inset))
			cc.offset_bottom = -float(max(margin, bottom_inset))

func _ensure_layers() -> void:
	# Background layer (bottom)
	_bg_layer = get_node_or_null("BackgroundLayer")
	if not _bg_layer:
		_bg_layer = Control.new()
		_bg_layer.name = "BackgroundLayer"
		_bg_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_bg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bg_layer)
		move_child(_bg_layer, 0)
	# Overlay layer (top)
	_overlay_layer = get_node_or_null("OverlayLayer")
	if not _overlay_layer:
		_overlay_layer = Control.new()
		_overlay_layer.name = "OverlayLayer"
		_overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_overlay_layer)
		# Place between background (0) and existing UI nodes to avoid covering buttons visually
		move_child(_overlay_layer, 1)

func _build_background() -> void:
	if _bg_layer.get_node_or_null("AnimatedBackground"):
		return
	var bg := ColorRect.new()
	bg.name = "AnimatedBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Military dark olive background
	bg.color = Color(0.08, 0.10, 0.08, 1.0)
	_bg_layer.add_child(bg)
	var t := bg.create_tween().set_loops()
	t.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(bg, "modulate", Color(1,1,1,1), 3.0)
	t.tween_property(bg, "modulate", Color(0.96,0.98,1,1), 3.0)

	# Optional: lightweight overlays below (disable on Android to avoid rare driver crashes on press-triggered redraw)
	var is_android := OS.has_feature("Android") or OS.get_name() == "Android"
	if is_android:
		return

	# Tactical grid overlay (military vibe)
	var grid := ColorRect.new()
	grid.name = "Grid"
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grid_shader := Shader.new()
	grid_shader.code = """
	shader_type canvas_item;
	uniform float scale = 48.0; // grid size in px
	uniform float line = 0.012; // line thickness
	uniform vec4 color : source_color = vec4(0.5, 0.8, 0.3, 0.08);
	void fragment() {
		vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE; // pixels
		uv /= scale;
		vec2 g = fract(uv);
		float l = step(1.0 - line, g.x) + step(1.0 - line, g.y);
		l = clamp(l, 0.0, 1.0);
		COLOR = vec4(color.rgb, color.a * l);
	}
	"""
	var grid_mat := ShaderMaterial.new()
	grid_mat.shader = grid_shader
	grid.material = grid_mat
	_bg_layer.add_child(grid)

	# Scanlines overlay (very subtle)
	var scan := ColorRect.new()
	scan.name = "Scanlines"
	scan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scan_shader := Shader.new()
	scan_shader.code = """
	shader_type canvas_item;
	uniform float intensity = 0.06;
	uniform float density = 160.0;
	uniform float speed = 0.15;
	void fragment() {
		vec2 suv = SCREEN_UV;
		float f = fract(suv.y * density + TIME * speed);
		float a = smoothstep(0.0, 0.015, f) * smoothstep(1.0, 0.985, f) * intensity;
		COLOR = vec4(1.0, 1.0, 1.0, a);
	}
	"""
	var scan_mat := ShaderMaterial.new()
	scan_mat.shader = scan_shader
	scan.material = scan_mat
	_bg_layer.add_child(scan)

	# Diagonal sweeping highlight across screen
	var sweep := ColorRect.new()
	sweep.name = "Sweep"
	sweep.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sweep_shader := Shader.new()
	sweep_shader.code = """
	shader_type canvas_item;
	uniform float width = 0.16;
	uniform float speed = 0.05;
	uniform vec4 color : source_color = vec4(0.5, 0.9, 0.3, 0.06);
	void fragment() {
		vec2 uv = SCREEN_UV;
		float d = fract((uv.x + uv.y) * 0.5 + TIME * speed);
		float band = smoothstep(0.0, width, d) * (1.0 - smoothstep(1.0 - width, 1.0, d));
		COLOR = vec4(color.rgb, color.a * band);
	}
	"""
	var sweep_mat := ShaderMaterial.new()
	sweep_mat.shader = sweep_shader
	sweep.material = sweep_mat
	_bg_layer.add_child(sweep)

func _animate_menu_in() -> void:
	var items: Array = []
	var header := get_node_or_null("Header")
	if header: items.append(header)
	for b in [resume_btn, play_btn, codex_btn, profile_btn, settings_btn, quit_btn]:
		if b and b.visible: items.append(b)
	MenuStyle.fade_scale_in(items, 0.06, 0.2)

func _wire_micro_animations() -> void:
	for b in [resume_btn, play_btn, codex_btn, profile_btn, settings_btn, quit_btn]:
		if not b: continue
		b.mouse_entered.connect(func(): MenuStyle.micro_bump(b))
		b.pressed.connect(func(): MenuStyle.micro_bump(b, 0.05, 0.09))

func _prompt_resume_dialog(last: Dictionary) -> void:
	# Minimal two-option dialog: Continue or New Game
	var dlg := ConfirmationDialog.new()
	dlg.title = "Pokračovat v rozehrané hře?"
	var wave := int(last.get("wave", 0))
	var lives := int(last.get("lives", 0))
	dlg.dialog_text = "Nalezena rozehraná hra (vlna %d, životy %d). Chceš pokračovat, nebo začít novou?" % [wave, lives]
	# Repurpose OK as Continue and Cancel as New Game
	dlg.get_ok_button().text = "Pokračovat"
	dlg.get_cancel_button().text = "Nová hra"
	dlg.exclusive = true
	dlg.confirmed.connect(func():
		_on_resume()
	)
	dlg.canceled.connect(func():
		_animate_menu_in()
		_wire_micro_animations()
	)
	add_child(dlg)
	dlg.popup_centered()

func _refresh_header() -> void:
	var g = get_tree().root.get_node_or_null("Game")
	if not g:
		return
	var provider: String = "guest"
	if g.auth and g.auth.provider:
		provider = String(g.auth.provider)
	user_lbl.text = "User: %s" % ("Guest" if provider == "guest" else "Google")
	gold_lbl.text = "Gold: %d" % int(g.profile.get("gold", 0))

func _on_play() -> void:
	# Give quick visual feedback and switch scenes using deferred call (Android-safe)
	if is_instance_valid(play_btn):
		play_btn.disabled = true
		play_btn.text = "Loading..."
	get_tree().call_deferred("change_scene_to_packed", SCN_MAIN)

func _on_resume() -> void:
	var saver = get_tree().root.get_node_or_null("SaveGame")
	if saver and saver.has_method("request_resume"):
		saver.request_resume()
	# Defer play to outside of input handling
	call_deferred("_on_play")

func _on_codex() -> void:
	if is_instance_valid(codex_btn):
		codex_btn.disabled = true
		codex_btn.text = "Loading..."
	get_tree().call_deferred("change_scene_to_packed", SCN_CODEX)

func _on_profile() -> void:
	if is_instance_valid(profile_btn):
		profile_btn.disabled = true
		profile_btn.text = "Loading..."
	get_tree().call_deferred("change_scene_to_packed", SCN_PROFILE)

func _on_settings() -> void:
	var scn := load("res://scenes/Settings.tscn") as PackedScene
	if scn:
		var inst := scn.instantiate()
		add_child(inst)
		if inst.has_method("open_modal"):
			inst.call_deferred("open_modal")

func _on_quit() -> void:
	get_tree().quit()

# --- Military HUD overlay (radar + status) ---
var _hud_time_lbl: Label
var _hud_status_lbl: Label
var _hud_radar: Control

func _build_military_hud() -> void:
	if _overlay_layer.get_node_or_null("MilHUD"):
		return
	var hud := Control.new()
	hud.name = "MilHUD"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(hud)

	# Small status label (top-left)
	_hud_status_lbl = Label.new()
	_hud_status_lbl.text = "RADAR ONLINE  •  SECTOR A-3"
	_hud_status_lbl.modulate = Color(1,1,1,0.7)
	_hud_status_lbl.position = Vector2(16, 12)
	hud.add_child(_hud_status_lbl)
	MenuStyle.style_label(_hud_status_lbl, 16)

	# Clock label (top-right)
	_hud_time_lbl = Label.new()
	_hud_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_time_lbl.anchor_right = 1.0
	_hud_time_lbl.offset_right = -16
	_hud_time_lbl.anchor_left = 0.5
	_hud_time_lbl.offset_left = 0
	_hud_time_lbl.text = _format_time()
	_hud_time_lbl.modulate = Color(1,1,1,0.7)
	hud.add_child(_hud_time_lbl)
	MenuStyle.style_label(_hud_time_lbl, 16)

	# Radar widget (top-right, under time)
	var win := DisplayServer.window_get_size()
	var small := win.x < 1200
	var rsize := Vector2(140, 140) if small else Vector2(160, 160)
	if ENABLE_RADAR:
		var radar := ColorRect.new()
		radar.name = "Radar"
		_hud_radar = radar
		radar.custom_minimum_size = rsize
		radar.size = rsize
		radar.anchor_right = 1.0
		radar.anchor_top = 0.0
		radar.anchor_left = 1.0
		radar.anchor_bottom = 0.0
		radar.offset_right = -16
		radar.offset_top = 40
		radar.offset_left = -16 - rsize.x
		radar.offset_bottom = radar.offset_top + rsize.y
		radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Radar shader disabled for now (stability). Re-enable when finalized.
		hud.add_child(radar)
	else:
		# Placeholder panel to reserve space (no shader)
		var panel := Panel.new()
		panel.name = "RadarPlaceholder"
		_hud_radar = panel
		panel.custom_minimum_size = rsize
		panel.size = rsize
		panel.anchor_right = 1.0
		panel.anchor_top = 0.0
		panel.anchor_left = 1.0
		panel.anchor_bottom = 0.0
		panel.offset_right = -16
		panel.offset_top = 40
		panel.offset_left = -16 - rsize.x
		panel.offset_bottom = panel.offset_top + rsize.y
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.10, 0.08, 0.8)
		sb.border_color = Color(0.60, 0.85, 0.35, 0.5)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(80)
		panel.add_theme_stylebox_override("panel", sb)
		hud.add_child(panel)

	_apply_responsive_layout()

func _process(_dt: float) -> void:
	if _hud_time_lbl:
		# Update once per ~0.25s without heavy cost
		var now := _format_time()
		if _hud_time_lbl.text != now:
			_hud_time_lbl.text = now

 

func _format_time() -> String:
	# Example: 2025-09-16 13:05:42 -> display HH:MM:SS Z
	var full := Time.get_datetime_string_from_system(true)
	var s := full
	if full.length() >= 19:
		s = full.substr(11, 8) + " Z"
	return "LOCAL TIME  " + s

func _apply_responsive_layout() -> void:
	# Ensure HUD elements don’t overlap menu. Shrink radar on narrow screens.
	var win := DisplayServer.window_get_size()
	var small := win.x < 1200
	if _hud_radar and is_instance_valid(_hud_radar):
		var rsize := Vector2(120, 120) if win.x < 900 else (Vector2(140, 140) if small else Vector2(160, 160))
		_hud_radar.custom_minimum_size = rsize
		_hud_radar.size = rsize
		_hud_radar.offset_left = -16 - rsize.x
		_hud_radar.offset_bottom = _hud_radar.offset_top + rsize.y
	# Header font size tightening on small
	if user_lbl:
		MenuStyle.style_label(user_lbl, 16 if small else 20)
	if gold_lbl:
		MenuStyle.style_label(gold_lbl, 16 if small else 20)
