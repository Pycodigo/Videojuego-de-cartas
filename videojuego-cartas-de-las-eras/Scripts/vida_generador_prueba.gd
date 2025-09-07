extends Node2D

@onready var health_bar = $vida
@onready var needle = $agujaP
@onready var current_heatlh_label = $vida_actual
@onready var max_health_label = $vida_max

@export var max_health: int = 1000
var current_health: int

func _ready() -> void:
	current_health = max_health
	current_heatlh_label.text = str(current_health)
	max_health_label.text = str(max_health)
	update_health_bar()
	
	# Test automático: cada segundo pierde 100 de vida
	var timer = Timer.new()
	timer.wait_time = 1
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.connect("timeout", Callable(self, "_test_damage"))
	
func _test_damage():
	take_damage(100)

func take_damage(amount: int):
	current_health = clamp(current_health - amount, 0, max_health)
	update_health_bar()

func heal(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)
	update_health_bar()

func update_health_bar():
	# Actualizar la barra.
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	current_heatlh_label.text = str(current_health)
	
	# Modificar rotación de la aguja: -90º completo, 270º vacío.
	var health_ratio = float(current_health) / float(max_health)
	var start_angle = -90.0
	var end_angle = 270.0
	var needle_rotation = lerp(start_angle, end_angle, 1.0 - health_ratio)
	
	# Tween para animar la aguja.
	var tween = create_tween()
	tween.tween_property(needle, "rotation_degrees", needle_rotation, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
