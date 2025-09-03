extends Panel

@export var text: String
@onready var card_label = $Label

# Tamaño fijo de la carta
const card_size = Vector2(100, 120)

func _ready() -> void:
	card_label.text = text
