extends Node2D

@onready var player_hand = $mano
@onready var deck = $baraja
@onready var slots = [$huecos/hueco, $huecos/hueco2, $huecos/hueco3]

var last_total_angle: float = 0.0
var start_draw: int = 7

func _ready() -> void:
	# Esperar un frame para asegurar que todo esté cargado.
	await get_tree().process_frame
	draw_starting_hand(start_draw)

# Repartir n cartas desde la baraja.
func draw_starting_hand(n: int):
	for i in range(n):
		var card = deck.draw_card()
		if card:
			# Guardar posición global de la baraja.
			var start_pos = deck.global_position
			player_hand.add_child(card)
			card.global_position = start_pos  # Colocar sobre la baraja.
			card.original_position = card.position # Guardar posición.
			card.board = self  # Pasar referencia.
			
			# Poner la mano en abanico.
			organize_hand()
			
			# Pausa entre robos para efecto visual.
			await get_tree().create_timer(0.15).timeout

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

func try_place_card(card) -> bool:
	var closest_slot = null
	var min_dist = 999999
	var threshold = 50.0

	for slot in slots:
		var dist = card.global_position.distance_to(slot.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_slot = slot

	if closest_slot and min_dist <= threshold:
		var tween = create_tween()
		tween.tween_property(card, "global_position", closest_slot.global_position, 0.3)
		card.dragging = false
		card.is_dragged = true
		return true

	return false
