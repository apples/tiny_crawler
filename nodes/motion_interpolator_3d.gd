@tool
class_name MotionInterpolator3D
extends Node3D

enum MotionMode {
	SMOOTH,
	STAY,
	TARGET,
}

enum ProcessFunc {
	FRAME,
	PHYSICS,
}

@export var target_path: NodePath:
	get:
		return target_path
	set(v):
		target_path = v
		update_configuration_warnings()

@export_range(0.0, 1.0, 0.01) var position_smoothing: float = 0.0
@export var position_x: MotionMode = MotionMode.SMOOTH
@export var position_y: MotionMode = MotionMode.SMOOTH
@export var position_z: MotionMode = MotionMode.SMOOTH

@export_range(0.0, 1.0, 0.01) var rotation_smoothing: float = 0.0

@export var process_func: ProcessFunc = ProcessFunc.FRAME

@onready var _target: Node3D = get_node(target_path)

func _ready():
	if process_priority == 0:
		process_priority = 1
	
	if Engine.is_editor_hint():
		return
	
	if target_path:
		_target = get_node(target_path)
	

func _process(delta:float):
	if process_func == ProcessFunc.FRAME:
		_process_func(delta)

func _physics_process(delta: float):
	if process_func == ProcessFunc.PHYSICS:
		_process_func(delta)

func _process_func(delta: float):
	if Engine.is_editor_hint():
		return
	
	var parent := get_parent_node_3d()
	
	if not parent or not _target:
		return
	
	var position_factor = 1.0 - pow(position_smoothing, delta * 60.0)
	var rotation_factor = 1.0 - pow(rotation_smoothing, delta * 60.0)
	
	var stay_position := parent.global_position
	var target_position := _target.global_position
	var smooth_position: Vector3 = lerp(stay_position, target_position, position_factor)
	var result_position: Vector3
	
	match position_x:
		MotionMode.SMOOTH: result_position.x = smooth_position.x
		MotionMode.STAY: result_position.x = stay_position.x
		MotionMode.TARGET: result_position.x = target_position.x
	
	match position_y:
		MotionMode.SMOOTH: result_position.y = smooth_position.y
		MotionMode.STAY: result_position.y = stay_position.y
		MotionMode.TARGET: result_position.y = target_position.y
	
	match position_z:
		MotionMode.SMOOTH: result_position.z = smooth_position.z
		MotionMode.STAY: result_position.z = stay_position.z
		MotionMode.TARGET: result_position.z = target_position.z
	
	parent.global_position = result_position
	parent.global_basis = parent.global_basis.get_rotation_quaternion().slerp(_target.global_basis.get_rotation_quaternion(), rotation_factor)

func _get_configuration_warnings():
	var result := PackedStringArray()
	
	var parent := get_parent()
	
	if not parent:
		result.push_back("Must have a parent.")
	elif not parent is Node3D:
		result.push_back("Parent must be a Node3D.")
	
	if target_path == NodePath():
		result.push_back("Needs a target.")
	elif not get_node(target_path) is Node3D:
		result.push_back("Target must be a Node3D.")
	
	return result
