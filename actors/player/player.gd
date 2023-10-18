extends CharacterBody3D

var step_height := 0.6
var min_step_height := 0.1
var mouse_sensitivity := 0.01
var move_speed := 15.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var disable_movement := false

var is_sword_hitbox_active: bool:
	get:
		return sword_hitbox.monitoring if sword_hitbox else false
	set(v):
		sword_hitbox.monitoring = v

@onready var animation_tree: AnimationTree = %AnimationTree

@onready var camera: Camera3D = %Camera3D
@onready var sword_hitbox: Area3D = %SwordHitbox
@onready var shape_cast: ShapeCast3D = $ShapeCast
@onready var camera_spring_arm: SpringArm3D = %CameraSpringArm

@onready var stair_shape_cast_up: ShapeCast3D = $StairShapeCastUp
@onready var stair_shape_cast_forward: ShapeCast3D = $StairShapeCastForward
@onready var stair_shape_cast_down: ShapeCast3D = $StairShapeCastDown

func swing_sword():
	#animation_player.play("player_animations/sword_swing")
	pass

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("attack"):
			swing_sword()
		
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera_spring_arm.rotate_x(event.relative.y * mouse_sensitivity)
			camera_spring_arm.rotation.x = clampf(camera_spring_arm.rotation.x, -deg_to_rad(85), deg_to_rad(85))
	elif event is InputEventMouseButton:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float):
	if velocity:
		$LizardTarget.global_rotation.y = -Vector2(velocity.x, velocity.z).angle() + PI/2

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * -Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if not disable_movement and direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	animation_tree["parameters/MovementSM/IdleRun/blend_position"] = velocity.length() / move_speed
	
	move_and_slide_with_stairs(delta)

func move_and_slide_with_stairs(delta: float):
	var motion := velocity * delta
	
	if motion.is_zero_approx():
		return
	
	if _try_stair_step(motion):
		return
	
	#var start_height := global_position.y
	#var do_snap := is_on_floor()
	#if is_on_floor():
		#move_and_collide(Vector3.UP * step_height)
	move_and_slide()
	#if do_snap:
		#apply_floor_snap()
	#var gained_height := global_position.y - start_height
	#if gained_height > 0:
		#move_and_collide(Vector3.DOWN * gained_height)
	
	#motion = motion.normalized() * safe_margin
	
	#_try_stair_step(motion, true)

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
		is_sword_hitbox_active = false
