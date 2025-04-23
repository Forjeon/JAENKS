class_name LobbyHostGD extends Node


# Signals
signal sig_join_approved(address: String);


# Constants
const HANDSHAKE_PORT: int = 25251;
const HANDSHAKE_REQUEST_MESSAGE: String = "I am a piece of JAENKS";
const BROADCAST_MESSAGE: String = "Let us get JAENKSy";
const BROADCAST_PORT: int = 25250;

# Instance variables
var broadcast_peer: PacketPeerUDP = PacketPeerUDP.new();
var broadcast_timer: float = 0.0;
var handshake_connection: ENetConnection = ENetConnection.new();
var server_name: String = "JAENKS LAN Server";


# -------------------------------{ Godot functions }------------------------------

# _process function
func _process(delta: float) -> void:
	self.broadcast_timer = minf(self.broadcast_timer + delta, 1.0);
	if self.broadcast_timer == 1.0:
		self.broadcast_timer = 0.0;
		self.broadcast_server();


# _ready function
func _ready() -> void:
	broadcast_peer.set_broadcast_enabled(true);
	broadcast_peer.set_dest_address("255.255.255.255", self.BROADCAST_PORT);


# ------------------------------{ Custom functions }------------------------------

# Broadcasts LAN server and player count
func broadcast_server() -> void:
	var player_count = 1;	# TODO: get number of players currently connected
	var max_players = 20;	# TODO: get max player count
	broadcast_peer.put_packet(("%s;%s;%d;%d" % [self.BROADCAST_MESSAGE, self.server_name, player_count, max_players]).to_utf8_buffer());


func set_server_name(n: String) -> void:
	self.server_name = n;

