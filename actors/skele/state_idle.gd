extends StateMachineState

func _process(delta: float) -> void:
	if not this.visibility_area.seeable_bodies.is_empty():
		this.target = this.visibility_area.seeable_bodies.pick_random()
		print("Start chase")
		goto("Chasing")
		return
	
	character.move_direction = Vector3.ZERO

func update_velocity(delta: float, default_update_velocity: Callable):
	default_update_velocity.call(delta)
