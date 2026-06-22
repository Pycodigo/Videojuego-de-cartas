extends Node2D

signal card_placed(card)

# Tipo de carta que acepta este slot. Vacío = acepta cualquiera.
@export var accepted_card_type: String = ""

var occupied: bool = false

func _ready() -> void:
	add_to_group("slots")

func try_place_card(card) -> bool:
	if occupied:
		return false
	# Si el slot tiene restricción, comprobar que la carta es del tipo correcto.
	if accepted_card_type != "" and card.card_type != accepted_card_type:
		print("Este slot solo acepta cartas de tipo: ", accepted_card_type)
		return false
	occupied = true
	card_placed.emit(card)
	print("Carta colocada: ", card.card_name)
	return true

func contains_point(point: Vector2) -> bool:
	# Área de la colisión para las cartas.
	var slot_rect = Rect2(global_position, Vector2(130, 240))
	return slot_rect.has_point(point)
