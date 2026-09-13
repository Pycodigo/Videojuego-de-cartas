extends "res://Scripts/Cards/base_card.gd"

func _ready() -> void:
	card_name = "CARD_THE_WALL_NAME"
	era_name = "CARD_ACIENT_ERA"
	ability = {
		"name": "CARD_THE_WALL_ABILITY",
		"state": "CARD_ABILITY_ACTIVE_TYPE",
		"description": "CARD_THE_WALL_ABILITY_DESCRIPTION",
	}
	max_hp = 20
	current_hp = 20
	energy_cost = 2
	base_attack = 2
	base_defense = 13
	cooldown = 2
	
	# Ejecutar la inicialización de la base.
	super._ready()
