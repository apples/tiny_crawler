extends CharacterBody3D

@export var step_height := 0.6
@export var min_step_height := 0.1
@export var mouse_sensitivity := 0.01
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_speed_multiplier := 2.0
var velocity_blend_xfade := 0.1
var move_direction: Vector3

var move_speed := 5.92477 / (4.0/3.0):
	get:
		return move_speed * move_speed_multiplier

var aim_direction: Vector3:
	get:
		return (global_basis * Vector3.MODEL_FRONT * Vector3(1, 0, 1)).normalized()

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var attack_hitbox: Area3D = %AttackHitbox

@onready var stair_shape_cast_up: ShapeCast3D = $StairShapeCastUp
@onready var stair_shape_cast_forward: ShapeCast3D = $StairShapeCastForward
@onready var stair_shape_cast_down: ShapeCast3D = $StairShapeCastDown

func _process(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta
	var parent := get_parent()
	if "handle_direction" in parent:
		parent.handle_direction(delta)
	#print("vel ", velocity)
	if velocity:
		global_rotation.y = -Vector2(velocity.x, velocity.z).angle() + PI/2
	
	var current_velocity_blend: float = animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"]
	var target_velocity_blend := velocity.length() / move_speed
	var velocity_blend := move_toward(current_velocity_blend, target_velocity_blend, delta / velocity_blend_xfade) 
	animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"] = velocity_blend
	#print("blend ", animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"])
	
	animation_tree["parameters/Movement/IdleRun/RunTimeScale/scale"] = move_speed_multiplier
	
	move_and_slide_with_stairs(delta)

func default_handle_direction(_delta: float):
	if not is_on_floor():
		return
	if move_direction:
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
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
		#var travel := motion * stair_shape_cast_forward.get_closest_collision_safe_fraction()
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
