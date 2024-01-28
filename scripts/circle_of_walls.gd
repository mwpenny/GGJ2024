@tool

extends Node

@export var mat : Material :
	set(val):
		mat = val
		_reset()

@export var segments: int = 16 :
	set(val):
		segments = val
		_reset()
		
@export var radius: float = 1.0 :
	set(val):
		radius = val
		_reset()
		
@export var height: float = 1.0 :
	set(val):
		height = val
		_reset()
		
@export var begin_angle: float = 0.0 :
	set(val):
		begin_angle = val
		_reset()
		
@export var  end_angle: float = PI * 2.0 :
	set(val):
		end_angle = val
		_reset()
		
@export var thickness: float = 0.5 :
	set(val):
		thickness = val
		_reset()

# Called when the node enters the scene tree for the first time.
func _ready():
	_reset()

func _reset():
	for child in get_children():
		child.queue_free()
		
	#Each segment has 2 triangles
	var num_vertices_in_packed_array = segments * 6;
	var add_height = Vector3(Vector3.UP * height);

	var arc_angle = end_angle - begin_angle;
	var angle_per_segment = arc_angle / segments;

	var idx = 0;
	for i in range(segments):
		var va = []; # vertex array
		var angle = begin_angle + angle_per_segment * i
		var next_angle = angle + angle_per_segment;
		
		var p1b = Vector3(cos(angle), 0.0, sin(angle)) * radius
		var p1t = p1b + add_height
		var p2b = Vector3(cos(next_angle), 0.0, sin(next_angle)) * radius
		var p2t = p2b + add_height
		
		va.append(p1b)
		va.append(p1t)
		va.append(p2b)
		va.append(p1t)
		va.append(p2t)
		va.append(p2b)
		
		var pva = PackedVector3Array(va)
		
		var cps = ConcavePolygonShape3D.new()
		cps.set_faces(pva)
		
		var array_mesh = ArrayMesh.new()
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = pva
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		array_mesh.surface_set_material(0, mat)
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = array_mesh
		add_child(mesh_instance)
		
		var cs = CollisionShape3D.new()
		cs.set_shape(cps)

		var wall = StaticBody3D.new()
		wall.set_collision_layer_value(1, false)  # Static
		wall.set_collision_layer_value(2, false)  # Dynamic
		wall.set_collision_layer_value(3, true)   # Non-player
		wall.add_child(cs)
		add_child(wall)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
