extends RigidBody3D


# Onready variables
@onready var collision: CollisionShape3D = $CollisionShape3D;
@onready var temp_character_body: MeshInstance3D = $MeshInstance3D;	# TODO: switch this to handle actual character body

# Instance variables
var is_crouching = false;


# -------------------------------------{ API }------------------------------------

# Enter crouching state
func try_crouch() -> void:
	if not self.is_crouching:
		# Set crouching state
		self.is_crouching = true;

		# Scale and translate collision
		self.collision.position.y = self.collision.position.y / 2.0;
		self.collision.set_scale(Vector3(1.0, 0.5, 1.0));

		#FIXME:TEMP scale and translate temp character body
		self.temp_character_body.position.y = self.temp_character_body.position.y / 2.0;
		self.temp_character_body.set_scale(Vector3(1.0, 0.5, 1.0));
		#FIXME:ENDTEMP


# Exit crouching state
func try_uncrouch() -> void:
	if self.is_crouching:
		# Reset crouching state
		self.is_crouching = false;

		# Scale and translate collision
		self.collision.position.y = self.collision.position.y * 2.0;
		self.collision.set_scale(Vector3(1.0, 1.0, 1.0));

		#FIXME:TEMP scale and translate temp character body
		self.temp_character_body.position.y = self.temp_character_body.position.y * 2.0;
		self.temp_character_body.set_scale(Vector3(1.0, 1.0, 1.0));
		#FIXME:ENDTEMP


# Synchronize position
func update_position(remote_position: Vector3) -> void:
	self.set_position(remote_position);


# Synchronize rotation
func update_rotation(remote_rotation: Vector3) -> void:
	self.set_rotation(remote_rotation);

