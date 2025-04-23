extends VBoxContainer


# Constants
const SERVER_LIST_ENTRY: PackedScene = preload("res://scenes/gui/server_list_entry.tscn");


func _ready() -> void:
	print("LISTEN PORT: %d" % LobbyHostGD.BROADCAST_PORT);#FIXME:DEL

