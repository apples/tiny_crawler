extends CharacterBody3D

var step_height := 0.6
var min_step_height := 0.1
var mouse_sensitivity := 0.01
var move_speed_multiplier := 2.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity_blend_xfade := 0.1

var move_speed := 5.92477 / (4.0/3.0):
	get:
		return move_speed * move_speed_multiplier

var aim_direction: Vector3:
	get:
		var horizontal_vel := velocity * Vector3(1, 0, 1)
		return horizontal_vel.normalized() if not horizontal_vel.is_zero_approx() else global_basis * Vector3.MODEL_FRONT

@onready var animation_tree: AnimationTree = %AnimationTree

@onready var camera: Camera3D = %Camera3D
@onready var attack_hitbox: Area3D = %AttackHitbox
@onready var camera_spring_arm: SpringArm3D = %CameraSpringArm

@onready var stair_shape_cast_up: ShapeCast3D = $StairShapeCastUp
@onready var stair_shape_cast_forward: ShapeCast3D = $StairShapeCastForward
@onready var stair_shape_cast_down: ShapeCast3D = $StairShapeCastDown
@onready var state_machine: StateMachine = %StateMachine

func _input(event: InputEvent):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			camera_spring_arm.rotate_y(-event.relative.x * mouse_sensitivity)
			camera_spring_arm.rotation.x = clampf(camera_spring_arm.rotation.x - event.relative.y * mouse_sensitivity, -deg_to_rad(60), deg_to_rad(60))
	

func _process(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta
	if "handle_direction" in state_machine.current_state:
		state_machine.current_state.handle_direction(delta)
	if velocity:
		global_rotation.y = -Vector2(velocity.x, velocity.z).angle() + PI/2
	
	var current_velocity_blend: float = animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"]
	var target_velocity_blend := velocity.length() / move_speed
	var velocity_blend := move_toward(current_velocity_blend, target_velocity_blend, delta / velocity_blend_xfade) 
	animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"] = velocity_blend
	print(animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"])
	
	animation_tree["parameters/Movement/IdleRun/RunTimeScale/scale"] = move_speed_multiplier
	
	move_and_slide_with_stairs(delta)

func default_handle_direction(delta: float):
	if not is_on_floor():
		return
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (camera_spring_arm.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

func move_and_slide_with_stairs(delta: float):
	var motion := velocity * delta
	
	if motion.is_zero_approx():
		return
	
	if _try_stair_step(motion):
		return
	
	move_and_slide()

func _try_stair_step(motion: Vector3, allow_ramps := false):
	if not is_on_floor():
		return false
	
	if motion.is_zero_approx():
		return false
	
	stair_shape_cast_up.position = Vector3(0, 1, 0)
	stair_shape_cast_up.target_position = Vector3.UP * step_height
	
	stair_shape_cast_up.force_shapecast_update()
	
	for i in range(stair_shape_cast_up.get_collision_count()):
		if stair_shape_cast_up.get_collision_normal(i).dot(Vector3.UP) < -0.001:
			print("ceiling = ",
				stair_shape_cast_up.get_collider(i), " ",
				stair_shape_cast_up.get_collision_normal(i), " ",
				stair_shape_cast_up.get_collision_normal(i).dot(Vector3.UP))
			return false
	
	stair_shape_cast_forward.position = stair_shape_cast_up.position + stair_shape_cast_up.target_position
	stair_shape_cast_forward.target_position = basis.inverse() * motion
	stair_shape_cast_forward.force_shapecast_update()
	
	if stair_shape_cast_forward.get_collision_count() > 0:
		# we might be sliding along a wall
		var travel := motion * stair_shape_cast_forward.get_closest_collision_safe_fraction()
		#motion = Plane(stair_shape_cast_forward.get_collision_normal(0)).project(motion)
		motion = motion.slide(stair_shape_cast_forward.get_collision_normal(0))
		
		stair_shape_cast_forward.target_position = basis.inverse() * motion
		stair_shape_cast_forward.force_shapecast_update()
	
	if stair_shape_cast_forward.get_collision_count() != 0:
		return false
	
	stair_shape_cast_down.position = stair_shape_cast_forward.position + stair_shape_cast_forward.target_position
	stair_shape_cast_down.target_position = Vector3.DOWN * step_height * 0.95
	
	stair_shape_cast_down.force_shapecast_update()
	
	if stair_shape_cast_down.get_collision_count() == 0:
		# didn't land on anything
		return false
	
	if not allow_ramps and stair_shape_cast_down.get_collision_normal(0).dot(Vector3.UP) < 0.95:
		# landed on slope
		return false
	
	var dist := stair_shape_cast_down.position + (stair_shape_cast_down.get_collision_point(0) - stair_shape_cast_down.global_position).project(stair_shape_cast_down.target_position.normalized())
	
	if dist.y < min_step_height:
		# too small to be a step
		return false
	
	position += basis * dist
	print("stairs DETECTED ", stair_shape_cast_down.get_collision_point(0),
		" ", dist)
	return true

func _on_sword_hitbox_body_entered(body: Node3D) -> void:
	if "apply_damage" in body:
		body.apply_damage(1)
		attack_hitbox.monitoring = false

func notify_action_finished():
	if "notify_action_finished" in state_machine.current_state:
		state_machine.current_state.notify_action_finished()
