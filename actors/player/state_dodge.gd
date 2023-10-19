extends StateMachineState

var direction: Vector3

func _enter_state(_param):
	direction = (this.velocity * Vector3(1, 0, 1)).normalized() if not this.velocity.is_zero_approx() else this.basis * Vector3.FORWARD
	this.animation_tree["parameters/ActionStateMachine/playback"].start("dodge")
	this.animation_tree["parameters/ActionOneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

#func _exit_state():
	#this.move_speed /= move_speed_penalty

func handle_direction(delta: float):
	this.velocity.x = direction.x * this.move_speed
	this.velocity.z = direction.z * this.move_speed
