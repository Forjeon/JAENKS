extends Node


# Constants
const BASE_PORT: int = 25250;
const PROXY_PLAYER_SCENE: PackedScene = preload("res://scenes/player/proxy_player.tscn");

# Onready and export variables
@onready var local_player = $LocalPlayer;

# Instance variables
var local_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();
var pending_peers: Dictionary = {};
var peer_id: int;
var proxy_players: Dictionary = {};


# -------------------------------{ Godot functions }------------------------------

func _process(delta: float) -> void:
	self.connect_pending_peers();


# _ready function
func _ready() -> void:
	# Connect local multiplayer peer signals
	self.multiplayer.peer_connected.connect(self._on_peer_connected);
	self.multiplayer.peer_disconnected.connect(self._on_peer_disconnected);

	# Connect local player signals
	self.local_player.sig_crouch.connect(self._on_player_crouch);
	self.local_player.sig_positioned.connect(self._on_player_positioned);
	self.local_player.sig_rotated.connect(self._on_player_rotated);
	self.local_player.sig_uncrouch.connect(self._on_player_uncrouch);

	# Connect local lobby host signals
	#FIXME:TODO: LOBBY HOST SHOULD ONLY EXIST IF THIS PEER IS HOST (WILL BE HANDLED BY MENU SCREEN SCRIPT; CURRENTLY BOTH HOST AND LISTENER ARE PRESENT BUT DISABLED BASED ON CLI ARGS)
	$LobbyHost.sig_join_approved.connect(self._on_host_join_approved);

	# Connect local listener signals
	#FIXME:TODO: LISTENER SHOULD ONLY EXIST IF THIS PEER IS NOT HOST (WILL BE HANDLED BY MENU SCREEN SCRIPT; CURRENTLY BOTH HOST AND LISTENER ARE PRESENT BUT DISABLED BASED ON CLI ARGS)
	$LanLobbyListener.sig_join_approved.connect(self._on_listener_join_approved);
	
	#FIXME:TODO: MOVE THIS TO OTHER SCRIPTS (LAN LISTENER, ONLINE SERVER SELECTOR, ETC.)
	#var peers: Dictionary = {};

	if OS.get_cmdline_args().is_empty():#FIXME:TODO: GET HOST IP FROM LAN LISTENER / ONLINE SERVER SELECTOR AND GUI STUFF
		self.set_up_local_peer(2);
		self.create_mesh([]);
		#self.add_peer(3, "10.0.0.8");
	else:
		self.set_up_local_peer(3);
		self.create_mesh([2]);


# ------------------------------{ Custom functions }------------------------------

# Adds a new peer to the mesh
func add_peer(id: int, address: String) -> void:
	var peer_connection = ENetConnection.new();
	var port = self.BASE_PORT + self.peer_id;
	peer_connection.create_host();
	peer_connection.connect_to_host(address, port);
	print("Connecting to peer %d at %s:%d" % [id, address, port]);
	self.pending_peers[id] = peer_connection;


# Creates the peer-to-peer mesh
func create_mesh(peers: Array) -> void:
	for id in peers:
		var peer_connection = ENetConnection.new();
		var port = self.BASE_PORT + id;
		peer_connection.create_host_bound("*", port);
		print("Listening for peer %d at *:%d" % [id, port]);
		self.pending_peers[id] = peer_connection;


#	Handle peers connecting
func connect_pending_peers() -> void:
	for id in self.pending_peers:
		var peer_connection = self.pending_peers[id];
		var ret = peer_connection.service();
		
		# Peer connected
		if ret[0] == ENetConnection.EVENT_CONNECT:
			print("Adding peer %d" % id);
			self.local_peer.add_mesh_peer(id, peer_connection);
			self.pending_peers.erase(id);
		# Peer error
		elif ret[0] != ENetConnection.EVENT_NONE:
			print("Mesh peer error %d" % id);
			self.pending_peers.erase(id);
			#FIXME:TODO: RETRY HOW MANY TIMES BEFORE THIS LOCAL PEER DISCONNECTS ITSELF DUE TO INCOMPLETE MESH CONSTRUCTION?
	
	if not self.pending_peers.is_empty():
		self.local_peer.poll();


func set_up_local_peer(peer_id: int) -> void:
	self.peer_id = peer_id;
	self.local_peer.create_mesh(self.peer_id);
	self.multiplayer.set_multiplayer_peer(self.local_peer);


# --------------------------------{ RPC functions }-------------------------------

# Updates peers to declare that the local player has crouched
@rpc("any_peer", "call_remote", "reliable", 2)
func transfer_player_crouch() -> void:
	self.proxy_players[self.multiplayer.get_remote_sender_id()].try_crouch();


# Updates peers with the new local player position
@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func transfer_player_position(player_position: Vector3) -> void:
	self.proxy_players[self.multiplayer.get_remote_sender_id()].update_position(player_position);


# Updates peers with the new local player rotation
@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func transfer_player_rotation(player_rotation: Vector3) -> void:
	self.proxy_players[self.multiplayer.get_remote_sender_id()].update_rotation(player_rotation);


# Updates peers to declare that the local player has uncrouched
@rpc("any_peer", "call_remote", "reliable", 2)
func transfer_player_uncrouch() -> void:
	self.proxy_players[self.multiplayer.get_remote_sender_id()].try_uncrouch();


# ------------------------------{ Signal functions }------------------------------

# Activated when a peer has been approved to join the mesh hosted by this peer
func _on_host_join_approved(address: String) -> void:
	var peer_id = 3;#FIXME: DETERMINE THIS BASED ON SMALLEST PEER ID > 2 WHICH IS NOT YET TAKEN
	self.add_peer(peer_id, address);


# Activated when this peer has been approved to join a mesh
func _on_listener_join_approved(peers: Array) -> void:
	self.create_mesh(peers);


# Activated when a peer connects to the mesh
func _on_peer_connected(id: int) -> void:
	print("Peer %d connected" % id);
	# TODO: send GUI player connect note (in chatbox?)
	self.proxy_players[id] = PROXY_PLAYER_SCENE.instantiate();
	self.add_child(self.proxy_players[id]);


# Activated when a peer disconnects from the mesh
func _on_peer_disconnected(id: int) -> void:
	# TODO: ragdoll peer proxy player
	# TODO: send GUI player disconnect note (in chatbox?)
	print("Peer %d disconnected" % id);
	self.remove_child(self.proxy_players[id]);
	self.proxy_players.erase(id);


# Activated when the local player crouches
func _on_player_crouch() -> void:
	self.rpc("transfer_player_crouch");


# Activated when the local player position changes
func _on_player_positioned(player_position: Vector3) -> void:
	self.rpc("transfer_player_position", player_position);


# Activated when the local player rotation changes
func _on_player_rotated(player_rotation: Vector3) -> void:
	self.rpc("transfer_player_rotation", player_rotation);


# Activated when the local player uncrouches
func _on_player_uncrouch() -> void:
	self.rpc("transfer_player_uncrouch");
