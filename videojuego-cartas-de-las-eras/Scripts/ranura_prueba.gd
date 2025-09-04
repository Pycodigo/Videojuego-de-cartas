extends Node2D

var occupied: bool = false
func can_accept_card() -> bool:
	return not occupied

func snap_card(card: Node2D):
	if can_accept_card():
		occupied = true
		card.global_position = global_position
		card.rotation_degrees = 0
