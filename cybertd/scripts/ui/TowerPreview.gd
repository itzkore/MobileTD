extends Control

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var visual_placeholder: Node2D = $SubViewportContainer/SubViewport/VisualPlaceholder

const TURRET_VISUAL_SCRIPT = preload("res://scripts/visuals/TurretVisual.gd")

func set_visual(config: Dictionary) -> void:
	# Smažeme starý vizuál, pokud existuje
	for child in visual_placeholder.get_children():
		child.queue_free()

	# Vytvoříme nový vizuál
	var visual = Node2D.new()
	visual.script = TURRET_VISUAL_SCRIPT
	visual_placeholder.add_child(visual)

	# Nakonfigurujeme ho podle dat
	for key in config:
		if key in visual:
			visual.set(key, config[key])
