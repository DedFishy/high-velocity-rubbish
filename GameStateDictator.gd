extends Node3D

var random_props: Node3D

var freefloating_props: Array[Node3D]
var caught_props: Array[Node3D]

var nuclear_bombs: Array[Node3D]

const the_amount_of_stuff_spawned_each_time_stuff_is_spawned = 5

const new_stuff_min_distance = 10
const new_stuff_max_distance = 25

const bomb_min_difference = 25
const bomb_max_difference = 40

const prop_gravitron_multiplier = 2

const prop_initial_linear_velocity_range = 10
const prop_initial_rotational_velocity_range = 10

func _ready() -> void:
	random_props = $RandomProps
	freefloating_props = []
	caught_props = []
	nuclear_bombs = []
	#random_props.set_process(false)
	random_props.hide()

func _physics_process(delta: float) -> void:
	if !$Ship.ingame: return
	for prop in freefloating_props:
		var vector_towards_ship = $Ship/ShipModel.global_position - prop.position
		prop.linear_velocity += vector_towards_ship.normalized() * (vector_towards_ship.length()) * delta * prop_gravitron_multiplier

func spawn_stuff():
	for _i in range(0, the_amount_of_stuff_spawned_each_time_stuff_is_spawned):
		spawn_new_prop(
			$Ship.position,
			new_stuff_min_distance, new_stuff_max_distance
		)
	spawn_new_prop($Ship.position, bomb_min_difference, bomb_max_difference, $OtherProps/DaBomb)

func get_random_signums() -> Vector3:
	return Vector3(
		-1 if randi_range(0,1) == 0 else 1,
		-1 if randi_range(0,1) == 0 else 1,
		-1 if randi_range(0,1) == 0 else 1
	)

func get_random_prop_position_offset(minimum_offset: float, maximum_offset: float) -> Vector3:
	var x = randf()
	var y = randf()
	var z = randf()
	
	if x+y+z == 0: return get_random_prop_position_offset(minimum_offset, maximum_offset) # Try again the lazy way
	
	# Multiply all by magic funny thing and    the desired distance
	var multiplier = (1 / sqrt(x*x+y*y+z*z)) * randf_range(minimum_offset,maximum_offset)
	x *= multiplier
	y *= multiplier
	z *= multiplier
	
	return Vector3(x, y, z)

func spawn_new_prop(anchor_position: Vector3, minimum_offset: float, maximum_offset: float, prop: Node3D = null):
	var random_position_offset = get_random_prop_position_offset(minimum_offset, maximum_offset) * get_random_signums()
	var prop_position = anchor_position + random_position_offset
	var new_prop = (get_random_prop() if prop == null else prop).duplicate(DuplicateFlags.DUPLICATE_GROUPS)
	new_prop.show()
	add_child(new_prop)
	freefloating_props.append(new_prop)
	new_prop.position = Vector3.ZERO;
	new_prop.rotation_degrees = Vector3(randi_range(0, 360),randi_range(0, 360),randi_range(0, 360))
	new_prop.linear_velocity = Vector3(
		randi_range(-prop_initial_linear_velocity_range, prop_initial_linear_velocity_range),
		randi_range(-prop_initial_linear_velocity_range, prop_initial_linear_velocity_range),
		randi_range(-prop_initial_linear_velocity_range, prop_initial_linear_velocity_range))
	new_prop.angular_velocity = Vector3(
		randi_range(-prop_initial_rotational_velocity_range, prop_initial_rotational_velocity_range),
		randi_range(-prop_initial_rotational_velocity_range, prop_initial_rotational_velocity_range),
		randi_range(-prop_initial_rotational_velocity_range, prop_initial_rotational_velocity_range))
	new_prop.global_position = prop_position

func get_random_prop() -> Node3D:
	var children = random_props.get_children()
	return children[randi_range(0, children.size()-1)]
	
func assimilate_prop(prop: RigidBody3D):
	caught_props.append(prop)
	freefloating_props.remove_at(freefloating_props.find(prop))

	prop.hide()
	prop.set_process(false)
	sync_rubbish_indicator()
	

func fire_prop():
	if caught_props.size() == 0: return
	var prop = caught_props[0]
	caught_props.remove_at(0)
	freefloating_props.append(prop)
	var prop_direction = $Ship.global_transform.basis.z
	prop.show()
	prop.set_process(true)
	prop.position = $Ship.global_position + prop_direction*4
	print(prop_direction)
	prop.linear_velocity = prop_direction * 100
	
	$Ship.apply_impulse(-prop_direction)
	sync_rubbish_indicator()
	
func sync_rubbish_indicator():
	var count = caught_props.size()
	var optional_s = "" if count == 1 else "s"
	$CanvasLayer/CollectedRubbishIndicator.text = "COLLECTED RUBBISH: " + str(count)
	$CanvasLayer/ColorRect/RestartMenu/Label2.text = "You collected " + str(count) + " piece" + optional_s + " of rubbish"

func flashbang():
	$CanvasLayer/ColorRect.show()
	$CanvasLayer/ColorRect/AudioStreamPlayer.play()
	
	for prop_list in [caught_props, freefloating_props, nuclear_bombs]:
		for prop: Node3D in prop_list:
			prop.queue_free()
		prop_list.clear()

func restart():
	$Ship.set_process(true)
	$Ship.ingame = true
	$Ship.position = Vector3.ZERO
	$Ship.rotation = Vector3.ZERO
	$CanvasLayer/ColorRect.hide()
	sync_rubbish_indicator()
