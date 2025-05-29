extends Area3D

@export var player_path: NodePath  # Caminho para o nó do jogador
var player: Node = null

func _ready():
	# Conecta o sinal para detectar entrada de corpos
	connect("body_entered", Callable(self, "_on_body_entered"))

	# Garante que o player esteja atribuído ao iniciar
	if player_path != NodePath():
		player = get_node(player_path)

func _on_body_entered(body):
	if body == player:
		player.grant_extra_card_option()
