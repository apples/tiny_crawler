class_name ControlEvent
extends RefCounted

var type: StringName
var pressed: bool
var value

func _init(p_type: StringName, p_pressed: bool, p_value = null):
	type = p_type
	pressed = p_pressed
	value = p_value
