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
	ERA,
	DISCARD
}
@export var slot_owner: SlotOwner
@export var slot_type: SlotType

var occupied: bool = false
# Carta que ocupa el slot (null si está libre).
var current_card = null
# Cartas descartadas.
var discarded_cards: Array = []

func _ready() -> void:
	add_to_group("slots")
	# Para que no esté por encima de las cartas.
	z_index = -1

func try_place_card(card) -> bool:
	# El descarte puede recibir múltiples cartas.
	if slot_type == SlotType.DISCARD:
		if not card.go_discard:
			return false
		
		# Comprobar propietario.
		if card.is_in_ai and slot_owner != SlotOwner.AI:
			return false
		if not card.is_in_ai and slot_owner != SlotOwner.PLAYER:
			return false
		
		discarded_cards.append(card)
		card.z_index = discarded_cards.size()
		card_placed.emit(card)
		
		print("Carta descartada: ", card.card_name)
		return true
	
	# Los slots normales solo pueden contener una carta.
	if occupied:
		return false
	
	# Comprobar tipo de carta.
	if card.is_era_type:
		if slot_type != SlotType.ERA:
			return false
	else:
		if slot_type != SlotType.BASIC:
			return false
	
	# Comprobar propietario.
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
