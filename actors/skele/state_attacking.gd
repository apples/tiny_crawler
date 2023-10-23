extends StateMachineState

var move_speed_penalty := 0.001
var direction: Vector3

func _enter_state(_param):
	direction = this.aim_direction
	this.animation_tree["parameters/playback"].travel("Actions")
	this.animation_tree["parameters/Actions/playback"].travel("attack1")

func handle_direction(delta: float):
	this.velocity.x = direction.x * move_speed_penalty
	this.velocity.z = direction.z * move_speed_penalty

func notify_action_finished():
	goto("Neutral")
