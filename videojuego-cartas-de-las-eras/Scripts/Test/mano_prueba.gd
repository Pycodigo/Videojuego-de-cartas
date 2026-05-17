extends Node2D

@onready var player_hand = $mano
@onready var btn_add = $UI/pone
@onready var btn_remove = $UI/descarta
@onready var btn_reset = $UI/reinicia

var cards = preload("res://Scenes/carta_prueba.tscn")

# Guardar y mantener ángulo total del abanico para consistencia visual.
var last_total_angle: float = 0.0

func _on_btn_add_pressed():
	var card = cards.instantiate()
	# Darle un texto identificador.
	card.text = "Carta " + str(player_hand.get_child_count() + 1)
	# Añadir carta a la mano.
	player_hand.add_child(card)
	organize_hand()

func _on_btn_remove_pressed():
	# Comprobar si hay cartas en la mano.
	if player_hand.get_child_count() > 0:
		# Pillar la última.
		var last_card = player_hand.get_child(player_hand.get_child_count() - 1)
		discard_card(last_card)
	else:
		print("No hay cartas para descartar.")

func _on_btn_reset_pressed():
	for p in player_hand.get_children():
		p.queue_free()
	organize_hand()

func discard_card(card:Node, animated: bool = true):
	card.queue_free()
	var children = player_hand.get_children()
	var total = children.size()
	
	# Guardar posiciones actuales.
	var current_positions = []
	for c in children:
		current_positions.append(c.position)

	# Quitar la carta.
	card.queue_free()
	total -= 1  # Nuevo total tras eliminar.

	# Calcular separación horizontal.
	var base_spacing = 80.0 # Distancia ideal entre cartas.
	var max_width = 500.0
	var spacing = base_spacing
	if total > 1 and (total - 1) * base_spacing > max_width:
		spacing = max_width / (total - 1)

	# Animar cartas restantes a su nueva posición y rotación.
	for i in range(total):
		var c = player_hand.get_child(i)
		var target_x = (i - (total - 1)/2.0) * spacing # Centrar las cartas horizontalmente. 
		# La carta del medio queda en x=0.
		var target_y = -sin(float(i) / float(max(total-1,1)) * PI) * 25.0
		# Rotar las cartas suavemente hacia los extremos para simular un abanico.
		var target_rot = (float(i)/float(max(total-1,1)) - 0.5) * 2 * 15.0

		var tween = create_tween()
		tween.tween_property(c, "position", Vector2(target_x, target_y), 0.3)
		tween.tween_property(c, "rotation_degrees", target_rot, 0.3)
		
	# Esperar a que el tween termine.
	await get_tree().process_frame  # Esperar mínimo un frame para que el tween se cree.
	
	# Reajustar la mano.
	organize_hand()

# Organiza la mano del jugador en abanico.
func organize_hand(animated: bool=true):
	# Obtener toda la mano actual del jugador.
	var total = player_hand.get_child_count()
	if total == 0:
		return # Salir si no hay cartas.

	var card_width = 100.0
	var base_spacing = 80.0 # Distancia entre cartas.
	var max_width = 500.0

	# Calcular separación horizontal.
	var needed_width = (total - 1) * base_spacing
	var spacing = base_spacing
	if needed_width > max_width and total > 1:
		spacing = max_width / (total - 1) # Reducir la separación.

	# Calcular ángulo del abanico.
	var total_angle = last_total_angle
	if total_angle == 0.0:
		total_angle = min(40.0, total * 7.0)
	var initial_angle = -total_angle / 2.0

	var curve_height = 25.0 # Altura máxima de la curva.
	var max_angle = 15.0 # Rotación máxima de la carta más extrema.

	for i in range(total):
		var card = player_hand.get_child(i)
		
		# Evitar división por cero si solo hay una carta (evita que no se muestre).
		var t = 0.5
		if total > 1:
			t = float(i) / float(total - 1)
		
		# Posición horizontal centrada respecto al medio de la mano.
		var x = (i - (total - 1)/2.0) * spacing
		
		# Altura de la curva.
		var y = 0.0
		if total > 1:
			y = -sin(t * PI) * curve_height  # Solo si hay varias cartas.
		
		# Rotación de la carta en grados.
		var rot = 0.0
		if total > 1:
			rot = (t - 0.5) * 2 * max_angle  # Solo si hay varias cartas.
		
		# Rotación suave de cartas.
		if animated:
			var tween = create_tween()
			tween.tween_property(card, "position", Vector2(x, y), 0.3)
			tween.tween_property(card, "rotation_degrees", rot, 0.3)
		else:
			card.position = Vector2(x, y)
			card.rotation_degrees = rot


	# Guardar ángulo usado para mantener consistencia.
	last_total_angle = total_angle
