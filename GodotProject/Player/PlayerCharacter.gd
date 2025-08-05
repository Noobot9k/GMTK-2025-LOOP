extends CharacterController
class_name PlayerCharacter

@export var _control_enabled = false
#@export var attack_controller : AttackController
@export var camera_rig : FPSCamera
#@export var view_model_controller : ViewModel

@onready var AbilityManager = find_child("AbilityManager")

func set_control_enabled(control_enabled : bool):
	if _control_enabled == control_enabled: return
	
	_control_enabled = control_enabled
	
	#attack_controller.set_enabled(control_enabled)
	#if view_model_controller:
		#view_model_controller.set_enabled(control_enabled)
	if model:
		model.visible = not control_enabled

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if not _control_enabled:
		input_vector = Vector2()
		return
	
	if is_wall_running:
		camera_rig.SubjectLeanDirection = get_wall_normal()
	else:
		camera_rig.SubjectLeanDirection = Vector3.ZERO
	
	input_vector = Input.get_vector(\
		"move_left", "move_right", "move_forward", "move_backward")
	jump_held = Input.is_action_pressed("jump")
	
	super(_delta)
