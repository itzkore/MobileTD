extends PanelContainer

signal selected(tower_type: String)

@onready var preview: Control = $HBoxContainer/TowerPreview
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var cost_label: Label = $HBoxContainer/VBoxContainer/CostLabel
@onready var stats_label: Label = $HBoxContainer/VBoxContainer/StatsLabel
@onready var button: Button = $Button

var tower_type: String

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

func set_data(p_tower_type: String, data: Dictionary) -> void:
	tower_type = p_tower_type
	name_label.text = data.get("name", "N/A")
	cost_label.text = "Cost: %d G" % data.get("cost", 0)
	
	var stats_text = "Dmg: %d" % data.get("damage", 0)
	if data.has("armor_penetration"):
		stats_text += " / Pen: %d" % data.get("armor_penetration", 0)
	stats_label.text = stats_text
	
	if preview.has_method("set_visual"):
		preview.set_visual(data.get("visual_config", {}))

func _on_button_pressed() -> void:
	selected.emit(tower_type)
