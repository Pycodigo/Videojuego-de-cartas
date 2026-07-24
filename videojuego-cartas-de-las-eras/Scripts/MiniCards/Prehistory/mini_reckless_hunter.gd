extends "res://Scripts/MiniCards/mini_base_card.gd"

func _ready() -> void:
	mini_card_color = "#402a0ed2"
	era_color = "#7a3111"
	card_name = "CARD_RECKLESS_HUNTER_NAME"
	card_img = preload("res://Images/Prehistory/hunter.png")
	card_type = "UI_CARD_TYPE_BASIC"
	era_name = "CARD_PREHISTORY_ERA"
	ability_name = "CARD_RECKLESS_HUNTER_ABILITY"
	ability_type = "CARD_ABILITY_ACTIVE_TYPE"
	max_hp = 13
	energy_cost = 3
	attack = 15
	defense = 2
	cooldown = 1
	
	# Ejecutar la inicialización de la base.
	super._ready()
