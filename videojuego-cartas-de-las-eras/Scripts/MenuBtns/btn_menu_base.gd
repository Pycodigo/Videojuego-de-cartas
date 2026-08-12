extends Control

# Atributos del botón.
@export var btn_menu_name: String
@export var btn_path: String
# Comprobar si es el botón de salir.
@export var btn_is_exit: bool
# Comprobar si se va a usar barajas para jugar o no.
@export var btn_want_select: bool

# Nodos del botón.
@onready var btn_menu = $BtnMenu
@onready var icon_bg = $BtnMenu/IconBG
@onready var icon_texture = $BtnMenu/IconBG/TextureIcon
@onready var menu_name_bg = $BtnMenu/NameBG
@onready var menu_name = $BtnMenu/NameBG/Name

# Ruta a la que manda el botón.
var path = ""
var is_exit = false
var want_select = false

func _ready() -> void:
	_init_btn_menu()
	# Crear animación de movimiento.
	var tween = create_tween()
	# Secuencia: centro -> izda -> centro -> dcha -> centro -> (repetir).
	tween.set_loops()
	tween.tween_property(btn_menu, "scale:x", 0.7, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(btn_menu, "rotation", deg_to_rad(-5), 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(btn_menu, "scale:x", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(btn_menu, "rotation", 0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(btn_menu, "scale:x", 0.7, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(btn_menu, "rotation", deg_to_rad(5), 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(btn_menu, "scale:x", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(btn_menu, "rotation", 0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	

func _init_btn_menu() -> void:
	menu_name.text = btn_menu_name
	path = btn_path
	is_exit = btn_is_exit
	want_select = btn_want_select


func _on_btn_menu_pressed() -> void:
	$BtnSound.play()
	await $BtnSound.finished
	get_tree().change_scene_to_file(path)
	Global.music = $MenuChill.get_playback_position()
	if is_exit:
		get_tree().quit()
	Global.want_to_select = want_select


func _on_btn_menu_mouse_entered() -> void:
	# Aumentar un poco el tamaño de la carta para destacarla.
	var tween_entered = create_tween()
	tween_entered.tween_property(btn_menu, "scale", Vector2(1.3, 1.3), 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_btn_menu_mouse_exited() -> void:
	# Devolver a tamaño original al salir.
	var tween_exit = create_tween()
	tween_exit.tween_property(btn_menu, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
