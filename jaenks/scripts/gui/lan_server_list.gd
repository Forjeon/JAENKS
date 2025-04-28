class_name LANServerListGD extends VBoxContainer


# Signals
signal sig_join(server_name: String, server_address: String);


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
	var server_entries: Array[Node] = [];

	# Check through received packets
	while self.peer.get_available_packet_count() > 0:
		var packet_contents = self.peer.get_packet().get_string_from_ascii();

		# Packet is a LAN server broadcast; add it to the list of LAN servers
		if packet_contents.begins_with(self.LISTEN_MESSAGE):
			# Get server details
			var server_details = packet_contents.split(";");
			var server_name = server_details[1];
			var server_player_count = server_details[2].to_int();
			var server_max_players = server_details[3].to_int();

			var server_address = self.peer.get_packet_ip();

			# Create server list entry
			var server_entry = self.SERVER_LIST_ENTRY.instantiate();
			(server_entry as ServerListEntryGD).set_server_details(server_name, server_address, server_player_count, server_max_players);
			server_entry.sig_join.connect(self._on_server_join_pressed);

			# Add server to list
			server_entries.push_back(server_entry);

	server_entries.sort_custom(self.sort_server_entries);
	return server_entries;


# Update the GUI server list
func list_servers(server_entries: Array[Node]) -> void:
	# Remove previously found servers
	for child_node in self.get_children():
		self.remove_child(child_node);
	
	# List newly found servers
	for server_entry_node in server_entries:
		self.add_child(server_entry_node);


# Sorts server entries by name and then by address (stable)
func sort_server_entries(a: Node, b: Node) -> bool:
	var server_a = a as ServerListEntryGD;
	var server_b = b as ServerListEntryGD;
	if server_a.get_server_name() < server_b.get_server_name() or (server_a.get_server_name() == server_b.get_server_name() and server_a.get_server_address() <= server_b.get_server_address()):
		return true;
	return false;


# ------------------------------{ Signal functions }------------------------------

# Activated when any server list entry join button is pressed
func _on_server_join_pressed(server_name: String, server_address: String) -> void:
	self.sig_join.emit(server_name, server_address);

