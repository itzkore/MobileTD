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
const PANEL_WIDTH = 220.0
const ANIM_SPEED = 0.3

var is_open: bool = false

func _ready() -> void:
	# Initialize hidden state (off-screen to the right):
	# For right-anchored controls, visible uses negative right offset (margin),
	# hidden uses +width (right edge PANEL_WIDTH px to the right of viewport),
	# and left offset keeps width.
	_set_panel_offsets(PANEL_WIDTH)
	upgrade_button.pressed.connect(func(): upgrade_damage.emit())
	sell_button.pressed.connect(func(): sell_requested.emit())

func _set_panel_offsets(right_offset: float) -> void:
	# For right-anchored control (anchor_left=anchor_right=1):
	# pos_right = parent_width + offset_right
	# Visible: offset_right = -20 (panel margin 20px from right), offset_left = -20 - width
	# Hidden:  offset_right = 0   (panel fully off to the right),  offset_left = width
	offset_right = right_offset
	offset_left = right_offset - PANEL_WIDTH

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

func _animate_panel(p_show: bool) -> void: # Přejmenováno z 'show'
	if p_show == is_open:
		return
		
	is_open = p_show
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target_right := -20.0 if p_show else PANEL_WIDTH
	var target_left := target_right - PANEL_WIDTH
	# Animate both offsets in parallel for a proper slide
	tween.tween_property(self, "offset_right", target_right, ANIM_SPEED)
	tween.parallel().tween_property(self, "offset_left", target_left, ANIM_SPEED)
