extends Control

# Nodos de la barra.
@onready var energy_label = $BatteryHat/EnergyLabel
@onready var segments: Array[Panel] = [
	$Segment1,
	$Segment2,
	$Segment3,
	$Segment4,
	$Segment5
]

# Material del shader de los segmentos.
var segment_materials: Array[ShaderMaterial] = []
# Progreso de la barra de ambos paneles.
var total_height: float

# Valor actual
var progress: float = 0.5

# Cantidad de energía (actual y máxima).
var energy: int = 20
var max_energy: int = 40


func _ready() -> void:
	for i in segments.size():
		segments[i].material = segments[i].material.duplicate()
		segment_materials.append(segments[i].material as ShaderMaterial)
		segment_materials[i].set_shader_parameter("segment_index", i)
	
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
		
		for material in segment_materials:
			material.set_shader_parameter("progress", progress)
		
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
	
	for material in segment_materials:
		material.set_shader_parameter("progress", value)
