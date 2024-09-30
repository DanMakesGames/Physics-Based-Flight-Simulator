extends RigidBody3D

@onready var HUD_AoA = $VBoxContainer/AoA
@onready var HUD_lift = $VBoxContainer/Lift
@onready var HUD_Speed = $VBoxContainer/Speed
@onready var HUD_Alt = $VBoxContainer/Alt
@onready var HUD_Controls = $VBoxContainer/Controls
@onready var left_wing = $left_wing
@onready var right_wing = $right_wing
@onready var elevator_wing = $elevator_wing

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
@export var max_thrust : float = 0
@export var wing_area : float = 1
@export var aileron_max_angle : float = 5

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
	
	left_wing.update_physics(self, delta)
	right_wing.update_physics(self, delta)
	
	elevator_wing.camber = elevator * 3
	elevator_wing.update_physics(self, delta)
	
	var pitch_velocity = angular_velocity.dot(basis.x)
	HUD_lift.text = "Wing Lift: %f, Elv Lift: %f" % [left_wing.lift_out.length() + right_wing.lift_out.length(), elevator_wing.lift_out.length()]
	HUD_Speed.text = "Speed: %f, Pitch Vel: %f" % [linear_velocity.length(), rad_to_deg(pitch_velocity)]
	HUD_Alt.text = "Alt: %f, Pitch %f" % [position.y, rad_to_deg(rotation.x)]
