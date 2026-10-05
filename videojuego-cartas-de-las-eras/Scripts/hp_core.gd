extends Control

# Nodos del núcleo.
@onready var shield = $Shield
@onready var shield_border = $ShieldBorder
@onready var hp_lbl = $HpLabel
@onready var fragments = $Fragments

# Obtener el tablero (AI/Player -> board).
@onready var board = get_parent().get_parent()
# Exportar el detectar si es de IA o no.
@export var is_in_ai: bool = false

# Vida del núcleo.
var current_hp: int = 0
var max_hp: int = 180

# Recibió daño (esperar a que termine).
var damage_received: bool = false

# Inicio general de los puntos de las grietas.
var initial_point := Vector2(125, 125)
# Grieta que se está formando actualmente.
var current_crack_line: Line2D
var current_crack_points: PackedVector2Array
var current_crack_final: Vector2
var current_crack_level: int = -1

# Azul claro, gris oscuro.
var bright_color := Color("#35d6e8")
var dark_color := Color("#555555")

func _ready() -> void:
	print(get_path(), " -> is_in_ai: ", is_in_ai)
	current_hp = max_hp
	hp_lbl.text = str(current_hp)
	# Crear los lados del hexágono.
	var sides_hexagon = PackedVector2Array([
		Vector2(125, 25),  # Arriba.
		Vector2(225, 75), # Arriba-derecha.
		Vector2(225, 175), # Abajo-derecha.
		Vector2(125, 225), # Abajo.
		Vector2(25, 175),  # Abajo-izquierda.
		Vector2(25, 75)   # Arriba-izquierda.
	])
	# Crear los lados de cada rombo (en distintas posiciones).
	var sides_fragment = PackedVector2Array([
		Vector2(0, -25), # Arriba.
		Vector2(25, 0), # Derecha.
		Vector2(0, 25), # Abajo.
		Vector2(-25, 0) # Izquierda.
	])
	
	# Asignar.
	shield.polygon = sides_hexagon
	var sides_h_border = sides_hexagon.duplicate()
	sides_h_border.append(sides_hexagon[0])
	shield_border.points = sides_h_border
	
	for i in range(6):
		var fragment = fragments.get_child(i)
		var vertex = sides_hexagon[i]

		fragment.position = vertex 
		fragment.z_index = 1
		fragment.polygon = sides_fragment


func _on_gui_input(event: InputEvent) -> void:
	# No es el de la IA.
	if not is_in_ai:
		print("Salgo: este núcleo no es de la IA")
		return
	# No hay ataque en curso.
	if not board.attacking_card:
		print("Salgo: no hay cartas atacando.")
		return
	# La IA todavía tiene cartas en juego.
	if board.AI_slots_have_cards():
		print("Salgo: hay por lo menos una carta en juego.")
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed  and not damage_received:
			await receive_damage(board.attacking_card.actual_atk)
			update_fragments()
			# Solo ataca una vez.
			board.attacking_card._cannot_use_card()
			board.attacking_card = null
			board.pause_while_deciding = false
			

func receive_damage(damage: int) -> void:
	damage_received = true
	var tween = create_tween()
	
	# Quitar vida gradualmente.
	while damage > 0:
		damage -= 1
		current_hp -= 1
		
		if current_hp < 0:
			current_hp = 0
		
		var damage_taken = max_hp - current_hp
		if damage_taken % 15 == 0:
			create_lines()
		
		# Actualizar lo visual.
		hp_lbl.text = str(current_hp)
		await get_tree().create_timer(0.05).timeout
	
	# Crear grieta parcial.
	var damage_taken = max_hp - current_hp
	
	if damage_taken > 0 and damage_taken % 15 != 0:
		create_lines()
	damage_received = false

# Cambiar los colores de los rombos.
func update_fragments() -> void:
	print("HP al actualizar rombos: ", current_hp)
	var damage_taken = max_hp - current_hp
	var fragments_damage = damage_taken / 30.0

	for i in range(6):
		var fragment = fragments.get_child(i)

		# Cuánto daño corresponde a cada rombo.
		var fragment_progress = clamp(fragments_damage - i, 0.0, 1.0)

		var new_color = bright_color.lerp(dark_color, fragment_progress)
		
		# Animar cambio de color.
		var tween = create_tween()
		tween.tween_property(fragment, "color", new_color, 0.3)

# Crear una grieta.
func create_crack(initial, final, points_amount) -> PackedVector2Array:
	 # Guardar los puntos creados.
	var points = PackedVector2Array()
	points.append(initial)
	
	for i in range(1, points_amount - 1):
		# Conseguir los puntos intermedios (sin contar inicio ni final).
		var t = i / float(points_amount - 1)
		
		var point = initial.lerp(final, t)
		point += Vector2(
			randf_range(-8, 8),
			randf_range(-8, 8)
		)
		
		# Guardar intermedios.
		points.append(point)
	
	points.append(final)
	return points

func create_random_final_point() -> Vector2:
	# Lados del hexágono.
	var sides = [
		[Vector2(125, 25), Vector2(225, 75)],
		[Vector2(225, 75), Vector2(225, 175)],
		[Vector2(225, 175), Vector2(125, 225)],
		[Vector2(125, 225), Vector2(25, 175)],
		[Vector2(25, 175), Vector2(25, 75)],
		[Vector2(25, 75), Vector2(125, 25)]
	]
	
	# Elegir un lado al azar.
	var side = sides.pick_random()
	
	# Elegir una posición aleatoria dentro del lado.
	var t = randf()
	
	# Calcular el punto final.
	var final_point = side[0].lerp(side[1], t)
	
	return final_point
	
# Animar una grieta.
func animate_crack(points: PackedVector2Array) -> void:
	var line = Line2D.new()
	line.width = 3
	line.default_color = Color.BLACK
	
	# Empezar únicamente con el primer punto.
	line.add_point(points[0])
	add_child(line)
	
	# Ir añadiendo el resto de puntos.
	for i in range(1, points.size()):
		await get_tree().create_timer(0.05).timeout
		line.add_point(points[i])


# Dibujarlas.
func create_lines() -> void:
	print("HP al crear grietas: ", current_hp)
	
	var damage_taken = max_hp - current_hp
	var damage_level = int(damage_taken / 15.0)
	var crack_progress = fmod(damage_taken, 15.0) / 15.0
	
	# Hemos empezado un nuevo tramo de 15 de daño.
	if damage_level != current_crack_level:
		
		current_crack_level = damage_level
		
		# Crear un nuevo recorrido completo.
		current_crack_final = create_random_final_point()
		current_crack_points = create_crack(
			initial_point,
			current_crack_final,
			6
		)
		
		# Crear la línea de este tramo.
		current_crack_line = Line2D.new()
		current_crack_line.width = 3
		current_crack_line.default_color = Color.BLACK
		add_child(current_crack_line)
		
		# Si acabamos de llegar exactamente a 15, 30, 45...
		# la grieta aparece completa.
		if damage_taken > 0 and damage_taken % 15 == 0:
			current_crack_line.points = current_crack_points
		else:
			update_current_crack(crack_progress)
			
			# Animarla al aparecer.
			for i in range(1, current_crack_line.points.size()):
				await get_tree().create_timer(0.05).timeout
		
	# El tramo actual ya existe: simplemente lo hacemos más largo.
	else:
		update_current_crack(crack_progress)
	
	# Las ramas solo se crean cuando completamos un tramo.
	if damage_taken > 0 and damage_taken % 15 == 0:
		
		var branch_amount = randi_range(
			max(0, damage_level - 1),
			min(12, damage_level + 1)
		)
		
		for i in range(branch_amount):
			# Obtener el origen de cada rama.
			var branch_index = randi_range(
				1,
				current_crack_points.size() - 2
			)
			
			var branch_point = current_crack_points[branch_index]
			var branch_final = create_random_final_point()
			
			# Cantidad aleatoria.
			var branch_points_amount = randi_range(3, 6)
			
			# Crear la grieta.
			var crack_points = create_crack(
				branch_point,
				branch_final,
				branch_points_amount
			)
			
			# Animarla.
			animate_crack(crack_points)


# Actualizar la longitud de la grieta actual.
func update_current_crack(progress: float) -> void:
	if not current_crack_line:
		return
	
	var new_points = PackedVector2Array()
	
	for point in current_crack_points:
		var new_point = initial_point.lerp(
			point,
			progress
		)
		
		new_points.append(new_point)
	
	current_crack_line.points = new_points
