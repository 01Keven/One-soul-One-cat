extends StaticBody3D

@export var break_delay: float = 1.0
@export var broken_version: PackedScene  # prefab da plataforma em forma de RigidBody3D

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		break_platform()

func break_platform():
	await get_tree().create_timer(break_delay).timeout
	
	if not is_instance_valid(self):
		return
	
	# Instancia a versão quebrável
	var falling_platform = broken_version.instantiate()
	get_parent().add_child(falling_platform)
	falling_platform.global_transform = global_transform
	
	queue_free()
