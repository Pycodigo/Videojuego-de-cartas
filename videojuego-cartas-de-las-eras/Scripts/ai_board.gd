extends Control

# Nodos del jugador.
@onready var player_hand = $Player/Hand
@onready var player_deck = $Player/Deck

# Cartas a robar al inicio.
var start_draw: int = 7

# Evita que se haga zoom en las cartas cuando se arrastra.
var card_is_dragging: bool = false
var last_total_angle: float = 0.0
# Pausar las acciones del jugador mientras esté en zoom.
var pause_while_zoom: bool = false


func _ready() -> void:
	# Esperar un frame para asegurar que todo esté cargado.
	await get_tree().process_frame
	draw_starting_hand(start_draw)
	#Inicialmente, al no tener cartas en slots, el botón de finalizar turno está deshabilitado.
	'''update_finish_turn_btn()
	turn_label.visible = false
	turn_owner.visible = false
	deployment_phase = true'''
	
	# Mostrar botón de reset solo si hay cartas en los slots y estamos en preparación.
	#reset_btn.visible = turn == 1 and not first_player_turn_done and has_cards_in_slots()
	
	# Solo en el primer turno: decidir al azar quién empieza.
	#is_player_turn = randi() % 2 == 0
	#cnt_actions = 1
	
	#era_slot.occupied = false
	#era_slot.current_era = null
	
	var viewport_size = get_viewport().get_visible_rect().size
	print(viewport_size)  # Vector2(ancho, alto)


# Repartir n cartas desde la baraja.
func draw_starting_hand(n: int):
	for i in range(n):
		var card = player_deck.draw_card()
		if card:
			# Guardar posición global de la baraja.
			var start_pos = player_deck.global_position
			player_hand.add_child(card)
			print(card.get_parent())
			card.global_position = start_pos  # Colocar sobre la baraja.
			card.original_position_global = card.global_position # Guardar posición.
			
			# Poner la mano en abanico.
			organize_hand()
		
		'''if AIcard:
			AIcard.is_hidden = true
			
			# Guardar posición global de la baraja.
			var start_pos = AIdeck.global_position
			AIhand.add_child(AIcard)
			AIcard.global_position = start_pos  # Colocar sobre la baraja.
			AIcard.original_position_global = AIcard.global_position # Guardar posición.
			
			# Poner la mano en abanico.
			organize_hand_AI()'''
		
		# Pausa entre robos para efecto visual.
		await get_tree().create_timer(0.15).timeout


# Organiza la mano del jugador en abanico.
func organize_hand() -> void:
	# Pillar todas las cartas de la mano.
	var player_total = player_hand.get_child_count()
	if player_total == 0:
		print("La mano del jugador está vacía.")
		return
		
	# Altura máxima del 'abanico'.
	var curve_hand_height: float = 25.0
	# Ángulo máximo de una carta.
	var max_angle: float = 15.0
	# Ancho de la mano.
	var hand_width = player_hand.size.x
	print("Hand width:", player_hand.size.x)
	print("Cartas:", player_hand.get_child_count())
	# Espacio entre cartas (base).
	var base_spacing_cards: float = 120.0
	# Por si no cambia.
	var spacing_cards = base_spacing_cards
	# Recalcular el espacio entre cartas en caso de que se pase del ancho disponible.
	if (player_total - 1) * base_spacing_cards > hand_width and player_total > 1:
		spacing_cards = hand_width / (player_total - 1)
	
	for i in range(player_total):
		# Obtener una carta.
		var card = player_hand.get_child(i)
		if not card.in_hand:
			continue # Solo ajustar cartas que siguen en la mano.
		
		print("Steal: ", card.in_hand)
		
		# Rotación de la carta en la mano. Va de 0 a 1, por lo que la primera iría, en un principio, en 0.5
		var hand_ratio: float = 0.5
		# Altura variable.
		var y := -curve_hand_height
		# Sumamos la mitad del ancho de la mano (para que no se vaya tanto).
		var center_x: float = hand_width / 2.0
		# Posición horizontal.
		var x := center_x
		# Rotación del 'abanico'.
		var rot: float = 0.0
		
		if player_total > 1:
			# Recalculamos la rotación de cada carta dependiendo de cuántas hayan.
			hand_ratio = float(i) / (float(player_total) - 1.0)
			# Calcular posición.
			x = center_x + (i - (player_total-1)/2.0) * spacing_cards
			print(i, " -> ", hand_ratio)
			# Calcular altura.
			y = -sin(hand_ratio * PI) * curve_hand_height
			print("Card height: ", y)
			# Calcular sus rotaciones.
			rot = (hand_ratio - 0.5) * 2 * max_angle
			print("hand_width: ", hand_width, " | spacing_cards: ", spacing_cards, " | player_total: ", player_total)
		
		var local_pos = Vector2(x, y)
		print(local_pos)
		# Mover las cartas a la mano de forma fluida.
		var tween = create_tween()
		tween.tween_property(card, "position", local_pos, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.set_parallel().tween_property(card, "rotation_degrees", rot, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		card.hand_position = local_pos
