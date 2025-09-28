extends "res://Scripts/cartaIA_normal_base_prueba.gd"

func _ready() -> void:
	card_name = "Rey de espadas"
	texture = preload("res://Images/test/rey.jpg")
	max_health = 150
	cost = 4
	attack = 10
	defense = 5
	ability = "Espíritu de Rey"
	
	init_card()
