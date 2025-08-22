extends Button

var distance: float = 10     # Distancia horizontal.
var zoom: float = 0.1    # Ampliar si pasa el ratón.
var duration: float = 1.1  # Duración del ciclo.

var cicle_horizontal:Tween  # Objeto que ejecuta la animación de movimiento.
var cicle_zoom:Tween  # Objeto que ejecuta la animación de zoom.

func _ready() -> void:
	_start_animation()
	# Detectar que el ratón entró.
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	# Detectar que el ratón salió.
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

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
