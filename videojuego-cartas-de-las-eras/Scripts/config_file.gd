extends Node

# Reescribe el archivo de configuración.
var config = ConfigFile.new()
# Ruta del archivo de configuración.
const SETTINGS_FILE_PATH = "user://config.cfg"

func _ready() -> void:
	load_settings()

# Guardar.
func save_settings() -> void:
	config.save(SETTINGS_FILE_PATH)

# Cargar.
func load_settings() -> void:
	if config.load(SETTINGS_FILE_PATH) == OK:
		apply_settings()

# Aplicar al iniciar.
func apply_settings() -> void:
	# Idioma.
	var locale = config.get_value("settings", "locale", "es")
	TranslationServer.set_locale(locale)
	
	# FPS.
	var fps = config.get_value("settings", "fps", 60)
	Engine.max_fps = fps
	
	# VSync.
	var vsync = config.get_value("settings", "vsync", true)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
	
	# IMPORTANTE el orden.
	set_all_resolution()
	
	# Audio.
	for bus in ["Master", "Music", "SFX"]:
		var volume = config.get_value("audio", bus, 1.0)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(bus),
			linear_to_db(volume)
		)
	
	print("Tamaño aplicado en apply_settings: ", DisplayServer.window_get_size())

# Setters (llamados desde config.gd)
func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	config.set_value("settings", "locale", locale)
	save_settings()

func set_fullscreen(enabled: bool) -> void:
	config.set_value("settings", "fullscreen", enabled)
	set_all_resolution()
	save_settings()

func set_vsync(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)
	config.set_value("settings", "vsync", enabled)
	save_settings()

func set_resolution(res: Vector2i) -> void:
	config.set_value("settings", "resolution", res)
	set_all_resolution()
	save_settings()

func set_window_mode(mode: int) -> void:
	config.set_value("settings", "window_mode", mode)
	set_all_resolution()
	save_settings()

func set_music_master(volume: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))
	config.set_value("settings", "music_volume", volume)
	save_settings()

# Mini función para aplicar las resoluciones (útil para solucionar lo de pantalla completa).
func set_all_resolution() -> void:
	# Pantalla completa.
	var fullscreen = config.get_value("settings", "fullscreen", false)
	# Modo de ventana.
	var mode = config.get_value("settings", "window_mode", 0)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		match mode:
			0:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			1:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	print("Tamaño tras aplicar modo de ventana: ", DisplayServer.window_get_size())
	
	# Resolución.
	var res = config.get_value("settings", "resolution", Vector2i(1280, 720))
	DisplayServer.window_set_size(res)
	print("Resolución que voy a aplicar: ", res)
