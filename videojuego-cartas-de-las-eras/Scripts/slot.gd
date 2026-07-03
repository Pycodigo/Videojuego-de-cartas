extends Control

signal card_placed(card)

# Tipo de carta que acepta este slot. Vacío = acepta cualquiera.
@export var accepted_card_type: String = ""

var occupied: bool = false
# Carta que ocupa el slot (null si está libre).
var current_card = null

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
	current_card = card
	card_placed.emit(card)
	print("Carta colocada: ", card.card_name)
	return true

# Llamar cuando la carta es removida o eliminada. Libera dicho slot.
func remove_card() -> void:
	if not occupied:
		return
	
	var card = current_card
	occupied = false
	current_card = null
	card_placed.emit(card)

func contains_point(point: Vector2) -> bool:
	# Área de la colisión para las cartas.
	return get_global_rect().has_point(point)
