extends StateMachineState

var direction: Vector3
var startpos: Vector3
var last_root_motion: Vector3

func _enter_state(_param):
	startpos = this.global_position
	last_root_motion = Vector3.ZERO
	direction = this.aim_direction
	this.animation_tree["parameters/playback"].travel("Actions")
	this.animation_tree["parameters/Actions/playback"].travel("dodgeroll")

func _exit_state():
	print(this.global_position)
	print("%s m" % (this.global_position - startpos).length())

func update_velocity(delta: float, _default_update_velocity: Callable):
	var root_spd := 10.0 / (2.0/3.0)
	#print("root_spd ", root_spd)
	this.velocity.x = direction.x * root_spd
	this.velocity.z = direction.z * root_spd

func notify_action_finished():
	goto("Neutral")
