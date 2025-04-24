extends VBoxContainer


# Signals
signal sig_host_lan();
signal sig_join_lan();


# -------------------------------{ Godot functions }------------------------------

# _ready function
func _ready() -> void:
	$HostLANButton.pressed.connect(self._on_host_lan_button_pressed);
	$JoinLANButton.pressed.connect(self._on_join_lan_button_pressed);
	$QuitButton.pressed.connect(self._on_quit_button_pressed);


# ------------------------------{ Signal functions }------------------------------

# Activates when the host LAN button is pressed
func _on_host_lan_button_pressed() -> void:
	self.sig_host_lan.emit();


# Activates when the join LAN button is pressed
func _on_join_lan_button_pressed() -> void:
	self.sig_join_lan.emit();


# Activates when the quit button is pressed
func _on_quit_button_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST);
	get_tree().quit();

