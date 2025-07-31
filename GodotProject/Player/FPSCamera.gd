class_name FPSCamera
extends Node3D

@export var CameraSubject : Node3D
## Offset in the subject's local space. -z values move the camera forward.
## Non-zero values for x and z are not recommended.
@export var SubjectOffset : Vector3 = Vector3(0,0.7,0)
@export var SubjectLeanDirection : Vector3
@export var LeanSpeed : float = 5

@export var Sensitivity_Vertical : float = (1.0/10.0)
@export var Sensitivity_Horizontal : float = (1.0/10.0)

@export_flags_3d_physics var HitMask : int
var LookVector : Vector3
var Origin : Vector3
var HitPosition : Vector3

@onready var Axis : Node3D = self
@onready var Pivot : Node3D = $Pivot
@onready var testObj : Node3D = find_child("CSGSphere3D", false, true)

var _smoothedLeanDirection : Vector3 = Vector3.ZERO

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global_basis = CameraSubject.global_basis

func _input(event):
	if not event is InputEventMouseMotion: return
	Axis.rotate(Vector3.UP, -deg_to_rad(event.relative.x) * Sensitivity_Horizontal)
	Pivot.rotate_object_local(
		Vector3.LEFT,
		deg_to_rad(event.relative.y) * Sensitivity_Vertical
	)

func _process(_delta):
	# this code is working as intended but there's a bug with the physics
	# interpolation addon that causes the camera to go crazy when using
	# a SubjectOffset that isn't 0 on the x and z. Switch the camera subject to
	# the CharacterBody3D instead of the smoothed visual if needed.
	global_position = \
		CameraSubject.global_transform.translated_local(SubjectOffset).origin
	
	LookVector = (Pivot.to_global(Vector3.FORWARD) \
		- Pivot.to_global(Vector3.ZERO)).normalized()
	Origin = Pivot.global_position
	
	# camera leaning for things like wallrunning
	#if SubjectLeanDirection.length() > 0:
		#_smoothedLeanDirection = \
			#SubjectLeanDirection.normalized() * _smoothedLeanDirection.length()
	#var blend = 1-pow(0.5, _delta * 10)
	_smoothedLeanDirection = \
		_smoothedLeanDirection.move_toward(SubjectLeanDirection, _delta * LeanSpeed)
	
	if _smoothedLeanDirection.length() > 0:
		var cross = LookVector.cross(Vector3.UP)
		var directionMultiplier = -cross.dot(_smoothedLeanDirection.normalized())
		Pivot.rotation_degrees.z = \
			15 * directionMultiplier * _smoothedLeanDirection.length()
	
	
	var space_state = get_world_3d().direct_space_state
	# use global coordinates, not local to node
	var query = PhysicsRayQueryParameters3D.create(Origin, LookVector * 250, HitMask)
	var result = space_state.intersect_ray(query)
	if result:
		#var rightVect = result.normal.cross(Vector3.UP)
		#var upVect = rightVect.cross(result.normal)
		#HitTransform = Transform3D(global_basis, result.position)
		#HitTransform = HitTransform.looking_at(result.position + result.normal)
		HitPosition = result.position
	else:
		#HitTransform = Transform3D(Pivot.global_basis, Origin + LookVector * 1000)
		HitPosition = Origin + LookVector * 50
	
	if testObj:
		#testObj.global_transform = Transform3D(HitTransform)
		testObj.global_position = HitPosition
