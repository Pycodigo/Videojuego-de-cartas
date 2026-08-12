extends Control

@onready var your_decks_btn = $YourDecksBtn

var distance: float = 10     # Distancia horizontal.
var zoom: float = 0.1    # Ampliar si pasa el ratón.
var duration: float = 1.1  # Duración del ciclo.

var cicle_horizontal:Tween  # Objeto que ejecuta la animación de movimiento.
var cicle_zoom:Tween  # Objeto que ejecuta la animación de zoom.

func _ready() -> void:
	# Iniciamos música.
	$MenuChill.play(Global.music)
	# Forzar tamaño mínimo.
	DisplayServer.window_set_min_size(Vector2i(1024, 600))

func _start_animation():
	# Crea un bucle.
	cicle_horizontal = create_tween().set_loops()
	
	# Movimiento de izquierda a derecha.
	cicle_horizontal.tween_property(self, "position:x", position.x - distance, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cicle_horizontal.tween_property(self, "position:x", position.x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_mouse_entered():
	#Crea la animación.
	cicle_zoom = create_tween()
	
	#Aumenta el tamaño de la carta.
	cicle_zoom.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_SINE)
	
	# Detener la animación de movimiento.
	if cicle_horizontal and cicle_horizontal.is_running():
		cicle_horizontal.stop()

func _on_mouse_exited():
	#Crea la animación.
	cicle_zoom = create_tween()
	
	#Devolver la carta a su tamaño original.
	cicle_zoom.tween_property(self, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_SINE)
	
	# Volver a ejecutar la animación de movimiento.
	_start_animation()

func _on_play_pressed() -> void:
	$"ButtonSound".play()
	await $"ButtonSound".finished
	Global.want_to_select = true
	get_tree().change_scene_to_file("res://Scenes/your_decks.tscn")
	Global.music = $"MenuChill".get_playback_position()


func _on_exit_pressed() -> void:
	$"ButtonSound".play()
	await $"ButtonSound".finished
	get_tree().quit()


func _on_config_pressed() -> void:
	$"ButtonSound".play()
	await $"ButtonSound".finished
	get_tree().change_scene_to_file("res://Scenes/config.tscn")
	Global.music = $"MenuChill".get_playback_position()


func _on_deck_builder_btn_pressed() -> void:
	$"ButtonSound".play()
	await $"ButtonSound".finished
	get_tree().change_scene_to_file("res://Scenes/deck_builder.tscn")
	Global.music = $"MenuChill".get_playback_position()


func _on_your_decks_btn_pressed() -> void:
	$"ButtonSound".play()
	await $"ButtonSound".finished
	Global.want_to_select = false
	get_tree().change_scene_to_file("res://Scenes/your_decks.tscn")
	Global.music = $"MenuChill".get_playback_position()
