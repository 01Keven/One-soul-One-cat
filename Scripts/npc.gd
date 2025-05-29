extends Node3D

@export var npc_id: int = 0
@export var npc_name: String = "NPC"
@export var dialog_lines: Array[String]
@onready var miado: AudioStreamPlayer = $Miado
@onready var dialog_label: Label3D = $dialog_label
@onready var area: Area3D = $Area3D

var player_in_range := false
var is_talking := false
var current_line := 0
var player_camera: Camera3D

func _ready():
	dialog_label.text = "..."
	dialog_label.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	player_camera = get_viewport().get_camera_3d()

func _process(delta):
	if player_camera and dialog_label.visible:
		var cam_pos = player_camera.global_transform.origin
		var label_pos = dialog_label.global_transform.origin
		cam_pos.y = label_pos.y
		dialog_label.look_at(cam_pos, Vector3.UP)
		dialog_label.rotate_y(deg_to_rad(180))

	if player_in_range and Input.is_action_just_pressed("interact") and not is_talking:
		start_dialog()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		# Removido: _reset_dialog() → não queremos reiniciar o diálogo ao sair

func start_dialog():
	is_talking = true
	current_line = 0
	if miado.stream:
		miado.play()
	show_next_line()

func show_next_line():
	if current_line < dialog_lines.size():
		dialog_label.text = dialog_lines[current_line]
		dialog_label.visible = true
		current_line += 1
		await get_tree().create_timer(5.0).timeout
		show_next_line()
	else:
		is_talking = false
		dialog_label.visible = false
		dialog_label.text = ""

# (Opcional: Remova este método se não for mais usado)
func _reset_dialog():
	dialog_label.visible = false
	dialog_label.text = ""
	is_talking = false
	current_line = 0
