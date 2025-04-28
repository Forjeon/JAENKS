class_name LobbyHostGD extends Node


# Signals
signal sig_join_approved(address: String);


# Constants
const HANDSHAKE_PORT: int = 25251;
const HANDSHAKE_MESSAGE: String = "I am a piece of JAENKS";
const BROADCAST_MESSAGE: String = "Let us get JAENKSy";
const BROADCAST_PORT: int = 25250;

# Instance variables
var broadcast_peer: PacketPeerUDP = PacketPeerUDP.new();
var broadcast_timer: float = 0.0;
#var handshake_peer: PacketPeerUDP = PacketPeerUDP.new();
var handshake_server: TCPServer = TCPServer.new();
var local_lobby_peer: LobbyPeerGD;
var max_players: int;
var server_name: String;


# -------------------------------{ Godot functions }------------------------------

# _process function
func _process(delta: float) -> void:
	# Broadcast LAN server and perform handshakes
	self.broadcast_timer = minf(self.broadcast_timer + delta, 1.0);
	if self.broadcast_timer == 1.0:
		self.broadcast_timer = 0.0;
		self.broadcast_server();
		self.perform_handshake();


# _ready function
func _ready() -> void:
	# Set up broadcast peer
	self.broadcast_peer.set_broadcast_enabled(true);
	self.broadcast_peer.set_dest_address("255.255.255.255", self.BROADCAST_PORT);

	# Set up handshake peer
	#self.handshake_peer.bind(self.HANDSHAKE_PORT, "*");
	self.handshake_server.listen(self.HANDSHAKE_PORT);


# ------------------------------{ Custom functions }------------------------------

# Broadcasts LAN server and player count
func broadcast_server() -> void:
	self.broadcast_peer.put_packet(("%s;%s;%d;%d" % [self.BROADCAST_MESSAGE, self.server_name, self.local_lobby_peer.get_player_count(), self.max_players]).to_utf8_buffer());


# Attempts the join handshake with the next join request peer
func perform_handshake() -> void:
	# Check for pending handshakes
	if self.handshake_server.is_connection_available():
		var handshake_peer = self.handshake_server.take_connection();
		handshake_peer.set_no_delay(true);
		handshake_peer.poll();

		# Wait for connection to be established
		while not (handshake_peer.get_status() == StreamPeerTCP.Status.STATUS_CONNECTED or handshake_peer.get_status() == StreamPeerTCP.Status.STATUS_ERROR):
			await self.get_tree().create_timer(0.1).timeout;
			handshake_peer.poll();

		if handshake_peer.get_status() == StreamPeerTCP.Status.STATUS_ERROR:
			return;
		
		# Packet is a join request; begin handshake
		if handshake_peer.get_string() == self.HANDSHAKE_MESSAGE:
			if self.local_lobby_peer.get_player_count() < self.max_players and not self.local_lobby_peer.has_pending_peers():
				# Peer may join
				handshake_peer.put_var(self.local_lobby_peer.get_peer_list());
				self.sig_join_approved.emit(handshake_peer.get_connected_host());
			else:
				# Peer may not join
				handshake_peer.put_var(Array());


# Sets up server details
func set_up_server(n: String, max_player_count: int, lobby_peer: LobbyPeerGD) -> void:
	self.server_name = n;
	self.max_players = max_player_count;
	self.local_lobby_peer = lobby_peer;

