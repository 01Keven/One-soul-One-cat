extends Area3D

@export var targets_to_remove: Array[Node3D] = []

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body is RigidBody3D and body.is_in_group("pickable"):
		for target in targets_to_remove:
			if is_instance_valid(target):
				target.queue_free()
		#queue_free()  # Opcional: remove a própria área após a ativação
