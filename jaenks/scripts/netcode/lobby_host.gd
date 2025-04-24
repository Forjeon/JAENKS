class_name LobbyHostGD extends Node
#FIXME:TODO:NOTE: ONLY ACCEPT JOIN REQUESTS IF CURRENT PLAYER COUNT IS BELOW MAX


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
var local_peer: LobbyPeerGD;
var max_players: int;
var server_name: String;


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
	broadcast_peer.put_packet(("%s;%s;%d;%d" % [self.BROADCAST_MESSAGE, self.server_name, self.local_peer.get_peer_count(), self.max_players]).to_utf8_buffer());


# Sets up server details
func set_up_server(n: String, max_player_count: int, lobby_peer: LobbyPeerGD) -> void:
	self.server_name = n;
	self.max_players = max_player_count;
	self.local_peer = lobby_peer;

