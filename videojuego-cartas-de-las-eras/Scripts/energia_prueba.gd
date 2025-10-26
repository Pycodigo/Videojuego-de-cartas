extends Panel

@onready var energy_bar = $ProgressBar
@onready var current_energy_label = $Label

@export var max_energy: int = 150
var current_energy: int

var energy_animation: Tween = null

func _ready() -> void:
	current_energy = max_energy
	current_energy_label.text = str(current_energy)
	update_energy_bar()

# Restar energía al usar un ataque o habilidad.
func consume_energy(amount: int):
	if current_energy < amount:
		print("No tienes suficiente energía.")
		return
	
	current_energy = clamp(current_energy - amount, 0, max_energy)
	update_energy_bar()

# Recuperar energía al pasar turno.
func recover_energy(amount: int):
	current_energy = clamp(current_energy + amount, 0, max_energy)
	update_energy_bar()

func update_energy_bar():
	# Animación de la barra.
	if energy_animation and energy_animation.is_running():
		energy_animation.kill()
	energy_animation = create_tween()
	energy_animation.tween_property(energy_bar, "value", current_energy, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Animación del número (energía actual).
	# Tween personalizado que interpola valores enteros y actualiza el label.
	var start_value = int(current_energy_label.text)
	var animation_label = create_tween()
	animation_label.tween_method(
		func(v): current_energy_label.text = str(int(v)),
		start_value, current_energy, 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Revisar si está sin energía.
	if current_energy <= 0:
		current_energy = 0
		print("Te has quedado sin energía.")
