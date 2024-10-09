extends Camera3D

var rotation_offset : Vector3
var is_freelook : bool = false
var mouse_sensitivity : float = 0.01
var mouse_velocity : Vector2

@export_group("Player Camera")
## in local space
@export var default_distance : float
@export var default_rotation_offset : Vector3
@export var target : Node3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_velocity = event.velocity
		print("%v" % event.screen_velocity)

func _process(delta: float) -> void:
	is_freelook = Input.is_action_pressed("freelook")
	
	if is_freelook:
		rotation_offset.y += mouse_velocity.x * mouse_sensitivity * delta
		rotation_offset.x += -1.0 * mouse_velocity.y * mouse_sensitivity * delta

	elif target:
		var forward : Vector3 = target.basis.orthonormalized().z
		var heading : Vector3 = forward
		heading.y = 0
		heading = heading.normalized()
		# pitch
		rotation_offset.x = forward.angle_to(heading) * signf(forward.y)
		# yaw
		rotation_offset.y = (heading.angle_to(Vector3(0,0,1)) * signf(heading.x))  + PI
	
	mouse_velocity = Vector2.ZERO
	
	var yaw = Basis(Vector3(0, 1, 0), rotation_offset.y)
	var pitch = Basis(Vector3(1, 0, 0), rotation_offset.x)
	var total_rotation : Basis = yaw * pitch
	var offset_position = total_rotation.orthonormalized() * Vector3(0,0,default_distance)
	
	if target != null:
		position = offset_position + target.position
	else:
		position = offset_position + position
	
	quaternion = Quaternion(total_rotation.orthonormalized())
	
	
