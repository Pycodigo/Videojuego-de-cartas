extends Control

# Atributos de la mini carta.
@export var card_name: String
@export var card_img: Texture2D
@export var ability_name: String # No necesita ser un diccionario aquí.
@export var ability_type: String
@export var era_name: String
@export var max_hp: int
@export var energy_cost: int
@export var attack: int
@export var defense: int
@export var cooldown: int
@export var mini_card_color: Color
@export var era_color: Color
# Tipo de carta (para los filtros).
@export var card_type: String

# Nodos.
@onready var mini_card_bg = $MiniBasicCard/MiniCardBG
@onready var era_color_bg = $MiniBasicCard/EraColorBG
@onready var mini_card_name = $MiniBasicCard/MiniCardName
@onready var mini_card_texture = $MiniBasicCard/MiniCardTexture
@onready var stats_text = $MiniBasicCard/StatsText
@onready var ability_name_text = $MiniBasicCard/AbilityName
@onready var ability_type_text = $MiniBasicCard/AbilityTypeText
@onready var cooldown_text = $MiniBasicCard/CooldownNum

# Enviar señal del tipo de carta que es al editor.
signal add_requested(mini_card: Control)


func _ready() -> void:
	init_card()

# Permitir cambiar color en los paneles.
func _set_panel_color(panel: Panel, color: Color) -> void:
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = color
	panel.add_theme_stylebox_override("panel", style)

func init_card():
	_set_panel_color(mini_card_bg, mini_card_color)
	_set_panel_color(era_color_bg, era_color)
	mini_card_name.text = card_name
	mini_card_texture.texture = card_img
	stats_text.text = str("❤ ", max_hp, "    ⚡ ", energy_cost, "          ⚔ ", attack, "    🛡 ", defense)
	ability_name_text.text = ability_name
	ability_type_text.text = ability_type
	cooldown_text.text = str(cooldown)


func _on_add_btn_pressed() -> void:
	add_requested.emit(self)
