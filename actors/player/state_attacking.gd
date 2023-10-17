extends StateMachineState

var move_speed_penalty := 0.25

func _enter_state(_param):
	this.move_speed *= move_speed_penalty

func _exit_state():
	this.move_speed /= move_speed_penalty

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			this.rotate_y(-event.relative.x * this.mouse_sensitivity)
			this.camera.rotate_x(-event.relative.y * this.mouse_sensitivity)
			this.camera.rotation.x = clampf(this.camera.rotation.x, -deg_to_rad(85), deg_to_rad(85))
	
