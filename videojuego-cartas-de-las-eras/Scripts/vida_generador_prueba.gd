extends Node2D

@onready var health_bar = $vida
@onready var needle = $agujaP
@onready var current_health_label = $vida_actual
@onready var max_health_label = $vida_max

@export var max_health: int = 1000
var current_health: int

# Animación de la aguja y vida.
var needle_animation: Tween = null
var health_animation: Tween = null

func _ready() -> void:
	current_health = max_health
	current_health_label.text = str(current_health)
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
	
	# Modificar rotación de la aguja: -90º completo, 270º vacío.
	var health_ratio = float(current_health) / float(max_health)
	var start_angle = -90.0
	var end_angle = 270.0
	var needle_rotation = lerp(start_angle, end_angle, 1.0 - health_ratio)
	
	# Animación de la aguja.
	if needle_animation and needle_animation.is_running():
		needle_animation.kill()
	needle_animation = create_tween()
	needle_animation.tween_property(needle, "rotation_degrees", needle_rotation, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Animación de la barra.
	if health_animation and health_animation.is_running():
		health_animation.kill()
	health_animation = create_tween()
	health_animation.tween_property(health_bar, "value", current_health, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Animación del número (vida actual).
	# Tween personalizado que interpola valores enteros y actualiza el label.
	var start_value = int(current_health_label.text)
	var animation_label = create_tween()
	animation_label.tween_method(
		func(v): current_health_label.text = str(int(v)),
		start_value, current_health, 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
