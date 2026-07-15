extends Control

# Señales para el editor de mazos.
signal removed(card_key: String) # Si se quedó a 0 copias.
signal count_changed(card_key: String, new_count: int) # Nº de copias.

var card_key: String = ""
var count: int = 0

@export var era_color: Color

@onready var card_name_text = $DeckRowBG/CardNameText
@onready var num_cards_text = $DeckRowBG/NumCardsText
@onready var era_color_bg = $DeckRowBG/EraColorBG


func _ready() -> void:
	pass

# Permitir cambiar color en los paneles.
func _set_panel_color(panel: Panel, p_era_color: Color) -> void:
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = p_era_color
	panel.add_theme_stylebox_override("panel", style)

func add_copy() -> void:
	count += 1
	num_cards_text.text = str("x%d" % count)
	count_changed.emit(card_key, count)

# Meter sus correspondientes datos.
func setup(p_card_key: String, p_era_color: Color) -> void:
	card_key = p_card_key
	card_name_text.text = p_card_key
	_set_panel_color(era_color_bg, p_era_color)
	add_copy()



func _on_minus_btn_pressed() -> void:
	count -= 1
	if count <= 0:
		removed.emit(card_key)
		queue_free()
	else:
		num_cards_text.text = str("x%d" % count)
		count_changed.emit(card_key, count)

func _on_delete_btn_pressed() -> void:
	removed.emit(card_key)
	queue_free()
