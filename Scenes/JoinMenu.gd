extends Control

@onready var ip_input: LineEdit = $VBoxContainer/IPLineEdit
@onready var port_input: LineEdit = $VBoxContainer/PortLineEdit
@onready var status_label: Label = $VBoxContainer/StatusLabel

func _ready() -> void:
	port_input.text = str(GameConfig.server_port)

func _on_connect_button_pressed():
	var endpoint: Dictionary = _parse_endpoint(ip_input.text, port_input.text)
	if !bool(endpoint.get("valid", false)):
		var error_message: String = str(endpoint.get("error", "Invalid server address."))
		status_label.text = error_message
		DebugLog.network_error(error_message)
		return

	var ip: String = str(endpoint.get("ip", "127.0.0.1"))
	var port: int = int(endpoint.get("port", GameConfig.DEFAULT_SERVER_PORT))
	DebugLog.network("Join requested from menu: %s:%d; log=%s" % [ip, port, DebugLog.get_network_log_path()])

	GameConfig.is_hosting = false
	GameConfig.is_dedicated_server = false
	GameConfig.set_multiplayer_provider(GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER)
	GameConfig.set_matchmaking_mode(GameConfig.MATCHMAKING_MODE_DIRECT_CONNECT)
	GameConfig.server_ip = ip
	GameConfig.server_port = port

	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")

func _parse_endpoint(raw_ip: String, raw_port: String) -> Dictionary:
	var ip: String = raw_ip.strip_edges()
	var port_text: String = raw_port.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"

	var endpoint_parts: PackedStringArray = ip.split(":")
	if endpoint_parts.size() == 2:
		ip = endpoint_parts[0].strip_edges()
		port_text = endpoint_parts[1].strip_edges()
		if port_text.is_empty() or !port_text.is_valid_int():
			return {
				"valid": false,
				"error": "Invalid port in server address.",
			}

	if ip.is_empty():
		return {
			"valid": false,
			"error": "Server IP is empty.",
		}
	if !port_text.is_empty() and !port_text.is_valid_int():
		return {
			"valid": false,
			"error": "Invalid server port.",
		}

	var port: int = GameConfig.parse_server_port(port_text)
	return {
		"valid": true,
		"ip": ip,
		"port": port,
	}
