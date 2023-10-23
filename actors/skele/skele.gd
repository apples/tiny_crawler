extends Node3D

@export var properties: Dictionary
@export var mouse_sensitivity := 0.01

@onready var character_base = $CharacterBase
@onready var state_machine: StateMachine = %StateMachine

func _ready():
	if "angle" in properties:
		print("angle, ", float(properties.angle), " / ", properties.angle)
		character_base.rotation.y = deg_to_rad(90.0 - float(properties.angle))

func _process(delta: float):
	character_base.rotation.y += delta

func handle_direction(delta: float):
	if "handle_direction" in state_machine.current_state:
		state_machine.current_state.handle_direction(delta)

func notify_action_finished():
	if "notify_action_finished" in state_machine.current_state:
		state_machine.current_state.notify_action_finished()
