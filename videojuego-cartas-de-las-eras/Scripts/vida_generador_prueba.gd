extends Node2D

@onready var health_bar = $vida
@onready var needle = $agujaP

@export var max_health: int = 1000
var current_health: int
