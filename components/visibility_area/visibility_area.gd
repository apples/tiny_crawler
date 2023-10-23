extends Area3D

var seeable_bodies: Array[Node3D] = []

@onready var ray_cast: RayCast3D = $RayCast3D

func _physics_process(delta: float) -> void:
	var seen_this_frame: Array[Node3D] = []
	for body: PhysicsBody3D in get_overlapping_bodies():
		for so in body.get_shape_owners():
			var xform := body.shape_owner_get_transform(so)
			ray_cast.target_position = to_local(body.global_position + xform.origin)
			ray_cast.force_raycast_update()
			var can_see := ray_cast.get_collider() == body
			if can_see:
				seen_this_frame.append(body)
				break
	seeable_bodies = seeable_bodies.filter(func (body):
		return body in seen_this_frame
	)
	seeable_bodies.append_array(seen_this_frame.filter(func (body):
		return body not in seeable_bodies
	))
