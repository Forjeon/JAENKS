class_name LobbyHostGD extends Node
#FIXME:TODO:NOTE: ONLY ACCEPT JOIN REQUESTS IF CURRENT PLAYER COUNT IS BELOW MAX


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
var handshake_peer: PacketPeerUDP = PacketPeerUDP.new();
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
	self.handshake_peer.bind(self.HANDSHAKE_PORT, "*");


# ------------------------------{ Custom functions }------------------------------

# Broadcasts LAN server and player count
func broadcast_server() -> void:
	self.broadcast_peer.put_packet(("%s;%s;%d;%d" % [self.BROADCAST_MESSAGE, self.server_name, self.local_lobby_peer.get_player_count(), self.max_players]).to_utf8_buffer());


# Attempts the join handshake with the next join request peer
func perform_handshake() -> void:
	if self.handshake_peer.get_available_packet_count() > 0:
		var packet_contents = self.handshake_peer.get_packet().get_string_from_ascii();

		# Packet is a join request; begin handshake
		if packet_contents == self.HANDSHAKE_MESSAGE:
			# Get handshake peer details
			var peer_address = self.handshake_peer.get_packet_ip();

			# Conclude handshake
			self.handshake_peer.set_dest_address(peer_address, self.HANDSHAKE_PORT);
			if self.local_lobby_peer.get_player_count() < self.max_players and not self.local_lobby_peer.has_pending_peers():
				# Peer may join
				self.handshake_peer.put_var(self.local_lobby_peer.get_peer_list());
				self.sig_join_approved.emit(peer_address);
			else:
				# Peer may not join
				self.handshake_peer.put_var([]);


# Sets up server details
func set_up_server(n: String, max_player_count: int, lobby_peer: LobbyPeerGD) -> void:
	self.server_name = n;
	self.max_players = max_player_count;
	self.local_lobby_peer = lobby_peer;

