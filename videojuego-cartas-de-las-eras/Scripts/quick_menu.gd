extends Control

# Nodos del menú rápido.
@onready var quick_menu_panel = $QuickMenuPanel

# Menú se mostró.
var quick_menu_showed: bool = false
# Evitar solapar animaciones.
var finish_animation: bool = true
# Posiciones.
var original_position_quick_menu

func _ready() -> void:
	original_position_quick_menu = quick_menu_panel.position.x



# Al pulsar click izquierdo, mostrar todo el menú rápido.
func _on_quick_menu_panel_gui_input(event: InputEvent) -> void:
	if quick_menu_showed:
		return
	
	var tween = create_tween()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Ponerlo por encima.
			quick_menu_panel.z_index = 1
			tween.tween_property(quick_menu_panel, "position:x", quick_menu_panel.position.x - 400, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			await tween.finished
			quick_menu_showed = true
			# Bloquear todo lo demás que no sea el menú rápido.
			mouse_filter = Control.MOUSE_FILTER_STOP

# Pulsar fuera del panel y solo cuando está el menú puesto.
func _on_gui_input(event: InputEvent) -> void:
	if not quick_menu_showed:
		return
	var tween = create_tween()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			tween.tween_property(quick_menu_panel, "position:x", original_position_quick_menu, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			quick_menu_showed = false
			await tween.finished
			# Ponerlo por debajo.
			quick_menu_panel.z_index = 0
			# Dejarlo como estaba.
			mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_btn_home_pressed() -> void:
	if quick_menu_showed:
		get_tree().change_scene_to_file("res://Scenes/main.tscn")


func _on_btn_config_pressed() -> void:
	if quick_menu_showed:
		get_tree().change_scene_to_file("res://Scenes/config.tscn")


func _on_btn_rules_pressed() -> void:
	pass # Replace with function body.


func _on_btn_deck_builder_pressed() -> void:
	if quick_menu_showed:
		get_tree().change_scene_to_file("res://Scenes/deck_builder.tscn")


func _on_btn_your_decks_pressed() -> void:
	if quick_menu_showed:
		Global.want_to_select = false
		get_tree().change_scene_to_file("res://Scenes/your_decks.tscn")


func _on_btn_exit_pressed() -> void:
	if quick_menu_showed:
		get_tree().quit()
