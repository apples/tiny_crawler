class_name CharacterBase
extends CharacterBody3D

signal process_done()

const FLOOR_ANGLE_THRESHOLD := 0.01
const CMP_EPSILON := 0.00001

@export var mouse_sensitivity := 0.01
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var base_move_speed_multiplier := 1.0
@export var acceleration: float = 100.0

@export_group("Stairs", "stairs")
@export var stairs_step_height := 0.6
@export var stairs_min_step_height := 0.1
@export var stairs_min_forward_step := 0.05
@export var stairs_prefix: bool = true
@export var stairs_postfix: bool = true
@export var stairs_always_snap: bool = true

var move_speed_multiplier := 1.0
var velocity_blend_xfade := 0.1
var move_direction: Vector3
var speed_limit: float = 17.0

var move_speed := 5.92477 / (4.0/3.0):
	get:
		return move_speed * move_speed_multiplier

var aim_direction: Vector3:
	get:
		return (global_basis * Vector3.MODEL_FRONT * Vector3(1, 0, 1)).normalized()

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var attack_hitbox: Area3D = %AttackHitbox

@onready var main_collision_shape: CollisionShape3D = $MainCollisionShape
@onready var stair_shape_cast_up: ShapeCast3D = $StairShapeCastUp
@onready var stair_shape_cast_forward: ShapeCast3D = $StairShapeCastForward
@onready var stair_shape_cast_down: ShapeCast3D = $StairShapeCastDown
@onready var leg_prototype: CollisionShape3D = $LegPrototype

func _ready():
	move_speed_multiplier = base_move_speed_multiplier
	
	# sunflower spiral
	var hitbox := main_collision_shape.shape as CapsuleShape3D
	var ray := leg_prototype.shape as SeparationRayShape3D
	var PHI := PI * (1 + sqrt(5))
	var num_legs := 15
	for i in range(num_legs):
		var indice := float(i) + 0.5
		var r: float = clamp(sqrt(indice / float(num_legs)), 0.0, sqrt(2.0)/2.0) * hitbox.radius
		print(r, " ", sqrt(indice / float(num_legs)))
		var t := PHI * indice
		var pos := Vector3(r * cos(t), ray.length, r * sin(t))
		var leg := CollisionShape3D.new()
		leg.name = "Leg_%s" % i
		leg.position = pos
		leg.rotation = leg_prototype.rotation
		leg.shape = ray
		add_child(leg)

func _physics_process(delta: float):
	velocity.y -= gravity * delta
	var parent := get_parent()
	if "update_velocity" in parent:
		parent.update_velocity(delta, default_update_velocity)
	
	# speed limit
	var new_ground_vel = (Vector3(1, 0, 1) * velocity).limit_length(speed_limit)
	velocity.x = new_ground_vel.x
	velocity.z = new_ground_vel.z
	
	if velocity.x or velocity.z:
		global_rotation.y = -Vector2(velocity.x, velocity.z).angle() + PI/2
	
	var current_velocity_blend: float = animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"]
	var target_velocity_blend := velocity.length() / move_speed
	var velocity_blend := move_toward(current_velocity_blend, target_velocity_blend, delta / velocity_blend_xfade) 
	animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"] = velocity_blend
	#print("blend ", animation_tree["parameters/Movement/IdleRun/Blend/blend_amount"])
	
	animation_tree["parameters/Movement/IdleRun/RunTimeScale/scale"] = move_speed_multiplier
	
	move_and_slide()
	
	#if stairs_always_snap:
		#apply_floor_snap()
		#
		#if not is_on_floor():
			#print("snap failed")
			#var cc := move_and_collide(Vector3(0, -5, 0), true)
			#if cc:
				#print("    altitude: ", cc.get_travel().y)
				#print("    normal:   ", cc.get_normal())
			#else:
				#print("    no ground")
	
	process_done.emit()

func default_update_velocity(delta: float):
	if not is_on_floor():
		return
	var ground_vel := Vector2(velocity.x, velocity.z)
	var ground_move_dir := Vector2(move_direction.x, move_direction.z)
	if move_direction:
		ground_vel = ground_vel.move_toward(ground_move_dir * move_speed, acceleration * delta)
	else:
		ground_vel = ground_vel.move_toward(Vector2.ZERO, acceleration * delta)
	velocity.x = ground_vel.x
	velocity.z = ground_vel.y

func move_and_slide_with_stairs(delta: float):
	var motion := velocity * delta
	
	if motion.is_zero_approx():
		move_and_slide()
		return
	
	if stairs_prefix:
		if _try_stair_step(motion):
			return
	
	move_and_slide()
	
	if not stairs_postfix:
		return
	
	for i in range(get_slide_collision_count()):
		if not abs(get_slide_collision(i).get_normal().dot(Vector3.UP)) < 0.001:
			continue
		motion = get_slide_collision(i).get_remainder()
		if motion.x or motion.z:
			_try_stair_step(motion, true)
			break
	

func _try_stair_step(motion: Vector3, allow_ramps := false):
	if not is_on_floor():
		return false
	
	if motion.is_zero_approx():
		return false
	
	stair_shape_cast_up.position = Vector3(0, 1, 0)
	stair_shape_cast_up.target_position = Vector3.UP * (stairs_step_height + safe_margin)
	
	stair_shape_cast_up.force_shapecast_update()
	
	for i in range(stair_shape_cast_up.get_collision_count()):
		if stair_shape_cast_up.get_collision_normal(i).dot(Vector3.UP) < -0.001:
			print("ceiling = ",
				stair_shape_cast_up.get_collider(i), " ",
				stair_shape_cast_up.get_collision_normal(i), " ",
				stair_shape_cast_up.get_collision_normal(i).dot(Vector3.UP))
			return false
	
	var forward_step_motion := motion * Vector3(1, 0, 1)
	if forward_step_motion.length() < stairs_min_forward_step:
		forward_step_motion = forward_step_motion.normalized() * stairs_min_forward_step
	
	stair_shape_cast_forward.position = stair_shape_cast_up.position + stair_shape_cast_up.target_position
	stair_shape_cast_forward.target_position = basis.inverse() * forward_step_motion
	stair_shape_cast_forward.force_shapecast_update()
	
	var oldmot = motion
	if stair_shape_cast_forward.get_collision_count() > 0:
		# we might be sliding along a wall
		#var travel := motion * stair_shape_cast_forward.get_closest_collision_safe_fraction()
		#motion = Plane(stair_shape_cast_forward.get_collision_normal(0)).project(motion)
		forward_step_motion = forward_step_motion.slide(stair_shape_cast_forward.get_collision_normal(0))
		
		if forward_step_motion.length() < stairs_min_forward_step:
			forward_step_motion = forward_step_motion.normalized() * stairs_min_forward_step
		
		stair_shape_cast_forward.target_position = basis.inverse() * (motion * Vector3(1, 0, 1))
		stair_shape_cast_forward.force_shapecast_update()
	
	if stair_shape_cast_forward.get_collision_count() != 0:
		return false
	
	stair_shape_cast_down.position = stair_shape_cast_forward.position + stair_shape_cast_forward.target_position
	stair_shape_cast_down.target_position = Vector3.DOWN * (stairs_step_height + safe_margin)
	
	stair_shape_cast_down.force_shapecast_update()
	
	if stair_shape_cast_down.get_collision_count() == 0:
		# didn't land on anything
		return false
	
	if not allow_ramps and stair_shape_cast_down.get_collision_normal(0).dot(Vector3.UP) < 0.95:
		# landed on slope
		return false
	
	var hit_pos := stair_shape_cast_down.to_local(stair_shape_cast_down.get_collision_point(0))
	var pos := stair_shape_cast_down.position + hit_pos.project(stair_shape_cast_down.target_position.normalized())
	var dist := pos + Vector3.UP * safe_margin
	
	if dist.y < stairs_min_step_height:
		# too small to be a step
		return false
	
	#print("--==--")
	#print("mot ", motion, " originally ", oldmot)
	#print("fwd ", forward_step_motion)
	#print("sta ", stair_shape_cast_up.position)
	#print(" -> ", stair_shape_cast_forward.position)
	#print(" -> ", stair_shape_cast_down.position)
	#print(" -> ", pos, " <", frac, ">")
	#print("hit ", stair_shape_cast_down.get_collision_point(0))
	#print("old ", position)
	#print("  + ", basis * dist, " : ", dist)
	position += basis * dist
	#print("new ", position)
	#print(".")
	velocity.y = 0.0
	#print("stairs DETECTED ", stair_shape_cast_down.get_collision_point(0), " ", dist)
	return true

func _on_attack_hitbox_body_entered(body: Node3D) -> void:
	if "apply_damage" in body:
		body.apply_damage(1)
		attack_hitbox.monitoring = false

func apply_damage(amount: float):
	print("Ouchie! ", get_parent().name)
