extends Node
class_name MenuStyle

const COL_BG_A := Color(0.07, 0.09, 0.07, 1.0)   # deep olive black
const COL_BG_B := Color(0.10, 0.14, 0.10, 1.0)   # dark olive
const COL_ACC  := Color(0.60, 0.85, 0.35, 1.0)   # military lime
const COL_TEXT := Color(0.90, 0.97, 0.90, 1.0)   # warm off-white with green tint

const BTN_RADIUS := 10
const BTN_PAD := Vector2(20, 14)

static func style_button(b: Button, font_size: int, min_size: Vector2) -> void:
	if not b:
		return
	b.add_theme_color_override("font_color", COL_TEXT)
	b.add_theme_color_override("font_hover_color", COL_TEXT)
	b.add_theme_color_override("font_pressed_color", COL_TEXT)
	b.add_theme_color_override("font_focus_color", COL_TEXT)
	b.add_theme_constant_override("outline_size", 0)
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_BG_B.darkened(0.08)
	sb.corner_radius_top_left = BTN_RADIUS
	sb.corner_radius_top_right = BTN_RADIUS
	sb.corner_radius_bottom_left = BTN_RADIUS
	sb.corner_radius_bottom_right = BTN_RADIUS
	sb.content_margin_left = BTN_PAD.x
	sb.content_margin_right = BTN_PAD.x
	sb.content_margin_top = BTN_PAD.y
	sb.content_margin_bottom = BTN_PAD.y
	# Subtle border to evoke tactical UI
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(COL_ACC.r, COL_ACC.g, COL_ACC.b, 0.25)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = COL_BG_B.lightened(0.05)
	sbh.border_color = Color(COL_ACC.r, COL_ACC.g, COL_ACC.b, 0.35)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = COL_BG_B.lightened(0.10)
	sbp.border_color = Color(COL_ACC.r, COL_ACC.g, COL_ACC.b, 0.45)
	b.add_theme_stylebox_override("pressed", sbp)
	var sbd := sb.duplicate() as StyleBoxFlat
	sbd.bg_color = COL_BG_B.darkened(0.18)
	sbd.border_color = Color(COL_ACC.r, COL_ACC.g, COL_ACC.b, 0.15)
	b.add_theme_stylebox_override("disabled", sbd)

static func style_label(l: Label, font_size: int) -> void:
	if not l:
		return
	l.add_theme_color_override("font_color", COL_TEXT)
	l.add_theme_font_size_override("font_size", font_size)

static func micro_bump(ctrl: Control, strength := 0.035, dur := 0.08) -> void:
	if not ctrl:
		return
	var t := ctrl.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if OS.has_feature("Android"):
		# On Android devices avoid scaling on press (crash-prone on some GPUs). Do alpha pulse.
		var orig := ctrl.modulate
		t.tween_property(ctrl, "modulate", Color(orig.r, orig.g, orig.b, 0.85), dur)
		t.tween_interval(0.02)
		t.tween_property(ctrl, "modulate", orig, dur)
	else:
		t.tween_property(ctrl, "scale", Vector2(1.0 + strength, 1.0 + strength), dur)
		t.tween_interval(0.02)
		t.tween_property(ctrl, "scale", Vector2.ONE, dur)

static func fade_scale_in(ctrls: Array, delay_step := 0.05, dur := 0.18) -> void:
	var base := 0.0
	for c in ctrls:
		if not (c and c is CanvasItem):
			continue
		var ci := c as CanvasItem
		ci.modulate.a = 0.0
		if not OS.has_feature("Android"):
			(c as Control).scale = Vector2(0.98, 0.98)
		var t := ci.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.set_parallel(false)
		t.tween_interval(base)
		t.tween_property(ci, "modulate:a", 1.0, dur)
		if not OS.has_feature("Android"):
			t.tween_property((ci as Control), "scale", Vector2.ONE, dur)
		base += delay_step
