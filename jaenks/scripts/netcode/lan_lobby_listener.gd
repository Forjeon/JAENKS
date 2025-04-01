extends Node


# -------------------------------{ Godot functions }------------------------------

# _ready function
func _ready() -> void:
	print("IPS: %s" % IP.get_local_addresses());
	for x in IP.get_local_interfaces():
		print(x);

