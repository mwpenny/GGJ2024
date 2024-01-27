extends Node

var game_state = null

# Called when the node enters the scene tree for the first time.
func _ready():
	game_state = get_node("/root/GameState")
	game_state.register_lord_character(self)

func _process(_delta):
	if not game_state.gameplay_enabled:
		return
