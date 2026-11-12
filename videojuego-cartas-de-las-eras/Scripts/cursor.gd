extends TextureRect

@export var follow_speed: float = 20.0
@export var rotation_speed: float = 15.0
@export var click_rotation: float = 12.5

func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	position = get_global_mouse_position()

func _process(delta: float) -> void:
	# Factor de suavizado independiente de los FPS.
	var smooth := 1.0 - exp(-follow_speed * delta)

	# Seguimiento del ratón.
	global_position = global_position.lerp(
		get_global_mouse_position(),
		smooth
	)

	# Rotación al pulsar.
	var desired_rotation := click_rotation if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0.0

	rotation_degrees = lerp(
		rotation_degrees,
		desired_rotation,
		1.0 - exp(-rotation_speed * delta)
	)
