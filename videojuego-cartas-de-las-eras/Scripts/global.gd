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
	
	# Determinar ataque.
	var atk = player_attacking_card.attack
	if "modified_attack" in player_attacking_card and player_attacking_card.modified_attack != null:
		atk = player_attacking_card.modified_attack

	# Determinar defensa del objetivo si existe.
	var def_target = 0
	if "defense" in player_attack_target:
		def_target = player_attack_target.defense
		if "modified_defense" in player_attack_target and player_attack_target.modified_defense != null:
			def_target = player_attack_target.modified_defense

	# Calcular daño.
	var damage = max(atk - def_target, 0)
	print("Ataque: %s (%d atk) -> %s (%d def) = %d daño" % [
		player_attacking_card.card_name, atk,
		player_attack_target.card_name if "card_name" in player_attack_target else "objetivo",
		def_target, damage
	])

	# Aplicar daño.
	player_attack_target.take_damage(damage)

	# Animación de la carta atacante.
	var tween = create_tween()
	tween.tween_property(player_attacking_card.front_texture, "modulate", Color(1,1,1,1), 1.0)
	await tween.finished

	# Limpiar modo ataque.
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
	
	# Determinar ataque.
	var atk = AIattacking_card.attack
	if "modified_attack" in AIattacking_card and AIattacking_card.modified_attack != null:
		atk = AIattacking_card.modified_attack

	# Determinar defensa del objetivo si existe.
	var def_target = 0
	if "defense" in AIattack_target:
		def_target = AIattack_target.defense
		if "modified_defense" in AIattack_target and AIattack_target.modified_defense != null:
			def_target = AIattack_target.modified_defense

	# Calcular daño.
	var damage = max(atk - def_target, 0)
	print("Ataque IA: %s (%d atk) -> %s (%d def) = %d daño" % [
		AIattacking_card.card_name, atk,
		AIattack_target.card_name if "card_name" in AIattack_target else "objetivo",
		def_target, damage
	])

	# Aplicar daño.
	AIattack_target.take_damage(damage)

	# Animación de la carta atacante.
	var tween = create_tween()
	tween.tween_property(AIattacking_card.front_texture, "modulate", Color(1,1,1,1), 1.0)
	await tween.finished
	
	AIattacking_card = null
	AIattack_target = null
	
	# Gastar acción.
	if board.AIcnt_actions <= board.AImax_actions:
		print("Acción gastada. Al oponente le quedan ", (board.AImax_actions - board.AIcnt_actions), " acciones.")
		board.AIcnt_actions += 1
	else:
		# Evitar que la IA siga atacando.
		AIattack_mode = false

func choose_AIattack_target(player_cards: Array = []) -> Node:
	var board = get_tree().current_scene
	var targets = []

	# Si se pasaron cartas del jugador, filtrar las que siguen vivas.
	if player_cards.size() > 0:
		for card in player_cards:
			# Verificar que la carta sigue viva y en juego.
			if "discarded" in card and not card.discarded and "in_hand" in card and not card.in_hand:
				targets.append(card)
	else:
		# Buscar en los slots del jugador.
		for c in board.player_board_play.get_children():
			if "card_name" in c and "discarded" in c and "in_hand" in c and not c.discarded and not c.in_hand:
				targets.append(c)
	
	print("IA: Cartas enemigas encontradas: ", targets.size())
	if targets.size() > 0:
		for t in targets:
			print("  - ", t.card_name if "card_name" in t else t.name)

	# Si hay cartas, elegir la mejor según prioridad.
	if targets.size() > 0:
		return _choose_best_target(targets)
	
	# Solo atacar el generador si no hay cartas y puede ser atacado.
	if board.player_generator.can_attack_generator():
		print("IA: No hay cartas enemigas, atacando generador.")
		return board.player_generator
	
	print("IA: No hay objetivos válidos")
	return null


# Sistema de priorización inteligente de objetivos.
func _choose_best_target(targets: Array) -> Node:
	var scored_targets = []
	
	print("Mejor objetivo: Evaluando ", targets.size(), " objetivos...")
	for target in targets:
		print("  - Objetivo: ", target.card_name if "card_name" in target else target.name, " | Node: ", target.name, " | Padre: ", target.get_parent().name if target.get_parent() else "sin padre")
		var score = _calculate_target_priority(target)
		scored_targets.append({"card": target, "score": score})
	
	# Ordenar por puntuación (mayor = mejor objetivo).
	scored_targets.sort_custom(func(a, b): return a.score > b.score)
	
	var best = scored_targets[0].card
	print("IA: Objetivo elegido: ", best.card_name, " (mejor puntuación: ", scored_targets[0].score, ")")
	print("  -> Nodo elegido: ", best.name, " | Padre: ", best.get_parent().name if best.get_parent() else "sin padre")
	return best


# Calcula prioridad de un objetivo (mayor = más prioritario).
func _calculate_target_priority(target) -> float:
	var score = 0.0
	
	# Verificar que tenga las propiedades necesarias
	if not ("defense" in target and "attack" in target and "current_health" in target):
		return 0.0
	
	var def = target.defense
	if "modified_defense" in target and target.modified_defense != null:
		def = target.modified_defense
	
	var atk = target.attack
	if "modified_attack" in target and target.modified_attack != null:
		atk = target.modified_attack
	
	var hp = target.current_health
	var max_hp = target.max_health if "max_health" in target else hp
	
	# Prioridad 1: Cartas con alto ataque (amenazas).
	score += (atk / 2.0) * 15  # Más puntos por ataque alto.
	
	# Prioridad 2: Cartas con baja defensa (fáciles de matar).
	score += max(0, 15 - def) * 8  # Mucho peso a baja defensa.
	
	# Prioridad 3: Cartas muy dañadas que podemos rematar.
	var hp_percent = (float(hp) / max_hp) * 100
	if hp_percent <= 25:
		score += 100  # Rematar cartas casi muertas.
	elif hp_percent <= 50:
		score += 50
	elif hp_percent <= 75:
		score += 20
	
	# Prioridad 4: Penalizar cartas con mucha vida restante.
	if hp > 100:
		score -= 10
	
	return score


# Aplicar habilidad.
func apply_ability(card: Card, ability: Dictionary):
	if ability.is_empty():
		print("La carta ", card.card_name, " no tiene habilidad.")
		return
	
	var board = get_tree().current_scene
	
	# No consumir energía si la habilidad es automática con trigger "on_damage".
	if not (ability.activation == "auto" and ability.has("trigger") and ability.trigger == "on_damage"):
		var energy_cost = card.cost if "cost" in card else 0
		
		if not board.player_energy_bar:
			print("No existe energía.")
		else:
			board.player_energy_bar.consume_energy(energy_cost)
			print("Cantidad de energía usada por ", card.card_name, " en habilidad: ", energy_cost)
	
	match ability.type:
		"stat_mod":
			_apply_ability_stat_mod(card, ability)
	
	# Gastar acción solo si es manual.
	if ability.activation == "manual" and board.cnt_actions <= board.max_actions:
		print("Acción gastada. Te quedan ", (board.max_actions - board.cnt_actions), " acciones.")
		board.cnt_actions += 1

# Modificación de stats.
func _apply_ability_stat_mod(card: Panel, ability: Dictionary):
	var board = get_tree().current_scene
	var stat_change = int(ability.value)  # Convertir número a uno entero.
	
	for c in board.player_board_play.get_children():
		# Comprobar que c es una carta con las propiedades necesarias.
		if not ("card_name" in c):
			continue
		if c.discarded or c.in_hand:
			continue
		if not _is_target_for_ability(card, c, ability):
			continue
		
		match ability["stat"]:
			"attack":
				# Usar el valor ya modificado si existe, sino el base.
				var current_atk = c.modified_attack if c.modified_attack != null else c.attack
				c.modified_attack = int(current_atk + stat_change)
				
				if "attack_hover" in c and c.attack_hover:
					c.attack_hover.text = "Ataque: " + str(c.attack) + " (+" + str(c.modified_attack - c.attack) + ")"
					c.attack_label.text = str(c.modified_attack)
					_show_buff_color(c.attack_hover)
					_show_buff_color(c.attack_label)
				elif "attack_label" in c:
					c.attack_label.text = str(c.modified_attack)
					_show_buff_color(c.attack_label)
				
			"defense":
				# Usar el valor ya modificado si existe, sino el base.
				var current_def = c.modified_defense if c.modified_defense != null else c.defense
				c.modified_defense = int(current_def + stat_change)
				
				if "defense_hover" in c and c.defense_hover:
					c.defense_hover.text = "Def: " + str(c.defense) + " (+" + str(c.modified_defense - c.defense) + ")"
					c.defense_label.text = str(c.modified_defense)
					_show_buff_color(c.defense_hover)
					_show_buff_color(c.defense_label)
				elif "defense_label" in c:
					c.defense_label.text = str(c.modified_defense)
					_show_buff_color(c.defense_label)
			"attack_defense":
				# Usar el valor ya modificado si existe, sino el base.
				var current_atk = c.modified_attack if c.modified_attack != null else c.attack
				c.modified_attack = int(current_atk + stat_change)
				var current_def = c.modified_defense if c.modified_defense != null else c.defense
				c.modified_defense = int(current_def + stat_change)
				
				if "attack_hover" in c and c.attack_hover:
					c.attack_hover.text = "Ataque: " + str(c.attack) + " (+" + str(c.modified_attack - c.attack) + ")"
					c.attack_label.text = str(c.modified_attack)
					_show_buff_color(c.attack_hover)
					_show_buff_color(c.attack_label)
				elif "attack_label" in c:
					c.attack_label.text = str(c.modified_attack)
					_show_buff_color(c.attack_label)
				if "defense_hover" in c and c.defense_hover:
					c.defense_hover.text = "Def: " + str(c.defense) + " (+" + str(c.modified_defense - c.defense) + ")"
					c.defense_label.text = str(c.modified_defense)
					_show_buff_color(c.defense_hover)
					_show_buff_color(c.defense_label)
				elif "defense_label" in c:
					c.defense_label.text = str(c.modified_defense)
					_show_buff_color(c.defense_label)
		
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
func set_active_era(era) -> void:
	var board = get_tree().current_scene
	
	# Si ya hay una era activa, no hacer nada aquí.
	if active_era != null and active_era != era:
		print("ADVERTENCIA: Intentando activar era cuando ya hay una activa.")
	
	# Guardar y aplicar la nueva era.
	active_era = era
	print("Era activa ahora: ", active_era.name_era)
	apply_era_effect(active_era)


# Aplicar efecto de la era a todas las cartas en juego.
func apply_era_effect(era) -> void:
	if not era or not era.details:
		return
	var board = get_tree().current_scene

	match era.details["type"]:
		"medieval":
			apply_medieval_effect(era)
		"future":
			apply_future_effect(era)

	print("Efecto de la era aplicado: ", era.name_era)

func apply_medieval_effect(era) -> void:
	match era.details["subtype"]:
		"stat_mod":
			apply_era_stat_mod(era)
	
	print("Efecto de la era aplicado: ", era.name_era)

func apply_future_effect(era) -> void:
	match era.details["subtype"]:
		"stat_mod":
			apply_era_stat_mod(era)
	
	print("Efecto de la era aplicado: ", era.name_era)

# Aplica el efecto de stats de la era a todas las cartas en juego.
func apply_era_stat_mod(era) -> void:
	var board = get_tree().current_scene
	if not board:
		return
	
	# Comporbar que se pillan todas las cartas en juego.
	print("Cartas del jugador: ", board.player_board_play.get_children())
	print("Cartas de la IA: ", board.AIboard_play.get_children())
	var all_cards = board.player_board_play.get_children() + board.AIboard_play.get_children()
	print("Todas las cartas: ", all_cards)
	
	for card in all_cards:
		# Verificar que tenga las propiedades necesarias.
		if not ("card_name" in card and "era_name" in card and "attack" in card and "defense" in card):
			continue
		if card.discarded:
			continue
		
		# Asegurar que las cartas de IA no están marcadas como "in_hand".
		if "in_hand" in card and card.in_hand and card.get_parent() == board.AIboard_play:
			card.in_hand = false
		
		# Aumento según era.
		var sum: int
		if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
			sum = int(era.details["value_era"])
		else:
			sum = int(era.details["value_not_era"])
		
		match era.details["effect"]:
			"attack":
				# Usar el valor ya modificado si existe, sino el base.
				var current_atk = card.modified_attack if card.modified_attack != null else card.attack
				card.modified_attack = int(current_atk + sum)
				card.era_modified_attack = sum
				
				if "attack_hover" in card and card.attack_hover:
					if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
						card.attack_hover.text = "Ataque: " + str(card.attack) + " (+" + str(card.modified_attack - card.attack) + ")"
						_show_buff_color(card.attack_hover)
						_show_buff_color(card.attack_label)
					else:
						card.attack_hover.text = "Ataque: " + str(card.attack) + " (" + str(card.modified_attack - card.attack) + ")"
						_show_debuff_color(card.attack_hover)
						_show_debuff_color(card.attack_label)
					
				elif "attack_label" in card:
					if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
						_show_buff_color(card.attack_label)
					else:
						_show_debuff_color(card.attack_label)
				
				card.attack_label.text = str(card.modified_attack)
				
			"defense":
				# Usar el valor ya modificado si existe, sino el base.
				var current_defense = card.modified_defense if card.modified_defense != null else card.defense
				card.modified_defense = int(current_defense + sum)
				card.era_modified_defense = sum
				
				if "defense_hover" in card and card.defense_hover:
					if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
						card.defense_hover.text = "Def: " + str(card.defense) + " (+" + str(card.modified_defense - card.defense) + ")"
						_show_buff_color(card.defense_hover)
						_show_buff_color(card.defense_label)
					else:
						card.defense_hover.text = "Def: " + str(card.defense) + " (" + str(card.modified_defense - card.defense) + ")"
						_show_buff_color(card.defense_hover)
						_show_buff_color(card.defense_label)
					
				elif "defense_label" in card:
					if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
						_show_buff_color(card.defense_label)
					else:
						_show_debuff_color(card.defense_label)
				
				card.defense_label.text = str(card.modified_defense)
			"attack_defense":
				# Usar el valor ya modificado si existe, sino el base.
				var current_atk = card.modified_attack if card.modified_attack != null else card.attack
				card.modified_attack = int(current_atk + sum)
				card.era_modified_attack = sum
				var current_defense = card.modified_defense if card.modified_defense != null else card.defense
				card.modified_defense = int(current_defense + sum)
				card.era_modified_defense = sum
				
				if "attack_hover" in card and card.attack_hover:
					if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
						card.attack_hover.text = "Ataque: " + str(card.attack) + " (+" + str(card.modified_attack - card.attack) + ")"
						_show_buff_color(card.attack_hover)
						_show_buff_color(card.attack_label)
					else:
						card.attack_hover.text = "Ataque: " + str(card.attack) + " (" + str(card.modified_attack - card.attack) + ")"
						_show_debuff_color(card.attack_hover)
						_show_debuff_color(card.attack_label)
					
				elif "attack_label" in card:
					if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
						_show_buff_color(card.attack_label)
					else:
						_show_debuff_color(card.attack_label)
				
				card.attack_label.text = str(card.modified_attack)
				
				if "defense_hover" in card and card.defense_hover:
					if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
						card.defense_hover.text = "Def: " + str(card.defense) + " (+" + str(card.modified_defense - card.defense) + ")"
						_show_buff_color(card.defense_hover)
						_show_buff_color(card.defense_label)
					else:
						card.defense_hover.text = "Def: " + str(card.defense) + " (" + str(card.modified_defense - card.defense) + ")"
						_show_buff_color(card.defense_hover)
						_show_buff_color(card.defense_label)
					
				elif "defense_label" in card:
					if card.era_name.strip_edges().to_lower() == era.name_era.strip_edges().to_lower():
						_show_buff_color(card.defense_label)
					else:
						_show_debuff_color(card.defense_label)
				
				card.defense_label.text = str(card.modified_defense)
		
		print("%s modificado por %s: atk=%d, def=%d" % [card.card_name, era.name_era, card.modified_attack, card.modified_defense])


# Retirar efecto de la era anterior.
func remove_era_effect(era) -> void:
	if not era:
		return
	var board = get_tree().current_scene
	if not board:
		return
	
	var all_cards = board.player_board_play.get_children() + board.AIboard_play.get_children()
	for card in all_cards:
		# Verificar que tenga las propiedades necesarias.
		if not ("card_name" in card and "era_name" in card and "attack" in card and "defense" in card):
			continue
		if card.discarded:
			continue
		
		# Asegurar que las cartas de IA no están marcadas como "in_hand".
		if "in_hand" in card and card.in_hand and card.get_parent() == board.AIboard_play:
			card.in_hand = false
		
		var current_atk = card.modified_attack if card.modified_attack != null else card.attack
		var current_defense = card.modified_defense if card.modified_defense != null else card.defense
		var current_era_atk = card.era_modified_attack if card.era_modified_attack != null else 0
		var current_era_defense = card.era_modified_defense if card.era_modified_defense != null else 0
		# Quitar las modificaciones de esta era.
		card.modified_attack = current_atk - current_era_atk
		card.modified_defense = current_defense - current_era_defense

		# UI
		if card.attack_label:
			card.attack_label.text = str(card.modified_attack)
			_return_color(card.attack_label)
		if "attack_hover" in card:
			card.attack_hover.text = "Ataque: " + str(card.attack)
			_return_color(card.attack_hover)

		if card.defense_label:
			card.defense_label.text = str(card.modified_defense)
			_return_color(card.defense_label)
		if "defense_hover" in card:
			card.defense_hover.text = "Def: " + str(card.defense)
			_return_color(card.defense_hover)
		
		card.era_modified_attack = 0
		card.era_modified_defense = 0


	print("Efecto de la era retirado correctamente: ", era.name_era)
	active_era = null

# Mostrar color del aumento.
func _show_buff_color(stat_label: Label):
	var t = create_tween()
	t.tween_property(stat_label, "modulate", Color(0.5, 1, 0.5, 1), 0.2)

func _show_debuff_color(stat_label: Label):
	var t = create_tween()
	t.tween_property(stat_label, "modulate", Color(0.7, 1, 0.7, 1), 0.2)

func _return_color(stat_normal: Label):
	var t = create_tween()
	t.tween_property(stat_normal, "modulate", Color(1, 1, 1, 1), 0.2)
