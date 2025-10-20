extends "res://Scripts/carta_normal_base_prueba.gd"

func _ready() -> void:
	card_name = "Rey de espadas"
	texture = preload("res://Images/test/rey.jpg")
	max_health = 150
	cost = 4
	attack = 2000
	defense = 5
	ability = {
		"name": "Espíritu de Rey",
		"type": "stat_mod",  # Tipo de habilidad.
		"stat": "defense", # Stat que modifica.
		"value": 20, # +x%.
		"target": "allies", # Objetivo.
		"activation": "manual" # Activación manual.
	}
	ability_detailed = "El rey ofrece +20% de ataque\na sus aliados"
	
	init_card()
