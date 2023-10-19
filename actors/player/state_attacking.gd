extends StateMachineState

var move_speed_penalty := 0.001

func _enter_state(_param):
	this.move_speed *= move_speed_penalty
	this.animation_tree["parameters/ActionStateMachine/playback"].start("attack1")
	this.animation_tree["parameters/ActionOneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _exit_state():
	this.move_speed /= move_speed_penalty

func notify_action_finished():
	goto("Neutral")
