extends Node2D

@onready var deck_sprite = $reverso
@onready var label_deck_count = $contador

var card_scenes: Array = [
	preload("res://Scenes/Cards/Test/cartaIA_rey_espadas.tscn"),
	preload("res://Scenes/Cards/Test/cartaIA_caballo_espadas.tscn"),
	preload("res://Scenes/Cards/Test/cartaIA_medieval.tscn")
]
var cards: Array = []           # Cartas del mazo.
var visual_cards: Array = []    # Sprites que se apilan en el mazo.
var max_cards: int = 60

func _ready():
	build_deck()
	shuffle_deck()
	update_deck_visual()
	update_count()

# Construir la baraja.
func build_deck():
	cards.clear()
	
	# Añadir al menos una carta normal.
	var normal_cards = [
		card_scenes[0], 
		card_scenes[1]
	]
	var first_card_scene = normal_cards[randi() % normal_cards.size()]
	var first_card = first_card_scene.instantiate()
	first_card.text = "1"
	cards.append(first_card)
	
	for i in range(max_cards):
		# Seleccionar tipo de carta.
		var scene = card_scenes[randi() % card_scenes.size()]
		var card = scene.instantiate()
		card.text = str(i + 1)
		cards.append(card)

# Barajar el mazo.
func shuffle_deck():
	cards.shuffle()

# Robar carta superior.
func draw_card() -> Node:
	if cards.size() == 0:
		print("La baraja está vacía")
		return null
	var card = cards.pop_front()
	update_count()
	draw_visual_card()  # Animar visual.
	update_deck_visual()
	return card

# Animación de la carta visual.
func draw_visual_card():
	if visual_cards.size() == 0:
		return

	# Tomar la carta superior visual.
	var top_card = visual_cards.pop_back()
	var tween = create_tween()
	tween.tween_callback(top_card.queue_free)

	# Ajustar la pila restante.
	for i in range(visual_cards.size()):
		var tween2 = create_tween()
		tween2.tween_property(visual_cards[i], "position:y", -i * 1.2, 0.2)

# Ver cuántas quedan
func cards_left() -> int:
	return cards.size()

# Actualizar contador.
func update_count():
	if label_deck_count:
		label_deck_count.text = str(cards.size()) + "/" + str(max_cards)

# Actualizar visual del mazo.
func update_deck_visual():
	# Limpiar visuales anteriores.
	for child in deck_sprite.get_children():
		child.queue_free()
	visual_cards.clear()
	
	# Máximo de mazo visual (evita que se vea gigante).
	var max_visuals = 20
	
	if cards.size() == 0:
		# Ocultar el mazo.
		deck_sprite.visible = false
		return
	else:
		deck_sprite.visible = true
	
	#Cantidad que se va a dibujar.
	var thickness = int(remap(cards.size(), 0, max_cards, 0, max_visuals))
	
	for i in range(thickness):
		var back = Sprite2D.new()
		back.texture = preload("res://Images/test/baseball-card.png")
		back.position = Vector2(0, -i * 1.2)
		deck_sprite.add_child(back)
		visual_cards.append(back)
