extends "res://scripts/Tower.gd"

const AcousticWaveScene = preload("res://scenes/effects/AcousticWave.tscn")

func _shoot(_target: Node):
	var wave = AcousticWaveScene.instantiate()
	wave.global_position = _get_muzzle_global()
	wave.rotation = sprite.rotation
	get_tree().current_scene.add_child(wave)
