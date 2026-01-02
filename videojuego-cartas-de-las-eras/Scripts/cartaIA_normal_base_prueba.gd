extends Panel

# Atributos de la carta.
@export var text: String
@export var card_name: String
@export var era_type: String
@export var era_name: String
@export var texture: Texture2D
@export var max_health: int
@export var cost: int
@export var attack: int
@export var defense: int
@export var ability: String

# Estadísticas modificadas.
var modified_attack = null
var modified_defense = null

# Nodos.
@onready var front_texture = $textura_carta
@onready var hidden_texture = $oculto
@onready var card_label = $Label
@onready var name_label = $nombre
@onready var health_label = $vida
@onready var cost_label = $energia
@onready var attack_label = $ataque
@onready var defense_label = $defensa
@onready var ability_label = $habilidad
@onready var era_label = $tipo_era


# Diferencia entre el ratón y la posición de la carta al iniciar el arrastre.
var offset = Vector2.ZERO
var original_rotation: float = 0.0
#Definir tamaño fijo para sprites.
var rect_size = Vector2(140, 180)

# Guardar posiciones.
var original_position_global: Vector2
var original_position_local: Vector2

# Marcar si la carta está en estado “arrastrado” para controlar animaciones.
var is_dragged: bool = false
var in_hand: bool = true
var current_slot = null
# Variable de descarte.
var discarded: bool = false

# Mostrar la carta.
var is_hidden: bool = false  

# Variable estática para controlar arrastre único
static var card_dragged: Panel = null

# Estadísticas.
var current_health: int

# Animación de la vida.
var health_animation: Tween = null


func _ready():
	# Añadir a grupo.
	add_to_group("cartas")
	init_card()

func init_card():
	hide_card()
	
	if texture:
		front_texture.texture = texture
		front_texture.size = rect_size
		front_texture.stretch_mode = TextureRect.STRETCH_SCALE
	name_label.text = card_name
	era_label.text = era_type
	current_health = max_health
	health_label.text = str(current_health) + " PS"
	cost_label.text = str(cost)
	attack_label.text = str(attack)
	defense_label.text = str(defense)
	ability_label.text = ability
	
	# Guardar la posición inicial global de la carta.
	original_position_global = global_position
	
	deploy_AI_cards()

func _gui_input(event: InputEvent) -> void:
	if discarded:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Global.player_attack_mode:
			if Global.player_attacking_card == self:
				return
		print("Seleccionando objetivo: ", card_name)
		Global.select_attack_target(self)

	
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
		func(v): health_label.text = str(int(v)) + "PS",
		old_health, current_health, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var damage_in_tween = create_tween()
	damage_in_tween.tween_property(front_texture, "modulate", Color(1,0,0,1), 0.2)
	await damage_in_tween.finished
	var damage_out_tween = create_tween()
	damage_out_tween.tween_property(front_texture, "modulate", Color(1,1,1,1), 0.2)
	await damage_out_tween.finished
	var damage_finish_tween = create_tween()
	damage_finish_tween.tween_property(front_texture, "modulate", Color(1,0,0,1), 0.2)
	await damage_finish_tween.finished
	var finish_tween = create_tween()
	finish_tween.tween_property(front_texture, "modulate", Color(1,1,1,1), 0.2)
	await finish_tween.finished
	
	if current_health <= 0:
		current_health = 0
		discard()

func find_parent_slot() -> Node:
	var board = get_tree().current_scene
	for slot in board.AIcard_slots:
		if self in slot.get_children() or slot.get_node_or_null(name) != null:
			return slot
	return null

func discard():
	if discarded:
		return

	discarded = true
	in_hand = false

	var board = get_tree().current_scene

	var slot = current_slot if current_slot else find_parent_slot()
	if slot:
		slot.card_slot_cnt = max(slot.card_slot_cnt - 1, 0)
		if slot.card_slot_cnt == 0:
			slot.occupied = false
		print("Actualizado slot:", slot.name, " -> cartas:", slot.card_slot_cnt)
		current_slot = null

	# Animación y mover a descarte
	var discard_tween = create_tween()
	discard_tween.tween_property(self, "scale", Vector2(0.1,0.1), 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	discard_tween.tween_property(self, "modulate:a", 0, 0.4)
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

func _move_to_board():
	var board = get_tree().current_scene
	if get_parent() != board.AIboard_play:
		var old_global = global_position
		get_parent().remove_child(self)
		board.AIboard_play.add_child(self)
		global_position = old_global
	
	# Animación de movimiento hacia el slot y rotación 0º
	var tween = create_tween()
	tween.tween_property(self, "global_position", current_slot.global_position, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Hacer que gire desde 180º hasta 0º (se voltea boca arriba)
	tween.parallel().tween_property(self, "rotation_degrees", 0, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Incrementar contador del slot.
	if current_slot:
		current_slot.card_slot_cnt += 1
		current_slot.occupied = true
		
	# Una vez finalice, nos aseguramos de que quede exactamente en el slot
	await tween.finished
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

# Colocación automática de la IA.
func deploy_AI_cards():
	var board = get_tree().current_scene
	
	# Esperar a que la mano termine de organizarse.
	board.organize_hand_AI(true)
	await get_tree().create_timer(1.2).timeout

	
	# Filtrar solo cartas normales, no las demás.
	for card in board.AIhand.get_children():
		# Saltar otras cartas.
		if "name_era" in card:  # Si tiene name_era, es una carta de era.
			print("Saltando carta de era: ", card.name_era if "name_era" in card else "Era")
			continue
		
		# Solo procesar cartas normales que estén en la mano.
		if "card_name" in card and card.in_hand:
			var slot = get_random_free_AI_slot()
			if slot:
				card.in_hand = false
				card.current_slot = slot
				slot.occupied = true
				
				print("IA coloca carta normal: ", card.card_name, " en slot: ", slot.name)
				
				# Animar carta al slot.
				var tween = create_tween()
				tween.tween_property(card, "global_position", slot.global_position, 0.3)
				tween.tween_property(card, "rotation_degrees", 0, 0.3)
				tween.connect("finished", Callable(card, "_move_to_board"))
				
				# Esperar un poco antes de colocar la siguiente carta.
				await get_tree().create_timer(0.4).timeout
			else:
				print("IA: No hay más slots disponibles para ", card.card_name)
				break  # Salir si no hay más slots.

# Devuelve un slot aleatorio disponible para la IA.
func get_random_free_AI_slot():
	var board = get_tree().current_scene
	
	# Buscar un slot libre para la IA.
	var free_slots = []
	for slot in board.AIcard_slots:
		if not slot.occupied:
			free_slots.append(slot)
	if free_slots.size() == 0:
		return null # No quedan slots libres.
	return free_slots[randi() % free_slots.size()]

func show_card():
	is_hidden = false
	update_card_visible()

func hide_card():
	is_hidden = true
	update_card_visible()

func update_card_visible():
	# Comprobar si está oculta.
	if is_hidden:
		front_texture.visible = false
		hidden_texture.visible = true
		card_label.visible = false
		era_label.visible = false
		name_label.visible = false
		health_label.visible = false
		cost_label.visible = false
		attack_label.visible = false
		defense_label.visible = false
		ability_label.visible = false
	else:
		front_texture.visible = true
		hidden_texture.visible = false
		card_label.visible = true
		era_label.visible = true
		name_label.visible = true
		health_label.visible = true
		cost_label.visible = true
		attack_label.visible = true
		defense_label.visible = true
		ability_label.visible = true
