extends CharacterBody3D

#SPRINT
@onready var sprint_ui: Control = $Icons_Alerts  # Node Control pai do ProgressBar
@onready var sprint_bar: TextureProgressBar = sprint_ui.get_node("jump_icon")
@onready var sprint_timer: Timer = $Timer
var is_sprinting := false

@export var initial_spawn_position: Vector3 = Vector3(0, 1, 0)  # Ajuste para o local seguro da sua cena

#CARDS MENU
var card_chosen := false
var can_jump_once := false
var pickup_enabled := false
var extra_card_granted := false

#BULLET
var bullets_left := 0  # Inicializa com 0
var weapon_enabled := false
var has_shot := false
var can_shoot := false
var current_bullet: RigidBody3D = null
@onready var pistol: Node3D = $"Camera3D/Pistol fbx"  # Arma principal
@onready var shoot_audio := $ShootAudio
@onready var error_audio := $ErrorAudio
var bullet_speed = 300.0
@onready var bullet_scene = preload("res://Scenes/bullet.tscn")
@onready var bullet_spawn_point = $"Camera3D/Pistol fbx/BulletSpawn"

@onready var pos: Node3D = $"Camera3D/Pistol fbx/Pistol/pos"


@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D
@onready var hand: Node3D = $Camera3D/Hand


var held_object: RigidBody3D = null

var speed
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

@export var walk_speed = 5.0
@export var sprint_speed = 8.0
@export var jump_velocity = 4.5
@export var mouse_sensitivy = 0.003
@export var cards_ui_path: NodePath  # Caminho para o Control 'Cards'

@export var bob_freq = 2.0
@export var bob_amp = 0.08
@export var t_bob = 0.0

@onready var camera: Camera3D = $Camera3D
@onready var cards_ui: Control = get_node(cards_ui_path)

# Botões
@onready var jump_button: Button = cards_ui.get_node("PanelContainer/HBoxContainer/Jump")
@onready var inventory_button: Button = cards_ui.get_node("PanelContainer/HBoxContainer/Inventory")
@onready var sprint_button: Button = cards_ui.get_node("PanelContainer/HBoxContainer/Sprint")
@onready var shoot_button: Button = cards_ui.get_node("PanelContainer/HBoxContainer/Shoot")

var ui_active := false

const gravity = 9.8

func _ready():
	# outras inicializações...
	var level_loader = get_node("/root/LevelLoader")  # ou caminho correto para o LevelLoader no seu projeto
	level_loader.connect("scene_loaded", Callable(self, "_on_scene_loaded"))


	sprint_ui.visible = false
	sprint_bar.value = 0.0
	sprint_timer.timeout.connect(_on_sprint_timeout)

	pistol.visible = false
	if not ui_active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Conecta cada botão a uma função
	jump_button.pressed.connect(_on_jump_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	sprint_button.pressed.connect(_on_sprint_button_pressed)
	shoot_button.pressed.connect(_on_shoot_button_pressed)
	cards_ui.visible = false
	#Dialogic.start("timeline")




func _input(event):
	if event.is_action_pressed("reset_game"):
		reset_current_level()

	if event.is_action_pressed("cards"):
		_toggle_cards_ui()

	elif not ui_active and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

		var motion = event.relative
		rotate_y(-motion.x * mouse_sensitivy)
		camera.rotation.x = clamp(
			camera.rotation.x - motion.y * mouse_sensitivy,
			deg_to_rad(-90),
			deg_to_rad(90)
		)

	# SOMENTE tenta atirar se arma estiver habilitada e visível
	if event.is_action_pressed("shoot") and weapon_enabled and pistol.visible:
		try_shoot()


func _physics_process(delta: float) -> void:
	if ui_active:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor() and can_jump_once:
		velocity.y = jump_velocity
		can_jump_once = false  # Pulo foi usado, desativa


	speed = sprint_speed if is_sprinting else walk_speed



	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 7.0)

	move_and_slide()
	



func try_shoot():
	if not weapon_enabled or not pistol.visible:
		error_audio.play()
		print("Erro: arma não habilitada")
		return
	
	if bullets_left <= 0:
		error_audio.play()
		print("Sem balas restantes!")
		return
	
	spawn_bullet()
	bullets_left -= 1
	shoot_audio.play()
	print("Disparo realizado. Balas restantes: ", bullets_left)




func spawn_bullet():
	var projectile = bullet_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = bullet_spawn_point.global_transform
	projectile.linear_velocity = bullet_spawn_point.global_transform.basis.z * -1 * bullet_speed
	current_bullet = projectile

	# Libera a referência após 3 segundos
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(current_bullet):
		current_bullet.queue_free()
	current_bullet = null


func _process(delta: float) -> void:
	if pickup_enabled and Input.is_action_pressed("pickup"):
		print("pegando item")
		if not held_object:
			if ray_cast_3d.is_colliding():
				var object = ray_cast_3d.get_collider()
				if object and object.is_in_group("pickable"):
					held_object = object
					held_object.freeze = true
					held_object.collision_layer = 2  # Desativa colisão com jogador, por exemplo
		else:
			# Enquanto segura, posiciona o objeto na frente da mão
			held_object.global_transform = hand.global_transform
	else:
		if held_object:
			print("soltando item, bloqueando de pegar novamente")
			# Solta o objeto ao soltar a tecla
			held_object.freeze = false
			held_object.collision_layer = 1  # Ou outro valor padrão que você usar
			held_object = null
			pickup_enabled = false  # Desativa pickup após soltar
	
	if is_sprinting:
		sprint_bar.value = (sprint_timer.time_left / sprint_timer.wait_time) * 100.0

func _on_sprint_timeout():
	is_sprinting = false
	sprint_ui.visible = false
	sprint_bar.value = 100.0

				

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

func _toggle_cards_ui():
	if card_chosen:
		return  # Impede reabrir se já escolheu uma opção

	ui_active = not ui_active
	cards_ui.visible = ui_active
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if ui_active else Input.MOUSE_MODE_CAPTURED


func _exit_cards_ui():
	ui_active = false
	cards_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	card_chosen = true  # Marca que o jogador já escolheu

# Funções de cada botão
func _on_jump_button_pressed():
	print("Pulo ativado!")
	can_jump_once = true
	_exit_cards_ui()

func _on_inventory_button_pressed():
	print("Modo Grab ativado! Sem arma.")
	disable_weapon_permanently()
	pickup_enabled = true
	_exit_cards_ui()



func _on_sprint_button_pressed():
	print("Correndo!")
	_exit_cards_ui()

	is_sprinting = true
	sprint_ui.visible = true
	sprint_bar.value = 0.0
	sprint_timer.start()

	# Inicialize o progresso da barra manualmente (valor vai de 0 a 100)
	sprint_bar.value = 0.0



func _on_shoot_button_pressed():
	print("Arma habilitada!")
	weapon_enabled = true
	pistol.visible = true

	bullets_left += 1  # Dá uma bala extra
	print("Bala extra concedida! Total de balas: ", bullets_left)

	await get_tree().create_timer(0.3).timeout  # Previne disparo acidental

	_exit_cards_ui()

	
func reset_current_level():
	var current_scene = get_tree().current_scene
	if current_scene:
		var current_scene_path = current_scene.scene_file_path

		# Encontra o ID correspondente ao caminho atual
		for id in LevelLoader.levels.keys():
			if LevelLoader.levels[id] == current_scene_path:
				LevelLoader.fade_to_scene_id(id)
				return
		print("ID da cena atual não encontrado para reset.")

func grant_extra_card_option():
	# remove o bloqueio extra_card_granted para poder abrir várias vezes
	card_chosen = false  # Permite que o jogador abra o menu novamente
	ui_active = false
	cards_ui.visible = false

	print("Agora você pode escolher uma carta extra!")

	# Exibe o menu de cards novamente, com botões habilitados
	_toggle_cards_ui()
	jump_button.disabled = false
	inventory_button.disabled = false
	sprint_button.disabled = false
	shoot_button.disabled = false

func enable_extra_card_choice():
	if ui_active:
		# Já está aberto, não faz nada
		return
	grant_extra_card_option()

	
func disable_weapon_permanently():
	weapon_enabled = false
	pistol.visible = false
	bullets_left = 0
	print("Arma removida permanentemente!")
