@tool
class_name MotionInterpolator3D
extends Node3D

enum MotionMode {
	PHYSICS_INTERPOLATION,
	SMOOTH_DAMP,
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

@export var motion_mode: MotionMode = MotionMode.PHYSICS_INTERPOLATION:
	get:
		return motion_mode
	set(v):
		motion_mode = v
		notify_property_list_changed()
		update_configuration_warnings()

@export var position_keep_initial_offset: bool = false

@export_group("Smoothing", "smoothing")
@export_range(0.0, 1.0, 0.01) var smoothing_position: float = 0.5
@export_range(0.0, 1.0, 0.01) var smoothing_rotation: float = 0.5

@export_group("")
@export var process_func: ProcessFunc = ProcessFunc.FRAME:
	get:
		return process_func
	set(v):
		process_func = v
		update_configuration_warnings()

@onready var _target: Node3D

var _offset: Vector3

var _previous_target_xform: Transform3D
var _current_target_xform: Transform3D

func _ready():
	if process_priority == 0:
		process_priority = 1
	if process_physics_priority == 0:
		process_physics_priority = process_priority
	
	if Engine.is_editor_hint():
		return
	
	if target_path:
		_target = get_node(target_path)
	
	if position_keep_initial_offset:
		if _target:
			var parent := get_parent_node_3d()
			if parent:
				_offset = parent.global_position - _target.global_position
			else:
				push_error("Inital offset cannot be calculated: parent not valid.")
		else:
			push_error("Inital offset cannot be calculated: target not in tree.")
	
	if _target:
		_current_target_xform = _target.global_transform.translated(_offset)
		_previous_target_xform = _current_target_xform

func _process(delta:float):
	if Engine.is_editor_hint():
		return
		
	print("process")
	
	if process_func == ProcessFunc.FRAME:
		_process_func(delta)

func _physics_process(delta: float):
	if Engine.is_editor_hint():
		return
	
	print("physics_process")
	
	if process_func == ProcessFunc.PHYSICS:
		_process_func(delta)
	
	await get_tree().process_frame
	
	print("advance")
	
	_previous_target_xform = _current_target_xform
	_current_target_xform = _target.global_transform.translated(_offset)
	

func _process_func(delta: float):
	var parent := get_parent_node_3d()
	
	if not parent or not _target:
		return
	
	var target_xform := _target.global_transform.translated(_offset)
	
	match motion_mode:
		MotionMode.SMOOTH_DAMP:
			parent.global_position = parent.global_position.lerp(target_xform.origin, 1.0 - pow(smoothing_position, delta * 60.0))
			parent.global_basis = parent.global_basis.get_rotation_quaternion() \
				.slerp(target_xform.basis.get_rotation_quaternion(), 1.0 - pow(smoothing_rotation, delta * 60.0))
		MotionMode.PHYSICS_INTERPOLATION:
			parent.global_transform = _previous_target_xform.interpolate_with(_current_target_xform, Engine.get_physics_interpolation_fraction())


func _validate_property(property: Dictionary) -> void:
	if (property.name as String).begins_with("smoothing") and motion_mode != MotionMode.SMOOTH_DAMP:
		property.usage = PROPERTY_USAGE_NO_EDITOR

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
	
	if motion_mode == MotionMode.PHYSICS_INTERPOLATION and process_func == ProcessFunc.PHYSICS:
		result.append("Using PHYSICS_INTERPOLATION in the PHYSICS process_func won't have any effect. Use FRAME process_func instead.")
	
	return result
