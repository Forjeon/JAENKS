class_name LobbyPeerGD extends Node
#FIXME:TODO:NOTE: MUST PERIODICALLY SYNC PEERS MESH PEER LISTS (HOST IS AUTHORITY)


# Constants
const BASE_PORT: int = LobbyHostGD.BROADCAST_PORT;
const HOST_PEER_ID: int = 2;
const PROXY_PLAYER_SCENE: PackedScene = preload("res://scenes/player/proxy_player.tscn");

# Onready and export variables
@onready var local_player = $LocalPlayer;

# Instance variables
var local_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();
var pending_peers: Dictionary[int, ENetConnection] = {};
var peer_id: int; var proxy_players: Dictionary[int, Node] = {};


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

	# Set local peer
	self.multiplayer.set_multiplayer_peer(self.local_peer);


# ------------------------------{ Custom functions }------------------------------

# Adds a new peer to the mesh
func add_peer(id: int, address: String) -> void:
	var peer_connection = ENetConnection.new();
	var port = self.BASE_PORT + self.peer_id;
	peer_connection.create_host();
	peer_connection.connect_to_host(address, port);
	print("Connecting to peer %d at %s:%d" % [id, address, port]);
	self.pending_peers[id] = peer_connection;


# Creates the initial P2P mesh
func create_mesh(peers: Array) -> void:
	for id in peers:
		var peer_connection = ENetConnection.new();
		var port = self.BASE_PORT + id;
		peer_connection.create_host_bound("*", port);
		print("Listening for peer %d at *:%d" % [id, port]);
		self.pending_peers[id] = peer_connection;


# Finalize connection of initial peers to mesh
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


# Find the next smallest available peer ID
func get_next_peer_id(peers: Array) -> int:	# Expects peers to be Array[int]
	var smallest_free_peer_id = self.HOST_PEER_ID
	peers.sort();
	for id in peers:
		if smallest_free_peer_id != id:
			break;
		smallest_free_peer_id += 1;
	return smallest_free_peer_id;


func get_peer_list() -> Array:	# True return type is Array[int], but Godot doesn't like that for some reason
	var peers = Array(self.multiplayer.get_peers());
	peers.push_back(self.peer_id);
	peers.sort();
	return peers;


func get_player_count() -> int:
	return self.multiplayer.get_peers().size() + 1;	# Magic number 1 makes sure to include local peer as one of the players in the lobby



func has_pending_peers() -> bool:
	return not self.pending_peers.is_empty();


# Set up this peer as host
func set_as_host(lobby_host: Node) -> void:
	# Connect lobby host signals
	lobby_host.sig_join_approved.connect(self._on_host_join_approved);

	# Set up local peer
	self.set_up_local_peer(self.HOST_PEER_ID);
	self.create_mesh([]);


# Set up this peer as non host
func set_as_peer(peers: Array[int]) -> void:
	self.set_up_local_peer(self.get_next_peer_id(peers));
	self.create_mesh(peers);


# Set up this peer
func set_up_local_peer(id: int) -> void:
	self.peer_id = id;
	self.local_peer.create_mesh(self.peer_id);


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
	var id = self.get_next_peer_id(Array(self.multiplayer.get_peers()));
	self.rpc("add_peer", id, address);


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

