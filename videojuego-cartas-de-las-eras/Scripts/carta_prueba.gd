extends Panel

@export var text: String
@onready var card_label = $Label

# Arrastra carta.
var dragging = false
# Diferencia entre el ratón y la posición de la carta al iniciar el arrastre.
var offset = Vector2.ZERO
var original_rotation: float = 0.0

# Guardar posiciones.
var original_position_global: Vector2
var original_position_local: Vector2

# Marcar si la carta está en estado “arrastrado” para controlar animaciones.
var is_dragged: bool = false
var in_hand: bool = true
var current_slot = null

func _ready():
	card_label.text = text
	# Guardar la posición inicial global de la carta.
	original_position_global = global_position

func _input(event):
	#if not in_hand:
		#return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_global_rect().has_point(get_global_mouse_position()):
			dragging = true
			offset = global_position - get_global_mouse_position()
			straighten()
		elif not event.pressed and dragging:
			dragging = false
			# Intentar colocar la carta en el slot más cercano.
			snap_to_slot()
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + offset

# Animar la carta a cero grados de rotación cuando se arrastra.
func straighten(duration: float = 0.2):
	if not is_dragged:
		is_dragged = true
		original_rotation = rotation_degrees
		create_tween().tween_property(self, "rotation_degrees", 0, duration)

# Volver a la rotación original.
func restore_rotation(duration: float = 0.2):
	if is_dragged:
		is_dragged = false
		create_tween().tween_property(self, "rotation_degrees", original_rotation, duration)

# Intentar colocar la carta en el slot.
func snap_to_slot():
	var board = get_tree().current_scene
	if not board or not "card_slots" in board:
		return

	# Buscar slot cercano.
	var closest_slot = null
	var closest_dist = 100.0
	for slot in board.card_slots:
		if slot.occupied:
			continue
		var dist = global_position.distance_to(slot.global_position)
		if dist < closest_dist:
			closest_slot = slot
			closest_dist = dist

	if closest_slot:
		in_hand = false
		current_slot = closest_slot
		closest_slot.occupied = true

		# Animar a posición global y rotación cero grados.
		var tween = create_tween()
		tween.tween_property(self, "global_position", closest_slot.global_position, 0.2)
		tween.tween_property(self, "rotation_degrees", 0, 0.2)
		tween.connect("finished", Callable(self, "_move_to_board"))
	else:
		# Vuelve a la mano.
		in_hand = true
		restore_rotation()
		return_to_hand()

func _move_to_board():
	var board = get_tree().current_scene
	if get_parent() != board.board_play:
		get_parent().remove_child(self)
		board.board_play.add_child(self)
	global_position = current_slot.global_position
	rotation_degrees = 0
	board.organize_hand()

func return_to_hand():
	# Liberar slot anterior si estaba en uno.
	if current_slot:
		current_slot.occupied = false
		current_slot = null
	
	in_hand = true
	var board = get_tree().current_scene
	if get_parent() != board.player_hand:
		get_parent().remove_child(self)
		board.player_hand.add_child(self)
	in_hand = true
	board.organize_hand()
