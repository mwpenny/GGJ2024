extends RigidBody3D

@export var visuals_root : Node3D = null
@export var animation_tree : AnimationTree = null
@export var laugh_particles : GPUParticles3D

var game_state = null

enum AIState {
	THINK,
	CHASE,
	GROUND_POUND,
}

const CHASE_LOVE_DECAY_MULT = 0.01 
const SCOOT_SPEED = 0.6
const WALK_SPEED = 1.0
const RUN_SPEED = 3.5
const THINK_TIME = 2.0
const SCOOT_WAIT_TIME = 1.0

var last_scoot_was_left: bool = false
var awaiting_scoot: bool = true
var state_machine = AIState.THINK
var state_timer: float = THINK_TIME
var movement_speed = 0
var player_love = -40.0
var follow_target = null
var normalized_movement_vector = Vector2(0,1)
var await_scoot_timer = SCOOT_WAIT_TIME
var scoot_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	game_state = get_node("/root/GameState")
	game_state.register_lord_character(self)

func _process(delta):
	if not game_state.gameplay_enabled:
		return
	
	if state_machine == AIState.THINK:
		_do_think(delta)
	elif state_machine == AIState.CHASE:
		_do_chase(delta)
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
	elif state_machine == AIState.CHASE:
		awaiting_scoot = true
		state_timer = 10.0
		_update_follow_target()
	elif state_machine == AIState.GROUND_POUND:
		state_timer = 10.0

func _do_think(delta):
	animation_tree.set("parameters/conditions/idle_or_special", true)
	state_timer -= delta
	if state_timer <= 0:
		var next_states = [
			AIState.CHASE,
			# AIState.GROUND_POUND,
		]
		_change_state(
			next_states[randi() % len(next_states)]
		)

func _update_follow_target():
	if player_love == 0:
		follow_target = null
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
	
	player_love += follow_target.score_mult * CHASE_LOVE_DECAY_MULT
	if state_timer <= 0:
		_change_state(AIState.THINK)

func _face_follow_target():
	var look_at = follow_target.global_position
	look_at.y = visuals_root.global_position.y
	visuals_root.global_transform = visuals_root.global_transform.looking_at(look_at)

func _do_ground_pound(delta):
	_change_state(AIState.THINK)

func _integrate_forces(_state):
	if follow_target:
		var other_xz = Vector2(follow_target.global_position.x, follow_target.global_position.z)
		var my_xz = Vector2(global_position.x, global_position.z)
		normalized_movement_vector = other_xz - my_xz
	
	linear_velocity = Vector3(normalized_movement_vector.x, 0, normalized_movement_vector.y) * movement_speed

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
	if body == game_state.player_one or body == game_state.player_two:
		var mass_ratio = mass / body.mass
		var knockback_vector = Vector3(
			linear_velocity.x,
			5,
			linear_velocity.y
		)

		body.velocity += knockback_vector * mass_ratio
