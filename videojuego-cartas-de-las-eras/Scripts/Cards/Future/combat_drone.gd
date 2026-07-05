extends "res://Scripts/Cards/base_card.gd"

func _ready() -> void:
	card_name = "CARD_COMBAT_DRONE_NAME"
	era_name = "CARD_FUTURE_ERA"
	ability = {
		"name": "CARD_COMBAT_DRONE_ABILITY",
		"state": "CARD_ABILITY_ACTIVE_TYPE",
		"description": "CARD_COMBAT_DRONE_ABILITY_DESCRIPTION",
	}
	max_hp = 5
	current_hp = 5
	energy_cost = 2
	attack = 5
	defense = 2
	cooldown = 2
	
	# Ejecutar la inicialización de la base.
	super._ready()
