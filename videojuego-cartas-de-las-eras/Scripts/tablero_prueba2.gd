extends Node2D

@onready var player_hand = $mano
@onready var deck = $baraja
@onready var card_slots = [$ranuras/ranura_prueba, $ranuras/ranura_prueba2, $ranuras/ranura_prueba3]


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
			card.original_position_global = card.global_position # Guardar posición.
			
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
		
		var local_pos = Vector2(x, y)
		var global_pos = player_hand.to_global(local_pos)
		
		if animated:
			var tween = create_tween()
			tween.tween_property(card, "global_position", global_pos, 0.3)
			tween.tween_property(card, "rotation_degrees", rot, 0.3)
			card.original_position_global = global_pos
		else:
			card.global_position = global_pos
			card.rotation_degrees = rot
			card.original_position_global = global_pos


	# Guardar ángulo usado para mantener consistencia.
	last_total_angle = total_angle
