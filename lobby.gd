extends Node

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CLIENTS = 8

signal server_connected
signal server_connected_failed

var players_loaded : int = 0

func _ready() -> void:
	var args = Array(OS.get_cmdline_args())
	for arg in args:
		var key = arg.trim_prefix("--")
		if key == "server":
			initialize_server()
	
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	SyncManager.sync_lost.connect(on_sync_lost)
	SyncManager.sync_regained.connect(on_sync_regained)
	SyncManager.sync_error.connect(on_sync_error)
	

func initialize():
	players_loaded = 0

func initialize_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer

func initialize_client(in_ip:String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(in_ip, PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(on_server_connected)
	multiplayer.connection_failed.connect(on_server_connected_failed)

func is_playing_online() -> bool:
	return multiplayer.has_multiplayer_peer() == false || multiplayer.multiplayer_peer.get_connection_status() == 0

func on_server_connected():
	server_connected.emit()
	
func on_server_connected_failed():
	server_connected_failed.emit()

func connect_to_server(input_IP : String ):
	initialize_client(input_IP)
	
func on_peer_connected(peer_id):
	print("peer connected id: %d" % peer_id)
	SyncManager.add_peer(peer_id)

func on_peer_disconnected(peer_id):
	print("peer disconnected id: %d" % peer_id)
	SyncManager.remove_peer(peer_id)

func tell_server_to_start_game() -> void:
	if multiplayer.is_server() == true:
		return
	start_game_server.rpc_id(1)
	
@rpc("any_peer","call_remote","reliable")
func start_game_server():
	if multiplayer.is_server() == false:
		return
	# let server gather some ping data if it hasnt already.
	await(2.0)
	print("Start Game")
	load_game.rpc()

@rpc("authority", "call_local", "reliable")
func load_game():
	get_tree().change_scene_to_file("res://TestLevel.tscn")

@rpc("any_peer", "call_local", "reliable")
func player_finished_loading():
	players_loaded += 1
	var required_loaded = multiplayer.get_peers().size() + 1
	print("Player Loaded %d / %d" % [players_loaded, required_loaded])
	if players_loaded >= required_loaded:
		print("Start Game")
		SyncManager.start()
	
func on_sync_lost():
	print("lost sync")

func on_sync_regained():
	print("sync regained")

func on_sync_error(message:String):
	print("Sync Error: " + message)
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	SyncManager.clear_peers()
