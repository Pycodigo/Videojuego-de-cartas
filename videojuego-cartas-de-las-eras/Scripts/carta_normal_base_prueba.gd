extends Panel
class_name Card

# Atributos de la carta.
@export var text: String
@export var card_name: String
@export var texture: Texture2D
@export var max_health: int
@export var cost: int
@export var attack: int
@export var defense: int
@export var ability: Dictionary = {} #Diccionario que describe la habilidad.
@export var ability_detailed: String
@export var era_type: String
@export var era_name: String

# Estadísticas modificadas.
var modified_attack = null
var modified_defense = null

# Nodos.
@onready var front_texture = $textura_carta
@onready var card_label = $Label
@onready var name_label = $nombre
@onready var health_label = $vida
@onready var cost_label = $energia
@onready var attack_label = $ataque
@onready var defense_label = $defensa
@onready var ability_label = $habilidad
@onready var era_label = $tipo_era

# Panel de información detallada.
@onready var info_hover = $info
@onready var name_hover = $info/NombreInfo
@onready var health_hover = $info/VidaInfo
@onready var cost_hover = $info/CosteInfo
@onready var attack_hover = $info/AtaqueInfo
@onready var defense_hover = $info/DefensaInfo
@onready var ability_hover = $info/HabilidadInfo
@onready var era_hover = $info/EraInfo

# Opciones.
@onready var options = $opc
@onready var attack_option = $opc/ataque
@onready var ability_option = $opc/habilidad
@onready var cancel_option = $opc/cancelar

# Arrastra carta.
var dragging = false
var click_started = false
var ready_for_drag = false
var block_drag: bool
# Diferencia entre el ratón y la posición de la carta al iniciar el arrastre.
var offset = Vector2.ZERO
var original_rotation: float = 0.0
#Definir tamaño fijo para sprites.
var rect_size = Vector2(140, 180)
# Comprobar si hay algún panel de opciones abierto.
static var card_with_open_panel: Card = null

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
	var ability_name = ""
	if ability and ability.has("name"):
		ability_name = ability.name
	ability_label.text = ability_name
	
	# Panel de info detallada.
	name_hover.text = card_name
	health_hover.text = "Vida: " + str(current_health) + "/" + str(max_health)
	cost_hover.text = "Coste: " + str(cost)
	attack_hover.text = "Ataque: " + str(attack)
	defense_hover.text = "Def: " + str(defense)
	ability_hover.text = ability_name + ":\n" + ability_detailed
	era_hover.text = "Era: " + era_name
	
	# Espera un frame para asegurar que la carta está en el tablero.
	await get_tree().process_frame
	if ability and ability.activation == "auto" and not in_hand and not discarded:
		Global.apply_ability(self, ability)
	
	card_label.text = text
	# Guardar la posición inicial global de la carta.
	original_position_global = global_position
	
	info_hover.visible = false
	options.visible = false


func _gui_input(event):
	if discarded:
		return

	var board = get_tree().current_scene

	#print("is_player_turn:", board.is_player_turn, " first_player_turn_done:", board.first_player_turn_done)
	if not board.is_player_turn and not board.deployment_phase:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			click_started = true
			dragging = false
			offset = global_position - get_global_mouse_position()
			straighten()
		else: # botón soltado
			if dragging:
				# Solo permitir mover si está en la mano o fase de preparación
				if in_hand or board.deployment_phase:
					snap_to_slot()
			elif click_started and not dragging:
				# Abrir panel solo si:
				# - Carta en slot
				# - Turno jugador normal
				# - No en fase de preparación
				if current_slot != null and not in_hand and not discarded and not board.deployment_phase:
					show_options_panel()
				else:
					options.visible = false
			click_started = false
			dragging = false
	elif event is InputEventMouseMotion:
		# Solo arrastrar si está en la mano o fase de preparación
		if click_started and (in_hand or board.deployment_phase):
			global_position = get_global_mouse_position() + offset
			if not dragging:
				dragging = true
				if current_slot:
					# Liberar slot
					current_slot.occupied = false
					current_slot = null
					in_hand = true
				options.visible = false

func show_options_panel():
	if options == null:
		return

	# Solo mostrar si la carta está en un slot (no en la mano).
	if in_hand or discarded:
		options.visible = false
		return

	# Si hay otra carta con el panel abierto, cerrar.
	if card_with_open_panel and card_with_open_panel != self:
		print("Cerrando panel anterior de: ", card_with_open_panel.card_name)
		card_with_open_panel.options.visible = false
		card_with_open_panel = null

	# Mostrar este panel.
	print("Abriendo panel de: ", card_name)
	options.visible = true
	card_with_open_panel = self

	options.z_index = 100  # Aparece encima de todo.
	options.position = Vector2.ZERO  # Dentro del Panel de la carta.
	options.scale = self.scale       # Escala igual que la carta.

func set_ready_for_drag():
	ready_for_drag = true

# Animar la carta a cero grados de rotación cuando se arrastra.
func straighten(duration: float = 0.2):
	if not ready_for_drag:
		return
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

	# Animación de daño.
	if health_animation and health_animation.is_running():
		health_animation.kill()

	health_animation = create_tween()
	health_animation.tween_method(
		func(v): health_label.text = str(int(v)) + "PS",
		old_health, current_health, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Activar habilidad si tiene trigger "on_damage"
	if ability and ability.activation == "auto" and ability.has("trigger") and ability.trigger == "on_damage":
		Global.apply_ability(self, ability)
	
	if current_health <= 0:
		current_health = 0
		discard()

func find_parent_slot() -> Node:
	var board = get_tree().current_scene
	for slot in board.player_card_slots:
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


# Intentar colocar la carta en el slot.
func snap_to_slot():
	var board = get_tree().current_scene
	if not board or not "player_card_slots" in board:
		return
	
	# Buscar slot cercano.
	var closest_slot = null
	var closest_dist = 100.0
	for slot in board.player_card_slots:
		if slot.occupied:
			continue
		var dist = global_position.distance_to(slot.global_position)
		if dist < closest_dist:
			closest_slot = slot
			closest_dist = dist

	if closest_slot:
		# Colocar carta en el slot encontrado.
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
	
	# Actualizar botón.
	board.update_finish_turn_btn()

func _move_to_board():
	var board = get_tree().current_scene
	if get_parent() != board.player_board_play:
		get_parent().remove_child(self)
		board.player_board_play.add_child(self)
	
	# Incrementar contador del slot.
	if current_slot:
		current_slot.card_slot_cnt += 1
		current_slot.occupied = true
	
	global_position = current_slot.global_position
	rotation_degrees = 0
	board.organize_hand()

func return_to_hand():
	# Liberar slot anterior si estaba en uno.
	if current_slot:
		current_slot.occupied = false
		current_slot = null
	
	# Asegurarse de que la carta se considera en la mano
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

# Mostrar y ocultar el panel detallado.
func _on_mouse_entered() -> void:
	if discarded or info_hover.visible:
		return
	info_hover.visible = true
	info_hover.z_index = 100
	info_hover.modulate.a = 0
	create_tween().tween_property(info_hover, "modulate:a", 1.0, 0.2)
	adjust_hover_position()

func _on_mouse_exited() -> void:
	var t = create_tween()
	t.tween_property(info_hover, "modulate:a", 0, 0.2)
	await t.finished
	info_hover.visible = false

func adjust_hover_position():
	if info_hover == null:
		return
	
	var viewport_size = get_viewport_rect().size
	var global_pos = get_global_mouse_position()
	var hover_size = info_hover.size
	
	# Posición base: a la derecha del ratón.
	var new_pos = global_pos + Vector2(20, 0)
	
	# Evitar que se salga por la derecha.
	if new_pos.x + hover_size.x > viewport_size.x:
		new_pos.x = global_pos.x - hover_size.x - 20
	
	# Evitar que se salga por abajo.
	if new_pos.y + hover_size.y > viewport_size.y:
		new_pos.y = viewport_size.y - hover_size.y - 10
	
	# Evitar que se salga por arriba.
	if new_pos.y < 0:
		new_pos.y = 10
	
	# Asignar posición en coordenadas globales.
	info_hover.global_position = new_pos


func _on_attack_btn_pressed() -> void:
	var board = get_tree().current_scene
	if board.cnt_actions > board.max_actions:
		print("Acciones ya gastadas para atacar. Pasa turno.")
		return
	
	# Solo si está en juego y lista para atacar.
	if not in_hand and not discarded:
		Global.start_attack(self)
		options.visible = false

func _on_cancel_btn_pressed() -> void:
	options.visible = false


func _on_ability_pressed() -> void:
	var board = get_tree().current_scene
	if board.cnt_actions > board.max_actions:
		print("Acciones ya gastadas para usar habilidad. Pasa turno.")
		return
	
	# Solo si está en juego y lista para atacar.
	if not in_hand and not discarded:
		if ability and ability.activation == "manual":
			print("Manual.")
			Global.apply_ability(self, ability)
			options.visible = false
