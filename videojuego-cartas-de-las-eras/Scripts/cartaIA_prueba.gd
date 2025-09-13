extends Panel

@export var text: String
@onready var card_label = $Label
@onready var health_label = $vida
@onready var front_sprite = $"Baseball-card"
@onready var hidden_sprite = $oculto

# Diferencia entre el ratón y la posición de la carta al iniciar el arrastre.
var offset = Vector2.ZERO
var original_rotation: float = 0.0

# Guardar posiciones.
var original_position_global: Vector2
var original_position_local: Vector2

var in_hand: bool = true
var current_slot = null
# Variable de descarte.
var discarded: bool = false
# Ocultar la carta.
var is_hidden: bool

# Estadísticas.
@export var max_health: int = 100
var current_health: int

# Animación de la vida.
var health_animation: Tween = null


func _ready():
	hide_card()
	
	current_health = max_health
	health_label.text = str(current_health) + "/" + str(max_health)
	
	card_label.text = text
	# Guardar la posición inicial global de la carta.
	original_position_global = global_position
	
	# Test automático: cada segundo pierde 5 de vida.
	if randi() % 7 < 2:
		var timer = Timer.new()
		timer.wait_time = 1
		timer.one_shot = false
		timer.autostart = true
		add_child(timer)
		timer.connect("timeout", Callable(self, "_test_damage"))
	
func _test_damage():
	take_damage(40)

# Animar la carta a cero grados de rotación cuando se arrastra.
func straighten(duration: float = 0.2):
	original_rotation = rotation_degrees
	create_tween().tween_property(self, "rotation_degrees", 0, duration)

# Volver a la rotación original.
func restore_rotation(duration: float = 0.2):
	create_tween().tween_property(self, "rotation_degrees", original_rotation, duration)

func take_damage(amount: int):
	if discarded:
		return
	
	var old_health = current_health
	current_health = clamp(current_health - amount, 0, max_health)

	# Animación de daño.
	if health_animation and health_animation.is_running():
		health_animation.kill()

	health_animation = create_tween()
	health_animation.tween_method(
		func(v): health_label.text = str(int(v)) + "/" + str(max_health),
		old_health, current_health, 0.5
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
	var discard_slot = board.AIdiscard_slot
	if not discard_slot:
		return

	# Hacer que la carta se encoja y desaparezca.
	var discard_tween = create_tween()
	discard_tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.4)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	discard_tween.tween_property(self, "modulate:a", 0, 0.4) # Se desvanece.
	
	# Esperar a que termine la animación.
	await discard_tween.finished
	_move_to_discard()

func _move_to_discard():
	var board = get_tree().current_scene
	var discard_slot = board.AIdiscard_slot
	if get_parent() != discard_slot:
		get_parent().remove_child(self)
		discard_slot.add_child(self)

	# Colocarlo en el centro del slot.
	position = Vector2.ZERO
	rotation_degrees = 0
	
	# Hacer animación inversa para que aparezca.
	var appear_tween = create_tween()
	appear_tween.tween_property(self, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	
	board.organize_hand_AI()
	show_card()


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
		show_card()

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
	board.organize_hand_AI()
	show_card()

func return_to_hand():
	# Liberar slot anterior si estaba en uno.
	if current_slot:
		current_slot.occupied = false
		current_slot = null
	
	in_hand = true
	var board = get_tree().current_scene
	if get_parent() != board.AIhand:
		get_parent().remove_child(self)
		board.AIhand.add_child(self)
	in_hand = true
	board.organize_hand_AI()
	hide_card()

func show_card():
	is_hidden = false
	update_card_visible()

func hide_card():
	is_hidden = true
	update_card_visible()

func update_card_visible():
	# Comprobar si está oculta.
	if is_hidden:
		front_sprite.visible = false
		hidden_sprite.visible = true
		health_label.visible = false
		card_label.visible = false
	else:
		front_sprite.visible = true
		hidden_sprite.visible = false
		health_label.visible = true
		card_label.visible = true
