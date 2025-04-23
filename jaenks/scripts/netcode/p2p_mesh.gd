extends Node


# Constants
const BASE_PORT = 25250;
const PROXY_PLAYER_SCENE = preload("res://scenes/player/proxy_player.tscn");

# Onready and export variables
@onready var local_player = $LocalPlayer;

# Instance variables
var local_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();
var pending_peers: Dictionary<int, ENetConnection> = {};
var peer_id: int;
var proxy_players: Dictionary = {};


# -------------------------------{ Godot functions }------------------------------

func _process(delta) -> void:
	self.poll_peer_slots();


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
	
	#FIXME:TODO: MOVE THIS TO OTHER SCRIPTS (LAN LISTENER, ONLINE SERVER SELECTOR, ETC.)
	#var peers: Dictionary = {};

	if not OS.get_cmdline_args().is_empty():#FIXME:TODO: GET HOST IP FROM LAN LISTENER / ONLINE SERVER SELECTOR AND GUI STUFF
		self.create_p2p_mesh({});
	else:
		self.create_p2p_mesh({2: "10.0.0.8"});

	#	Create the peer-to-peer mesh
	#var ids = {};
	#for i in range(2, 22):
		#ids[i] = "127.0.0.1";
	#for a in OS.get_cmdline_args():
		#if a.is_valid_int() and ids.has(a.to_int()):
			#self.create_p2p_mesh(a.to_int(), ids);
			#self.create_p2p_mesh(peers);


# ------------------------------{ Custom functions }------------------------------

# Creates the peer-to-peer mesh
func create_p2p_mesh(peers: Dictionary) -> void:
	self.peer_id = peers.size() + 2;
	self.set_up_local_peer();

	for id in peers:
		if id == self.peer_id:
			continue;

		var connection = ENetConnection.new();
		var port = self.BASE_PORT + id;

		if id < self.peer_id:
			connection.create_host_bound("*", port);
			print("Peer %d for peer %d listening on %s:%d" % [id, self.peer_id, peers[id], port]);
		else:
			connection.create_host();
			connection.connect_to_host(peers[id], port);
			print("Peer %d for peer %d connecting to %s:%d" % [id, self.peer_id, peers[id], port]);

		self.pending_peers[id] = connection;


#	Handle peers connecting
func poll_peer_slots() -> void:
	for id in self.pending_peers:
		var host = self.pending_peers[id];
		var ret = host.service();
		
		# Peer connected
		if ret[0] == ENetConnection.EVENT_CONNECT:
			print("Adding host %d" % id);
			self.local_peer.add_mesh_peer(id, host);
			self.pending_peers.erase(id);
		# Peer error
		elif ret[0] != ENetConnection.EVENT_NONE:
			print("Mesh peer error %d" % id);
			self.pending_peers.erase(id);
	
	self.local_peer.poll();


func set_up_local_peer() -> void:
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

