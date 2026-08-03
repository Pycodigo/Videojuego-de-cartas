extends Control

# Atributos de la carta.
@export var card_name: String
@export var ability: Dictionary # Diccionario que describe la habilidad.
@export var era_name: String
@export var current_hp: int # Vida actual de la carta.
@export var max_hp: int
@export var energy_cost: int
@export var attack: int
@export var defense: int
@export var cooldown: int

# Nodos de la carta.
@onready var card_panel = $BasicCard
@onready var name_text = $BasicCard/NameText
@onready var energy_cost_text = $BasicCard/EnergyText
@onready var energy_cost_texture = $BasicCard/ThunderTexture
@onready var energy_cost_border_texture = $BasicCard/EnergyTexture
@onready var ability_text = $BasicCard/AbilityText
@onready var hp_text = $BasicCard/HpText
@onready var hp_texture = $BasicCard/HeartTexture
@onready var hp_border_texture = $BasicCard/HpTexture
@onready var attack_text = $BasicCard/AttackText
@onready var attack_texture = $BasicCard/SwordTexture
@onready var defense_text = $BasicCard/DefenseText
@onready var defense_texture = $BasicCard/ShieldTexture
@onready var cooldown_text = $BasicCard/CooldownText
@onready var cooldown_texture = $BasicCard/CooldownTexture
@onready var action_bg = $BasicCard/ActionBG

# Textos en zoom.
@onready var hp_zoom_texture = $BasicCard/HpZoomBorderTexture
@onready var hp_zoom_text = $BasicCard/HpZoomBorderTexture/HpZoomText
@onready var energy_cost_zoom_texture = $BasicCard/EnergyZoomBorderTexture
@onready var energy_cost_zoom_text = $BasicCard/EnergyZoomBorderTexture/EnergyZoomText
@onready var attack_zoom_texture = $BasicCard/AttackZoomBorderTexture
@onready var attack_zoom_text = $BasicCard/AttackZoomBorderTexture/AttackZoomText
@onready var defense_zoom_texture = $BasicCard/DefenseZoomBorderTexture
@onready var defense_zoom_text = $BasicCard/DefenseZoomBorderTexture/DefenseZoomText
@onready var cooldown_zoom_texture = $BasicCard/CooldownZoomBorderTexture
@onready var cooldown_zoom_text = $BasicCard/CooldownZoomBorderTexture/CooldownZoomText
@onready var ability_zoom_texture = $BasicCard/AbilityZoomBorderTexture
@onready var ability_zoom_text = $BasicCard/AbilityZoomBorderTexture/AbilityZoomText
@onready var action_texture = $BasicCard/ActionTexture

# Detalles de la carta.
@onready var detail_panel = $Details
@onready var name_detail = $Details/NameDetail
@onready var era_detail = $Details/EraDetailText
@onready var ability_detail = $Details/AbilityNameDetailText
@onready var ability_description = $Details/ScrollContainer/DescriptionDetailText
@onready var hp_num_detail = $Details/HPNumDetail
@onready var energy_cost_num_detail = $Details/EnergyNumDetail
@onready var atk_num_detail = $Details/ATKNumDetail
@onready var def_num_detail = $Details/DEFNumDetail
@onready var cooldown_num_detail = $Details/CooldownNumDetail
@onready var state_text_detail = $Details/StateText

# Botones.
@onready var plus_btn = $BasicCard/PlusBtn
@onready var cancel_btn = $BasicCard/CancelBtn
@onready var atk_btn = $BasicCard/ATKBtn
@onready var def_btn = $BasicCard/DefBtn

# Obtener el tablero (card -> deck -> player -> board).
@onready var board = get_parent().get_parent().get_parent()

# Tamaño de la carta.
var card_size = Vector2(300, 400)
# Tamaño agrandado.
var card_zoom_size = Vector2(512, 700)

# Tamaño fijo del panel de detalles (debe coincidir con el diseño de la .tscn).
const DETAIL_SIZE = Vector2(912, 700)

# Guardar posiciones.
var original_position_global: Vector2
var original_position_local: Vector2
var atk_btn_original_pos: Vector2
var def_btn_original_pos: Vector2
# Posición de la carta en la mano.
var hand_position: Vector2

# Tiempo del ratón sobre la carta.
var mouse_time: float = 0.0
# Indicar que el ratón pasó por la carta.
var mouse_hovering: bool = false
# Indicar si el ratón está sujetando la carta.
var hold_card: bool = false
# Determinar si la carta tiene zoom.
var zoom_active: bool = false
var cannot_zoom: bool = false
# Hacer que el panel de detalles aparezca solo una vez.
var detail_panel_appeared: bool = false
# Hacer que las acciones de una carta aparezcan solo una vez.
var actions_showed: bool = false
# Guardar distancia entre cursor y esquina de la carta.
var drag_offset = null
# Comprobar que la carta está en un slot (y el zoom).
var is_in_slot: bool = false
var was_zoomed_in_slot: bool = false
# Slot en el que está colocada la carta actualmente (null si no está en ninguno).
var current_slot = null
# Comprobar si se usó una acción.
var card_action_clicked: bool = false
# Controlar los clicks.
var click_timer: Timer
# Rotación original.
var original_rotation: float = 0.0
# Rotación de carta en mano.
var hand_rotation: float = 0.0
# La carta ya subió.
var is_raised: bool = false
var raise_tween: Tween

# Estado de arrastre/click.
var press_position: Vector2 = Vector2.ZERO
var is_dragging: bool = false
const DRAG_THRESHOLD := 15.0  # Píxeles que hay que mover el ratón para que cuente como arrastre.

# Guardar la posición y escala del slot.
var slot_pos: Vector2
var slot_scale: Vector2

# Comprobar si la carta está en la mano.
var in_hand: bool = true
# Obtener posición de la carta en la mano.
var hand_index: int = -1

# Guardar que acción (ataque, defensa...) se hizo click.
var action_clicked: int = 0  # 1 (ATK), 2 (DEF), 3 (HABILIDAD).


func _ready() -> void:
	init_card()
	# Conectar las funciones del ratón a la carta de panel.
	if not card_panel.gui_input.is_connected(_on_basic_card_gui_input):
		card_panel.gui_input.connect(_on_basic_card_gui_input)
	
	# Timer para no abrir los botones hasta confirmar que no es un doble click.
	click_timer = Timer.new()
	click_timer.one_shot = true
	click_timer.wait_time = 0.3  
	add_child(click_timer)
	click_timer.timeout.connect(_on_card_left_clicked)

# Base de las cartas.
func init_card():
	name_text.text = card_name
	name_detail.text = card_name
	era_detail.text = era_name
	energy_cost_text.text = str(energy_cost)
	energy_cost_num_detail.text = str(energy_cost)
	ability_text.text = ability.get("name", "")
	ability_detail.text = ability.get("name", "")
	state_text_detail.text = ability.get("state", "")
	ability_description.text = ability.get("description", "")
	hp_text.text = str(current_hp)
	attack_text.text = str(attack)
	defense_text.text = str(defense)
	cooldown_text.text = str(cooldown)
	hp_num_detail.text = str(max_hp, " (", current_hp, ")")
	atk_num_detail.text = str(attack)
	def_num_detail.text = str(defense)
	cooldown_num_detail.text = str(cooldown)
	
	hp_zoom_text.text = str(current_hp)
	energy_cost_zoom_text.text = str(energy_cost)
	attack_zoom_text.text = str(attack)
	defense_zoom_text.text = str(defense)
	cooldown_zoom_text.text = str(cooldown)
	ability_zoom_text.text = ability.get("name", "")
	
	# Ocultar stats de zoom (e iconos).
	hp_zoom_texture.visible = false
	energy_cost_zoom_texture.visible = false
	attack_zoom_texture.visible = false
	defense_zoom_texture.visible = false
	cooldown_zoom_texture.visible = false
	ability_zoom_texture.visible = false
	action_texture.visible = false
	action_bg.visible = false
	
	# Ocultar botones de acciones.
	atk_btn.visible = false
	def_btn.visible = false
	atk_btn.disabled = true
	def_btn.disabled = true
	
	# Ocultar el panel de la info al principio (y desactivar el botón).
	detail_panel.visible = false
	plus_btn.visible = false
	plus_btn.disabled = true
	cancel_btn.visible = false
	cancel_btn.disabled = true
	
	# Guardar la posición inicial global de la carta.
	original_position_global = card_panel.global_position
	
	atk_btn_original_pos = atk_btn.position
	def_btn_original_pos = def_btn.position

# Zoom de la carta.
func _show_zoom() -> void:
	if in_hand:
		return
	
	# Crear animación.
	var tween = create_tween()
	
	# Ponerlo por encima del resto.
	self.z_index = 1
	plus_btn.z_index = 1
	cancel_btn.z_index = 1
	
	if is_in_slot:
		# Posiciones destino originales (relativas al 300x400 de la carta).
		var original_pos = {
			hp_zoom_texture:           Vector2(26, 195),          
			energy_cost_zoom_texture:  Vector2(182, 194),        
			attack_zoom_texture:       Vector2(26, 251),        
			defense_zoom_texture:      Vector2(184, 249),       
			cooldown_zoom_texture:     Vector2(105, 220),
			ability_zoom_texture:      Vector2(47, 294),
		}

		for stat_zoom in original_pos:
			tween.tween_property(stat_zoom, "modulate:a", 0.0, 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(stat_zoom, "scale", Vector2.ONE, 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(stat_zoom, "position", original_pos[stat_zoom], 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Ocultar al terminar.
		tween.tween_callback(func():
			hp_zoom_texture.visible = false
			energy_cost_zoom_texture.visible = false
			attack_zoom_texture.visible = false
			defense_zoom_texture.visible = false
			cooldown_zoom_texture.visible = false
			ability_zoom_texture.visible = false
		)
		
		# Ocultar botones.
		if actions_showed:
			tween.tween_property(atk_btn, "position:y", atk_btn_original_pos.y, 0.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(def_btn, "position:y", def_btn_original_pos.y, 0.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(atk_btn, "modulate:a", 0.0, 0.15)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(def_btn, "modulate:a", 0.0, 0.15)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			tween.tween_callback(func():
				atk_btn.visible = false
				def_btn.visible = false
				atk_btn.disabled = true
				def_btn.disabled = true
			)
		
		# Volver a mostrar stats normales.
		for stat in [hp_border_texture, hp_text, hp_texture, 
		energy_cost_text, energy_cost_texture, energy_cost_border_texture,
		ability_text, attack_text, attack_texture, defense_text, defense_texture, 
		cooldown_text, cooldown_texture]:
			stat.modulate.a = 0.0
			tween.parallel().tween_property(stat, "modulate:a", 1.0, 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		was_zoomed_in_slot = true
	
	# Activar los botones para detalles (y cancelar).
	plus_btn.visible = true
	plus_btn.disabled = false
	cancel_btn.visible = true
	cancel_btn.disabled = false
	
	var viewport_size = get_viewport().get_visible_rect().size
	var target_pos = viewport_size / 2 - card_zoom_size / 2
	var target_scale = card_zoom_size / card_size
	
	card_panel.pivot_offset = Vector2.ZERO # Escala desde el centro.
	
	# Posición y escala a la vez.
	tween.tween_property(card_panel, "global_position", target_pos, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card_panel, "scale", target_scale, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Los textos (y botones) tardan medio segundo más en aparecer (Para hacerlo más bonito).
	for text in [name_text, ability_text, attack_text, cooldown_text, 
	defense_text, energy_cost_text, hp_text, plus_btn, cancel_btn]:
		text.modulate.a = 0.0
		tween.parallel().tween_property(text, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.5)

# Volver a tener la carta en tamaño normal.
func _hide_zoom() -> void:
	# Crear animación.
	var tween = create_tween()
	
	self.z_index = 0
	
	# Primero desvanece el panel de detalles si estaba visible.
	if detail_panel_appeared:
		detail_panel_appeared = false
		tween.tween_property(detail_panel, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func(): detail_panel.visible = false)
	
	# Volver al slot o a la posición original según corresponda.
	var target_pos = slot_pos if was_zoomed_in_slot else original_position_global
	var target_scale = slot_scale if was_zoomed_in_slot else Vector2.ONE
	
	# Posición y escala de la carta a la vez.
	tween.tween_property(card_panel, "global_position", target_pos, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card_panel, "scale", target_scale, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	for text in [name_text, ability_text, attack_text, cooldown_text, 
	defense_text, energy_cost_text, hp_text]:
		tween.parallel().tween_property(text, "modulate:a", 1.0, 0.0)
		
	# Desvanecer botones en paralelo con la animación.
	for button in [plus_btn, cancel_btn]:
		tween.parallel().tween_property(button, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Ocultar y desactivar al terminar.
	tween.tween_callback(func():
		plus_btn.visible = false
		plus_btn.disabled = true
		cancel_btn.visible = false
		cancel_btn.disabled = true
	)
	
	tween.tween_callback(func(): plus_btn.text = "+")
	
	if actions_showed:
		# Mover en vertical los botones, y que aparezcan de forma suave (si no está en la mano).
		tween.tween_property(atk_btn, "position:y", atk_btn.position.y - 150, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(def_btn, "position:y", def_btn.position.y + 150, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		atk_btn.modulate.a = 0.0
		tween.parallel().tween_property(atk_btn, "modulate:a", 1.0, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		def_btn.modulate.a = 0.0
		tween.parallel().tween_property(def_btn, "modulate:a", 1.0, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		atk_btn.visible = true
		def_btn.visible = true
		atk_btn.disabled = false
		def_btn.disabled = false
	
	if was_zoomed_in_slot:
		# Ocultar stats normales (se ven mal).
		for stat in [hp_border_texture, hp_text, hp_texture, 
		energy_cost_text, energy_cost_texture, energy_cost_border_texture,
		ability_text, attack_text, attack_texture, defense_text, defense_texture, 
		cooldown_text, cooldown_texture]:
			tween.parallel().tween_property(stat, "modulate:a", 0.0, 0.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Posiciones destino en esquinas (relativas al 300x400 de la carta).
		var corners = {
			hp_zoom_texture:           Vector2(-80, -15),      # Esquina superior izquierda.
			energy_cost_zoom_texture:  Vector2(220, -15),      # Esquina superior derecha.
			attack_zoom_texture:       Vector2(-80, 350),      # Esquina inferior izquierda.
			defense_zoom_texture:      Vector2(220, 350),      # Esquina inferior derecha.
			cooldown_zoom_texture:     Vector2(70, 130),       # Centro.
			ability_zoom_texture:      Vector2(-60, 210),      # Centro un poco más abajo.
		}

		for stat_zoom in corners:
			stat_zoom.visible = true
			stat_zoom.modulate.a = 0.0
			tween.tween_property(stat_zoom, "modulate:a", 1.0, 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(stat_zoom, "scale", Vector2(2, 2), 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(stat_zoom, "position", corners[stat_zoom], 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(0.08)
		
		
		was_zoomed_in_slot = false

func _process(delta: float) -> void:
	if board.pause_while_zoom:
		return
	
	var mouse_pos = get_global_mouse_position()
	var mouse_over = card_panel.get_global_rect().has_point(mouse_pos)

	# Buscar cuál es la carta que realmente está arriba bajo el ratón.
	var top_card := false

	if mouse_over:
		var hand = get_parent()

		for i in range(hand.get_child_count() - 1, -1, -1):
			var card = hand.get_child(i)

			if card.card_panel.get_global_rect().has_point(mouse_pos):
				top_card = (card == self)
				break

	# Control del hover para zoom.
	if not mouse_over or not top_card or zoom_active or cannot_zoom or hold_card or board.card_is_dragging:
		mouse_time = 0.0
		mouse_hovering = false
	else:
		mouse_hovering = true
		mouse_time += delta

		if mouse_time >= 1.5:
			mouse_time = 0.0

			if not in_hand:
				zoom_active = true
				restore_rotation(0.2)

	# Control de levantar carta.
	var should_raise = (
		top_card
		and in_hand
		and not is_in_slot
		and not hold_card
		and not zoom_active
		and not board.card_is_dragging
		and not zoom_active
	)

	if should_raise:
		if not is_raised and raise_tween == null:
			move_up(0.1)
	else:
		if is_raised and raise_tween == null:
			go_back_to_position(0.1)

	# Movimiento de arrastre.
	if hold_card and not zoom_active:
		card_panel.global_position = card_panel.global_position.lerp(
			mouse_pos - drag_offset,
			0.2
		)
		restore_rotation(0.2)

func move_up(duration: float) -> void:
	if raise_tween:
		raise_tween.kill()

	raise_tween = create_tween()
	
	# Recordar que negativo, en este caso, la manda para arriba.
	raise_tween.tween_property(self, "position:y", hand_position.y - 100, duration)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Esperar a que termine.
	raise_tween.tween_callback(func():
		raise_tween = null
		is_raised = true
	)

func go_back_to_position(duration: float) -> void:
	print("VOLVIENDO:", card_name)
	# Devolvemos a su posición original en la mano.
	if raise_tween:
		raise_tween.kill()

	raise_tween = create_tween()
	
	raise_tween.tween_property(self, "position:y", hand_position.y, duration)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Esperar a que termine.
	raise_tween.tween_callback(func():
		print("YA BAJÓ:", card_name)
		raise_tween = null
		is_raised = false
	)

# Volver a la rotación original.
func restore_rotation(duration: float):
	if zoom_active or cannot_zoom or hold_card or board.card_is_dragging or not in_hand:
		create_tween().tween_property(self, "rotation_degrees", original_rotation, duration)

func _on_plus_btn_pressed() -> void:
	if detail_panel_appeared:
		detail_panel_appeared = false
		
		var tween = create_tween()
		
		# Desvanecer el panel.
		tween.tween_property(detail_panel, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func(): detail_panel.visible = false)
		
		# Volver la carta al centro.
		var viewport_size = get_viewport().get_visible_rect().size
		var target_pos = viewport_size / 2 - card_zoom_size / 2
		tween.tween_property(card_panel, "global_position", target_pos, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Cambiar el texto de - a +.
		tween.tween_property(plus_btn, "modulate:a", 0.0, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func(): plus_btn.text = "+")
		tween.tween_property(plus_btn, "modulate:a", 1.0, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		return
	
	detail_panel_appeared = true
	detail_panel.visible = true
	
	var viewport_size = get_viewport().get_visible_rect().size
	var gap = 50
	
	# El panel usa tamaño fijo para que coincida con el diseño de sus hijos en la .tscn.
	detail_panel.size = DETAIL_SIZE
	
	# Centrar carta y panel juntos en pantalla.
	var total_width = card_zoom_size.x + gap + DETAIL_SIZE.x
	var start_x = viewport_size.x / 2 - total_width / 2
	var start_y = viewport_size.y / 2 - card_zoom_size.y / 2
	
	var target_pos_left = Vector2(start_x, start_y)
	
	# Detail se posiciona en global, justo a la derecha de la carta.
	detail_panel.global_position = Vector2(start_x + card_zoom_size.x + gap, start_y)
	
	# Crear animaciones.
	var tween = create_tween()
	
	# Mover la carta a la izquierda.
	tween.tween_property(card_panel, "global_position", target_pos_left, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Cambiar el texto de + a -.
	tween.tween_property(plus_btn, "modulate:a", 0.0, 0.15)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): plus_btn.text = "-")
	tween.tween_property(plus_btn, "modulate:a", 1.0, 0.15)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Hacer aparecer el panel con retraso.
	detail_panel.modulate.a = 0.0
	tween.parallel().tween_property(detail_panel, "modulate:a", 1.0, 0.8)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.5)

func _on_cancel_btn_pressed() -> void:
	print("Cancelar pulsado. zoom_active = ", zoom_active)
	mouse_hovering = false
	# Reiniciar el tiempo al cancelar.
	mouse_time = 0.0
	# Quitar el zoom.
	if zoom_active:
		zoom_active = false
		board.pause_while_zoom = false
		_hide_zoom()


func _on_basic_card_gui_input(event: InputEvent) -> void:
	if zoom_active or board.pause_while_zoom:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Cualquier pulsación nueva cancela un click simple pendiente.
			click_timer.stop()
			if event.double_click:
				if actions_showed:
					_deselect_card()
				_shake_card_effect()
				return
			
			# Aún no se arrastra, solo guardar dónde se pulsó.
			press_position = get_global_mouse_position()
			drag_offset = press_position - card_panel.global_position
			is_dragging = false
			mouse_hovering = false
			mouse_time = 0.0
		else:
			if is_dragging:
				hold_card = false
				is_dragging = false
				board.card_is_dragging = false
				restore_rotation(0.2)
				_try_drop_on_slot()
				# Organizar mano.
				board.organize_hand()
			else:
				# Esperar a ver si llega un segundo click.
				click_timer.start()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if not in_hand and event.pressed:
			zoom_active = true
			board.pause_while_zoom = true
			_show_zoom()

	elif event is InputEventMouseMotion:
		if not is_in_slot:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT and not is_dragging:
				if press_position.distance_to(get_global_mouse_position()) >= DRAG_THRESHOLD:
					is_dragging = true
					hold_card = true
					board.card_is_dragging = true
					board.organize_hand()
					print("Arrastrando carta...")


func _input(event: InputEvent) -> void:
	if not actions_showed:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _is_click_inside_card(get_global_mouse_position()):
			_deselect_card()


func _is_click_inside_card(point: Vector2) -> bool:
	if card_panel.get_global_rect().has_point(point):
		return true
	if atk_btn.visible and atk_btn.get_global_rect().has_point(point):
		return true
	if def_btn.visible and def_btn.get_global_rect().has_point(point):
		return true
	return false


func _deselect_card() -> void:
	cannot_zoom = false
	actions_showed = false
	
	var tween = create_tween()
	tween.tween_property(atk_btn, "position:y", atk_btn_original_pos.y, 0.4)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(def_btn, "position:y", def_btn_original_pos.y, 0.4)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(atk_btn, "modulate:a", 0.0, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(def_btn, "modulate:a", 0.0, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_callback(func():
		atk_btn.visible = false
		def_btn.visible = false
		atk_btn.disabled = true
		def_btn.disabled = true
	)

func _try_drop_on_slot() -> void:
	var mouse_pos = get_global_mouse_position()
	# Buscar todos los slots disponibles.
	var slots = get_tree().get_nodes_in_group("slots")
	for slot in slots:
		if slot.contains_point(mouse_pos):
			if slot == current_slot:
				# Se soltó sobre el mismo slot donde ya estaba: no hay
				# movimiento real, se queda tal cual (sigue ocupado por ella).
				card_panel.global_position = original_position_global
				return
			if slot.try_place_card(self):
				# El movimiento tuvo éxito: AHORA sí liberamos el slot antiguo
				# (si la carta venía de otro slot), nunca antes de saber que
				# el nuevo slot la aceptó.
				var previous_slot = current_slot

				# Crear animaciones.
				var tween = create_tween()

				# Mover la carta al centro del slot.
				# Usar get_global_rect() para obtener posición y tamaño reales del slot.
				var slot_rect = slot.get_global_rect()

				var target_scale = slot_rect.size / card_size
				slot_scale = target_scale
				card_panel.pivot_offset = Vector2.ZERO

				tween.tween_property(card_panel, "scale", target_scale, 0.3)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tween.parallel().tween_property(card_panel, "global_position", slot_rect.position, 0.3)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				
				slot_pos = slot_rect.position
				
				# Ocultar stats normales (se ven mal).
				for stat in [hp_border_texture, hp_text, hp_texture, 
				energy_cost_text, energy_cost_texture, energy_cost_border_texture,
				ability_text, attack_text, attack_texture, defense_text, defense_texture, 
				cooldown_text, cooldown_texture]:
					tween.parallel().tween_property(stat, "modulate:a", 0.0, 0.2)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				
				# Posiciones destino en esquinas (relativas al 300x400 de la carta).
				var corners = {
					hp_zoom_texture:           Vector2(-80, -15),           # Esquina superior izquierda.
					energy_cost_zoom_texture:  Vector2(220, -15),         # Esquina superior derecha.
					attack_zoom_texture:       Vector2(-80, 350),         # Esquina inferior izquierda.
					defense_zoom_texture:      Vector2(220, 350),       # Esquina inferior derecha.
					cooldown_zoom_texture:     Vector2(70, 130),       # Centro.
					ability_zoom_texture:      Vector2(-60, 210),      # Centro un poco más abajo.
				}

				for stat_zoom in corners:
					stat_zoom.visible = true
					stat_zoom.modulate.a = 0.0
					tween.tween_property(stat_zoom, "modulate:a", 1.0, 0.1)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					tween.parallel().tween_property(stat_zoom, "scale", Vector2(2, 2), 0.1)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					tween.parallel().tween_property(stat_zoom, "position", corners[stat_zoom], 0.1)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(0.08)

				# Actualizar la posición original por si se deselecciona después.
				tween.tween_callback(func():
					original_position_global = card_panel.global_position
				)
				is_in_slot = true
				in_hand = false
				board.organize_hand()
				current_slot = slot

				# Liberar el slot anterior ahora que la carta ya está oficialmente
				# en el nuevo. Si no existía (venía de la mano), no hace nada.
				if previous_slot != null:
					previous_slot.remove_card()
				return
	'''Si no cayó en ningún slot válido, volver a la posición anterior.
	Si la carta venía de un slot, ese slot sigue ocupado (no se tocó).
	Poner self, porque si se pone card_panel, 
	no funciona correctamente al solo afectar el panel en vez de todo.'''
	var tween = create_tween()
	tween.tween_property(card_panel, "global_position", original_position_global, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if in_hand:
		tween.parallel().tween_property(self, "rotation_degrees", hand_rotation, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	
func _on_card_left_clicked() -> void:
	if actions_showed or card_action_clicked or in_hand:
		return
	
	print("Click izquierdo sobre la carta...\nClick on hand: ", in_hand)
	cannot_zoom = true
	
	# Crear animaciones.
	var tween = create_tween()
	# Mover en vertical los botones, y que aparezcan de forma suave (si no está en la mano).
	tween.tween_property(atk_btn, "position:y", atk_btn.position.y - 150, 0.5)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(def_btn, "position:y", def_btn.position.y + 150, 0.5)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	atk_btn.modulate.a = 0.0
	tween.parallel().tween_property(atk_btn, "modulate:a", 1.0, 0.4)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	def_btn.modulate.a = 0.0
	tween.parallel().tween_property(def_btn, "modulate:a", 1.0, 0.4)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	atk_btn.visible = true
	def_btn.visible = true
	atk_btn.disabled = false
	def_btn.disabled = false
	
	actions_showed = true

# Efecto de sacudida en cartas para las habilidades.
func _shake_card_effect() -> void:
	if card_action_clicked or in_hand:
		return
	
	print("Activando habilidad de carta...")
	
	card_action_clicked = true
	cannot_zoom = true
	
	var tween = create_tween()
	
	var duration: float = 0.5
	var intensity: float = 8.0
	var num_shakes = 8
	var time_per_shake = duration / num_shakes
	
	var base_pos = card_panel.global_position
	
	for i in num_shakes:
		# Generar desplazamiento aleatorio en X e Y, definido por la intensidad.
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(card_panel, "global_position", base_pos + offset, time_per_shake)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Al final, vuelve a la posición original, de forma repentina.
	tween.tween_callback(func():
		card_panel.global_position = base_pos
	)
	
	action_clicked = 3
	_activate_action()

func _activate_action() -> void:
	action_texture.visible = true
	action_bg.visible = true
	
	# Color e icono varían según la acción.
	var target_color = null
	var target_icon = null
	
	action_texture.position = Vector2(125, -20)
	# Hacer el icono invisible al principio.
	action_texture.scale = Vector2(0, 0)
	
	# Crear animaciones.
	var tween = create_tween()
	
	# Cambiar icono y color dependiendo de la acción pulsada.
	match action_clicked:
		1:
			target_color = Color("#ff0a06")
			target_icon = preload("res://Images/Icono ataque.png")
		2:
			target_color = Color("#0065df")
			target_icon = preload("res://Images/Icono defensa.png")
		3:
			target_color = Color("#e3c500")
			target_icon = preload("res://Images/Icono habilidad.png")
		_:
			return # Acción no válida, regresa.
	
	action_texture.texture = target_icon
	action_bg.modulate.a = 0.0
	action_bg.color = target_color
	tween.tween_property(action_bg, "modulate:a", 1.0, 0.4)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property(action_bg, "modulate:a", 0.4, 0.2)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(action_bg, "color", target_color, 0.5)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Hacerlo enorme para efecto.
	tween.parallel().tween_property(action_texture, "scale", Vector2(2.5, 2.5), 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property(action_texture, "scale", Vector2(2, 2), 0.2)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_atk_btn_pressed() -> void:
	action_clicked = 1
	card_action_clicked = true
	_deselect_card()
	_activate_action()


func _on_def_btn_pressed() -> void:
	action_clicked = 2
	card_action_clicked = true
	_deselect_card()
	_activate_action() 
