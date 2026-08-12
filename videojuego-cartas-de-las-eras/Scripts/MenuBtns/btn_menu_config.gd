extends "res://Scripts/MenuBtns/btn_menu_base.gd"

func _ready() -> void:
	btn_menu_name = "UI_CONFIG_TITLE"
	btn_path = "res://Scenes/config.tscn"
	btn_is_exit = false
	
	# Ejecutar la inicialización de la base.
	super._ready()
