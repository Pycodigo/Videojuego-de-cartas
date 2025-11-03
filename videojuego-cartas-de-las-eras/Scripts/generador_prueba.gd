extends Panel

@onready var health_bar = $vida
@onready var needle = $agujaP
@onready var current_health_label = $vida_actual

@export var max_health: int = 1000
var current_health: int

# Animación de la aguja y vida.
var needle_animation: Tween = null
var health_animation: Tween = null

func _ready() -> void:
	current_health = max_health
	current_health_label.text = str(current_health)
	update_health_bar()

func can_attack_generator() -> bool:
	var board = get_tree().current_scene
	# Devuelve true solo si todos los slots tienen card_slot_cnt == 0.
	var all_clear = board.player_card_slots.all(func(slot):
		return slot.card_slot_cnt == 0
	)

	print("Todos los slots vacíos: ", all_clear)
	return all_clear

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var board = get_tree().current_scene
		if not board.is_player_turn or board.deployment_phase:
			return

func take_damage(amount: int):
	# Si la IA aún tiene cartas en juego, el generador no puede ser dañado.
	if not can_attack_generator():
		print("El generador está protegido por las cartas del enemigo.")
		return
	
	current_health = clamp(current_health - amount, 0, max_health)
	update_health_bar()

func heal(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)
	update_health_bar()

func update_health_bar():
	# Modificar rotación de la aguja: -90º completo, 270º vacío.
	var health_ratio = float(current_health) / float(max_health)
	var start_angle = -90.0
	var end_angle = 270.0
	var needle_rotation = lerp(start_angle, end_angle, 1.0 - health_ratio)
	
	# Animación de la aguja.
	if needle_animation and needle_animation.is_running():
		needle_animation.kill()
	needle_animation = create_tween()
	needle_animation.tween_property(needle, "rotation_degrees", needle_rotation, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Animación de la barra.
	if health_animation and health_animation.is_running():
		health_animation.kill()
	health_animation = create_tween()
	health_animation.tween_property(health_bar, "value", current_health, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Animación del número (vida actual).
	# Tween personalizado que interpola valores enteros y actualiza el label.
	var start_value = int(current_health_label.text)
	var animation_label = create_tween()
	animation_label.tween_method(
		func(v): current_health_label.text = str(int(v)),
		start_value, current_health, 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Revisar si el generador muere
	if current_health <= 0:
		current_health = 0
		destroy_generator()

func destroy_generator():
	print("Generador destruído. Fin del juego.")
	hide()
	if not ResourceLoader.exists("res://Scenes/fin_juego_prueba.tscn"):
		print("ERROR: no existe la escena:", "res://Scenes/fin_juego_prueba.tscn")
		return

	var victory_scene = preload("res://Scenes/fin_juego_prueba.tscn")
	var victory_panel = victory_scene.instantiate()

	# Añadir al árbol en la raíz para asegurarnos que se vea por encima.
	get_tree().get_root().add_child(victory_panel)

	# Llamar a mostrar y conectar la señal.
	if "show_victory" in victory_panel:
		victory_panel.show_victory(false)
	else:
		print("WARNING: la escena no tiene show_victory()")

	# Conectar la señal (por si quieres reaccionar desde este script)
	if victory_panel.has_signal("victory_confirmed"):
		victory_panel.connect("victory_confirmed", Callable(self, "_on_victory_confirmed"))

func _on_victory_confirmed(result: bool) -> void:
	print("Se recibió victory_confirmed:", result)
	# aquí paras cualquier loop del juego, guardas puntuación, etc.
