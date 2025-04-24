extends VBoxContainer


# Constants
const TITLE_MENU_SCENE_FILEPATH: String = "res://scenes/gui/title_screen_menu.tscn";


# -------------------------------{ Godot functions }------------------------------

# _ready function
func _ready() -> void:
	# Connect server list signals
	$ScrollContainer/MarginContainer/LANServerList.sig_join.connect(self._on_lan_server_list_join);

	# Connect back button signals
	$BackButton.pressed.connect(self._on_back_button_pressed);


# ------------------------------{ Signal functions }------------------------------

# Activated when the back button is pressed
func _on_back_button_pressed() -> void:
	self.get_tree().change_scene_to_file(self.TITLE_MENU_SCENE_FILEPATH);


# Activated when a server join button is pressed in the server list
func _on_lan_server_list_join(server_name: String, server_address: String) -> void:
	print("JOIN TODO");#FIXME:DEL
	# TODO: instantiate the peer version of the game scene and plug in the server address
	# TODO: in the future, server_name will be used to give a join loading screen such as "Joining <server_name>..." with a loading bar / processing indicator
