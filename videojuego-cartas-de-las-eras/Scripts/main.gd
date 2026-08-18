extends Control

func _ready() -> void:
	# Iniciamos música.
	$MenuChill.play(Global.music)
	# Forzar tamaño mínimo.
	DisplayServer.window_set_min_size(Vector2i(1024, 600))
