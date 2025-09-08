extends Panel

@export var text: String
@onready var card_label = $Label
@onready var health_label = $vida

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
# Variable de descarte.
var discarded: bool = false

# Variable estática para controlar arrastre único
static var card_dragged: Panel = null

# Estadísticas.
@export var max_health: int = 100
var current_health: int

# Animación de la vida.
var health_animation: Tween = null


func _ready():
	current_health = max_health
	health_label.text = str(current_health) + "/" + str(max_health)
	
	card_label.text = text
	# Guardar la posición inicial global de la carta.
	original_position_global = global_position
	
	# Test automático: cada segundo pierde 5 de vida.
	var timer = Timer.new()
	timer.wait_time = 1
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.connect("timeout", Callable(self, "_test_damage"))
	
func _test_damage():
	take_damage(40)

func _input(event):
	# Otra carta ya está siendo arrastrada.
	if not in_hand or (card_dragged and card_dragged != self) or discarded:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_global_rect().has_point(get_global_mouse_position()):
			dragging = true
			card_dragged = self
			offset = global_position - get_global_mouse_position()
			straighten()
		elif not event.pressed and dragging:
			dragging = false
			card_dragged = null
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

func take_damage(amount: int):
	if discarded:
		return
	
	var old_health = current_health
	current_health = clamp(current_health - amount, 0, max_health)

	# Tween de número
	if health_animation and health_animation.is_running():
		health_animation.kill()

	health_animation = create_tween()
	health_animation.tween_method(
		func(v): health_label.text = str(int(v)) + "/" + str(max_health),
		old_health, current_health, 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if current_health <= 0:
		current_health = 0
		discard()

func discard():
	if discarded:
		return

	discarded = true
	in_hand = false

	var board = get_tree().current_scene
	var discard_slot = board.discard_slot
	if not discard_slot:
		return

	# Guardar la posición global actual de la carta.
	var start_global_pos = global_position
	# Posición global del slot.
	var target_global_pos = discard_slot.global_position

	# Tween desde la posición actual hacia la del slot.
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_global_pos, 0.4)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation_degrees", 0, 0.4)
	tween.connect("finished", Callable(self, "_move_to_discard"))

func _move_to_discard():
	var board = get_tree().current_scene
	var discard_slot = board.discard_slot
	if get_parent() != discard_slot:
		get_parent().remove_child(self)
		discard_slot.add_child(self)

	# Posición local exacta dentro del slot.
	position = Vector2.ZERO
	rotation_degrees = 0


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
