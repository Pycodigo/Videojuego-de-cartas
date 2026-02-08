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
@onready var player_generator = $jugador/generador
@onready var player_energy_bar = $jugador/Energia

# Oponente IA.
@onready var AIhand = $IA/mano
@onready var AIdeck = $IA/barajaIA
@onready var AIcard_slots = \
	[$IA/ranuras/ranura_prueba,\
	 $IA/ranuras/ranura_prueba2,\
	 $IA/ranuras/ranura_prueba3]
@onready var AIdiscard_slot = $IA/ranura_descarte
@onready var AIboard_play = $IA/cartas_en_juego
@onready var AIgenerator = $IA/generadorIA
@onready var AIenergy_bar = $IA/EnergiaIA
@onready var AIgeneratorbtn = $IA/Button

# Era global.
@onready var era_slot = $ranura_era_prueba

# Botón para terminar turno.
@onready var finish_turn_btn = $Finaliza

# Texto de turnos.
@onready var turn_label = $turnos
@onready var turn_owner = $"dueño"

@onready var reset_btn = $reinicio

# Variables de turno.
var turn: int = 1
var is_player_turn: bool
var first_player_turn_done: bool
# Contador de acciones por turno.
var cnt_actions: int = 1
var max_actions: int = 3
#var max_actions: int = 999
# Contador de acciones del oponente por turno.
var AIcnt_actions: int = 0
var AImax_actions: int = 3

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
	deployment_phase = true
	
	# Mostrar botón de reset solo si hay cartas en los slots y estamos en preparación.
	reset_btn.visible = turn == 1 and not first_player_turn_done and has_cards_in_slots()
	
	# Solo en el primer turno: decidir al azar quién empieza.
	is_player_turn = randi() % 2 == 0
	cnt_actions = 1
	
	era_slot.occupied = false
	era_slot.current_era = null
	
	var viewport_size = get_viewport().get_visible_rect().size
	print(viewport_size)  # Vector2(ancho, alto)

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
			tween.connect("finished", Callable(card, "set_ready_for_drag"))
		else:
			card.position = local_pos
			card.rotation_degrees = rot
			card.set_ready_for_drag()


	last_total_angle = total_angle
	return Tween

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

func has_cards_in_slots() -> bool:
	for slot in player_card_slots:
		if slot.get_child_count() > 0:
			return true
	return false

func update_finish_turn_btn():
	# Habilitar solo si al menos un slot tiene carta.
	var can_finish = false
	for slot in player_card_slots:
		if slot.occupied:
			can_finish = true
			break
	finish_turn_btn.disabled = not can_finish

func _on_finish_turn_btn_pressed() -> void:
	deployment_phase = false
	reset_btn.visible = false
	
	# Cerrar todos los paneles de opciones de las cartas.
	for card in get_tree().get_nodes_in_group("cartas"):
		card.options.visible = false
	
	show_next_turn()

func show_next_turn(duration: float = 1.5) -> void:
	# Hacer que el siguiente turno sea del contrario.
	is_player_turn = not is_player_turn
	
	if Global.active_era:
		Global.active_era.next_turn()
	
	var owner: String
	if is_player_turn:
		owner = "Vas tú"
		print("Tu turno\nTurno jugador: ", is_player_turn)
		# Recuperar energía.
		player_energy_bar.recover_energy(5)
	else:
		owner = "Va tu oponente"
		print("Turno IA\nTurno jugador: ", is_player_turn)
		# Recuperar energía.
		AIenergy_bar.recover_energy(5)
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

		print("Vuelves a tener las tres acciones.");
		cnt_actions = 1
	else:
		var new_cardAI = AIdeck.draw_card()
		if new_cardAI:
			new_cardAI.is_hidden = true
			AIhand.add_child(new_cardAI)
			new_cardAI.global_position = AIdeck.global_position  # Colocar sobre la baraja.
			new_cardAI.original_position_global = new_cardAI.global_position # Guardar posición.
			
			print("Oponente vuelve a tener las tres acciones.");
			AIcnt_actions = 0
			
			# Poner la mano en abanico.
			organize_hand_AI()
			# Hacer que la IA actúe en su turno.
			AI_play_turn()

func reset_slots_to_hand():
	print("\n=== RESET DEBUG ===")
	var moved := false
	
	# Solo permitir reset antes del primer turno.
	if turn > 1 or first_player_turn_done:
		print("Reseteo deshabilitado: ya pasó la fase de preparación.")
		reset_btn.visible = false
		return

	# Recorrer todas las cartas que puedan estar en slots.
	var all_cards = player_board_play.get_children() + player_hand.get_children()
	for card in all_cards:
		# Solo cartas que realmente tienen un slot asignado y no están ya en la mano.
		if card is Card and card.current_slot != null and not card.in_hand:
			print("Devolviendo carta: ", card.name, " del slot: ", card.current_slot.name)
			# Lógica de devolver a la mano.
			card.return_to_hand()

			# Animar a la mano de vuelta.
			var target_pos = player_hand.to_local(card.global_position)
			var tween = create_tween()
			tween.tween_property(card, "position", target_pos, 0.3)
			tween.tween_property(card, "rotation_degrees", 0, 0.3)

			moved = true

	if moved:
		organize_hand()            # Reorganizar la mano con animación.
		update_finish_turn_btn()   # Actualizar el botón de finalizar turno.
		print("Reseteo: cartas devueltas a la mano.")
		reset_btn.visible = has_cards_in_slots()
	else:
		print("Reseteo: no encontró ninguna carta para devolver.")



func _on_reset_btn_pressed() -> void:
	reset_slots_to_hand()

# Devuelve true si la IA tiene alguna carta activa en el tablero.
func has_AI_cards_on_board() -> bool:
	if not AIboard_play:
		return false

	for card in AIboard_play.get_children():
		# Asegurar de que las cartas IA tengan una propiedad "discarded" o "muerta"
		if card.is_inside_tree() and not card.discarded:
			return true
	return false

func _on_AIgenerator_pressed():
	print("Generador presionado -> Llamando a select_attack_target")
	if not Global.player_attack_mode:
		print("No estás en modo ataque.")
		return
	
	Global.select_attack_target(AIgenerator)

func AI_play_turn() -> void:
	finish_turn_btn.visible = false
	await get_tree().create_timer(0.5).timeout

	print("\n=== TURNO IA INICIADO ===")
	print("Acciones disponibles: ", AImax_actions)
	print("Energía disponible: ", AIenergy_bar.AIcurrent_energy)

	var board = get_tree().current_scene

	# Intentar jugar carta de era.
	if not deployment_phase:
		var eras_in_hand = []
		for card in AIhand.get_children():
			if "name_era" in card and card.in_hand:
				eras_in_hand.append(card)
		
		if eras_in_hand.size() > 0:
			print("IA: Evaluando si jugar era...")
			for era in eras_in_hand:
				var can_play = await era.should_AI_play_era()
				var era_played = await era.AI_play_era()
				if era_played and can_play:
					print("IA: Era jugada con éxito.")
					await get_tree().create_timer(0.8).timeout
					break

	# Usar habilidad de stat_mod solo una vez si conviene.
	var ability_used := false
	for card in AIboard_play.get_children():
		if "card_name" in card and "ability" in card and not card.discarded and not card.in_hand:
			var decision = Global.AI_should_use_ability(card, [])
			if decision.use_ability and card.ability.type == "stat_mod" and not ability_used:
				Global.apply_AI_ability(card, card.ability)
				ability_used = true
				await get_tree().create_timer(0.5).timeout
				break  # Solo una habilidad por turno.

	# Atacar con todas las acciones restantes.
	while AIcnt_actions < AImax_actions:
		var any_action_done := false

		# Obtener cartas IA disponibles para atacar.
		var AIcards := []
		for card in AIboard_play.get_children():
			if "card_name" in card and not card.discarded and not card.in_hand:
				AIcards.append(card)
		
		if AIcards.size() == 0:
			print("IA: No tiene cartas para usar.")
			break

		# Obtener cartas del jugador como posibles objetivos.
		var player_cards := []
		for card in player_board_play.get_children():
			if "card_name" in card and not card.discarded and not card.in_hand:
				player_cards.append(card)

		if player_cards.size() == 0:
			print("IA: No hay cartas enemigas, se puede atacar el generador si es posible.")
			break

		# Ordenar cartas IA por eficiencia (ataque/coste).
		var sorted_cards = AIcards.duplicate()
		sorted_cards.sort_custom(func(a, b):
			var atk_a = a.modified_attack if "modified_attack" in a and a.modified_attack != null else a.attack
			var atk_b = b.modified_attack if "modified_attack" in b and b.modified_attack != null else b.attack
			var cost_a = a.cost if "cost" in a else 1
			var cost_b = b.cost if "cost" in b else 1
			var eff_a = float(atk_a) / max(cost_a, 1)
			var eff_b = float(atk_b) / max(cost_b, 1)
			return eff_a > eff_b
		)

		# Atacar con la mejor carta disponible.
		for card in sorted_cards:
			if AIcnt_actions >= AImax_actions:
				break

			var target = Global.choose_AIattack_target(player_cards)
			if target:
				await Global.AIstart_attack(card)
				await Global.select_AIattack_target(target)
				any_action_done = true
				await get_tree().create_timer(0.5).timeout

		if not any_action_done:
			break

	print("=== TURNO IA FINALIZADO ===")
	print("Energía restante: ", AIenergy_bar.AIcurrent_energy)
	print("Acciones usadas: ", AIcnt_actions, "/", AImax_actions)
	await get_tree().create_timer(0.3).timeout
	finish_turn_btn.visible = true
	_on_finish_turn_btn_pressed()
