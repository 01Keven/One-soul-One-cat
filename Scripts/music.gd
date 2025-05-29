extends Node

#@onready var music_player = AudioStreamPlayer.new()
@onready var music_player: AudioStreamPlayer = $"SurfaceOfTheMoon-JohnPatitucci"

func _ready():
	add_child(music_player)
	music_player.stream = load("res://Sounds/Surface of the Moon - John Patitucci.mp3")
	music_player.loop = true
	music_player.play()
