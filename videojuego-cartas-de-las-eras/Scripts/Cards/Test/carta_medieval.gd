extends BaseEra

func _ready() -> void:
	name_era = "Era medieval"
	texture = preload("res://Images/test/medieval.jpg")
	max_turns = 4
	effect = {
		"name": "Espíritu de hierro",
		"type": "medieval",  # Tipo de era.
		"subtype": "stat_mod", # Tipo de efecto.
		"effect": "attack_defense", # Stats que modifica (en este caso).
		"value_era": 10, # +x%.
		"value_not_era": -10, # -x% a cartas que no sean de esa era.
		"activation": "auto" # Activación automática.
	}
	effect_detailed = "Aumento 10% ataque y defensa\na cartas medievales.\nEfecto opuesto a las que no."
	
	_update_visuals()
