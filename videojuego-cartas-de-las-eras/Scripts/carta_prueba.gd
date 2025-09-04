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
# Para no afectar a las demás cartas.
var is_dragged: bool = false

func _ready() -> void:
	card_label.text = text

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
				restore_rotation()

	# Mover mientras arrastramos.
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + offset


# Animar a rotación vertical (0°)
func straighten(duration: float = 0.3):
	if not is_dragged:
		is_dragged = true
		original_rotation = rotation_degrees # Guardar rotación original de la carta.
		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees", 0, duration)

# Restaurar su rotación original.
func restore_rotation(duration: float = 0.3):
	if is_dragged:
		is_dragged = false
		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees", original_rotation, duration)
