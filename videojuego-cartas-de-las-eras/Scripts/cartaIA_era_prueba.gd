extends Panel

@export var text: String
@export var name_era: String = "Era sin nombre"
@export var max_turns: int
@export var texture: Texture2D
@export var details: Dictionary = {}
@export var owner_era: String = ""  # "Player" o "AI"

# Estados.
var turns_left: int = 0
var active: bool = false

@onready var texture2d = $textura_carta
@onready var hidden_texture = $oculto
@onready var card_label = $Label
@onready var name_label = $nombre
@onready var turns_label = $turnos
@onready var effect_label = $efecto

var offset := Vector2.ZERO

# Guardar posiciones.
var original_position_global: Vector2
var original_position_local: Vector2

var original_rotation: float = 0.0
#Definir tamaño fijo para sprites.
var rect_size = Vector2(140, 180)
# Comprobar si hay algún panel de opciones abierto.
static var card_with_open_panel: Card = null

var in_hand: bool = true
var current_slot = null
# Variable de descarte.
var discarded: bool = false

# Mostrar la carta.
var is_hidden: bool = false 

func _ready():
	add_to_group("eras")
	turns_left = max_turns
	_update_visuals()
	hide_card()

# Activar era.
func activate():
	var board = get_tree().current_scene
	
	if active:
		return
	active = true
	print("Era activada con la IA: ", name_era)
	Global.set_active_era(self)
	board.organize_hand_AI()

func inactivate():
	if not active:
		return
	print("Era finalizada: ", name_era)
	active = false
	Global.remove_era_effect(self)
	discard()

func next_turn():
	if not active:
		return
	turns_left -= 1
	print("Era: ", name_era, "-> turnos restantes: ", turns_left)
	_update_visuals()
	if turns_left <= 0:
		inactivate()

func discard():
	if discarded:
		return

	discarded = true
	in_hand = false

	var board = get_tree().current_scene

	var slot = current_slot
	if slot:
		# Solo actualizar card_slot_cnt si existe (slots normales).
		if "card_slot_cnt" in slot:
			slot.card_slot_cnt = max(slot.card_slot_cnt - 1, 0)
			if slot.card_slot_cnt == 0:
				slot.occupied = false
		else:
			# Liberar ocupación.
			slot.occupied = false

		current_slot = null

	# Animación y mover a descarte.
	var discard_tween = create_tween()
	discard_tween.tween_property(self, "scale", Vector2(0.1,0.1), 0.4)
	discard_tween.tween_property(self, "modulate:a", 0, 0.4)
	await discard_tween.finished
	_move_to_discard()

func _move_to_discard():
	var board = get_tree().current_scene
	var discard_slot = board.AIdiscard_slot
	if get_parent() != discard_slot:
		get_parent().remove_child(self)
		discard_slot.add_child(self)

	# Colocarlo en el centro del slot, invisible y pequeño.
	position = Vector2.ZERO
	rotation_degrees = 0

	# Hacer animación inversa para que aparezca.
	var appear_tween = create_tween()
	appear_tween.tween_property(self, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	
	board.organize_hand_AI()

func _update_visuals():
	if texture:
		texture2d.texture = texture
	name_label.text = name_era
	turns_label.text = str(turns_left)
	card_label.text = text
	
	var effect_name = ""
	if details and details.has("name"):
		effect_name = details["name"]
	effect_label.text = effect_name

# Comprobar si la IA debería jugar la era.
func should_AI_play_era() -> bool:
	var board = get_tree().current_scene
	if not board:
		return false
	
	var ai_cards = []
	for card in board.AIboard_play.get_children():
		if "card_name" in card and "era_name" in card and not card.discarded:
			ai_cards.append(card)
	
	if ai_cards.size() == 0:
		print("IA: No tiene cartas en juego, no juega era")
		return false
	
	# Contar cuántas cartas se benefician de esta era.
	var matching_cards = 0
	for card in ai_cards:
		if card.era_name.strip_edges().to_lower() == name_era.strip_edges().to_lower():
			matching_cards += 1
	
	# Calcular porcentaje de cartas que se benefician.
	var benefit_percentage = (float(matching_cards) / ai_cards.size()) * 100
	
	print("IA: Era '", name_era, "' beneficia a ", matching_cards, "/", ai_cards.size(), " cartas (", int(benefit_percentage), "%)")
	
	# Solo jugar si beneficia a más del 50% de las cartas.
	return benefit_percentage > 50.0

# Jugar la era en su turno.
func AI_play_era():
	var board = get_tree().current_scene
	
	if not board or not board.era_slot:
		print("IA: No hay slot de era disponible")
		return false
	
	# No jugar durante fase de preparación.
	if board.deployment_phase:
		print("IA: No juega eras durante preparativos")
		return false
	
	var slot = board.era_slot
	
	# Si el slot está ocupado, no jugar esta era.
	if slot.occupied:
		print("IA: Slot de era ya ocupado")
		return false
	
	# Verificar si es conveniente jugar esta era.
	if not should_AI_play_era():
		print("IA: No es conveniente jugar era ", name_era)
		return false
	
	print("IA: Jugando era ", name_era, " (beneficia a mayoría de cartas)")
	
	# Colocar esta era.
	in_hand = false
	current_slot = slot
	slot.occupied = true
	
	# Guardar posición global antes de reparentar.
	var saved_global_pos = global_position
	
	# Reparentar.
	if get_parent() != slot.get_parent():
		get_parent().remove_child(self)
		slot.get_parent().add_child(self)
		global_position = saved_global_pos
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", slot.global_position, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation_degrees", -90, 0.4)
	await tween.finished
	
	activate()
	show_card()
	
	return true

func show_card():
	is_hidden = false
	update_card_visible()

func hide_card():
	is_hidden = true
	update_card_visible()

func update_card_visible():
	# Comprobar si está oculta.
	if is_hidden:
		texture2d.visible = false
		hidden_texture.visible = true
		card_label.visible = false
		name_label.visible = false
		turns_label.visible = false
		effect_label.visible = false
	else:
		texture2d.visible = true
		hidden_texture.visible = false
		card_label.visible = true
		name_label.visible = true
		turns_label.visible = true
		effect_label.visible = true
