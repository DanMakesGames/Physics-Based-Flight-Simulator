extends Node2D

func _ready() -> void:
	Lobby.server_connected.connect(on_server_connected)
	Lobby.server_connected_failed.connect(on_server_connected_failed)

func _on_connect_button_pressed() -> void:
	Lobby.connect_to_server(%IpLineEdit.text)

func _on_start_button_pressed() -> void:
	Lobby.tell_server_to_start_game()

func on_server_connected():
	%StatusText.text = "Server connected!"

func on_server_connected_failed():
	%StatusText.text = "Failed to connect to server."
