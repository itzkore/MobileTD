extends PanelContainer

signal build_choice(tower_type: String)
signal upgrade_damage()
signal sell_requested()

@onready var title: Label = $VBoxContainer/Title
@onready var build_content: VBoxContainer = $VBoxContainer/Content/BuildContent
@onready var tower_content: VBoxContainer = $VBoxContainer/Content/TowerContent
@onready var stats_label: Label = $VBoxContainer/Content/TowerContent/StatsLabel
@onready var upgrade_button: Button = $VBoxContainer/Content/TowerContent/UpgradeButton
@onready var sell_button: Button = $VBoxContainer/Content/TowerContent/SellButton

const TOWER_CARD_SCENE = preload("res://scenes/ui/TowerCard.tscn")
const PANEL_WIDTH = 220.0
const ANIM_SPEED = 0.3

var is_open: bool = false

func _ready() -> void:
	# Začínáme mimo obrazovku
	position.x = get_viewport_rect().size.x
	upgrade_button.pressed.connect(func(): upgrade_damage.emit())
	sell_button.pressed.connect(func(): sell_requested.emit())

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
	var target_x = get_viewport_rect().size.x - (PANEL_WIDTH + 20) if p_show else get_viewport_rect().size.x
	
	tween.tween_property(self, "position:x", target_x, ANIM_SPEED)
