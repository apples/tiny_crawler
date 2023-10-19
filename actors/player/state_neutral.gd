extends StateMachineState

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("attack"):
			goto("Attacking")
	
	if event.is_action_pressed("dodge"):
		goto("Dodge")

func handle_direction(delta: float):
	this.default_handle_direction(delta)
