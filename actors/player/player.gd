extends Node3D

@export var properties: Dictionary
@export var mouse_sensitivity := 0.01

@onready var camera = %ThirdPersonCamera
@onready var character_base = $CharacterBase
@onready var state_machine: StateMachine = %StateMachine

func _ready():
	var angle := deg_to_rad(float(properties.angle) if "angle" in properties else 0.0)
	character_base.rotation.y = angle
	camera.yaw = angle

func _input(event: InputEvent):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			camera.yaw += -event.relative.x * mouse_sensitivity
			camera.pitch = clampf(camera.pitch - event.relative.y * mouse_sensitivity, -deg_to_rad(60), deg_to_rad(60))
		if event.is_action_pressed("zoom_in"):
			camera.distance /= 1.1
		if event.is_action_pressed("zoom_out"):
			camera.distance *= 1.1
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_F8:
					Engine.time_scale = 1
				KEY_F9:
					Engine.time_scale = 0.1
			

func _process(delta: float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	character_base.move_direction = (camera.facing_basis * Vector3(input_dir.x, 0, input_dir.y) * Vector3(1, 0, 1)).normalized()
	#print(character_base.move_direction)

func update_velocity(delta: float, default_update_velocity: Callable):
	if "update_velocity" in state_machine.current_state:
		state_machine.current_state.update_velocity(delta, default_update_velocity)

func notify_action_finished():
	if "notify_action_finished" in state_machine.current_state:
		state_machine.current_state.notify_action_finished()
