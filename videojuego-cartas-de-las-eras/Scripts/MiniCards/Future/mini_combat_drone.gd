extends "res://Scripts/MiniCards/mini_base_card.gd"

func _ready() -> void:
	mini_card_color = "#220869c0"
	era_color = "#0c437d"
	card_name = "CARD_COMBAT_DRONE_NAME"
	card_img = preload("res://Images/Future/dron.png")
	card_type = "UI_CARD_TYPE_BASIC"
	era_name = "CARD_FUTURE_ERA"
	ability_name = "CARD_COMBAT_DRONE_ABILITY"
	ability_type = "CARD_ABILITY_ACTIVE_TYPE"
	max_hp = 5
	energy_cost = 2
	attack = 5
	defense = 2
	cooldown = 2
	
	# Ejecutar la inicialización de la base.
	super._ready()
