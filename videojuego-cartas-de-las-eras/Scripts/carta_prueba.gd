extends Panel

@export var text: String
@onready var card_label = $Label

# Tamaño fijo de la carta
const card_size = Vector2(100, 120)

# Permitir arrastre.
var dragging = false
# Mantiene posición.
var offset = Vector2.ZERO
# Guardar rotación original de la carta.
var original_rotation: float = 0.0
# Posición original global (para volver a la mano).
var original_position_global: Vector2
# Posición original local.
var original_position_local: Vector2
# Para no afectar a las demás cartas.
var is_dragged: bool = false
# Saber si está en la mano.
var in_hand: bool = true

# Saber en qué slot está.
var current_slot = null

func _ready() -> void:
	card_label.text = text
	original_position_global = global_position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and get_global_rect().has_point(get_global_mouse_position()):
				# Iniciar arrastre.
				dragging = true
				offset = global_position - get_global_mouse_position()
				straighten()
			elif not event.pressed:
				# Soltar
				dragging = false
				snap_to_slot()
	# Mover mientras arrastramos.
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + offset


# Animar a rotación vertical (0°)
func straighten(duration: float = 0.3):
	if not is_dragged:
		is_dragged = true
		original_rotation = rotation_degrees # Guardar rotación original de la carta.
		create_tween().tween_property(self, "rotation_degrees", 0, duration)

# Restaurar su rotación original.
func restore_rotation(duration: float = 0.3):
	if is_dragged:
		is_dragged = false
		create_tween().tween_property(self, "rotation_degrees", original_rotation, duration)

# Encajar carta en el slot más cercano disponible.
func snap_to_slot():
	var board = get_tree().current_scene
	if not board or not "card_slots" in board:
		return

	if current_slot:
		current_slot.occupied = false
		current_slot = null

	var closest_slot = null
	var closest_dist = 50.0
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
		# Animar primero, cambiar parent después
		var tween = create_tween()
		tween.tween_property(self, "global_position", closest_slot.global_position, 0.2)
		tween.tween_property(self, "rotation_degrees", 0, 0.2)
		tween.connect("finished", Callable(self, "_move_to_board"))
	else:
		# Vuelve a la mano
		in_hand = true
		restore_rotation()
		return_to_hand()

func _move_to_board():
	var board = get_tree().current_scene
	get_parent().remove_child(self)
	board.board_play.add_child(self)
	global_position = current_slot.global_position

func return_to_hand(animated: bool = true):
	var board = get_tree().current_scene
	get_parent().remove_child(self)
	board.player_hand.add_child(self)
	self.in_hand = true

	if animated:
		# Animar desde la posición global actual hacia la posición local en la mano
		var target_pos = self.position # posición local calculada por organize_hand
		var tween = create_tween()
		tween.tween_property(self, "position", target_pos, 0.3)
	else:
		self.position = self.position

	# Reorganizar la mano después de añadir la carta
	board.organize_hand()
