extends Control

signal remove_requested(filter_key)

var filter_key: String # Filtro específico que se borra.

@onready var filter_text: Label = $PanelContainer/HBoxContainer/FilterTagText

func setup(filter_name: String, value: String) -> void:
	filter_key = filter_name
	filter_text.text = str(value)

func _on_delete_btn_pressed() -> void:
	remove_requested.emit(filter_key)
