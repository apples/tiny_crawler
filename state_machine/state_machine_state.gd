@icon("res://state_machine/icon_state_machine_state.svg")
class_name StateMachineState
extends Node

var state_machine: StateMachine

var this: Node:
	get: return state_machine.this

var state_parameter

func _enter_state(_param):
	pass

func _exit_state():
	pass

func _process_always(_delta):
	pass

func _ready():
	state_machine = get_parent() as StateMachine
	assert(state_machine)

func goto(state_name: String, param = null):
	state_machine.goto(state_name, param)
