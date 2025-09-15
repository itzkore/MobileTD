extends Control

@onready var towers_list: VBoxContainer = $VBox/Tabs/Towers/TowersList
@onready var enemies_list: VBoxContainer = $VBox/Tabs/Enemies/EnemiesList
@onready var back_btn: Button = $VBox/Back

const DefsData = preload("res://scripts/data/Defs.gd")

func _ready() -> void:
	_populate()
	back_btn.pressed.connect(_on_back)

func _populate() -> void:
	_clear_children(towers_list)
	_clear_children(enemies_list)
	for t in DefsData.towers():
		var l := Label.new()
		l.text = "%s (DMG %d, ROF %.2f, RNG %d)" % [t.name, t.damage, t.fire_rate, t.range]
		towers_list.add_child(l)
	for e in DefsData.enemies():
		var l2 := Label.new()
		l2.text = "%s (HP %d, SPD %d)" % [e.name, e.hp, e.speed]
		enemies_list.add_child(l2)

func _clear_children(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

func _on_back() -> void:
	var scene := load("res://scenes/MainMenu.tscn") as PackedScene
	if scene:
		get_tree().change_scene_to_packed(scene)
