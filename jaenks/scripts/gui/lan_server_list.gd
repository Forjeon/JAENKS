class_name LANServerListGD extends VBoxContainer


# Constants
const LISTEN_MESSAGE: String = LobbyHostGD.BROADCAST_MESSAGE;
const LISTEN_PORT: int = LobbyHostGD.BROADCAST_PORT;
const SERVER_LIST_ENTRY: PackedScene = preload("res://scenes/gui/server_list_entry.tscn");

# Instance variables
var peer: PacketPeerUDP = PacketPeerUDP.new();
var poll_timer: float = 0.0;


# -------------------------------{ Godot functions }------------------------------

# _process function
func _process(delta: float) -> void:
	# Update server list
	self.poll_timer = minf(self.poll_timer + delta, 1.0);
	if self.poll_timer == 1.0:
		self.poll_timer = 0.0;
		self.list_servers(self.find_servers());
	
# _ready function
func _ready() -> void:
	self.peer.bind(self.LISTEN_PORT, "0.0.0.0");


# ------------------------------{ Custom functions }------------------------------

# Listen for LAN server and update the server list GUI
func find_servers() -> Array[Node]:
	var server_entries = [];

	print("POLLING SERVER LIST");#FIXME:DEL
	if self.peer.get_available_packet_count() > 0:
		var packet_contents = self.peer.get_packet().get_string_from_ascii();
		var packet_source_address = self.peer.get_packet_ip();
		print("\nReceived message from %s:%d \"%s\"" % [packet_source_address, self.LISTEN_PORT, packet_contents]);#FIXME:DEL

		if packet_contents.begins_with(self.LISTEN_MESSAGE):
			var server_details = packet_contents.split(";");
			var server_name = server_details[1];
			var server_player_count = server_details[2].to_int();
			print("SERVER FOUND! \"%s\", %d, %d/20" % [server_name, packet_source_address, server_player_count]);#FIXME:DEL
			# ADD SERVER ENTRY TO LIST

	server_entries.sort_custom(self.sort_server_entries);
	return server_entries;


# Update the GUI server list
func list_servers(server_entries: Array[Node]) -> void:
	for child_node in self.get_children():
		self.remove_child(child_node);


# Sorts server entries by name and then by address (stable)
func sort_server_entries(a: Node, b: Node) -> bool:
	var server_a = a as ServerListEntryGD;
	var server_b = b as ServerListEntryGD;
	if server_a.get_server_name() < server_b.get_server_name() or (server_a.get_server_name() == server_b.get_server_name() and server_a.get_server_address() <= server_b.get_server_address()):
		return true;
	return false;

