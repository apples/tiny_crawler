extends CharacterBody3D

var step_height := 1.0
var mouse_sensitivity := 0.01
var move_speed := 15.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

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
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * -Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	animation_tree["parameters/BlendSpaceIdleRun/blend_position"] = velocity.length() / move_speed
	
	if not _try_stair_step(delta):
		move_and_slide()
	
	$Lizard/Armature/Skeleton3D/Lizard.scale.y = -1.0 if not is_on_floor() else 1.0

func _try_stair_step(delta: float):
	if not is_on_floor():
		return false
	
	stair_shape_cast_up.position = Vector3(0, 1, 0)
	stair_shape_cast_up.target_position = Vector3.UP * step_height
	stair_shape_cast_forward.position = stair_shape_cast_up.position + stair_shape_cast_up.target_position
	stair_shape_cast_forward.target_position = basis.inverse() * velocity * delta
	stair_shape_cast_down.position = stair_shape_cast_forward.position + stair_shape_cast_forward.target_position
	stair_shape_cast_down.target_position = Vector3.DOWN * step_height * 0.95
	
	stair_shape_cast_up.force_shapecast_update()
	stair_shape_cast_forward.force_shapecast_update()
	stair_shape_cast_down.force_shapecast_update()
	
	var ceiling_hit := false
	for i in range(stair_shape_cast_up.get_collision_count()):
		if stair_shape_cast_up.get_collision_normal(i).dot(Vector3.UP) < -0.001:
			ceiling_hit = true
			print("ceiling = ",
				stair_shape_cast_up.get_collider(i), " ",
				stair_shape_cast_up.get_collision_normal(i), " ",
				stair_shape_cast_up.get_collision_normal(i).dot(Vector3.UP))
			break
	
	var mas := true
	
	if (not ceiling_hit) and \
		stair_shape_cast_forward.get_collision_count() == 0 and \
		stair_shape_cast_down.get_collision_count() == 1 and \
		stair_shape_cast_down.get_collision_normal(0).dot(Vector3.UP) >= 0.95:
			var dist := stair_shape_cast_down.position + (stair_shape_cast_down.get_collision_point(0) - stair_shape_cast_down.global_position).project(stair_shape_cast_down.target_position.normalized())
			
			position += basis * dist
			print("stairs DETECTED ", stair_shape_cast_down.get_collision_point(0),
				" ", dist)
			return true
	
	return false

func _on_sword_hitbox_body_entered(body: Node3D) -> void:
	if "apply_damage" in body:
		body.apply_damage(1)
		is_sword_hitbox_active = false
