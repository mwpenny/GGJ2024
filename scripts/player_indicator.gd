extends Node3D

const VERY_SMALL_VERTICAL_BUMP = 0.05 #prevent z-fighting
var ray = null

func _ready():
	ray = get_node("Ray")

func _physics_process(_delta):
	if ray.is_colliding():
		global_position.y = ray.get_collision_point().y
	else:
		global_position.y = get_parent().global_position.y

	global_position.y += VERY_SMALL_VERTICAL_BUMP
	basis = get_parent().global_transform.basis.inverse()
