# phase_loader_area.gd
extends Area3D

@export var level_id: int = 1

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		LevelLoader.fade_to_scene_id(level_id)
