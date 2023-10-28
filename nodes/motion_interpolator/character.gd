extends CharacterBody3D


var t := 0.0

func _ready():
	Engine.physics_ticks_per_second = 1

func _physics_process(delta: float) -> void:
	velocity.x = cos(t)
	t += delta
	move_and_slide()
