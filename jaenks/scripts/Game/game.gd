extends Node


const BASE_PORT = 4333;

var mesh_hosts = {}
var enet = ENetMultiplayerPeer.new();


# Godot functions
func _process(delta):
	for id in mesh_hosts:
		var host = mesh_hosts[id];
		var ret = host.service();
		
		if ret[0] == ENetConnection.EVENT_CONNECT:
			print("Adding host %d" % id);
			enet.add_mesh_peer(id, host);
			mesh_hosts.erase(id);
		elif ret[0] != ENetConnection.EVENT_NONE:
			print("Mesh peer error %d" % id);
			mesh_hosts.erase(id);
	
	enet.poll();


func _ready():
	multiplayer.peer_connected.connect(self._on_peer_connected);
	var ids = {};
	for i in range(2, 5):
		ids[i] = "127.0.0.1";
	for a in OS.get_cmdline_args():
		if a.is_valid_int() and ids.has(a.to_int()):
			create_mesh(a.to_int(), ids);


# Custom functions
func create_mesh(my_id: int, peers: Dictionary):
	enet.create_mesh(my_id);
	multiplayer.set_multiplayer_peer(enet);
	
	var my_id_pos = peers.keys().find(my_id);
	var port_index = 0;
	for id in peers:
		if id == my_id:
			continue;
		
		port_index += 1;
		var connection = ENetConnection.new();
		var port = BASE_PORT + ((port_index + my_id_pos) % peers.size());
		
		if id < my_id:
			connection.create_host_bound("*", port);
			print("Peer %d listening on %s:%d" % [id, peers[id], port]);
		else:
			connection.create_host();
			connection.connect_to_host(peers[id], port);
			print("Peer %d connecting to %s:%d" % [id, peers[id], port]);
		
		mesh_hosts[id] = connection;


# Signal functions
func _on_peer_connected(id: int):
	print("Peer %d connected" % id);
