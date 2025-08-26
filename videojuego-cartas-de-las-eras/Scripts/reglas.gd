extends Control

@onready var left = $izda
@onready var select = $elecc
@onready var right = $dcha

var options = ["Fácil", "Normal", "Difícil"]
var index = 0

func _ready() -> void:
	$MenuChill.play(Global.music)
	update_text()

func _on_left_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	index = (index - 1 + options.size()) % options.size()
	print(index)
	update_text()
	

func update_text() -> void:
	select.text = options[index]

func _on_right_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	index = (index + 1) % options.size()
	print(index)
	update_text()


func _on_volver_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	get_tree().change_scene_to_file("res://Scenes/modos.tscn")
	Global.music = $MenuChill.get_playback_position()
