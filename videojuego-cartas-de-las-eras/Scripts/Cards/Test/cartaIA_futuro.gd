extends "res://Scripts/cartaIA_era_prueba.gd"

func _ready() -> void:
	name_era = "Era futurista"
	texture = preload("res://Images/test/futuro.jpg")
	max_turns = 3
	details = {
		"name": "Hackeo masivo",
		"type": "future",  # Tipo de era.
		"subtype": "stat_mod", # Tipo de efecto.
		"effect": "defense", # Stats que modifica (en este caso).
		"value_era": 3, # +cantidad.
		"value_not_era": -3, # -cantidad a cartas que no sean de esa era.
		"activation": "auto" # Activación automática.
	}
	
	_update_visuals()
	
	super._ready()  # Ejecuta el _ready del padre.
