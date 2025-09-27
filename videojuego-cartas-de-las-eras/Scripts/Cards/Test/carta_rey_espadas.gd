extends "res://Scripts/carta_normal_base_prueba.gd"

func _ready() -> void:
	card_name = "Rey de espadas"
	texture = preload("res://Images/test/rey.jpg")
	max_health = 150
	cost = 4
	attack = 10
	defense = 5
	ability = "Espíritu de Rey"
	ability_detailed = "El rey ofrece +20% de ataque\na sus aliados"
	
	init_card()
