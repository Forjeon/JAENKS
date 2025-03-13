extends RigidBody3D


@export var MOVE_SPEED: float = 10.0;
@export var LOOK_SENSITIVITY: float = 0.005;

@onready var player_view = self.find_child("Camera3D");

var view_rotation = Vector2();


# Godot functions
func _input(event) -> void:
	# Look input
	if event is InputEventMouseMotion:
		view_rotation -= event.screen_relative * LOOK_SENSITIVITY;
		view_rotation.y = clampf(view_rotation.y, -PI/2, PI/2);


func _physics_process(delta) -> void:
	process_input_move(delta);
	process_look(delta);


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);


# Custom functions
func process_input_move(delta) -> void:
	if Input.is_action_pressed("Move Forward"):
		self.position -= self.transform.basis.z * MOVE_SPEED * delta;
	if Input.is_action_pressed("Move Backward"):
		self.position += self.transform.basis.z * MOVE_SPEED * delta;
	if Input.is_action_pressed("Move Left"):
		self.position -= self.transform.basis.x * MOVE_SPEED * delta;
	if Input.is_action_pressed("Move Right"):
		self.position += self.transform.basis.x * MOVE_SPEED * delta;


func process_look(delta) -> void:
	rotation.y = view_rotation.x;
	player_view.rotation.x = view_rotation.y;
