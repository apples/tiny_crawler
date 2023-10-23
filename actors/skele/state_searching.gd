extends StateMachineState

func _enter_state(_params):
	var nav := this.navigation_agent as NavigationAgent3D
	nav.target_position = this.last_target_position
	

func _physics_process(delta: float) -> void:
	if not this.visibility_area.seeable_bodies.is_empty():
		this.target = this.visibility_area.seeable_bodies.pick_random()
		print("Start chase")
		goto("Chasing")
		return
	
	var nav := this.navigation_agent as NavigationAgent3D
	
	if nav.is_navigation_finished():
		print("search failed")
		character.move_direction = Vector3.ZERO
		goto("Idle")
		return
	
	var next_pos := nav.get_next_path_position()
	
	character.move_direction = ((next_pos - character.global_position) * Vector3(1, 0, 1)).normalized()

func update_velocity(delta: float, default_update_velocity: Callable):
	default_update_velocity.call(delta)
