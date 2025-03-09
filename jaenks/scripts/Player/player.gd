extends RigidBody3D


@export var move_speed: float;
@export var look_sensitivity: float;

var old_mouse_pos = Vector2();


func _physics_process(delta):
	process_input_move(delta);
	process_input_look(delta);


func process_input_look(delta):
	var new_mouse_pos = get_viewport().get_mouse_position();
	var yaw = self.old_mouse_pos.x - new_mouse_pos.x;
	rotate_y(yaw * look_sensitivity * delta);
	self.old_mouse_pos = new_mouse_pos;
	print(get_viewport().get_mouse_position());


func process_input_move(delta):
	var move_vec = Vector3();
	
	if Input.is_action_pressed("Move Forward"):
		move_vec.z -= 1.0;
	if Input.is_action_pressed("Move Backward"):
		move_vec.z += 1.0;
	if Input.is_action_pressed("Move Left"):
		move_vec.x -= 1.0;
	if Input.is_action_pressed("Move Right"):
		move_vec.x += 1.0;
	
	#apply_central_force(move_vec.normalized() * move_force * delta);
	set_axis_velocity(move_vec.normalized() * self.rotation * move_speed * delta);
