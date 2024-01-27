extends CharacterBody3D

var game_state = null
var input_prefix = ""

const ACCELERATION = 175
const FRICTION = 60
const MAX_VELOCITY = 25

const GRAVITY = 70
const JUMP_IMPULSE = 20

func _ready():
	game_state = get_node("/root/GameState")

func _process(_delta):
	if not game_state.gameplay_enabled:
		return

func _physics_process(delta):
	#if not game_state.gameplay_enabled:
	#	return

	var move_direction = _get_move_direction()
	_face_direction_xz(move_direction)

	velocity = _get_velocity_vector(move_direction, delta)
	move_and_slide()

func init(player_num):
	input_prefix = "p%d_" % player_num

func _get_input_name(name):
	return input_prefix + name

func _get_move_direction():
	var x_axis = Input.get_axis(_get_input_name("move_left"), _get_input_name("move_right"))
	var z_axis = Input.get_axis(_get_input_name("move_up"), _get_input_name("move_down"))
	var jump = 1 if Input.is_action_just_pressed(_get_input_name("jump")) else 0

	return Vector3(x_axis, jump, z_axis).normalized()

func _face_direction_xz(direction):
	var direction_xz = Vector3(direction.x, 0, direction.z)
	if direction_xz != Vector3.ZERO:
		direction_xz.y = 0
		self.basis = Basis.looking_at(direction_xz, Vector3.UP, true)

func _get_velocity_vector(direction, delta):
	var acceleration = direction * ACCELERATION * delta
	var friction = FRICTION * delta
	var velocity_vector = Vector3(
		move_toward(velocity.x + acceleration.x, 0, friction),
		move_toward(velocity.y, -MAX_VELOCITY, GRAVITY * delta),
		move_toward(velocity.z + acceleration.z, 0, friction)
	)

	# TODO: analog jump
	if direction.y > 0 and is_on_floor():
		velocity_vector.y = JUMP_IMPULSE

	return velocity_vector.limit_length(MAX_VELOCITY)
