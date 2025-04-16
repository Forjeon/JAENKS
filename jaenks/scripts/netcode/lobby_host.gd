extends Node


# Signals
signal sig_mesh_peers(peers: Dictionary);
# -------------------------------{ Godot functions }------------------------------

# _ready function
func _ready() -> void:
	# Connect mesh signals
	#	NOTE: the p2p_mesh.gd Node must be the direct parent of this Node

