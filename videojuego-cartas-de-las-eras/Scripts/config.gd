extends Control

@onready var language = $opc/UI_TAB_GENERAL/VBoxContainer/idioma/idioma
@onready var resolution_type = $"opc/UI_TAB_GRAPHICS/VBoxContainer/resolución/opc"
@onready var window_type = $"opc/UI_TAB_GRAPHICS/VBoxContainer/modo/ventana"

# Tamaño mínimo.
var min_width = 1024
var min_height = 600

# Lista de idiomas.
var idioms: Array[String] = [
	"UI_LANGUAGE_ES",
	"UI_LANGUAGE_EN",
	"UI_LANGUAGE_GL"
]

# Claves de idioma.
var locales: Array[String] = [
	"es",
	"en",
	"gl"
]

# Lista de resoluciones disponibles.
var resolutions = [
	Vector2i(1024, 600),
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

# Modos de ventana.
const window_mode: Array[String] = [
	"UI_WINDOW_BORDERED",
	"UI_WINDOW_BORDERLESS"
]

func _ready() -> void:
	# Iniciar música.
	$MenuChill.play(Global.music)
	
	# Idiomas.
	for idiom in idioms:
		language.add_item(idiom)
	
	var current = locales.find(TranslationServer.get_locale())
	if current != -1:
		language.select(current)
	
	# Resoluciones.
	for res in resolutions:
		resolution_type.add_item(str(res.x) + "x" + str(res.y))
	
	# Seleccionar la resolución guardada.
	var saved_res = GlobalConfigFile.config.get_value("settings", "resolution", Vector2i(1280, 720))
	var res_index = resolutions.find(saved_res)
	if res_index != -1:
		resolution_type.select(res_index)
	
	# Modos de ventana
	for mode in window_mode:
		window_type.add_item(mode)
	
	# Seleccionar el modo guardado.
	var saved_mode = GlobalConfigFile.config.get_value("settings", "window_mode", 0)
	window_type.select(saved_mode)
	
	# Aplicar estado inicial de pantalla completa.
	var is_fullscreen = GlobalConfigFile.config.get_value("settings", "fullscreen", false)
	$"opc/UI_TAB_GRAPHICS/VBoxContainer/completo/CheckButtonFullScreen".button_pressed = is_fullscreen


func _on_idioma_item_selected(index: int) -> void:
	GlobalConfigFile.set_locale(locales[index])

func _on_opc_item_selected(index: int) -> void:
	GlobalConfigFile.set_resolution(resolutions[index])

func _on_vindow_item_selected(mode: int) -> void:
	GlobalConfigFile.set_window_mode(mode)

func _on_check_button_v_sync_toggled(toggled_on: bool) -> void:
	GlobalConfigFile.set_vsync(toggled_on)

func _on_check_button_full_screen_toggled(toggled_on: bool) -> void:
	GlobalConfigFile.set_fullscreen(toggled_on)
	resolution_type.disabled = toggled_on
	window_type.disabled = toggled_on

func _on_btn_test_pressed() -> void:
	$ButtonSound.play()

func _on_back_btn_pressed() -> void:
	# Volver desde configuración.
	$"ButtonSound".play()
	await $"ButtonSound".finished
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	Global.music = $"MenuChill".get_playback_position()
