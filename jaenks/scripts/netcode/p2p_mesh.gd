extends Node


const BASE_PORT = 2525;
const PROXY_PLAYER_SCENE = preload("res://scenes/player/proxy_player.tscn");

@onready var LOCAL_PLAYER = $LocalPlayer;

var mesh_hosts = {};
var enet = ENetMultiplayerPeer.new();
var proxy_players = {};


# Godot functions
func _process(delta) -> void:
	self.poll_peer_slots();


func _ready() -> void:
	multiplayer.peer_connected.connect(self._on_peer_connected);
	multiplayer.peer_disconnected.connect(self._on_peer_disconnected);
	
	var ids = {};
	for i in range(2, 22):
		ids[i] = "127.0.0.1";
	for a in OS.get_cmdline_args():
		if a.is_valid_int() and ids.has(a.to_int()):
			self.create_p2p_mesh(a.to_int(), ids);


# Custom functions
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
		self.rpc("transfer_player_transform", self.LOCAL_PLAYER.transform);


# RPC functions
@rpc("any_peer", "call_remote", "reliable", 2)
func transfer_player_crouch() -> void:
	print("RECEIVED PEER %d CROUCH" % self.multiplayer.get_remote_sender_id());	# TODO


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func transfer_player_transform(player_transform: Transform3D) -> void:
	self.proxy_players[self.multiplayer.get_remote_sender_id()].transform = player_transform;


@rpc("any_peer", "call_remote", "reliable", 2)
func transfer_player_uncrouch() -> void:
	print("RECEIVED PEER %d UNCROUCH" % self.multiplayer.get_remote_sender_id());	# TODO


# Signal functions
func _on_peer_connected(id: int) -> void:
	print("Peer %d connected" % id);
	self.proxy_players[id] = PROXY_PLAYER_SCENE.instantiate();
	self.add_child(self.proxy_players[id]);


func _on_peer_disconnected(id: int) -> void:
	print("Peer %d disconnected" % id);
	self.remove_child(self.proxy_players[id]);
	self.proxy_players.erase(id);


func _on_player_crouch() -> void:
	self.rpc("transfer_player_crouch");


func _on_player_transformed(player_transform: Transform3D) -> void:
	self.rpc("transfer_player_transform", player_transform);


func _on_player_uncrouch() -> void:
	self.rpc("transfer_player_uncrouch");

