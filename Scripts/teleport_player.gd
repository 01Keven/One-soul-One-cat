extends Area3D

@export var player_path: NodePath
@export var teleport_marker: Marker3D

var player: Node3D
var teleporting := false

func _ready():
	player = get_node(player_path)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body == player and not teleporting:
		teleporting = true
		await teleport_with_fade()
		teleporting = false

func teleport_with_fade():
	await _start_fade_out()
	player.global_transform.origin = teleport_marker.global_transform.origin
	await get_tree().create_timer(0.1).timeout
	await _start_fade_in()

func _start_fade_out():
	var fade_rect = get_fade_rect()
	if not fade_rect:
		push_error("FadeRect não encontrado.")
		return

	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _start_fade_in():
	var fade_rect = get_fade_rect()
	if not fade_rect:
		push_error("FadeRect não encontrado.")
		return

	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func get_fade_rect() -> ColorRect:
	# Substitua "TransitionManager" pelo nome real do seu autoload se necessário
	if "LevelLoader" in ProjectSettings.get_setting("autoload/LevelLoader"):
		return LevelLoader.fade_rect
	elif has_node("/root/TransitionManager"):
		return get_node("/root/TransitionManager").fade_rect
	else:
		return null
