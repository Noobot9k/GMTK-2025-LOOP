extends Node

func _ready() -> void:
	preload("uid://2hlgssnsobk1")

func LoadMainLevel():
	get_tree().change_scene_to_file("uid://2hlgssnsobk1")
