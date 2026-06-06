extends HSlider

@export var bus_name: String

var bus_index: int

func _ready() -> void:
	# Detectar tipo de sonido.
	bus_index = AudioServer.get_bus_index(bus_name)
	value_changed.connect(_on_value_changed)
	
	# Cargar valor guardado, si no hay usa 1.0 (volumen máximo).
	value = GlobalConfigFile.config.get_value("audio", bus_name, 1.0)
	
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))


func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(value) #Convierte a decibelios.
	)
	# Guardar con el nombre del bus como clave.
	GlobalConfigFile.config.set_value("audio", bus_name, value)
	GlobalConfigFile.save_settings()
