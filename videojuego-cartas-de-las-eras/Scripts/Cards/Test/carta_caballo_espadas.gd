extends "res://Scripts/carta_normal_base_prueba.gd"

func _ready() -> void:
	card_name = "Caballo de espadas"
	era_type = "M"
	texture = preload("res://Images/test/caballo.jpg")
	max_health = 120
	cost = 2
	attack = 9
	defense = 9
	ability = {
		"name": "Espíritu guerrero",
		"type": "stat_mod",  # Tipo de habilidad.
		"stat": "defense", # Stat que modifica.
		"value": 1, # Cantidad.
		"target": "self", # Objetivo.
		"activation": "auto", # Activación automática.
		"trigger": "on_damage" # Condición para activarse.
	}
	ability_detailed = "Durante el próximo turno, si\nrecibe daño directo,\n+1 de defensa"
	era_name = "Era medieval"
	
	init_card()
