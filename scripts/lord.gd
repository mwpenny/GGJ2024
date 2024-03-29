extends RigidBody3D

@export var visuals_root : Node3D = null
@export var animation_tree : AnimationTree = null
@export var laugh_particles : GPUParticles3D
@export var center_marker : Node3D = null
@export var south_marker : Node3D = null
@export var movable_target : Node3D = null

@export var target_indicator_scene : PackedScene

var game_state = null

enum AIState {
	THINK,
	RETURN_TO_CENTER,
	PRE_CHASE,
	CHASE,
	TARGET_GROUND_POUND,
	GROUND_POUND
}

const GROUND_POUND_PHASE_COUNT = 5
const CHASE_LOVE_DECAY_MULT = 0.04 
const SCOOT_SPEED = 0.6
const WALK_SPEED = 1.0
const RUN_SPEED = 3.5
const TORPEDO_SPEED = 4.3
const THINK_TIME = 2.0
const SCOOT_WAIT_TIME = 1.0
const MAX_ROTATION = 0.9
const MAX_LOVE = 75

var last_scoot_was_left: bool = false
var awaiting_scoot: bool = true
var state_machine = AIState.THINK
var state_timer: float = THINK_TIME
var movement_speed = 0
var player_love = 0.0
var follow_target = null
var fart_target = null
var normalized_movement_vector = Vector2(0,1)
var await_scoot_timer = SCOOT_WAIT_TIME
var scoot_count = 0
var collisions = []

var ground_pound_count = 0
var ground_pound_in_air = false
var ground_pound_targeting = false

# Called when the node enters the scene tree for the first time.
func _ready():
	game_state = get_node("/root/GameState")
	game_state.register_lord_character(self)

func _process(delta):
	if not game_state.gameplay_enabled:
		return
	
	if state_machine == AIState.THINK:
		_do_think(delta)
	if state_machine == AIState.RETURN_TO_CENTER:
		_do_return_to_center(delta)
	elif state_machine == AIState.PRE_CHASE:
		_do_pre_chase(delta)
	elif state_machine == AIState.CHASE:
		_do_chase(delta)
	elif state_machine == AIState.TARGET_GROUND_POUND:
		_do_ground_pound_target(delta)
	elif state_machine == AIState.GROUND_POUND:
		_do_ground_pound(delta)

	_handle_laughter()

func _reset_animations():
	scoot_count = 0
	animation_tree.set("parameters/conditions/idle_or_special", false)
	animation_tree.set("parameters/conditions/is_running", false)
	animation_tree.set("parameters/conditions/is_swinging", false)
	animation_tree.set("parameters/conditions/is_walking", false)
	animation_tree.set("parameters/conditions/is_wiggling_left", false)
	animation_tree.set("parameters/conditions/is_wiggling_right", false)

func _change_state(state):
	print("Changing state to %d. Love is now %f..." % [state, player_love])
	_reset_animations()
	movement_speed = 0.0
	state_machine = state
	if state_machine == AIState.THINK:
		state_timer = THINK_TIME
	elif state_machine == AIState.PRE_CHASE:
		_update_follow_target()
		state_timer = 3.0
	elif state_machine == AIState.CHASE:
		awaiting_scoot = true
		state_timer = 10.0
	elif state_machine == AIState.GROUND_POUND:
		state_timer = 3.0

func _do_think(delta):
	animation_tree.set("parameters/conditions/idle_or_special", true)
	state_timer -= delta
	if state_timer <= 0:
		var next_states = [
			AIState.PRE_CHASE,
			AIState.TARGET_GROUND_POUND,
		]
		_change_state(
			next_states[randi() % len(next_states)]
		)

func _update_follow_target():
	if player_love == 0:
		var choices = [game_state.player_one, game_state.player_two]
		follow_target = choices[randi() % len(choices)]
		return
	if player_love > 0:
		follow_target = game_state.player_two
		return
	follow_target = game_state.player_one

func _do_chase(delta):
	state_timer -= delta
	var love_amplitude = abs(player_love)
	if love_amplitude == 0:
		animation_tree.set("parameters/conditions/idle_or_special", true)
		movement_speed = 0.0
	elif love_amplitude < 2.0:
		animation_tree.set("parameters/conditions/idle_or_special", true)
		if awaiting_scoot:
			movement_speed = 0.0
			if await_scoot_timer > 0:
				await_scoot_timer -= delta
			else:
				awaiting_scoot = false
				animation_tree.set("parameters/conditions/is_wiggling_left", not last_scoot_was_left)
				animation_tree.set("parameters/conditions/is_wiggling_right", last_scoot_was_left)
				last_scoot_was_left = not last_scoot_was_left
		else:
			movement_speed = SCOOT_SPEED
	elif love_amplitude < 4.0:
		animation_tree.set("parameters/conditions/is_running", false)
		animation_tree.set("parameters/conditions/idle_or_special", false)
		animation_tree.set("parameters/conditions/is_walking", true)
		movement_speed = WALK_SPEED
	else:
		animation_tree.set("parameters/conditions/is_walking", false)
		animation_tree.set("parameters/conditions/idle_or_special", false)
		animation_tree.set("parameters/conditions/is_running", true)
		movement_speed = RUN_SPEED
	
	if follow_target != null:
		_face_follow_target()
	
	# HACK
	if follow_target != fart_target:
		player_love += follow_target.score_mult * CHASE_LOVE_DECAY_MULT

		# HACK
		if player_love > MAX_LOVE:
			player_love = MAX_LOVE
		elif player_love < -MAX_LOVE:
			player_love = -MAX_LOVE
	if state_timer <= 0:
		_change_state(AIState.RETURN_TO_CENTER)

func _face_follow_target():
	if not follow_target:
		return
	var look_at = follow_target.global_position
	look_at.y = visuals_root.global_position.y
	visuals_root.global_transform = visuals_root.global_transform.looking_at(look_at)

func _face_follow_target_torpedo():
	var look_at = follow_target.global_position
	look_at.y = visuals_root.global_position.y
	visuals_root.global_transform = visuals_root.global_transform.looking_at(look_at).rotated_local(Vector3.LEFT, PI/2.0)

func _face_south_marker():
	var look_at = south_marker.global_position
	look_at.y = visuals_root.global_position.y
	visuals_root.global_transform = visuals_root.global_transform.looking_at(look_at)

func _do_ground_pound_target(delta):
	if not ground_pound_targeting:
		_target_ground_pound()
		ground_pound_targeting = true

func _do_ground_pound(delta):
	follow_target = movable_target
	movement_speed = TORPEDO_SPEED
	_face_follow_target_torpedo()
	state_timer -= delta
	if global_position.distance_to(follow_target.global_position) < 2.0 or state_timer <= 0:
		_change_state(AIState.RETURN_TO_CENTER)

func _integrate_forces(_state):
	if follow_target:
		var other_xz = Vector2(follow_target.global_position.x, follow_target.global_position.z)
		var my_xz = Vector2(global_position.x, global_position.z)
		normalized_movement_vector = other_xz - my_xz
	
	linear_velocity = Vector3(normalized_movement_vector.x, -1, normalized_movement_vector.y) * movement_speed

	_apply_collisions()

func _apply_collisions():
	for body in collisions:
		if body != game_state.player_one and body != game_state.player_two:
			continue

		var mass_ratio = mass / body.mass
		var knockback_vector = Vector3(
			linear_velocity.x,
			5,
			linear_velocity.y
		) * mass_ratio
		body.apply_knockback(knockback_vector.limit_length(40))

func _end_scoot_animation():
	awaiting_scoot = true
	await_scoot_timer = SCOOT_WAIT_TIME

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "wiggle_right" or anim_name == "wiggle_left":
		# this prevents looping
		animation_tree.set("parameters/conditions/is_wiggling_left", false)
		animation_tree.set("parameters/conditions/is_wiggling_right", false)
		scoot_count += 1
		if scoot_count == 2:
			scoot_count = 0
			_end_scoot_animation()

func _handle_laughter():
	var is_laughing = false
	if (
		state_machine == AIState.THINK
		or state_machine == AIState.CHASE
	   ) and abs(player_love) > 30.0:
		is_laughing = true
	animation_tree.set("parameters/conditions/is_laughing", is_laughing)
	animation_tree.set("parameters/conditions/is_neutral", not is_laughing)
	laugh_particles.emitting = is_laughing

func _on_body_entered(body):
	if not collisions.has(body):
		collisions.append(body)

func _on_body_exited(body):
	if collisions.has(body):
		collisions.erase(body)

func _do_return_to_center(_delta):
	follow_target = center_marker
	movement_speed = WALK_SPEED
	animation_tree.set("parameters/conditions/is_walking", true)
	_face_south_marker()
	if global_position.distance_to(center_marker.global_position) < 7.0:
		_change_state(AIState.THINK)

func _do_pre_chase(_delta):
	_rotate_towards_follow_target(_delta)
	state_timer -= _delta
	if state_timer <= 0:
		_change_state(AIState.CHASE)

func _rotate_towards_follow_target(_delta):
	#TODO slow down
	_face_follow_target()


func _target_ground_pound():
	_update_follow_target()
	var target_indicator = target_indicator_scene.instantiate()
	get_parent().add_child(target_indicator)
	target_indicator.global_position = follow_target.global_position
	target_indicator.global_position.y += 1.0 # HACK
	movable_target.global_position = target_indicator.global_position
	
func finish_targeting():
	ground_pound_targeting = false
	_change_state(AIState.GROUND_POUND)


func _on_player_farted(player):
	if fart_target:
		if follow_target == fart_target:
			follow_target = null
		fart_target.queue_free()
		fart_target = null

	player_love += player.score_mult * 10

	# HACK
	var target_indicator = Node3D.new()
	target_indicator.global_position = player.global_position
	#target_indicator.score_mult = player.score_mult
	get_parent().add_child(target_indicator)

	# Double HACK
	fart_target = target_indicator
	follow_target = fart_target


func _on_player_knocked_back(player):
	var other_player = null
	if player == game_state.player_one:
		other_player = game_state.player_two
	else:
		other_player = game_state.player_one

	player_love += other_player.score_mult * 10


func _on_player_death(player):
	player_love = 0
