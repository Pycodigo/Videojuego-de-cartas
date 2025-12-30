extends Panel

@export var text: String
@export var name_era: String = "Era sin nombre"
@export var max_turns: int
@export var texture: Texture2D
@export var details: Dictionary = {}

# Estados.
var turns_left: int = 0
var active: bool = false

@onready var texture2d = $textura_carta
@onready var card_label = $Label
@onready var name_label = $nombre
@onready var turns_label = $turnos
@onready var effect_label = $efecto

var dragging := false
var offset := Vector2.ZERO

# Guardar posiciones.
var original_position_global: Vector2
var original_position_local: Vector2

# Arrastra carta.
var click_started = false
var ready_for_drag = false
var block_drag: bool
var original_rotation: float = 0.0
#Definir tamaño fijo para sprites.
var rect_size = Vector2(140, 180)
# Comprobar si hay algún panel de opciones abierto.
static var card_with_open_panel: Card = null

# Marcar si la carta está en estado “arrastrado” para controlar animaciones.
var is_dragged: bool = false
var in_hand: bool = true
var current_slot = null
# Variable de descarte.
var discarded: bool = false

# Mostrar la carta.
var is_hidden: bool = false 

# Variable estática para controlar arrastre único.
static var card_dragged: Panel = null

func _ready():
	add_to_group("eras")
	turns_left = max_turns
	_update_visuals()

# Activar.
func activate():
	var board = get_tree().current_scene
	
	if active:
		return
	active = true
	print("Era activada: ", name_era)
	Global.set_active_era(self)
	board.organize_hand()

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
	var board = get_tree().current_scene
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.4)
	await tween.finished
	queue_free()
	if board and board.has_node("ranura_era_prueba"):
		var slot = board.get_node("ranura_era_prueba")
		slot.occupied = false
		slot.clear_era()
	
	# Animación y mover a descarte
	var discard_tween = create_tween()
	discard_tween.tween_property(self, "scale", Vector2(0.1,0.1), 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	discard_tween.tween_property(self, "modulate:a", 0, 0.4)
	await discard_tween.finished
	_move_to_discard()

func _move_to_discard():
	var board = get_tree().current_scene
	var discard_slot = board.player_discard_slot
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
	
	board.organize_hand()

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


# Intentar colocar la carta en el slot de era.
func snap_to_era_slot():
	var board = get_tree().current_scene
	if not board:
		return

	var slot = board.era_slot
	var dist = global_position.distance_to(slot.global_position)

	if dist < 200:
		# Si hay otra era, descartar.
		if slot.occupied and slot.current_era and slot.current_era != self:
			slot.current_era.discard()

		in_hand = false
		current_slot = slot
		slot.occupied = true
		slot.current_era = self

		# Conservar posición global al reparentar.
		var saved_global_pos := global_position

		if get_parent() != slot.get_parent():
			get_parent().remove_child(self)
			slot.get_parent().add_child(self)
			global_position = saved_global_pos

		# Animar usando posición global
		var target_global_pos = slot.global_position + Vector2(30, -150)
		var tween := create_tween()
		tween.tween_property(self, "global_position", target_global_pos, 0.25)
		tween.tween_property(self, "rotation_degrees", -90, 0.25)
		await tween.finished

		activate()
	else:
		in_hand = true
		restore_rotation()
		return_to_hand()

	board.update_finish_turn_btn()


# Animar la carta a menos noventa grados de rotación cuando se arrastra.
func sideways(duration: float = 0.2):
	if not ready_for_drag:
		return
	if not is_dragged:
		is_dragged = true
		original_rotation = rotation_degrees
		create_tween().tween_property(self, "rotation_degrees", -90, duration)

# Volver a la rotación original.
func restore_rotation(duration: float = 0.2):
	if is_dragged:
		is_dragged = false
		create_tween().tween_property(self, "rotation_degrees", original_rotation, duration)

# Poner a 0º (recto) al arrastrar.
func straighten(duration: float = 0.2):
	create_tween().tween_property(self, "rotation_degrees", 0, duration)


func return_to_hand():
	# Liberar slot anterior si estaba en uno.
	if current_slot:
		current_slot.occupied = false
		current_slot = null
	
	# Asegurarse de que la carta se considera en la mano.
	in_hand = true
	dragging = false
	is_dragged = false
	ready_for_drag = false   # Se activará al terminar el tween en organize_hand.
	
	var board = get_tree().current_scene
	if get_parent() != board.player_hand:
		get_parent().remove_child(self)
		board.player_hand.add_child(self)
	board.organize_hand()
	
	# Actualizar botón.
	board.update_finish_turn_btn()
