extends Area3D

@export var player_path: NodePath
@export var game_over_screen_path: NodePath
@export var timer_path: NodePath

var player: Node3D
var game_over_screen: CanvasLayer
var timer: Timer
var game_over_started := false

func _ready():
	player = get_node(player_path)
	game_over_screen = get_node(game_over_screen_path)
	timer = get_node(timer_path)

	# Garante que o Control está invisível no início
	game_over_screen.visible = false
	
	# Garante que o timer não esteja rodando
	timer.stop()

	# Conecta os sinais
	self.body_entered.connect(_on_body_entered)
	timer.timeout.connect(_on_timeout)

func _on_body_entered(body):
	if body == player and not game_over_started:
		game_over_started = true
		game_over_screen.visible = true
		timer.start(5.0)

func _on_timeout():
	get_tree().quit()
