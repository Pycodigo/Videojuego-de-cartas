extends Node2D

@onready var deck_sprite = $reverso
@onready var label_deck_count = $contador

# Escena de la carta individual que tapa el mazo.
var card_scene: PackedScene = preload("res://Scenes/carta_prueba.tscn")
# Lista de cartas en la baraja.
var cards: Array = [] 
# Número máximo de cartas.
var max_cards: int = 60

# Iniciar la baraja.
func _ready():
	build_deck()
	shuffle_deck()
	update_count()

# Construir la baraja.
func build_deck():
	cards.clear()
	for i in range(max_cards):
		var card = card_scene.instantiate()
		card.text = "Carta " + str(i + 1)
		cards.append(card)

# Barajar aleatoriamente.
func shuffle_deck():
	cards.shuffle()

# Robar la carta superior.
func draw_card() -> Node:
	if cards.size() > 0:
		var card = cards.pop_front()  # Quita y devuelve la primera carta.
		update_count()
		return card
	else:
		print("La baraja está vacía")
		return null

# Ver cuántas cartas quedan.
func cards_left() -> int:
	print("Quedan " + str(cards.size))
	return cards.size()

# Actualizar contador y efecto visual.
func update_count():
	if label_deck_count:
		# Mostrar las cartas que quedan.
		label_deck_count.text = str(cards.size()) + "/" + str(max_cards)
	
	# Efecto visual: reducir ligeramente el sprite según cartas restantes
	if deck_sprite:
		var scale_factor = 0.5 + 0.5 * (cards.size() / max_cards)
		deck_sprite.scale = Vector2(scale_factor, scale_factor)
