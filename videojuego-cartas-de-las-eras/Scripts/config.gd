extends Control

@onready var language = $opc/General/VBoxContainer/idioma/idioma
@onready var resolution_type = $"opc/Gráficos/VBoxContainer/resolución/opc"
@onready var window_mode = $"opc/Gráficos/VBoxContainer/modo/ventana"
@onready var fps_slider = $"opc/Gráficos/FPSlider"
@onready var fps_label = $"opc/Gráficos/fps_num"

# Tamaño mínimo.
var min_width = 1024
var min_height = 600

# Lista de idiomas.
var idioms: Array[String] = [
	"Español",
	"Gallego"
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
const window_modes: Array[String] = [
	"Con bordes",
	"Sin bordes",
	"Pantalla completa"
]

func _ready() -> void:
	# Iniciar música.
	$MenuChill.play(Global.music)
	
	for idiom in idioms:
		language.add_item(idiom)
	
	# Llenar las opciones.
	for res in resolutions:
		resolution_type.add_item(str(res.x) + "x" + str(res.y))
	
	for mode in window_modes:
		window_mode.add_item(mode)
	
	# Desactivar resolución si estamos en pantalla completa, incluso al volver.
	resolution_type.disabled = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Comprobar los fps del ordenador.
	print(str(Engine.get_frames_per_second()) + " fps actuales.")
	
	# Aplicar valor inicial.
	Engine.max_fps = int(fps_slider.value)
	# Mostrar en texto.
	fps_label.text = str(int(fps_slider.value))
	
	#Conectar los fps.
	fps_slider.connect("value_changed", Callable(self, "_on_fps_slider_changed"))

func _on_opc_item_selected(index: int) -> void:
	var res = resolutions[index]
	
	# Forzar tamaño elegido.
	var width = max(res.x, min_width)
	var height = max(res.y, min_height)
	
	DisplayServer.window_set_size(Vector2i(width, height))


func _on_vindow_item_selected(mode: int) -> void:
	match mode:
		0: # Con bordes.
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1: #Sin bordes.
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2: # Pantalla completa.
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			#Quitar bordes.
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	
	# Desactivar resolución si estamos en pantalla completa.
	resolution_type.disabled = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_check_button_toggled(pressed: bool) -> void:
	# Comprobar si el botón está activado.
	if pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		print("vsync activado")
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		print("vsync desactivado")


func _on_fps_slider_changed(fps_value:float) -> void:
	# Cambiar fps dinámicamente.
	Engine.max_fps = int(fps_value)
	# Mostrar el texto.
	fps_label.text = str(int(fps_value))
	print(str(Engine.get_frames_per_second()) + " fps actuales.")


func _on_btn_test_pressed() -> void:
	$ButtonSound.play()
