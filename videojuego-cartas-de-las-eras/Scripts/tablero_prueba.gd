extends Node2D

@onready var player_hand = $mano
@onready var btn_add = $UI/pone
@onready var btn_remove = $UI/descarta
@onready var btn_reset = $UI/reinicia

var cards = preload("res://Scenes/carta_prueba.tscn")

# Mantener ángulo total del abanico para consistencia visual.
var last_total_angle: float = 0.0

func _on_btn_add_pressed():
	var card = cards.instantiate()
	# Darle un texto identificador.
	card.text = "Carta " + str(player_hand.get_child_count() + 1)
	player_hand.add_child(card)
	organize_hand()

func _on_btn_remove_pressed():
	if player_hand.get_child_count() > 0:
		var last_card = player_hand.get_child(player_hand.get_child_count() - 1)
		discard_card(last_card)
	else:
		print("No hay cartas para descartar.")

func _on_btn_reset_pressed():
	for p in player_hand.get_children():
		p.queue_free()
	organize_hand()

func discard_card(card:Node):
	card.queue_free()
	organize_hand()

# Organiza la mano del jugador en abanico.
func organize_hand(animated: bool=false):
	var total = player_hand.get_child_count()
	if total == 0:
		return

	var card_width = 100.0
	var base_spacing = 80.0
	var max_width = 500.0

	# Calcular separación horizontal.
	var needed_width = (total - 1) * base_spacing
	var spacing = base_spacing
	if needed_width > max_width and total > 1:
		spacing = max_width / (total - 1)

	# Calcular ángulo del abanico.
	var total_angle = last_total_angle
	if total_angle == 0.0:
		total_angle = min(40.0, total * 7.0)
	var initial_angle = -total_angle / 2.0

	var curve_height = 25.0
	var max_angle = 15.0

	for i in range(total):
		var card = player_hand.get_child(i)
		
		# Evitar división por cero si solo hay una carta.
		var t = 0.5
		if total > 1:
			t = float(i) / float(total - 1)
		
		var x = (i - (total - 1)/2.0) * spacing
		
		var y = 0.0
		if total > 1:
			y = -sin(t * PI) * curve_height  # Solo si hay varias cartas.
		
		var rot = 0.0
		if total > 1:
			rot = (t - 0.5) * 2 * max_angle  # Solo si hay varias cartas.
		
		if animated:
			var tween = create_tween()
			tween.tween_property(card, "position", Vector2(x, y), 0.3)
			tween.tween_property(card, "rotation_degrees", rot, 0.3)
		else:
			card.position = Vector2(x, y)
			card.rotation_degrees = rot


	# Guardar ángulo usado para mantener consistencia.
	last_total_angle = total_angle
