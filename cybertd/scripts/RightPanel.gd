extends PanelContainer

signal build_choice(tower_type: String)
signal upgrade_damage()
signal sell_requested()

@onready var title: Label = $VBoxContainer/Title
@onready var build_content: VBoxContainer = $VBoxContainer/Scroll/Content/BuildContent
@onready var tower_content: VBoxContainer = $VBoxContainer/Scroll/Content/TowerContent
@onready var stats_label: Label = $VBoxContainer/Scroll/Content/TowerContent/StatsLabel
@onready var upgrade_button: Button = $VBoxContainer/Scroll/Content/TowerContent/UpgradeButton
@onready var sell_button: Button = $VBoxContainer/Scroll/Content/TowerContent/SellButton

const TOWER_CARD_SCENE = preload("res://scenes/ui/TowerCard.tscn")
const MIN_PANEL_WIDTH := 240.0
const RIGHT_MARGIN := 20.0
const ANIM_SPEED := 0.3

var is_open: bool = false
var scrim: ColorRect

func _ready() -> void:
	# Apply UIScaler for consistent sizing
	var scaler = get_tree().root.get_node_or_null("UIScaler")
	if scaler and scaler.has_method("apply_to"):
		scaler.apply_to(self)
		if "scale_factor" in scaler:
			var sf: float = scaler.scale_factor
			# Expand panel based on scale for comfortable layout
			set_deferred("custom_minimum_size", Vector2(MIN_PANEL_WIDTH * sf + 40.0, 0))

	# Ensure scrim exists under the same parent to catch click-away
	var parent_ctrl := get_parent() as Control
	scrim = get_node_or_null("../RightPanelScrim")
	if not scrim and parent_ctrl:
		scrim = ColorRect.new()
		scrim.name = "RightPanelScrim"
		scrim.color = Color(0, 0, 0, 0.20)
		scrim.mouse_filter = Control.MOUSE_FILTER_STOP
		scrim.visible = false
		parent_ctrl.add_child(scrim)
		# Make scrim cover full screen, behind the panel
		scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
		scrim.z_index = max(0, z_index - 1)
		parent_ctrl.move_child(scrim, max(0, parent_ctrl.get_children().find(self) - 1))
	if scrim and not scrim.gui_input.is_connected(_on_scrim_input):
		scrim.gui_input.connect(_on_scrim_input)

	# Defer hidden placement until layout is resolved so width is valid
	call_deferred("_init_hidden")
	
	upgrade_button.pressed.connect(func(): upgrade_damage.emit())
	sell_button.pressed.connect(func(): sell_requested.emit())

func _init_hidden() -> void:
	var w := _panel_width()
	_apply_offsets(w, w) # hidden: right_offset = w, left = w - w = 0

func _apply_offsets(right_offset: float, width: float) -> void:
	offset_right = right_offset
	offset_left = right_offset - width

func open_build(p_tower_data: Dictionary) -> void:
	title.text = "Build Tower"
	build_content.visible = true
	tower_content.visible = false
	
	# Vyčistíme staré karty
	for child in build_content.get_children():
		child.queue_free()
		
	# Vytvoříme nové karty z poskytnutých dat
	for type in p_tower_data:
		var card_data = p_tower_data[type]
		
		var card = TOWER_CARD_SCENE.instantiate()
		build_content.add_child(card)
		card.set_data(type, card_data)
		card.selected.connect(func(tower_type): build_choice.emit(tower_type))
		
	_animate_panel(true)

func open_tower(stats: Dictionary) -> void:
	title.text = "Tower LVL %d" % stats.get("level", 1)
	build_content.visible = false
	tower_content.visible = true
	
	var text := "Damage: %d\nRate: %.2f/s\nRange: %.0f\nTurn: %.0f deg/s\nSplash: %.0f" % [
		int(stats.get("damage",0)),
		float(1.0/max(0.001, float(stats.get("cooldown",1.0)))),
		float(stats.get("range",0.0)),
		float(stats.get("turn_rate", 0.0)),
		float(stats.get("splash",0.0))
	]
	stats_label.text = text
	
	_animate_panel(true)

func set_upgrade_state(cost: int, can_upgrade: bool) -> void:
	upgrade_button.text = "Upgrade (%d G)" % cost
	upgrade_button.disabled = not can_upgrade

func close_panel() -> void:
	_animate_panel(false)


func _panel_width() -> float:
	# Determine actual width at runtime; fall back to minimum
	var w := size.x
	if w <= 1.0:
		w = get_combined_minimum_size().x
	if w <= 1.0:
		w = custom_minimum_size.x
	if w <= 1.0:
		w = MIN_PANEL_WIDTH
	return max(w, MIN_PANEL_WIDTH)

func _animate_panel(p_show: bool) -> void:
	if p_show == is_open:
		return
		
	is_open = p_show
	var w := _panel_width()
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target_right := -RIGHT_MARGIN if p_show else w
	var target_left := target_right - w
	# Animate both offsets in parallel for a proper slide
	tween.tween_property(self, "offset_right", target_right, ANIM_SPEED)
	tween.parallel().tween_property(self, "offset_left", target_left, ANIM_SPEED)

	# Toggle scrim visibility to allow click-away to close
	if is_instance_valid(scrim):
		scrim.visible = p_show
		if p_show:
			scrim.set_deferred("mouse_filter", Control.MOUSE_FILTER_STOP)
		else:
			scrim.set_deferred("mouse_filter", Control.MOUSE_FILTER_IGNORE)

func _on_scrim_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventMouseButton and event.pressed:
		close_panel()
	elif event is InputEventScreenTouch and event.pressed:
		close_panel()
