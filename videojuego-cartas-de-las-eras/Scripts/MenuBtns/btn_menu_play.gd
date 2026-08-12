extends "res://Scripts/MenuBtns/btn_menu_base.gd"

func _ready() -> void:
	btn_menu_name = "UI_PLAY"
	btn_path = "res://Scenes/your_decks.tscn"
	btn_is_exit = false
	btn_want_select = true
	
	# Ejecutar la inicialización de la base.
	super._ready()
