extends Node

var music = 0.0

# Ataque.
var player_attack_mode: bool = false
var AIattack_mode: bool = false
var player_attacking_card: Panel = null  # Carta que va a atacar.
var AIattacking_card: Panel = null  # Carta que va a atacar el oponente.
var player_attack_target: Panel = null   # Carta enemiga seleccionada.
var AIattack_target: Panel = null   # Carta enemiga seleccionada.

var active_era: Node = null

func start_attack(card: Panel):
	player_attack_mode = true
	player_attacking_card = card
	player_attack_target = null
	# Cambiar el color de la carta a rosa en 1 segundo.
	var tween = create_tween()
	tween.tween_property(card.front_texture, "modulate", Color(1,0,0.5,1), 1.0)
	await tween.finished
	
func AIstart_attack(card: Panel):
	AIattack_mode = true
	AIattacking_card = card
	AIattack_target = null
	# Cambiar el color de la carta a rosa en 1 segundo.
	var tween = create_tween()
	tween.tween_property(card.front_texture, "modulate", Color(1,0,0.5,1), 1.0)
	await tween.finished

func select_attack_target(target: Node):
	print(">>> select_attack_target() llamado con: ", target.name)
	print("Modo de ataque: ", player_attack_mode)
	
	if not player_attack_mode:
		print("No estás en modo ataque, se ignora la selección.")
		return
	
	player_attack_target = target

	_execute_attack()

func select_AIattack_target(target: Node):
	print(">>> select_AIattack_target() llamado con: ", target.name)
	print("Modo de ataque: ", AIattack_mode)
	
	AIattack_mode = true
	if not AIattack_mode:
		print("Oponente no está en modo ataque, se ignora la selección.")
		return
	
	AIattack_target = target

	_execute_AIattack()

func _execute_attack():
	if not player_attacking_card or not player_attack_target:
		return
	
	var board = get_tree().current_scene
	var energy_cost = player_attacking_card.cost if "cost" in player_attacking_card else 0
	
	if not board.player_energy_bar:
		print("No existe energía.")
	else:
		board.player_energy_bar.consume_energy(energy_cost)
		print("Cantidad de energía usada por ", player_attacking_card.card_name, " en ataque: ", energy_cost)
	
	# Determinar ataque
	var atk = player_attacking_card.modified_attack if player_attacking_card.modified_attack != null else player_attacking_card.attack

	# Determinar defensa si existe.
	var def_target = 0
	if "modified_defense" in player_attack_target:
		def_target = player_attack_target.modified_defense if player_attack_target.modified_defense != null else player_attack_target.defense

	# Calcular daño
	var damage = max(atk - def_target, 0)

	# Aplicar daño
	player_attack_target.take_damage(damage)

	# Animación de la carta atacante
	var tween = create_tween()
	tween.tween_property(player_attacking_card.front_texture, "modulate", Color(1,1,1,1), 1.0)
	await tween.finished

	# Limpiar modo ataque
	player_attack_mode = false
	player_attacking_card = null
	player_attack_target = null
	
	# Gastar acción.
	if board.cnt_actions <= board.max_actions:
		print("Acción gastada. Te quedan ", (board.max_actions - board.cnt_actions), " acciones.")
		board.cnt_actions += 1

func _execute_AIattack():
	if not AIattacking_card or not AIattack_target:
		return
	
	var board = get_tree().current_scene
	var energy_cost = AIattacking_card.cost if "cost" in AIattacking_card else 0
	
	if not board.AIenergy_bar:
		print("No existe energía.")
	else:
		board.AIenergy_bar.consume_energy(energy_cost)
		print("Cantidad de energía usada por oponente ", AIattacking_card.card_name, " en ataque: ", energy_cost)
	
	# Determinar ataque
	var atk = AIattacking_card.modified_attack if AIattacking_card.modified_attack != null else AIattacking_card.attack

	# Determinar defensa si existe.
	var def_target = 0
	if "modified_defense" in AIattack_target:
		def_target = AIattack_target.modified_defense if AIattack_target.modified_defense != null else AIattack_target.defense

	# Calcular daño
	var damage = max(atk - def_target, 0)

	# Aplicar daño
	AIattack_target.take_damage(damage)

	# Animación de la carta atacante
	var tween = create_tween()
	tween.tween_property(AIattacking_card.front_texture, "modulate", Color(1,1,1,1), 1.0)
	await tween.finished
	
	AIattack_mode = false
	AIattacking_card = null
	AIattack_target = null
	
	# Gastar acción.
	if board.AIcnt_actions <= board.AImax_actions:
		print("Acción gastada. Al oponente le quedan ", (board.AImax_actions - board.AIcnt_actions), " acciones.")
		board.AIcnt_actions += 1

func choose_AIattack_target(player_cards: Array = []) -> Node:
	var board = get_tree().current_scene
	var targets = []

	# Si se pasaron cartas del jugador, filtrar las que siguen vivas
	if player_cards.size() > 0:
		for card in player_cards:
			# Verificar que la carta sigue viva y en juego
			if "discarded" in card and not card.discarded and "in_hand" in card and not card.in_hand:
				targets.append(card)
	else:
		# Fallback: buscar en player_board_play
		for c in board.player_board_play.get_children():
			if "card_name" in c and "discarded" in c and "in_hand" in c and not c.discarded and not c.in_hand:
				targets.append(c)
	
	print("IA: Cartas enemigas encontradas: ", targets.size())
	if targets.size() > 0:
		for t in targets:
			print("  - ", t.card_name if "card_name" in t else t.name)

	# Si hay cartas, elegir la mejor según prioridad
	if targets.size() > 0:
		return _choose_best_target(targets)
	
	# Solo atacar el generador si NO hay cartas y puede ser atacado
	if board.player_generator.can_attack_generator():
		print("IA: No hay cartas enemigas, atacando generador")
		return board.player_generator
	
	print("IA: No hay objetivos válidos")
	return null


# Sistema de priorización inteligente de objetivos
func _choose_best_target(targets: Array) -> Node:
	var scored_targets = []
	
	print("DEBUG _choose_best_target: Evaluando ", targets.size(), " objetivos")
	for target in targets:
		print("  - Objetivo: ", target.card_name if "card_name" in target else target.name, " | Node: ", target.name, " | Padre: ", target.get_parent().name if target.get_parent() else "sin padre")
		var score = _calculate_target_priority(target)
		scored_targets.append({"card": target, "score": score})
	
	# Ordenar por puntuación (mayor = mejor objetivo)
	scored_targets.sort_custom(func(a, b): return a.score > b.score)
	
	var best = scored_targets[0].card
	print("IA: Objetivo elegido: ", best.card_name, " (puntuación: ", scored_targets[0].score, ")")
	print("  -> Nodo elegido: ", best.name, " | Padre: ", best.get_parent().name if best.get_parent() else "sin padre")
	return best


# Calcula prioridad de un objetivo (mayor = más prioritario)
func _calculate_target_priority(target) -> float:
	var score = 0.0
	
	# Verificar que tenga las propiedades necesarias
	if not ("modified_defense" in target and "modified_attack" in target and "current_health" in target):
		return 0.0
	
	var def = target.modified_defense if target.modified_defense != null else target.defense
	var atk = target.modified_attack if target.modified_attack != null else target.attack
	var hp = target.current_health
	
	# PRIORIDAD 1: Cartas que podemos matar en un golpe (+100 puntos)
	# Nota: Necesitamos la carta atacante para calcular esto, 
	# pero de momento priorizamos cartas con poca vida
	if hp <= 30:
		score += 100
	elif hp <= 50:
		score += 50
	
	# PRIORIDAD 2: Cartas con alto ataque (amenazas) (+50 puntos por cada 5 de ataque)
	score += (atk / 5.0) * 50
	
	# PRIORIDAD 3: Cartas con baja defensa (más fáciles de matar) (+30 puntos base - defensa)
	score += (30 - def)
	
	# PRIORIDAD 4: Cartas con poca vida restante (+10 puntos por cada 10 de vida que le falte)
	var missing_hp = target.max_health - hp
	score += (missing_hp / 10.0) * 10
	
	return score


# Aplicar habilidad.
func apply_ability(card: Card, ability: Dictionary):
	if ability.is_empty():
		print("La carta ", card.card_name, " no tiene habilidad.")
		return
	
	var board = get_tree().current_scene
	var energy_cost = card.cost if "cost" in card else 0
	
	if not board.player_energy_bar:
		print("No existe energía.")
	else:
		board.player_energy_bar.consume_energy(energy_cost)
		print("Cantidad de energía usada por ", card.card_name, " en habilidad: ", energy_cost)
	
	match ability.type:
		"stat_mod":
			_apply_stat_mod(card, ability)
			#break
	
	# Gastar acción.
	if board.cnt_actions <= board.max_actions:
		print("Acción gastada. Te quedan ", (board.max_actions - board.cnt_actions), " acciones.")
		board.cnt_actions += 1

# Modificación de stats.
func _apply_stat_mod(card: Panel, ability: Dictionary):
	var board = get_tree().current_scene
	var stat_change = 1 + float(ability.value) / 100  # Convertir porcentaje a multiplicador.

	for c in board.board_play.get_children():
		# Comprobar que c es una carta con las propiedades necesarias.
		if not (c is Card):
			continue
		if c.discarded or c.in_hand:
			continue
		if not _is_target_for_ability(card, c, ability):
			continue
		
		match ability.stat:
			"attack":
				c.modified_attack = int(c.attack * stat_change)
				if c.attack_hover:  # Evitar errores si no existe.
					c.attack_hover.text = "Ataque: " + str(c.attack) + " (+" + str(ability.value) + "%)"
					c.attack_label.text = str((c.attack * stat_change))
					_show_buff_color(c.attack_hover)
					_show_buff_color(c.attack_label)
				break
			"defense":
				c.modified_defense = int(c.defense * stat_change)
				if c.defense_hover:  # Evitar errores si no existe.
					c.defense_hover.text = "Def: " + str(c.defense) + " (+" + str(ability.value) + "%)"
					c.defense_label.text = str((c.defense * stat_change))
					_show_buff_color(c.defense_hover)
					_show_buff_color(c.defense_label)
				break
		
		print("%s recibe modificación de %s por %s" % [c.card_name, ability.stat, ability.name])


# Comprobar si la carta es objetivo válido.
func _is_target_for_ability(source_card: Panel, target_card: Panel, ability: Dictionary) -> bool:
	match ability.target:
		"self":
			return source_card == target_card
		"allies":
			return source_card.owner == target_card.owner and source_card != target_card
		"enemy":
			return source_card.owner != target_card.owner
	return false

# Guardar la era activa y aplicar sus efectos.
func set_active_era(era: BaseEra) -> void:
	if active_era:
		remove_era_effect(active_era)
	active_era = era
	print("Era activa guardada en Global: ", era.name_era)
	apply_era_effect(active_era)

# Aplicar efecto de la era a todas las cartas en juego
func apply_era_effect(era: BaseEra) -> void:
	if not era or not era.effect:
		return
	var board = get_tree().current_scene

	match era.effect["type"]:
		"medieval":
			apply_medieval_effect(era)

	print("Efecto de la era aplicado: ", era.name_era)

func apply_medieval_effect(era: BaseEra) -> void:
	match era.effect["subtype"]:
		"stat_mod":
			apply_era_stat_mod(era)
	
	print("Efecto de la era aplicado: ", era.name_era)

# Aplica el efecto de stats de la era a todas las cartas en juego
func apply_era_stat_mod(era: BaseEra) -> void:
	var board = get_tree().current_scene
	if not board:
		return
	
	var all_cards = board.player_board_play.get_children() + board.board_play.get_children()
	
	for card in all_cards:
		if not (card is Card):
			continue
		if card.discarded or card.in_hand:
			continue
		
		# Multiplicador según era
		var multiplier: float = 1.0
		if card.era_name == era.name_era:
			multiplier = 1.0 + float(era.effect["value_era"]) / 100
		else:
			multiplier = 1.0 + float(era.effect["value_not_era"]) / 100

		# Aplicar modificadores sobre stats base
		card.modified_attack = int(card.attack * multiplier)
		card.modified_defense = int(card.defense * multiplier)
		
		# Actualizar visual
		if card.attack_hover:
			card.attack_hover.text = "Ataque: %d (%+d%%)" % [card.attack, int(round((multiplier-1)*100))]
			card.attack_label.text = str(card.modified_attack)
			_show_buff_color(card.attack_hover)
			_show_buff_color(card.attack_label)
		if card.defense_hover:
			card.defense_hover.text = "Def: %d (%+d%%)" % [card.defense, int(round((multiplier-1)*100))]
			card.defense_label.text = str(card.modified_defense)
			_show_buff_color(card.defense_hover)
			_show_buff_color(card.defense_label)
		
		print("%s modificado por era %s: atk=%d, def=%d" % [card.card_name, era.name_era, card.modified_attack, card.modified_defense])


# Retirar efecto de la era anterior.
func remove_era_effect(era: BaseEra) -> void:
	if not era:
		return
	var board = get_tree().current_scene
	if not board:
		return
	
	var all_cards = board.player_board_play.get_children() + board.board_play.get_children()
	for card in all_cards:
		if not (card is Card):
			continue
		if card.discarded or card.in_hand:
			continue
		
		# Restaurar stats originales
		card.modified_attack = card.attack
		card.modified_defense = card.defense
		
		# Actualizar visual
		if card.attack_hover:
			card.attack_hover.text = "Ataque: %d" % card.attack
		if card.defense_hover:
			card.defense_hover.text = "Def: %d" % card.defense
	
	print("Efecto de la era retirado: ", era.name_era)
	active_era = null

# Mostrar color del bufo.
func _show_buff_color(stat_label: Label):
	var t = create_tween()
	t.tween_property(stat_label, "modulate", Color(0.5, 1, 0.5, 1), 0.2)
