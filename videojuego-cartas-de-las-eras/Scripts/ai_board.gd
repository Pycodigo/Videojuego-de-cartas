extends Control

# Nodos del jugador.
@onready var player = $Player
@onready var player_hand = $Player/Hand
@onready var player_deck = $Player/Deck

# Nodos de la IA.
@onready var ai = $AI
@onready var ai_hand = $AI/Hand
# Baraja de IA.
var ai_deck

# Cartas a robar al inicio.
var start_draw: int = 7

# Ruta baraja IA.
var ai_complete_path
var ai_complete_paths: Array = []

# Evita que se haga zoom en las cartas cuando se arrastra.
var card_is_dragging: bool = false
var last_total_angle: float = 0.0
# Pausar las acciones del jugador mientras esté en zoom.
var pause_while_zoom: bool = false

# Mandar si es jugador o bot.
var is_player: bool


func _ready() -> void:
	# Esperar un frame para asegurar que todo esté cargado.
	await get_tree().process_frame
	# Ruta de las barajas IA.
	var ai_path = "res://Scenes/AIDecks/"
	var dir = DirAccess.open(ai_path)
	if not dir:
		print("Error: La carpeta de la barajas no existe.")
		return
	# Pillar los archivos.
	var ai_deck_files = dir.get_files()
	
	for ai_deck_name in ai_deck_files:
		# Comprobar si no termina en .tscn.
		if not ai_deck_name.ends_with(".tscn"):
			continue
	
		ai_complete_path = ai_path + ai_deck_name
		ai_complete_paths.append(ai_complete_path)
		
			
	# Elegir (al azar) la baraja de IA.
	var pick_ai_random = ai_complete_paths[randi_range(0, ai_complete_paths.size() - 1)]
	print("Pick_AI_random: ", pick_ai_random)
	var ai_random = load(pick_ai_random)
	ai_deck = ai_random.instantiate()
	# Poner la posición correctamente.
	ai_deck.position = Vector2(40, 30)
	# Añadir como hijo.
	ai.add_child(ai_deck)
	print("Baraja IA: ", ai_deck)
	
	# Mandar si robar cartas con una baraja u otra (para que no se confunda).
	if player_deck:
		draw_starting_hand(start_draw, player_deck, player_hand)
		is_player = true
	if ai_deck:
		draw_starting_hand(start_draw, ai_deck, ai_hand)
		is_player = false
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
func draw_starting_hand(n: int, deck, hand):
	for i in range(n):
		var card = deck.draw_card()
		# Guardar posición global de la baraja.
		var start_pos = deck.global_position
		hand.add_child(card)
		print(card.get_parent())
		card.global_position = start_pos  # Colocar sobre la baraja.
		card.original_position_global = card.global_position # Guardar posición.
			
		# Poner la mano en abanico.
		organize_hand()
		organize_hand_AI()
		
		# Pausa entre robos para efecto visual.
		await get_tree().create_timer(0.15).timeout


# Organiza la mano del jugador en abanico.
func organize_hand() -> void:
	# Pillar todas las cartas de la mano.
	var player_total = player_hand.get_child_count()
	# Cartas que quedan en la mano.
	var valid_total: int = 0
	# Índices de las cartas (para reorganizar).
	var j: int = 0
	
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
	
	# Primero averiguar cuántas cartas hay realmente.
	for card in player_hand.get_children():
		if card.in_hand and not card.is_dragging:
			valid_total += 1
	
	for i in range(player_total):
		# Obtener una carta.
		var card = player_hand.get_child(i)
		if not card.in_hand or card.is_dragging or card.is_in_slot:
			print("If not: In hand ", card.in_hand, " Is dragging ", card.is_dragging)
			continue # Solo ajustar cartas que siguen en la mano.
		
		print("If: In hand ", card.in_hand, " Is dragging ", card.is_dragging)
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
		
		if valid_total > 1:
			# Recalculamos la rotación de cada carta dependiendo de cuántas hayan.
			hand_ratio = float(j) / (float(valid_total) - 1.0)
			# Calcular posición.
			x = center_x + (j - (valid_total-1)/2.0) * spacing_cards
			print(j, " -> ", hand_ratio)
			# Calcular altura.
			y = -sin(hand_ratio * PI) * curve_hand_height
			print("Card height: ", y)
			# Calcular sus rotaciones.
			rot = (hand_ratio - 0.5) * 2 * max_angle
			print("hand_width: ", hand_width, " | spacing_cards: ", spacing_cards, " | player_total: ", player_total)
		
		var local_pos = Vector2(x, y)
		print(local_pos)
		print(card.card_name, " actual: ", card.position)
		print(card.card_name, " destino: ", local_pos)
		# Mover las cartas a la mano de forma fluida.
		var tween = create_tween()
		tween.tween_property(card, "position", local_pos, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.set_parallel().tween_property(card, "rotation_degrees", rot, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		card.hand_index = j
		j += 1
		
		card.hand_position = local_pos
		# Al final, guarda la posición y rotación.
		tween.tween_callback(func():
			card.original_position_global = card.global_position
			card.hand_rotation = rot
		)


# Organiza la mano de la IA en abanico.
func organize_hand_AI() -> void:
	# Pillar todas las cartas de la mano.
	var ai_total = ai_hand.get_child_count()
	# Cartas que quedan en la mano.
	var valid_total: int = 0
	# Índices de las cartas (para reorganizar).
	var j: int = 0
	
	if ai_total == 0:
		print("La mano de la IA está vacía.")
		return
		
	# Altura máxima del 'abanico'.
	var curve_hand_height: float = 25.0
	# Ángulo máximo de una carta.
	var max_angle: float = 15.0
	# Ancho de la mano.
	var hand_width = ai_hand.size.x
	print("Hand width:", ai_hand.size.x)
	print("Cartas:", ai_hand.get_child_count())
	# Espacio entre cartas (base).
	var base_spacing_cards: float = 120.0
	# Por si no cambia.
	var spacing_cards = base_spacing_cards
	# Recalcular el espacio entre cartas en caso de que se pase del ancho disponible.
	if (ai_total - 1) * base_spacing_cards > hand_width and ai_total > 1:
		spacing_cards = hand_width / (ai_total - 1)
	
	# Primero averiguar cuántas cartas hay realmente.
	for card in ai_hand.get_children():
		if card.in_hand and not card.is_dragging:
			valid_total += 1
	
	for i in range(ai_total):
		# Obtener una carta.
		var card = ai_hand.get_child(i)
		if not card.in_hand or card.is_dragging or card.is_in_slot:
			print("AI: If not: In hand ", card.in_hand, " Is dragging ", card.is_dragging)
			continue # Solo ajustar cartas que siguen en la mano.
		
		print("AI If: In hand ", card.in_hand, " Is dragging ", card.is_dragging)
		print("AI Steal: ", card.in_hand)
		
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
		
		if valid_total > 1:
			# Recalculamos la rotación de cada carta dependiendo de cuántas hayan.
			hand_ratio = float(j) / (float(valid_total) - 1.0)
			# Calcular posición.
			x = center_x + (j - (valid_total-1)/2.0) * spacing_cards
			print(j, " -> ", hand_ratio)
			# Calcular altura.
			y = sin(hand_ratio * PI) * curve_hand_height
			print("Card height: ", y)
			# Calcular sus rotaciones.
			rot = (hand_ratio - 0.5) * 2 * max_angle
			print("hand_width: ", hand_width, " | spacing_cards: ", spacing_cards, " | ai_total: ", ai_total)
		
		var local_pos = Vector2(x, y - 200)
		print(local_pos)
		print(card.card_name, " IA actual: ", card.position)
		print(card.card_name, " IA destino: ", local_pos)
		# Mover las cartas a la mano de forma fluida.
		var tween = create_tween()
		tween.tween_property(card, "position", local_pos, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.set_parallel().tween_property(card, "rotation_degrees", rot, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		card.hand_index = j
		j += 1
		
		card.hand_position = local_pos
		# Al final, guarda la posición y rotación.
		tween.tween_callback(func():
			card.original_position_global = card.global_position
			card.hand_rotation = rot
		)
