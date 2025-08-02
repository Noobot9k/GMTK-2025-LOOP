@tool
extends Node3D
class_name ViewModel

signal Step

@onready var animTree = $AnimationTree
#@onready var _shotOriginRemoteTransform : RemoteTransform3D = $Armature/Skeleton3D/Gun/ShotOrigin/RemoteTransform3D
@export var camera : Camera3D
@export var Char : CharacterController

@export_group("Animation values", "Anim")
@export var AnimMovementAlpha : float = 0:
	set(newVal):
		AnimMovementAlpha = newVal
		_animSetMovementAlpha(newVal)
@export var AnimJumpHeld : bool = false:
	set(newVal):
		animTree.set(ATP_JumpHeld, newVal)
@export var AnimGrounded : bool = false:
	set(newVal):
		animTree.set(ATP_Grounded, newVal)
@export var AnimFireHeld : bool = false:
	set(newValue):
		animTree.set(ATP_FireHeld, newValue)
@export var AnimChargeAlpha : float = 0:
	set(newVal):
		animTree.set(ATP_ShotChargeBlend, newVal/2)

# animation track paths. Not sure if I want to @export them.
@export_group("Animation Track Paths", "ATP_")
@export var ATP_JumpHeld = "parameters/Movement/conditions/jump_held"
@export var ATP_Grounded = "parameters/Movement/conditions/grounded"
@export var ATP_FireHeld = "parameters/Weapon/conditions/fire_held"
@export var ATP_ShotChargeBlend = "parameters/Shot_Charge_Blend/add_amount"
@export var ATP_MovementBlendAmount = "parameters/Movement/Walking/MovementBlend/blend_amount"
@export var ATP_MovementBlendScale = "parameters/Movement/Walking/MovementScale/scale"

#var _externalShotOrigin : Node3D
var _enabled = false
#var lasttick = -100

func SetAnimChargeAlpha(newValue : float):
	AnimChargeAlpha = newValue
func SetAnimFireHeld(newValue : bool):
	AnimFireHeld = newValue

func FootStep():
	if Engine.is_editor_hint(): return
	
	Step.emit()

func set_enabled(enabled : bool):
	if Engine.is_editor_hint(): return
	
	if _enabled == enabled: return
	_enabled = enabled
	camera.current = enabled
	self.visible = enabled

func _ready() -> void:
	#_findExternalShotOrigin()
	update_configuration_warnings()
	if Engine.is_editor_hint(): return
	pass

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	AnimMovementAlpha = (Char.velocity * Vector3(1,0,1)).length() / Char.move_speed
	AnimJumpHeld = Char.jump_held
	AnimGrounded = Char.is_on_floor()
	
	#_animSetMovementAlpha(AnimMovementAlpha)
	#animTree.set(ATP_JumpHeld, AnimJumpHeld)
	#animTree.set(ATP_Grounded, AnimGrounded)
	
	#var tick = ScaledTime.CurrentTime
	#if tick - lasttick > 0.5:
		#AnimShoot()
		#lasttick = tick

#func AnimShoot():
	#animTree.set(ATP_FireHeld, true)
	#await  get_tree().process_frame
	#animTree.set(ATP_FireHeld, false)

#func AnimSetChargeAlpha(alpha : float):
	#animTree.set(ATP_ShotChargeBlend, alpha / 2)

func _animSetMovementAlpha(alpha : float):
	animTree.set(ATP_MovementBlendAmount, alpha)
	animTree.set(ATP_MovementBlendScale, alpha)

#func _findExternalShotOrigin() -> Node3D:
	#if not _shotOriginRemoteTransform: return
	#
	#var children : Array[Node] = find_children("ShotOrigin", "Node3D", false, false)
	#
	#if children.size() > 0:
		#for child in children:
			#if not child is Node3D: continue
			#
			#_externalShotOrigin = child
			#_shotOriginRemoteTransform.remote_path = _shotOriginRemoteTransform.get_path_to(_externalShotOrigin)
			#return _externalShotOrigin
	#
	#_externalShotOrigin = null
	#_shotOriginRemoteTransform.remote_path = ""
	#return null

#func _notification(what: int) -> void:
	#if what != NOTIFICATION_CHILD_ORDER_CHANGED: return
	##_findExternalShotOrigin()
	#update_configuration_warnings()

#func _get_configuration_warnings() -> PackedStringArray:
	#if _externalShotOrigin != null: return []
	#var warnings = ["Add a Node3D named 'ShotOrigin' to be synced to the shot origin for external use."]
	#return warnings
