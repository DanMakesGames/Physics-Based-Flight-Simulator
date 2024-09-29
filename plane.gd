extends Node3D

@onready var HUD_node = $VBoxContainer/Info

var pitch_input : float = 0
var roll_input : float = 0
var throttle_input : float = 0
var throttle : float = 0

var velocity : Vector3
var rotation_delta : Quaternion

var net_forces : Vector3


var throttle_sensitivity = 1.0

var max_pitch_speed = 1
var max_roll_speed = 1

const gravity : float = 9.8

@export_group("Aerodynamics")
@export var AoA_to_lift : Array[Vector2] = []
@export var AoA_to_drag : Array[Vector2] = []
## In degrees
@export var angle_of_incidence : float = 0.0

## m^2
@export var wing_area : float = 1.0 

# kg/m^3
@export var air_pressure : float = 1.0 

#kg
@export var mass : float = 1.0 

@export var max_thrust = 10

# AoA in degrees
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

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	return
	process_input()
	process_physics(delta)
	update_transformation(delta)

# gather and digest input
func process_input() -> void:
	pitch_input = Input.get_axis("pitch_up", "pitch_down")
	roll_input = Input.get_axis("roll_left", "roll_right")
	throttle_input = Input.get_axis("throttle_down", "throttle_up")
	throttle = minf(maxf(throttle + throttle_sensitivity * throttle_input, 0),1)
	
	
func process_physics(delta_time : float) ->void:
	net_forces = Vector3.ZERO
	
	var thrust_magnitude = max_thrust * throttle
	var thrust : Vector3 = transform.basis.z.normalized() * thrust_magnitude
	
	net_forces += thrust
	
	var horizon_angle = rad_to_deg(basis.z.angle_to(Vector3(0,0,1)))
	#var lift = calculate_lift()
	var plane_space : Basis = Basis(quaternion)
	var local_velocity =  velocity * basis.orthonormalized()
	local_velocity.x = 0
	
	var AoA_sign = -signf(local_velocity.y)
	var AoA = ( rad_to_deg(local_velocity.angle_to(Vector3(0,0,1))) * AoA_sign ) + angle_of_incidence
	
	HUD_node.text = "AoA %f, localV %v" % [AoA, local_velocity]
	
	var lift_coefficient = read_data(AoA, AoA_to_lift)
	var drag_coefficient = read_data(AoA, AoA_to_drag)
	# time for the lift equation, aka the Bernoulli equation
	var lift_force = lift_coefficient * air_pressure * local_velocity.length_squared() * 0.5 * wing_area
	var drag_force = drag_coefficient * air_pressure * local_velocity.length_squared() * 0.5 * wing_area
	
	net_forces += basis.y.normalized() * lift_force
	net_forces += velocity.normalized() * -1.0 * drag_force
	
	var gravity_force = Vector3.DOWN * gravity * mass
	
	net_forces += gravity_force
	
		# lets give ourselves some hope
	if position.y <= 0.01:
		net_forces += -1.0 * gravity_force
		velocity.y = maxf(0.0, velocity.y)
	
	var speed = velocity.dot(basis.z.normalized())
	
	#HUD_node.text = "Horizon %4f, AoA %4f, Force: %-4v, Velocity %-4v, Lift %4f, Thrust %4f" % [horizon_angle, AoA, net_forces, velocity, lift, thrust_magnitude]
	#HUD_node.text = "Horizon %f, AoA %f, Lift %f, speed %f" % [horizon_angle, AoA, lift, speed]
	#print("Horizon %f, AoA %f, Force: %v, Velocity %v, Lift %f, Thrust %f" % [horizon_angle, AoA, net_forces, velocity, lift, thrust_magnitude])
	var acceleration = net_forces / mass
	velocity += acceleration * delta_time
	
	var pitch_delta : Quaternion = Quaternion(Vector3(1,0,0), delta_time * max_pitch_speed * pitch_input)
	var roll_delta : Quaternion = Quaternion(Vector3(0,0,1), delta_time * max_roll_speed * roll_input)
	
	rotation_delta = pitch_delta * roll_delta
	
func calculate_lift() -> float:
	
	var plane_space : Basis = Basis(quaternion)
	var local_velocity =  velocity * basis.orthonormalized()
	local_velocity.x = 0
	
	var AoA_sign = -signf(local_velocity.y)
	var AoA = ( rad_to_deg(local_velocity.angle_to(Vector3(0,0,1))) * AoA_sign ) + angle_of_incidence
	
	HUD_node.text = "AoA %f, localV %v" % [AoA, local_velocity]
	
	var lift_coefficient = read_data(AoA,AoA_to_lift)
	# time for the lift equation, aka the Bernoulli equation
	var lift_force = lift_coefficient * air_pressure * local_velocity.length_squared() * 0.5 * wing_area
	return lift_force

func update_transformation(delta_time : float) -> void:
	position += delta_time * velocity
	
	position.y = maxf(0, position.y)
	
	quaternion = quaternion * rotation_delta

func calculate_AoA() -> float:
	var plane_space : Basis = Basis(quaternion)
	var local_velocity = velocity * basis.orthonormalized()
	local_velocity.x = 0
	
	var AoA_sign = -signf(local_velocity.y)
	var AoA = ( rad_to_deg(local_velocity.angle_to(Vector3(0,0,1))) * AoA_sign ) + angle_of_incidence
	return AoA
