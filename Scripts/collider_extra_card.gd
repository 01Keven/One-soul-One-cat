extends Area3D

@export var card_type: String = "ExtraCard"  # ou outro identificador útil

func _ready():
	# Conectando o sinal de forma segura
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):  # mais robusto do que checar o nome
		print("Player entrou na área do card!")

		if body.has_method("grant_extra_card_option"):
			body.grant_extra_card_option()

		# Destroi o Area3D de forma segura no próximo frame
		call_deferred("queue_free")
