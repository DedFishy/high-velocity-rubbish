extends Node3D

var camera: Camera3D
var camera_pivot: Node3D
var ship_model: Node3D;
var last_camera_radius = 0;

const rotation_speed = 5;

const invert_camera_controls = true;
const rotation_speed_sign = -1 if invert_camera_controls else 1

const spawning_stuff_clock_max = 10
var spawning_stuff_clock = 2

var target_camera_radius = 4
var min_camera_radius = 4

var ingame = true;

func _ready():
	camera = $CameraPivot/Camera3D
	camera_pivot = $CameraPivot
	ship_model = $ShipModel
	
	self.linear_velocity.z = 10

func _process(delta: float) -> void:
	if ingame: 
		update_spawning_clock(delta)
		if not $AudioStreamPlayer.playing:
			$AudioStreamPlayer.play()
	
func _physics_process(delta: float) -> void:
	update_camera(delta)
	update_cluster(delta)

func update_camera(delta: float):
		if $CameraPivot/Camera3D/Area3D.get_overlapping_bodies().size() > 0:
			target_camera_radius += 0.1
		else:
			if target_camera_radius > min_camera_radius:
				target_camera_radius -= 0.1
		var new_camera_radius = get_camera_radius()
		if last_camera_radius != new_camera_radius:
			last_camera_radius = new_camera_radius
			camera.position = Vector3(0, 0, -new_camera_radius)
		
		
func update_cluster(delta: float):
	var applied_rotation_speed = rotation_speed_sign * rotation_speed * delta;

	if Input.is_action_pressed("RotateCameraRight"):
		rotate_and_counteract(Vector3.UP, -applied_rotation_speed)
	if Input.is_action_pressed("RotateCameraLeft"):
		rotate_and_counteract(Vector3.UP, applied_rotation_speed)
		
	if Input.is_action_pressed("RotateCameraUp"):
		rotate_and_counteract(Vector3.LEFT, applied_rotation_speed)
	if Input.is_action_pressed("RotateCameraDown"):
		rotate_and_counteract(Vector3.LEFT, -applied_rotation_speed)
		
	if Input.is_action_just_pressed("Debug"):
		#get_parent().spawn_stuff()
		pass
		
	if Input.is_action_just_pressed("Fire"):
		get_parent().fire_prop()
	
func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int):
	if not ingame: return;
	if body.get_meta("IsDaBomb", false):
		get_parent().flashbang()
		ingame = false;
		$AudioStreamPlayer.stop()
	else:
		get_parent_node_3d().assimilate_prop(body)
		
func rotate_and_counteract(direction: Vector3, amount: float):
	var original_global_rotation = ship_model.global_rotation # Save original rotation relative to the world
	rotate_object_local(direction, amount) # Rotate the entire ship object
	ship_model.global_rotation = original_global_rotation # Return the ship model to its original rotation
		
func get_camera_radius():
	return target_camera_radius

func update_spawning_clock(delta: float):
	spawning_stuff_clock -= delta
	if spawning_stuff_clock <= 0:
		get_parent().spawn_stuff()
		spawning_stuff_clock = spawning_stuff_clock_max
