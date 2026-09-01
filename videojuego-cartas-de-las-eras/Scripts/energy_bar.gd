extends Control

# Nodos de la barra.
@onready var sandwatch_top: Panel = $Top
@onready var sandwatch_bottom: Panel = $Bottom
@onready var energy_label = $EnergyLabel

# Progreso de la barra de ambos paneles.
var total_height: float

# Material del shader del Top y Bottom.
var top_material: ShaderMaterial
var bottom_material: ShaderMaterial

# Valor actual
var progress: float = 0.5

# Cantidad de energía (actual y máxima).
var energy: int = 20
var max_energy: int = 40


func _ready() -> void:
	total_height = sandwatch_top.size.y + sandwatch_bottom.size.y
	top_material = sandwatch_top.material as ShaderMaterial
	bottom_material = sandwatch_bottom.material as ShaderMaterial
	
	# Lo iniciamos a 0 (en el tablero ya avisa la cantidad).
	spend_energy(0)


func spend_energy(amount: int) -> void:
	var old_energy := energy
	
	energy = max(energy - amount, 0)
	# Que no se pase del máximo.
	if energy > max_energy:
		energy = max_energy
	
	var tween := create_tween()
	
	tween.tween_method(
		func(value: float):
			energy_label.text = str(roundi(value)),
		float(old_energy),
		float(energy),
		0.4
	)
	
	var progress := float(energy) / float(max_energy)
	set_progress(progress)

func set_progress(new_progress: float, animate: bool = true) -> void:
	new_progress = clamp(new_progress, 0.0, 1.0)
	
	if not animate:
		progress = new_progress
		top_material.set_shader_parameter("progress", progress)
		bottom_material.set_shader_parameter("progress", progress)
		return
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_method(
		_update_progress,
		progress,
		new_progress,
		0.4
	)
	


func _update_progress(value: float) -> void:
	progress = value
	
	top_material.set_shader_parameter("progress", value)
	bottom_material.set_shader_parameter("progress", value)
