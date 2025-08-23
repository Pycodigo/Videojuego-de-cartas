extends Control

@onready var resolution_type = $"opc/Gráficos/resolución/opc"
@onready var window_mode = $"opc/Gráficos/modo/ventana"

# Tamaño mínimo.
var min_width = 1024
var min_height = 600

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
	# Llenar las opciones.
	for res in resolutions:
		resolution_type.add_item(str(res.x) + "x" + str(res.y))
	
	for mode in window_modes:
		window_mode.add_item(mode)
	
	# Desactivar resolución si estamos en pantalla completa, incluso al volver.
	resolution_type.disabled = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_opc_item_selected(index: int) -> void:
	var res = resolutions[index]
	
	# Forzar tamaño mínimo.
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
