extends Node3D

@export var properties: Dictionary
@export var mouse_sensitivity := 0.01

var target: CharacterBody3D
var last_target_position: Vector3

@onready var character_base: CharacterBody3D = $CharacterBase
@onready var state_machine: StateMachine = %StateMachine
@onready var visibility_area: Area3D = $VisibilityArea
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	var angle := deg_to_rad(float(properties.angle) if "angle" in properties else 0.0)
	character_base.rotation.y = angle

func update_velocity(delta: float, default_update_velocity: Callable):
	if "update_velocity" in state_machine.current_state:
		state_machine.current_state.update_velocity(delta, default_update_velocity)

func notify_action_finished():
	if "notify_action_finished" in state_machine.current_state:
		state_machine.current_state.notify_action_finished()


func _on_character_base_process_done() -> void:
	global_position = character_base.global_position
