extends RigidBody3D


# Signals
signal sig_crouch;
signal sig_positioned(new_position: Vector3);
signal sig_rotated(new_rotation: Vector3);
signal sig_uncrouch;


# Constants
#	Force
const AIRBORNE_MOVE_FORCE_MULT = 0.025;
const GROUNDED_MOVE_FORCE = 1500.0;
const VERTICAL_MOVE_FORCE_MULT = 0.4;
#	Speed
const AIRBORNE_SPEED_MAX = 30.0;
const CROUCH_SPEED_MULT = 0.5;
const JUMP_SPEED = 5.0;
const SPRINT_SPEED_MULT = 2.0;
const WALK_SPEED_MAX = 5.0;
#	Misc
const COYOTE_TIME_MAX = 0.2;
const LOOK_SENSITIVITY = 0.005;
#	Network synchronization
const TRANSFORM_SYNC_THRESHOLD = 0.01;

# Onready and export variables
@onready var collision: CollisionShape3D = $CollisionShape3D;
@onready var grounded_shapecast: ShapeCast3D = $GroundedShapeCast;
@onready var player_view: Camera3D = $CameraPivot/Camera3D;
@onready var player_view_pivot: Node3D = $CameraPivot;
@onready var temp_character_body: MeshInstance3D = $MeshInstance3D;	# TODO: switch this to handle actual character body
@onready var uncrouch_shapecast: ShapeCast3D = $UncrouchShapeCast;

# Instance variables
#	State
var can_uncrouch = true;
var is_crouching = false;
var is_grounded = true;
var is_jumping = false;
var is_sprinting = false;
#	Movement and orientation
var coyote_time = 0.0;
var do_direct_movement = true;
var do_movement_damping = true;
var do_try_uncrouch = false;
var target_view_rotation = Vector2();
#	Network synchronization
var old_position = Vector3();
var old_rotation = Vector3();


# -------------------------------{ Godot functions }------------------------------

# _input function
func _input(event: InputEvent) -> void:
	# Crouch input
	if event.is_action_pressed("crouch"):
		self.try_crouch();
	elif event.is_action_released("crouch"):
		self.do_try_uncrouch = true;

	# Jump input
	elif event.is_action_pressed("jump"):
		self.try_jump();
		self.is_jumping = true;
	elif event.is_action_released("jump"):
		self.is_jumping = false;

	# Look input
	elif event is InputEventMouseMotion:	# TODO: also handle controller look input
		self.set_target_view_rotation(event.get_screen_relative());

	# Sprint input
	elif event.is_action_pressed("sprint"):
		self.is_sprinting = true;
	elif event.is_action_released("sprint"):
		self.is_sprinting = false;


# _physics_process function
func _physics_process(delta: float) -> void:
	# Checks
	self.check_grounded();
	self.coyote_timer(delta);
	self.check_uncrouch();

	# State changes
	if self.do_try_uncrouch:
		self.try_uncrouch();

	# Movement and orientation
	self.process_look(delta);
	if self.do_direct_movement:
		self.process_direct_movement(delta);
	
	# Damping
	if self.do_movement_damping:
		self.process_damping(delta);


# _process function
func _process(delta: float) -> void:
	# Synchronize position
	var new_position = self.get_position();
	if absf((new_position - self.old_position).length()) > self.TRANSFORM_SYNC_THRESHOLD:
		self.sig_positioned.emit(new_position);
		self.old_position = new_position;

	# Synchronize rotation
	var new_rotation = self.get_rotation();
	if absf((new_rotation - self.old_rotation).length()) > self.TRANSFORM_SYNC_THRESHOLD:
		self.sig_rotated.emit(new_rotation);
		self.old_rotation = new_rotation;


# _ready function
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);


# ------------------------------{ Custom functions }------------------------------

# Check for groundedness with spherecast
func check_grounded() -> void:
	self.grounded_shapecast.force_shapecast_update();
	self.is_grounded = self.grounded_shapecast.is_colliding();


# Check if it is safe to uncrouch with spherecast
func check_uncrouch() -> void:
	self.uncrouch_shapecast.force_shapecast_update();
	self.can_uncrouch = not self.uncrouch_shapecast.is_colliding();


# Manage coyote time
func coyote_timer(delta: float) -> void:
	if not self.is_grounded:
		self.coyote_time = minf(self.coyote_time + delta, self.COYOTE_TIME_MAX);
	else:
		self.coyote_time = 0.0;


# Calculate input vector based on input
func get_3d_input_dir() -> Vector3:
	var horizontal_plane_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward");
	var vertical_dir = Input.get_axis("crouch", "jump");
	return Vector3(horizontal_plane_dir.x, vertical_dir, horizontal_plane_dir.y);


# Calculate the target movement speed based on input
func get_target_move_speed() -> float:
	var target_speed = self.WALK_SPEED_MAX;
	
	if self.is_sprinting:
		target_speed *= self.SPRINT_SPEED_MULT;
	
	if self.is_crouching:
		target_speed *= self.CROUCH_SPEED_MULT;
	
	return target_speed;


# Apply linear damping force based on current linear velocity and state
func process_damping(delta: float) -> void:
	var damping_force = Vector3();
	var linear_vel = self.get_linear_velocity();
	var linear_speed = linear_vel.length();

	# Grounded damping
	if self.is_grounded:
		damping_force -= linear_vel * self.GROUNDED_MOVE_FORCE;
		# Don't dampen vertical movement
		damping_force -= damping_force.project(self.transform.basis.y);
	# Airborne damping
	elif linear_speed > self.AIRBORNE_SPEED_MAX:
		damping_force -= linear_vel * self.GROUNDED_MOVE_FORCE * self.AIRBORNE_MOVE_FORCE_MULT;
	
	self.apply_central_force(damping_force * delta);


# Apply linear movement force based on input
func process_direct_movement(delta: float) -> void:
	# Get move direction and map to player orientation
	var input_dir = self.get_3d_input_dir();
	var vertical_input_dir = input_dir.project(self.transform.basis.y);
	input_dir += vertical_input_dir * self.VERTICAL_MOVE_FORCE_MULT - vertical_input_dir;
	var move_dir = input_dir.x * self.transform.basis.x + input_dir.y * self.transform.basis.y + input_dir.z * self.transform.basis.z;
	
	# Calculate target move velocity
	var target_move_vel = move_dir * self.get_target_move_speed();
	
	# Don't scale jump force—fixes infinite flying glitch
	if self.is_sprinting and self.is_jumping:
		var target_vertical_move_vel = target_move_vel.project(self.transform.basis.y);
		target_move_vel += (target_vertical_move_vel / self.SPRINT_SPEED_MULT) - target_vertical_move_vel;
	
	# Calculate move force
	var move_force = target_move_vel * self.GROUNDED_MOVE_FORCE;

	if not self.is_grounded:
		move_force *= self.AIRBORNE_MOVE_FORCE_MULT;
	
	self.apply_central_force(move_force * delta);


# Match yaw and pitch to target
func process_look(delta: float) -> void:
	rotation.y = self.target_view_rotation.x;
	player_view.rotation.x = self.target_view_rotation.y;


# Update and constrain the target yaw and pitch based on input
func set_target_view_rotation(screen_relative_vec: Vector2) -> void:
	self.target_view_rotation -= screen_relative_vec * LOOK_SENSITIVITY;
	self.target_view_rotation.y = clampf(self.target_view_rotation.y, -PI/2, PI/2);


# Enter crouching state
func try_crouch() -> void:
	if self.is_crouching == false:
		# Synchronize crouch
		self.sig_crouch.emit();

		# Set crouching state
		self.is_crouching = true;

		# Scale and translate collision
		self.collision.position.y = self.collision.position.y / 2.0;
		self.collision.set_scale(Vector3(1.0, 0.5, 1.0));

		# Translate view pivot
		self.player_view_pivot.position.y = self.player_view_pivot.position.y / 2.0;

		#FIXME:TEMP scale and translate temp character body
		self.temp_character_body.position.y = self.temp_character_body.position.y / 2.0;
		self.temp_character_body.set_scale(Vector3(1.0, 0.5, 1.0));
		#FIXME:ENDTEMP


# Replace vertical speed with jump based on input and state
func try_jump() -> void:
	if self.is_grounded or self.coyote_time < self.COYOTE_TIME_MAX:
		self.set_axis_velocity(self.transform.basis.y *self.JUMP_SPEED);


# Exit crouching state
func try_uncrouch() -> void:
	if self.can_uncrouch:
		# Synchronize uncrouch
		self.sig_uncrouch.emit();

		# Reset crouching state
		self.is_crouching = false;
		self.do_try_uncrouch = false;

		# Scale and translate collision
		self.collision.position.y = self.collision.position.y * 2.0;
		self.collision.set_scale(Vector3(1.0, 1.0, 1.0));

		# Translate view pivot
		self.player_view_pivot.position.y = self.player_view_pivot.position.y * 2.0;

		#FIXME:TEMP scale and translate temp character body
		self.temp_character_body.position.y = self.temp_character_body.position.y * 2.0;
		self.temp_character_body.set_scale(Vector3(1.0, 1.0, 1.0));
		#FIXME:ENDTEMP

