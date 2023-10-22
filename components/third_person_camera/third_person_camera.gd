extends Node3D

@onready var camera: Camera3D = %Camera3D
@onready var camera_spring_arm: SpringArm3D = %CameraSpringArm

var facing_basis: Basis:
	get:
		return camera.global_basis

var pitch: float:
	get:
		return camera_spring_arm.rotation.x
	set(v):
		camera_spring_arm.rotation.x = v

var yaw: float:
	get:
		return camera_spring_arm.rotation.y
	set(v):
		camera_spring_arm.rotation.y = v

var roll: float:
	get:
		return camera.rotation.z
	set(v):
		camera.rotation.z = v

var distance: float:
	get:
		return camera_spring_arm.spring_length
	set(v):
		camera_spring_arm.spring_length = v
