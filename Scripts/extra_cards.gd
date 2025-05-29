extends RigidBody3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var already_activated = false

func _ready():
	animation_player.play("idle")
	max_contacts_reported = 1
	contact_monitor = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if already_activated:
		return

	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider and collider.is_in_group("player"):
			print("Colidiu com o player!")
			if collider.has_method("enable_extra_card_choice"):
				collider.enable_extra_card_choice()
				print("Método enable_extra_card_choice() chamado!")

			already_activated = true
			call_deferred("queue_free")
