extends Node3D

var ray = null

func _ready():
	ray = get_node("Ray")

func _process(delta):
	var collision = ray.get_collision_point()
	if collision:
		global_position.y = collision.y
	else:
		global_position.y = get_parent().global_position.y

	basis = get_parent().global_transform.basis.inverse()
