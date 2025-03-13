extends RigidBody3D


const AIRBORNE_MOVE_FORCE_MULT = 0.1;
const LOOK_SENSITIVITY = 0.005;
const GROUNDED_MOVE_FORCE = 1500.0;
const JUMP_VEL = 5.0;
const SPRINT_SPEED_MAX_MULT = 2.0;
const WALK_SPEED_MAX = 5.0;

@onready var player_view = self.find_child("Camera3D");

var do_direct_movement = true;
var is_grounded = true;
var is_sprinting = false;
var view_rotation = Vector2();


# Godot functions
func _input(event) -> void:
	# Look input
	if event is InputEventMouseMotion:
		view_rotation -= event.screen_relative * LOOK_SENSITIVITY;
		view_rotation.y = clampf(view_rotation.y, -PI/2, PI/2);
	# Jump input
	elif event.is_action_pressed("jump"):
		self.try_jump();
	# Sprint input
	elif event.is_action_pressed("sprint"):
		self.is_sprinting = true;
	elif event.is_action_released("sprint"):
		self.is_sprinting = false;


func _physics_process(delta) -> void:
	if self.do_direct_movement:
		process_input_move(delta);
	process_look(delta);


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);


# Custom functions
func process_input_move(delta) -> void:
	# Get move direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward");
	var move_dir = input_dir.x * self.transform.basis.x + input_dir.y * self.transform.basis.z;
	
	# Calculate move force based on player state (sprint vs. walk, grounded vs. airborne)
	var target_move_vel = move_dir * self.WALK_SPEED_MAX;
	if self.is_sprinting:
		target_move_vel *= self.SPRINT_SPEED_MAX_MULT;
	
	var move_force = (target_move_vel - self.linear_velocity) * self.GROUNDED_MOVE_FORCE;
	if not self.is_grounded:
		move_force *= self.AIRBORNE_MOVE_FORCE_MULT;
	move_force -= move_force.project(self.transform.basis.y);	# Don't damp player vertical velocity
	
	self.apply_central_force(move_force * delta);


func process_look(delta) -> void:
	rotation.y = view_rotation.x;
	player_view.rotation.x = view_rotation.y;


func try_jump() -> void:
	if self.is_grounded:
		self.apply_central_impulse(Vector3.UP * self.JUMP_VEL);
