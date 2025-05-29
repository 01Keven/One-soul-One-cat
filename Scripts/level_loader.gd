extends Node
signal scene_loaded(new_scene)

var fade_layer: CanvasLayer
var fade_rect: ColorRect
var next_scene_path: String = ""
var levels = {
	1: "res://Scenes/main.tscn",
	2: "res://Scenes/Levels/level_1.tscn",
	3: "res://Scenes/Levels/level_2.tscn",
	4: "res://Scenes/Levels/level_3.tscn"
}

func _ready():
	# Cria o canvas acima de tudo
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)

	# Cria o retângulo preto para o fade
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchor_left = 0
	fade_rect.anchor_top = 0
	fade_rect.anchor_right = 1
	fade_rect.anchor_bottom = 1
	fade_rect.offset_left = 0
	fade_rect.offset_top = 0
	fade_rect.offset_right = 0
	fade_rect.offset_bottom = 0
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # <--- ESSA LINHA AQUI
	fade_layer.add_child(fade_rect)

#func load_saved_level():
	#SaveManager.load_game()
	#var id = SaveManager.saved_data.get("level_id", 1)
	#fade_to_scene_id(id)

func fade_to_scene_id(id: int):
	if not levels.has(id):
		print("ID de fase inválido: ", id)
		return
	next_scene_path = levels[id]
	await _start_fade_out()
	get_tree().change_scene_to_file(next_scene_path)
	await get_tree().create_timer(0.1).timeout
	await _start_fade_in()

func _start_fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _start_fade_in():
	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
func reset_current_scene():
	for id in levels:
		if levels[id] == get_tree().current_scene.scene_file_path:
			load_scene_by_id(id)
			return

func load_scene_by_id(scene_id: int):
	if scene_id in levels:
		var path = levels[scene_id]
		var scene = load(path)
		var new_scene = scene.instantiate()
		get_tree().root.call_deferred("add_child", new_scene)
		
		if get_tree().current_scene:
			get_tree().current_scene.queue_free()
		
		get_tree().current_scene = new_scene
		emit_signal("scene_loaded", new_scene)
	else:
		push_error("Scene ID inválido: %d" % scene_id)
