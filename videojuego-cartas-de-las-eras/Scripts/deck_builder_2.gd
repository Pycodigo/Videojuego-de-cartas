extends Control

# Nodos.
@onready var deck_bg = $DeckBG
@onready var deck_name = $DeckBG/DeckName
@onready var deck_icon = $DeckBG/IconBG
@onready var color_deck_btn = $EditPanel/ColorPickerButton
@onready var deck_icon_selector = $EditPanel/DeckIconSelector

# Ventana para los iconos.
@onready var cover_selector = $EditPanel/CoverSelector
@onready var cards_container = $EditPanel/CoverSelector/TabContainer/UI_CARDS/ScrollContainer/CardsContainer


func _ready() -> void:
	cover_selector.visible = false
	if DeckDraft.has_draft:
		deck_name.text = DeckDraft.current_deck["name"]
		_set_panel_color(deck_bg, Color(DeckDraft.current_deck["color"]))
		var icon_path: String = DeckDraft.current_deck.get("icon", "")

		if icon_path != "" and ResourceLoader.exists(icon_path):
			deck_icon.texture = load(icon_path)
		# Cargar las imágenes.
		_refresh_cards()

func _set_panel_color(panel: Panel, p_deck_color: Color) -> void:
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = p_deck_color
	panel.add_theme_stylebox_override("panel", style)


# Cambiar el color de la baraja al gusto.
func _on_color_picker_button_color_changed(color: Color) -> void:
	_set_panel_color(deck_bg, color)
	DeckDraft.current_deck["color"] = color.to_html()


func _on_deck_icon_selector_pressed() -> void:
	if cover_selector.visible:
		cover_selector.grab_focus()
		return
	
	cover_selector.popup()

func _on_cover_selector_close_requested() -> void:
	cover_selector.hide()

func _refresh_cards() -> void:
	# Vaciar el contenedor.
	for child in cards_container.get_children():
		child.queue_free()

	for card in DeckDraft.current_deck["cards"].values():
		var texture := load(card["texture"]) as Texture2D
		var card_button := TextureButton.new()

		card_button.texture_normal = texture
		card_button.custom_minimum_size = Vector2(100, 140)

		card_button.ignore_texture_size = true
		card_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		# Cuando se pulse, cambiar icono.
		card_button.pressed.connect(_on_card_selected.bind(texture))

		cards_container.add_child(card_button)

func _on_card_selected(texture: Texture2D) -> void:
	deck_icon.texture = texture
	DeckDraft.current_deck["icon"] = texture.resource_path
	cover_selector.hide()


func _on_save_btn_pressed() -> void:
	# Crear carpeta si no existe.
	DirAccess.make_dir_recursive_absolute("user://UserDecks")
	
	var path := "user://UserDecks/%s.json" % str(DeckDraft.current_deck["id"])
	print(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		push_error("No se pudo abrir: %s" % path)
		return
	
	file.store_string(JSON.stringify(DeckDraft.current_deck, "\t"))
	print("Archivo guardado en %s" % path)
	file.close()
	get_tree().change_scene_to_file("res://Scenes/main.tscn")


func _on_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	DeckDraft.clear_draft()
