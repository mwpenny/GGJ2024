extends Node3D

var game_state = null

func _ready():
	game_state = get_node("/root/GameState")

	var player_one = get_node("Player1")
	player_one.init(1)
	game_state.register_player_one(player_one)

	var player_two = get_node("Player2")
	player_two.init(2)
	game_state.register_player_two(player_two)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_death(player):
	# TODO: game end screen
	if player == game_state.player_one:
		print("Player 1 died")
	else:
		print("Player 2 died")

	player.global_position = Vector3(0, 10, 0)
