extends Node


# Constants
const BASE_PORT = 2525;
const PROXY_PLAYER_SCENE = preload("res://scenes/player/proxy_player.tscn");

# Onready and export variables
@onready var local_player = $LocalPlayer;

# Instance variables
var mesh_hosts = {};
var enet = ENetMultiplayerPeer.new();
var proxy_players = {};


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
	
	# Create the peer-to-peer mesh
	var ids = {};
	for i in range(2, 22):
		ids[i] = "127.0.0.1";
	for a in OS.get_cmdline_args():
		if a.is_valid_int() and ids.has(a.to_int()):
			self.create_p2p_mesh(a.to_int(), ids);


# ------------------------------{ Custom functions }------------------------------

# Creates the peer-to-peer mesh
func create_p2p_mesh(my_id: int, peers: Dictionary) -> void:
	self.enet.create_mesh(my_id);
	self.multiplayer.set_multiplayer_peer(enet);
	
	var my_id_pos = peers.keys().find(my_id);
	var port_index = 0;
	for id in peers:
		if id == my_id:
			continue;
		
		port_index += 1;
		var connection = ENetConnection.new();
		var port = self.BASE_PORT + ((port_index + my_id_pos) % peers.size());
		
		if id < my_id:
			connection.create_host_bound("*", port);
			print("Peer %d listening on %s:%d" % [id, peers[id], port]);
		else:
			connection.create_host();
			connection.connect_to_host(peers[id], port);
			print("Peer %d connecting to %s:%d" % [id, peers[id], port]);
		
		self.mesh_hosts[id] = connection;


#	Handle peers connecting
func poll_peer_slots() -> void:
	for id in self.mesh_hosts:
		var host = self.mesh_hosts[id];
		var ret = host.service();
		
		# Peer connected
		if ret[0] == ENetConnection.EVENT_CONNECT:
			print("Adding host %d" % id);
			self.enet.add_mesh_peer(id, host);
			self.mesh_hosts.erase(id);
		# Peer error
		elif ret[0] != ENetConnection.EVENT_NONE:
			print("Mesh peer error %d" % id);
			self.mesh_hosts.erase(id);
	
	enet.poll();


func push_player_transform() -> void:
	if not proxy_players.is_empty():
		self.rpc("transfer_player_transform", self.local_player.transform);


# --------------------------------{ RPC functions }-------------------------------

# Updates peers to declare that the local player has crouched
@rpc("any_peer", "call_remote", "reliable", 2)
func transfer_player_crouch() -> void:
	print("RECEIVED PEER %d CROUCH" % self.multiplayer.get_remote_sender_id());	# TODO
	self.proxy_players[self.multiplayer.get_remote_sender_id()].try_crouch();


# Updates peers with the new local player position
@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func transfer_player_position(player_position: Vector3) -> void:
	print("RECEIVED PEER %d POSITION" % self.multiplayer.get_remote_sender_id());#FIXME:DEL
	#self.proxy_players[self.multiplayer.get_remote_sender_id()].set_position(player_position);
	self.proxy_players[self.multiplayer.get_remote_sender_id()].update_position(player_position);


# Updates peers with the new local player rotation
@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func transfer_player_rotation(player_rotation: Vector3) -> void:
	print("RECEIVED PEER %d ROTATION" % self.multiplayer.get_remote_sender_id());#FIXME:DEL
	#self.proxy_players[self.multiplayer.get_remote_sender_id()].set_rotation(player_rotation);
	self.proxy_players[self.multiplayer.get_remote_sender_id()].update_rotation(player_rotation);


# Updates peers to declare that the local player has uncrouched
@rpc("any_peer", "call_remote", "reliable", 2)
func transfer_player_uncrouch() -> void:
	print("RECEIVED PEER %d UNCROUCH" % self.multiplayer.get_remote_sender_id());	# TODO
	self.proxy_players[self.multiplayer.get_remote_sender_id()].try_uncrouch();


# ------------------------------{ Signal functions }------------------------------

# Activated when a peer connects to the mesh
func _on_peer_connected(id: int) -> void:
	print("Peer %d connected" % id);
	self.proxy_players[id] = PROXY_PLAYER_SCENE.instantiate();
	self.add_child(self.proxy_players[id]);


# Activated when a peer disconnects from the mesh
func _on_peer_disconnected(id: int) -> void:
	# TODO: ragdoll peer proxy player
	print("Peer %d disconnected" % id);
	self.remove_child(self.proxy_players[id]);
	self.proxy_players.erase(id);


# Activated when the local player crouches
func _on_player_crouch() -> void:
	self.rpc("transfer_player_crouch");
	print("CROUCH");#FIXME:DEL


# Activated when the local player position changes
func _on_player_positioned(player_position: Vector3) -> void:
	self.rpc("transfer_player_position", player_position);
	print("POSITIONED");#FIXME:DEL


# Activated when the local player rotation changes
func _on_player_rotated(player_rotation: Vector3) -> void:
	self.rpc("transfer_player_rotation", player_rotation);
	print("ROTATED");#FIXME:DEL


# Activated when the local player uncrouches
func _on_player_uncrouch() -> void:
	self.rpc("transfer_player_uncrouch");
	print("UNCROUCH");#FIXME:DEL

