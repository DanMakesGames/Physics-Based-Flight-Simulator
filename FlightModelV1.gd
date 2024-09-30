extends RigidBody3D

@onready var HUD_AoA = $VBoxContainer/AoA
@onready var HUD_lift = $VBoxContainer/Lift
@onready var HUD_Speed = $VBoxContainer/Speed
@onready var HUD_Alt = $VBoxContainer/Alt
@onready var HUD_Controls = $VBoxContainer/Controls

var pitch_input : float = 0
var roll_input : float = 0
var throttle_input : float = 0

var throttle : float = 0
var elevator : float = 0
var ailerons : float = 0
var direct_control = false

@export_group("Controls")
@export var throttle_sensitivity = 1.0

@export var pitch_sensitivity : float = 0.1
@export var roll_sensitivity : float = 0.1


@export_group("Aerodynamics")
@export var AoA_to_lift : Array[Vector2] = []
@export var AoA_to_lift_elivator : Array[Vector2] = []
@export var max_thrust : float = 0
@export var angle_of_incidence : float = 0
@export var wing_area : float = 1

## represents air density
@export var wing_lift_multiplier : float = 1
@export var wing_drag_multiplier : float = 1
@export var wing_roll_multiplier : float = 1 

## represents a lot of things including the area of the stabilizer and the distance of the tail from the center of mass
@export var vertical_stabilizer_multiplier : float = 1

## represents a lot of things including the area of the stabilizer and the distance of the tail from the center of mass
@export var horizontal_stabilizer_multiplier : float = 1

@export var roll_stabilizer_multiplier : float = 1

@export var elevator_force_multiplier : float = 1
@export var aileron_max_angle : float = 5

var left_wing : Airfoil
var right_wing : Airfoil
var elevator_wing : Airfoil

func _physics_process(delta: float) -> void:
	process_input(delta)
	aerodynamic_update(delta)

# gather and digest input
func process_input(delta : float) -> void:
	pitch_input = Input.get_axis("pitch_up", "pitch_down")
	if direct_control:
		elevator = pitch_input
	else:
		elevator += pitch_input * pitch_sensitivity * delta
	elevator = clampf(elevator, -1, 1)
	
	roll_input = Input.get_axis("roll_left", "roll_right")
	if direct_control:
		ailerons = roll_input
	else:
		ailerons += roll_input * roll_sensitivity * delta
	ailerons = clampf(ailerons, -1, 1)
	
	if Input.get_action_strength("reset_roll") > 0:
		ailerons = 0
	
	if Input.get_action_strength("reset_pitch") > 0:
		elevator = 0
	
	HUD_Controls.text = "elevator: %f, ailerons: %f" % [elevator, ailerons]
	
	throttle_input = Input.get_axis("throttle_down", "throttle_up")
	throttle = minf(maxf(throttle + throttle_sensitivity * throttle_input, 0),1)

func aerodynamic_update(delta : float):
	# Thrust Calculations
	var thrust_magnitude = max_thrust * throttle
	var thrust : Vector3 = basis.z.normalized() * thrust_magnitude
	apply_central_force(thrust)
	
	update_wings()
	update_horizontal_stabilizers()
	
	var pitch_velocity = angular_velocity.dot(basis.x)
	HUD_Speed.text = "Speed: %f, Pitch Vel: %f" % [linear_velocity.length(), rad_to_deg(pitch_velocity)]
	HUD_Alt.text = "Alt: %f, Pitch %f" % [position.y, rad_to_deg(rotation.x)]

# These calculations are not truely accurate. They provide stabilization with no genuine airframe drag
func update_stabilizers():
	# vertical
	#var local_velocity = linear_velocity * basis.orthonormalized()
	#var vertical_velocity = Vector3(local_velocity.x,0,local_velocity.z)
	#var vertical_drag_coefficient = vertical_velocity.normalized().dot(Vector3(1,0,0))
	#var vertical_drag_torque = vertical_drag_coefficient * pow(vertical_velocity.dot(Vector3(1,0,0)), 2) * vertical_stabilizer_multiplier
	#apply_torque(basis.orthonormalized().y.normalized() * vertical_drag_torque)
	
	# horizontal
	# var horizontal_velocity = Vector3(0,local_velocity.y,local_velocity.z)
	# var horizontal_drag_coefficient = horizontal_velocity.normalized().dot(Vector3(0,1,0))
	# var horizontal_drag_torque = -1.0 * horizontal_drag_coefficient * horizontal_velocity.length_squared() * horizontal_stabilizer_multiplier
	# apply_torque(basis.orthonormalized().x.normalized() * horizontal_drag_torque)
	# HUD_lift.text += "HozStab Torque %f" % horizontal_drag_torque
	
	# roll
	var roll_velocity = angular_velocity.dot(basis.z.normalized())
	var roll_drag_torque = roll_stabilizer_multiplier * pow(roll_velocity, 2)
	roll_drag_torque *= signf(roll_velocity) * -1.0
	apply_torque(basis.z * roll_drag_torque)

# TODO: This is probably not very accurate. Does not take into AoA's effect on generated lift.
func update_elevators():
	var local_velocity = linear_velocity * basis.orthonormalized()
	local_velocity.x = 0
	
	# lift calculation
	#var lift_coefficient = remap(elevator, -1, 1, elevator_min_lift_coeficient, elevator_max_lift_coeficient)
	#var lift_torque = lift_coefficient * local_velocity.length_squared() * elevator_force_multiplier
	#apply_torque(basis.orthonormalized().x.normalized() * -lift_torque)

func update_horizontal_stabilizers():
	var local_velocity = linear_velocity * basis.orthonormalized()
	local_velocity.x = 0
	
	var AoA_sign = -signf(local_velocity.y)
	var AoA = ( rad_to_deg(local_velocity.angle_to(Vector3(0,0,1))) * AoA_sign )
	
	# lift 
	#var lift_coefficient = remap(AoA - (elevator * 1), -15, 15, -1.0, 1.0)
	#var lift_force = lift_coefficient * local_velocity.length_squared() * elevator_force_multiplier
	#var local_lift_normal = local_velocity.normalized().cross(Vector3(1,0,0)).normalized() 
	#apply_force((basis.orthonormalized() * local_lift_normal) * lift_force, basis.z * -5)
	
	#var lift_coefficient = clampf(remap(AoA - (elevator * 1), -15, 15, -1.0, 1.0),-1.0,1.0)
	var lift_coefficient : float = read_data(AoA + elevator, AoA_to_lift_elivator)
	#var lift_force = lift_coefficient * local_velocity.length_squared() * elevator_force_multiplier
	#var local_lift_normal = local_velocity.normalized().cross(Vector3(1,0,0)).normalized() 
	#apply_force((basis.orthonormalized() * local_lift_normal) * lift_force, basis.z * -5)
	
	
	var local_lift_normal = local_velocity.normalized().cross(Vector3(1,0,0)).normalized() 
	apply_force((basis.orthonormalized() * local_lift_normal) * lift_coefficient * local_velocity.length_squared() * elevator_force_multiplier, basis.z * -1.0)

	# drag
	var horizontal_drag_coefficient = absf(local_velocity.normalized().dot(Vector3(0,1,0)))
	var horizontal_drag_force = horizontal_drag_coefficient * local_velocity.length_squared() * horizontal_stabilizer_multiplier
	apply_force(-1.0 * linear_velocity.normalized() * horizontal_drag_force, basis.z * -1)
	HUD_lift.text += "HozStab Torque %f" % horizontal_drag_force

func update_wings():
	# Lift Calculations
	var local_velocity = linear_velocity * basis.orthonormalized()
	var wing_local_velocity = local_velocity
	wing_local_velocity.x = 0
	
	var AoA_sign = -signf(wing_local_velocity.y)
	var wing_AoA = ( rad_to_deg(wing_local_velocity.angle_to(Vector3(0,0,1))) * AoA_sign ) + angle_of_incidence
	
	HUD_AoA.text = "Wing AoA: %f" % wing_AoA
	
	var aileron_angle_left = ailerons * aileron_max_angle
	var aileron_angle_right = -1.0 * ailerons * aileron_max_angle
	
	var lift_coefficient_left = read_data(wing_AoA + aileron_angle_left, AoA_to_lift)
	var lift_coefficient_right = read_data(wing_AoA + aileron_angle_right, AoA_to_lift)
	var drag_coefficient = absf(Vector3(0,1,0).dot(wing_local_velocity.normalized()))
	
	# Bernoulli equation
	var lift_force_left = lift_coefficient_left * wing_lift_multiplier * wing_local_velocity.length_squared() * 0.5 * wing_area
	var lift_force_right = lift_coefficient_right * wing_lift_multiplier * wing_local_velocity.length_squared() * 0.5 * wing_area
	var wing_lift_force = lift_force_left + lift_force_right
	var roll_torque = (lift_force_left - lift_force_right) * wing_roll_multiplier
	var wing_drag_force = drag_coefficient * wing_drag_multiplier * wing_local_velocity.length_squared() * 0.5 * wing_area
	
	HUD_lift.text = "Lift: %f, Torque %f" % [wing_lift_force, roll_torque]
	# lift is perpendicular to the flow
	var local_lift_normal = wing_local_velocity.normalized().cross(Vector3(1,0,0)).normalized()
	# TODO is lift always perpendicular to the aircraft or is it perpendicular to the wing?>
	apply_central_force(wing_lift_force * (basis.orthonormalized() * local_lift_normal))
	apply_central_force(wing_drag_force * (basis.orthonormalized() * wing_local_velocity).normalized() * -1.0)
	apply_torque(basis.z.normalized() * roll_torque)

func read_data(input: float, data : Array[Vector2]) -> float:
	var output : float = 0.0
	
	if AoA_to_lift.size() == 0 or input < data[0].x or input > data[-1].x:
		return output
		
	var max_range = data.size()-1
	for index in range(0,max_range):
		var current_element = data[index]
		var next_element = data[index + 1]
		if input >= current_element.x and input < next_element.x:
			output = (((input - current_element.x) / (next_element.x - current_element.x)) * (next_element.y - current_element.y)) + current_element.y
			break
	return output
