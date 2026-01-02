extends "res://Scripts/cartaIA_era_prueba.gd"

func _ready() -> void:
	name_era = "Era medieval"
	texture = preload("res://Images/test/medieval.jpg")
	max_turns = 4
	details = {
		"name": "Espíritu de hierro",
		"type": "medieval",  # Tipo de era.
		"subtype": "stat_mod", # Tipo de efecto.
		"effect": "attack_defense", # Stats que modifica (en este caso).
		"value_era": 15, # +x%.
		"value_not_era": -15, # -x% a cartas que no sean de esa era.
		"activation": "auto" # Activación automática.
	}
	_update_visuals()
	
	super._ready()  # Ejecuta el _ready del padre.
