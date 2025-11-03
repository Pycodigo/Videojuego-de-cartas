extends CanvasLayer

@onready var main_label = $VBoxContainer/mensaje
@onready var sub_label = $VBoxContainer/submensaje
@onready var bg = $Panel
@onready var register_btn = $VBoxContainer/HBoxContainer/registro
@onready var exit_btn = $VBoxContainer/HBoxContainer/salir

func _ready() -> void:
	visible = false
	if not bg: 
		scale = Vector2(0.8, 0.8)
	else:
		scale = Vector2(1, 1)
	bg.modulate = Color(1, 1, 1, 0.3)

func show_victory(is_player_winner: bool):
	visible = true

	if is_player_winner:
		main_label.text = "¡Victoria!"
		sub_label.text = "Has derrotado a tu oponente."
	else:
		main_label.text = "Derrota..."
		sub_label.text = "Tu generador ha sido destruido."
	
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# Animar opacidad y escala al mismo tiempo
	tween.tween_property(bg, "modulate:a", 1.0, 0.6)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.6)
