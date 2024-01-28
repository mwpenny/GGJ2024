extends Node3D

var game_state = null

var ball = preload("res://scenes/ball.tscn")

@export var colorArray: Array[Color] = []

func _ready():
	game_state = get_node("/root/GameState")

	var player_one = get_node("Player1")
	player_one.init(1)
	game_state.register_player_one(player_one)

	var player_two = get_node("Player2")
	player_two.init(2)
	game_state.register_player_two(player_two)
	
	start_falling_balls()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_death(player):
	# TODO: game end screen
	if player == game_state.player_one:
		print("Player 1 died")
	else:
		print("Player 2 died")

	player.global_position = Vector3(player.score_mult * -3, 10, 0)
	
func spawn_falling_ball():
	var new_ball = ball.instantiate()
	
	# Set the radius and center position of the 3D circle
	var radius = 23
	var centerPos = Vector3(0, 20, 0)

	# Generate a random angle in radians
	var randomAngle = randf_range(0, 2 * PI)
	var randomDistance = randf_range(0, radius)

	# Calculate the random point's position within the 3D circle
	var randomX = centerPos.x + randomDistance * cos(randomAngle)
	var randomZ = centerPos.z + randomDistance * sin(randomAngle)
	var randomY = centerPos.y

	# Create a Vector3 with the random point's position
	var randomPoint = Vector3(randomX, randomY, randomZ)
	
	$Balls.add_child(new_ball)
	new_ball.global_transform.origin = randomPoint

func start_falling_balls():
	# Start a timer that will call the spawn_falling_ball function every 0.5
	# seconds
	$BallSpawnTimer.start()

func stop_falling_balls():
	# Stop the timer
	$BallSpawnTimer.stop()
