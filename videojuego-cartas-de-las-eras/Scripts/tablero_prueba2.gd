extends Node2D

@onready var player_hand = $mano
@onready var deck = $baraja

var last_total_angle: float = 0.0
var start_draw: int = 7

func _ready() -> void:
	# Esperar un frame para asegurar que todo esté cargado
	await get_tree().process_frame
	draw_starting_hand(start_draw)

# Repartir n cartas desde la baraja
func draw_starting_hand(n: int):
	for i in range(n):
		var card = deck.draw_card()
		if card:
			# Poner la carta sobre el mazo.
			card.position = deck.position
			add_child(card) # Añadir temporalmente al tablero para animación,
			
			# Tween animado hacia la mano
			var target_pos = get_card_target_position(player_hand.get_child_count(), card)
			var target_rot = get_card_target_rotation(player_hand.get_child_count())
			
			var tween = create_tween()
			tween.tween_property(card, "position", target_pos, 0.3)
			tween.tween_property(card, "rotation_degrees", target_rot, 0.3)
			
			# Esperar a que la animación acabe antes de añadirla a la mano
			await tween.finished
			
			# Pasar la carta a player_hand (local)
			card.position = player_hand.to_local(card.position)
			player_hand.add_child(card)
			
			# Reorganizar la mano en abanico
			organize_hand()

# Calcular posición final de una carta según el abanico
func get_card_target_position(index: int, card: Node) -> Vector2:
	var total = player_hand.get_child_count() + 1
	var base_spacing = 80.0
	var max_width = 500.0
	var spacing = base_spacing
	if (total - 1) * base_spacing > max_width:
		spacing = max_width / (total - 1)
	var t = 0.5
	if total > 1:
		t = float(index) / float(total - 1)
	var x = (index - (total - 1)/2.0) * spacing
	var y = -sin(t * PI) * 25.0
	return player_hand.to_global(Vector2(x, y))

# Calcular rotación de la carta en abanico
func get_card_target_rotation(index: int) -> float:
	var total = player_hand.get_child_count() + 1
	var max_angle = 15.0
	var t = 0.5
	if total > 1:
		t = float(index) / float(total - 1)
	return (t - 0.5) * 2 * max_angle

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
