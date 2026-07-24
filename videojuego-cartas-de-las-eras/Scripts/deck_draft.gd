extends Node

'''Aquí se guarda temporalmente la última baraja actual.
Sirve para que deck_builder_2.tscn pueda ver y mantener los datos de la baraja 
que se pusieron en la anterior escena. Así, si no se confirma, se descarta.'''

var current_deck: Dictionary = {}
var has_draft: bool = false

func set_draft(data: Dictionary) -> void:
	current_deck = data
	has_draft = true

func clear_draft() -> void:
	current_deck = {} # Vacío.
	has_draft = false
