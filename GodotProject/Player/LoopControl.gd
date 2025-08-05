extends Node
class_name LoopControl

@export var LoopSize : float = 32:
	set(newValue):
		LoopSize = newValue
		_updateFog()
@export var LoopRenderCount : int = 4:
	set(newValue):
		LoopRenderCount = clamp(newValue, 0, 4)
@export var Renderers : Array[SubViewport]
@export var CameraTransform : Node3D
@export var RemotePositions : Array[Node3D]
@export var ReverseRemotePosition : Node3D
@export var RenderSurface : LoopRenderSurface
@export var ReverseRenderSurface : LoopRenderSurface
@export var PlayerChar : PlayerCharacter
@export var WorldEnviro : WorldEnvironment

func _updateFog():
	var fogAlpha = (LoopSize - 32) / 32
	WorldEnviro.environment.fog_density = lerp(0.025, 0.01, fogAlpha)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("renderers_increase"):
		IncreaseRenderers()
	if Input.is_action_just_pressed("renderers_decrease"):
		DecreaseRenderers()
	
	_updateFog()
	
	var cameraLookVect : Vector3 = (CameraTransform.global_basis * Vector3.FORWARD)
	var cameraDot : float = cameraLookVect.dot(Vector3.UP)
	var cameraAngle : float = rad_to_deg(cameraLookVect.angle_to(Vector3.UP))
	
	PlayerChar.voidout_hight = -LoopSize - 1
	
	RenderSurface.position.y = -LoopSize if cameraDot <= 0 else 0.0
	RenderSurface.global_basis = Basis.looking_at(
		Vector3.FORWARD,
		Vector3.UP if cameraDot <=0 else Vector3.DOWN
		)
	
	ReverseRenderSurface.position.y = 0.0 if cameraDot <= 0 else -LoopSize
	ReverseRenderSurface.global_basis = Basis.looking_at(
		Vector3.FORWARD,
		Vector3.DOWN if cameraDot <=0 else Vector3.UP
		)
	ReverseRenderSurface.SourceViewport.render_target_update_mode = \
	SubViewport.UPDATE_ALWAYS if \
		cameraAngle >= 90 - (75/2.0) and cameraAngle <= 90 + (75/2.0)\
		else SubViewport.UPDATE_DISABLED
	
	ReverseRemotePosition.position.y = -LoopSize if cameraDot <= 0 else LoopSize
	for remotePos in RemotePositions:
		remotePos.position.y = LoopSize if cameraDot <= 0 else -LoopSize
	
	for i in Renderers.size():
		var renderer : SubViewport = Renderers[i]
		renderer.render_target_update_mode = \
		SubViewport.UPDATE_ALWAYS if i < LoopRenderCount \
		else SubViewport.UPDATE_DISABLED

func TweenLoopSize(newLoopSize : float, tweenLength : float = 1) -> Tween:
	var newTween : Tween = get_tree().create_tween()
	newTween.set_ignore_time_scale(true)
	newTween.set_ease(Tween.EASE_IN_OUT)
	newTween.set_trans(Tween.TRANS_CUBIC)
	newTween.tween_property(self, "LoopSize", newLoopSize, tweenLength)
	return newTween

func IncreaseRenderers():
	LoopRenderCount += 1

func DecreaseRenderers():
	LoopRenderCount -= 1
