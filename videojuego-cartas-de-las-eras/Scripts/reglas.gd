extends Control

@onready var select_d = $elecc
@onready var select_t = $elecc2

var op_d: Array[String] = ["Fácil", "Normal", "Difícil"]
var op_t: Array[int] = [10, 15, 20, 25, 30]
var index_d = 1 # Poner como predeterminado 'Normal'
var index_t = 4 # Poner como predeterminado '30'

func _ready() -> void:
	$MenuChill.play(Global.music)
	update_difficulty()
	update_turns()

func _on_left_d_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	# Pasar a la anterior opción.
	index_d = (index_d - 1 + op_d.size()) % op_d.size()
	print("ID:" + str(index_d) + " " + op_d[index_d])
	update_difficulty()

func _on_left_t_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	# Pasar a la anterior opción.
	index_t = (index_t - 1 + op_t.size()) % op_t.size()
	print("ID:" + str(index_t) + " turns:" + str(op_t[index_t]))
	update_turns()


func update_difficulty() -> void:
	select_d.text = op_d[index_d]

func update_turns() -> void:
	select_t.text = str(op_t[index_t])

func _on_right_d_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	# Pasar a la siguiente opción.
	index_d = (index_d + 1) % op_d.size()
	print("ID:" + str(index_d) + " " + op_d[index_d])
	update_difficulty()

func _on_right_t_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	# Pasar a la siguiente opción.
	index_t = (index_t + 1) % op_t.size()
	print("ID:" + str(index_t) + " turns:" + str(op_t[index_t]))
	update_turns()


func _on_volver_pressed() -> void:
	$ButtonSound.play()
	await $ButtonSound.finished
	get_tree().change_scene_to_file("res://Scenes/modos.tscn")
	Global.music = $MenuChill.get_playback_position()
