extends StateMachineState

func _physics_process(delta: float) -> void:
	if this.target not in this.visibility_area.seeable_bodies:
		this.last_target_position = this.target.global_position
		this.target = null
		print("target lost")
		goto("Searching")
		return
	
	var nav := this.navigation_agent as NavigationAgent3D
	
	nav.target_position = this.target.global_position
	
	if nav.is_navigation_finished():
		print("chase done")
		character.move_direction = Vector3.ZERO
		return
	
	var next_pos := nav.get_next_path_position()
	
	character.move_direction = ((next_pos - character.global_position) * Vector3(1, 0, 1)).normalized()

func update_velocity(delta: float, default_update_velocity: Callable):
	default_update_velocity.call(delta)

func _debug_draw_path():
	return
	var nav := this.navigation_agent as NavigationAgent3D
	var lv := character.global_position
	for v in nav.get_current_navigation_path():
		DebugDraw3D.draw_line(lv, v, Color(1, 1, 0))
		DebugDraw3D.draw_sphere(v, nav.radius, Color(1, 1, 0))
