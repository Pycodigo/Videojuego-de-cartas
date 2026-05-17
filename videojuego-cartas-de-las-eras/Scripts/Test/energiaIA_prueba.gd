extends Panel

@onready var AIenergy_bar = $ProgressBar
@onready var AIcurrent_energy_label = $Label

@export var AImax_energy: int = 150
var AIcurrent_energy: int

var AIenergy_animation: Tween = null

func _ready() -> void:
	AIcurrent_energy = AImax_energy
	AIcurrent_energy_label.text = str(AIcurrent_energy)
	update_energy_bar()

# Restar energía al usar un ataque o habilidad.
func consume_energy(amount: int):
	if AIcurrent_energy < amount:
		print("No tienes suficiente energía.")
		return
	
	AIcurrent_energy = clamp(AIcurrent_energy - amount, 0, AImax_energy)
	update_energy_bar()

# Recuperar energía al pasar turno.
func recover_energy(amount: int):
	AIcurrent_energy = clamp(AIcurrent_energy + amount, 0, AImax_energy)
	update_energy_bar()

func update_energy_bar():
	# Animación de la barra.
	if AIenergy_animation and AIenergy_animation.is_running():
		AIenergy_animation.kill()
	AIenergy_animation = create_tween()
	AIenergy_animation.tween_property(AIenergy_bar, "value", AIcurrent_energy, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Animación del número (energía actual).
	# Tween personalizado que interpola valores enteros y actualiza el label.
	var start_value = int(AIcurrent_energy_label.text)
	var animation_label = create_tween()
	animation_label.tween_method(
		func(v): AIcurrent_energy_label.text = str(int(v)),
		start_value, AIcurrent_energy, 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Revisar si está sin energía.
	if AIcurrent_energy <= 0:
		AIcurrent_energy = 0
		print("Te has quedado sin energía.")
