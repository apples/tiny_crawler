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

@export var process_func: ProcessFunc = ProcessFunc.FRAME

@export_group("Position", "position")
@export var position_keep_initial_offset: bool = false
@export var position_motion_mode: MotionMode = MotionMode.PHYSICS_INTERPOLATION:
	get:
		return position_motion_mode
	set(v):
		position_motion_mode = v
		notify_property_list_changed()
@export_range(0.0, 1.0, 0.01) var position_smoothing_x: float = 0.0
@export_range(0.0, 1.0, 0.01) var position_smoothing_y: float = 0.0
@export_range(0.0, 1.0, 0.01) var position_smoothing_z: float = 0.0

@export_group("Rotation", "rotation")
@export var rotation_motion_mode: MotionMode = MotionMode.PHYSICS_INTERPOLATION:
	get:
		return rotation_motion_mode
	set(v):
		rotation_motion_mode = v
		notify_property_list_changed()
@export_range(0.0, 1.0, 0.01) var rotation_smoothing: float = 0.0

@onready var _target: Node3D

var _offset: Vector3

var _previous_target_xform: Transform3D
var _current_target_xform: Transform3D

func _validate_property(property: Dictionary) -> void:
	if (property.name as String).begins_with("position_smoothing") and position_motion_mode != MotionMode.SMOOTH_DAMP:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if (property.name as String).begins_with("rotation_smoothing") and rotation_motion_mode != MotionMode.SMOOTH_DAMP:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _ready():
	if process_priority == 0:
		process_priority = 1
	
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
	
	var stay_xform := parent.global_transform
	var target_xform := _target.global_transform.translated(_offset)
	
	if target_xform != _current_target_xform:
		_previous_target_xform = _current_target_xform
		_current_target_xform = target_xform
	
	match position_motion_mode:
		MotionMode.SMOOTH_DAMP:
			parent.global_position = Vector3(
				lerpf(stay_xform.origin.x, target_xform.origin.x, 1.0 - pow(position_smoothing_x, delta * 60.0)),
				lerpf(stay_xform.origin.y, target_xform.origin.y, 1.0 - pow(position_smoothing_y, delta * 60.0)),
				lerpf(stay_xform.origin.z, target_xform.origin.z, 1.0 - pow(position_smoothing_z, delta * 60.0)))
		MotionMode.PHYSICS_INTERPOLATION:
			parent.global_position = _previous_target_xform.origin.lerp(_current_target_xform.origin, Engine.get_physics_interpolation_fraction())
	
	match rotation_motion_mode:
		MotionMode.SMOOTH_DAMP:
			parent.global_basis = stay_xform.basis.get_rotation_quaternion()\
				.slerp(target_xform.basis.get_rotation_quaternion(), 1.0 - pow(rotation_smoothing, delta * 60.0))
		MotionMode.PHYSICS_INTERPOLATION:
			parent.global_basis = _previous_target_xform.basis.get_rotation_quaternion()\
				.slerp(_current_target_xform.basis.get_rotation_quaternion(), Engine.get_physics_interpolation_fraction())

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
