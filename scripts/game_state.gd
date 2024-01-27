extends Node

var main_menu_enabled = true
var hud_enabled = false
var gameplay_enabled = false

var camera = null
var lord = null
var player_one = null
var player_two = null

func reset():
	if lord:
		lord.reset()
	else:
		push_error("Lord character not registered to game state.")
	
	if player_one:
		player_one.reset()
	else:
		push_error("Player one not registered to game state.")
	
	if player_two:
		player_two.reset()
	else:
		push_error("Player two not registered to game state.")

func register_lord_character(l):
	if lord == l:
		return
	if lord:
		lord.queue_free()
	lord = l
	
func register_player_one(p):
	if player_one == p:
		return
	if player_two == p:
		player_two = player_one
		player_one = p
		return
	if player_one:
		player_one.queue_free()
	player_one = p
	
func register_player_two(p):
	if player_two == p:
		return
	if player_one == p:
		player_one = player_two
		player_two = p
		return
	if player_two:
		player_two.queue_free()
	player_two = p

func start():
	main_menu_enabled = false
	# TODO: tween camera before `_enable_gameplay`
	_enable_gameplay()

func _enable_gameplay():
	hud_enabled = true
	gameplay_enabled = true

