extends RigidBody3D


@export var move_force: float;


func _physics_rocess(delta):
	apply_central_force(Vector3.FORWARD * move_force)
