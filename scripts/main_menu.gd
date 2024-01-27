extends Control

@export var start_button : Button = null

var game_state = null

# Called when the node enters the scene tree for the first time.
func _ready():
	game_state = get_node("/root/GameState")
	
	if not start_button:
		push_error("Start button not registered to main menu!")
	else:
		start_button.pressed.connect(self._start_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	visible = game_state.main_menu_enabled

func _start_button_pressed():
	game_state.start()
