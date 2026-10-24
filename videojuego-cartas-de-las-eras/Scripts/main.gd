extends Control

func _ready() -> void:
	# Iniciamos música.
	$MenuChill.play(Global.music)
	# Forzar tamaño mínimo.
	DisplayServer.window_set_min_size(Vector2i(800, 600))
	print("Vector: ", Vector2(0, 0).lerp(Vector2(100, 0), 0.07))
