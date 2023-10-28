class_name CharacterBase
extends CharacterBody3D

@export var mouse_sensitivity := 0.01
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var base_move_speed_multiplier := 1.0
@export var acceleration: float = 100.0
@export var num_legs := 15

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
@onready var leg_prototype: CollisionShape3D = $LegPrototype

func _ready():
	move_speed_multiplier = base_move_speed_multiplier
	
	# sunflower spiral
	var hitbox := main_collision_shape.shape as CapsuleShape3D
	var ray := leg_prototype.shape as SeparationRayShape3D
	var PHI := PI * (1 + sqrt(5))
	for i in range(num_legs):
		var indice := float(i) + 0.5
		var r: float = clamp(sqrt(indice / float(num_legs)), 0.0, sqrt(2.0)/2.0) * hitbox.radius
		var t := PHI * indice
		var pos := Vector3(r * cos(t), ray.length, r * sin(t))
		var leg := CollisionShape3D.new()
		leg.name = "Leg_%s" % i
		leg.position = pos
		leg.rotation = leg_prototype.rotation
		leg.shape = ray
		add_child(leg)

func _physics_process(delta: float):
	if not is_on_floor():
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


func _on_attack_hitbox_body_entered(body: Node3D) -> void:
	if "apply_damage" in body:
		body.apply_damage(1)
		attack_hitbox.monitoring = false

func apply_damage(amount: float):
	print("Ouchie! ", get_parent().name)
