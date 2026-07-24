extends Control

# Contenedor de las barajas.
@onready var deck_container: GridContainer = $ScrollContainer/DeckContainer

func _ready() -> void:
	_load_all_decks()

func _load_all_decks() -> void:
	# Limpiar el contenedor por si se vuelve a llamar.
	for deck in deck_container.get_children():
		deck.queue_free()
	
	# Cargar una vez la escena de baraja.
	var deck_scene := preload("res://Scenes/user_deck.tscn")
	
	# Ir a la carpeta del usuario.
	var dir := DirAccess.open("user://UserDecks")
	# Avisar si no existe.
	if dir == null:
		push_warning("No existe la carpeta UserDecks.")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_add_deck_panel(deck_scene, "user://UserDecks/" + file_name)
			file_name = dir.get_next()
	
	dir.list_dir_end()

func _add_deck_panel(deck_scene: PackedScene, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		return
	
	# Instancia nueva por cada JSON creado.
	var panel := deck_scene.instantiate()
	deck_container.add_child(panel)
	panel.deck_setup(data)
	panel.edit_requested.connect(_on_deck_edit_requested)

func _on_deck_edit_requested(deck_data: Dictionary) -> void:
	# Enviamos los datos de la baraja al 'borrador'.
	DeckDraft.set_draft(deck_data)
	get_tree().change_scene_to_file("res://Scenes/deck_builder.tscn")


func _on_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
