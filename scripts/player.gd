@tool #just to allow visualizing the material overrides.

extends CharacterBody3D

const PlayerIndicator = preload("res://scripts/player_indicator.gd")

@export var clothing_material : Material
@export var hat_material : Material
@export var indicator_material : Material
@export var clothing_meshes : Array[MeshInstance3D]
@export var hat_meshes : Array[MeshInstance3D]
@export var indicator : MeshInstance3D
@export var fart_particles : GPUParticles3D

signal death(player)
signal farted(player)
signal knocked_back(player)

var game_state = null
var input_prefix = ""
var mass = 25.0

const ACCELERATION = 175
const FRICTION = 60
const MAX_VELOCITY = 25
const KILL_PLANE_HEIGHT = -30
const FART_RADIUS = 10

const INVINCIBILITY_TIME = 2
const FART_TIME = 2

const GRAVITY = 70
const JUMP_IMPULSE = 20
const FART_JUMP_IMPULSE = JUMP_IMPULSE * 2

# 1.0 for player one, -1.0 for player two
var score_mult = 0

var invincibility_timer = 0
var fart_timer = 0

func _ready():
	if not Engine.is_editor_hint():
		game_state = get_node("/root/GameState")
	# Override material colors
	if clothing_material and clothing_meshes:
		for mesh in clothing_meshes:
			mesh.material_override = clothing_material
	if hat_material and hat_meshes:
		for mesh in hat_meshes:
			mesh.material_override = hat_material
	if indicator_material and indicator:
		indicator.material_override = indicator_material

func _process(_delta):
	if not game_state or not game_state.gameplay_enabled:
		return

func _physics_process(delta):
	if not game_state or not game_state.gameplay_enabled:
		return

	if is_dead():
		kill()
		return

	_tick_timers(delta)
	_update_visibility()

	var move_direction = _get_move_direction()
	_face_direction_xz(move_direction)

	_process_actions()

	velocity = _get_velocity_vector(move_direction, delta)
	move_and_slide()

func init(player_num):
	score_mult = -2.0 * (player_num - 1.5) #trust me: it works
	# print("Player %d has %f multiplier." % [player_num, score_mult])
	input_prefix = "p%d_" % player_num

func is_moving():
	return velocity.length() > 0

func is_running():
	return velocity.length() > (MAX_VELOCITY / 2)

func is_dead():
	return global_position.y < KILL_PLANE_HEIGHT

func apply_knockback(knockback_velocity):
	if not _is_knockback_disabled():
		velocity += knockback_velocity
		_start_knockback_cooldown()
		knocked_back.emit(self)

func kill():
	velocity = Vector3.ZERO
	_start_knockback_cooldown()

	death.emit(self)

func _is_knockback_disabled():
	return invincibility_timer > 0

func _start_knockback_cooldown():
	invincibility_timer = INVINCIBILITY_TIME

func _tick_timers(delta):
	if invincibility_timer > 0:
		invincibility_timer = move_toward(invincibility_timer, 0, delta)
	if fart_timer > 0:
		fart_timer = move_toward(fart_timer, 0, delta)

func _update_visibility():
	visible = (int(invincibility_timer * 1000) % 2) == 0

func _get_input_name(name):
	return input_prefix + name

func _get_move_direction():
	# TODO: maybe something clever needs to happen with detecting devices and
	# using mouse and keyboard for one of the players

	var left = Input.get_action_strength(_get_input_name("move_left"))
	var right = Input.get_action_strength(_get_input_name("move_right"))
	var up = Input.get_action_strength(_get_input_name("move_up"))
	var down = Input.get_action_strength(_get_input_name("move_down"))

	var x_axis = right - left
	var z_axis = down - up
	var jump = 1 if Input.is_action_just_pressed(_get_input_name("jump")) else 0

	return Vector3(x_axis, jump, z_axis).normalized()

func _process_actions():
	if fart_timer <= 0 and Input.is_action_just_pressed(_get_input_name("fart")) and not _is_knockback_disabled():
		_do_fart()

func _do_fart():
	if not is_on_floor():
		velocity.y += FART_JUMP_IMPULSE
	
	fart_timer = FART_TIME
	fart_particles.emitting = true
	farted.emit(self)

	var other_player = null
	if self == game_state.player_one:
		other_player = game_state.player_two
	else:
		other_player = game_state.player_one

	var distance = abs(global_position.distance_to(other_player.global_position))
	if distance < FART_RADIUS:
		var direction = other_player.global_position.normalized()
		other_player.apply_knockback(Vector3(direction.x * 35, 35, direction.z * 35))

func _face_direction_xz(direction):
	var direction_xz = Vector3(direction.x, 0, direction.z)
	if direction_xz:
		direction_xz.y = 0
		self.basis = Basis.looking_at(direction_xz, Vector3.UP, true)

func _get_velocity_vector(direction, delta):
	var acceleration = direction * ACCELERATION * delta
	var friction = FRICTION * delta

	var velocity_vector = Vector3(velocity)

	if velocity_vector.length() < MAX_VELOCITY:
		velocity_vector.x += acceleration.x
		velocity_vector.z += acceleration.z

	velocity_vector.x = move_toward(velocity_vector.x, 0, friction)
	velocity_vector.y = move_toward(velocity_vector.y, -MAX_VELOCITY, GRAVITY * delta)
	velocity_vector.z = move_toward(velocity_vector.z, 0, friction)

	# TODO: analog jump
	if direction.y > 0 and is_on_floor():
		velocity_vector.y += JUMP_IMPULSE

	return velocity_vector
