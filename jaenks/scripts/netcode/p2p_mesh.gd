extends Node

# TODO:
#	MESH:
#		HAS: peers/hosts
#		DOES: cp2pm(), broadcast, join, peer list, add peer, new peer, bye, del peer, end
#	GAME:
#		HAS: proxy players, local player (?)
#		DOES: player position, player rotation, player state (un/crouch, etc.), player connect, player disconnect
#	DO WE NEED poll_peer_slots() ANYMORE?
#
#	PROTOCOL: client is peer, server is lobby host peer
#		FIND GAME: LAN broadcast received or check signal server
#		HANDSHAKE (NEW CONNECTION):
#			1. client sends JOIN to server
#			- if lobby is full:
#				2. server responds to client NO
#				3. HANDSHAKE FAIL, CLIENT DOES NOT CONNECT
#			- if lobby is not full:
#				2. server responds with peer list (including host)
#				3. IN UNSPECIFIED ORDER:
#					- server adds client to its mesh
#					- server tells existing peers to add client to their meshes
#					- client creates its P2P mesh and connects to game
#		DISCONNECT:
#			1. client sends BYE to peers
#			2. IN UNSPECIFIED ORDER:
#				- client saves player/character state, closes connections and exits (back to main menu or full exit)
#				- peers remove client from their meshes
#		END GAME:
#			1. server sends END to peers
#			2. IN UNSPECIFIED ORDER:
#				- server saves game and player/character states, closes connections, and exits (back to main menu or full exit)
#				- peers save player/character states, close connections, and exit (back to main menu)


# Constants
const BASE_PORT = 25250;
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
	
	#FIXME:TODO: MOVE THIS TO OTHER SCRIPTS (LAN LISTENER, ONLINE SERVER SELECTOR, ETC.)
	var peers: Dictionary = {};

	if not OS.get_cmdline_args().is_empty():#FIXME:TODO: GET HOST IP FROM LAN LISTENER / ONLINE SERVER SELECTOR AND GUI STUFF
		#	Handshake
		# TODO: send join message to host
		# TODO: host responds with peer list if yes or empty list if no (usually due to full lobby)

	#	Create the peer-to-peer mesh
	var ids = {};
	for i in range(2, 22):
		ids[i] = "127.0.0.1";
	for a in OS.get_cmdline_args():
		if a.is_valid_int() and ids.has(a.to_int()):
			self.create_p2p_mesh(a.to_int(), ids);


# ------------------------------{ Custom functions }------------------------------

# Creates the peer-to-peer mesh
func create_p2p_mesh(peers: Dictionary) -> void:
	var my_id: int = peers.size() + 2;
	self.enet.create_mesh(my_id);
	self.multiplayer.set_multiplayer_peer(enet);
	# TODO: ALL OF THIS NEEDS TO BE REDONE. WHEN A NEW PEER JOINS, THEY HANDSHAKE WITH THE "HOST", WHO SENDS THEM THEIR LIST OF ALL CURRENTLY CONNECTED PEERS AND THEIR IPS AND ALSO ALERTS THOSE PEERS OF THE NEW PEER AND THEIR IP; EXISTING PEERS (INCLUDING THE "HOST") USE create_host_bound() TO OPEN A LISTENING CONNECTION FOR THE NEW PEER, WHO THEN USES create_host() AND connect_to_host() TO JOIN THE MESH. WHEN A PEER LEAVES, ALL REMAINING PEERS ARE NOTIFIED (MANUAL DISCONNECT) OR DETECT (NETWORK DISCONNECT) AND SIMPLY REMOVE THAT PEER FROM THEIR VIEW OF THE MESH (DISCONNECT, CLOSE BINDING, DELETE FROM PEER IP LIST). FOLLOWING THIS, LOCALHOST CANNOT BE USED AS THE IP, AND ONLY TWO PORTS WILL BE USED IN JAENKS—ONE FOR SERVER FINDING (LAN / SIGNALING SERVER) AND HANDSHAKE AND ONE FOR MESH PARTICIPATION

	#var my_id_pos = peers.keys().find(my_id);
	#var port_index = 0;
	for id in peers:
		if id == my_id:
			continue;

		#port_index += 1;
		var connection = ENetConnection.new();
		var port = self.BASE_PORT + id;
		#var port = self.BASE_PORT + ((port_index + my_id_pos) % peers.size());

		if id < my_id:
			connection.create_host_bound("*", port);
			print("Peer %d for peer %d listening on %s:%d" % [id, my_id, peers[id], port]);
		else:
			connection.create_host();
			connection.connect_to_host(peers[id], port);
			print("Peer %d for peer %d connecting to %s:%d" % [id, my_id, peers[id], port]);

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

