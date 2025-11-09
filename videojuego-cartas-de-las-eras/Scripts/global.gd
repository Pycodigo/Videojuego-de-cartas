extends Node

var music = 0.0

# Ataque.
var attack_mode: bool = false
var attacking_card: Panel = null  # Carta que va a atacar.
var attack_target: Panel = null   # Carta enemiga seleccionada.

var active_era: Node = null

func start_attack(card: Panel):
	attack_mode = true
	attacking_card = card
	attack_target = null
	# Cambiar el color de la carta a rosa en 1 segundo.
	var tween = create_tween()
	tween.tween_property(card.front_texture, "modulate", Color(1,0,0.5,1), 1.0)
	await tween.finished

func select_attack_target(target: Node):
	print(">>> select_attack_target() llamado con: ", target.name)
	print("Modo de ataque: ", attack_mode)
	
	if not attack_mode:
		print("No estás en modo ataque, se ignora la selección.")
		return
	
	attack_target = target

	_execute_attack()

func _execute_attack():
	if not attacking_card or not attack_target:
		return
	
	var board = get_tree().current_scene
	var energy_cost = attacking_card.cost if "cost" in attacking_card else 0
	
	if not board.player_energy_bar:
		print("No existe energía.")
	else:
		board.player_energy_bar.consume_energy(energy_cost)
		print("Cantidad de energía usada por ", attacking_card.card_name, " en ataque: ", energy_cost)
	
	# Determinar ataque
	var atk = attacking_card.modified_attack if attacking_card.modified_attack != null else attacking_card.attack

	# Determinar defensa si existe.
	var def_target = 0
	if "modified_defense" in attack_target:
		def_target = attack_target.modified_defense if attack_target.modified_defense != null else attack_target.defense

	# Calcular daño
	var damage = max(atk - def_target, 0)

	# Aplicar daño
	attack_target.take_damage(damage)

	# Animación de la carta atacante
	var tween = create_tween()
	tween.tween_property(attacking_card.front_texture, "modulate", Color(1,1,1,1), 1.0)
	await tween.finished

	# Limpiar modo ataque
	attack_mode = false
	attacking_card = null
	attack_target = null
	
	# Gastar acción.
	if board.cnt_actions <= board.max_actions:
		print("Acción gastada. Te quedan ", (board.max_actions - board.cnt_actions), " acciones.")
		board.cnt_actions += 1


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
					_show_buff_color(c.attack_hover)
				break
			"defense":
				c.modified_defense = int(c.defense * stat_change)
				if c.defense_hover:  # Evitar errores si no existe.
					c.defense_hover.text = "Def: " + str(c.defense) + " (+" + str(ability.value) + "%)"
					_show_buff_color(c.defense_hover)
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
			_show_buff_color(card.attack_hover)
		if card.defense_hover:
			card.defense_hover.text = "Def: %d (%+d%%)" % [card.defense, int(round((multiplier-1)*100))]
			_show_buff_color(card.defense_hover)
		
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
