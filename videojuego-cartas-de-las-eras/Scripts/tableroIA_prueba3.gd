extends Node2D

# Jugador.
@onready var player_hand = $jugador/mano
@onready var player_deck = $jugador/baraja
@onready var player_card_slots = \
	[$jugador/ranuras/ranura_prueba,\
	 $jugador/ranuras/ranura_prueba2,\
	 $jugador/ranuras/ranura_prueba3]
@onready var player_discard_slot = $jugador/ranura_descarte
@onready var player_board_play = $jugador/cartas_en_juego

# Oponente IA.
@onready var AIhand = $IA/mano
@onready var AIdeck = $IA/barajaIA
@onready var AIcard_slots = \
	[$IA/ranuras/ranura_prueba,\
	 $IA/ranuras/ranura_prueba2,\
	 $IA/ranuras/ranura_prueba3]
@onready var AIdiscard_slot = $IA/ranura_descarte
@onready var board_play = $IA/cartas_en_juego

# Botón para terminar turno.
@onready var finish_turn_btn = $Finaliza

# Texto de turnos.
@onready var turn_label = $turnos
@onready var turn_owner = $"dueño"

# Variables de turno.
var turn: int = 1
var is_player_turn: bool = true
var first_player_turn_done: bool

var deployment_phase: bool = true  # Fase inicial de colocar cartas.
var last_total_angle: float = 0.0
var start_draw: int = 7

func _ready() -> void:
	# Esperar un frame para asegurar que todo esté cargado.
	await get_tree().process_frame
	draw_starting_hand(start_draw)
	#Inicialmente, al no tener cartas en slots, el botón de finalizar turno está deshabilitado.
	update_finish_turn_btn()
	turn_label.visible = false
	turn_owner.visible = false
	
	# Solo en el primer turno: decidir al azar quién empieza.
	is_player_turn = randi() % 2 == 0

# Repartir n cartas desde la baraja.
func draw_starting_hand(n: int):
	for i in range(n):
		var card = player_deck.draw_card()
		var AIcard = AIdeck.draw_card()
		if card:
			# Guardar posición global de la baraja.
			var start_pos = player_deck.global_position
			player_hand.add_child(card)
			card.global_position = start_pos  # Colocar sobre la baraja.
			card.original_position_global = card.global_position # Guardar posición.
			
			# Poner la mano en abanico.
			organize_hand()
		
		if AIcard:
			AIcard.is_hidden = true
			
			# Guardar posición global de la baraja.
			var start_pos = AIdeck.global_position
			AIhand.add_child(AIcard)
			AIcard.global_position = start_pos  # Colocar sobre la baraja.
			AIcard.original_position_global = AIcard.global_position # Guardar posición.
			
			# Poner la mano en abanico.
			organize_hand_AI()
		
		# Pausa entre robos para efecto visual.
		await get_tree().create_timer(0.15).timeout

# Organiza la mano del jugador en abanico.
func organize_hand(animated: bool=true):
	var total = player_hand.get_child_count()
	if total == 0:
		print("Mano vacía.")
		return

	var base_spacing = 80.0
	var max_width = 500.0
	var spacing = base_spacing
	if (total-1) * base_spacing > max_width and total > 1:
		spacing = max_width / (total-1)

	var total_angle = min(40.0, total*7.0)
	var curve_height = 25.0
	var max_angle = 15.0

	for i in range(total):
		var card = player_hand.get_child(i)
		if not card.in_hand:
			continue  # Solo ajustar cartas que siguen en la mano.

		var t = 0.5 if total==1 else float(i)/float(total-1)
		var x = (i-(total-1)/2.0) * spacing
		var y = 0.0 if total==1 else -sin(t*PI) * curve_height
		var rot = 0.0 if total==1 else (t-0.5)*2*max_angle
		var global_pos = player_hand.to_global(Vector2(x,y))

		var local_pos = Vector2(x, y)
		if animated:
			var tween = create_tween()
			tween.tween_property(card, "position", local_pos, 0.3)
			tween.tween_property(card, "rotation_degrees", rot, 0.3)
		else:
			card.position = local_pos
			card.rotation_degrees = rot


	last_total_angle = total_angle

func organize_hand_AI(animated: bool = true):
	var total = AIhand.get_child_count()
	if total == 0:
		return

	var base_spacing = 80.0
	var max_width = 500.0
	var spacing = base_spacing
	if (total-1) * base_spacing > max_width and total > 1:
		spacing = max_width / (total-1)

	var curve_height = 25.0
	var max_angle = 15.0
	var y_offset = -200.0  # Desplaza toda la mano hacia abajo.

	for i in range(total):
		var AIcard = AIhand.get_child(i)
		if not AIcard.in_hand:
			continue

		var t = 0.5 if total == 1 else float(i)/float(total-1)
		var x = (i-(total-1)/2.0) * spacing
		var y = (0.0 if total == 1 else sin(t*PI) * curve_height) + y_offset
		var rot = 0.0 if total == 1 else (t-0.5)*2*max_angle

		# Girar 180° para que se vea boca abajo
		AIcard.rotation_degrees = rot + 180
		var local_pos = Vector2(x, y)

		if animated:
			var tween = create_tween()
			tween.tween_property(AIcard, "position", local_pos, 0.3)
			tween.tween_property(AIcard, "rotation_degrees", rot + 180, 0.3)
		else:
			AIcard.position = local_pos
			AIcard.rotation_degrees = rot + 180

func update_finish_turn_btn():
	# Habilitar solo si al menos un slot tiene carta.
	var can_finish = false
	for slot in player_card_slots:
		if slot.occupied:
			can_finish = true
			break
	finish_turn_btn.disabled = not can_finish

func _on_finish_turn_btn_pressed() -> void:
	var board = get_tree().current_scene
	board.deployment_phase = is_player_turn
	
	show_next_turn()

func show_next_turn(duration: float = 1.5) -> void:
	var owner: String
	if is_player_turn:
		owner = "Vas tú"
	else:
		owner = "Va tu oponente"
	turn_label.text = "Turno " + str(turn)
	turn_owner.text = owner
	turn_label.visible = true
	turn_owner.visible = true
	finish_turn_btn.disabled = true

	# Posición y tamaño inicial.
	turn_label.modulate.a = 0
	turn_label.scale = Vector2(1.5, 1.5)  # Comienza más grande.
	turn_label.position = Vector2(361, 224)
	turn_owner.modulate.a = 0
	turn_owner.scale = Vector2(1.5, 1.5)  # Comienza más grande.
	turn_owner.position = Vector2(445, 311)

	var label_tween = create_tween()
	var owner_tween = create_tween()

	# Aparece con zoom a escala normal.
	label_tween.tween_property(turn_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	label_tween.tween_property(turn_label, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	owner_tween.tween_property(turn_owner, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	owner_tween.tween_property(turn_owner, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Mantener visible durante la duración.
	label_tween.tween_interval(duration)
	owner_tween.tween_interval(duration)

	# Desaparece con fade-out y ligero desplazamiento hacia arriba.
	label_tween.tween_property(turn_label, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	label_tween.tween_property(turn_label, "position:y", turn_label.position.y - 20, 0.3)
	owner_tween.tween_property(turn_owner, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	owner_tween.tween_property(turn_owner, "position:y", turn_label.position.y - 20, 0.3)
	
	turn += 1
	
	await label_tween.finished
	await owner_tween.finished
	
	turn_label.visible = false
	turn_owner.visible = false
	finish_turn_btn.disabled = false
	label_tween.kill()
	owner_tween.kill()
	
	draw_card_per_turn()
	
	# Hacer que el siguiente turno sea del contrario.
	is_player_turn = not is_player_turn

func draw_card_per_turn():
	# Lógica de robo.
	if is_player_turn:
		var new_card = player_deck.draw_card()
		if new_card:
			player_hand.add_child(new_card)
			new_card.global_position = player_deck.global_position  # Colocar sobre la baraja.
			new_card.original_position_global = new_card.global_position # Guardar posición.
			
			# Poner la mano en abanico.
			organize_hand()
	else:
		var new_cardAI = AIdeck.draw_card()
		if new_cardAI:
			new_cardAI.is_hidden = true
			AIhand.add_child(new_cardAI)
			new_cardAI.global_position = AIdeck.global_position  # Colocar sobre la baraja.
			new_cardAI.original_position_global = new_cardAI.global_position # Guardar posición.
			
			# Poner la mano en abanico.
			organize_hand_AI()
