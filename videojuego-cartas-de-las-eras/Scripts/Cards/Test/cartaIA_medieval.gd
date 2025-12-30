extends "res://Scripts/cartaIA_era_prueba.gd"

func _ready() -> void:
	name_era = "Era medieval"
	texture = preload("res://Images/test/medieval.jpg")
	max_turns = 4
	
	_update_visuals()
	
	super._ready()  # Ejecuta el _ready del padre.
