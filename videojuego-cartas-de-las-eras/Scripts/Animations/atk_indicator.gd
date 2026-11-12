extends Control

# Exportar a animación.
@export var line_progress: float

# Nodos.
@onready var line = $Line2D
@onready var marker = $Marker
@onready var borders = $Marker/Borders
@onready var anim: AnimationPlayer = $AnimationPlayer

enum State { APPEAR, SELECT, ENTERING, INVALID, WAITING_VALID, WAITING_INVALID, EXITING }
var state: State = State.APPEAR
var transition_id: int = 0 # Evita que colapsen las animaciones.

var init_point
var final_point

# Guardar para tener la carta de referencia.
var card: Panel

func _process(delta: float) -> void:
	# Hacer que el marcador siga al ratón, centrado.
	marker.global_position = get_global_mouse_position() - marker.pivot_offset
	
	if card == null:
		return
	update_atk_line()

func set_line_atk(panel: Panel) -> void:
	if panel == null:
		return
	card = panel

	init_point = card.global_position + Vector2(card.size.x / 4.0, 0)
	var local_init_point = line.to_local(init_point)

	# Crear los dos puntos inicialmente en el origen.
	line.clear_points()
	line.add_point(local_init_point)
	line.add_point(local_init_point)

# Obtener punto de origen de la línea.
func update_atk_line() -> void:
	# Evitar errores.
	if card == null:
		return
	
	init_point = card.global_position + Vector2(card.size.x / 4.0, 0)
	var local_init_point = line.to_local(init_point)

	final_point = get_global_mouse_position() + Vector2(borders.size.x / 3.0, borders.size.y / 2.0)
	var local_final_point = line.to_local(final_point)

	# Interpolar entre ambos puntos.
	var current_point = lerp(local_init_point, local_final_point, line_progress)

	# Actualizar los puntos.
	line.set_point_position(0, local_init_point)
	line.set_point_position(1, current_point)

func get_current_target() -> Control:
	var hovered = get_viewport().gui_get_hovered_control()
	var iterations = 0

	while hovered != null:
		print("Buscando objetivo: ", hovered.name)

		if hovered.name == "BasicCard" or hovered.name == "HpCore":
			return hovered

		hovered = hovered.get_parent()
		iterations += 1

		if iterations > 20:
			print("ERROR: demasiados padres")
			return null

	return null
