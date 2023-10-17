extends StateMachineState

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("attack"):
			#this.animation_player.play("player_animations/sword_swing")
			goto("Attacking")
		

func _process(delta):
	var facing: Vector3 = (this.velocity * Vector3(1, 0, 1)).normalized()
	
