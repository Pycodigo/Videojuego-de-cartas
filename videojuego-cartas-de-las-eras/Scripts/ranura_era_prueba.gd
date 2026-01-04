extends Node2D

var occupied: bool = false
var current_era: Node = null

func set_era(era: BaseEra):
	current_era = era
	occupied = true
	era.global_position = global_position

func clear_era():
	current_era = null
	occupied = false
