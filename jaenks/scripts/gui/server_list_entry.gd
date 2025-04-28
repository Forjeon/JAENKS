class_name ServerListEntryGD extends MarginContainer


# Signals
signal sig_join(server_name: String, server_address: String);


# Onready and export variables
@onready var name_label: Label = $HBoxContainer/ServerName;
@onready var address_label: Label = $HBoxContainer/ServerAddress;
@onready var player_count_label: Label = $HBoxContainer/ServerPlayerCount;

# Instance variables
var server_name: String;
var server_address: String;
var player_count: int;
var max_player_count: int;


# -------------------------------{ Godot functions }------------------------------

# _ready function
func _ready() -> void:
	# Connect join button signals
	$HBoxContainer/JoinButton.pressed.connect(self._on_join_button_pressed);

	# Set up labels
	self.name_label.set_text(self.server_name);
	self.address_label.set_text(self.server_address);
	self.player_count_label.set_text("%d/%d" % [self.player_count, self.max_player_count]);


# ------------------------------{ Custom functions }------------------------------

func get_server_address() -> String:
	return self.address_label.get_text();


func get_server_name() -> String:
	return self.name_label.get_text();


func set_server_details(n: String, address: String, players: int, max_players: int) -> void:
	self.server_name = n;
	self.server_address = address;
	self.player_count = players;
	self.max_player_count = max_players;


# ------------------------------{ Signal functions }------------------------------

# Activated when the join button is pressed
func _on_join_button_pressed() -> void:
	self.sig_join.emit(self.get_server_name(), self.get_server_address());
