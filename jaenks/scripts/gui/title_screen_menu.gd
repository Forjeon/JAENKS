extends VBoxContainer


# Constants
const LAN_HOST_SERVER_SCENE_FILEPATH: String = "res://scenes/gui/lan_host_server_menu.tscn";
const LAN_SERVERS_LIST_SCENE_FILEPATH: String = "res://scenes/gui/lan_servers_menu.tscn";


# -------------------------------{ Godot functions }------------------------------

# _ready function
func _ready() -> void:
	$HostLANButton.pressed.connect(self._on_host_lan_button_pressed);
	$JoinLANButton.pressed.connect(self._on_join_lan_button_pressed);
	$QuitButton.pressed.connect(self._on_quit_button_pressed);


# ------------------------------{ Signal functions }------------------------------

# Activates when the host LAN button is pressed
func _on_host_lan_button_pressed() -> void:
	self.get_tree().change_scene_to_file(self.LAN_HOST_SERVER_SCENE_FILEPATH);


# Activates when the join LAN button is pressed
func _on_join_lan_button_pressed() -> void:
	self.get_tree().change_scene_to_file(self.LAN_SERVERS_LIST_SCENE_FILEPATH);


# Activates when the quit button is pressed
func _on_quit_button_pressed() -> void:
	self.get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST);
	self.get_tree().quit();

