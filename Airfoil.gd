class_name Airfoil
extends Object

@export_group("Aerodynamics")
@export var AoA_max : float = 20
@export var lift_coefficient_max : float = 1.2
@export var wing_area : float = 1
@export var camber : float = 0
@export var local_offset : Vector3 = Vector3.ZERO
@export var drag_zero_AoA : float = 0.025
@export var drag_multiplier : float = 1.0
@export var lift_multiplier : float = 1.0

var lift_out : Vector3
var drag_out : Vector3

func update_physics(body : RigidBody3D, delta:float):
	var global_offset = body.basis.orthonormalized() * local_offset
	var local_velocity = body.linear_velocity * body.basis.orthonormalized()
	
	var AoA_sign = -signf(local_velocity.y)
	var AoA = rad_to_deg(local_velocity.angle_to(Vector3(0,0,1))) * AoA_sign
	AoA += camber
	
	# Lift
	var lift_coefficient : float = 0
	if absf(AoA) <= AoA_max:
		lift_coefficient = clampf(remap(AoA, -AoA_max, AoA_max, -lift_coefficient_max, lift_coefficient_max),  -lift_coefficient_max, lift_coefficient_max)
		
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
	var drag_force = (body.basis.orthonormalized() * local_velocity) * -1.0 * drag_force_magnitude
	drag_out = drag_force
	body.apply_force(drag_force, global_offset)
