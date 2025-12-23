extends "res://Scripts/carta_normal_base_prueba.gd"

func _ready() -> void:
	card_name = "Rey de espadas"
	era_type = "F"
	texture = preload("res://Images/test/rey.jpg")
	max_health = 2
	cost = 4
	attack = 10
	defense = 5
	ability = {
		"name": "Espíritu de Rey",
		"type": "stat_mod",  # Tipo de habilidad.
		"stat": "attack", # Stat que modifica.
		"value": 20, # +x%.
		"target": "allies", # Objetivo.
		"activation": "manual" # Activación manual.
	}
	ability_detailed = "El rey ofrece +20% de ataque\na sus aliados"
	era_name = "Era futurista"
	
	init_card()
