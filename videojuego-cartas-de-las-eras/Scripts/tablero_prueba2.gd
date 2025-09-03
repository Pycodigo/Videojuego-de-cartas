extends Node2D

@onready var player_hand = $mano
@onready var deck = $baraja

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
			
			# Poner la mano en abanico.
			organize_hand()
			
			# Pausa entre robos para efecto visual.
			await get_tree().create_timer(0.2).timeout

# Organiza la mano del jugador en abanico.
func organize_hand(animated: bool=true):
	var total = player_hand.get_child_count()
	if total == 0:
		return

	var card_width = 100.0
	var base_spacing = 80.0
	var max_width = 500.0

	# Separación horizontal limitada
	var spacing = base_spacing
	if total > 1 and (total - 1) * base_spacing > max_width:
		spacing = max_width / (total - 1)

	var total_angle = last_total_angle
	if total_angle == 0.0:
		total_angle = min(40.0, total * 7.0)
	var initial_angle = -total_angle / 2.0

	var curve_height = 25.0
	var max_angle = 15.0

	for i in range(total):
		var card = player_hand.get_child(i)
		var t = 0.5
		if total > 1:
			t = float(i) / float(total - 1)

		var x = (i - (total - 1)/2.0) * spacing
		var y = 0.0
		if total > 1:
			y = -sin(t * PI) * curve_height

		var rot = 0.0
		if total > 1:
			rot = (t - 0.5) * 2 * max_angle

		if animated:
			var tween = create_tween()
			tween.tween_property(card, "position", Vector2(x, y), 0.3)
			tween.tween_property(card, "rotation_degrees", rot, 0.3)
		else:
			card.position = Vector2(x, y)
			card.rotation_degrees = rot

	last_total_angle = total_angle
