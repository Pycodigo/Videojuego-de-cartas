extends "res://Scripts/cartaIA_normal_base_prueba.gd"

func _ready() -> void:
	card_name = "Caballo de espadas"
	era_type = "M"
	texture = preload("res://Images/test/caballo.jpg")
	max_health = 120
	cost = 2
	attack = 9
	defense = 9
	ability = "Espíritu guerrero"
	
	init_card()
	era_name = "Era medieval"
