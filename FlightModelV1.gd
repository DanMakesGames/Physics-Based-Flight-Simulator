extends RigidBody3D

@onready var HUD_debug = %debug

@onready var left_wing = $left_wing
@onready var right_wing = $right_wing
@onready var elevator_wing = $elevator_wing
@onready var vertical_stabilizer_wing = $vertical_stabilizer_wing

var throttle : float = 0
var elevator : float = 0
var ailerons : float = 0

@export_group("Controls")
@export var throttle_sensitivity : float = 1.0
@export var pitch_sensitivity : float = 0.1
@export var roll_sensitivity : float = 1

@export_group("Aerodynamics")
@export var max_thrust : float = 0
@export var aileron_max_angle : float = 5
@export var body_drag : float = 1
@export var roll_dampening : float = 2

func ready_for_play() -> void:
	freeze = false
	sleeping = false

func _physics_process(delta: float) -> void:
	pass
	#HUD_debug.text = ""
	#process_input(delta)
	#aerodynamic_update(delta)

# digest input
func process_input(input : Dictionary, delta : float) -> void:
	if input.has("pitch"):
		var pitch_input = input["pitch"]
		if is_zero_approx(pitch_input):
			var reduce_value = pitch_sensitivity * delta * signf(elevator)
			if signf(elevator - reduce_value) != signf(elevator):
				elevator = 0
			else:
				elevator -= reduce_value
		else:
			elevator += pitch_input * pitch_sensitivity * delta
		elevator = clampf(elevator, -1, 1)
	
	if input.has("roll"):
		ailerons = input["roll"]
		ailerons = clampf(ailerons, -1, 1)
	
	if input.has("throttle"):
		var throttle_input = input["throttle"]
		throttle = minf(maxf(throttle + throttle_sensitivity * throttle_input, 0),1)
	
	HUD_debug.text += "elevator: %f, ailerons: %f, throttle %f\n" % [elevator, ailerons, throttle]
	

func _get_local_input()->Dictionary:
	var input := {}
	
	input["pitch"] = Input.get_axis("pitch_up", "pitch_down")
	input["roll"] = Input.get_axis("roll_left", "roll_right")
	input["throttle"] = Input.get_axis("throttle_down", "throttle_up")
	
	return input

func _network_process(input:Dictionary) -> void:
	HUD_debug.text = ""
	var fixed_delta = 1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second") 
	#process_input(input, fixed_delta)
	#aerodynamic_update(fixed_delta)
	
func _save_state() -> Dictionary:
	var state := {}
	
	state["throttle"] = throttle
	state["ailerons"] = ailerons
	state["elevator"] = elevator
	
	var direct_state = PhysicsServer3D.body_get_direct_state(get_rid())
	state["transform"] = direct_state.transform
	state["velocity"] = direct_state.linear_velocity
	state[""]
	
	print("save %d, %d, %v" % [SyncManager._current_tick,multiplayer.get_unique_id(), transform.origin])
	return state

func _load_state(state: Dictionary) -> void:
	throttle = state["throttle"]
	ailerons = state["ailerons"]
	elevator = state["elevator"]
	
	ready_for_play()
	var direct_state = PhysicsServer3D.body_get_direct_state(get_rid())
	print("load %d, %d, %v" % [SyncManager._current_tick - SyncManager._rollback_ticks,multiplayer.get_unique_id(), direct_state.transform.origin])

func _on_receive_state(state: Dictionary, tick: int) -> void:
	# compare new state against old state at tick
	# if different enough, trigger a rollback 
	pass

func aerodynamic_update(delta : float):
	# Thrust Calculations
	var thrust_magnitude = max_thrust * throttle
	var thrust : Vector3 = basis.z.normalized() * thrust_magnitude
	apply_central_force(thrust)
	
	var aileron_angle : float = ailerons * aileron_max_angle
	left_wing.camber = aileron_angle
	left_wing.update_physics(self, delta)
	
	right_wing.camber = -aileron_angle
	right_wing.update_physics(self, delta)
	
	elevator_wing.camber = elevator * 5
	elevator_wing.update_physics(self, delta)
	
	# body drag
	var body_drag_force_magnitude : float = linear_velocity.length_squared() *  body_drag
	var body_drag_force : Vector3 = linear_velocity.normalized() * -1.0 * body_drag_force_magnitude
	apply_central_force(body_drag_force)
	
	# body roll
	var roll_velocity : float = angular_velocity.dot(basis.z)
	var roll_dampening_magnitude : float = pow(roll_velocity,2) * -1.0 * signf(roll_velocity) * roll_dampening
	apply_torque(basis.z.normalized() * roll_dampening_magnitude)
	
	vertical_stabilizer_wing.update_physics(self, delta)
	
	var local_velocity = linear_velocity * basis.orthonormalized()
	var AoA_sign = -signf(local_velocity.y)
	var AoA = rad_to_deg(local_velocity.angle_to(Vector3(0,0,1))) * AoA_sign
	
	var pitch_velocity = angular_velocity.dot(basis.x)
	
	if HUD_debug != null:
		HUD_debug.text += "AoA %f, %f \n" % [AoA, 1.0/delta]
		HUD_debug.text += "Wing Lift: %f \n" % [left_wing.lift_out.length() + right_wing.lift_out.length()]
		HUD_debug.text += "Speed: %f, Pitch Vel: %f\n" % [linear_velocity.length(), rad_to_deg(pitch_velocity)]
		HUD_debug.text += "Alt: %f, Pitch %f, Roll %f\n" % [position.y, rad_to_deg(basis.z.angle_to(Vector3(basis.z.x,0,basis.z.z).normalized())) * signf(basis.z.y), rad_to_deg(rotation.z)]
		HUD_debug.text += elevator_wing.get_debug_string() + "\n"
		HUD_debug.text += vertical_stabilizer_wing.get_debug_string() + "\n"
