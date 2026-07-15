extends Control

const DECK_ROW_SCENE: PackedScene = preload("res://Scenes/deck_row.tscn")
const ERA_COUNT_SCENE: PackedScene = preload("res://Scenes/era_count.tscn")
const MAX_DECK_SIZE: int = 60
const FILTER_TAG_SCENE := preload("res://Scenes/filter_tag.tscn")

# Nodos.
@onready var collection_grid: GridContainer = $MainBar/ColectionBar/ScrollContainer/GridContainer
@onready var deck_list: VBoxContainer = $MainBar/DeckBar/ScrollContainer/DeckList
@onready var deck_name: LineEdit = $TopBarName/DeckNameInput
@onready var count_deck_label: Label = $CountDeck
@onready var progress_bar: ProgressBar = $MainBar/DeckBar/Header/ProgressBar
@onready var tag_filter: FlowContainer = $MainBar/ColectionBar/TagFilter
@onready var search_bar: LineEdit = $MainBar/ColectionBar/LineEdit
@onready var cards_resume: FlowContainer = $MainBar/DeckBar/CardsResume
@onready var info_deck: Label = $MainBar/DeckBar/Info
@onready var count_colection: Label = $CountColection

# Botones de filtros.
@onready var card_type_btn = $MainBar/ColectionBar/Filter/ButtonFilters/CardTypeOption
@onready var era_option_btn = $MainBar/ColectionBar/Filter/ButtonFilters/EraOption
@onready var ability_type_btn = $MainBar/ColectionBar/Filter/ButtonFilters/AbilityTypeOption

# Filas del mazo actual, indexadas por el nombre de la carta (card_name).
var deck_rows: Dictionary = {}
# Nº total de copias en el mazo.
var total_cards: int = 0

# Metadatos de era por carta, para poder calcular el resumen por era
# sin tener que ir preguntando a las mini cartas originales cada vez.
var card_era_data: Dictionary = {}
# era_name -> Color (para pintar cada fila del resumen).
var era_color_by_key: Dictionary = {}

# Filtros.
var filters = {
	"search_text": "",
	"card_type": null,
	"era_name": null,
	"ability_type": null,
}

const CARD_TYPES := [
	"UI_CARD_TYPE_BASIC",
	"Era",
]

const ERAS := [
	"CARD_PREHISTORY_ERA",
	"CARD_ANCIENT_ERA",
	"CARD_MIDDLE_ERA",
	"CARD_REVOLUTION_ERA",
	"CARD_FUTURE_ERA",
]

const ABILITY_TYPES := [
	"CARD_ABILITY_ACTIVE_TYPE",
	"CARD_ABILITY_PASSIVE_TYPE",
]

func _ready() -> void:
	info_deck.visible = false
	count_colection.text = str(collection_grid.get_child_count())
	_setup_filters()
	
	# Conectar cada mini carta que ya esté en la colección al pulsar en el editor.
	for mini_card in collection_grid.get_children():
		_connect_mini_card(mini_card)
		card_era_data[mini_card.card_name] = {
			"era_name": mini_card.era_name,
			"era_color": mini_card.era_color,
		}
		if not era_color_by_key.has(mini_card.era_name):
			era_color_by_key[mini_card.era_name] = mini_card.era_color


# Conectar la señal "add_requested" de una mini carta de la colección.
func _connect_mini_card(mini_card: Control) -> void:
	if mini_card.has_signal("add_requested") and not mini_card.add_requested.is_connected(_on_mini_card_add_requested):
		mini_card.add_requested.connect(_on_mini_card_add_requested)


# Llamar al pulsar añadir al mazo.
func _on_mini_card_add_requested(mini_card: Control) -> void:
	if total_cards >= MAX_DECK_SIZE:
		print("El mazo ya tiene el máximo de %d cartas." % MAX_DECK_SIZE)
		info_deck.visible = true
		info_deck.text = tr("UI_MAX_DECK_LIMIT") % MAX_DECK_SIZE
		info_deck.set("theme_override_colors/font_color", Color("#8c9600"))
		return

	var card_key: String = mini_card.card_name

	if deck_rows.has(card_key):
		# Ya existe una fila para esta carta: solo se incrementa el contador.
		deck_rows[card_key].add_copy()
	else:
		# No existe todavía: se crea su deck_row y se le pasan los datos.
		var row := DECK_ROW_SCENE.instantiate()
		deck_list.add_child(row)
		row.setup(card_key, mini_card.era_color)

		# Estas dos sí son señales: el deck_row avisa "hacia arriba"
		# cuando cambia su estado, sin saber quién lo escucha.
		row.removed.connect(_on_deck_row_removed)
		row.count_changed.connect(_on_deck_row_count_changed)

		deck_rows[card_key] = row

	_recount_total()
	_update_deck_counters()


# Se llama cuando una fila del mazo llega a 0 copias y se elimina sola.
func _on_deck_row_removed(card_key: String) -> void:
	deck_rows.erase(card_key)
	_recount_total()
	_update_deck_counters()


# Se llama cuando cambia el nº de copias de una fila (sin llegar a 0).
func _on_deck_row_count_changed(_card_key: String, _new_count: int) -> void:
	_recount_total()
	_update_deck_counters()


# Recalcula el total de cartas sumando las copias de cada fila viva.
func _recount_total() -> void:
	var sum := 0
	for row in deck_rows.values():
		sum += row.count
	total_cards = sum


# Actualiza el contador "x/60" y la barra de progreso.
func _update_deck_counters() -> void:
	count_deck_label.text = "%d/%d" % [total_cards, MAX_DECK_SIZE]
	progress_bar.value = total_cards
	_refresh_era_counts()


# Recalcula cuántas cartas de cada era hay en el mazo a partir de
# deck_rows, y reconstruye el resumen entero.
func _refresh_era_counts() -> void:
	var totals: Dictionary = {}  

	for card_key in deck_rows:
		var row = deck_rows[card_key]
		var era_key: String = card_era_data.get(card_key, {}).get("era_name", "")
		if era_key == "":
			continue
		totals[era_key] = totals.get(era_key, 0) + row.count

	# Vaciar el resumen actual.
	for child in cards_resume.get_children():
		cards_resume.remove_child(child)
		child.queue_free()

	# Reconstruir solo las eras que tengan al menos 1 carta en el mazo,
	# respetando el orden de eras (Prehistoria, Antigüedad, ...).
	for era_key in ERAS:
		if not totals.has(era_key):
			continue
		var era_row := ERA_COUNT_SCENE.instantiate()
		cards_resume.add_child(era_row)
		era_row.setup(era_key, era_color_by_key.get(era_key, Color.WHITE), totals[era_key])


func apply_filters() -> void:
	# Pillar todas las cartas.
	for mini_card in collection_grid.get_children():
		var visible := true
		# Buscador general (nombre carta + nombre habilidad)
		var search_text: String = filters["search_text"]

		if not search_text.is_empty():
			var card_name = tr(mini_card.card_name).to_lower()
			var ability_name = tr(mini_card.ability_name).to_lower()
			var search = search_text.to_lower()

			if not card_name.contains(search) and not ability_name.contains(search):
				visible = false

		# Filtros normales
		if visible:
			for key in filters:
				if key == "search_text":
					continue

				var value = filters[key]

				if value == null:
					continue

				var card_value = mini_card.get(key)

				if card_value == null:
					visible = false
					break

				if not str(card_value).to_lower().contains(str(value).to_lower()):
					visible = false
					break
		mini_card.visible = visible

func update_filter_tags() -> void:
	# Eliminar etiquetas actuales.
	for child in tag_filter.get_children():
		child.queue_free()

	# Crear etiquetas nuevas.
	for key in filters.keys():
		var value = filters[key]

		if value == null:
			continue

		if value is String and value.is_empty():
			continue

		var tag = FILTER_TAG_SCENE.instantiate()

		tag.remove_requested.connect(_on_filter_tag_removed)

		tag_filter.add_child(tag)
		tag.setup(key, str(value))

	# Mostrar u ocultar el contenedor de filtros.
	var has_filters := tag_filter.get_child_count() > 0
	tag_filter.visible = has_filters

func _on_filter_tag_removed(filter_key: String) -> void:
	match filter_key:
		"search_text":
			filters[filter_key] = ""
			search_bar.clear()

		"card_type":
			filters[filter_key] = null
			card_type_btn.select(0) # "Tipo carta"

		"era_name":
			filters[filter_key] = null
			era_option_btn.select(0) # "Eras"

		"ability_type":
			filters[filter_key] = null
			ability_type_btn.select(0) # "Tipo habilidad"

	update_filter_tags()
	apply_filters()

func set_filter(key: String, value) -> void:
	filters[key] = value
	update_filter_tags()
	apply_filters()

# Poner filtros en sus botones.
func _setup_filters() -> void:
	card_type_btn.add_item("UI_CARD_TYPE_FILTER")
	card_type_btn.set_item_disabled(0, true)
	card_type_btn.add_item("UI_ALL_TEXT")
	
	era_option_btn.add_item("Era")
	era_option_btn.set_item_disabled(0, true)
	era_option_btn.add_item("UI_ALL_TEXT")
	
	ability_type_btn.add_item("UI_ABILITY_TYPE_FILTER")
	ability_type_btn.set_item_disabled(0, true)
	ability_type_btn.add_item("UI_ALL_TEXT")
	
	for card_type in CARD_TYPES:
		card_type_btn.add_item(card_type)
	
	for era_type in ERAS:
		era_option_btn.add_item(era_type)
	
	for ability_type in ABILITY_TYPES:
		ability_type_btn.add_item(ability_type)
	
	card_type_btn.select(0)
	era_option_btn.select(0)
	ability_type_btn.select(0)


func _on_card_type_option_item_selected(index: int) -> void:
	if index <= 1:
		set_filter("card_type", null)
	else:
		set_filter("card_type", card_type_btn.get_item_text(index))


func _on_era_option_item_selected(index: int) -> void:
	if index <= 1:
		set_filter("era_name", null)
	else:
		set_filter("era_name", era_option_btn.get_item_text(index))


func _on_ability_type_option_item_selected(index: int) -> void:
	if index <= 1:
		set_filter("ability_type", null)
	else:
		set_filter("ability_type", ability_type_btn.get_item_text(index))


func _on_line_edit_text_changed(text: String) -> void:
	set_filter("search_text", text)

# Vaciar el mazo entero.
func _on_btn_delete_pressed() -> void:
	for row in deck_rows.values():
		deck_list.remove_child(row)
		row.queue_free()
	
	deck_rows.clear()
	total_cards = 0
	_update_deck_counters()
	info_deck.visible = false


func _on_btn_save_pressed() -> void:
	# Comprobar que el mazo tiene 60 cartas.
	if total_cards < MAX_DECK_SIZE:
		info_deck.visible = true
		info_deck.text = "UI_NEED_SIXTY"
		info_deck.set("theme_override_colors/font_color", Color("#e30010"))
		return
	
	# Comprobar que el mazo tenga nombre.
	if deck_name.text.strip_edges().is_empty():
		info_deck.visible = true
		info_deck.text = "UI_WITHOUT_NAME"
		info_deck.set("theme_override_colors/font_color", Color("#e30010"))
		return
	
	var deck_data := {
		"name": deck_name.text,
		"cards": {},
	}
	
	# Guardar cada carta con su cantidad.
	for card_name in deck_rows:
		deck_data["cards"][card_name] = deck_rows[card_name].count
	
	# Crear carpeta si no existe.
	DirAccess.make_dir_recursive_absolute("res://UserDecks")
	
	var path := "res://UserDecks/%s.json" % deck_name.text
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		print("Error en ", file)
		info_deck.visible = true
		info_deck.text = "UI_CANNOT_SAVE"
		info_deck.set("theme_override_colors/font_color", Color("#e30010"))
		return
	
	file.store_string(JSON.stringify(deck_data, "\t"))
	file.close()
	print("Mazo creado con éxito en: ", path)
	info_deck.visible = true
	info_deck.text = "UI_DECK_SAVED"
	info_deck.set("theme_override_colors/font_color", Color("#3b9d00"))
