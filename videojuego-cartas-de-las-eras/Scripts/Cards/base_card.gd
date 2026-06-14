extends Control

# Atributos de la carta.
@export var card_name: String
@export var ability: Dictionary # Diccionario que describe la habilidad.
@export var ability_detailed: String # Explica la habilidad completa al hacer zoom.
@export var card_texture: Texture2D # Varía según cada carta.
@export var era_texture: Texture2D # Varía según la era designada.
@export var era_name: String
@export var hp: int
@export var energy_cost: int
@export var attack: int
@export var defense: int
@export var cooldown: int

# Nodos de la carta.
@onready var card_panel = $BasicCard
@onready var cart_art = $BasicCard/CardTexture
@onready var era_art = $BasicCard/EraTexture
@onready var name_text = $BasicCard/NameText
@onready var energy_cost_text = $BasicCard/EnergyText
@onready var ability_text = $BasicCard/AbilityText
@onready var hp_text = $BasicCard/HpText
@onready var attack_text = $BasicCard/AttackText
@onready var defense_text = $BasicCard/DefenseText
@onready var cooldown_text = $BasicCard/CooldownText

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
@onready var plus_button = $BasicCard/PlusButton
@onready var plus_text = $BasicCard/PlusButton/PlusText
@onready var cancel_button = $BasicCard/CancelButton
@onready var cancel_text = $BasicCard/CancelButton/CancelText

# Tamaño de la carta.
var card_size = Vector2(300, 400)
# Tamaño agrandado.
var card_zoom_size = Vector2(512, 700)

# Tamaño fijo del panel de detalles (debe coincidir con el diseño de la .tscn).
const DETAIL_SIZE = Vector2(912, 700)

# Guardar posiciones.
var original_position_global: Vector2
var original_position_local: Vector2

# Tiempo del ratón sobre la carta.
var mouse_time: float = 0.0
# Indicar que el ratón pasó por la carta.
var mouse_hovering: bool = false
# Determinar si la carta tiene zoom.
var zoom_active: bool = false
# Hacer que el panel de detalles aparezca solo una vez.
var detail_panel_appeared: bool = false


func _ready() -> void:
	init_card()

# Base de las cartas.
func init_card():
	if card_texture:
		cart_art.texture = card_texture
		cart_art.stretch_mode = TextureRect.STRETCH_SCALE
	if era_texture:
		era_art.texture = era_texture
		era_art.stretch_mode = TextureRect.STRETCH_SCALE
	name_text.text = card_name
	name_detail.text = card_name
	era_detail.text = era_name
	energy_cost_text.text = str(energy_cost)
	energy_cost_num_detail.text = str(energy_cost)
	ability_text.text = ability.get("name", "")
	ability_detail.text = ability.get("name", "")
	state_text_detail.text = ability.get("state", "")
	ability_description.text = ability.get("description", "")
	hp_text.text = str(hp)
	attack_text.text = str(attack)
	defense_text.text = str(defense)
	cooldown_text.text = str(cooldown)
	hp_num_detail.text = str(hp)
	atk_num_detail.text = str(attack)
	def_num_detail.text = str(defense)
	cooldown_num_detail.text = str(cooldown)
	
	# Ocultar el panel de la info al principio (y desactivar el botón).
	detail_panel.visible = false
	plus_button.visible = false
	plus_button.disabled = true
	plus_text.visible = false
	cancel_button.visible = false
	cancel_button.disabled = true
	cancel_text.visible = false
	
	# Guardar la posición inicial global de la carta.
	original_position_global = card_panel.global_position

# Zoom de la carta.
func _show_zoom() -> void:
	# Activar los botones para detalles (y cancelar).
	plus_button.visible = true
	plus_button.disabled = false
	plus_text.visible = true
	cancel_button.visible = true
	cancel_button.disabled = false
	cancel_text.visible = true
	
	var viewport_size = get_viewport().get_visible_rect().size
	var target_pos = viewport_size / 2 - card_zoom_size / 2
	var target_scale = card_zoom_size / card_size
	
	# Crear animación.
	var tween = create_tween()
	card_panel.pivot_offset = card_size / 2 # Escala desde el centro.
	
	# Posición y escala a la vez.
	tween.tween_property(card_panel, "global_position", target_pos, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card_panel, "scale", target_scale, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Los textos (y botones) tardan medio segundo más en aparecer (Para hacerlo más bonito).
	for text in [name_text, ability_text, attack_text, cooldown_text, 
	defense_text, energy_cost_text, hp_text, plus_text, cancel_text, plus_button, cancel_button]:
		text.modulate.a = 0.0
		tween.parallel().tween_property(text, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.5)

# Volver a tener la carta en tamaño normal.
func _hide_zoom() -> void:
	# Crear animación.
	var tween = create_tween()
	
	# Primero desvanece el panel de detalles si estaba visible.
	if detail_panel_appeared:
		detail_panel_appeared = false
		tween.tween_property(detail_panel, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func(): detail_panel.visible = false)
	
	# Posición y escala de la carta a la vez.
	tween.tween_property(card_panel, "global_position", original_position_global, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(card_panel, "scale", Vector2.ONE, 0.3)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	for text in [name_text, ability_text, attack_text, cooldown_text, 
	defense_text, energy_cost_text, hp_text]:
		tween.parallel().tween_property(text, "modulate:a", 1.0, 0.0)
		
	# Desvanecer botones en paralelo con la animación.
	for button in [plus_button, plus_text, cancel_button, cancel_text]:
		tween.parallel().tween_property(button, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Ocultar y desactivar al terminar.
	tween.tween_callback(func():
		plus_button.visible = false
		plus_button.disabled = true
		plus_text.visible = false
		cancel_button.visible = false
		cancel_button.disabled = true
		cancel_text.visible = false
	)
	
	tween.tween_callback(func(): plus_text.text = "+")

func _process(delta: float) -> void:
	if mouse_hovering and not zoom_active:
		# Inicializar el 'cronómetro' del ratón.
		mouse_time += delta
		if mouse_time >= 1.5:
			zoom_active = true
			_show_zoom()

func _on_mouse_entered() -> void:
	# Ponemos este bool, pues mouse_hovering solo se activa una vez.
	mouse_hovering = true

func _on_plus_button_pressed() -> void:
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
		tween.tween_property(plus_text, "modulate:a", 0.0, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func(): plus_text.text = "+")
		tween.tween_property(plus_text, "modulate:a", 1.0, 0.15)\
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
	tween.tween_property(plus_text, "modulate:a", 0.0, 0.15)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): plus_text.text = "-")
	tween.tween_property(plus_text, "modulate:a", 1.0, 0.15)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Hacer aparecer el panel con retraso.
	detail_panel.modulate.a = 0.0
	tween.parallel().tween_property(detail_panel, "modulate:a", 1.0, 0.8)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.5)

func _on_cancel_button_pressed() -> void:
	mouse_hovering = false
	# Reiniciar el tiempo al cancelar.
	mouse_time = 0.0
	# Quitar el zoom.
	if zoom_active:
		zoom_active = false
		_hide_zoom()
