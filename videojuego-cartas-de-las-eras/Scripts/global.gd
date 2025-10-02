extends Node

var music = 0.0

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



func select_attack_target(target_card: Panel):
	if not attack_mode:
		return
	attack_target = target_card
	_show_attack_indicator(attacking_card, attack_target)
	# Aplicar ataque.
	_execute_attack()

func _show_attack_indicator(attacker: Panel, target: Panel):
	print(attacker.card_name, " ataca a ", target.card_name, " oponente.")

func _execute_attack():
	if attacking_card and attack_target:
		attack_target.take_damage(attacking_card.attack - attack_target.defense)
		# Cambiar el color de la carta a normal en 1 segundo.
		var tween = create_tween()
		tween.tween_property(attacking_card.front_texture, "modulate", Color(1,1,1,1), 1.0)
		await tween.finished
	# Limpiar modo ataque.
	attack_mode = false
	attacking_card = null
	attack_target = null
