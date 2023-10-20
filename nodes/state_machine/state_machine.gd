@icon("res://nodes/state_machine/icon_state_machine.svg")
class_name StateMachine
extends Node

@export var this_path: NodePath
@export var default_state: StateMachineState

var this: Node
var current_state: StateMachineState

func _ready():
	this = get_node(this_path)
	assert(this)
	
	if not default_state:
		default_state = get_child(0)
	assert(default_state)
	
	for i in get_child_count():
		var child = get_child(i)
		if child is StateMachineState:
			child.process_mode = Node.PROCESS_MODE_DISABLED
	
	current_state = default_state
	
	current_state.process_mode = Node.PROCESS_MODE_INHERIT
	current_state._enter_state(null)

func _process(delta):
	for i in get_child_count():
		var child = get_child(i)
		if child is StateMachineState:
			child._process_always(delta)

func goto(state_name: String, param = null):
	var next_state = get_node(state_name) as StateMachineState
	if not next_state:
		push_error("Invalid state name: ", state_name)
		return
	
	current_state._exit_state()
	current_state.process_mode = Node.PROCESS_MODE_DISABLED
	
	current_state = next_state
	#await get_tree().process_frame
	
	current_state.process_mode = Node.PROCESS_MODE_INHERIT
	current_state._enter_state(param)
