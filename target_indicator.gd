extends Node3D

const LIFETIME = 3.0

var time_elapsed = 0
var game_state = null

func _ready():
	game_state = get_node("/root/GameState")

func _process(_delta):
	time_elapsed += _delta
	if time_elapsed >= LIFETIME:
		game_state.lord.finish_targeting()
		queue_free()
