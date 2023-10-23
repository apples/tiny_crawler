extends StateMachineState

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("attack"):
			goto("Attacking")
	
	if event.is_action_pressed("dodge"):
		goto("Dodge")

func update_velocity(delta: float, default_update_velocity: Callable):
	default_update_velocity.call(delta)
