extends Control

signal card_placed(card)

# Saber si el slot recibe cartas del jugador o IA.
enum SlotOwner {
	PLAYER,
	AI
}
# Tipos de cartas que van en algunos slots.
enum SlotType {
	BASIC,
	ERA
}
@export var slot_owner: SlotOwner
@export var slot_type: SlotType

var occupied: bool = false
# Carta que ocupa el slot (null si está libre).
var current_card = null

func _ready() -> void:
	add_to_group("slots")

func try_place_card(card) -> bool:
	if occupied:
		return false
	# Comprobar que en el slot para las eras no se metan cartas básicas y viceversa.
	if card.is_era_type and slot_type != SlotType.ERA:
		return false
	if not card.is_era_type and slot_type != SlotType.BASIC:
		return false
	
	if card.is_in_ai and slot_owner != SlotOwner.AI:
		return false
	if not card.is_in_ai and slot_owner != SlotOwner.PLAYER:
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
