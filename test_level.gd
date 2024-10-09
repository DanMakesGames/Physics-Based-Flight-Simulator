extends Node3D

const airplane_data = preload("res://AirplaneV1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Lobby.player_finished_loading.rpc_id(1)
	SyncManager.sync_started.connect(start_game)
	SyncManager.sync_started.connect(stop_game)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_game():
	print("Start Game!")
	#$Airplane1.set_sleeping(false)
	
func stop_game():
	print("Stop Game!")
