class_name LobbyHostGD extends Node


# Signals
signal sig_join_approved(address: String);


# Constants
const HANDSHAKE_PORT: int = 25251;
const BROADCAST_MESSAGE: String = "Let us get JAENKSy";
const BROADCAST_PORT: int = 25250;

# Instance variables
var broadcast_peer: PacketPeerUDP = PacketPeerUDP.new();
var handshake_connection: ENetConnection = ENetConnection.new();


# -------------------------------{ Godot functions }------------------------------

# _process function
func _process(delta: float) -> void:
	if not OS.get_cmdline_args().is_empty():#FIXME:TODO: MENU SCREEN SCRIPT WILL INSTANTIATE EITHER THIS OR A LISTENER, AT WHICH POINT THIS SHOULD BE FULLY ACTIVE WITHOUT REGARD TO CLI ARGS
		broadcast_peer.put
# _ready function
func _ready() -> void:
	broadcast_peer.set_broadcast_enabled(true);
	broadcast_peer.set_dest_address("255.255.255.255", self.BROADCAST_PORT);

