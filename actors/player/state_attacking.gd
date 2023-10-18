extends StateMachineState

var move_speed_penalty := 0.001

func _enter_state(_param):
	this.move_speed *= move_speed_penalty
	this.animation_tree["parameters/AttackOneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	await get_tree().create_timer(2.0)
	goto("Neutral")

func _exit_state():
	this.move_speed /= move_speed_penalty

