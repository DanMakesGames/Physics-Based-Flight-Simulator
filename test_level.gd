extends Node3D

const airplane_data = preload("res://AirplaneV1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Lobby.is_playing_online():
		Lobby.player_finished_loading.rpc_id(1)
		SyncManager.sync_started.connect(start_game)
		SyncManager.sync_stopped.connect(stop_game)
		
		var space := get_viewport().world_3d.space
		PhysicsServer3D.space_set_active(space, false)
		
		if multiplayer.is_server():
			var client_peer_id = multiplayer.get_peers()[0]
			%Airplane1.set_multiplayer_authority(client_peer_id)
		else:
			%Airplane1.set_multiplayer_authority(multiplayer.get_unique_id())

func _save_state() -> Dictionary:
	var space_rid = get_viewport().world_3d.space
	print("save_state: %d airplane %v" % [multiplayer.get_unique_id(), %Airplane1.get_node("CollisionShape3D").position])
	return {"physics_state" : RapierPhysicsServer3D.export_binary(%Airplane1.get_node("CollisionShape3D").get_rid())}
	#return {"physics_state" : RapierPhysicsServer3D.export_binary(space_rid)}

func _load_state(state: Dictionary) -> void:
	var space_rid = get_viewport().world_3d.space
	
	#RapierPhysicsServer3D.import_binary(space_rid, state["physics_state"])
	var binary : PackedByteArray = state["physics_state"] as PackedByteArray
	RapierPhysicsServer3D.import_binary(%Airplane1.get_rid(), binary)
	print("load_state: %d airplane %v" % [multiplayer.get_unique_id(), %Airplane1.position])
	%Airplane1.ready_for_play()

func _network_process(input:Dictionary) -> void:
	print("_network_process %d" % multiplayer.get_unique_id())
	var space_rid = get_viewport().world_3d.space
	var fixed_delta = 1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	RapierPhysicsServer3D.space_step(space_rid,fixed_delta)
	RapierPhysicsServer3D.space_flush_queries(space_rid)
	
func start_game():
	print("Start Game! %d" % multiplayer.get_unique_id())
	#get_tree().reload_current_scene()
	%Airplane1.ready_for_play()
	
func stop_game():
	print("Stop Game! %d" % multiplayer.get_unique_id())
