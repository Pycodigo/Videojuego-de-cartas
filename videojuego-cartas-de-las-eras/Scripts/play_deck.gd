extends Node

#Aquí se guarda temporalmente la baraja que el usuario quiere usar.

var deck_id: float = 0.0
var deck_selected: bool = false

func set_actual_deck(data_id: float) -> void:
	deck_id = data_id
	deck_selected = true

func clear_actual_deck() -> void:
	deck_id = 0.0 # Vacío.
	deck_selected = false
