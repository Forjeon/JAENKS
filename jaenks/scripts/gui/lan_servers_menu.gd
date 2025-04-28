extends VBoxContainer


# Constants
const GAME_SCENE_FILEPATH: String = "res://scenes/levels/testing01.tscn";
const LOBBY_PEER_SCENE_FILEPATH: String = "res://scenes/lobby/lobby_peer.tscn";
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
	# TODO: in the future, server_name will be used to give a join loading screen such as "Joining <server_name>..." with a loading bar / processing indicator
	# Perform handshake
	var handshake_peer = StreamPeerTCP.new();
	handshake_peer.set_no_delay(true);
	handshake_peer.connect_to_host(server_address, LobbyHostGD.HANDSHAKE_PORT);
	handshake_peer.poll();

	# Wait for connection to be established
	while not (handshake_peer.get_status() == StreamPeerTCP.Status.STATUS_CONNECTED or handshake_peer.get_status() == StreamPeerTCP.Status.STATUS_ERROR):
		await self.get_tree().create_timer(0.1).timeout;
		handshake_peer.poll();
	
	if handshake_peer.get_status() == StreamPeerTCP.Status.STATUS_ERROR:
		# TODO: handle somehow (show popup?)
		return;

	# Start handshake
	handshake_peer.put_string(LobbyHostGD.HANDSHAKE_MESSAGE);
	var peers = handshake_peer.get_var();

	if peers.is_empty():
		# Handshake failed
		# TODO: handle somehow (show popup?)
		return;
	else:
		# Handshake succeeded; join game
		#	Instantiate game scene
		var game = load(self.GAME_SCENE_FILEPATH).instantiate();

		# Set up lobby peer
		var lobby_peer = load(self.LOBBY_PEER_SCENE_FILEPATH).instantiate();
		(lobby_peer as LobbyPeerGD).set_as_peer(peers);
		game.add_child(lobby_peer);

		# Switch to game scene
		self.get_tree().root.add_child(game);
		self.get_tree().root.remove_child(self);
