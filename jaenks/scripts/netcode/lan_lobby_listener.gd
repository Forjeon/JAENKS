extends Node


# Signals
signal sig_join_approved(peers: Array);


# Constants
const HANDSHAKE_PORT: int = 25251;
const LISTEN_PORT: int = 25250;

# Instance variables
var listener_peer: PacketPeerUDP = PacketPeerUDP.new();
var handshake_connection: ENetConnection = ENetConnection.new();


# -------------------------------{ Godot functions }------------------------------

# _process function
func _process(delta: float) -> void:
	# TODO: LIST AVAILABLE LAN SERVERS AND MAKE JOIN REQUEST BASED ON GUI (INSTEAD OF DEFAULTING TO AUTO JOIN REQUEST AS IS CURRENTLY IMPLEMENTED, WHICH ONLY WORKS IF THERE IS ONE LAN SERVER PRESENT)
	if self.listener_peer.get_available_packet_count() > 0:
		var packet_contents = listener_peer.get_packet().get_string_from_ascii();
		var packet_source_address = self.listener_peer.get_packet_ip();
		print("Received message from %s:%d \"%s\"" % [packet_source_address, self.listener_peer.get_packet_port(), packet_contents]);
		if packet_contents == "Let us get JAENKSy":	# TODO: move this to a constant in lobby_host.gd which is accessible here
			self.join(packet_source_address);


# _ready function
func _ready() -> void:
	if OS.get_cmdline_args().is_empty():
		self.listener_peer.bind(self.LISTEN_PORT, "0.0.0.0");


# ------------------------------{ Custom functions }------------------------------

func join(address: String) -> void:
	# TODO: HANDLE MULTIPLE SIMULTANEOUS JOIN REQUESTS (LISTENER MUST LOOP ON TRYING TO CONNECT UNTIL IT SUCCEEDS OR IS DENIED)
	print("JOIN TODO")#FIXME:DEL
	#handshake_connection.create_host();
	#handshake_connection.connect_to_host(address, self.HANDSHAKE_PORT);

