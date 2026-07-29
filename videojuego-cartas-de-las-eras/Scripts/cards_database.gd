extends Node

var card_routes: Dictionary = {}

# Llamar a la función.
func _ready() -> void:
	_build_deck_database()

func _build_deck_database() -> void:
	# Ruta de las cartas.
	var cards_path = "res://Scenes/Cards/"
	var dir = DirAccess.open(cards_path)
	if not dir:
		print("La carpeta no existe.")
		return
	# Obtener subcarpetas (Prehistory, Future...).
	var cards_dir = dir.get_directories()
	
	for dir_name in cards_dir:
		if dir_name.contains("Test"):
			continue
		
		# Ruta con subcarpetas.
		var cards_subpath = cards_path + dir_name + "/"
		var subdir = DirAccess.open(cards_subpath)
		
		if not subdir:
			continue
		# Pillar los archivos.
		var cards_subdir = subdir.get_files()
		
		for subdir_name in cards_subdir:
			# Comprobar que termine únicamente en .tscn.
			if not subdir_name.ends_with(".tscn"):
				continue
			
			var card_complete_path = cards_subpath + subdir_name
			# Cargar la ruta de la carta.
			var card_scene = load(card_complete_path)
			# Instanciarla.
			var card_node = card_scene.instantiate()
			add_child(card_node)
			print("card_name: ", card_node.card_name)
			# Guardar en el diccionario por nombre (para que Godot identifique la carta sin problemas).
			card_routes[card_node.card_name] = card_scene
			print(card_routes)
			# Liberar el nodo temporal.
			card_node.queue_free()
