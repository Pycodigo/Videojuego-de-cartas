extends "res://Scripts/MenuBtns/btn_menu_base.gd"

func _ready() -> void:
	btn_menu_name = "UI_EXIT"
	btn_path = ""
	btn_is_exit = true
	
	# Ejecutar la inicialización de la base.
	super._ready()
