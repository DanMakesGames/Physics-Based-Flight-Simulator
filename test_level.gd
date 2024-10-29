extends Node3D

const airplane_data = preload("res://AirplaneV1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return
	if Lobby.is_playing_online():
		Lobby.player_finished_loading.rpc_id(1)
		SyncManager.sync_started.connect(start_game)
		SyncManager.sync_stopped.connect(stop_game)
		SyncManager.remote_state_mismatch.connect(on_mismatch_state)
		
		var space := get_viewport().world_3d.space
		PhysicsServer3D.space_set_active(space, false)
		
		if multiplayer.is_server():
			var client_peer_id = multiplayer.get_peers()[0]
			%Airplane1.set_multiplayer_authority(client_peer_id)
		else:
			%Airplane1.set_multiplayer_authority(multiplayer.get_unique_id())

func _save_state() -> Dictionary:
	var state : Dictionary = {}
	
	var space_3d_rid = get_viewport().world_3d.space
	state["space_state"] =  RapierPhysicsServer3D.export_binary(space_3d_rid).duplicate()
	
	return state

func _load_state(state: Dictionary) -> void:
	var space_3d_rid = get_viewport().world_3d.space
	RapierPhysicsServer3D.import_binary(space_3d_rid, state["space_state"].duplicate())

func _network_process(input:Dictionary) -> void:
	var space_rid = get_viewport().world_3d.space
	var fixed_delta = 1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

	RapierPhysicsServer3D.space_step(space_rid,fixed_delta)
	RapierPhysicsServer3D.space_flush_queries(space_rid)

#func _physics_process(delta: float) -> void:
#	var space := get_viewport().world_3d.space
#	PhysicsServer3D.space_set_active(space, false)
#	
#	var space_rid = get_viewport().world_3d.space
#	var fixed_delta = 1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
#
#	RapierPhysicsServer3D.space_step(space_rid,fixed_delta)
#	RapierPhysicsServer3D.space_flush_queries(space_rid)

func start_game():
	print("Start Game! %d" % multiplayer.get_unique_id())
	%Airplane1.ready_for_play()
	
func stop_game():
	print("Stop Game! %d" % multiplayer.get_unique_id())

func on_mismatch_state(tick, peer_id, local_hash, remote_hash) -> void:
	for state in SyncManager.state_buffer:
		var airplane_state = state.data["/root/Node3D/Airplane1"]
		var physics_transform : Transform3D = airplane_state["transform"]
		print("help %d %d %v" %[multiplayer.get_unique_id(), state.tick, physics_transform.origin])
	
