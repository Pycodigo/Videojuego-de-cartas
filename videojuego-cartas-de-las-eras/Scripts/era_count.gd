extends Control

var era_key: String = ""
var count: int = 0

@export var era_color: Color

@onready var era_name_text = $HBoxContainer/EraNameText
@onready var num_cards_era_text = $HBoxContainer/NumCardsEraText
@onready var era_color_bg = $EraColorBG


func _ready() -> void:
	pass


# Permitir cambiar color en los paneles.
func _set_panel_color(panel: Panel, p_era_color: Color) -> void:
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = p_era_color
	panel.add_theme_stylebox_override("panel", style)


# Refleja el total de cartas de la respectiva era.
func setup(p_era_key: String, p_era_color: Color, p_count: int) -> void:
	era_key = p_era_key
	era_name_text.text = p_era_key
	_set_panel_color(era_color_bg, p_era_color)
	set_count(p_count)

func set_count(p_count: int) -> void:
	count = p_count
	num_cards_era_text.text = "x%d" % count
