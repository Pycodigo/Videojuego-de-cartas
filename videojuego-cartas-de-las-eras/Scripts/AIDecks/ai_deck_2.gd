extends "res://Scripts/base_ai_deck.gd"

func _ready() -> void:
	card_scenes = [
		preload("res://Scenes/Cards/Future/combat_drone.tscn"),
	]
	
	# Ejecutar la inicialización de la base.
	super._ready()
