extends Control

@export var p1_bar: TextureProgressBar = null
@export var p2_bar: TextureProgressBar = null

var game_state = null

# Called when the node enters the scene tree for the first time.
func _ready():
	game_state = get_node("/root/GameState")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not game_state:
		return
	if game_state.lord:
		var love = game_state.lord.player_love
		if love < 0:
			love *= -1.0
			p1_bar.value = 0.0
			p2_bar.value = love
		else:
			p1_bar.value = love
			p2_bar.value = 0.0
			
		
