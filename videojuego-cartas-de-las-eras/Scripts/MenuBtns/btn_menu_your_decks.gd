extends "res://Scripts/MenuBtns/btn_menu_base.gd"

func _ready() -> void:
	btn_menu_name = "UI_YOUR_DECKS"
	btn_path = "res://Scenes/your_decks.tscn"
	btn_is_exit = false
	want_select = false
	
	# Ejecutar la inicialización de la base.
	super._ready()
