extends RigidBody3D


const AIRBORNE_MOVE_FORCE_MULT = 0.1;
const COYOTE_TIME = 0.2;
const LOOK_SENSITIVITY = 0.005;
const GROUNDED_MOVE_FORCE = 1500.0;
const JUMP_VEL = 5.0;
const SPRINT_SPEED_MAX_MULT = 2.0;
const WALK_SPEED_MAX = 5.0;

@onready var player_view: Camera3D = $CameraPivot/Camera3D;
@onready var grounded_shapecast: ShapeCast3D = $GroundedShapeCast;

var do_direct_movement = true;
var do_movement_damping = true;
var is_grounded = true;
var is_sprinting = false;
var target_view_rotation = Vector2();
# TODO: crouching, holding crouch/jump whilst airborne to move down/up, coyote time


# Godot functions
func _input(event: InputEvent) -> void:
	# Look input
	if event is InputEventMouseMotion:	# TODO: also handle controller look input
		self.set_target_view_rotation(event.screen_relative);
	# Jump input
	elif event.is_action_pressed("jump"):
		self.try_jump();
	# Sprint input
	elif event.is_action_pressed("sprint"):
		self.is_sprinting = true;
	elif event.is_action_released("sprint"):
		self.is_sprinting = false;


func _physics_process(delta: float) -> void:
	self.check_grounded();
	# TODO: spherecast for groundedness + coyote time
	if self.do_direct_movement:
		self.process_input_move(delta);
	self.process_look(delta);


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);


# Custom functions
func check_grounded() -> void:
	self.grounded_shapecast.force_shapecast_update();
	self.is_grounded = self.grounded_shapecast.is_colliding();


func process_input_move(delta: float) -> void:
	# Get move direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward");
	var move_dir = input_dir.x * self.transform.basis.x + input_dir.y * self.transform.basis.z;
	
	# Calculate target move velocity
	var target_move_vel = move_dir * self.WALK_SPEED_MAX;
	if self.is_sprinting:
		target_move_vel *= self.SPRINT_SPEED_MAX_MULT;
	
	# Dampen current velocity towards target move velocity
	var move_force = target_move_vel * self.GROUNDED_MOVE_FORCE;
	if self.do_movement_damping and self.is_grounded:
		move_force -= self.linear_velocity * self.GROUNDED_MOVE_FORCE;
		
	if not self.is_grounded:
		move_force *= self.AIRBORNE_MOVE_FORCE_MULT;
		
	move_force -= move_force.project(self.transform.basis.y);	# Don't damp player vertical velocity
	
	self.apply_central_force(move_force * delta);


func process_look(delta: float) -> void:
	rotation.y = self.target_view_rotation.x;
	player_view.rotation.x = self.target_view_rotation.y;


func set_target_view_rotation(screen_relative_vec: Vector2) -> void:
	self.target_view_rotation -= screen_relative_vec * LOOK_SENSITIVITY;
	self.target_view_rotation.y = clampf(self.target_view_rotation.y, -PI/2, PI/2);


func try_jump() -> void:
	if self.is_grounded:
		self.apply_central_impulse(Vector3.UP * self.JUMP_VEL);
