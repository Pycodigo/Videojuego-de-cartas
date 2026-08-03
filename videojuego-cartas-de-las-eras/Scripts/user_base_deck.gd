extends Control

@export var deck_color: Color

# Señal para poder editar, o eliminar, la baraja pedida.
signal edit_requested(deck_data: Dictionary)
signal delete_requested(deck_data: Dictionary)
signal play_requested(deck_id: float)

# Nodos.
@onready var deck_bg = $DeckBG
@onready var icon_deck = $DeckBG/IconBG
@onready var deck_name_text = $DeckBG/DeckName
@onready var edit_btn = $DeckBG/EditBtn
@onready var delete_btn = $DeckBG/DeleteBtn
@onready var use_btn = $DeckBG/UseBtn


var deck_data: Dictionary = {}
var deck_id: float = 0.0


func _ready() -> void:
	if Global.want_to_select:
		use_btn.visible = true
		edit_btn.visible = false
		delete_btn.visible = false
	else:
		use_btn.visible = false
		edit_btn.visible = true
		delete_btn.visible = true

# Permitir cambiar color en los paneles.
func _set_panel_color(panel: Panel, p_deck_color: Color) -> void:
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = p_deck_color
	panel.add_theme_stylebox_override("panel", style)

# Meter sus correspondientes datos (todo en uno mejor).
func deck_setup(p_deck_data: Dictionary) -> void:
	deck_data = p_deck_data
	deck_name_text.text = deck_data["name"]
	_set_panel_color(deck_bg, Color(deck_data["color"]))
	# Por si no tiene icono.
	if deck_data.get("icon", "") != "" and ResourceLoader.exists(deck_data["icon"]):
		icon_deck.texture = load(deck_data["icon"])

func _on_edit_btn_pressed() -> void:
	edit_requested.emit(deck_data)


func _on_delete_btn_pressed() -> void:
	delete_requested.emit(deck_data)


func _on_use_btn_pressed() -> void:
	deck_id = deck_data["id"]
	play_requested.emit(deck_id)
