extends RigidBody3D

@export var speed: float = 500.0

func _ready():
	# Ativa monitoramento de colisões
	contact_monitor = true
	max_contacts_reported = 1
	connect("body_entered", _on_body_entered)

	# Aplica impulso para frente (-Z)
	apply_impulse(-global_transform.basis.z * speed)

	# Autodestrói após 3 segundos
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("destructible"):
		if body.has_method("destroy_and_spawn"):
			body.destroy_and_spawn()
		queue_free()  # destrói a bala
