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
	print("PEER HANDSHAKING %s" % server_address);#FIXME:DEL
	var handshake_connection = ENetConnection.new();
	handshake_connection.create_host();
	var handshake_peer = handshake_connection.connect_to_host(server_address, LobbyHostGD.HANDSHAKE_PORT);
	handshake_peer.put_packet(LobbyHostGD.HANDSHAKE_MESSAGE.to_utf8_buffer());
	while handshake_peer.get_available_packet_count() == 0:
		print("WAITING FOR HANDSHAKE");
	var peers = handshake_peer.get_var();

	if peers.is_empty():
		# Handshake failed
		print("JOIN HANDSHAKE DENIED");#FIXME:DEL
		# TODO: handle somehow (show popup?)
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
