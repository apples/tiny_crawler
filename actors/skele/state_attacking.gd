extends StateMachineState

var move_speed_penalty := 0.001
var direction: Vector3

func _enter_state(_param):
	direction = character.aim_direction
	character.animation_tree["parameters/playback"].travel("Actions")
	character.animation_tree["parameters/Actions/playback"].travel("attack1")

func update_velocity(delta: float, _default_update_velocity: Callable):
	character.velocity.x = direction.x * move_speed_penalty
	character.velocity.z = direction.z * move_speed_penalty

func notify_action_finished():
	goto("Chasing")
