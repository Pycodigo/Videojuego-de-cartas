extends "res://Scripts/Cards/base_card.gd"

func _ready() -> void:
	card_name = "CARD_RECKLESS_HUNTER_NAME"
	era_name = "CARD_PREHISTORY_ERA"
	ability = {
		"name": "CARD_RECKLESS_HUNTER_ABILITY",
		"state": "CARD_ABILITY_ACTIVE_TYPE",
		"description": "CARD_RECKLESS_HUNTER_ABILITY_DESCRIPTION",
	}
	max_hp = 13
	current_hp = 13
	energy_cost = 3
	attack = 15
	defense = 2
	cooldown = 1
	
	
	init_card()
