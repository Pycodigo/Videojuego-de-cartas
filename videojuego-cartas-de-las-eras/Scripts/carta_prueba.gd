extends Panel

@export var text: String
@onready var card_label = $Label

# Tamaño fijo de la carta
const card_size = Vector2(100, 120)

func _ready() -> void:
	# Asignar tamaño para que se vea desde la primera carta.
	var rect_size = card_size
	
	card_label.text = text
