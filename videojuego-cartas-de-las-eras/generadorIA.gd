extends Button

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

func has_AIcards_in_slots() -> bool:
	var board = get_tree().current_scene

	# Revisar todas las cartas en el grupo
	for card in get_tree().get_nodes_in_group("cartas"):
		# Solo cartas que no estén en la mano ni descartadas
		if card.in_hand or card.discarded:
			continue
		# Verificar si su slot actual es de la IA
		if card.current_slot in board.AIcard_slots:
			print("Carta en slot IA encontrada:", card.name)
			return true
	return false


# Función recursiva para buscar nodos Card dentro de cualquier hijo.
func _contains_card(node: Node) -> bool:
	if node is Card and not node.discarded and not node.in_hand:
		return true
	for child in node.get_children():
		if _contains_card(child):
			return true
	return false

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var board = get_tree().current_scene
		if not board.is_player_turn or board.deployment_phase:
			return



func take_damage(amount: int):
	var board = get_tree().current_scene
	# Si la IA aún tiene cartas en juego, el generador no puede ser dañado.
	if board.has_AI_cards_on_board():
		print("El generador está protegido por las cartas del enemigo.")
		return
	
	current_health = clamp(current_health - amount, 0, max_health)
	update_health_bar()

func heal(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)
	update_health_bar()

func update_health_bar():
	# Actualizar la barra.
	health_bar.max_value = max_health
	
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
