extends Control

# Nodos del jugador.
@onready var player = $Player
@onready var player_hand = $Player/Hand
@onready var player_deck = $Player/Deck
@onready var player_slots = $Player/Slots
@onready var player_discard_slot = $Player/Slots/SlotDiscard
@onready var player_energy_bar = $Player/EnergyBar

# Nodos de la IA.
@onready var ai = $AI
@onready var ai_hand = $AI/Hand
@onready var ai_slots = $AI/Slots
@onready var ai_discard_slot = $AI/Slots/SlotDiscard
@onready var ai_energy_bar = $AI/EnergyBar
# Baraja de IA.
var ai_deck

# Otros nodos.
@onready var reset_btn = $ResetBtn
@onready var finish_turn_btn = $FinishTurnBtn
@onready var turn_lbl = $Label
@onready var actions_border = $ActionsBorder
@onready var actions_lbl = $ActionsBorder/ActionsLabel
@onready var actions_num = $ActionsBorder/ActionsNumber

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
# Turno del jugador o bot.
var is_ai_turn: bool = false
# Carta del jugador que ataca.
var attacking_card = null
var pause_while_deciding: bool = false

var times_slot: int

# Cartas que se defienden.
var defending_cards: Array = []

# Contadores.
var turn_cnt: int = 0
var max_actions: int = 3
var current_actions: int


func _ready() -> void:
	# Decir el turno actual.
	turn_lbl.text = "Turno " + str(turn_cnt)
	# Poner el botón de reiniciar.
	var tween = create_tween()
	tween.tween_property(reset_btn, "position:x", 0, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(finish_turn_btn, "position:x", 0, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
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
		await draw_starting_hand(start_draw, ai_deck, ai_hand)
		is_player = false
		while times_slot < 5:
			var card = choose_card_to_play()
			if card == null:
				break
			if await _AI_place_card_in_slot(card):
				times_slot += 1
		
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
	if pause_while_deciding:
		return
	
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
	
	# Primero averiguar cuántas cartas hay realmente.
	for card in player_hand.get_children():
		if card.in_hand and not card.is_dragging:
			valid_total += 1
	
	# Recalcular el espacio entre cartas en caso de que se pase del ancho disponible.
	if (valid_total - 1) * base_spacing_cards > hand_width and valid_total > 1:
		spacing_cards = hand_width / (valid_total - 1)
	
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

# Poner las cartas de los slots del jugador en mano.
func _on_reset_btn_pressed() -> void:
	# Pillar las cartas del jugador en juego.
	var player_cards_slots: Array = []
	for slot in player_slots.get_children():
		if slot == player_discard_slot:
			continue
		if slot.occupied:
			player_cards_slots.append(slot.current_card)
	
	# LLamar a la función para cada carta.
	for player_card in player_cards_slots:
		player_card._return_to_hand()

# Elegir la mejor carta.
func choose_card_to_play() -> Control:
	var best_card = null
	var best_value = -INF
	
	# Comprobar que la IA tiene cartas en la mano.
	var ai_total = ai_hand.get_child_count()
	if ai_total == 0:
		print("La mano de la IA está vacía.")
		return best_card
	
	var valid_cards: Array = []
	
	# Solo mira las cartas válidas (están en la mano).
	for card in ai_hand.get_children():
		if not card.in_hand or card.is_in_slot:
			continue
		
		valid_cards.append(card)
	
	for card in valid_cards:
		# Comprobar que el coste no es mayor que la energía restante a usar en un solo turno.
		if card.energy_cost > ai_energy_bar.energy:
			continue
		
		# Evitar dividir entre 0.
		var cost_div: float = card.energy_cost
		if cost_div <= 0:
			cost_div = 1
		# Fórmula en turno de preparación (recordar poner un match para cada era después).
		var score = (card.base_attack * 2 + (card.max_hp + card.base_defense)) / cost_div
		
		if score > best_value:
			best_value = score
			best_card = card
	
	print("Mejor carta: ", best_card.card_name)
	return best_card

# Colocar la mejor carta de la IA en un slot.
func _AI_place_card_in_slot(ai_best_card) -> bool:
	if ai_best_card == null:
		return false
	# Buscar todos los slots de IA disponibles.
	for slot in ai_slots.get_children():
		if slot.slot_owner == slot.SlotOwner.AI and not slot.occupied and slot.try_place_card(ai_best_card):
			# Crear animación de volteo.
			var flip_tween = create_tween()
			
			# Hacer animación de volteo.
			var flip_start = flip_tween.tween_property(ai_best_card.card_panel, "scale:x", 0, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			flip_tween.tween_callback(func():
				# Ocultar el cover.
				ai_best_card.cover.visible = false
			)
			var flip_ends = flip_tween.tween_property(ai_best_card.card_panel, "scale:x", 1, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await flip_ends.finished
			
			# Crear resto de animaciones.
			var tween = create_tween()
			
			# Poner rotación a 0º.
			tween.tween_property(ai_best_card, "rotation_degrees", ai_best_card.original_rotation, 0.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

			# Mover la carta al centro del slot.
			# Usar get_global_rect() para obtener posición y tamaño reales del slot.
			var slot_rect = slot.get_global_rect()

			var target_scale = slot_rect.size / ai_best_card.card_size
			ai_best_card.slot_scale = target_scale
			ai_best_card.card_panel.pivot_offset = Vector2.ZERO

			tween.parallel().tween_property(ai_best_card.card_panel, "scale", target_scale, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(ai_best_card.card_panel, "global_position", slot_rect.position, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			ai_best_card.slot_pos = slot_rect.position
			
			# Ocultar stats normales (se ven mal).
			for stat in [ai_best_card.hp_border_texture, ai_best_card.hp_text, ai_best_card.hp_texture, 
			ai_best_card.energy_cost_text, ai_best_card.energy_cost_texture, 
			ai_best_card.energy_cost_border_texture, ai_best_card.ability_text, 
			ai_best_card.attack_text, ai_best_card.attack_texture, 
			ai_best_card.defense_text, ai_best_card.defense_texture, 
			ai_best_card.cooldown_text, ai_best_card.cooldown_texture]:
				tween.parallel().tween_property(stat, "modulate:a", 0.0, 0.2)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# Posiciones destino en esquinas (relativas al 300x400 de la carta).
			var corners = {
				ai_best_card.hp_zoom_texture:           Vector2(-80, -15),      # Esquina superior izquierda.
				ai_best_card.energy_cost_zoom_texture:  Vector2(220, -15),      # Esquina superior derecha.
				ai_best_card.attack_zoom_texture:       Vector2(-80, 350),      # Esquina inferior izquierda.
				ai_best_card.defense_zoom_texture:      Vector2(220, 350),      # Esquina inferior derecha.
				# ai_best_card.cooldown_zoom_texture:     Vector2(70, 130),      # Centro.
				ai_best_card.cooldown_zoom_texture:     Vector2(70, 400),       # Abajo del todo.
				# ai_best_card.ability_zoom_texture:      Vector2(-60, 210),     # Centro un poco más abajo.
				ai_best_card.ability_zoom_texture:      Vector2(-60, 270),      # Centro un poco más abajo.
			}

			for stat_zoom in corners:
				stat_zoom.visible = true
				stat_zoom.modulate.a = 0.0
				tween.tween_property(stat_zoom, "modulate:a", 1.0, 0.1)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tween.parallel().tween_property(stat_zoom, "scale", Vector2(2, 2), 0.1)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(stat_zoom, "position", corners[stat_zoom], 0.1)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(0.08)

			# Actualizar la posición original por si se deselecciona después.
			tween.tween_callback(func():
				ai_best_card.original_position_global = ai_best_card.card_panel.global_position
			)
			
			ai_best_card.is_in_slot = true
			ai_best_card.in_hand = false
			ai_best_card.current_slot = slot
			organize_hand_AI()
			return true
	
	# Todos los slots estaban ocupados.
	print("Ningún slot está libre.")
	return false


# Evaluar qué acción usa la IA.
func AI_evaluate_action() -> void:
	# Pillar las cartas del jugador y la IA en juego.
	var player_cards_slots: Array = []
	var ai_cards_slots: Array = []

	for slot in player_slots.get_children():
		if slot == player_discard_slot:
			continue
		if slot.occupied:
			print(slot.current_card.card_name, " HP: ", slot.current_card.current_hp)
			player_cards_slots.append(slot.current_card)

	for ai_slot in ai_slots.get_children():
		if ai_slot == ai_discard_slot:
			continue

		if ai_slot.occupied:
			ai_cards_slots.append(ai_slot.current_card)
	
	# Generar todas las interacciones entre cartas.
	for ai_card in ai_cards_slots:
		# No tener en cuenta cartas que cuesten más de la energía disponible.
		if ai_card.energy_cost > ai_energy_bar.energy:
			continue
		# Comprobar que quedan acciones.
		if current_actions <= 0:
			return
		
		var best_target = null
		var best_value_atk = -INF
		# Calcular amenaza del jugador a nivel defensivo.
		var max_threat: float = 0.0
		var threat: float = 0.0
		var defense_score: float = 0.0

		for player_card in player_cards_slots:
			# Evitar meter cartas descartadas.
			if player_card.current_hp <= 0:
				continue
			
			print("Carta bot: ", ai_card.card_name, " / Carta jugador: ", player_card.card_name)
			
			# Daño que haría la IA contra la carta rival.
			var damage = max(0, ai_card.actual_atk - player_card.def_used)

			# Daño que recibiría la IA.
			var resistance = max(0, player_card.actual_atk - ai_card.base_defense)
			var damage_taken = player_card.actual_atk

			# Ver si puede la IA destruir la carta rival.
			var can_kill = damage >= player_card.current_hp

			# Guardar la mayor amenaza encontrada.
			max_threat = max(max_threat, resistance)
			threat = max(threat, player_card.actual_atk)

			var attack_score: float = 0.0

			if can_kill:
				attack_score = 10 + (damage * 2.0 - ai_card.energy_cost)
			else:
				attack_score = damage * 2.0 - ai_card.energy_cost

			print(
				"Carta bot: ", ai_card.card_name,
				" / Carta jugador: ", player_card.card_name,
				" / Daño: ", damage,
				" / Puede matar: ", can_kill
			)

			print("Puntuación ataque: ", attack_score)
			
			# Guardar la mejor carta para atacar según la puntuación.
			if attack_score > best_value_atk:
				best_value_atk = attack_score
				best_target = player_card

		# Comprobar si la carta moriría sin defender y defendiendo sobrevive.
		var avoid_lose_card = threat >= ai_card.current_hp and max_threat < ai_card.current_hp

		if avoid_lose_card:
			defense_score = 10 + ((threat - max_threat) * 2.0 - ai_card.energy_cost)
		else:
			defense_score = (threat - max_threat) * 2.0 - ai_card.energy_cost

		print(
			"Carta bot: ", ai_card.card_name,
			" / Amenaza máxima: ", max_threat,
			" / Puntuación defensa: ", defense_score
		)
		
		if best_target != null:
			if best_value_atk > defense_score:
				ai_card.action_clicked = 1
				print(
					"ANTES DE ACTIVAR: ", ai_card.card_name,
					" | BG visible: ", ai_card.action_bg.visible,
					" | BG alpha: ", ai_card.action_bg.modulate.a,
					" | TEX visible: ", ai_card.action_texture.visible,
					" | TEX alpha: ", ai_card.action_texture.modulate.a,
					" | TEX scale: ", ai_card.action_texture.scale
				)

				await ai_card._activate_action()

				print(
					"DESPUÉS DE ACTIVAR: ", ai_card.card_name,
					" | BG visible: ", ai_card.action_bg.visible,
					" | BG alpha: ", ai_card.action_bg.modulate.a,
					" | TEX visible: ", ai_card.action_texture.visible,
					" | TEX alpha: ", ai_card.action_texture.modulate.a,
					" | TEX scale: ", ai_card.action_texture.scale
				)
				# Atacar al objetivo.
				await best_target.receive_damage(ai_card.actual_atk)
				print("Carta rival: ", ai_card.card_name, " ataca a ", best_target.card_name, ".")
				print("Después del ataque: ", best_target.card_name, " HP: ", best_target.current_hp)
				await ai_card._cannot_use_card()
			else:
				ai_card.action_clicked = 2
				await ai_card._activate_action()
				
				# Usamos la defensa base (con animaciones).
				while ai_card.def_used < ai_card.base_defense:
					ai_card.def_used += 1
					
					# Actualizar lo visual.
					ai_card.defense_text.text = str(ai_card.def_used)
					ai_card.defense_zoom_text.text = str(ai_card.def_used)
					ai_card.def_num_detail.text = str(ai_card.def_used)
					await get_tree().create_timer(0.08).timeout
				
				# Cambiar color.
				ai_card.defense_zoom_text.add_theme_color_override("font_color", Color.BLUE)
				defending_cards.append(ai_card)
				print("Carta rival: ", ai_card.card_name, " se defiende.")
		else:
			ai_card.action_clicked = 2
			await ai_card._activate_action()
			
			# Usamos la defensa base (con animaciones).
			while ai_card.def_used < ai_card.base_defense:
				ai_card.def_used += 1
				
				# Actualizar lo visual.
				ai_card.defense_text.text = str(ai_card.def_used)
				ai_card.defense_zoom_text.text = str(ai_card.def_used)
				ai_card.def_num_detail.text = str(ai_card.def_used)
				await get_tree().create_timer(0.08).timeout
			
			# Cambiar color.
			ai_card.defense_zoom_text.add_theme_color_override("font_color", Color.BLUE)
			defending_cards.append(ai_card)
			print("Carta rival: ", ai_card.card_name, " se defiende.")
		
		ai_energy_bar.spend_energy(ai_card.energy_cost)
		current_actions -= 1
		
		# Actualizar lo visual.
		actions_num.text = str(current_actions)
		await get_tree().create_timer(0.08).timeout
		if current_actions == 0:
			# Poner texto a rojo.
			actions_lbl.add_theme_color_override("font_color", Color.RED)
			actions_num.add_theme_color_override("font_color", Color.RED)
			await _pass_turn()
			return

# Pasar turno.
func _pass_turn() -> void:
	var has_cards := false
	
	# Reiniciamos acciones.
	current_actions = max_actions
	
	# Actualizar lo visual.
	actions_num.text = str(current_actions)
	actions_lbl.add_theme_color_override("font_color", Color.WHITE)
	actions_num.add_theme_color_override("font_color", Color.WHITE)
	
	
	# Comprobar si hay cartas en juego y reiniciar las cartas.
	if is_ai_turn:
		# Acaba de terminar la IA.
		# Va a empezar el jugador.
		for slot in player_slots.get_children():
			if slot == player_discard_slot:
				continue
			
			if slot.occupied:
				has_cards = true
				var card = slot.current_card
				
				card._deactivate_actions()
				card.action_clicked = 0
				card.card_action_clicked = false
				card.def_used = 0
				
				# Actualizar lo visual.
				card.defense_text.text = str(card.def_used)
				card.defense_zoom_text.text = str(card.def_used)
				card.def_num_detail.text = str(card.def_used)
				card.defense_zoom_text.add_theme_color_override("font_color", Color.WHITE)
	
	else:
		# Acaba de terminar el jugador.
		# Va a empezar la IA.
		for slot in ai_slots.get_children():
			if slot == ai_discard_slot:
				continue
			
			if slot.occupied:
				has_cards = true
				var card = slot.current_card
				
				await card._deactivate_actions()
				card.action_clicked = 0
				card.card_action_clicked = false
				card.def_used = 0
				
				# Actualizar lo visual.
				card.defense_text.text = str(card.def_used)
				card.defense_zoom_text.text = str(card.def_used)
				card.def_num_detail.text = str(card.def_used)
				card.defense_zoom_text.add_theme_color_override("font_color", Color.WHITE)
	
	
	# Esperar a que termine la animación de todas las cartas.
	await get_tree().create_timer(0.25).timeout
	
	
	if turn_cnt == 0:
		# Comprobar si hay, al menos, alguna carta en juego.
		if not has_cards:
			print("No hay cartas en juego. Se pone al menos una.")
			return
		
		# Decidir al azar quién empieza.
		is_ai_turn = randi() % 2 == 0
		print("AI turn: " + str(is_ai_turn))
		_draw_per_turn()
		
		# Quitar botón de reinicio.
		var tween = create_tween()
		
		tween.tween_property(reset_btn, "modulate:a", 0.0, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Mostrar acciones.
		tween.parallel().tween_property(actions_border, "position:x", 0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		reset_btn.visible = false
		finish_turn_btn.text = "UI_FINISH_TURN"
	
	else:
		# Cambiar de turno.
		is_ai_turn = not is_ai_turn
		_draw_per_turn()
	
	
	# Aumentar contador de turno.
	turn_cnt += 1
	
	print("AI turn: " + str(is_ai_turn))
	
	# Actualizar texto del turno.
	turn_lbl.text = "Turno " + str(turn_cnt)
	
	
	# La IA actúa solo cuando es su turno.
	if is_ai_turn and turn_cnt > 0:
		await AI_evaluate_action()

func _draw_per_turn() -> void:
	# Robar carta para la IA.
		if is_ai_turn:
			var new_ai_card = ai_deck.draw_card()
			ai_hand.add_child(new_ai_card)
			organize_hand_AI()
			if turn_cnt > 1:
				ai_energy_bar.spend_energy(-5)
		# Robar carta para el jugador.
		else:
			var new_player_card = player_deck.draw_card()
			player_hand.add_child(new_player_card)
			organize_hand()
			if turn_cnt > 1:
				player_energy_bar.spend_energy(-5)

func _on_finish_turn_btn_pressed() -> void:
	await _pass_turn()
