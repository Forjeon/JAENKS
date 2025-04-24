extends VBoxContainer


# Constants
const TITLE_MENU_SCENE_FILEPATH: String = "res://scenes/gui/title_screen_menu.tscn";

# Onready and export variables
@onready var server_max_players: LineEdit = $MaxPlayersField.get_line_edit();
@onready var server_name: LineEdit = $ServerNameField


# -------------------------------{ Godot functions }------------------------------

# _ready function
func _ready() -> void:
	# Connect host button signals
	$HostButton.pressed.connect(self._on_host_button_pressed);

	# Connect back button signals
	$BackButton.pressed.connect(self._on_back_button_pressed);


# ------------------------------{ Signal functions }------------------------------

# Activated when the back button is pressed
func _on_back_button_pressed() -> void:
	self.get_tree().change_scene_to_file(self.TITLE_MENU_SCENE_FILEPATH);


# Activated when the host button is pressed
func _on_host_button_pressed() -> void:
	print("HOST TODO: |%s| %d" % [self.server_name.get_text(), self.server_max_players.get_text().to_int()]);#FIXME:DEL
	# TODO: change to host version of the game scene and plug in server name and max player count

