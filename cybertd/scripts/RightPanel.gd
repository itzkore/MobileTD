extends Control

signal build_choice(tower_type: String)
signal upgrade_damage()
signal sell_requested()

@onready var build_box: VBoxContainer = $Panel/VBox/Build
@onready var tower_box: VBoxContainer = $Panel/VBox/Tower
@onready var lbl_title: Label = $Panel/VBox/Title
@onready var lbl_stats: Label = $Panel/VBox/Tower/Stats
@onready var btn_build_rapid: Button = $Panel/VBox/Build/Rapid
@onready var btn_build_sniper: Button = $Panel/VBox/Build/Sniper
@onready var btn_build_splash: Button = $Panel/VBox/Build/Splash
@onready var btn_upgrade_damage: Button = $Panel/VBox/Tower/UpgradeDamage
@onready var btn_sell: Button = $Panel/VBox/Tower/Sell

var open_state: bool = false

func _ready() -> void:
    visible = false
    btn_build_rapid.pressed.connect(func(): build_choice.emit("rapid"))
    btn_build_sniper.pressed.connect(func(): build_choice.emit("sniper"))
    btn_build_splash.pressed.connect(func(): build_choice.emit("splash"))
    btn_upgrade_damage.pressed.connect(func(): upgrade_damage.emit())
    btn_sell.pressed.connect(func(): sell_requested.emit())

func open_build(costs: Dictionary) -> void:
    lbl_title.text = "Build Tower"
    build_box.visible = true
    tower_box.visible = false
    btn_build_rapid.text = "Rapid (%d)" % int(costs.get("rapid", 10))
    btn_build_sniper.text = "Sniper (%d)" % int(costs.get("sniper", 18))
    btn_build_splash.text = "Splash (%d)" % int(costs.get("splash", 14))
    _show_panel()
    visible = true

func open_tower(stats: Dictionary) -> void:
    lbl_title.text = "Tower"
    build_box.visible = false
    tower_box.visible = true
    var text := "Damage: %d\nRate: %.2f/s\nRange: %.0f\nSplash: %.0f\nLevel: %d" % [
        int(stats.get("damage",0)),
        float(1.0/max(0.001, float(stats.get("cooldown",1.0)))),
        float(stats.get("range",0.0)),
        float(stats.get("splash",0.0)),
        int(stats.get("level",1))
    ]
    lbl_stats.text = text
    _show_panel()
    visible = true

func set_upgrade_state(cost: int, can_upgrade: bool) -> void:
    btn_upgrade_damage.text = "Upgrade (%d)" % cost
    btn_upgrade_damage.disabled = not can_upgrade

func close_panel() -> void:
    if not open_state:
        return
    open_state = false
    visible = false

func _show_panel() -> void:
    if open_state:
        return
    open_state = true
    visible = true

func is_open() -> bool:
    return open_state
