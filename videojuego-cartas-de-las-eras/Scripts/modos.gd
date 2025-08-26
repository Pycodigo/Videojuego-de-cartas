extends Control

func _ready() -> void:
	$MenuChill.play(Global.music)

func _on_duelo_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	get_tree().change_scene_to_file("res://Scenes/reglas.tscn")
	Global.music = $MenuChill.get_playback_position()
