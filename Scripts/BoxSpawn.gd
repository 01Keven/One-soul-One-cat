extends StaticBody3D

  # arraste o RigidBody3D aqui no editor

@export var object_scene: PackedScene

func destroy_and_spawn():
	var new_body = object_scene.instantiate()
	get_parent().add_child(new_body)  # adiciona ao mesmo nível
	new_body.global_transform = global_transform
	new_body.global_transform.origin += Vector3.UP * 0.5  # evitar atravessar o chão
	queue_free()
