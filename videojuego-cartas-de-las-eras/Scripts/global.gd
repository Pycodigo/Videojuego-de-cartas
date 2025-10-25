extends Node

var music = 0.0

# Ataque.
var attack_mode: bool = false
var attacking_card: Panel = null  # Carta que va a atacar.
var attack_target: Panel = null   # Carta enemiga seleccionada.

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


# Aplicar habilidad.
func apply_ability(card: Card, ability: Dictionary):
	if ability.is_empty():
		print("La carta ", card.card_name, " no tiene habilidad.")
		return
	
	if ability.type == "stat_mod":
		_apply_stat_mod(card, ability)

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

		if ability.stat == "attack":
			c.modified_attack = int(c.attack * stat_change)
			if c.attack_hover:  # Evitar errores si no existe.
				c.attack_hover.text = "Ataque: " + str(c.attack) + " (+" + str(ability.value) + "%)"
				_show_buff_color(c.attack_hover)
		elif ability.stat == "defense":
			c.modified_defense = int(c.defense * stat_change)
			if c.defense_hover:  # Evitar errores si no existe.
				c.defense_hover.text = "Def: " + str(c.defense) + " (+" + str(ability.value) + "%)"
				_show_buff_color(c.defense_hover)
		
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

# Mostrar color del bufo.
func _show_buff_color(stat_label: Label):
	var t = create_tween()
	t.tween_property(stat_label, "modulate", Color(0.5, 1, 0.5, 1), 0.2)
