extends VBoxContainer


# Constants
const GAME_SCENE_FILEPATH: String = "res://scenes/levels/testing01.tscn";
const LOBBY_HOST_SCENE_FILEPATH: String = "res://scenes/lobby/lobby_host.tscn";
const LOBBY_PEER_SCENE_FILEPATH: String = "res://scenes/lobby/lobby_peer.tscn";
const TITLE_MENU_SCENE_FILEPATH: String = "res://scenes/gui/title_screen_menu.tscn";

# Onready and export variables
@onready var server_max_players: LineEdit = $MaxPlayersField.get_line_edit();
@onready var server_name: LineEdit = $ServerNameField


# -------------------------------{ Godot functions }------------------------------

# _ready function
func _ready() -> void:
	# Connect host button signals
	$HostButton.pressed.connect(self._on_host_button_pressed);

	# Connect back button signals
	$BackButton.pressed.connect(self._on_back_button_pressed);


# ------------------------------{ Signal functions }------------------------------

# Activated when the back button is pressed
func _on_back_button_pressed() -> void:
	self.get_tree().change_scene_to_file(self.TITLE_MENU_SCENE_FILEPATH);


# Activated when the host button is pressed
func _on_host_button_pressed() -> void:
	# Instantiate game scene
	var game = load(self.GAME_SCENE_FILEPATH).instantiate();

	# Set up lobby host
	var lobby_peer = load(self.LOBBY_PEER_SCENE_FILEPATH).instantiate();	# Lobby peer created here to be used in lobby host setup call
	var lobby_host = load(self.LOBBY_HOST_SCENE_FILEPATH).instantiate();
	(lobby_host as LobbyHostGD).set_up_server(self.server_name.get_text(), self.server_max_players.get_text().to_int(), lobby_peer as LobbyPeerGD);
	game.add_child(lobby_host);

	# Set up lobby peer
	(lobby_peer as LobbyPeerGD).set_as_host(lobby_host);
	game.add_child(lobby_peer);

	# Switch to game scene
	self.get_tree().root.add_child(game);
	self.get_tree().root.remove_child(self);


