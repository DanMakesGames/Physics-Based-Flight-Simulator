class_name Airfoil
extends Node

@export_group("Aerodynamics")
@export var AoA_max : float = 20
@export var lift_coefficient_max : float = 1.2
@export var lift_coefficient_zero_AOA : float = 0
@export var wing_area : float = 1
@export var local_offset : Vector3 = Vector3.ZERO
@export var drag_zero_AoA : float = 0.025
@export var drag_multiplier : float = 1.0
@export var lift_multiplier : float = 1.0

var camber : float = 0

var lift_out : Vector3
var drag_out : Vector3
var last_AoA : float

func update_physics(body : RigidBody3D, delta:float):
	var global_offset = body.basis.orthonormalized() * local_offset
	var local_velocity = body.linear_velocity * body.basis.orthonormalized()
	
	var AoA_sign = -signf(local_velocity.y)
	var AoA = rad_to_deg(local_velocity.angle_to(Vector3(0,0,1))) * AoA_sign
	AoA += camber
	
	if absf(AoA) > AoA_max and is_zero_approx(local_velocity.length()) != true:
		print("Stall: %s AOA: %f->%f Lift_Orth: %f, Drag_Orth: %f" % [name,last_AoA, AoA, lift_out.dot(body.basis.y), drag_out.dot(body.basis.y)] )
	
	# Lift
	var lift_coefficient : float = 0
	if absf(AoA) <= AoA_max:
		if AoA <= 0:
			lift_coefficient = remap(AoA, -AoA_max, 0, -lift_coefficient_max, lift_coefficient_zero_AOA)
		else:
			lift_coefficient = remap(AoA, 0, AoA_max, lift_coefficient_zero_AOA, lift_coefficient_max)
			
	# Bernoulli equation
	var lift_force_magnitude : float = lift_coefficient * local_velocity.length_squared() * 0.5 * wing_area * lift_multiplier
	
	# lift is perpendicular to the flow
	var local_lift_normal = local_velocity.normalized().cross(Vector3(1,0,0)).normalized()
	var lift_force : Vector3 = (body.basis.orthonormalized() * local_lift_normal) * lift_force_magnitude
	lift_out = lift_force
	body.apply_force(lift_force, global_offset)
	
	# Drag
	var drag_coefficient = absf(Vector3(0,1,0).dot(local_velocity.normalized())) + drag_zero_AoA
	var drag_force_magnitude = drag_coefficient * local_velocity.length_squared() * 0.5 * wing_area * drag_multiplier
	
	# drag is in the opposite direction of flow
	var drag_force = (body.basis.orthonormalized() * local_velocity.normalized()).normalized() * -1.0 * drag_force_magnitude
	drag_out = drag_force
	last_AoA = AoA
	body.apply_force(drag_force, global_offset)
